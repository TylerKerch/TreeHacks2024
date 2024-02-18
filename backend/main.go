package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sagemakerruntime"
	"github.com/gorilla/websocket"
	"github.com/lpernett/godotenv"
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

	// Image Description
	GPT4V_MODEL_ENGINE = "gpt-4-vision-preview"
	GPT4V_OPENAI_URL   = "https://api.openai.com/v1/chat/completions"

	// Starting context window
	FRESH_CONTEXT_WINDOW = "You are a tool that aides the elderly in navigating their computers by helping them fulfill a goal (like 'watching a video about cats') by suggesting a next step. Your goal is to only output the next step towards reaching the final screen. Currently, your goal is to assist the user with this query that they've provided: GLOBAL_QUERY. If you have reached the final screen (that is, there isn't an action the user needs to take), say 'LAST STEP'. Below is the context of the task including steps that have been taken. CONTEXT: "
)

var sess *session.Session
var sagemaker_client *sagemakerruntime.SageMakerRuntime
var previous_embedding []float64 = nil
var conn *websocket.Conn
var current_screen_image string

var current_global_query string        // reset me on new query
var step_channel chan (bool) = nil     // reset me on new query
var current_step_count = 0             // reset me on new query
var current_context_window string = "" // reset me on new query

func UpdateContextWindow(global_query string) {
	current_context_window = strings.Replace(FRESH_CONTEXT_WINDOW, "GLOBAL_QUERY", global_query, 1)
}

func writeBack(messageType string, payload string) {
	err := conn.WriteJSON(MessageContents{
		Type:    messageType,
		Payload: payload,
	})
	if err != nil {
		log.Println(err)
	}
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
		current_screen_image = incomingMessage.Payload
		decodedBytes, err := base64.StdEncoding.DecodeString(incomingMessage.Payload)
		if err != nil {
			return err
		}

		startTime := time.Now()

		result, err := sagemaker_client.InvokeEndpoint(&sagemakerruntime.InvokeEndpointInput{
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
		if previous_embedding != nil {
			next_action = CompareVectors(previous_embedding, embedding)
		}

		previous_embedding = embedding

		switch next_action {
		case NOTHING:
			go writeBack(NOTHING, "")
			return nil
		case REINDEX:
			jsonData, err := ReindexImage(incomingMessage.Payload)
			if err != nil {
				log.Println(err)
			}

			go writeBack(REINDEX, string(jsonData))
			return nil
		case VOICE_OVER:
			jsonData, err := ReindexImage(incomingMessage.Payload)
			if err != nil {
				log.Println(err)
			}
			go writeBack(REINDEX, string(jsonData))
			voiceMessage := ImageDescription(incomingMessage.Payload)
			go writeBack(VOICE_OVER, voiceMessage)
			return nil
		}
	case QUERY:
		if step_channel != nil {
			step_channel <- true
		}

		current_global_query = incomingMessage.Payload
		step_channel = make(chan bool)
		current_step_count = 0
		UpdateContextWindow(current_global_query)

		go func() {
			for {
				select {
				case <-step_channel:
					return
				default:
					// Event loop
					nextStep := GetQueryNextStep(QueryNextStepContext{
						CurrentStep:          current_step_count,
						CurrentScreenImage:   current_screen_image,
						CurrentContextWindow: current_context_window,
						GlobalQuery:          current_global_query,
					})

					// text := nextStep.Text
					// closest_box := getClosestBox(text)
					// writeBack(DRAW_BOXES, closest_box)

					writeBack(VOICE_OVER, nextStep.Audio)
					current_context_window += "\n" + nextStep.Text
					current_step_count++
				}
			}
		}()
	}

	return err
}


func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	connection, err := upgrader.Upgrade(w, r, nil) // Upgrade the connection to a WebSocket.
	if err != nil {
		log.Println(err)
		return
	}

	conn = connection
	defer connection.Close()

	for {
		err = processMessage()

		if err != nil {
			log.Print(err)
		}
	}
}

func main() {
	ctx, _ := context.WithCancel(context.Background())
	err := godotenv.Load()
	if err != nil {
		panic("Environment variable(s) couldn't be loaded")
	}

	var access_token = os.Getenv("ACCESS_TOKEN")
	var secret_access_token = os.Getenv("SECRET_ACCESS_TOKEN")
	var openai_api_key = os.Getenv("OPEN_AI_API_KEY")

	if access_token == "" || secret_access_token == "" || openai_api_key == "" {
		panic("Environment variable(s) missing")
	}

	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String("us-east-1"),
		Credentials: credentials.NewStaticCredentials(access_token, secret_access_token, ""),
	})

	if err != nil {
		panic("Error creating AWS config")
	}

	sagemaker_client = sagemakerruntime.New(sess)

	ocrSetUp(ctx)
	http.HandleFunc("/ws", handleWebSocket)
	var uri = fmt.Sprintf("localhost:%d", PORT)

	fmt.Println("Running WebSocket server on " + uri)
	http.ListenAndServe(uri, nil)

	ocrClosePool()

	
}
