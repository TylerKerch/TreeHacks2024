package main

import (
	// "bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"

	// "io"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/lpernett/godotenv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sagemakerruntime"
	"gonum.org/v1/gonum/mat"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

const PORT = 8080

type MessageType uint

const (
	SCREENSHOT = iota
	QUERY
	CLEAR_BOUNDING_BOXES
	VOICE_OVER
	DRAW_BOXES
	INVALID
)

var sess *session.Session
var sagemakerClient *sagemakerruntime.SageMakerRuntime

// func writeBack(conn *websocket.Conn, message MessageType) {
// 	m := "test"

// 	conn.WriteMessage(messageType, m)
// }

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

func processMessage(conn *websocket.Conn) error {
	wsMessageType, message, err := conn.ReadMessage() // Read a message from the WebSocket.
	if err != nil {
		return err
	}

	var ourMessageType MessageType
	// var messageContents string

	if wsMessageType == websocket.TextMessage {
		if len(message) > 0 {
			switch firstByte := message[0]; firstByte {
			case '0':
				ourMessageType = SCREENSHOT
			case '1':
				ourMessageType = QUERY
			default:
				ourMessageType = INVALID
			}
		}
	} else {
		return errors.New("WS message was not in a binary form")
	}

	if ourMessageType == INVALID {
		return errors.New("received an invalid message type. Please make sure the first byte is correct")
	}

	switch ourMessageType {
	case SCREENSHOT:

		fmt.Println("Received screenshot")

		result, err := sagemakerClient.InvokeEndpoint(&sagemakerruntime.InvokeEndpointInput{
			Body:         message[1:],
			EndpointName: aws.String("clip-image-model-2023-02-11-06-16-48-670"),
			ContentType:  aws.String("application/x-image"),
		})
		if err != nil {
			log.Println(err)
			return errors.New("failed to call Sagemaker (CLIP) endpoint")
		}

		fmt.Println("Request finished")

		embedding, err := ConvertBodyToVector(result.Body)
		if err != nil {
			return errors.New("failed to convert body to vector from (CLIP) model")
		}
		embedding = Normalize(embedding)

		fmt.Println(embedding)

	case QUERY:
		// do something else
	}

	return err
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
