package cart

import (
	"fmt"
	"simple-event-modeling/common"
	"testing"
)

func TestCartAggregate_CreateCart(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	cmd := &CreateCartCommand{}
	event, err := cart.Handle(cmd)

	if err != nil {
		t.Errorf("Error creating cart: %v", err)
	}
	if event.Type != EventTypeCartCreated {
		t.Errorf("Expected event type %s, got %s", EventTypeCartCreated, event.Type)
	}
	if event.Version != 1 {
		t.Errorf("Expected version 1, got %d", event.Version)
	}
	if !cart.IsLive() {
		t.Error("Expected cart to be live after creation")
	}
	if cart.ID() == "" {
		t.Error("Expected cart to have an ID after creation")
	}
}

func TestCartAggregate_AddItem(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart first
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}

	// Add item
	addCmd := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-1",
	}
	event, err := cart.Handle(addCmd)

	if err != nil {
		t.Errorf("Error adding item: %v", err)
	}
	if event.Type != EventTypeItemAdded {
		t.Errorf("Expected event type %s, got %s", EventTypeItemAdded, event.Type)
	}
	if event.Version != 2 {
		t.Errorf("Expected version 2, got %d", event.Version)
	}

	// Check cart state
	items := cart.Items()
	if items["item-1"] != 1 {
		t.Errorf("Expected item-1 quantity 1, got %d", items["item-1"])
	}
}

func TestCartAggregate_AddItemWithoutCart(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Add item without creating cart first (should auto-create)
	addCmd := &AddItemCommand{
		AggregateID: "",
		ItemID:      "item-1",
	}
	event, err := cart.Handle(addCmd)

	if err != nil {
		t.Errorf("Error adding item: %v", err)
	}
	if event.Type != EventTypeItemAdded {
		t.Errorf("Expected event type %s, got %s", EventTypeItemAdded, event.Type)
	}
	if !cart.IsLive() {
		t.Error("Expected cart to be live after auto-creation")
	}

	// Check cart state
	items := cart.Items()
	if items["item-1"] != 1 {
		t.Errorf("Expected item-1 quantity 1, got %d", items["item-1"])
	}
}

func TestCartAggregate_RemoveItem(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add item
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}

	addCmd := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-1",
	}
	_, err = cart.Handle(addCmd)
	if err != nil {
		t.Fatalf("Error adding item: %v", err)
	}

	// Remove item
	removeCmd := &RemoveItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-1",
	}
	event, err := cart.Handle(removeCmd)

	if err != nil {
		t.Errorf("Error removing item: %v", err)
	}
	if event.Type != EventTypeItemRemoved {
		t.Errorf("Expected event type %s, got %s", EventTypeItemRemoved, event.Type)
	}
	if event.Version != 3 {
		t.Errorf("Expected version 3, got %d", event.Version)
	}

	// Check cart state
	items := cart.Items()
	if items["item-1"] != 0 {
		t.Errorf("Expected item-1 quantity 0, got %d", items["item-1"])
	}
}

func TestCartAggregate_RemoveNonexistentItem(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}

	// Try to remove item that's not in cart
	removeCmd := &RemoveItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "nonexistent-item",
	}
	_, err = cart.Handle(removeCmd)

	if err == nil {
		t.Error("Expected error when removing nonexistent item")
	}
	if _, ok := err.(*common.InvalidCommandError); !ok {
		t.Errorf("Expected InvalidCommandError, got %T", err)
	}
}

func TestCartAggregate_ClearCart(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add items
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}

	addCmd1 := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-1",
	}
	_, err = cart.Handle(addCmd1)
	if err != nil {
		t.Fatalf("Error adding item: %v", err)
	}

	addCmd2 := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-2",
	}
	_, err = cart.Handle(addCmd2)
	if err != nil {
		t.Fatalf("Error adding item: %v", err)
	}

	// Clear cart
	clearCmd := &ClearCartCommand{
		AggregateID: createEvent.AggregateID,
	}
	event, err := cart.Handle(clearCmd)

	if err != nil {
		t.Errorf("Error clearing cart: %v", err)
	}
	if event.Type != EventTypeCartCleared {
		t.Errorf("Expected event type %s, got %s", EventTypeCartCleared, event.Type)
	}

	// Check cart state
	items := cart.Items()
	if len(items) != 0 {
		t.Errorf("Expected empty cart, got %d items", len(items))
	}
}

func TestCartAggregate_MaxItemsLimit(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}

	// Add 3 items (the limit)
	for i := 1; i <= 3; i++ {
		addCmd := &AddItemCommand{
			AggregateID: createEvent.AggregateID,
			ItemID:      fmt.Sprintf("item-%d", i),
		}
		_, err = cart.Handle(addCmd)
		if err != nil {
			t.Fatalf("Error adding item %d: %v", i, err)
		}
	}

	// Try to add a 4th item (should fail)
	addCmd := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-4",
	}
	_, err = cart.Handle(addCmd)

	if err == nil {
		t.Error("Expected error when exceeding item limit")
	}
	if _, ok := err.(*common.InvalidCommandError); !ok {
		t.Errorf("Expected InvalidCommandError, got %T", err)
	}
}

func TestCartAggregate_EventReplay(t *testing.T) {
	store := common.NewEventStore()
	cart1 := NewCartAggregate(store)

	// Create cart and add items
	createCmd := &CreateCartCommand{}
	createEvent, err := cart1.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}

	addCmd1 := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-1",
	}
	_, err = cart1.Handle(addCmd1)
	if err != nil {
		t.Fatalf("Error adding item: %v", err)
	}

	addCmd2 := &AddItemCommand{
		AggregateID: createEvent.AggregateID,
		ItemID:      "item-2",
	}
	_, err = cart1.Handle(addCmd2)
	if err != nil {
		t.Fatalf("Error adding item: %v", err)
	}

	// Create new cart aggregate and hydrate from events
	cart2 := NewCartAggregate(store)
	err = cart2.Hydrate(createEvent.AggregateID)
	if err != nil {
		t.Fatalf("Error hydrating cart: %v", err)
	}

	// Check that both carts have the same state
	items1 := cart1.Items()
	items2 := cart2.Items()

	if len(items1) != len(items2) {
		t.Errorf("Expected same number of items, got %d vs %d", len(items1), len(items2))
	}

	for itemID, quantity1 := range items1 {
		if quantity2, ok := items2[itemID]; !ok || quantity1 != quantity2 {
			t.Errorf("Expected item %s quantity %d, got %d", itemID, quantity1, quantity2)
		}
	}

	if cart1.Version() != cart2.Version() {
		t.Errorf("Expected same version, got %d vs %d", cart1.Version(), cart2.Version())
	}

	if cart1.ID() != cart2.ID() {
		t.Errorf("Expected same ID, got %s vs %s", cart1.ID(), cart2.ID())
	}
}
