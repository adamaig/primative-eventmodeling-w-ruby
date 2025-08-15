package cart

import (
	"simple-event-modeling/common"
	"testing"
)

func TestCartItemsQuery_Execute(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add items
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}
	cartID := createEvent.AggregateID

	// Add multiple items
	addCmd1 := &AddItemCommand{AggregateID: cartID, ItemID: "apple"}
	_, err = cart.Handle(addCmd1)
	if err != nil {
		t.Fatalf("Error adding apple: %v", err)
	}

	addCmd2 := &AddItemCommand{AggregateID: cartID, ItemID: "banana"}
	_, err = cart.Handle(addCmd2)
	if err != nil {
		t.Fatalf("Error adding banana: %v", err)
	}

	addCmd3 := &AddItemCommand{AggregateID: cartID, ItemID: "apple"} // Add another apple
	_, err = cart.Handle(addCmd3)
	if err != nil {
		t.Fatalf("Error adding second apple: %v", err)
	}

	// Execute query
	query := NewCartItemsQuery(cartID, store)
	projection, err := query.Execute()
	if err != nil {
		t.Fatalf("Error executing query: %v", err)
	}

	// Verify projection
	if projection.CartID != cartID {
		t.Errorf("Expected cart ID %s, got %s", cartID, projection.CartID)
	}

	if len(projection.Items) != 2 {
		t.Errorf("Expected 2 unique items, got %d", len(projection.Items))
	}

	if projection.Items["apple"].Quantity != 2 {
		t.Errorf("Expected apple quantity 2, got %d", projection.Items["apple"].Quantity)
	}

	if projection.Items["banana"].Quantity != 1 {
		t.Errorf("Expected banana quantity 1, got %d", projection.Items["banana"].Quantity)
	}

	if projection.Totals.ItemCount != 3 {
		t.Errorf("Expected total item count 3, got %d", projection.Totals.ItemCount)
	}
}

func TestCartItemsQuery_WithRemovals(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add items
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}
	cartID := createEvent.AggregateID

	// Add items
	addCmd1 := &AddItemCommand{AggregateID: cartID, ItemID: "apple"}
	_, err = cart.Handle(addCmd1)
	if err != nil {
		t.Fatalf("Error adding apple: %v", err)
	}

	addCmd2 := &AddItemCommand{AggregateID: cartID, ItemID: "banana"}
	_, err = cart.Handle(addCmd2)
	if err != nil {
		t.Fatalf("Error adding banana: %v", err)
	}

	// Remove item
	removeCmd := &RemoveItemCommand{AggregateID: cartID, ItemID: "apple"}
	_, err = cart.Handle(removeCmd)
	if err != nil {
		t.Fatalf("Error removing apple: %v", err)
	}

	// Execute query
	query := NewCartItemsQuery(cartID, store)
	projection, err := query.Execute()
	if err != nil {
		t.Fatalf("Error executing query: %v", err)
	}

	// Verify projection
	if len(projection.Items) != 1 {
		t.Errorf("Expected 1 item after removal, got %d", len(projection.Items))
	}

	if _, exists := projection.Items["apple"]; exists {
		t.Error("Expected apple to be removed from projection")
	}

	if projection.Items["banana"].Quantity != 1 {
		t.Errorf("Expected banana quantity 1, got %d", projection.Items["banana"].Quantity)
	}

	if projection.Totals.ItemCount != 1 {
		t.Errorf("Expected total item count 1, got %d", projection.Totals.ItemCount)
	}
}

func TestCartItemsQuery_ClearCart(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add items
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}
	cartID := createEvent.AggregateID

	// Add items
	addCmd := &AddItemCommand{AggregateID: cartID, ItemID: "apple"}
	_, err = cart.Handle(addCmd)
	if err != nil {
		t.Fatalf("Error adding apple: %v", err)
	}

	// Clear cart
	clearCmd := &ClearCartCommand{AggregateID: cartID}
	_, err = cart.Handle(clearCmd)
	if err != nil {
		t.Fatalf("Error clearing cart: %v", err)
	}

	// Execute query
	query := NewCartItemsQuery(cartID, store)
	projection, err := query.Execute()
	if err != nil {
		t.Fatalf("Error executing query: %v", err)
	}

	// Verify projection
	if len(projection.Items) != 0 {
		t.Errorf("Expected empty cart after clear, got %d items", len(projection.Items))
	}

	if projection.Totals.ItemCount != 0 {
		t.Errorf("Expected total item count 0, got %d", projection.Totals.ItemCount)
	}
}

func TestCartItemsQuery_ComputedFields(t *testing.T) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add item
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		t.Fatalf("Error creating cart: %v", err)
	}
	cartID := createEvent.AggregateID

	addCmd := &AddItemCommand{AggregateID: cartID, ItemID: "apple"}
	_, err = cart.Handle(addCmd)
	if err != nil {
		t.Fatalf("Error adding apple: %v", err)
	}

	// Execute query
	query := NewCartItemsQuery(cartID, store)
	projection, err := query.Execute()
	if err != nil {
		t.Fatalf("Error executing query: %v", err)
	}

	// Verify computed fields are initialized
	if projection.Totals == nil {
		t.Error("Expected totals to be computed")
	}

	if projection.Totals.ItemCount != 1 {
		t.Errorf("Expected computed item count 1, got %d", projection.Totals.ItemCount)
	}

	// Verify item view has computed fields
	if item, exists := projection.Items["apple"]; exists {
		if item.Total != item.Price*float64(item.Quantity) {
			t.Errorf("Expected computed total %f, got %f", item.Price*float64(item.Quantity), item.Total)
		}
	} else {
		t.Error("Expected apple item in projection")
	}
}

func TestCartItemsQuery_EmptyCart(t *testing.T) {
	store := common.NewEventStore()
	cartID := "nonexistent-cart"

	// Execute query on non-existent cart
	query := NewCartItemsQuery(cartID, store)
	_, err := query.Execute()

	// Should handle gracefully (empty projection)
	if err == nil {
		t.Error("Expected error for non-existent cart")
	}
}
