# frozen_string_literal: true

module SimpleEventModeling
  module Common
    # In-memory event store for event-sourced aggregates.
    #
    # Stores any event object that responds to `aggregate_id` and `version`.
    # See {EventProtocol} for the required interface.
    #
    # @example
    #   event = MyEvent.new(aggregate_id: '123', version: 1)
    #   store = EventStore.new
    #   store.append(event)
    #
    # @see EventProtocol
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
        raise Errors::StreamNotFoundError, aggregate_id unless streams.key?(aggregate_id)

        streams[aggregate_id] || []
      end

      def get_stream_version(aggregate_id)
        get_stream(aggregate_id).last&.version || 0
      end
    end
  end
end
