// Package simpleeventmodeling provides cart commands and queries for event-driven modeling.
package simpleeventmodeling

import "errors"

// Command interfaces

type Command interface {
	Execute(es *EventStore) error
}

// CreateCart command

type CreateCart struct {
	CartID string
}

func (c *CreateCart) Execute(es *EventStore) error {
	if es.StreamExists(c.CartID) {
		return errors.New("cart already exists")
	}
	es.AppendEvent(c.CartID, "CartCreated", map[string]interface{}{"cart_id": c.CartID})
	return nil
}

// AddItem command

type AddItem struct {
	CartID string
	Item   string
}

func (c *AddItem) Execute(es *EventStore) error {
	if !es.StreamExists(c.CartID) {
		return errors.New("cart not found")
	}
	es.AppendEvent(c.CartID, "ItemAdded", map[string]interface{}{"item": c.Item})
	return nil
}

// RemoveItem command

type RemoveItem struct {
	CartID string
	Item   string
}

func (c *RemoveItem) Execute(es *EventStore) error {
	if !es.StreamExists(c.CartID) {
		return errors.New("cart not found")
	}
	es.AppendEvent(c.CartID, "ItemRemoved", map[string]interface{}{"item": c.Item})
	return nil
}

// ClearCart command

type ClearCart struct {
	CartID string
}

func (c *ClearCart) Execute(es *EventStore) error {
	if !es.StreamExists(c.CartID) {
		return errors.New("cart not found")
	}
	es.AppendEvent(c.CartID, "CartCleared", map[string]interface{}{})
	return nil
}

// Queries

// GetCart returns the current state of the cart (list of items).
func GetCart(es *EventStore, cartID string) ([]string, error) {
	events, err := es.GetEvents(cartID)
	if err != nil {
		return nil, err
	}
	var items []string
	for _, event := range events {
		switch event.Type {
		case "ItemAdded":
			item, ok := event.Data["item"].(string)
			if ok {
				items = append(items, item)
			}
		case "ItemRemoved":
			item, ok := event.Data["item"].(string)
			if ok {
				// Remove first occurrence
				for i, v := range items {
					if v == item {
						items = append(items[:i], items[i+1:]...)
						break
					}
				}
			}
		case "CartCleared":
			items = []string{}
		}
	}
	return items, nil
}
