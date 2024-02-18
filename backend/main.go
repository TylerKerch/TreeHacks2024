package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"bytes"
	"io"

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
	GPT4V_OPENAI_URL   = "https://api.openai.com/v1/chat/completions"
)

var sess *session.Session
var sagemakerClient *sagemakerruntime.SageMakerRuntime
var previousEmbedding []float64 = nil
var conn *websocket.Conn

func writeBack(message string, payload string) {
	// m := "test"

	// conn.WriteMessage(messageType, m)
}

func ReindexImage(payload string) {
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
		panic(err)
	}
	defer resp.Body.Close()

	// Read and print the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	println(string(body))
}

func processMessage() error {
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

		next_action := VOICE_OVER
		if previousEmbedding != nil {
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
			voiceMessage := ImageDescription(incomingMessage.Payload)
			go writeBack(VOICE_OVER, voiceMessage)
			return nil
		}
	case QUERY:

	}

	return err
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	connection, err := upgrader.Upgrade(w, r, nil) // Upgrade the connection to a WebSocket.
	if err != nil {
		log.Println(err)
		return
	}
	defer connection.Close()

	conn = connection

	for {
		err = processMessage()

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
