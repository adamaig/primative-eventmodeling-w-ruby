# Axon Notes

## Aggregates

Commands that target aggregates contain a reference to this identifier. Axon Framework will load the events for the aggregate with this identifier, replay the events on an empty instance, and invoke the command. This is how the aggregate’s state is reconstructed to support Event-Sourcing.

The aggregate identifier has to be globally unique in your event store. This means that events are loaded based only on the identifier, and nothing else. 

Note that commands that construct a new aggregate (via a constructor) do not need an identifier. However, your @AggregateIdentifier field needs to have a value after the first command

### Structure 
An Aggregate is a regular Java object, which contains state and methods to alter that state

### EventSourcingHandler
Using the @EventSourcingHandler is what tells the framework that the annotated function should be called when the Aggregate is 'sourced from its events'. As all the Event Sourcing Handlers combined will form the Aggregate, this is where all the state changes happen. Note that the Aggregate Identifier must be set in the @EventSourcingHandler of the first Event published by the aggregate. This is usually the creation event. Lastly, @EventSourcingHandler annotated functions are resolved using specific rules. These rules are the same for the @EventHandler annotated methods, and are thoroughly explained in Annotated Event Handler.

A no-arg constructor, which is required by Axon. Axon Framework uses this constructor to create an empty aggregate instance before initializing it using past Events. Failure to provide this constructor will result in an exception when loading the Aggregate.

### AggregateLifecycle

The AggregateLifecycle#apply(Object) will go through a number of steps:

1. The current scope of the Aggregate is retrieved.
1. The last known sequence number of the Aggregate is used to set the sequence number of the event to publish.
1. The provided Event payload, the Object, will be wrapped in an EventMessage. The EventMessage will also receive the sequenceNumber from the previous step, as well as the Aggregate its identifier.
1. The Event Message will be published from here on. The event will first be sent to all the Event Handlers in the Aggregate which are interested. This is necessary for Event Sourcing, to update the Aggregate’s state accordingly.
1. After the Aggregate itself has handled the event, it will be published on the EventBus.

The static AggregateLifecycle#apply(Object…​) is what is used when an Event Message should be published. Upon calling this function the provided `Object`s will be published as `EventMessage`s within the scope of the Aggregate they are applied in.

### Aggregate lifecycle operations
There are a couple of operations which are desirable to be performed whilst in the life cycle of an Aggregate. To that end, the AggregateLifecycle class in Axon provides a couple of static functions:

 - apply(Object) and apply(Object, MetaData): The AggregateLifecycle#apply will publish an Event message on an EventBus such that it is known to have originated from the Aggregate executing the operation. There is the possibility to provide just the Event Object or both the Event and some specific MetaData.
- createNew(Class, Callable): Instantiate a new Aggregate as a result of handling a Command. Read this for more details on this.
- isLive(): Check to verify whether the Aggregate is in a 'live' state. An Aggregate is regarded to be 'live' if it has finished replaying historic events to recreate it’s state. If the Aggregate is thus in the process of being event sourced, an AggregateLifecycle.isLive() call would return false. Using this isLive() method, you can perform activity that should only be done when handling newly generated events.
- markDeleted(): Will mark the Aggregate instance calling the function as being 'deleted'. Useful if the domain specifies a given Aggregate can be removed/deleted/closed, after which it should no longer be allowed to handle any Commands. This function should be called from an @EventSourcingHandler annotated function to ensure that being marked deleted is part of that Aggregate’s state.

## Messages

[ref](https://docs.axoniq.io/axon-framework-reference/4.11/messaging-concepts)
A Message consists of a Payload, which is an application-specific object that represents the actual functional message, and Meta Data, which is a key-value pair describing the context of the message

### Commands
Commands describe an intent to change the application’s state. They are implemented as (preferably read-only) POJOs that are wrapped using one of the CommandMessage implementations.

Commands always have exactly one destination. While the sender does not care which component handles the command or where that component resides, it may be interesting knowing the outcome of it. That is why command messages sent over the command bus allow for a result to be returned.

### Events 
Events are objects that describe something that has occurred in the application. A typical source of events is the aggregate. When something important has occurred within the aggregate, it will raise an event...When an event is raised by an aggregate, it is wrapped in a DomainEventMessage (which extends EventMessage). All other events are wrapped in an EventMessage. Aside from common Message attributes like the unique Identifier an EventMessage also contains a timestamp. The DomainEventMessage additionally contains the type and identifier of the aggregate that raised the event. It also contains the sequence number of the event in the aggregate’s event stream, which allows the order of events to be reproduced.

Although domain events technically indicate a state change, you should try to capture the intention of the state in the event, too. A good practice is to use an abstract implementation of a domain event to capture the fact that certain state has changed, and use a concrete sub-implementation of that abstract class that indicates the intention of the change. For example, you could have an abstract AddressChangedEvent, and two implementations ContactMovedEvent and AddressCorrectedEvent that capture the intent of the state change.

An EventMessage (an interface extending Message) also provides a timestamp, representing the time at which the event was generated.

### Queries
Queries describe a request for information or state. A query can have multiple handlers. When dispatching queries, the client indicates whether he wants a result from one or from all available query handlers.

The QueryMessage carries, besides Payload and Meta Data, a description of the type of response that the requesting component expects.
