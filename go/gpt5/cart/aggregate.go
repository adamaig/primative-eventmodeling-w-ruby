package cart

import (
	"errors"

	"gpt5/common"

	"github.com/google/uuid"
)

// Aggregate implements command validation and emits events.
type Aggregate struct {
	common.BaseAggregate
	items map[string]int
}

func NewAggregate(store *common.EventStore) *Aggregate {
	agg := &Aggregate{BaseAggregate: common.NewBaseAggregate(store), items: map[string]int{}}
	return agg
}

// On applies an event to mutate state.
func (a *Aggregate) On(e common.Event) error {
	switch e.Type {
	case "CartCreated":
		// Set aggregate ID on creation
		a.BaseAggregate.SetID(e.AggregateID)
		a.BaseAggregate.SetVersion(e.Version)
		a.BaseAggregate.SetLive(true)
		return nil
	case "ItemAdded":
		item, _ := e.Data["item"].(string)
		a.items[item]++
		a.BaseAggregate.SetVersion(e.Version)
		return nil
	case "ItemRemoved":
		item, _ := e.Data["item"].(string)
		if a.items[item] > 0 {
			a.items[item]--
			if a.items[item] == 0 {
				delete(a.items, item)
			}
		}
		a.BaseAggregate.SetVersion(e.Version)
		return nil
	case "CartCleared":
		a.items = map[string]int{}
		a.BaseAggregate.SetVersion(e.Version)
		return nil
	default:
		return errors.New("unhandled event type")
	}
}

// Hydrate loads state by replaying events for aggregateID.
func (a *Aggregate) Hydrate(id string) error {
	return a.BaseAggregate.HydrateWith(id, a.On)
}

// Handle processes commands and appends events when valid.
func (a *Aggregate) Handle(cmd any) (common.Event, error) {
	switch c := cmd.(type) {
	case CreateCart:
		// Always generate a new cart id (matches Ruby behavior)
		id := uuid.NewString()
		// first event version always 1
		ev := NewCartCreated(id).Event
		// set internal id via On
		if err := a.On(ev); err != nil {
			return common.Event{}, err
		}
		a.Store().Append(ev)
		return ev, nil
	case AddItem:
		if c.ItemID == "" {
			return common.Event{}, &common.InvalidCommandError{Message: "item id required"}
		}
		// If no aggregate id provided and aggregate not initialized, create cart first
		if c.AggregateID == "" && a.BaseAggregate.ID() == "" {
			newID := uuid.NewString()
			created := NewCartCreated(newID).Event
			if err := a.On(created); err != nil {
				return common.Event{}, err
			}
			a.Store().Append(created)
		} else if a.BaseAggregate.ID() == "" { // lazy hydrate if not live
			if err := a.Hydrate(c.AggregateID); err != nil {
				return common.Event{}, err
			}
			a.BaseAggregate.SetID(c.AggregateID)
		}
		// validation: max 3 total items
		total := 0
		for _, n := range a.items {
			total += n
		}
		if total >= 3 {
			return common.Event{}, &common.InvalidCommandError{Message: "Too many items in cart"}
		}
		ver := a.Version() + 1
		ev := NewItemAdded(a.BaseAggregate.ID(), ver, c.ItemID).Event
		if err := a.On(ev); err != nil {
			return common.Event{}, err
		}
		a.Store().Append(ev)
		return ev, nil
	case RemoveItem:
		if c.AggregateID == "" {
			return common.Event{}, &common.InvalidCommandError{Message: "aggregate id required"}
		}
		if a.BaseAggregate.ID() == "" {
			if err := a.Hydrate(c.AggregateID); err != nil {
				return common.Event{}, err
			}
			a.BaseAggregate.SetID(c.AggregateID)
		}
		if _, ok := a.items[c.ItemID]; !ok {
			return common.Event{}, &common.InvalidCommandError{Message: "Item is not in the cart"}
		}
		ver := a.Version() + 1
		ev := NewItemRemoved(a.BaseAggregate.ID(), ver, c.ItemID).Event
		if err := a.On(ev); err != nil {
			return common.Event{}, err
		}
		a.Store().Append(ev)
		return ev, nil
	case ClearCart:
		if c.AggregateID == "" {
			return common.Event{}, &common.InvalidCommandError{Message: "aggregate id required"}
		}
		if a.BaseAggregate.ID() == "" {
			if err := a.Hydrate(c.AggregateID); err != nil {
				return common.Event{}, err
			}
			a.BaseAggregate.SetID(c.AggregateID)
		}
		ver := a.Version() + 1
		ev := NewCartCleared(a.BaseAggregate.ID(), ver).Event
		if err := a.On(ev); err != nil {
			return common.Event{}, err
		}
		a.Store().Append(ev)
		return ev, nil
	default:
		return common.Event{}, &common.InvalidCommandError{Message: "unknown command"}
	}
}
