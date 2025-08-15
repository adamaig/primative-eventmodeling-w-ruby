// Package main provides an extended example demonstrating advanced SimpleEventModeling usage
package main

import (
	"fmt"
	"log"
	"simple-event-modeling/cart"
	"simple-event-modeling/common"
)

func demonstrateEventReplay() {
	fmt.Println("=== Event Replay Demonstration ===")
	store := common.NewEventStore()

	// Scenario: Multiple carts created and modified over time
	cartIDs := make([]string, 0)

	// Create 3 different carts
	for i := 1; i <= 3; i++ {
		cartAggregate := cart.NewCartAggregate(store)
		createCmd := &cart.CreateCartCommand{}
		event, err := cartAggregate.Handle(createCmd)
		if err != nil {
			log.Fatal("Error creating cart:", err)
		}
		cartIDs = append(cartIDs, event.AggregateID)
		fmt.Printf("Created cart %d with ID: %s\n", i, event.AggregateID[:8]+"...")

		// Add items to each cart
		for j := 1; j <= 2; j++ {
			addCmd := &cart.AddItemCommand{
				AggregateID: event.AggregateID,
				ItemID:      fmt.Sprintf("product-%d-%d", i, j),
			}
			cartAggregate.Handle(addCmd)
		}
	}

	// Now demonstrate replay for each cart
	fmt.Println("\nReplaying events for each cart:")
	for i, cartID := range cartIDs {
		replayCart := cart.NewCartAggregate(store)
		err := replayCart.Hydrate(cartID)
		if err != nil {
			log.Fatal("Error replaying cart:", err)
		}

		fmt.Printf("Cart %d (%s...):\n", i+1, cartID[:8])
		items := replayCart.Items()
		for itemID, quantity := range items {
			fmt.Printf("  %s: %d\n", itemID, quantity)
		}
		fmt.Printf("  Version: %d\n", replayCart.Version())
	}

	// Show total events in store
	fmt.Printf("\nTotal events in store: %d\n", len(store.GetAllEvents()))
}

func demonstrateBusinessRules() {
	fmt.Println("\n=== Business Rules Demonstration ===")
	store := common.NewEventStore()
	cartAggregate := cart.NewCartAggregate(store)

	// Create cart
	createCmd := &cart.CreateCartCommand{}
	event, err := cartAggregate.Handle(createCmd)
	if err != nil {
		log.Fatal("Error creating cart:", err)
	}
	cartID := event.AggregateID

	fmt.Printf("Testing business rule: Maximum 3 items per cart\n")

	// Add items up to the limit
	for i := 1; i <= 3; i++ {
		addCmd := &cart.AddItemCommand{
			AggregateID: cartID,
			ItemID:      fmt.Sprintf("item-%d", i),
		}
		_, err := cartAggregate.Handle(addCmd)
		if err != nil {
			fmt.Printf("Error adding item %d: %s\n", i, err.Error())
		} else {
			fmt.Printf("✓ Added item-%d\n", i)
		}
	}

	// Try to add one more (should fail)
	addCmd := &cart.AddItemCommand{
		AggregateID: cartID,
		ItemID:      "item-4",
	}
	_, err = cartAggregate.Handle(addCmd)
	if err != nil {
		fmt.Printf("✓ Correctly rejected item-4: %s\n", err.Error())
	} else {
		fmt.Printf("✗ Unexpectedly accepted item-4\n")
	}

	// Test removing non-existent item
	removeCmd := &cart.RemoveItemCommand{
		AggregateID: cartID,
		ItemID:      "non-existent-item",
	}
	_, err = cartAggregate.Handle(removeCmd)
	if err != nil {
		fmt.Printf("✓ Correctly rejected removing non-existent item: %s\n", err.Error())
	} else {
		fmt.Printf("✗ Unexpectedly accepted removing non-existent item\n")
	}
}

func demonstrateEventSourcing() {
	fmt.Println("\n=== Event Sourcing Demonstration ===")
	store := common.NewEventStore()
	cartAggregate := cart.NewCartAggregate(store)

	// Create cart
	createCmd := &cart.CreateCartCommand{}
	event, err := cartAggregate.Handle(createCmd)
	if err != nil {
		log.Fatal("Error creating cart:", err)
	}
	cartID := event.AggregateID

	fmt.Printf("Performing a series of operations...\n")

	// Series of operations
	operations := []struct {
		description string
		command     interface{}
	}{
		{"Add Apple", &cart.AddItemCommand{AggregateID: cartID, ItemID: "apple"}},
		{"Add Banana", &cart.AddItemCommand{AggregateID: cartID, ItemID: "banana"}},
		{"Add Orange", &cart.AddItemCommand{AggregateID: cartID, ItemID: "orange"}},
		{"Remove Banana", &cart.RemoveItemCommand{AggregateID: cartID, ItemID: "banana"}},
		{"Add Grape", &cart.AddItemCommand{AggregateID: cartID, ItemID: "grape"}},
	}

	for i, op := range operations {
		_, err := cartAggregate.Handle(op.command)
		if err != nil {
			fmt.Printf("%d. %s - Failed: %s\n", i+1, op.description, err.Error())
		} else {
			fmt.Printf("%d. %s - Success\n", i+1, op.description)
		}
	}

	// Show final state
	fmt.Printf("\nFinal cart state:\n")
	items := cartAggregate.Items()
	for itemID, quantity := range items {
		fmt.Printf("  %s: %d\n", itemID, quantity)
	}

	// Show complete event history
	fmt.Printf("\nComplete event history:\n")
	events, err := store.GetStream(cartID)
	if err != nil {
		log.Fatal("Error getting events:", err)
	}
	for i, evt := range events {
		fmt.Printf("%d. %s (v%d) at %s\n",
			i+1, evt.Type, evt.Version, evt.CreatedAt.Format("15:04:05.000"))
		if len(evt.Data) > 0 {
			fmt.Printf("   Data: %v\n", evt.Data)
		}
	}

	// Demonstrate point-in-time reconstruction
	fmt.Printf("\nDemonstrating point-in-time reconstruction:\n")

	// Replay only first 3 events
	partialCart := cart.NewCartAggregate(store)
	partialEvents := events[:3] // First 3 events

	// We need to manually replay since we can't easily limit Hydrate
	for _, event := range partialEvents {
		partialCart.On(event)
	}
	partialCart.SetLive(true)

	fmt.Printf("State after first 3 events:\n")
	partialItems := partialCart.Items()
	for itemID, quantity := range partialItems {
		fmt.Printf("  %s: %d\n", itemID, quantity)
	}
}

func main() {
	demonstrateEventReplay()
	demonstrateBusinessRules()
	demonstrateEventSourcing()

	fmt.Println("\n=== Summary ===")
	fmt.Println("✓ Commands are simple records with no behaviors")
	fmt.Println("✓ Events are simple records with no behaviors")
	fmt.Println("✓ Aggregates handle command validation")
	fmt.Println("✓ Aggregates append events to store when commands are valid")
	fmt.Println("✓ Aggregates hydrate by replaying event streams")
	fmt.Println("✓ Complete audit trail and point-in-time reconstruction")
	fmt.Println("✓ Business rules enforced through command validation")
}
