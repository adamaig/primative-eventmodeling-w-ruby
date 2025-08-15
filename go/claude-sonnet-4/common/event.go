// Package common provides the Event type for the SimpleEventModeling framework.
// Events are simple records with no behaviors, containing state change information.
package common

import (
	"time"

	"github.com/google/uuid"
)

// Event represents a domain event in the system
// Events are simple records with no behaviors, containing state change information
type Event struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	CreatedAt   time.Time              `json:"created_at"`
	AggregateID string                 `json:"aggregate_id"`
	Version     int                    `json:"version"`
	Data        map[string]interface{} `json:"data"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// NewEvent creates a new event with the given parameters
func NewEvent(eventType, aggregateID string, version int, data, metadata map[string]interface{}) *Event {
	if data == nil {
		data = make(map[string]interface{})
	}
	if metadata == nil {
		metadata = make(map[string]interface{})
	}

	return &Event{
		ID:          uuid.New().String(),
		Type:        eventType,
		CreatedAt:   time.Now(),
		AggregateID: aggregateID,
		Version:     version,
		Data:        data,
		Metadata:    metadata,
	}
}
