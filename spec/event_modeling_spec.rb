require 'spec_helper'
require 'time'

describe EventModeling do
  include EventModeling

  describe EventModeling::EventStore do
    it { expect(EventModeling::EventStore).to be_a(Class) }

    let(:event_store) { EventModeling::EventStore.new }
    let(:stream_id) { 'test-stream-123' }
    let(:event) { { type: 'UserCreated', data: { name: 'John' } } }

    describe '#events' do
      it 'returns an empty array' do
        expect(event_store.events).to eq([])
      end
    end

    # Event Persistence
    describe '#append_event' do
      it 'appends a single event to a stream' do
        event_store.append_event(stream_id, event)
        events = event_store.get_events(stream_id)

        expect(events.size).to eq(1)
        expect(events.first[:type]).to eq('UserCreated')
        expect(events.first[:data]).to eq({ name: 'John' })
      end

      it 'appends multiple events to the same stream' do
        event1 = { type: 'UserCreated', data: { name: 'John' } }
        event2 = { type: 'UserUpdated', data: { name: 'Jane' } }

        event_store.append_event(stream_id, event1)
        event_store.append_event(stream_id, event2)

        events = event_store.get_events(stream_id)
        expect(events.size).to eq(2)
        expect(events[0][:type]).to eq('UserCreated')
        expect(events[1][:type]).to eq('UserUpdated')
      end

      it 'assigns sequential version numbers to events' do
        event1 = { type: 'UserCreated', data: { name: 'John' } }
        event2 = { type: 'UserUpdated', data: { name: 'Jane' } }

        event_store.append_event(stream_id, event1)
        event_store.append_event(stream_id, event2)

        events = event_store.get_events(stream_id)
        expect(events[0][:version]).to eq(1)
        expect(events[1][:version]).to eq(2)
      end

      it 'assigns timestamps to events' do
        freeze_time = Time.now
        allow(Time).to receive(:now).and_return(freeze_time)

        event_store.append_event(stream_id, event)
        events = event_store.get_events(stream_id)

        expect(events.first[:timestamp]).to eq(freeze_time)
      end

      it 'handles events in different streams independently' do
        stream1 = 'stream-1'
        stream2 = 'stream-2'
        event1 = { type: 'Event1', data: {} }
        event2 = { type: 'Event2', data: {} }

        event_store.append_event(stream1, event1)
        event_store.append_event(stream2, event2)

        expect(event_store.get_events(stream1).size).to eq(1)
        expect(event_store.get_events(stream2).size).to eq(1)
        expect(event_store.get_events(stream1).first[:type]).to eq('Event1')
        expect(event_store.get_events(stream2).first[:type]).to eq('Event2')
      end
    end

    describe '#append_events' do
      it 'appends multiple events to a stream in a single operation' do
        events = [
          { type: 'UserCreated', data: { name: 'John' } },
          { type: 'UserUpdated', data: { name: 'Jane' } },
          { type: 'UserDeleted', data: {} }
        ]

        event_store.append_events(stream_id, events)
        stored_events = event_store.get_events(stream_id)

        expect(stored_events.size).to eq(3)
        expect(stored_events.map { |e| e[:type] }).to eq(%w[UserCreated UserUpdated UserDeleted])
      end

      it 'assigns sequential version numbers to batch events' do
        events = [
          { type: 'Event1', data: {} },
          { type: 'Event2', data: {} },
          { type: 'Event3', data: {} }
        ]

        event_store.append_events(stream_id, events)
        stored_events = event_store.get_events(stream_id)

        expect(stored_events[0][:version]).to eq(1)
        expect(stored_events[1][:version]).to eq(2)
        expect(stored_events[2][:version]).to eq(3)
      end

      it 'continues version numbering from existing events' do
        # First append a single event
        event_store.append_event(stream_id, { type: 'FirstEvent', data: {} })

        # Then append multiple events
        events = [
          { type: 'SecondEvent', data: {} },
          { type: 'ThirdEvent', data: {} }
        ]
        event_store.append_events(stream_id, events)

        stored_events = event_store.get_events(stream_id)
        expect(stored_events[0][:version]).to eq(1)
        expect(stored_events[1][:version]).to eq(2)
        expect(stored_events[2][:version]).to eq(3)
      end

      it 'handles empty event array' do
        event_store.append_events(stream_id, [])
        events = event_store.get_events(stream_id)

        expect(events).to be_empty
      end

      it 'maintains event order within the batch' do
        events = [
          { type: 'First', data: { order: 1 } },
          { type: 'Second', data: { order: 2 } },
          { type: 'Third', data: { order: 3 } }
        ]

        event_store.append_events(stream_id, events)
        stored_events = event_store.get_events(stream_id)

        expect(stored_events[0][:data][:order]).to eq(1)
        expect(stored_events[1][:data][:order]).to eq(2)
        expect(stored_events[2][:data][:order]).to eq(3)
      end
    end

    describe '#commit' do
      it 'persists pending events'
    end

    # Event Retrieval
    describe '#get_events' do
      it 'gets all events for a specific stream'
      it 'gets events from a specific version'
    end

    describe '#get_events_from_version' do
      it 'gets events from a specific version onwards' do
        # Setup events with versions 1, 2, 3
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })
        event_store.append_event(stream_id, { type: 'Event3', data: {} })

        events = event_store.get_events_from_version(stream_id, 2)

        expect(events.size).to eq(2)
        expect(events[0][:type]).to eq('Event2')
        expect(events[1][:type]).to eq('Event3')
        expect(events[0][:version]).to eq(2)
        expect(events[1][:version]).to eq(3)
      end

      it 'returns all events when version is 1' do
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        events = event_store.get_events_from_version(stream_id, 1)

        expect(events.size).to eq(2)
        expect(events[0][:version]).to eq(1)
        expect(events[1][:version]).to eq(2)
      end

      it 'returns empty array when version is higher than stream' do
        event_store.append_event(stream_id, { type: 'Event1', data: {} })

        events = event_store.get_events_from_version(stream_id, 5)

        expect(events).to be_empty
      end

      it 'returns empty array for non-existent stream' do
        events = event_store.get_events_from_version('non-existent', 1)

        expect(events).to be_empty
      end

      it 'returns all events when version is 0' do
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        events = event_store.get_events_from_version(stream_id, 0)

        expect(events.size).to eq(2)
      end
    end

    describe '#get_all_events' do
      it 'gets all events across all streams' do
        stream1 = 'stream-1'
        stream2 = 'stream-2'

        event_store.append_event(stream1, { type: 'Event1', data: { source: 'stream1' } })
        event_store.append_event(stream2, { type: 'Event2', data: { source: 'stream2' } })
        event_store.append_event(stream1, { type: 'Event3', data: { source: 'stream1' } })

        all_events = event_store.get_all_events

        expect(all_events.size).to eq(3)
        types = all_events.map { |e| e[:type] }
        expect(types).to include('Event1', 'Event2', 'Event3')
      end

      it 'returns events in chronological order by timestamp' do
        stream1 = 'stream-1'
        stream2 = 'stream-2'

        time1 = Time.parse('2025-01-01 10:00:00')
        time2 = Time.parse('2025-01-01 10:01:00')
        time3 = Time.parse('2025-01-01 10:02:00')

        allow(Time).to receive(:now).and_return(time1)
        event_store.append_event(stream1, { type: 'First', data: {} })

        allow(Time).to receive(:now).and_return(time3)
        event_store.append_event(stream2, { type: 'Third', data: {} })

        allow(Time).to receive(:now).and_return(time2)
        event_store.append_event(stream1, { type: 'Second', data: {} })

        all_events = event_store.get_all_events

        expect(all_events.size).to eq(3)
        expect(all_events[0][:type]).to eq('First')
        expect(all_events[1][:type]).to eq('Second')
        expect(all_events[2][:type]).to eq('Third')
      end

      it 'returns empty array when no events exist' do
        all_events = event_store.get_all_events

        expect(all_events).to be_empty
      end

      it 'gets all events from a specific position' do
        stream1 = 'stream-1'
        stream2 = 'stream-2'

        time1 = Time.parse('2025-01-01 10:00:00')
        time2 = Time.parse('2025-01-01 10:01:00')
        time3 = Time.parse('2025-01-01 10:02:00')

        allow(Time).to receive(:now).and_return(time1)
        event_store.append_event(stream1, { type: 'First', data: {} })

        allow(Time).to receive(:now).and_return(time2)
        event_store.append_event(stream2, { type: 'Second', data: {} })

        allow(Time).to receive(:now).and_return(time3)
        event_store.append_event(stream1, { type: 'Third', data: {} })

        events_from_position = event_store.get_all_events(1)

        expect(events_from_position.size).to eq(2)
        expect(events_from_position[0][:type]).to eq('Second')
        expect(events_from_position[1][:type]).to eq('Third')
      end

      it 'handles from_position greater than total events' do
        event_store.append_event(stream_id, { type: 'OnlyEvent', data: {} })

        events = event_store.get_all_events(5)

        expect(events).to be_empty
      end
    end

    # Stream Management
    describe '#stream_exists?' do
      it 'returns true for streams with events' do
        event_store.append_event(stream_id, event)

        expect(event_store.stream_exists?(stream_id)).to be true
      end

      it 'returns false for non-existent streams' do
        expect(event_store.stream_exists?('non-existent-stream')).to be false
      end

      it 'returns true for streams with multiple events' do
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        expect(event_store.stream_exists?(stream_id)).to be true
      end

      it 'returns false for empty stream that was never used' do
        # Create another stream but not the one we're checking
        event_store.append_event('other-stream', event)

        expect(event_store.stream_exists?(stream_id)).to be false
      end

      it 'returns true immediately after first event is appended' do
        expect(event_store.stream_exists?(stream_id)).to be false

        event_store.append_event(stream_id, event)

        expect(event_store.stream_exists?(stream_id)).to be true
      end
    end

    describe '#get_stream_version' do
      it 'returns the current version of a stream' do
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })
        event_store.append_event(stream_id, { type: 'Event3', data: {} })

        version = event_store.get_stream_version(stream_id)

        expect(version).to eq(3)
      end

      it 'returns 0 for non-existent stream' do
        version = event_store.get_stream_version('non-existent-stream')

        expect(version).to eq(0)
      end

      it 'returns 1 after first event is appended' do
        expect(event_store.get_stream_version(stream_id)).to eq(0)

        event_store.append_event(stream_id, event)

        expect(event_store.get_stream_version(stream_id)).to eq(1)
      end

      it 'increments version correctly with multiple appends' do
        expect(event_store.get_stream_version(stream_id)).to eq(0)

        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        expect(event_store.get_stream_version(stream_id)).to eq(1)

        event_store.append_event(stream_id, { type: 'Event2', data: {} })
        expect(event_store.get_stream_version(stream_id)).to eq(2)
      end

      it 'handles batch appends correctly' do
        events = [
          { type: 'Event1', data: {} },
          { type: 'Event2', data: {} },
          { type: 'Event3', data: {} }
        ]

        event_store.append_events(stream_id, events)

        expect(event_store.get_stream_version(stream_id)).to eq(3)
      end

      it 'maintains independent versions across streams' do
        stream1 = 'stream-1'
        stream2 = 'stream-2'

        event_store.append_event(stream1, { type: 'Event1', data: {} })
        event_store.append_event(stream2, { type: 'Event2', data: {} })
        event_store.append_event(stream1, { type: 'Event3', data: {} })

        expect(event_store.get_stream_version(stream1)).to eq(2)
        expect(event_store.get_stream_version(stream2)).to eq(1)
      end
    end

    describe '#delete_stream' do
      it 'marks a stream as deleted'
    end

    # Concurrency Control
    describe '#append_event_with_expected_version' do
      it 'appends event when expected version matches current version' do
        # Setup: append 2 events to get to version 2
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        # Expect version 2, append new event
        new_event = { type: 'Event3', data: { name: 'test' } }
        event_store.append_event_with_expected_version(stream_id, new_event, 2)

        events = event_store.get_events(stream_id)
        expect(events.size).to eq(3)
        expect(events.last[:type]).to eq('Event3')
        expect(events.last[:version]).to eq(3)
      end

      it 'appends event to new stream when expected version is 0' do
        new_event = { type: 'FirstEvent', data: { name: 'initial' } }
        event_store.append_event_with_expected_version(stream_id, new_event, 0)

        events = event_store.get_events(stream_id)
        expect(events.size).to eq(1)
        expect(events.first[:type]).to eq('FirstEvent')
        expect(events.first[:version]).to eq(1)
      end

      it 'raises ConcurrencyError when expected version is lower than current' do
        # Setup: append 2 events to get to version 2
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        # Try to append with expected version 1 (but current is 2)
        new_event = { type: 'Event3', data: {} }

        expect do
          event_store.append_event_with_expected_version(stream_id, new_event, 1)
        end.to raise_error(EventModeling::ConcurrencyError)
      end

      it 'raises ConcurrencyError when expected version is higher than current' do
        # Setup: append 1 event to get to version 1
        event_store.append_event(stream_id, { type: 'Event1', data: {} })

        # Try to append with expected version 5 (but current is 1)
        new_event = { type: 'Event2', data: {} }

        expect do
          event_store.append_event_with_expected_version(stream_id, new_event, 5)
        end.to raise_error(EventModeling::ConcurrencyError)
      end

      it 'raises ConcurrencyError when trying to append to non-existent stream with non-zero version' do
        new_event = { type: 'Event1', data: {} }

        expect do
          event_store.append_event_with_expected_version('non-existent', new_event, 1)
        end.to raise_error(EventModeling::ConcurrencyError)
      end

      it 'includes meaningful error message with current and expected versions' do
        # Setup: append 2 events to get to version 2
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        new_event = { type: 'Event3', data: {} }

        expect do
          event_store.append_event_with_expected_version(stream_id, new_event, 1)
        end.to raise_error(EventModeling::ConcurrencyError, /Expected version 1.*current version is 2/i)
      end

      it 'does not modify stream when concurrency error occurs' do
        # Setup: append 2 events to get to version 2
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        original_events = event_store.get_events(stream_id).dup
        new_event = { type: 'Event3', data: {} }

        expect do
          event_store.append_event_with_expected_version(stream_id, new_event, 1)
        end.to raise_error(EventModeling::ConcurrencyError)

        # Stream should be unchanged
        current_events = event_store.get_events(stream_id)
        expect(current_events).to eq(original_events)
        expect(current_events.size).to eq(2)
      end
    end

    describe '#get_stream_metadata' do
      it 'returns stream metadata including version' do
        # Append events to create metadata
        event_store.append_event(stream_id, { type: 'Event1', data: {} })
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        metadata = event_store.get_stream_metadata(stream_id)

        expect(metadata).to be_a(Hash)
        expect(metadata[:version]).to eq(2)
        expect(metadata[:created_at]).to be_a(Time)
        expect(metadata[:last_event_timestamp]).to be_a(Time)
      end

      it 'returns nil for non-existent streams' do
        metadata = event_store.get_stream_metadata('non-existent-stream')
        expect(metadata).to be_nil
      end

      it 'updates metadata after events are appended' do
        # Append first event
        first_time = Time.now
        allow(Time).to receive(:now).and_return(first_time)
        event_store.append_event(stream_id, { type: 'Event1', data: {} })

        metadata1 = event_store.get_stream_metadata(stream_id)
        expect(metadata1[:version]).to eq(1)
        expect(metadata1[:created_at]).to eq(first_time)
        expect(metadata1[:last_event_timestamp]).to eq(first_time)

        # Append second event with different timestamp
        second_time = first_time + 60 # 1 minute later
        allow(Time).to receive(:now).and_return(second_time)
        event_store.append_event(stream_id, { type: 'Event2', data: {} })

        metadata2 = event_store.get_stream_metadata(stream_id)
        expect(metadata2[:version]).to eq(2)
        expect(metadata2[:created_at]).to eq(first_time) # Created time doesn't change
        expect(metadata2[:last_event_timestamp]).to eq(second_time) # Last event time updates
      end
    end

    # Querying & Projections
    describe '#get_events_by_type' do
      it 'filters events by type' do
        # Setup events across multiple streams with different types
        event_store.append_event('stream1', { type: 'UserCreated', data: { name: 'Alice' } })
        event_store.append_event('stream2', { type: 'OrderPlaced', data: { amount: 100 } })
        event_store.append_event('stream1', { type: 'UserUpdated', data: { name: 'Alice Smith' } })
        event_store.append_event('stream3', { type: 'UserCreated', data: { name: 'Bob' } })
        event_store.append_event('stream2', { type: 'OrderShipped', data: { tracking: '123' } })
        
        user_created_events = event_store.get_events_by_type('UserCreated')
        
        expect(user_created_events.length).to eq(2)
        expect(user_created_events[0][:type]).to eq('UserCreated')
        expect(user_created_events[0][:data][:name]).to eq('Alice')
        expect(user_created_events[1][:type]).to eq('UserCreated')
        expect(user_created_events[1][:data][:name]).to eq('Bob')
      end

      it 'returns events in chronological order' do
        # Use specific timestamps to control order
        first_time = Time.now
        second_time = first_time + 30
        third_time = first_time + 60
        
        allow(Time).to receive(:now).and_return(first_time)
        event_store.append_event('stream1', { type: 'TestEvent', data: { order: 1 } })
        
        allow(Time).to receive(:now).and_return(third_time)
        event_store.append_event('stream2', { type: 'TestEvent', data: { order: 3 } })
        
        allow(Time).to receive(:now).and_return(second_time)
        event_store.append_event('stream3', { type: 'TestEvent', data: { order: 2 } })
        
        events = event_store.get_events_by_type('TestEvent')
        
        expect(events.length).to eq(3)
        expect(events[0][:data][:order]).to eq(1) # First chronologically
        expect(events[1][:data][:order]).to eq(2) # Second chronologically
        expect(events[2][:data][:order]).to eq(3) # Third chronologically
      end

      it 'returns empty array for non-existent types' do
        event_store.append_event('stream1', { type: 'UserCreated', data: {} })
        event_store.append_event('stream2', { type: 'OrderPlaced', data: {} })
        
        events = event_store.get_events_by_type('NonExistentType')
        expect(events).to eq([])
      end

      it 'uses case-sensitive type matching' do
        event_store.append_event('stream1', { type: 'UserCreated', data: {} })
        event_store.append_event('stream2', { type: 'usercreated', data: {} })
        event_store.append_event('stream3', { type: 'USERCREATED', data: {} })
        
        exact_match_events = event_store.get_events_by_type('UserCreated')
        expect(exact_match_events.length).to eq(1)
        expect(exact_match_events[0][:type]).to eq('UserCreated')
        
        lowercase_events = event_store.get_events_by_type('usercreated')
        expect(lowercase_events.length).to eq(1)
        expect(lowercase_events[0][:type]).to eq('usercreated')
        
        uppercase_events = event_store.get_events_by_type('USERCREATED')
        expect(uppercase_events.length).to eq(1)
        expect(uppercase_events[0][:type]).to eq('USERCREATED')
      end

      it 'returns empty array when no events exist' do
        events = event_store.get_events_by_type('AnyType')
        expect(events).to eq([])
      end
    end

    describe '#get_events_in_range' do
      it 'returns events within time range' do
        # Setup events with specific timestamps
        base_time = Time.now
        early_time = base_time - 60    # 1 minute before
        middle_time = base_time        # current time
        late_time = base_time + 60     # 1 minute after
        
        allow(Time).to receive(:now).and_return(early_time)
        event_store.append_event('stream1', { type: 'EarlyEvent', data: {} })
        
        allow(Time).to receive(:now).and_return(middle_time)
        event_store.append_event('stream2', { type: 'MiddleEvent', data: {} })
        
        allow(Time).to receive(:now).and_return(late_time)
        event_store.append_event('stream3', { type: 'LateEvent', data: {} })
        
        # Test inclusive range
        events_in_range = event_store.get_events_in_range(early_time, middle_time)
        
        expect(events_in_range.length).to eq(2)
        expect(events_in_range[0][:type]).to eq('EarlyEvent')
        expect(events_in_range[1][:type]).to eq('MiddleEvent')
      end

      it 'handles edge cases with nil timestamps' do
        base_time = Time.now
        
        allow(Time).to receive(:now).and_return(base_time)
        event_store.append_event('stream1', { type: 'TestEvent', data: {} })
        
        # Nil from_timestamp should include from beginning
        events_from_nil = event_store.get_events_in_range(nil, base_time + 60)
        expect(events_from_nil.length).to eq(1)
        
        # Nil to_timestamp should include to end
        events_to_nil = event_store.get_events_in_range(base_time - 60, nil)
        expect(events_to_nil.length).to eq(1)
        
        # Both nil should return all events
        events_both_nil = event_store.get_events_in_range(nil, nil)
        expect(events_both_nil.length).to eq(1)
      end

      it 'returns empty array for invalid ranges' do
        base_time = Time.now
        
        allow(Time).to receive(:now).and_return(base_time)
        event_store.append_event('stream1', { type: 'TestEvent', data: {} })
        
        # Range where from > to should return empty
        events = event_store.get_events_in_range(base_time + 60, base_time - 60)
        expect(events).to eq([])
        
        # Range that doesn't include any events
        events_before = event_store.get_events_in_range(base_time - 120, base_time - 60)
        expect(events_before).to eq([])
        
        events_after = event_store.get_events_in_range(base_time + 60, base_time + 120)
        expect(events_after).to eq([])
      end

      it 'maintains chronological order' do
        base_time = Time.now
        times = [
          base_time - 60,  # First
          base_time + 60,  # Third  
          base_time,       # Second
          base_time + 120  # Fourth
        ]
        
        times.each_with_index do |time, index|
          allow(Time).to receive(:now).and_return(time)
          event_store.append_event("stream#{index}", { type: 'TestEvent', data: { order: index } })
        end
        
        # Get events in middle range
        events = event_store.get_events_in_range(base_time - 30, base_time + 90)
        
        expect(events.length).to eq(2)
        expect(events[0][:data][:order]).to eq(2) # Second chronologically (base_time)
        expect(events[1][:data][:order]).to eq(1) # Third chronologically (base_time + 60)
      end

      it 'returns empty array when no events exist' do
        base_time = Time.now
        events = event_store.get_events_in_range(base_time - 60, base_time + 60)
        expect(events).to eq([])
      end
    end

    describe '#subscribe_to_stream' do
      it 'sets up real-time subscription to stream'
    end

    # Snapshots (Optional)
    describe '#save_snapshot' do
      it 'stores aggregate snapshot'
    end

    describe '#get_snapshot' do
      it 'retrieves latest snapshot'
    end
  end
end
