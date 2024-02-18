package main


import(
	"bytes"
	"context"
	"encoding/base64"
	"fmt"
	"os"
	"github.com/danlock/gogosseract"
)

var pool *gogosseract.Pool

func textRecognition(ctx context.Context, base64String string) string {
	// ParseImage loads the image and waits until the Tesseract worker sends back your result.
	data, _ := base64.StdEncoding.DecodeString(base64String)
    reader := bytes.NewReader(data)
	hocr, _ := pool.ParseImage(ctx, reader, gogosseract.ParseImageOptions{
		IsHOCR: true,
	})

	fmt.Println(hocr)

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