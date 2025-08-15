package cart

import (
	"simple-event-modeling/common"
	"testing"
)

func BenchmarkCartAggregate_AddItem(b *testing.B) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart first
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		b.Fatalf("Error creating cart: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Create a new cart for each iteration to avoid hitting the limit
		if i%3 == 0 {
			cart = NewCartAggregate(store)
			createCmd := &CreateCartCommand{}
			createEvent, err = cart.Handle(createCmd)
			if err != nil {
				b.Fatalf("Error creating cart: %v", err)
			}
		}

		addCmd := &AddItemCommand{
			AggregateID: createEvent.AggregateID,
			ItemID:      "item-1",
		}
		_, err := cart.Handle(addCmd)
		if err != nil {
			// Skip if we hit the limit
			if _, ok := err.(*common.InvalidCommandError); !ok {
				b.Fatalf("Unexpected error: %v", err)
			}
		}
	}
}

func BenchmarkCartAggregate_EventReplay(b *testing.B) {
	store := common.NewEventStore()
	cart := NewCartAggregate(store)

	// Create cart and add some events
	createCmd := &CreateCartCommand{}
	createEvent, err := cart.Handle(createCmd)
	if err != nil {
		b.Fatalf("Error creating cart: %v", err)
	}

	// Add multiple items to create a longer event stream
	for i := 0; i < 100; i++ {
		// Create new cart every 3 items to avoid limit
		if i%3 == 0 && i > 0 {
			cart = NewCartAggregate(store)
			createCmd := &CreateCartCommand{}
			createEvent, err = cart.Handle(createCmd)
			if err != nil {
				b.Fatalf("Error creating cart: %v", err)
			}
		}

		addCmd := &AddItemCommand{
			AggregateID: createEvent.AggregateID,
			ItemID:      "item-1",
		}
		cart.Handle(addCmd)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		newCart := NewCartAggregate(store)
		err := newCart.Hydrate(createEvent.AggregateID)
		if err != nil {
			b.Fatalf("Error hydrating cart: %v", err)
		}
	}
}
