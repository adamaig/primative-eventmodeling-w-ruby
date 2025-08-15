// Package cart provides query objects for projecting cart state from event streams.
// Queries implement the read side of CQRS, creating projections optimized for specific read scenarios.
package cart

import "simple-event-modeling/common"

// CartItemsQuery represents a query for projecting cart state from events.
// This demonstrates the Query side of CQRS (Command Query Responsibility Segregation).
// Unlike the aggregate's internal state, queries can create specialized projections
// optimized for specific read scenarios.
type CartItemsQuery struct {
	AggregateID string
	Store       *common.EventStore
	Projection  *CartProjection
}

// CartProjection represents a read model projection of cart state.
// This can differ from the aggregate's internal representation to optimize for queries.
type CartProjection struct {
	CartID string                   `json:"cart_id"`
	Items  map[string]*CartItemView `json:"items"`
	Totals *CartTotals              `json:"totals"`
}

// CartItemView represents an item in the cart projection.
// This view model can include additional computed fields for display.
type CartItemView struct {
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price,omitempty"` // Could be enriched from product service
	Total    float64 `json:"total,omitempty"` // Computed field
}

// CartTotals represents computed totals for the cart.
type CartTotals struct {
	ItemCount   int     `json:"item_count"`
	TotalAmount float64 `json:"total_amount"`
	TaxAmount   float64 `json:"tax_amount,omitempty"`
	GrandTotal  float64 `json:"grand_total,omitempty"`
}

// NewCartItemsQuery creates a new query for projecting cart state.
func NewCartItemsQuery(aggregateID string, store *common.EventStore) *CartItemsQuery {
	return &CartItemsQuery{
		AggregateID: aggregateID,
		Store:       store,
		Projection: &CartProjection{
			Items:  make(map[string]*CartItemView),
			Totals: &CartTotals{},
		},
	}
}

// Execute runs the query and returns the projected cart state.
// This demonstrates event replay for read model projection.
func (q *CartItemsQuery) Execute() (*CartProjection, error) {
	events, err := q.Store.GetStream(q.AggregateID)
	if err != nil {
		return nil, err
	}

	for _, event := range events {
		if err := q.On(event); err != nil {
			return nil, err
		}
	}

	// Compute derived fields
	q.computeTotals()

	return q.Projection, nil
}

// On applies events to build the projection.
// Note: This is similar to aggregate.On() but builds a different view of the data.
func (q *CartItemsQuery) On(event *common.Event) error {
	switch event.Type {
	case EventTypeCartCreated:
		return q.onCartCreated(event)
	case EventTypeItemAdded:
		return q.onItemAdded(event)
	case EventTypeItemRemoved:
		return q.onItemRemoved(event)
	case EventTypeCartCleared:
		return q.onCartCleared(event)
	default:
		// Queries can choose to ignore unknown events
		return nil
	}
}

// Event handlers for projection building

func (q *CartItemsQuery) onCartCreated(event *common.Event) error {
	q.Projection.CartID = event.AggregateID
	q.Projection.Items = make(map[string]*CartItemView)
	q.Projection.Totals = &CartTotals{}
	return nil
}

func (q *CartItemsQuery) onItemAdded(event *common.Event) error {
	if item, ok := event.Data["item"].(string); ok {
		if q.Projection.Items[item] == nil {
			q.Projection.Items[item] = &CartItemView{
				Quantity: 0,
				Price:    0.0, // Could be enriched from product catalog
			}
		}
		q.Projection.Items[item].Quantity++
	}
	return nil
}

func (q *CartItemsQuery) onItemRemoved(event *common.Event) error {
	if item, ok := event.Data["item"].(string); ok {
		if itemView, exists := q.Projection.Items[item]; exists {
			itemView.Quantity--
			if itemView.Quantity <= 0 {
				delete(q.Projection.Items, item)
			}
		}
	}
	return nil
}

func (q *CartItemsQuery) onCartCleared(event *common.Event) error {
	q.Projection.Items = make(map[string]*CartItemView)
	return nil
}

// computeTotals calculates derived fields for the projection.
// This demonstrates how queries can add computed fields not stored in events.
func (q *CartItemsQuery) computeTotals() {
	itemCount := 0
	totalAmount := 0.0

	for _, item := range q.Projection.Items {
		itemCount += item.Quantity
		item.Total = float64(item.Quantity) * item.Price
		totalAmount += item.Total
	}

	q.Projection.Totals.ItemCount = itemCount
	q.Projection.Totals.TotalAmount = totalAmount
	// Could add tax calculation, discounts, etc.
	q.Projection.Totals.GrandTotal = totalAmount
}
