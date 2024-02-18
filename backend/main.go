package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
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

// func writeBack(conn *websocket.Conn, message MessageType) {
// 	m := "test"

// 	conn.WriteMessage(messageType, m)
// }

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
		postBody, _ := json.Marshal(map[string]string{
			"inputs":           messageContents,
			"candidate_labels": "",
		})

		responseBody := bytes.NewBuffer(postBody)
		req, err := http.NewRequest("POST", CLIP_URL, responseBody)
		if err != nil {
			return err
		}

		req.Header.Set("Authorization", "Bearer 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")

		client := &http.Client{}
		resp, err := client.Do(req)

		if err != nil {
			return err
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		fmt.Printf("embedding: \n %s\n", body)

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
	http.HandleFunc("/ws", handleWebSocket)
	var uri = fmt.Sprintf("localhost:%d", PORT)

	fmt.Println("Running WebSocket server on " + uri)
	http.ListenAndServe(uri, nil)
}
