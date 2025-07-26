# frozen_string_literal: true

require_relative 'event_modeling/version'
require_relative 'event_modeling/errors'
require_relative 'event_modeling/event'
require_relative 'event_modeling/event_store'

# EventModeling library for educational event-driven architecture patterns.
#
# This module provides a complete EventStore implementation demonstrating
# event sourcing concepts including persistence, retrieval, concurrency control,
# pub/sub subscriptions, and snapshot functionality.
#
# @example Basic usage
#   event_store = EventModeling::EventStore.new
#   event = EventModeling::Event.new(type: 'UserCreated', data: { name: 'John' })
#   event_store.append_event('user-123', event.to_h)
#
# @example Traditional hash-based usage (backward compatible)
#   event_store = EventModeling::EventStore.new
#   event = { type: 'UserCreated', data: { name: 'John' } }
#   event_store.append_event('user-123', event)
#
# @since 1.0.0
module EventModeling
  # Convenience method to create a new EventStore instance
  #
  # @return [EventStore] new EventStore instance
  def self.new_event_store
    EventStore.new
  end

  # Convenience method to create a new Event instance
  #
  # @param type [String] the event type identifier
  # @param data [Hash] the event payload data
  # @return [Event] new Event instance
  def self.new_event(type:, data:)
    Event.new(type: type, data: data)
  end
end
