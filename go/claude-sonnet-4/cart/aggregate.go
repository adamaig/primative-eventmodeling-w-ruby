// Package cart provides the CartAggregate implementation for the cart domain.
// CartAggregate handles command validation and event persistence for shopping cart functionality.
package cart

import (
	"errors"
	"simple-event-modeling/common"

	"github.com/google/uuid"
)

// CartAggregate represents a shopping cart aggregate
// Aggregates handle command validation and append events to the store if commands are valid.
// Aggregates hydrate by replaying the relevant event stream.
type CartAggregate struct {
	*common.BaseAggregate
	items map[string]int // itemID -> quantity
}

// NewCartAggregate creates a new cart aggregate
func NewCartAggregate(store *common.EventStore) *CartAggregate {
	return &CartAggregate{
		BaseAggregate: common.NewBaseAggregate(store),
		items:         make(map[string]int),
	}
}

// Items returns a copy of the items in the cart
func (ca *CartAggregate) Items() map[string]int {
	items := make(map[string]int)
	for k, v := range ca.items {
		items[k] = v
	}
	return items
}

// Handle processes commands and returns resulting events
func (ca *CartAggregate) Handle(command interface{}) (*common.Event, error) {
	// Extract aggregate ID and determine if we need to hydrate
	var aggregateID string
	switch cmd := command.(type) {
	case *CreateCartCommand:
		aggregateID = cmd.AggregateID
	case *AddItemCommand:
		aggregateID = cmd.AggregateID
	case *RemoveItemCommand:
		aggregateID = cmd.AggregateID
	case *ClearCartCommand:
		aggregateID = cmd.AggregateID
	default:
		return nil, errors.New("unknown command type")
	}

	// Only hydrate if we have an aggregate ID and we're not creating a new cart
	if aggregateID != "" && !ca.IsLive() {
		if err := ca.Hydrate(aggregateID); err != nil {
			return nil, err
		}
	}

	switch cmd := command.(type) {
	case *CreateCartCommand:
		return ca.handleCreateCart()
	case *AddItemCommand:
		return ca.handleAddItem(cmd)
	case *RemoveItemCommand:
		return ca.handleRemoveItem(cmd)
	case *ClearCartCommand:
		return ca.handleClearCart(cmd)
	default:
		return nil, errors.New("unknown command type")
	}
}

// On applies events to aggregate state
func (ca *CartAggregate) On(event *common.Event) error {
	switch event.Type {
	case EventTypeCartCreated:
		return ca.onCartCreated(event)
	case EventTypeItemAdded:
		return ca.onItemAdded(event)
	case EventTypeItemRemoved:
		return ca.onItemRemoved(event)
	case EventTypeCartCleared:
		return ca.onCartCleared(event)
	default:
		return errors.New("unhandled event type: " + event.Type)
	}
}

// Hydrate rebuilds the aggregate state from its event stream
func (ca *CartAggregate) Hydrate(id string) error {
	return ca.BaseAggregate.Hydrate(id, ca.On)
}

// Event handlers

func (ca *CartAggregate) onCartCreated(event *common.Event) error {
	ca.SetID(event.AggregateID)
	ca.SetVersion(event.Version)
	// Mark the aggregate as live after creation
	if !ca.IsLive() {
		ca.SetLive(true)
	}
	return nil
}

func (ca *CartAggregate) onItemAdded(event *common.Event) error {
	if item, ok := event.Data["item"].(string); ok {
		if ca.items[item] == 0 {
			ca.items[item] = 1
		} else {
			ca.items[item]++
		}
	}
	ca.SetVersion(event.Version)
	return nil
}

func (ca *CartAggregate) onItemRemoved(event *common.Event) error {
	if item, ok := event.Data["item"].(string); ok {
		if ca.items[item] > 0 {
			ca.items[item]--
			if ca.items[item] == 0 {
				delete(ca.items, item)
			}
		}
	}
	ca.SetVersion(event.Version)
	return nil
}

func (ca *CartAggregate) onCartCleared(event *common.Event) error {
	ca.items = make(map[string]int)
	ca.SetVersion(event.Version)
	return nil
}

// Command handlers

func (ca *CartAggregate) handleCreateCart() (*common.Event, error) {
	cartID := uuid.New().String()
	event := NewCartCreatedEvent(cartID)

	if err := ca.On(event); err != nil {
		return nil, err
	}

	if err := ca.Store().Append(event); err != nil {
		return nil, err
	}

	return event, nil
}

func (ca *CartAggregate) handleAddItem(cmd *AddItemCommand) (*common.Event, error) {
	// If cart doesn't exist (no aggregate ID), create it first
	if cmd.AggregateID == "" || !ca.IsLive() {
		createEvent, err := ca.handleCreateCart()
		if err != nil {
			return nil, err
		}
		// Update the command with the new cart ID
		cmd.AggregateID = createEvent.AggregateID
	}

	if !ca.IsLive() {
		return nil, &common.InvalidCommandError{Message: "cart not initialized"}
	}

	// Business rule: maximum 3 total items in cart
	totalItems := 0
	for _, quantity := range ca.items {
		totalItems += quantity
	}
	if totalItems >= 3 {
		return nil, &common.InvalidCommandError{Message: "too many items in cart"}
	}

	event := NewItemAddedEvent(ca.ID(), ca.Version()+1, cmd.ItemID)

	if err := ca.On(event); err != nil {
		return nil, err
	}

	if err := ca.Store().Append(event); err != nil {
		return nil, err
	}

	return event, nil
}

func (ca *CartAggregate) handleRemoveItem(cmd *RemoveItemCommand) (*common.Event, error) {
	if !ca.IsLive() {
		return nil, &common.InvalidCommandError{Message: "cart not initialized"}
	}

	if ca.items[cmd.ItemID] == 0 {
		return nil, &common.InvalidCommandError{Message: "item " + cmd.ItemID + " is not in the cart"}
	}

	event := NewItemRemovedEvent(ca.ID(), ca.Version()+1, cmd.ItemID)

	if err := ca.On(event); err != nil {
		return nil, err
	}

	if err := ca.Store().Append(event); err != nil {
		return nil, err
	}

	return event, nil
}

func (ca *CartAggregate) handleClearCart(cmd *ClearCartCommand) (*common.Event, error) {
	if !ca.IsLive() {
		return nil, &common.InvalidCommandError{Message: "cart not initialized"}
	}

	event := NewCartClearedEvent(ca.ID(), ca.Version()+1)

	if err := ca.On(event); err != nil {
		return nil, err
	}

	if err := ca.Store().Append(event); err != nil {
		return nil, err
	}

	return event, nil
}
