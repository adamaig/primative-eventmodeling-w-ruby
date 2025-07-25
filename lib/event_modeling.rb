# frozen_string_literal: true

# This file is part of the EventModeling library.
# It defines the EventStore class and its methods.
module EventModeling
  # EventStore class to manage events
  class EventStore
    def initialize
      @streams = {}
    end

    def events
      []
    end

    def append_event(stream_id, event)
      @streams[stream_id] ||= []

      enhanced_event = event.dup
      enhanced_event[:version] = @streams[stream_id].length + 1
      enhanced_event[:timestamp] = Time.now

      @streams[stream_id] << enhanced_event
    end

    def append_events(stream_id, events)
      return if events.empty?

      @streams[stream_id] ||= []
      current_version = @streams[stream_id].length

      events.each_with_index do |event, index|
        enhanced_event = event.dup
        enhanced_event[:version] = current_version + index + 1
        enhanced_event[:timestamp] = Time.now

        @streams[stream_id] << enhanced_event
      end
    end

    def get_events(stream_id)
      @streams[stream_id] || []
    end
  end
end
