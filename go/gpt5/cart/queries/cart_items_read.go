package queries

import (
	"fmt"

	"gpt5/common"
)

// CartItemsRead projects the current state of a cart from its event stream.
// Result shape mirrors the Ruby version: { cart: { cart_id, items, totals } }
// items is map[itemID] -> { quantity: int }

type CartItemsRead struct {
	aggregateID string
	store       *common.EventStore
	projection  map[string]any
}

func NewCartItemsRead(aggregateID string, store *common.EventStore) *CartItemsRead {
	return &CartItemsRead{
		aggregateID: aggregateID,
		store:       store,
		projection:  map[string]any{},
	}
}

func (q *CartItemsRead) Execute() (map[string]any, error) {
	events, err := q.store.GetStream(q.aggregateID)
	if err != nil {
		return nil, err
	}
	for _, e := range events {
		if err := q.on(e); err != nil {
			return nil, err
		}
	}
	return map[string]any{"cart": q.projection}, nil
}

func (q *CartItemsRead) on(e common.Event) error {
	switch e.Type {
	case "CartCreated":
		return q.onCartCreated(e)
	case "ItemAdded":
		return q.onItemAdded(e)
	case "ItemRemoved":
		return q.onItemRemoved(e)
	case "CartCleared":
		return q.onCartCleared(e)
	default:
		return fmt.Errorf("unhandled event type: %s", e.Type)
	}
}

func (q *CartItemsRead) onCartCreated(e common.Event) error {
	q.projection["cart_id"] = e.AggregateID
	q.projection["items"] = map[string]map[string]int{}
	q.projection["totals"] = map[string]float64{"total": 0.0}
	return nil
}

func (q *CartItemsRead) onItemAdded(e common.Event) error {
	items, _ := q.projection["items"].(map[string]map[string]int)
	if items == nil {
		items = map[string]map[string]int{}
		q.projection["items"] = items
	}
	itemID, _ := e.Data["item"].(string)
	if _, ok := items[itemID]; !ok {
		items[itemID] = map[string]int{"quantity": 0}
	}
	items[itemID]["quantity"]++
	return nil
}

func (q *CartItemsRead) onItemRemoved(e common.Event) error {
	items, _ := q.projection["items"].(map[string]map[string]int)
	if items == nil {
		return nil
	}
	itemID, _ := e.Data["item"].(string)
	if _, ok := items[itemID]; !ok {
		return nil
	}
	items[itemID]["quantity"]--
	if items[itemID]["quantity"] < 1 {
		delete(items, itemID)
	}
	return nil
}

func (q *CartItemsRead) onCartCleared(_ common.Event) error {
	q.projection["items"] = map[string]map[string]int{}
	return nil
}
