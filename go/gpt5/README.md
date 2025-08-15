# gpt5 - SimpleEventModeling (Go)

A Go implementation of the SimpleEventModeling Ruby library with the same essential abstractions:

- Commands and Events are simple records with no behaviors
- Aggregates validate commands and append events to the store
- Aggregates hydrate by replaying the event stream

## Packages

- `common`: Event, EventStore (in-memory), Aggregate base, Errors
- `cart`: Commands, Events, Aggregate for a shopping cart

## Quick usage

```go
package main

import (
    "fmt"

    "gpt5/common"
    "gpt5/cart"
)

func main() {
    store := common.NewEventStore()
    agg := cart.NewAggregate(store)

    // Create a cart
    created, _ := agg.Handle(cart.CreateCart{})
    cartID := created.AggregateID

    // Add an item
    _, _ = agg.Handle(cart.AddItem{AggregateID: cartID, ItemID: "sku-1"})

    // Show stream version
    fmt.Println("version:", store.GetStreamVersion(cartID))
}
```
