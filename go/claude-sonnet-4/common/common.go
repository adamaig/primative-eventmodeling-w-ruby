// Package common provides the foundational components for the SimpleEventModeling framework.
// It includes Event, EventStore, Aggregate interfaces and implementations that provide the
// building blocks for event-sourced applications.
package common

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
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

// Aggregate defines the interface for event-sourced aggregates
type Aggregate interface {
	// ID returns the aggregate's identifier
	ID() string
	// Version returns the current version of the aggregate
	Version() int
	// IsLive returns whether the aggregate has been hydrated
	IsLive() bool
	// On applies an event to the aggregate state
	On(event *Event) error
	// Handle processes a command and returns any resulting events
	Handle(command interface{}) (*Event, error)
	// Hydrate rebuilds the aggregate state from its event stream
	Hydrate(id string) error
}

// BaseAggregate provides common functionality for aggregates
type BaseAggregate struct {
	id      string
	version int
	live    bool
	store   *EventStore
}

// NewBaseAggregate creates a new base aggregate
func NewBaseAggregate(store *EventStore) *BaseAggregate {
	return &BaseAggregate{
		store: store,
		live:  false,
	}
}

// ID returns the aggregate's identifier
func (ba *BaseAggregate) ID() string {
	return ba.id
}

// Version returns the current version of the aggregate
func (ba *BaseAggregate) Version() int {
	return ba.version
}

// IsLive returns whether the aggregate has been hydrated
func (ba *BaseAggregate) IsLive() bool {
	return ba.live
}

// Hydrate rebuilds the aggregate state from its event stream
func (ba *BaseAggregate) Hydrate(id string, onEvent func(*Event) error) error {
	if ba.live {
		return errors.New("aggregate is already live")
	}

	events, err := ba.store.GetStream(id)
	if err != nil {
		// If stream doesn't exist, that's okay - we'll start fresh
		if _, ok := err.(*StreamNotFoundError); !ok {
			return err
		}
	}

	for _, event := range events {
		if err := onEvent(event); err != nil {
			return err
		}
	}

	ba.live = true
	return nil
}

// SetID sets the aggregate's identifier
func (ba *BaseAggregate) SetID(id string) {
	ba.id = id
}

// SetVersion sets the aggregate's version
func (ba *BaseAggregate) SetVersion(version int) {
	ba.version = version
}

// SetLive sets the aggregate's live status
func (ba *BaseAggregate) SetLive(live bool) {
	ba.live = live
}

// Store returns the event store
func (ba *BaseAggregate) Store() *EventStore {
	return ba.store
}
