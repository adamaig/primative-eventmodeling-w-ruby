package queries_test

import (
	"reflect"
	"testing"

	"gpt5/cart"
	"gpt5/cart/queries"
	"gpt5/common"
)

func TestCartItemsRead_Projections(t *testing.T) {
	es := common.NewEventStore()

	cartCreated := cart.NewCartCreated("cart-123").Event
	item1 := cart.NewItemAdded("cart-123", 2, "item-456").Event
	item2 := cart.NewItemAdded("cart-123", 3, "item-789").Event
	item1again := cart.NewItemAdded("cart-123", 4, "item-456").Event

	es.Append(cartCreated)
	es.Append(item1)
	es.Append(item2)
	es.Append(item1again)

	q := queries.NewCartItemsRead("cart-123", es)
	res, err := q.Execute()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := map[string]any{
		"cart": map[string]any{
			"cart_id": "cart-123",
			"items": map[string]map[string]int{
				"item-456": {"quantity": 2},
				"item-789": {"quantity": 1},
			},
			"totals": map[string]float64{"total": 0.0},
		},
	}
	if !reflect.DeepEqual(res, expected) {
		t.Fatalf("projection mismatch\nexpected: %#v\nactual: %#v", expected, res)
	}
}

func TestCartItemsRead_RemovalsAndClear(t *testing.T) {
	es := common.NewEventStore()
	cartCreated := cart.NewCartCreated("cart-123").Event
	item1 := cart.NewItemAdded("cart-123", 2, "item-456").Event
	item2 := cart.NewItemAdded("cart-123", 3, "item-789").Event
	item1again := cart.NewItemAdded("cart-123", 4, "item-456").Event
	item1removed := cart.NewItemRemoved("cart-123", 5, "item-456").Event
	item2removed := cart.NewItemRemoved("cart-123", 6, "item-789").Event

	es.Append(cartCreated)
	es.Append(item1)
	es.Append(item2)
	es.Append(item1again)
	es.Append(item1removed)
	es.Append(item2removed)

	q := queries.NewCartItemsRead("cart-123", es)
	res, err := q.Execute()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := map[string]any{
		"cart": map[string]any{
			"cart_id": "cart-123",
			"totals":  map[string]float64{"total": 0.0},
			"items": map[string]map[string]int{
				"item-456": {"quantity": 1},
			},
		},
	}
	if !reflect.DeepEqual(res, expected) {
		t.Fatalf("projection mismatch after removals\nexpected: %#v\nactual: %#v", expected, res)
	}

	// Now clear
	cleared := cart.NewCartCleared("cart-123", 7).Event
	es.Append(cleared)

	res, err = q.Execute()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedAfterClear := map[string]any{
		"cart": map[string]any{
			"cart_id": "cart-123",
			"items":   map[string]map[string]int{},
			"totals":  map[string]float64{"total": 0.0},
		},
	}
	if !reflect.DeepEqual(res, expectedAfterClear) {
		t.Fatalf("projection mismatch after clear\nexpected: %#v\nactual: %#v", expectedAfterClear, res)
	}
}
