package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"image"
	"io"
	"net/http"
	// "image/jpeg"
	// "log"
	"strings"
	// "sync"

	"github.com/disintegration/imaging"
)

// decodeBase64Image decodes a base64-encoded image string and returns an image.Image.
func decodeBase64Image(encoded string) (image.Image, error) {
	// Strip metadata if present
	if idx := strings.Index(encoded, ","); idx != -1 {
		encoded = encoded[idx+1:]
	}

	// Decode base64 string
	decoded, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return nil, err
	}

	// Decode image
	img, _, err := image.Decode(bytes.NewReader(decoded))
	if err != nil {
		return nil, err
	}

	return img, nil
}

// cropImage takes an image and a bounding box, then returns the cropped image.
func cropImage(img image.Image, rect image.Rectangle) (image.Image, error) {
	croppedImg := imaging.Crop(img, rect)
	return croppedImg, nil
}

// Define a struct that matches the expected JSON payload structure
type Payload struct {
	ImageBase64 string       `json:"image_base64"`
	TextQuery   string       `json:"text_query"`
	Predictions []Prediction `json:"predictions"`
}

func tagImageBoxes(b64image string, predictions []Prediction) {
	// Construct the payload
	payload := Payload{
		ImageBase64: b64image,
		TextQuery:   "Where is the search bar?",
		Predictions: predictions,
	}

	// Marshal the payload into JSON
	jsonData, err := json.Marshal(payload)
	if err != nil {
		fmt.Println("Error marshaling JSON:", err)
		return
	}

	// Make the HTTP POST request
	resp, err := http.Post("http://localhost:8081/process-image", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Println("Error making request:", err)
		return
	}
	defer resp.Body.Close()

	// Read the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		return
	}

	fmt.Println("Response:", string(body))

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
