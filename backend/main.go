package main

import (
	// "bytes"
	"encoding/json"
	"errors"
	"fmt"
	// "io"
	"log"
	"net/http"

	"github.com/gorilla/websocket"

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
const CLIP_URL = "https://runtime.sagemaker.us-east-1.amazonaws.com/endpoints/clip-image-model-2023-02-11-06-16-48-670/invocations"

type MessageType uint

const (
	SCREENSHOT = iota
	QUERY
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
	var messageContents string

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

	messageContents = string(message[1:])
	log.Println(messageContents)

	switch ourMessageType {
	case SCREENSHOT:
		// do something
		result, err := sagemakerClient.InvokeEndpoint(&sagemakerruntime.InvokeEndpointInput{
			Body:         image,
			EndpointName: aws.String("clip-image-model-2023-02-11-06-16-48-670"),
			ContentType:  aws.String("application/x-image"),
		})
		if err != nil {

		}

		embedding, err := ConvertBodyToVector(result.Body)
		if err != nil {

		}
		embedding = Normalize(embedding)

		// postBody, _ := json.Marshal(map[string]string{
		// 	"inputs":           messageContents,
		// 	"candidate_labels": "",
		// })

		// responseBody := bytes.NewBuffer(postBody)
		// req, err := http.NewRequest("POST", CLIP_URL, responseBody)
		// if err != nil {
		// 	return err
		// }

		// req.Header.Set("Authorization", "Bearer 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")

		// client := &http.Client{}
		// resp, err := client.Do(req)

		// if err != nil {
		// 	return err
		// }
		// defer resp.Body.Close()

		// body, err := io.ReadAll(resp.Body)
		// if err != nil {
		// 	return err
		// }

		fmt.Printf("embedding: \n %s\n", embedding)

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
	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String("us-east-1"),
		Credentials: credentials.NewStaticCredentials("", "", ""),
	})
	if err != nil {
		// Handle session creation error
	}
	sagemakerClient = sagemakerruntime.New(sess)

	http.HandleFunc("/ws", handleWebSocket)
	var uri = fmt.Sprintf("localhost:%d", PORT)

	fmt.Println("Running WebSocket server on " + uri)
	http.ListenAndServe(uri, nil)
}
