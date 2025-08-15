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
    it 'should raise an error for a non-existent stream' do
      expect do
        store.get_stream('non_existent')
      end.to raise_error(SimpleEventModeling::Common::Errors::StreamNotFoundError, /Stream non_existent not found/)
    end
    it 'should return the correct stream for an existing aggregate_id' do
      store.append(event)
      store.append(event_2)
      store.append(event_3)

      expect(store.get_stream(stream_1)).to eq([event, event_2])
      expect(store.get_stream(stream_2)).to eq([event_3])
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

    it 'should raise an error for a non-existent stream' do
      expect do
        store.get_stream('non_existent')
      end.to raise_error(SimpleEventModeling::Common::Errors::StreamNotFoundError, /Stream non_existent not found/)
    end
  end
end
