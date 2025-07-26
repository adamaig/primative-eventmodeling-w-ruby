# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventModeling::Event do
  let(:event_type) { 'UserCreated' }
  let(:event_data) { { name: 'John', email: 'john@example.com' } }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates an event with type and data' do
        event = described_class.new(type: event_type, data: event_data)

        expect(event.type).to eq(event_type)
        expect(event.data).to eq(event_data)
        expect(event.version).to be_nil
        expect(event.timestamp).to be_nil
      end

      it 'creates an event with version and timestamp' do
        version = 1
        timestamp = Time.now
        event = described_class.new(type: event_type, data: event_data, version: version, timestamp: timestamp)

        expect(event.type).to eq(event_type)
        expect(event.data).to eq(event_data)
        expect(event.version).to eq(version)
        expect(event.timestamp).to eq(timestamp)
      end

      it 'freezes the data to prevent modification' do
        event = described_class.new(type: event_type, data: event_data)

        expect(event.data).to be_frozen
        expect { event.data[:name] = 'Jane' }.to raise_error(FrozenError)
      end

      it 'creates a copy of data to prevent external modification' do
        original_data = { name: 'John', email: 'john@example.com' }
        event = described_class.new(type: event_type, data: original_data)

        original_data[:name] = 'Jane'
        original_data[:email] = 'jane@example.com'

        expect(event.data[:name]).to eq('John')
        expect(event.data[:email]).to eq('john@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'raises InvalidEventError for non-string type' do
        expect do
          described_class.new(type: 123, data: event_data)
        end.to raise_error(EventModeling::InvalidEventError, 'Event type must be a String')
      end

      it 'raises InvalidEventError for nil type' do
        expect do
          described_class.new(type: nil, data: event_data)
        end.to raise_error(EventModeling::InvalidEventError, 'Event type must be a String')
      end

      it 'raises InvalidEventError for non-hash data' do
        expect do
          described_class.new(type: event_type, data: 'invalid')
        end.to raise_error(EventModeling::InvalidEventError, 'Event data must be a Hash')
      end

      it 'raises InvalidEventError for nil data' do
        expect do
          described_class.new(type: event_type, data: nil)
        end.to raise_error(EventModeling::InvalidEventError, 'Event data must be a Hash')
      end

      it 'allows empty hash as data' do
        expect do
          described_class.new(type: event_type, data: {})
        end.not_to raise_error
      end
    end
  end

  describe '#to_h' do
    context 'without metadata' do
      it 'converts event to hash format excluding nil values' do
        event = described_class.new(type: event_type, data: event_data)
        hash = event.to_h

        expect(hash).to eq({
                             type: event_type,
                             data: event_data
                           })
      end
    end

    context 'with metadata' do
      it 'includes version and timestamp when present' do
        version = 1
        timestamp = Time.now
        event = described_class.new(type: event_type, data: event_data, version: version, timestamp: timestamp)
        hash = event.to_h

        expect(hash).to eq({
                             type: event_type,
                             data: event_data,
                             version: version,
                             timestamp: timestamp
                           })
      end

      it 'includes only version when timestamp is nil' do
        version = 1
        event = described_class.new(type: event_type, data: event_data, version: version)
        hash = event.to_h

        expect(hash).to eq({
                             type: event_type,
                             data: event_data,
                             version: version
                           })
      end
    end
  end

  describe '#with_metadata' do
    let(:event) { described_class.new(type: event_type, data: event_data) }

    it 'creates a new event with version and timestamp' do
      version = 1
      timestamp = Time.now
      enhanced = event.with_metadata(version: version, timestamp: timestamp)

      expect(enhanced).to be_a(described_class)
      expect(enhanced).not_to equal(event) # Different object references
      expect(enhanced.type).to eq(event_type)
      expect(enhanced.data).to eq(event_data)
      expect(enhanced.version).to eq(version)
      expect(enhanced.timestamp).to eq(timestamp)
    end

    it 'uses current time as default timestamp' do
      version = 1
      freeze_time = Time.now

      allow(Time).to receive(:now).and_return(freeze_time)
      enhanced = event.with_metadata(version: version)

      expect(enhanced.timestamp).to eq(freeze_time)
    end

    it 'does not modify the original event' do
      version = 1
      timestamp = Time.now
      event.with_metadata(version: version, timestamp: timestamp)

      expect(event.version).to be_nil
      expect(event.timestamp).to be_nil
    end
  end

  describe '#==' do
    let(:event1) { described_class.new(type: event_type, data: event_data) }
    let(:event2) { described_class.new(type: event_type, data: event_data) }
    let(:different_type) { described_class.new(type: 'UserUpdated', data: event_data) }
    let(:different_data) { described_class.new(type: event_type, data: { name: 'Jane' }) }

    it 'returns true for events with same type and data' do
      expect(event1).to eq(event2)
    end

    it 'returns false for events with different types' do
      expect(event1).not_to eq(different_type)
    end

    it 'returns false for events with different data' do
      expect(event1).not_to eq(different_data)
    end

    it 'ignores version and timestamp in equality comparison' do
      enhanced1 = event1.with_metadata(version: 1, timestamp: Time.now)
      enhanced2 = event2.with_metadata(version: 2, timestamp: Time.now + 60)

      expect(enhanced1).to eq(enhanced2)
    end

    it 'returns false when comparing with non-Event objects' do
      expect(event1).not_to eq({ type: event_type, data: event_data })
      expect(event1).not_to eq('not an event')
      expect(event1).not_to eq(nil)
    end
  end

  describe '#eql?' do
    it 'behaves the same as ==' do
      event1 = described_class.new(type: event_type, data: event_data)
      event2 = described_class.new(type: event_type, data: event_data)

      expect(event1.eql?(event2)).to eq(event1 == event2)
    end
  end

  describe '#hash' do
    it 'returns same hash for equal events' do
      event1 = described_class.new(type: event_type, data: event_data)
      event2 = described_class.new(type: event_type, data: event_data)

      expect(event1.hash).to eq(event2.hash)
    end

    it 'returns different hash for different events' do
      event1 = described_class.new(type: event_type, data: event_data)
      event2 = described_class.new(type: 'UserUpdated', data: event_data)

      expect(event1.hash).not_to eq(event2.hash)
    end

    it 'allows events to be used as hash keys' do
      event1 = described_class.new(type: event_type, data: event_data)
      event2 = described_class.new(type: event_type, data: event_data)

      hash = { event1 => 'value1' }
      hash[event2] = 'value2'

      expect(hash.size).to eq(1) # Same event, so overwrites
      expect(hash[event1]).to eq('value2')
    end
  end

  describe '#to_s' do
    context 'without metadata' do
      it 'returns formatted string representation' do
        event = described_class.new(type: event_type, data: event_data)
        expected = "Event[#{event_type}]: #{event_data}"

        expect(event.to_s).to eq(expected)
      end
    end

    context 'with version only' do
      it 'includes version in string representation' do
        event = described_class.new(type: event_type, data: event_data, version: 1)
        expected = "Event[#{event_type} v1]: #{event_data}"

        expect(event.to_s).to eq(expected)
      end
    end

    context 'with version and timestamp' do
      it 'includes both version and timestamp' do
        timestamp = Time.new(2025, 7, 26, 12, 30, 45)
        event = described_class.new(type: event_type, data: event_data, version: 1, timestamp: timestamp)
        expected = "Event[#{event_type} v1 at #{timestamp}]: #{event_data}"

        expect(event.to_s).to eq(expected)
      end
    end

    context 'with timestamp only' do
      it 'includes only timestamp when version is nil' do
        timestamp = Time.new(2025, 7, 26, 12, 30, 45)
        event = described_class.new(type: event_type, data: event_data, timestamp: timestamp)
        expected = "Event[#{event_type} at #{timestamp}]: #{event_data}"

        expect(event.to_s).to eq(expected)
      end
    end
  end

  describe '#inspect' do
    it 'behaves the same as to_s' do
      event = described_class.new(type: event_type, data: event_data, version: 1)

      expect(event.inspect).to eq(event.to_s)
    end
  end
end
