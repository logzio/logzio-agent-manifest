package p

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

const maxSize = 512000

type PubSubMessage struct {
	Data []byte `json:"data"`
}

const textPayload = "textPayload"
const severity = "severity"

// client is used to make HTTP requests with a 10 second timeout.
// http.Clients should be reused instead of created as needed.
var client = &http.Client{
	Timeout: 10 * time.Second,
}

func shouldRetry(statusCode int) bool {
	retry := true
	switch statusCode {
	case http.StatusBadRequest:
		fmt.Printf("Got HTTP %d bad request, skip retry\n", statusCode)
		retry = false
	case http.StatusNotFound:
		fmt.Printf("Got HTTP %d not found, skip retry\n", statusCode)
		retry = false
	case http.StatusUnauthorized:
		fmt.Printf("Got HTTP %d unauthorized, skip retry.Please check your Logs' Token and try again\n", statusCode)
		retry = false
	case http.StatusForbidden:
		fmt.Printf("Got HTTP %d forbidden, skip retry\n", statusCode)
		retry = false
	case http.StatusOK:
		retry = false
	}
	return retry
}

func validateArgumentsAndCreateURL() (string, error) {

	if len(os.Getenv("token")) == 0 {
		return "", fmt.Errorf("Logzio token must be provided")
	}

	if len(os.Getenv("listener")) == 0 {
		return "", fmt.Errorf("Logzio listener must be provided")
	}

	typeLog := os.Getenv("type")
	if len(os.Getenv("type")) == 0 {
		fmt.Printf("Set default log type, `pubsub`")
		typeLog = "pubsub"
	}

	url := fmt.Sprintf("https://%s:8071?token=%s&type=%s", os.Getenv("listener"), os.Getenv("token"), typeLog)
	return url, nil
}

func updateFields(rawDecodedText *[]byte) error {
	var m map[string]interface{}
	err := json.Unmarshal(*rawDecodedText, &m)
	if err != nil {
		fmt.Printf("Can't parse a json: %s", err)
		return err
	}
	val, ok := m[textPayload]
	// If the key textPayload exists
	if ok {
		delete(m, textPayload)
		m["message"] = val
	}
	value, okey := m[severity]
	// If the key severity exists
	if okey {
		delete(m, severity)
		m["log_level"] = value
	}

	*rawDecodedText, err = json.Marshal(m)
	if err != nil {
		fmt.Printf("Can't parse json: %s", err)
		return err
	}
	return nil
}

func doRequest(rawDecodedText []byte, url string) {

	err := updateFields(&rawDecodedText)
	if err != nil {
		fmt.Printf("Can't to update log fields of 'log_level' and 'message': %s", err)
		return
	}
	if binary.Size(rawDecodedText) > maxSize {
		fmt.Printf("The request body size is larger than %d KB. The log will be converted to a string and the size of the string will be the %d KB. After that string of the log will be store in message.", maxSize, maxSize)
		cutMessage := string(rawDecodedText)[:maxSize]
		logToSend := fmt.Sprintf("{message:%s}", cutMessage)
		rawDecodedText = []byte(logToSend)
	}
	// gzip compress data before shipping
	var compressedBuf bytes.Buffer
	gzipWriter := gzip.NewWriter(&compressedBuf)
	gzipWriter.Write(rawDecodedText)
	gzipWriter.Close()

	backOff := time.Second * 2
	sendRetries := 4
	toBackOff := false
	for attempt := 0; attempt < sendRetries; attempt++ {
		if toBackOff {
			fmt.Printf("Failed to send logs, trying again in %s\n", backOff)
			time.Sleep(backOff)
			backOff *= 2
		}

		req, err := http.NewRequest("POST", url, &compressedBuf)
		if err != nil {
			fmt.Printf("Connection was failed: %s", err)
			return
		}
		req.Header.Add("Content-Encoding", "gzip")
		req.Header.Add("Content-Type", "text/plain")

		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("Can't send data to logz.io, reason is: %s", err)
			return
		}

		defer resp.Body.Close()

		if shouldRetry(resp.StatusCode) {
			toBackOff = true
		} else {
			break
		}

	}

}

func LogzioHandler(ctx context.Context, m PubSubMessage) error {

	url, err := validateArgumentsAndCreateURL()
	if err != nil {
		return err
	}

	doRequest(m.Data, url)
	return nil
}
