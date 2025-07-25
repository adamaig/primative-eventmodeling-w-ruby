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
      it 'appends event when expected version matches'
      it 'raises error when expected version does not match'
    end

    describe '#get_stream_metadata' do
      it 'returns stream metadata including version'
    end

    # Querying & Projections
    describe '#get_events_by_type' do
      it 'filters events by type'
    end

    describe '#get_events_in_range' do
      it 'returns events within time range'
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
