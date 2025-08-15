# frozen_string_literal: true

require 'securerandom'
require 'time'

module SimpleEventModeling
  module Common
    # The Event class provides a common basis for events in this example library. Derived
    # classes may be used for either internal Domain Events or Public Events meant for
    # collaborating with external systems.
    #
    # A DomainEvent is used to track eventsourced state changes for the identified aggregate.
    # The structure is
    # { id:, type:, created_at:, aggregate_id:, version:, data:, metadata:}
    #
    # @!attribute [r] id
    #   @return [String] Unique identifier for the event (UUID).
    # @!attribute [r] type
    #   @return [String] The type of the event.
    # @!attribute [r] created_at
    #   @return [String] Timestamp when the event was created.
    # @!attribute [r] aggregate_id
    #   @return [String] Identifier of the aggregate associated with the event.
    # @!attribute [r] version
    #   @return [Integer] Version number of the event for the aggregate.
    # @!attribute [r] data
    #   @return [Hash] Event-specific data payload.
    # @!attribute [r] metadata
    #   @return [Hash] Additional metadata for the event.
    #
    # @example Creating a new event
    #   event = SimpleEventModeling::Common::Event.new(
    #     type: "UserCreated",
    #     aggregate_id: "user-123",
    #     version: 1,
    #     data: { name: "Alice" },
    #     metadata: { source: "web" }
    #   )
    #
    # @param type [String] The type of the event.
    # @param aggregate_id [String] The aggregate identifier.
    # @param version [Integer] The version of the event.
    # @param data [Hash] The event data payload (default: {}).
    # @param metadata [Hash] The event metadata (default: {}).
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
  end
end
