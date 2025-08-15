# SimpleEventModeling - Go Implementation

A Go implementation of the SimpleEventModeling library, demonstrating event-driven architecture patterns using EventStore concepts. This implementation preserves the essential ideas of the Ruby version:

- **Commands and Events are simple records with no behaviors**
- **Aggregates handle command validation and append events to the store if commands are valid**  
- **Aggregates hydrate by replaying the relevant event stream**

## Architecture Overview

### Package Organization

The library is organized with clear separation of concerns, with each major concept in its own dedicated file:

#### Common Package (`common/`)
- **`common.go`**: Package documentation and overview
- **`errors.go`**: Error types and constants (`InvalidCommandError`, `StreamNotFoundError`)
- **`event.go`**: Event struct and creation functions
- **`event_store.go`**: EventStore implementation for in-memory persistence
- **`aggregate.go`**: Aggregate interface and BaseAggregate implementation

#### Cart Package (`cart/`)
- **`cart.go`**: Package documentation and domain overview
- **`commands.go`**: Command types (CreateCart, AddItem, RemoveItem, ClearCart)
- **`events.go`**: Event factory functions and constants
- **`aggregate.go`**: CartAggregate implementation with business logic

### Core Components

#### Event System
- **Event**: Simple record structure containing event data (ID, Type, CreatedAt, AggregateID, Version, Data, Metadata)
- **EventStore**: In-memory event persistence with stream management and retrieval
- **Event Types**: Domain-specific events created via factory functions

#### Aggregate System  
- **BaseAggregate**: Foundation for event-sourced aggregates with hydration and lifecycle management
- **CartAggregate**: Event-sourced shopping cart implementation demonstrating business rules
- **Command Handling**: Validation and event generation based on business logic

#### Error Handling
- **Custom Error Types**: Domain-specific errors for validation and system states
- **Explicit Error Handling**: Go's error interface for clear error propagation

## Key Design Principles

### 1. Commands and Events as Simple Records
```go
// Command - no behavior, just data (in commands.go)
type AddItemCommand struct {
    AggregateID string
    ItemID      string
}

// Event creation - factory function returns simple Event struct (in events.go)
func NewItemAddedEvent(aggregateID string, version int, itemID string) *common.Event {
    data := map[string]interface{}{"item": itemID}
    return common.NewEvent(EventTypeItemAdded, aggregateID, version, data, nil)
}
```

### 2. Aggregates Handle Command Validation
```go
// CartAggregate implementation (in aggregate.go)
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
// BaseAggregate hydration (in common/aggregate.go)
func (ca *CartAggregate) Hydrate(id string) error {
    return ca.BaseAggregate.Hydrate(id, ca.On)
}

// Event handling (in cart/aggregate.go)
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
├── go.mod                    # Go module definition
├── main.go                   # Basic demo application
├── README.md                 # This documentation
├── common/                   # Core framework package
│   ├── common.go             # Package documentation
│   ├── errors.go             # Error types and constants
│   ├── event.go              # Event struct and creation
│   ├── event_store.go        # EventStore implementation
│   ├── aggregate.go          # Aggregate interface and base
│   └── common_test.go        # Framework tests
├── cart/                     # Cart domain package
│   ├── cart.go               # Package documentation
│   ├── commands.go           # Command types
│   ├── events.go             # Event factory functions
│   ├── aggregate.go          # CartAggregate implementation
│   ├── cart_test.go          # Domain tests
│   └── cart_bench_test.go    # Performance benchmarks
└── examples/
    └── advanced_demo.go      # Advanced usage examples
```

### File Organization Benefits

- **Single Responsibility**: Each file focuses on one specific concept
- **Better Maintainability**: Changes to one concept don't affect others  
- **Improved Readability**: Smaller, focused files (20-80 lines vs 200-300)
- **Enhanced Documentation**: Targeted documentation for each concept
- **Team Collaboration**: Multiple developers can work on different concepts
- **Easier Testing**: Concepts can be tested and understood in isolation

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

Comprehensive tests cover all aspects of the library:

### Test Coverage by Package
- **Common Package**: Event creation, EventStore functionality, BaseAggregate lifecycle
- **Cart Package**: Command handling, business rules, event replay, error conditions
- **Integration Tests**: End-to-end workflows and state transitions
- **Performance Tests**: Benchmarks for command processing and event replay

### Test Organization
```
common/common_test.go    # Framework component tests
cart/cart_test.go        # Domain logic and business rule tests  
cart/cart_bench_test.go  # Performance benchmarks
```

### Running Tests
```bash
# Run all tests
go test -v ./...

# Run specific package tests
go test -v ./common
go test -v ./cart

# Run with benchmarks
go test -bench=. ./cart
```

### Test Categories
- **Unit Tests**: Individual component functionality
- **Integration Tests**: Aggregate command handling and event replay
- **Business Rule Tests**: Domain-specific validation logic
- **Error Condition Tests**: Invalid commands and edge cases
- **Performance Tests**: Operation throughput and memory usage
