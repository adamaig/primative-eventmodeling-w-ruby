// Package simpleeventmodeling provides a minimal event store for event-driven modeling.
// Equivalent to the Ruby SimpleEventModeling library.
package simpleeventmodeling

import (
	"errors"
	"sync"
	"time"
)

// Event represents a domain event.
type Event struct {
	Type      string                 // Event type
	Data      map[string]interface{} // Event payload
	Version   int                    // Sequential version in stream
	Timestamp time.Time              // Time event was appended
}

// EventStore is an in-memory event store for streams.
type EventStore struct {
	streams map[string][]Event
	lock    sync.RWMutex
}

// NewEventStore creates a new EventStore.
func NewEventStore() *EventStore {
	return &EventStore{
		streams: make(map[string][]Event),
	}
}

// AppendEvent adds an event to a stream, assigning version and timestamp.
func (es *EventStore) AppendEvent(streamID string, eventType string, data map[string]interface{}) Event {
	es.lock.Lock()
	defer es.lock.Unlock()
	events := es.streams[streamID]
	version := len(events) + 1
	event := Event{
		Type:      eventType,
		Data:      data,
		Version:   version,
		Timestamp: time.Now(),
	}
	es.streams[streamID] = append(events, event)
	return event
}

// GetEvents returns all events for a stream.
func (es *EventStore) GetEvents(streamID string) ([]Event, error) {
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
