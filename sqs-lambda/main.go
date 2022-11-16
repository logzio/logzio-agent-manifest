package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/logzio/logzio-go"
)

const (
	endNameLogzioListenerURL = "LOGZIO_LISTENER_URL"
	envNameLogzioToken       = "LOGZIO_TOKEN"
)

func HandleRequest(_ context.Context, event events.SQSEvent) error {
	fmt.Println("Got triggered by SQS - new messages are available")

	shipper, err := logzio.New(
		fmt.Sprintf("%s&type=agent-log", os.Getenv(envNameLogzioToken)),
		logzio.SetDebug(os.Stderr),
		logzio.SetUrl(os.Getenv(endNameLogzioListenerURL)),
		logzio.SetDrainDuration(time.Second*5),
	)
	if err != nil {
		return fmt.Errorf("error creating Logz.io sender object: %w", err)
	}

	for _, message := range event.Records {
		fmt.Printf("Sending message ID %s body: '%s' to Logz.io", message.MessageId, message.Body)

		if err = shipper.Send([]byte(message.Body)); err != nil {
			fmt.Printf("Error sending the message body: '%s' to Logz.io: %v", message.Body, err)
		}

		fmt.Printf("Sent message ID %s to Logz.io", message.MessageId)
	}

	shipper.Stop()
	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
