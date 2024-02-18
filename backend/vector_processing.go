package main

import (
	"encoding/json"
	"math"

	"gonum.org/v1/gonum/mat"
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

func CompareVectors(v1 []float64, v2 []float64) string {
	similarity := cosineSimilarity(v1, v2)

	if similarity < 0.85 {
		return VOICE_OVER
	}

	if similarity < 0.99 {
		return REINDEX
	}

	return NOTHING
}
