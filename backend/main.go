package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"time"
	"log"
	"net/http"
	"os"
	"treehacks/backend/constants"

	"github.com/gorilla/websocket"
	"github.com/lpernett/godotenv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sagemakerruntime"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

const PORT = 8080

type MessageContents struct {
	Type    string `json:"type"`
	Payload string `json:"payload"`
}

const (
	SCREENSHOT           = "IMAGE"
	QUERY                = "QUERY"
	CLEAR_BOUNDING_BOXES = "CLEAR"
	VOICE_OVER           = "SPEAK"
	DRAW_BOXES           = "DRAW"

	// Internal
	REINDEX = "REI"
	NOTHING = "NONE"

	//Image Description
	GPT4V_MODEL_ENGINE = "gpt-4-vision-preview"
	GPT4V_OPENAI_URL = "https://api.openai.com/v1/chat/completions"
)

var sess *session.Session
var sagemakerClient *sagemakerruntime.SageMakerRuntime
var previousEmbedding []float64 = nil

func writeBack(conn *websocket.Conn, message string, payload string) {
	// m := "test"

	// conn.WriteMessage(messageType, m)
}

func ReindexImage(payload string) {

}

func GenerateVoiceover(payload string) string {
	// get voiceover from GPT4

	// goroutine that fires a message over the network

	return ""
}

func processMessage(conn *websocket.Conn) error {
	wsMessageType, message, err := conn.ReadMessage() // Read a message from the WebSocket.
	if err != nil {
		return err
	}

	var incomingMessage MessageContents

	if wsMessageType == websocket.TextMessage {
		err := json.Unmarshal(message, &incomingMessage)
		if err != nil {
			return err
		}
	} else {
		return errors.New("WS message was not in a JSON form")
	}

	switch incomingMessage.Type {
	case SCREENSHOT:
		decodedBytes, err := base64.StdEncoding.DecodeString(incomingMessage.Payload)
		if err != nil {
			return err
		}

		startTime := time.Now()

		result, err := sagemakerClient.InvokeEndpoint(&sagemakerruntime.InvokeEndpointInput{
			Body:         decodedBytes,
			EndpointName: aws.String("clip-image-model-2023-02-11-06-16-48-670"),
			ContentType:  aws.String("application/x-image"),
		})
		if err != nil {
			return errors.New("failed to call Sagemaker (CLIP) endpoint")
		}

		elapsedTime := time.Since(startTime)
		fmt.Printf("The function took %s to execute.\n", elapsedTime)

		log.Println("Request finished")

		embedding, err := ConvertBodyToVector(result.Body)
		if err != nil {
			return errors.New("failed to convert body to vector from (CLIP) model")
		}
		embedding = Normalize(embedding)

		next_action := NOTHING

		if previousEmbedding == nil {
			next_action = VOICE_OVER
		} else {
			next_action = CompareVectors(previousEmbedding, embedding)
		}

		previousEmbedding = embedding
		log.Println(next_action)

		switch next_action {
		case NOTHING:
			return nil
		case REINDEX:
			go ReindexImage(incomingMessage.Payload)
			return nil
		case VOICE_OVER:
			go ReindexImage(incomingMessage.Payload)
			voiceMessage := GenerateVoiceover(incomingMessage.Payload)
			go writeBack(conn, VOICE_OVER, voiceMessage)
			return nil
		}
	case QUERY:

	}

	return err
}
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

func imageDescription(base64_image string) string {
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
				{"type": "image_url", "image_url": "data:image/jpeg;base64,"+base64_image},
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

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil) // Upgrade the connection to a WebSocket.
	if err != nil {
		log.Println(err)
		return
	}
	defer conn.Close()

	for {
		err = processMessage(conn)

		if err != nil {
			log.Print(err)
		}
	}
}

func main() {
	err := godotenv.Load()
	if err != nil {
		panic("Environment variable(s) couldn't be loaded")
	}
	
	var access_token = os.Getenv("ACCESS_TOKEN")
	var secret_access_token = os.Getenv("SECRET_ACCESS_TOKEN")

	if access_token == "" || secret_access_token == "" {
		panic("Environment variable(s) missing")
	}

	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String("us-east-1"),
		Credentials: credentials.NewStaticCredentials(access_token, secret_access_token, ""),
	})

	if err != nil {
		panic("Error creating AWS config")
	}

	sagemakerClient = sagemakerruntime.New(sess)

	http.HandleFunc("/ws", handleWebSocket)
	var uri = fmt.Sprintf("localhost:%d", PORT)

	fmt.Println("Running WebSocket server on " + uri)
	http.ListenAndServe(uri, nil)
}
