package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"treehacks/backend/constants"
)

// ConvertImageToBase64 takes the path of an image file and returns its base64 encoded string.
func ConvertImageToBase64(imagePath string) (string, error) {
	// Read the file into a byte slice
	imageBytes, err := os.ReadFile(imagePath)
	if err != nil {
		return "", err
	}

	// Encode the byte slice to base64
	base64Image := base64.StdEncoding.EncodeToString(imageBytes)

	return base64Image, nil
}

func ImageDescription(base64_image string) string {
	context := constants.CONTEXT
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
				{"type": "image_url", "image_url": "data:image/jpeg;base64," + base64_image},
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

	content := apiResponse.Choices[0].Message.Content
	fmt.Println("Content:", content)
	return content
}

// Define the struct for the image part
type ImageData struct {
	Width  int `json:"width"`
	Height int `json:"height"`
}

// Define the struct for each prediction
type Prediction struct {
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	Width  float64 `json:"width"`
	Height float64 `json:"height"`
	Class  string  `json:"class"`
}

// Define the root struct to match the full JSON structure
type ResponseData struct {
	Time        float64      `json:"time"`
	Image       ImageData    `json:"image"`
	Predictions []Prediction `json:"predictions"`
}

func ReindexImage(payload string) ([]Prediction, error) {
	// Prepare the HTTP request
	apiURL := "https://detect.roboflow.com/ui-screenshots/1?api_key=icHlGR6hm7WYll77q6bh"
	req, err := http.NewRequest("POST", apiURL, bytes.NewBuffer([]byte(payload)))
	if err != nil {
		panic(err)
	}

	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	// Send the request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// Read and print the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var data ResponseData
	err = json.Unmarshal(body, &data)
	if err != nil {
		return nil, err
	}

	return data.Predictions, nil

	// jsonData, err := json.Marshal(data.Predictions)
	// if err != nil {
	// 	return "", err
	// }

	// return string(jsonData), nil	
}
