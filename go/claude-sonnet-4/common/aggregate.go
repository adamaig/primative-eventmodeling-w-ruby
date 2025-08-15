// Package common provides aggregate interfaces and base implementation for the SimpleEventModeling framework.
// Aggregates handle command validation and event persistence in event-sourced systems.
package common

import "errors"

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
