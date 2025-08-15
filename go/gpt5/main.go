package main

import (
	"fmt"

	"gpt5/cart"
	"gpt5/common"
)

func main() {
	store := common.NewEventStore()
	agg := cart.NewAggregate(store)

	created, _ := agg.Handle(cart.CreateCart{})
	cartID := created.AggregateID

	_, _ = agg.Handle(cart.AddItem{AggregateID: cartID, ItemID: "sku-1"})
	_, _ = agg.Handle(cart.AddItem{AggregateID: cartID, ItemID: "sku-2"})

	fmt.Println("Cart:", cartID, "version:", store.GetStreamVersion(cartID))
}
