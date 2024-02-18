package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"

	// "image/jpeg"
	// "log"
	// "sync"
)

type TagBoxesPayload struct {
	ImageBase64 string       `json:"image_base64"`
	TextQuery   string       `json:"text_query"`
	Predictions []BoundingBox `json:"predictions"`
}

type TagBoxesResponse struct {
	Predictions []CLIPPrediction `json:"predictions"`
}

type CLIPPrediction struct {
	X           float64 `json:"x"`
	Y           float64 `json:"y"`
	Width       float64 `json:"width"`
	Height      float64 `json:"height"`
	Class       string  `json:"class"`
	DetectionId string  `json:"detection_id"`
	Similarity  float64 `json:"similarity"`
}

func tagImageBoxes(b64image string, textQuery string) ([]CLIPPrediction, error) {
	// Construct the payload
	payload := TagBoxesPayload{
		ImageBase64: b64image,
		TextQuery:   textQuery,
		Predictions: boundingBoxes,
	}

	// Marshal the payload into JSON
	jsonData, err := json.Marshal(payload)
	if err != nil {
		fmt.Println("Error marshaling JSON:", err)
		return nil, errors.New(err.Error())
	}

	// Make the HTTP POST request
	resp, err := http.Post("http://localhost:8081/process-image", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Println("Error making request:", err)
		return nil, errors.New(err.Error())
	}
	defer resp.Body.Close()

	// Read the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		return nil, errors.New(err.Error())
	}

	var tags TagBoxesResponse
	err = json.Unmarshal(body, &tags)
	if err != nil {
		fmt.Println("Error: ", err)
		return nil, errors.New(err.Error())
	}

	fmt.Println("Response:", len(tags.Predictions))
	return tags.Predictions, nil

	// Decode the base64 image
	// img, err := decodeBase64Image(b64image)
	// if err != nil {
	// 	log.Fatalf("Failed to decode base64 image: %v", err)
	// }

	// var wg sync.WaitGroup
	// embeddings := make([][]float64, len(predictions))

	// for i, prediction := range predictions {
	// 	wg.Add(1) // Increment the WaitGroup counter
	// 	go func(i int, prediction Prediction) {
	// 		defer wg.Done() // Decrement the counter when the goroutine completes

	// 		boundingBox := image.Rect(int(prediction.X-prediction.Width/2), int(prediction.Y-prediction.Height/2), int(prediction.X+prediction.Width/2), int(prediction.Y+prediction.Height/2))
	// 		// Crop the image using the bounding box
	// 		croppedImg, err := cropImage(img, boundingBox)
	// 		if err != nil {
	// 			log.Fatalf("Failed to crop image: %v", err)
	// 		}

	// 		// Encode the cropped image to a format (e.g., JPEG) and save it to a file
	// 		var buf bytes.Buffer
	// 		if err := jpeg.Encode(&buf, croppedImg, nil); err != nil {
	// 			log.Fatalf("Failed to encode cropped image: %v", err)
	// 		}
	// 		croppedImageBytes := buf.Bytes()
	// 		embedding, err := tagImage(croppedImageBytes)
	// 		if err != nil {
	// 			log.Fatalf("Failed to tag cropped image: %v", err)
	// 		}
	// 		embeddings[i] = embedding
	// 	}(i, prediction) // Pass the current loop variables as arguments to the goroutine
	// }

	// wg.Wait() // Wait for all goroutines to complete
	// print(len(embeddings), embeddings[0][0])
}
