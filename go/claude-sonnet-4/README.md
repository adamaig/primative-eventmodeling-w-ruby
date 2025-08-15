# SimpleEventModeling - Go Implementation

A Go implementation of the SimpleEventModeling library, demonstrating event-driven architecture patterns using EventStore concepts. This implementation preserves the essential ideas of the Ruby version:

- **Commands and Events are simple records with no behaviors**
- **Aggregates handle command validation and append events to the store if commands are valid**  
- **Aggregates hydrate by replaying the relevant event stream**

## Architecture Overview

### Core Components

#### Common Package (`common/`)
- **Event**: Simple record structure containing event data (ID, Type, CreatedAt, AggregateID, Version, Data, Metadata)
- **EventStore**: In-memory event persistence with stream management
- **BaseAggregate**: Foundation for event-sourced aggregates with hydration and lifecycle management
- **Errors**: Custom error types for the event modeling system

#### Cart Package (`cart/`)
- **Commands**: Simple structs representing user intents (CreateCart, AddItem, RemoveItem, ClearCart)
- **Events**: Factory functions for domain events (CartCreated, ItemAdded, ItemRemoved, CartCleared)
- **CartAggregate**: Event-sourced shopping cart implementation

## Key Design Principles

### 1. Commands and Events as Simple Records
```go
// Command - no behavior, just data
type AddItemCommand struct {
    AggregateID string
    ItemID      string
}

// Event creation - factory function returns simple Event struct
func NewItemAddedEvent(aggregateID string, version int, itemID string) *common.Event {
    data := map[string]interface{}{"item": itemID}
    return common.NewEvent(EventTypeItemAdded, aggregateID, version, data, nil)
}
```

### 2. Aggregates Handle Command Validation
```go
func (ca *CartAggregate) Handle(command interface{}) (*common.Event, error) {
    // Hydrate from event stream
    if err := ca.Hydrate(aggregateID); err != nil {
        return nil, err
    }
    
    // Validate command and business rules
    if totalItems >= 3 {
        return nil, &common.InvalidCommandError{Message: "too many items in cart"}
    }
    
    // Create and apply event
    event := NewItemAddedEvent(ca.ID(), ca.Version()+1, cmd.ItemID)
    ca.On(event)
    ca.Store().Append(event)
    return event, nil
}
```

### 3. Event Replay for Aggregate Hydration
```go
func (ca *CartAggregate) Hydrate(id string) error {
    return ca.BaseAggregate.Hydrate(id, ca.On)
}

func (ca *CartAggregate) On(event *common.Event) error {
    switch event.Type {
    case EventTypeItemAdded:
        return ca.onItemAdded(event)
    // ... other event handlers
    }
}
```

## Usage Example

```go
// Create event store and cart aggregate
store := common.NewEventStore()
cart := cart.NewCartAggregate(store)

// Create cart
createCmd := &cart.CreateCartCommand{}
event, err := cart.Handle(createCmd)

// Add items
addCmd := &cart.AddItemCommand{
    AggregateID: event.AggregateID,
    ItemID:      "item-1",
}
cart.Handle(addCmd)

// Event replay - create new aggregate and hydrate
newCart := cart.NewCartAggregate(store)
newCart.Hydrate(event.AggregateID)  // Replays all events
```

## Running the Demo

```bash
# Run the main demo
go run main.go

# Run tests
go test ./...

# Run with verbose output
go test -v ./...
```

## Project Structure

```
go/claude-sonnet-4/
├── go.mod                 # Go module definition
├── main.go               # Demo application
├── README.md             # This file
├── common/
│   ├── common.go         # Core event modeling types and interfaces
│   └── common_test.go    # Tests for common package
└── cart/
    ├── cart.go           # Cart domain implementation  
    └── cart_test.go      # Tests for cart package
```

## Key Features Demonstrated

### Event Sourcing
- Events are the source of truth
- Aggregate state is derived from events
- Complete audit trail of all changes

### Command-Query Responsibility Segregation (CQRS)
- Commands modify state (write side)
- Queries read current state (read side)
- Clear separation of concerns

### Domain-Driven Design
- Rich domain model with business rules
- Aggregates enforce invariants
- Events represent business-meaningful occurrences

### Business Rules Enforcement
- Maximum 3 items per cart
- Cannot remove items not in cart
- Proper command validation

## Comparison with Ruby Implementation

This Go implementation maintains the same conceptual structure as the Ruby version:

| Aspect | Ruby | Go |
|--------|------|----| 
| Commands | `Struct.new(:field)` | `struct { Field string }` |
| Events | Classes inheriting from `Event` | Factory functions returning `*Event` |
| Aggregates | Modules with `include Aggregate` | Structs embedding `*BaseAggregate` |
| Event Store | Class with hash storage | Struct with map storage |
| Error Handling | Custom exception classes | Custom error types |

The Go version emphasizes:
- **Type safety** through Go's static typing
- **Explicit error handling** with Go's error interface
- **Composition over inheritance** using struct embedding
- **Interface-based design** for extensibility

## Testing

Comprehensive tests cover:
- Event creation and storage
- Aggregate command handling
- Event replay and hydration
- Business rule validation
- Error conditions
- State transitions

Run tests with: `go test -v ./...`
