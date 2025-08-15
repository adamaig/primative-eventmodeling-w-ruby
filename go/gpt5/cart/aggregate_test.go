package cart_test

import (
	"testing"

	"gpt5/cart"
	"gpt5/common"
)

func TestCartAggregate_CreateCart(t *testing.T) {
	es := common.NewEventStore()
	agg := cart.NewAggregate(es)
	ev, err := agg.Handle(cart.CreateCart{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ev.Type != "CartCreated" {
		t.Fatalf("expected CartCreated, got %s", ev.Type)
	}
	if ev.AggregateID == "" {
		t.Fatal("expected aggregate id to be set")
	}
	if !agg.IsLive() {
		t.Fatal("expected aggregate to be live after create")
	}
}

func TestCartAggregate_AddItem(t *testing.T) {
	es := common.NewEventStore()
	agg := cart.NewAggregate(es)
	created, _ := agg.Handle(cart.CreateCart{})
	id := created.AggregateID
	added, err := agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-1"})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if added.Type != "ItemAdded" {
		t.Fatalf("expected ItemAdded, got %s", added.Type)
	}
	if es.GetStreamVersion(id) != 2 {
		t.Fatalf("expected version 2, got %d", es.GetStreamVersion(id))
	}
}

func TestCartAggregate_RemoveItem_Validation(t *testing.T) {
	es := common.NewEventStore()
	agg := cart.NewAggregate(es)
	created, _ := agg.Handle(cart.CreateCart{})
	id := created.AggregateID
	_, _ = agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-1"})
	_, _ = agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-1"})
	_, _ = agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-2"})
	if _, err := agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-3"}); err == nil {
		t.Fatal("expected error for too many items")
	}
}

func TestCartAggregate_ClearCart(t *testing.T) {
	es := common.NewEventStore()
	agg := cart.NewAggregate(es)
	created, _ := agg.Handle(cart.CreateCart{})
	id := created.AggregateID
	_, _ = agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-1"})
	_, _ = agg.Handle(cart.AddItem{AggregateID: id, ItemID: "sku-2"})
	cleared, err := agg.Handle(cart.ClearCart{AggregateID: id})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cleared.Type != "CartCleared" {
		t.Fatalf("expected CartCleared, got %s", cleared.Type)
	}
}
