package common

import (
	"testing"
)

func TestNewEvent(t *testing.T) {
	eventType := "TestEvent"
	aggregateID := "test-123"
	version := 1
	data := map[string]interface{}{"key": "value"}
	metadata := map[string]interface{}{"source": "test"}

	event := NewEvent(eventType, aggregateID, version, data, metadata)

	if event.Type != eventType {
		t.Errorf("Expected event type %s, got %s", eventType, event.Type)
	}
	if event.AggregateID != aggregateID {
		t.Errorf("Expected aggregate ID %s, got %s", aggregateID, event.AggregateID)
	}
	if event.Version != version {
		t.Errorf("Expected version %d, got %d", version, event.Version)
	}
	if event.Data["key"] != "value" {
		t.Errorf("Expected data key to be 'value', got %v", event.Data["key"])
	}
	if event.Metadata["source"] != "test" {
		t.Errorf("Expected metadata source to be 'test', got %v", event.Metadata["source"])
	}
	if event.ID == "" {
		t.Error("Expected event ID to be generated")
	}
	if event.CreatedAt.IsZero() {
		t.Error("Expected created at timestamp to be set")
	}
}

func TestNewEventWithNilMaps(t *testing.T) {
	event := NewEvent("TestEvent", "test-123", 1, nil, nil)

	if event.Data == nil {
		t.Error("Expected data map to be initialized")
	}
	if event.Metadata == nil {
		t.Error("Expected metadata map to be initialized")
	}
}

func TestEventStore(t *testing.T) {
	store := NewEventStore()

	// Test empty store
	_, err := store.GetStream("nonexistent")
	if err == nil {
		t.Error("Expected error for nonexistent stream")
	}

	version := store.GetStreamVersion("nonexistent")
	if version != 0 {
		t.Errorf("Expected version 0 for nonexistent stream, got %d", version)
	}

	// Test appending events
	event1 := NewEvent("Event1", "stream-1", 1, nil, nil)
	err = store.Append(event1)
	if err != nil {
		t.Errorf("Error appending event: %v", err)
	}

	event2 := NewEvent("Event2", "stream-1", 2, nil, nil)
	err = store.Append(event2)
	if err != nil {
		t.Errorf("Error appending event: %v", err)
	}

	// Test retrieving stream
	events, err := store.GetStream("stream-1")
	if err != nil {
		t.Errorf("Error getting stream: %v", err)
	}
	if len(events) != 2 {
		t.Errorf("Expected 2 events, got %d", len(events))
	}
	if events[0].Type != "Event1" {
		t.Errorf("Expected first event type 'Event1', got %s", events[0].Type)
	}
	if events[1].Type != "Event2" {
		t.Errorf("Expected second event type 'Event2', got %s", events[1].Type)
	}

	// Test stream version
	version = store.GetStreamVersion("stream-1")
	if version != 2 {
		t.Errorf("Expected version 2, got %d", version)
	}
}

func TestBaseAggregate(t *testing.T) {
	store := NewEventStore()
	aggregate := NewBaseAggregate(store)

	// Test initial state
	if aggregate.IsLive() {
		t.Error("Expected aggregate to not be live initially")
	}
	if aggregate.ID() != "" {
		t.Errorf("Expected empty ID initially, got %s", aggregate.ID())
	}
	if aggregate.Version() != 0 {
		t.Errorf("Expected version 0 initially, got %d", aggregate.Version())
	}

	// Test setting properties
	aggregate.SetID("test-123")
	aggregate.SetVersion(5)

	if aggregate.ID() != "test-123" {
		t.Errorf("Expected ID 'test-123', got %s", aggregate.ID())
	}
	if aggregate.Version() != 5 {
		t.Errorf("Expected version 5, got %d", aggregate.Version())
	}

	// Test hydration with no events
	eventHandler := func(event *Event) error {
		t.Errorf("Should not receive any events for empty stream")
		return nil
	}
	err := aggregate.Hydrate("nonexistent-stream", eventHandler)
	if err != nil {
		t.Errorf("Error hydrating from empty stream: %v", err)
	}
	if !aggregate.IsLive() {
		t.Error("Expected aggregate to be live after hydration")
	}

	// Test hydration when already live
	err = aggregate.Hydrate("another-stream", eventHandler)
	if err == nil {
		t.Error("Expected error when hydrating already live aggregate")
	}
}

func TestBaseAggregateHydrationWithEvents(t *testing.T) {
	store := NewEventStore()

	// Add some events to the store
	event1 := NewEvent("Event1", "test-stream", 1, map[string]interface{}{"data": "1"}, nil)
	event2 := NewEvent("Event2", "test-stream", 2, map[string]interface{}{"data": "2"}, nil)
	store.Append(event1)
	store.Append(event2)

	aggregate := NewBaseAggregate(store)

	// Track events received during hydration
	receivedEvents := make([]*Event, 0)
	eventHandler := func(event *Event) error {
		receivedEvents = append(receivedEvents, event)
		return nil
	}

	err := aggregate.Hydrate("test-stream", eventHandler)
	if err != nil {
		t.Errorf("Error hydrating aggregate: %v", err)
	}

	if len(receivedEvents) != 2 {
		t.Errorf("Expected 2 events during hydration, got %d", len(receivedEvents))
	}
	if receivedEvents[0].Type != "Event1" {
		t.Errorf("Expected first event type 'Event1', got %s", receivedEvents[0].Type)
	}
	if receivedEvents[1].Type != "Event2" {
		t.Errorf("Expected second event type 'Event2', got %s", receivedEvents[1].Type)
	}
	if !aggregate.IsLive() {
		t.Error("Expected aggregate to be live after hydration")
	}
}
