// Package common provides the EventStore implementation for the SimpleEventModeling framework.
// EventStore provides in-memory event storage for event-sourced aggregates.
package common

// EventStore provides in-memory event storage for event-sourced aggregates.
// It stores events that implement the event protocol (have AggregateID and Version).
type EventStore struct {
	events  []*Event
	streams map[string][]*Event
}

// NewEventStore creates a new in-memory event store
func NewEventStore() *EventStore {
	return &EventStore{
		events:  make([]*Event, 0),
		streams: make(map[string][]*Event),
	}
}

// Append adds an event to the store
func (es *EventStore) Append(event *Event) error {
	aggregateID := event.AggregateID
	if es.streams[aggregateID] == nil {
		es.streams[aggregateID] = make([]*Event, 0)
	}

	es.events = append(es.events, event)
	es.streams[aggregateID] = append(es.streams[aggregateID], event)
	return nil
}

// GetStream retrieves all events for a given aggregate ID
func (es *EventStore) GetStream(aggregateID string) ([]*Event, error) {
	stream, exists := es.streams[aggregateID]
	if !exists {
		return nil, &StreamNotFoundError{StreamID: aggregateID}
	}
	return stream, nil
}

// GetStreamVersion returns the current version of a stream
func (es *EventStore) GetStreamVersion(aggregateID string) int {
	stream, err := es.GetStream(aggregateID)
	if err != nil {
		return 0
	}
	if len(stream) == 0 {
		return 0
	}
	return stream[len(stream)-1].Version
}

// GetAllEvents returns all events in the store
func (es *EventStore) GetAllEvents() []*Event {
	return es.events
}
