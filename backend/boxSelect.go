package main

import (
	"bytes"
	"encoding/base64"
	"image"
	"image/draw"
	"image/jpeg"
	"log"
	// "sync"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"treehacks/backend/constants"
)

type SelectedCropped struct {
	X           float64 `json:"x"`
	Y           float64 `json:"y"`
	Width       float64 `json:"width"`
	Height      float64 `json:"height"`
	Type        string  `json:"type"`
	DetectionId int     `json:"detectionID"`
	Similarity  float64  `json:"similarity"`
	Text 		string  `json:"text"`
}

// Converts a CLIPPrediction to SelectedCropped with additional text.
func convertToSelectedCropped(prediction CLIPPrediction, text string) SelectedCropped {
	return SelectedCropped{
		X:           prediction.X,
		Y:           prediction.Y,
		Width:       prediction.Width,
		Height:      prediction.Height,
		Type:        prediction.Class,
		DetectionId: prediction.DetectionId,
		Similarity:  prediction.Similarity,
		Text:        text,
	}
}
// cropImageBase64 takes the base64 string of an image, and crop dimensions,
// then returns a new base64 string of the cropped image.
func cropImageBase64(imageBase64 string, x, y, width, height float64) string {
	// Decode the base64 string to []byte
	decoded, err := base64.StdEncoding.DecodeString(imageBase64)
	if err != nil {
		log.Fatalf("Failed to decode base64 string: %v", err)
	}

	// Decode the []byte to image.Image
	reader := bytes.NewReader(decoded)
	img, _, err := image.Decode(reader)
	if err != nil {
		log.Fatalf("Failed to decode image: %v", err)
	}

	// Crop the image
	rect := image.Rect(int(x-width/2), int(y-width/2), int(x+width/2), int(y+height/2))
	croppedImg := image.NewRGBA(rect)
	draw.Draw(croppedImg, rect, img, image.Pt(int(x), int(y)), draw.Src)

	// Encode the cropped image to base64
	var buf bytes.Buffer
	// Use jpeg.Encode for JPEG images or png.Encode for PNG images
	err = jpeg.Encode(&buf, croppedImg, nil)
	if err != nil {
		log.Fatalf("Failed to encode cropped image: %v", err)
	}
	encodedString := base64.StdEncoding.EncodeToString(buf.Bytes())

	return encodedString
}

func getClosestBox(imageBase64 string, textQuery string) SelectedCropped {
	predictions, _ := tagImageBoxes(imageBase64, textQuery)
	fmt.Println(predictions)
	selection := predictions[0]
	selectedCropped := cropImageBase64(imageBase64, selection.X, selection.Y, selection.Width, selection.Height)
	textCaption := SubImageDescription(imageBase64, selectedCropped)
	fmt.Println(selection)
	fmt.Println(textCaption)
	return convertToSelectedCropped(selection, textCaption)
}

func SubImageDescription(parent_image string, child_image string) string {
	context := constants.SUB_CONTEXT
	prompt := "What's in this image?"
	maxTokens := 2048
	var headers = map[string]string{
		"Authorization": "Bearer " + os.Getenv("OPEN_AI_API_KEY"),
		"Content-Type":  "application/json",
	}

	data := map[string]interface{}{
		"model": GPT4V_MODEL_ENGINE,
		"messages": []map[string]interface{}{
			{"role": "system", "content": context},
			{"role": "user", "content": []map[string]string{
				{"type": "text", "text": prompt},
				{"type": "image_url", "image_url": "data:image/jpeg;base64," + parent_image},
				{"type": "image_url", "image_url": "data:image/jpeg;base64," + child_image},
			}},
		},
		"max_tokens": maxTokens,
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		fmt.Println("Error encoding JSON:", err)
		return ""
	}

	req, err := http.NewRequest("POST", GPT4V_OPENAI_URL, bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Println("Error creating request:", err)
		return ""
	}
	log.Println("Called OpenAI")

	for key, value := range headers {
		req.Header.Add(key, value)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("Error making request:", err)
		return ""
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		return ""
	}
	type ApiResponse struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	var apiResponse ApiResponse
	if err := json.Unmarshal(body, &apiResponse); err != nil {
		fmt.Println("Error unmarshaling response body:", err)
		return ""
	}

	if len(apiResponse.Choices) == 0 {
		fmt.Println("No choices in response, error here: ", string(body))
		return ""
	}

	content := apiResponse.Choices[0].Message.Content
	fmt.Println("Content (Global Voiceover): ", content)
	return content
}