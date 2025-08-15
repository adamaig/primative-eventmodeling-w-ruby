package common

// Aggregate provides lifecycle and replay hooks for event-sourced models.
type Aggregate interface {
	ID() string
	Version() int
	IsLive() bool
	On(event Event) error
	Handle(command any) (Event, error)
	Hydrate(id string) error
}

// BaseAggregate contains common fields and helpers for aggregates.
type BaseAggregate struct {
	id      string
	version int
	live    bool
	store   *EventStore
}

// NewBaseAggregate constructs a base with the given store.
func NewBaseAggregate(store *EventStore) BaseAggregate {
	return BaseAggregate{store: store}
}

func (b *BaseAggregate) ID() string         { return b.id }
func (b *BaseAggregate) Version() int       { return b.version }
func (b *BaseAggregate) IsLive() bool       { return b.live }
func (b *BaseAggregate) Store() *EventStore { return b.store }
func (b *BaseAggregate) SetID(id string)    { b.id = id }
func (b *BaseAggregate) SetVersion(v int)   { b.version = v }
func (b *BaseAggregate) SetLive(l bool)     { b.live = l }

// Hydrate replays all events for id, applying via provided On method on receiver.
// Callers should wrap this to pass their own On implementation.
func (b *BaseAggregate) HydrateWith(id string, apply func(Event) error) error {
	if b.live {
		return nil // match Ruby: second hydrate is a no-op error there; we choose no-op for simplicity
	}
	stream, err := b.store.GetStream(id)
	if err != nil {
		if _, ok := err.(*StreamNotFoundError); !ok {
			return err
		}
		// missing stream is fine; aggregate starts fresh
	}
	for _, ev := range stream {
		if err := apply(ev); err != nil {
			return err
		}
	}
	b.live = true
	return nil
}
