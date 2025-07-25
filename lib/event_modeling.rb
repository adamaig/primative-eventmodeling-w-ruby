# frozen_string_literal: true

# This file is part of the EventModeling library.
# It defines the EventStore class and its methods.
module EventModeling
  # Custom error for concurrency conflicts
  class ConcurrencyError < StandardError; end

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

    def get_events_from_version(stream_id, version)
      stream_events = @streams[stream_id] || []
      return stream_events if version <= 1

      stream_events.select { |event| event[:version] >= version }
    end

    def get_all_events(from_position = 0)
      all_events = @streams.values.flatten
      chronological_events = all_events.sort_by { |event| event[:timestamp] }

      return chronological_events if from_position <= 0

      chronological_events.drop(from_position)
    end

    def stream_exists?(stream_id)
      @streams.key?(stream_id) && !@streams[stream_id].empty?
    end

    def get_stream_version(stream_id)
      return 0 unless @streams.key?(stream_id)

      @streams[stream_id].length
    end

    def append_event_with_expected_version(stream_id, event, expected_version)
      current_version = get_stream_version(stream_id)

      if current_version != expected_version
        raise ConcurrencyError,
              "Expected version #{expected_version}, but current version is #{current_version} for stream '#{stream_id}'"
      end

      append_event(stream_id, event)
    end

    def get_stream_metadata(stream_id)
      return nil unless @streams.key?(stream_id) && !@streams[stream_id].empty?

      events = @streams[stream_id]
      first_event = events.first
      last_event = events.last

      {
        version: events.length,
        created_at: first_event[:timestamp],
        last_event_timestamp: last_event[:timestamp]
      }
    end

    def get_events_by_type(event_type)
      all_events = get_all_events
      all_events.select { |event| event[:type] == event_type }
    end
  end
end
