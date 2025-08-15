// Package cart provides event types and creation functions for the cart domain.
// Events are simple record structures with no behaviors.
package cart

import "simple-event-modeling/common"

// Event type constants
const (
	EventTypeCartCreated = "CartCreated"
	EventTypeItemAdded   = "ItemAdded"
	EventTypeItemRemoved = "ItemRemoved"
	EventTypeCartCleared = "CartCleared"
)

// NewCartCreatedEvent creates a new CartCreated event
func NewCartCreatedEvent(aggregateID string) *common.Event {
	return common.NewEvent(EventTypeCartCreated, aggregateID, 1, nil, nil)
}

// NewItemAddedEvent creates a new ItemAdded event
func NewItemAddedEvent(aggregateID string, version int, itemID string) *common.Event {
	data := map[string]interface{}{
		"item": itemID,
	}
	return common.NewEvent(EventTypeItemAdded, aggregateID, version, data, nil)
}

// NewItemRemovedEvent creates a new ItemRemoved event
func NewItemRemovedEvent(aggregateID string, version int, itemID string) *common.Event {
	data := map[string]interface{}{
		"item": itemID,
	}
	return common.NewEvent(EventTypeItemRemoved, aggregateID, version, data, nil)
}

// NewCartClearedEvent creates a new CartCleared event
func NewCartClearedEvent(aggregateID string, version int) *common.Event {
	return common.NewEvent(EventTypeCartCleared, aggregateID, version, nil, nil)
}
