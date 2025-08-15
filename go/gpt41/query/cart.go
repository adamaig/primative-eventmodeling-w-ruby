package query

import (
	"../eventstore"
)

// GetCart returns the current state of the cart (list of items).
func GetCart(es *eventstore.EventStore, cartID string) ([]string, error) {
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
