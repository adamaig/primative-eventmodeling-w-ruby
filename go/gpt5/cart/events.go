package cart

import "gpt5/common"

// Domain events for the cart. Data-only.

type CartCreated struct{ common.Event }

type ItemAdded struct{ common.Event }

type ItemRemoved struct{ common.Event }

type CartCleared struct{ common.Event }

// Factories mirror the Ruby constructors.
func NewCartCreated(aggregateID string) CartCreated {
	return CartCreated{Event: common.NewEvent("CartCreated", aggregateID, 1, nil, nil)}
}

func NewItemAdded(aggregateID string, version int, itemID string) ItemAdded {
	return ItemAdded{Event: common.NewEvent("ItemAdded", aggregateID, version, map[string]interface{}{"item": itemID}, nil)}
}

func NewItemRemoved(aggregateID string, version int, itemID string) ItemRemoved {
	return ItemRemoved{Event: common.NewEvent("ItemRemoved", aggregateID, version, map[string]interface{}{"item": itemID}, nil)}
}

func NewCartCleared(aggregateID string, version int) CartCleared {
	return CartCleared{Event: common.NewEvent("CartCleared", aggregateID, version, nil, nil)}
}
