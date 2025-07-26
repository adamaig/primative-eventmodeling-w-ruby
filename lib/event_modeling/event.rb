# frozen_string_literal: true

module EventModeling
  # Represents an event in the event store.
  #
  # Events encapsulate the type and data payload, with version and timestamp
  # added automatically by the EventStore when appended.
  #
  # @example Creating an event
  #   event = Event.new(type: 'UserCreated', data: { name: 'John' })
  #
  # @since 1.0.0
  class Event
    attr_reader :type, :data, :version, :timestamp

    # Initialize a new Event instance.
    #
    # @param type [String] the event type identifier
    # @param data [Hash] the event payload data
    # @param version [Integer, nil] event version (set by EventStore)
    # @param timestamp [Time, nil] event timestamp (set by EventStore)
    # @raise [InvalidEventError] if type is not a String or data is not a Hash
    def initialize(type:, data:, version: nil, timestamp: nil)
      raise InvalidEventError, 'Event type must be a String' unless type.is_a?(String)
      raise InvalidEventError, 'Event data must be a Hash' unless data.is_a?(Hash)

      @type = type
      @data = data.dup.freeze
      @version = version
      @timestamp = timestamp
    end

    # Convert event to hash format for storage.
    #
    # @return [Hash] event as hash with symbol keys
    def to_h
      {
        type: @type,
        data: @data,
        version: @version,
        timestamp: @timestamp
      }.compact
    end

    # Create an enhanced copy with version and timestamp.
    #
    # @param version [Integer] the version number to assign
    # @param timestamp [Time] the timestamp to assign (defaults to current time)
    # @return [Event] new Event instance with version and timestamp
    def with_metadata(version:, timestamp: Time.now)
      Event.new(
        type: @type,
        data: @data,
        version: version,
        timestamp: timestamp
      )
    end

    # Check if two events are equal based on type and data.
    #
    # @param other [Event] event to compare with
    # @return [Boolean] true if events have same type and data
    def ==(other)
      return false unless other.is_a?(Event)

      @type == other.type && @data == other.data
    end

    alias eql? ==

    # Generate hash code for use in collections.
    #
    # @return [Integer] hash code based on type and data
    def hash
      [@type, @data].hash
    end

    # String representation of the event.
    #
    # @return [String] formatted event description
    def to_s
      version_info = @version ? " v#{@version}" : ''
      timestamp_info = @timestamp ? " at #{@timestamp}" : ''
      "Event[#{@type}#{version_info}#{timestamp_info}]: #{@data}"
    end

    alias inspect to_s
  end
end
