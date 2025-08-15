// Package cart provides the cart domain implementation for the SimpleEventModeling framework.
// It includes Commands, Events, and the Cart Aggregate that demonstrates event-sourced
// shopping cart functionality.
//
// The package is organized into separate files for each major concept:
// - commands.go: Command types (CreateCart, AddItem, RemoveItem, ClearCart)
// - events.go: Event types and creation functions (CartCreated, ItemAdded, etc.)
// - aggregate.go: CartAggregate implementation with business logic
package cart
