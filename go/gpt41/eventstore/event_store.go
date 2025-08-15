package eventstore

import (
	"errors"
	"sync"
	"time"

	"../event"
)

// EventStore is an in-memory event store for streams.
type EventStore struct {
	streams map[string][]event.Event
	lock    sync.RWMutex
}

// NewEventStore creates a new EventStore.
func NewEventStore() *EventStore {
	return &EventStore{
		streams: make(map[string][]event.Event),
	}
}

// AppendEvent adds an event to a stream, assigning version and timestamp.
func (es *EventStore) AppendEvent(streamID string, eventType string, data map[string]interface{}) event.Event {
	es.lock.Lock()
	defer es.lock.Unlock()
	events := es.streams[streamID]
	version := len(events) + 1
	e := event.Event{
		ID:          generateEventID(),
		AggregateID: streamID,
		Type:        eventType,
		Data:        data,
		Version:     version,
		Metadata:    map[string]interface{}{},
		CreatedAt:   time.Now(),
	}
	es.streams[streamID] = append(events, e)
	return e
}

// generateEventID creates a unique event ID (simple placeholder).
func generateEventID() string {
	return time.Now().Format("20060102150405.000000000")
}

// GetEvents returns all events for a stream.
func (es *EventStore) GetEvents(streamID string) ([]event.Event, error) {
	es.lock.RLock()
	defer es.lock.RUnlock()
	events, ok := es.streams[streamID]
	if !ok {
		return nil, errors.New("stream not found")
	}
	return events, nil
}

// StreamExists checks if a stream exists.
func (es *EventStore) StreamExists(streamID string) bool {
	es.lock.RLock()
	defer es.lock.RUnlock()
	_, ok := es.streams[streamID]
	return ok
}

// GetStreamVersion returns the current version of a stream.
func (es *EventStore) GetStreamVersion(streamID string) (int, error) {
	es.lock.RLock()
	defer es.lock.RUnlock()
	events, ok := es.streams[streamID]
	if !ok {
		return 0, errors.New("stream not found")
	}
	return len(events), nil
}

// DeleteStream removes a stream and its events.
func (es *EventStore) DeleteStream(streamID string) {
	es.lock.Lock()
	defer es.lock.Unlock()
	delete(es.streams, streamID)
}
