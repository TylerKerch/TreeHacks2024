package main

import (
	"encoding/json"
	"fmt"
	"gonum.org/v1/gonum/mat"
	"image"
	"log"
	"math"
	"bytes"
)

func ConvertBodyToVector(body []byte) ([]float64, error) {
	var result [][]float64
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	return result[0], nil
}

func Normalize(v []float64) []float64 {
	vec := mat.NewVecDense(len(v), v)

	// Compute the l2 norm (Euclidean norm)
	norm := mat.Norm(vec, 2)

	// Normalize the vector
	if norm != 0 {
		vec.ScaleVec(1/norm, vec)
	}

	return vec.RawVector().Data
}

func dotProduct(vectorA, vectorB []float64) float64 {
	var sum float64
	for i := range vectorA {
		sum += vectorA[i] * vectorB[i]
	}
	return sum
}

// Function to calculate the magnitude (or norm) of a vector
func magnitude(vector []float64) float64 {
	var sum float64
	for _, v := range vector {
		sum += v * v
	}
	return math.Sqrt(sum)
}

// Function to calculate cosine similarity between two vectors
func cosineSimilarity(vectorA, vectorB []float64) float64 {
	dot := dotProduct(vectorA, vectorB)
	magA := magnitude(vectorA)
	magB := magnitude(vectorB)
	return dot / (magA * magB)
}

// bytesToImage converts a byte slice into an image.Image.
func bytesToImage(b []byte) (image.Image, error) {
	reader := bytes.NewReader(b)
	img, _, err := image.Decode(reader)
	if err != nil {
		return nil, err
	}
	return img, nil
}

// compareImages compares two images pixel by pixel and returns a score based on the similarity.
func compareVectors(imgData1 []byte, imgData2 []byte) float64 {
	img1, err := bytesToImage(imgData1)
	if err != nil {
		log.Fatalf("Failed to convert bytes to image for imgData1: %v", err)
	}

	img2, err := bytesToImage(imgData2)
	if err != nil {
		log.Fatalf("Failed to convert bytes to image for imgData2: %v", err)
	}

	bounds1 := img1.Bounds()
	bounds2 := img2.Bounds()
	if bounds1.Dx() != bounds2.Dx() || bounds1.Dy() != bounds2.Dy() {
		log.Fatalf("Images are of different sizes: %v vs %v", bounds1.Size(), bounds2.Size())
	}

	var similarPixels int
	totalPixels := bounds1.Dx() * bounds1.Dy()

	for y := bounds1.Min.Y; y < bounds1.Max.Y; y++ {
		for x := bounds1.Min.X; x < bounds1.Max.X; x++ {
			r1, g1, b1, a1 := img1.At(x, y).RGBA()
			r2, g2, b2, a2 := img2.At(x, y).RGBA()
			if r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2 {
				similarPixels++
			}
		}
	}

	score := (float64(similarPixels) / float64(totalPixels)) * 100
	return score
}

func CompareVectors(v1 []float64, v2 []float64, b1 []byte, b2 []byte) string {
	similarity := cosineSimilarity(v1, v2)
	ret := compareVectors(b1, b2)
	fmt.Println(ret)
	if similarity < 0.85 {
		return VOICE_OVER
	}

	if similarity < 0.99 {
		return REINDEX
	}

	return NOTHING
}
