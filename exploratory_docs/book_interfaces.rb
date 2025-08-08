# Notes from the EventModeling book

class EventStoreInterface
  # return DomainEventStream
  def read_events(aggregate_id)
  end

  # return DomainEventStream
  def read_events_from_offset(aggregate_id, event_offset)
  end

  protected

  def append_events(events)
  end
end

class AggregateInterface
  # identifies the unique aggregate
  attr_reader :aggregate_id

  # validate transactional business rules
  # If valid command, then apply domain event (internal)
  def handle(command)
  end

  # event-sourcing handler
  # process stream of events to update aggregate
  # apply new event if aggregate has been loaded
  # Note: I think that Axon framework keeps aggregates in memory
  # so for this simple model to work, having a hydrate_from(stream) makes sense
  def on(event)
  end
end

# Internal Domain Events
# A simple data class
class EventInterface
end

# Simple data class
class CommandInterface
  attr_reader :aggregate_id
end

## Axon Models

# Mixin for Aggregates that provide standard lifecycle management
# methods.
module AggregateLifecyle
  attr_reader :live

  def load
    @live = false
    events = event_store.get_stream(aggregate_id)
    events.each do |event|
      on(event)
    end
    @live = true
  end

  def isLive?
    @live
  end

  def apply(event)
    on(event)
    event_store.appent(event)
  end

  def markDeleted!
    self.deleted = true
    apply(DeletedDomainEvent.new(self))
  end
end

class Message
  attr_accessor :message_id, :payload, :metadata

  def initialize(payload:, metadata:)
    @message_id = SecureRandom.uuid
    @payload = payload
    @metadata = metadata
  end
end

# Events are objects that describe something that has occurred in the application.
#
class EventMessage < Message
  attr_accessor :created_at

  def initialize(payload:, metadata:)
    super(payload, metadata)
    @created_at = Time.now
  end
end

# Represents a change in state of the generating Aggregate.
#
# When something important has occurred within the aggregate, it will raise an event...When an event is raised by an aggregate, it is wrapped in a DomainEventMessage (which extends EventMessage).
# Although domain events technically indicate a state change, you should try to capture the intention of the state in the event, too. A good practice is to use an abstract implementation of a domain event to capture the fact that certain state has changed, and use a concrete sub-implementation of that abstract class that indicates the intention of the change. For example, you could have an abstract AddressChangedEvent, and two implementations ContactMovedEvent and AddressCorrectedEvent that capture the intent of the state change.
class DomainEventMessage < EventMessage
  attr_accessor :aggregate_id, :aggregate_type, :sequence_position

  def initialize(aggregate, payload, metadata)
    super(payload, metadata)
    @aggregate_id = aggregate.id
    @aggregate_type = aggregate.class.public_constant
    @sequence_position = aggregate.sequence_position
  end
end

# Commands describe an intent to change the application’s state.
#
# Commands always have exactly one destination.
# While the sender does not care which component handles the command or where that component resides, it may be interesting knowing the outcome of it.
# That is why command messages sent over the command bus allow for a result to be returned.
class CommandMessage < Message
end

# Query messages are used to retrieve information from the system.
# They are typically sent to a query bus, which routes them to the appropriate query handler.
# The QueryMessage carries, besides Payload and Meta Data, a description of the type of response that the requesting component expects.
class QueryMessage < Message
  attr_accessor :response_type

  def initialize(payload:, metadata:, response_type:)
    super()
    @payload = payload
    @metadata = metadata
    @response_type = response_type
  end
end
