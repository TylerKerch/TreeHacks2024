package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"fmt"
	"os"
	"strings"

	"github.com/danlock/gogosseract"
	"golang.org/x/net/html"
)

var pool *gogosseract.Pool

// extractTextNodes traverses the DOM, extracts text nodes, and appends them to a slice.
func extractTextNodes(n *html.Node, texts *[]string) {
	if n.Type == html.TextNode {
		// Trim the node data to remove extra spaces and newlines
		text := strings.TrimSpace(n.Data)
		if text != "hOCR text" {
			*texts = append(*texts, text)
			if len(*texts) > 2 && (*texts)[len(*texts)-1] == "" && (*texts)[len(*texts)-2] == "" && (*texts)[len(*texts)-3] == "" {
				*texts = append(*texts, "\n")
			}
		}
	}
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		extractTextNodes(c, texts)
	}
}

// hOCRToText takes hOCR data as input and returns cleaned plain text.
func hOCRToText(hocrData string) (string, error) {
	doc, err := html.Parse(strings.NewReader(hocrData))
	if err != nil {
		return "", err
	}
	var texts []string
	extractTextNodes(doc, &texts)
	return strings.Join(texts, " "), nil
}

func textRecognition(ctx context.Context, base64String string) string {
	data, _ := base64.StdEncoding.DecodeString(base64String)
	reader := bytes.NewReader(data)
	hocr, _ := pool.ParseImage(ctx, reader, gogosseract.ParseImageOptions{
		IsHOCR: true,
	})

	fmt.Println(hOCRToText(hocr))

	return hocr
}
func ocrSetUp(ctx context.Context) {
	trainingDataFile, _ := os.Open("eng.traineddata")

	cfg := gogosseract.Config{
		Language:     "eng",
		TrainingData: trainingDataFile,
	}

	// Create 10 Tesseract instances that can process image requests concurrently.
	pool, _ = gogosseract.NewPool(ctx, 10, gogosseract.PoolConfig{Config: cfg})
}

func ocrClosePool() {
	pool.Close()
}
