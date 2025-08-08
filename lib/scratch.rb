# frozen_string_literal: true

module Scratch
end

require 'securerandom'
require 'time'

# A DomainEvent is used to track eventsourced state changes for the identified aggregate.
# The structure is
# { id:, type:, created_at:, aggregate_id:, version:, data:, metadata:}
# Represents a domain event
class Event
  attr_reader :id, :type, :created_at, :aggregate_id, :version, :data, :metadata

  def initialize(type:, aggregate_id:, version:, data: {}, metadata: {})
    @id = SecureRandom.uuid
    @type = type
    @created_at = DateTime.now.to_s
    @aggregate_id = aggregate_id
    @version = version
    @data = data
    @metadata = metadata
  end
end

# Event Persistence
#
# Stores all events as an append only log.
# Supports registering for listeners to specific topic streams.
# Supports registering listeners to specific event types.
class EventStore
  attr_reader :events, :streams

  def initialize
    @events = []
    @streams = {}
  end

  def append(event)
    aggregate_id = event.aggregate_id
    streams[aggregate_id] ||= []
    stream = streams[aggregate_id]

    events << event
    stream << event
    event
  end

  def get_stream(aggregate_id)
    streams[aggregate_id] || []
  end

  def get_stream_version(aggregate_id)
    get_stream(aggregate_id).last&.version || 0
  end
end

module DomainEvents; end

class DomainEvents::CartCreated < Event
  def initialize(aggregate_id:)
    super(type: self.class, aggregate_id: aggregate_id, version: 1)
  end
end

class DomainEvents::ItemAdded < Event
  def initialize(aggregate_id:, version:, item_id:)
    super(type: self.class, aggregate_id: aggregate_id, version: version, data: { item: item_id })
  end
end

module Commands
  Unknown = Struct.new(:aggregate_id)
  CreateCart = Struct.new(:aggregate_id)
  AddItem = Struct.new(:aggregate_id, :item_id)
end

module Aggregate
  attr_accessor :live

  def self.included(base)
    base.class_eval do
      attr_accessor :id, :version, :live, :store
    end
  end

  def initialize(store)
    @store = store
    @live = false
  end

  def isLive?
    @live ||= false
    @live
  end

  def on(event)
    raise NotImplementedError, 'You must implement the on method'
  end

  def handle(command)
    raise NotImplementedError, 'You must implement the handle method'
  end

  def hydrate(id:)
    raise 'Aggregate is already live' if isLive?

    # hydrate aggregate based on id
    events = store.get_stream(id)
    events.each do |event|
      on(event)
    end
    # mark the aggregate as live
    @live = true
  end
end

module Aggregates
  class Cart
    # include AggregateLifecyle implementation
    include Aggregate

    attr_reader :items

    def initialize(store)
      super(store)
      @items = {}
    end

    def handle(command)
      hydrate(id: command.aggregate_id)

      case command
      when Commands::CreateCart
        handle_create_cart_command
      when Commands::AddItem
        handle_add_item_command(command)
      else
        raise "Unknown command type: #{command.class}"
      end
    end

    def on(event)
      case event
      when DomainEvents::CartCreated
        on_cart_created(event)
      when DomainEvents::ItemAdded
        on_add_item(event)
      end
      @version = event.version
    end

    def on_cart_created(event)
      @id = event.aggregate_id
    end

    def on_add_item(event)
      @items[event.data[:item]] ||= 0
      @items[event.data[:item]] += 1
    end

    def handle_create_cart_command
      # validate
      cart_id = SecureRandom.uuid
      # create event
      event = DomainEvents::CartCreated.new(aggregate_id: cart_id)
      # update aggregate state
      on(event)
      # update stream
      store.append(event)
      event
    end

    def handle_add_item_command(command)
      # validate
      raise 'Cart not initialized' unless @id

      item_id = command.item_id
      # create event
      event = DomainEvents::ItemAdded.new(aggregate_id: @id, version: @version + 1, item_id: item_id)
      # update aggregate state
      on(event)
      # update stream
      store.append(event)
      event
    end
  end
end

class CartApp
  attr_reader :store

  def initialize(store)
    @store = store
  end

  def handle(command)
    aggregate = Aggregates::Cart.new
    aggregate.handle(command)
  end

  def handle_create_cart_command(command)
    cart_id = SecureRandom.uuid
    event = Event.new(type: Event::CartCreated, aggregate_id: cart_id, data: { aggregate_id: cart_id })

    result_event = store.append(event)

    DomainEvents::CartCreated.new(
      cart_id: cart_id,
      version: result_event.version,
      success?: true
    )
  end

  def handle_add_item_command(command)
    event = Event.new(type: Event::ItemAdded, aggregate_id: command.cart_id, data: { item_id: command.item_id })

    result_event = store.append(event)

    DomainEvents::ItemAdded.new(
      cart_id: command.cart_id,
      data: { items: [] },
      success?: true
    )
  end
end
