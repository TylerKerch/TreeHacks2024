package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
)

type QueryStep struct {
	Text  string `json:"step"`
	Audio string `json:"audio"`
	Err   error  `json:"error"`
}

type QueryNextStepContext struct {
	GlobalQuery          string `json:"global_query"`
	CurrentStep          int    `json:"current_step"`
	CurrentScreenImage   string `json:"current_screen_image"`
	CurrentContextWindow string `json:"current_context_window"`
}

func GetQueryNextStep(args QueryNextStepContext) QueryStep {
	context := args.CurrentContextWindow
	current_step := args.CurrentStep
	current_screen_image := args.CurrentScreenImage
	current_global_query := args.GlobalQuery

	prompt := fmt.Sprintf("I am on the following page. \\ I want to explain to a friend '%s'.  Tell me just the first step to achieve this. Be brief. If I have reached the last step, say 'LAST STEP', but otherwise do not.", current_global_query)
	if current_step != 0 {
		prompt = fmt.Sprintf("I am on the following page. I want to explain to a friend '%s'.  Tell me just the first step to achieve this and get to the next step. Be brief. If I have reached the last step, say 'LAST STEP', but otherwise do not.", current_global_query)
	}

	maxTokens := 128000
	var headers = map[string]string{
		"Authorization": "Bearer " + os.Getenv("OPEN_AI_API_KEY"),
		"Content-Type":  "application/json",
	}

	data := map[string]interface{}{
		"model": GPT4V_MODEL_ENGINE,
		"messages": []map[string]interface{}{
			{"role": "user", "content": []map[string]string{
				{"role": "system", "content": context},
				{"type": "text", "text": prompt},
				{"type": "image_url", "image_url": "data:image/jpeg;base64," + current_screen_image},
			}},
		},
		"max_tokens": maxTokens,
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return QueryStep{Err: errors.New("error marshaling struct to pass to GPT4")}
	}

	req, err := http.NewRequest("POST", GPT4V_OPENAI_URL, bytes.NewBuffer(jsonData))
	if err != nil {
		return QueryStep{Err: errors.New("error creating request")}
	}

	for key, value := range headers {
		req.Header.Add(key, value)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return QueryStep{Err: errors.New("error actually sending request")}
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return QueryStep{Err: errors.New("error reading from IO")}
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
		return QueryStep{Err: errors.New("error unmarshaling response body for query")}
	}

	content := apiResponse.Choices[0].Message.Content

	return QueryStep{Text: content, Audio: content, Err: nil}
}
