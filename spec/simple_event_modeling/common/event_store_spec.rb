# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleEventModeling::Common::EventStore do
  let(:store) { described_class.new }
  let(:stream_1) { '1' }
  let(:stream_2) { '2' }

  # Minimal event class for testing EventStore.
  # Implements the EventProtocol: must respond to :aggregate_id and :version.
  let(:event_class) do
    Struct.new(:aggregate_id, :version)
  end

  let(:event) { event_class.new(stream_1, 1) }
  let(:event_2) { event_class.new(stream_1, 2) }
  let(:event_3) { event_class.new(stream_2, 1) }

  describe '#append' do
    it 'should append events to the store' do
      expect { store.append(event) }.to change {
        store.events.length
      }.from(0).to(1)
    end

    it 'should store events in the correct stream' do
      store.append(event)
      store.append(event_2)
      store.append(event_3)

      expect(store.get_stream(stream_1).length).to eq(2)
      expect(store.get_stream(stream_2).length).to eq(1)
    end
  end

  describe '#get_stream' do
    it 'should return an empty stream for a non-existent aggregate_id' do
      expect(store.get_stream('non_existent')).to eq([])
    end
  end

  describe '#get_stream_version' do
    it 'should return the last version for an existing aggregate_id' do
      store.append(event)
      store.append(event_2)
      store.append(event_3)

      expect(store.get_stream_version(stream_1)).to eq(2)
      expect(store.get_stream_version(stream_2)).to eq(1)
    end

    it 'should return 0 for a non-existent aggregate_id' do
      expect(store.get_stream_version('non_existent')).to eq(0)
    end
  end
end
