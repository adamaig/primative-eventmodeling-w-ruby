# frozen_string_literal: true

require 'simple_event_modeling/common/event'
require 'simple_event_modeling/common/event_protocol'
require 'simple_event_modeling/common/event_store'

module SimpleEventModeling
  # This module holds common abstractions and implementations for an EventModeling-based application.
  # It includes foundational components such as Events, EventStores, Aggregates and their Lifecycle,
  # as well as Commands, Queries, and Protocols.
  #
  # @see SimpleEventModeling::Common
  # @note Intended to be extended with shared logic for event-driven architectures.
  module Common
  end
end
