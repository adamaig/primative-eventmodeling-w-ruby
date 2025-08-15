// Package main demonstrates the SimpleEventModeling library with a cart example
package main

import (
	"fmt"
	"log"
	"simple-event-modeling/cart"
	"simple-event-modeling/common"
)

func main() {
	// Create an event store
	store := common.NewEventStore()

	// Create a cart aggregate
	cartAggregate := cart.NewCartAggregate(store)

	fmt.Println("=== SimpleEventModeling Go Demo ===")
	fmt.Println()

	// Create a new cart
	fmt.Println("1. Creating a new cart...")
	createCmd := &cart.CreateCartCommand{}
	event, err := cartAggregate.Handle(createCmd)
	if err != nil {
		log.Fatal("Error creating cart:", err)
	}
	fmt.Printf("   Cart created with ID: %s\n", event.AggregateID)
	fmt.Printf("   Event: %s (version %d)\n", event.Type, event.Version)
	fmt.Println()

	// Add some items
	fmt.Println("2. Adding items to cart...")
	addCmd1 := &cart.AddItemCommand{
		AggregateID: event.AggregateID,
		ItemID:      "item-1",
	}
	event, err = cartAggregate.Handle(addCmd1)
	if err != nil {
		log.Fatal("Error adding item:", err)
	}
	fmt.Printf("   Added item-1 (version %d)\n", event.Version)

	addCmd2 := &cart.AddItemCommand{
		AggregateID: event.AggregateID,
		ItemID:      "item-2",
	}
	event, err = cartAggregate.Handle(addCmd2)
	if err != nil {
		log.Fatal("Error adding item:", err)
	}
	fmt.Printf("   Added item-2 (version %d)\n", event.Version)
	fmt.Println()

	// Show current cart state
	fmt.Println("3. Current cart state:")
	items := cartAggregate.Items()
	for itemID, quantity := range items {
		fmt.Printf("   %s: %d\n", itemID, quantity)
	}
	fmt.Printf("   Cart version: %d\n", cartAggregate.Version())
	fmt.Println()

	// Try to add too many items (should fail)
	fmt.Println("4. Trying to exceed cart limit...")
	addCmd3 := &cart.AddItemCommand{
		AggregateID: event.AggregateID,
		ItemID:      "item-3",
	}
	event, err = cartAggregate.Handle(addCmd3)
	if err != nil {
		log.Fatal("Error adding item:", err)
	}
	fmt.Printf("   Added item-3 (version %d)\n", event.Version)

	addCmd4 := &cart.AddItemCommand{
		AggregateID: event.AggregateID,
		ItemID:      "item-4",
	}
	_, err = cartAggregate.Handle(addCmd4)
	if err != nil {
		fmt.Printf("   Expected error: %s\n", err.Error())
	}
	fmt.Println()

	// Remove an item
	fmt.Println("5. Removing an item...")
	removeCmd := &cart.RemoveItemCommand{
		AggregateID: event.AggregateID,
		ItemID:      "item-2",
	}
	event, err = cartAggregate.Handle(removeCmd)
	if err != nil {
		log.Fatal("Error removing item:", err)
	}
	fmt.Printf("   Removed item-2 (version %d)\n", event.Version)
	fmt.Println()

	// Show final cart state
	fmt.Println("6. Final cart state:")
	items = cartAggregate.Items()
	for itemID, quantity := range items {
		fmt.Printf("   %s: %d\n", itemID, quantity)
	}
	fmt.Printf("   Cart version: %d\n", cartAggregate.Version())
	fmt.Println()

	// Demonstrate event replay by creating a new aggregate and hydrating it
	fmt.Println("7. Demonstrating event replay...")
	newCartAggregate := cart.NewCartAggregate(store)
	err = newCartAggregate.Hydrate(cartAggregate.ID())
	if err != nil {
		log.Fatal("Error hydrating cart:", err)
	}

	fmt.Println("   Replayed cart state:")
	items = newCartAggregate.Items()
	for itemID, quantity := range items {
		fmt.Printf("   %s: %d\n", itemID, quantity)
	}
	fmt.Printf("   Replayed cart version: %d\n", newCartAggregate.Version())
	fmt.Println()

	// Show all events in the store
	fmt.Println("8. All events in store:")
	events, err := store.GetStream(cartAggregate.ID())
	if err != nil {
		log.Fatal("Error getting events:", err)
	}
	for i, evt := range events {
		fmt.Printf("   %d. %s (v%d) - %s\n", i+1, evt.Type, evt.Version, evt.CreatedAt.Format("15:04:05"))
		if len(evt.Data) > 0 {
			fmt.Printf("      Data: %v\n", evt.Data)
		}
	}
}
