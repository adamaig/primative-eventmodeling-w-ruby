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

	// Demonstrate CQRS with Query projection
	fmt.Println("4. CQRS Query Projection (Read Model):")
	query := cart.NewCartItemsQuery(cartAggregate.ID(), store)
	projection, err := query.Execute()
	if err != nil {
		log.Fatal("Error executing query:", err)
	}
	fmt.Printf("   Cart ID: %s\n", projection.CartID)
	fmt.Printf("   Items in projection:\n")
	for itemID, itemView := range projection.Items {
		fmt.Printf("     %s: quantity=%d, price=%.2f, total=%.2f\n",
			itemID, itemView.Quantity, itemView.Price, itemView.Total)
	}
	fmt.Printf("   Totals: count=%d, amount=%.2f\n",
		projection.Totals.ItemCount, projection.Totals.TotalAmount)
	fmt.Println()

	// Try to add too many items (should fail)
	fmt.Println("5. Trying to exceed cart limit...")
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
	fmt.Println("6. Removing an item...")
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

	// Show final cart state vs query projection
	fmt.Println("7. Final state comparison:")
	fmt.Println("   Aggregate state (write model):")
	items = cartAggregate.Items()
	for itemID, quantity := range items {
		fmt.Printf("     %s: %d\n", itemID, quantity)
	}
	fmt.Printf("   Cart version: %d\n", cartAggregate.Version())

	fmt.Println("   Query projection (read model):")
	projection, err = query.Execute()
	if err != nil {
		log.Fatal("Error executing query:", err)
	}
	for itemID, itemView := range projection.Items {
		fmt.Printf("     %s: quantity=%d, total=%.2f\n",
			itemID, itemView.Quantity, itemView.Total)
	}
	fmt.Printf("   Computed totals: count=%d\n", projection.Totals.ItemCount)
	fmt.Println()

	// Demonstrate event replay by creating a new aggregate and hydrating it
	fmt.Println("8. Demonstrating event replay...")
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
	fmt.Println("9. All events in store:")
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
