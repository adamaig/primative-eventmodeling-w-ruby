# frozen_string_literal: true

# This file is part of the EventModeling library.
# It defines the EventStore class and its methods.
module EventModeling
  # Custom error for concurrency conflicts when expected version doesn't match current version
  class ConcurrencyError < StandardError; end

  # EventStore class to manage events in an in-memory event sourcing system.
  # 
  # This class provides a complete EventStore implementation for educational purposes,
  # demonstrating event-driven architecture patterns including event persistence,
  # retrieval, stream management, concurrency control, querying, pub/sub subscriptions,
  # and snapshot functionality.
  #
  # All events are stored in memory only and are lost when the application terminates.
  # Events are automatically enhanced with version numbers and timestamps.
  #
  # @example Basic usage
  #   event_store = EventStore.new
  #   event = { type: 'UserCreated', data: { name: 'John' } }
  #   event_store.append_event('user-123', event)
  #   events = event_store.get_events('user-123')
  #
  # @example With subscriptions
  #   event_store.subscribe_to_stream('user-123') do |event|
  #     puts "New event: #{event[:type]}"
  #   end
  #   event_store.append_event('user-123', event)  # triggers subscriber
  #
  # @since 1.0.0
  class EventStore
    # Initialize a new EventStore instance.
    # 
    # Creates empty storage for streams, subscriptions, and snapshots.
    # All data is stored in memory and will be lost when the instance is destroyed.
    def initialize
      @streams = {}
    end

    # Returns an empty array for backward compatibility.
    # 
    # @return [Array] empty array
    # @deprecated This method exists for compatibility but returns empty array
    def events
      []
    end

    # Appends a single event to the specified stream.
    # 
    # The event will be automatically enhanced with a sequential version number
    # starting from 1 and a timestamp. Subscribers to the stream will be notified.
    # If the stream doesn't exist, it will be created automatically.
    #
    # @param stream_id [String] unique identifier for the stream
    # @param event [Hash] event data containing :type and :data keys
    # @option event [String] :type the event type identifier
    # @option event [Hash] :data the event payload data
    # @return [void]
    # @raise [ArgumentError] if event is not a Hash or missing required keys
    #
    # @example Append a user creation event
    #   event = { type: 'UserCreated', data: { name: 'John', email: 'john@example.com' } }
    #   event_store.append_event('user-123', event)
    def append_event(stream_id, event)
      @streams[stream_id] ||= []

      enhanced_event = event.dup
      enhanced_event[:version] = @streams[stream_id].length + 1
      enhanced_event[:timestamp] = Time.now

      @streams[stream_id] << enhanced_event
      notify_subscribers(stream_id, enhanced_event)
    end

    # Appends multiple events to the specified stream in a single operation.
    # 
    # All events will be enhanced with sequential version numbers and timestamps.
    # Version numbers continue from the current stream version. Subscribers will
    # be notified for each event in the batch.
    #
    # @param stream_id [String] unique identifier for the stream
    # @param events [Array<Hash>] array of events to append
    # @return [void]
    # @raise [ArgumentError] if events is not an Array
    #
    # @example Append multiple events
    #   events = [
    #     { type: 'UserCreated', data: { name: 'John' } },
    #     { type: 'UserUpdated', data: { name: 'Jane' } }
    #   ]
    #   event_store.append_events('user-123', events)
    def append_events(stream_id, events)
      return if events.empty?

      @streams[stream_id] ||= []
      current_version = @streams[stream_id].length

      events.each_with_index do |event, index|
        enhanced_event = event.dup
        enhanced_event[:version] = current_version + index + 1
        enhanced_event[:timestamp] = Time.now

        @streams[stream_id] << enhanced_event
        notify_subscribers(stream_id, enhanced_event)
      end
    end

    # Retrieves all events for the specified stream.
    # 
    # Events are returned in the order they were appended, with version numbers
    # starting from 1. Each event includes the original data plus version and timestamp.
    #
    # @param stream_id [String] unique identifier for the stream
    # @return [Array<Hash>] array of events in append order, empty if stream doesn't exist
    #
    # @example Get all events from a stream
    #   events = event_store.get_events('user-123')
    #   events.each { |event| puts "#{event[:version]}: #{event[:type]}" }
    def get_events(stream_id)
      @streams[stream_id] || []
    end

    # Retrieves events from the specified stream starting from a specific version.
    # 
    # Returns all events with version number greater than or equal to the specified version.
    # If version is 1 or less, returns all events. Useful for rebuilding state from a
    # specific point in time.
    #
    # @param stream_id [String] unique identifier for the stream
    # @param version [Integer] minimum version number to include (inclusive)
    # @return [Array<Hash>] array of events from the specified version onwards
    #
    # @example Get events from version 5 onwards
    #   events = event_store.get_events_from_version('user-123', 5)
    def get_events_from_version(stream_id, version)
      stream_events = @streams[stream_id] || []
      return stream_events if version <= 1

      stream_events.select { |event| event[:version] >= version }
    end

    # Retrieves all events across all streams in chronological order.
    # 
    # Events are sorted by their timestamp to provide a global chronological view.
    # Optionally skip a number of events from the beginning using from_position.
    #
    # @param from_position [Integer] number of events to skip from the beginning (default: 0)
    # @return [Array<Hash>] array of all events sorted by timestamp
    #
    # @example Get all events across all streams
    #   all_events = event_store.get_all_events
    #
    # @example Get events starting from position 10
    #   recent_events = event_store.get_all_events(10)
    def get_all_events(from_position = 0)
      all_events = @streams.values.flatten
      chronological_events = all_events.sort_by { |event| event[:timestamp] }

      return chronological_events if from_position <= 0

      chronological_events.drop(from_position)
    end

    # Checks if the specified stream exists and contains events.
    # 
    # A stream is considered to exist if it has been created and contains at least one event.
    # Streams are created automatically when the first event is appended.
    #
    # @param stream_id [String] unique identifier for the stream
    # @return [Boolean] true if stream exists and has events, false otherwise
    #
    # @example Check if a stream exists
    #   if event_store.stream_exists?('user-123')
    #     puts "Stream has events"
    #   end
    def stream_exists?(stream_id)
      @streams.key?(stream_id) && !@streams[stream_id].empty?
    end

    # Gets the current version (number of events) for the specified stream.
    # 
    # Version numbers start from 1 for the first event. Returns 0 for non-existent
    # or empty streams. The version represents the total number of events in the stream.
    #
    # @param stream_id [String] unique identifier for the stream
    # @return [Integer] current version number (0 if stream doesn't exist)
    #
    # @example Get stream version
    #   version = event_store.get_stream_version('user-123')
    #   puts "Stream has #{version} events"
    def get_stream_version(stream_id)
      return 0 unless @streams.key?(stream_id)

      @streams[stream_id].length
    end

    # Appends an event to a stream with concurrency control using expected version.
    # 
    # This method provides optimistic concurrency control by requiring the caller
    # to specify the expected current version. If the actual version doesn't match,
    # a ConcurrencyError is raised, indicating another process has modified the stream.
    #
    # @param stream_id [String] unique identifier for the stream
    # @param event [Hash] event data to append
    # @param expected_version [Integer] expected current version of the stream
    # @return [void]
    # @raise [ConcurrencyError] if expected_version doesn't match current version
    #
    # @example Append with concurrency control
    #   current_version = event_store.get_stream_version('user-123')
    #   event_store.append_event_with_expected_version('user-123', event, current_version)
    def append_event_with_expected_version(stream_id, event, expected_version)
      current_version = get_stream_version(stream_id)

      if current_version != expected_version
        raise ConcurrencyError,
              "Expected version #{expected_version}, but current version is #{current_version} for stream '#{stream_id}'"
      end

      append_event(stream_id, event)
    end

    # Gets metadata about the specified stream.
    # 
    # Returns information including current version, creation timestamp, and
    # last event timestamp. Useful for monitoring and diagnostics.
    #
    # @param stream_id [String] unique identifier for the stream
    # @return [Hash, nil] metadata hash with :version, :created_at, :last_event_timestamp keys, or nil if stream doesn't exist
    #
    # @example Get stream metadata
    #   metadata = event_store.get_stream_metadata('user-123')
    #   puts "Version: #{metadata[:version]}, Created: #{metadata[:created_at]}"
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

    # Retrieves all events of a specific type across all streams.
    # 
    # Filters events by exact type matching (case-sensitive) and returns them
    # in chronological order by timestamp. Useful for building projections
    # or finding all occurrences of a particular event type.
    #
    # @param event_type [String] the event type to filter by
    # @return [Array<Hash>] array of events matching the type, sorted chronologically
    #
    # @example Get all user creation events
    #   user_events = event_store.get_events_by_type('UserCreated')
    def get_events_by_type(event_type)
      all_events = get_all_events
      all_events.select { |event| event[:type] == event_type }
    end

    # Retrieves events within a specific time range across all streams.
    # 
    # Filters events by timestamp, supporting inclusive range queries.
    # Either boundary can be nil to create open-ended ranges.
    # Results are returned in chronological order.
    #
    # @param from_timestamp [Time, nil] start of time range (inclusive), nil for no lower bound
    # @param to_timestamp [Time, nil] end of time range (inclusive), nil for no upper bound
    # @return [Array<Hash>] array of events within the time range, sorted chronologically
    #
    # @example Get events from last hour
    #   one_hour_ago = Time.now - 3600
    #   recent_events = event_store.get_events_in_range(one_hour_ago, nil)
    def get_events_in_range(from_timestamp, to_timestamp)
      all_events = get_all_events

      all_events.select do |event|
        event_time = event[:timestamp]

        # Handle nil timestamps
        from_condition = from_timestamp.nil? || event_time >= from_timestamp
        to_condition = to_timestamp.nil? || event_time <= to_timestamp

        from_condition && to_condition
      end
    end

    # Commits pending events to storage.
    # 
    # In this in-memory implementation, events are immediately persisted when appended,
    # so this method is a no-op provided for compatibility with transaction-based
    # EventStore implementations. Always returns true to indicate success.
    #
    # @return [Boolean] always returns true indicating successful commit
    #
    # @example Commit changes (no-op in this implementation)
    #   event_store.append_event('stream', event)
    #   event_store.commit  # returns true, but no actual work needed
    def commit
      # In-memory implementation - events are immediately persisted
      # This method is a no-op for compatibility with transaction-based EventStores
      true
    end

    # Deletes a stream and all its events.
    # 
    # Completely removes the stream from storage. After deletion, the stream
    # will not exist and get_stream_version will return 0. This operation
    # cannot be undone. Handles non-existent streams gracefully.
    #
    # @param stream_id [String] unique identifier for the stream to delete
    # @return [Array, nil] the deleted events array, or nil if stream didn't exist
    #
    # @example Delete a stream
    #   event_store.delete_stream('user-123')
    #   puts event_store.stream_exists?('user-123')  # => false
    def delete_stream(stream_id)
      @streams.delete(stream_id)
    end

    # Subscribes a callback to receive real-time notifications for new events in a stream.
    # 
    # The callback will be invoked immediately when events are appended to the specified
    # stream. Multiple subscribers can be registered for the same stream. Subscribers
    # only receive events for their specific stream, not global events.
    #
    # @param stream_id [String] unique identifier for the stream to subscribe to
    # @param callback [Proc, #call] callback that will receive new events
    # @yieldparam event [Hash] the newly appended event with version and timestamp
    # @return [void]
    #
    # @example Subscribe to stream events
    #   event_store.subscribe_to_stream('user-123') do |event|
    #     puts "New event: #{event[:type]} at version #{event[:version]}"
    #   end
    def subscribe_to_stream(stream_id, callback)
      @subscriptions ||= {}
      @subscriptions[stream_id] ||= []
      @subscriptions[stream_id] << callback
    end

    # Saves a snapshot of aggregate state for the specified stream.
    # 
    # Snapshots provide a performance optimization by storing the computed state
    # at a specific version, allowing faster state reconstruction. New snapshots
    # overwrite previous ones for the same stream. The snapshot includes the
    # provided data, version, and current timestamp.
    #
    # @param stream_id [String] unique identifier for the stream
    # @param snapshot_data [Object] the aggregate state data to store
    # @param version [Integer] the stream version this snapshot represents
    # @return [void]
    #
    # @example Save user aggregate snapshot
    #   user_state = { id: 123, name: 'John', email: 'john@example.com' }
    #   current_version = event_store.get_stream_version('user-123')
    #   event_store.save_snapshot('user-123', user_state, current_version)
    def save_snapshot(stream_id, snapshot_data, version)
      @snapshots ||= {}
      @snapshots[stream_id] = {
        data: snapshot_data,
        version: version,
        timestamp: Time.now
      }
    end

    # Retrieves the latest snapshot for the specified stream.
    # 
    # Returns the most recently saved snapshot containing the aggregate state data,
    # version, and timestamp. Used for optimizing state reconstruction by starting
    # from a known state rather than replaying all events from the beginning.
    #
    # @param stream_id [String] unique identifier for the stream
    # @return [Hash, nil] snapshot hash with :data, :version, :timestamp keys, or nil if no snapshot exists
    #
    # @example Get latest snapshot
    #   snapshot = event_store.get_snapshot('user-123')
    #   if snapshot
    #     puts "Snapshot from version #{snapshot[:version]}: #{snapshot[:data]}"
    #   end
    def get_snapshot(stream_id)
      @snapshots&.dig(stream_id)
    end

    private

    # Notifies all subscribers for a stream about a new event.
    # 
    # Calls each registered callback for the specified stream, passing the
    # new event as an argument. Handles errors gracefully to prevent one
    # failing subscriber from affecting others.
    #
    # @param stream_id [String] the stream that received the new event
    # @param event [Hash] the newly appended event to broadcast
    # @return [void]
    # @api private
    def notify_subscribers(stream_id, event)
      return unless @subscriptions&.key?(stream_id)

      @subscriptions[stream_id].each do |callback|
        callback.call(event)
      end
    end
  end
end
