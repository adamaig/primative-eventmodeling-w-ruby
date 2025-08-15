// Package common provides foundational error types for the SimpleEventModeling framework.
package common

import (
	"errors"
	"fmt"
)

// Errors for the event modeling system
var (
	ErrInvalidCommand   = errors.New("invalid command")
	ErrStreamNotFound   = errors.New("stream not found")
	ErrAggregateNotLive = errors.New("aggregate is not live")
)

// StreamNotFoundError represents an error when a stream is not found
type StreamNotFoundError struct {
	StreamID string
}

func (e *StreamNotFoundError) Error() string {
	return fmt.Sprintf("stream %s not found", e.StreamID)
}

// InvalidCommandError represents an error with invalid command data
type InvalidCommandError struct {
	Message string
}

func (e *InvalidCommandError) Error() string {
	return e.Message
}
