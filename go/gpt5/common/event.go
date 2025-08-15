package common

import (
	"time"

	"github.com/google/uuid"
)

// Event is a simple record with no behavior, representing a state change.
type Event struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	CreatedAt   time.Time              `json:"created_at"`
	AggregateID string                 `json:"aggregate_id"`
	Version     int                    `json:"version"`
	Data        map[string]interface{} `json:"data"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// NewEvent constructs an Event value.
func NewEvent(eventType, aggregateID string, version int, data, metadata map[string]interface{}) Event {
	if data == nil {
		data = map[string]interface{}{}
	}
	if metadata == nil {
		metadata = map[string]interface{}{}
	}
	return Event{
		ID:          uuid.NewString(),
		Type:        eventType,
		CreatedAt:   time.Now(),
		AggregateID: aggregateID,
		Version:     version,
		Data:        data,
		Metadata:    metadata,
	}
}
