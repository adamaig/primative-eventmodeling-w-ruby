package common

import "sync"

// EventStore is an in-memory store that keeps events per aggregate stream.
// It accepts any event that has AggregateID and Version fields.
type EventStore struct {
	mu      sync.RWMutex
	events  []Event
	streams map[string][]Event
}

// NewEventStore creates a new in-memory event store.
func NewEventStore() *EventStore {
	return &EventStore{
		events:  make([]Event, 0),
		streams: make(map[string][]Event),
	}
}

// Append adds an event to the store and returns it.
func (es *EventStore) Append(event Event) Event {
	es.mu.Lock()
	defer es.mu.Unlock()

	aggregateID := event.AggregateID
	if _, ok := es.streams[aggregateID]; !ok {
		es.streams[aggregateID] = make([]Event, 0)
	}

	es.events = append(es.events, event)
	es.streams[aggregateID] = append(es.streams[aggregateID], event)
	return event
}

// GetStream returns the events for a given aggregate or an error.
func (es *EventStore) GetStream(aggregateID string) ([]Event, error) {
	es.mu.RLock()
	defer es.mu.RUnlock()
	stream, ok := es.streams[aggregateID]
	if !ok {
		return nil, &StreamNotFoundError{StreamID: aggregateID}
	}
	return append([]Event(nil), stream...), nil
}

// GetStreamVersion returns the latest version in the stream or 0 if empty/missing.
func (es *EventStore) GetStreamVersion(aggregateID string) int {
	es.mu.RLock()
	defer es.mu.RUnlock()
	stream, ok := es.streams[aggregateID]
	if !ok || len(stream) == 0 {
		return 0
	}
	return stream[len(stream)-1].Version
}

// All returns all events ever appended.
func (es *EventStore) All() []Event {
	es.mu.RLock()
	defer es.mu.RUnlock()
	return append([]Event(nil), es.events...)
}
