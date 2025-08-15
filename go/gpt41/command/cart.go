package command

import (
	"errors"

	"../eventstore"
)

type Command interface {
	Execute(es *eventstore.EventStore) error
}

type CreateCart struct {
	CartID string
}

func (c *CreateCart) Execute(es *eventstore.EventStore) error {
	if es.StreamExists(c.CartID) {
		return errors.New("cart already exists")
	}
	es.AppendEvent(c.CartID, "CartCreated", map[string]interface{}{"cart_id": c.CartID})
	return nil
}

type AddItem struct {
	CartID string
	Item   string
}

func (c *AddItem) Execute(es *eventstore.EventStore) error {
	if !es.StreamExists(c.CartID) {
		return errors.New("cart not found")
	}
	es.AppendEvent(c.CartID, "ItemAdded", map[string]interface{}{"item": c.Item})
	return nil
}

type RemoveItem struct {
	CartID string
	Item   string
}

func (c *RemoveItem) Execute(es *eventstore.EventStore) error {
	if !es.StreamExists(c.CartID) {
		return errors.New("cart not found")
	}
	es.AppendEvent(c.CartID, "ItemRemoved", map[string]interface{}{"item": c.Item})
	return nil
}

type ClearCart struct {
	CartID string
}

func (c *ClearCart) Execute(es *eventstore.EventStore) error {
	if !es.StreamExists(c.CartID) {
		return errors.New("cart not found")
	}
	es.AppendEvent(c.CartID, "CartCleared", map[string]interface{}{})
	return nil
}
