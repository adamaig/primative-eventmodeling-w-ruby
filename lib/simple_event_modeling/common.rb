# frozen_string_literal: true

require 'simple_event_modeling/common/aggregate'
require 'simple_event_modeling/common/errors'
require 'simple_event_modeling/common/event'
require 'simple_event_modeling/common/event_protocol'
require 'simple_event_modeling/common/event_store'

module SimpleEventModeling
  # This file serves as a namespace for common components in the SimpleEventModeling framework.
  # It includes the Event, EventStore, Aggregate, and EventProtocol modules, which provide the
  # foundational building blocks for event-sourced applications.
  #
  # The Common module is designed to be extended with additional shared logic and utilities
  # that can be used across different parts of an event-driven architecture.
  #
  # @see SimpleEventModeling::Common::Aggregate
  # @see SimpleEventModeling::Common::Event
  # @see SimpleEventModeling::Common::EventStore
  # @see SimpleEventModeling::Common::EventProtocol
  # @note Intended to be extended with shared logic for event-driven architectures.
  module Common
  end
end
