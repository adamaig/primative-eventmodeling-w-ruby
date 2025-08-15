// Package cart provides command types for the cart domain.
// Commands are simple record structures with no behaviors.
package cart

// CreateCartCommand represents a command to create a new cart
type CreateCartCommand struct {
	AggregateID string
}

// AddItemCommand represents a command to add an item to the cart
type AddItemCommand struct {
	AggregateID string
	ItemID      string
}

// RemoveItemCommand represents a command to remove an item from the cart
type RemoveItemCommand struct {
	AggregateID string
	ItemID      string
}

// ClearCartCommand represents a command to clear all items from the cart
type ClearCartCommand struct {
	AggregateID string
}
