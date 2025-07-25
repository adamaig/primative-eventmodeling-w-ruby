require 'spec_helper'

describe EventModeling do
  include EventModeling

  describe EventModeling::EventStore do
    it { expect(EventModeling::EventStore).to be_a(Class) }

    let(:event_store) { EventModeling::EventStore.new }

    describe '#events' do
      it 'returns an empty array' do
        expect(event_store.events).to eq([])
      end
    end
  end
end
