package simpleeventmodeling

import (
	"reflect"
	"testing"

	"../eventstore"
)

func TestAppendEventAndGetEvents(t *testing.T) {
	es := eventstore.NewEventStore()
	streamID := "cart-1"
	event := es.AppendEvent(streamID, "CartCreated", map[string]interface{}{"cart_id": 1})

	if event.Version != 1 {
		t.Errorf("expected version 1, got %d", event.Version)
	}
	if event.Type != "CartCreated" {
		t.Errorf("expected type CartCreated, got %s", event.Type)
	}
	if event.Data["cart_id"] != 1 {
		t.Errorf("expected cart_id 1, got %v", event.Data["cart_id"])
	}
	if event.AggregateID != streamID {
		t.Errorf("expected AggregateID %s, got %s", streamID, event.AggregateID)
	}
	if event.ID == "" {
		t.Errorf("expected non-empty event ID")
	}
	if event.CreatedAt.IsZero() {
		t.Errorf("expected CreatedAt to be set")
	}
	if event.Metadata == nil {
		t.Errorf("expected Metadata to be initialized")
	}

	events, err := es.GetEvents(streamID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(events) != 1 {
		t.Errorf("expected 1 event, got %d", len(events))
	}
	if !reflect.DeepEqual(events[0], event) {
		t.Errorf("event mismatch: got %+v, want %+v", events[0], event)
	}
}

func TestStreamVersionAndExists(t *testing.T) {
	es := eventstore.NewEventStore()
	streamID := "cart-2"
	if es.StreamExists(streamID) {
		t.Errorf("stream should not exist yet")
	}
	_ = es.AppendEvent(streamID, "CartCreated", map[string]interface{}{"cart_id": 2})
	_ = es.AppendEvent(streamID, "ItemAdded", map[string]interface{}{"item": "apple"})

	if !es.StreamExists(streamID) {
		t.Errorf("stream should exist")
	}
	version, err := es.GetStreamVersion(streamID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if version != 2 {
		t.Errorf("expected version 2, got %d", version)
	}
}

func TestDeleteStream(t *testing.T) {
	es := eventstore.NewEventStore()
	streamID := "cart-3"
	_ = es.AppendEvent(streamID, "CartCreated", map[string]interface{}{"cart_id": 3})
	es.DeleteStream(streamID)
	if es.StreamExists(streamID) {
		t.Errorf("stream should be deleted")
	}
	_, err := es.GetEvents(streamID)
	if err == nil {
		t.Errorf("expected error for deleted stream")
	}
}

func TestCartCommandsAndQueries(t *testing.T) {
	es := eventstore.NewEventStore()
	cartID := "cart-100"

	// CreateCart
	create := &CreateCart{CartID: cartID}
	if err := create.Execute(es); err != nil {
		t.Fatalf("CreateCart failed: %v", err)
	}
	if !es.StreamExists(cartID) {
		t.Errorf("cart should exist after creation")
	}

	// AddItem
	add := &AddItem{CartID: cartID, Item: "apple"}
	if err := add.Execute(es); err != nil {
		t.Fatalf("AddItem failed: %v", err)
	}
	add2 := &AddItem{CartID: cartID, Item: "banana"}
	if err := add2.Execute(es); err != nil {
		t.Fatalf("AddItem failed: %v", err)
	}

	// RemoveItem
	remove := &RemoveItem{CartID: cartID, Item: "apple"}
	if err := remove.Execute(es); err != nil {
		t.Fatalf("RemoveItem failed: %v", err)
	}

	// Add another apple
	add3 := &AddItem{CartID: cartID, Item: "apple"}
	if err := add3.Execute(es); err != nil {
		t.Fatalf("AddItem failed: %v", err)
	}

	// ClearCart
	clear := &ClearCart{CartID: cartID}
	if err := clear.Execute(es); err != nil {
		t.Fatalf("ClearCart failed: %v", err)
	}

	// Query: GetCart
	items, err := GetCart(es, cartID)
	if err != nil {
		t.Fatalf("GetCart failed: %v", err)
	}
	if len(items) != 0 {
		t.Errorf("expected cart to be empty after clear, got %v", items)
	}

	// Add items again
	_ = (&AddItem{CartID: cartID, Item: "pear"}).Execute(es)
	_ = (&AddItem{CartID: cartID, Item: "grape"}).Execute(es)
	items, err = GetCart(es, cartID)
	if err != nil {
		t.Fatalf("GetCart failed: %v", err)
	}
	if len(items) != 2 || items[0] != "pear" || items[1] != "grape" {
		t.Errorf("unexpected cart items: %v", items)
	}
}
