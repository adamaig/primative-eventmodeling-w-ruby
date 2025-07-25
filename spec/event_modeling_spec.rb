require 'spec_helper'

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

        expect(events).to have(1).item
        expect(events.first[:type]).to eq('UserCreated')
        expect(events.first[:data]).to eq({ name: 'John' })
      end

      it 'appends multiple events to the same stream' do
        event1 = { type: 'UserCreated', data: { name: 'John' } }
        event2 = { type: 'UserUpdated', data: { name: 'Jane' } }

        event_store.append_event(stream_id, event1)
        event_store.append_event(stream_id, event2)

        events = event_store.get_events(stream_id)
        expect(events).to have(2).items
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

        expect(event_store.get_events(stream1)).to have(1).item
        expect(event_store.get_events(stream2)).to have(1).item
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

        expect(stored_events).to have(3).items
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
      it 'gets events from a specific version onwards'
    end

    describe '#get_all_events' do
      it 'gets all events across all streams'
      it 'gets all events from a specific position'
    end

    # Stream Management
    describe '#stream_exists?' do
      it 'returns true if stream exists'
      it 'returns false if stream does not exist'
    end

    describe '#get_stream_version' do
      it 'returns the current version of a stream'
      it 'returns 0 for non-existent stream'
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
