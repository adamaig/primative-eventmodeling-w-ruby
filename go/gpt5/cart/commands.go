package cart

// Commands are simple records with no behavior.

type CreateCart struct{ AggregateID string }

type AddItem struct {
	AggregateID string
	ItemID      string
}

type RemoveItem struct {
	AggregateID string
	ItemID      string
}

type ClearCart struct{ AggregateID string }
