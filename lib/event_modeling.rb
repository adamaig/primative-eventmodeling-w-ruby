# frozen_string_literal: true

require_relative 'event_modeling/version'
require_relative 'event_modeling/errors'
require_relative 'event_modeling/event'
require_relative 'event_modeling/command'
require_relative 'event_modeling/event_store'

# EventModeling library for educational event-driven architecture patterns.
#
# This module provides a complete EventStore implementation demonstrating
# event sourcing concepts including persistence, retrieval, concurrency control,
# pub/sub subscriptions, and snapshot functionality. It also includes Command
# objects for implementing CQRS (Command Query Responsibility Segregation) patterns.
#
# @example Basic EventStore usage
#   event_store = EventModeling::EventStore.new
#   event = EventModeling::Event.new(type: 'UserCreated', data: { name: 'John' })
#   event_store.append_event('user-123', event.to_h)
#
# @example Traditional hash-based usage (backward compatible)
#   event_store = EventModeling::EventStore.new
#   event = { type: 'UserCreated', data: { name: 'John' } }
#   event_store.append_event('user-123', event)
#
# @example CQRS pattern with Commands and Events
#   # 1. Create a command expressing user intent
#   command = EventModeling::Command.new(
#     type: 'CreateUser',
#     data: { name: 'John', email: 'john@example.com' }
#   )
#
#   # 2. Process command and generate events (business logic)
#   event = { type: 'UserCreated', data: command.data }
#
#   # 3. Store events in EventStore
#   event_store = EventModeling::EventStore.new
#   event_store.append_event('user-123', event)
#
# @example Application-specific Commands through subclassing
#   class CreateUserCommand < EventModeling::Command
#     def initialize(name:, email:)
#       super(type: 'CreateUser', data: { name: name, email: email })
#     end
#   end
#
#   command = CreateUserCommand.new(name: 'John', email: 'john@example.com')
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

  # Convenience method to create a new Command instance
  #
  # @param type [String] the command type identifier
  # @param data [Hash] the command payload data
  # @param command_id [String, nil] unique command identifier (auto-generated if nil)
  # @param created_at [Time, nil] command creation timestamp (auto-generated if nil)
  # @return [Command] new Command instance
  def self.new_command(type:, data:, command_id: nil, created_at: nil)
    Command.new(type: type, data: data, command_id: command_id, created_at: created_at)
  end
end
