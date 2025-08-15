package common

import "fmt"

// InvalidCommandError is returned when a command fails validation.
type InvalidCommandError struct{ Message string }

func (e *InvalidCommandError) Error() string { return e.Message }

// StreamNotFoundError is returned when a stream doesn't exist.
type StreamNotFoundError struct{ StreamID string }

func (e *StreamNotFoundError) Error() string { return fmt.Sprintf("stream %s not found", e.StreamID) }
