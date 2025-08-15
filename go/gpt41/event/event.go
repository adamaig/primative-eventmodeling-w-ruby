package event

import "time"

// Event represents a domain event.
type Event struct {
	ID          string                 // Unique event ID
	AggregateID string                 // Aggregate (stream) ID
	Type        string                 // Event type
	Version     int                    // Sequential version in stream
	Data        map[string]interface{} // Event payload
	Metadata    map[string]interface{} // Arbitrary event metadata
	CreatedAt   time.Time              // Time event was appended
}
