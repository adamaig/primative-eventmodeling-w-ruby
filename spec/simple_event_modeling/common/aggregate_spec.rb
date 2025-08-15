# frozen_string_literal: true

require 'spec_helper'

class TestAggregate
  include SimpleEventModeling::Common::Aggregate
  def on(event); end
  def handle(command); end
end

RSpec.describe SimpleEventModeling::Common::Aggregate do
  let(:store) { SimpleEventModeling::Common::EventStore.new }
  let(:aggregate_id) { '123' }

  let(:aggregate) { TestAggregate.new(store) }

  describe '#initialize' do
    it 'should not be live initially' do
      expect(aggregate.isLive?).to eq(false)
    end
  end

  describe '#on' do
    it 'should raise NotImplementedError if not implemented in base class' do
      agg = Class.new { include SimpleEventModeling::Common::Aggregate }.new(store)
      expect { agg.on(:event) }.to raise_error(NotImplementedError, 'You must implement the on method')
    end
  end

  describe '#handle' do
    it 'should raise NotImplementedError if not implemented in base class' do
      agg = Class.new { include SimpleEventModeling::Common::Aggregate }.new(store)
      expect { agg.handle(:command) }.to raise_error(NotImplementedError, 'You must implement the handle method')
    end
  end

  describe '#hydrate' do
    it 'should replay the stream on the aggregate' do
      events = [double(:event), double(:event), double(:event)]
      allow(store).to receive(:get_stream).with(aggregate_id).and_return(events)
      allow(aggregate).to receive(:on)
      aggregate.hydrate(id: aggregate_id)
      expect(aggregate).to have_received(:on).exactly(events.length).times
    end

    it 'should set the live state to true after hydration' do
      allow(store).to receive(:get_stream).and_return([])
      expect { aggregate.hydrate(id: aggregate_id) }.to change { aggregate.isLive? }.from(false).to(true)
    end

    it 'should raise an exception if the aggregate is already live' do
      allow(store).to receive(:get_stream).and_return([])
      aggregate.hydrate(id: aggregate_id)
      expect { aggregate.hydrate(id: aggregate_id) }.to raise_error(RuntimeError, 'Aggregate is already live')
    end
  end
end
