# frozen_string_literal: true

require 'spec_helper'
require 'pry'

class SomeAggregate
  include Aggregate

  attr_accessor :store

  def initialize(store)
    @store = store
  end
end

describe Scratch do
  include Scratch

  let(:store) { EventStore.new }

  def given_events(events)
    events.each { |event| store.append(event) }
  end

  def when_command(aggregate, command)
    aggregate.handle(command)
  end

  def then_events(events)
    expect(store.events).to match(events)
  end

  describe 'Event' do
    describe '#initialize' do
      it 'should have an id, type, payload, metadata, and timestamp' do
        event = Event.new(type: 'Test',
                          aggregate_id: '123',
                          version: 1,
                          data: { key: 'value' },
                          metadata: { source: 'test' })
        expect(event).to respond_to(:id)
        expect(event).to respond_to(:type)
        expect(event).to respond_to(:created_at)
        expect(event).to respond_to(:aggregate_id)
        expect(event).to respond_to(:version)
        expect(event).to respond_to(:data)
        expect(event).to respond_to(:metadata)
      end
    end
  end

  describe 'EventStore' do
    let(:stream_1) { '1' }
    let(:stream_2) { '2' }
    let(:event) { Event.new(type: 'First', aggregate_id: stream_1, version: 1) }
    let(:event_2) { Event.new(type: 'Second', aggregate_id: stream_1, version: 2) }
    let(:event_3) { Event.new(type: 'Third', aggregate_id: stream_2, version: 1) }

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

  describe 'Aggregate' do
    let(:store) { EventStore.new }
    let(:aggregate_id) { '123' }
    let(:events) do
      [
        Event.new(type: Faker::App.name, aggregate_id: aggregate_id, version: 1),
        Event.new(type: Faker::App.name, aggregate_id: aggregate_id, version: 2),
        Event.new(type: Faker::App.name, aggregate_id: aggregate_id, version: 3),
        Event.new(type: Faker::App.name, aggregate_id: aggregate_id, version: 4)
      ]
    end
    let(:aggregate) { SomeAggregate.new(store) }

    describe '#initialize' do
      it 'should not be live initially' do
        expect(aggregate.isLive?).to eq(false)
      end
    end

    describe '#on' do
      it 'should raise NotImplementedError if the method is not implemented in the base class' do
        expect { aggregate.on(Event.new(type: 'Test', aggregate_id: '123', version: 1)) }
          .to raise_error(NotImplementedError, 'You must implement the on method')
      end
    end

    describe '#handle' do
      it 'should raise NotImplementedError if the method is not implemented in the base class' do
        expect { aggregate.handle({}) }
          .to raise_error(NotImplementedError, 'You must implement the handle method')
      end
    end

    describe '#hydrate' do
      it 'should replay the stream on the aggregate' do
        events.each { |e| store.append(e) }
        allow(aggregate).to receive(:on)
        aggregate.hydrate(id: aggregate_id)
        expect(aggregate).to have_received(:on).exactly(events.length).times
      end
      it 'should set the live state to true after hydration' do
        allow(aggregate).to receive(:on)
        events.each { |e| store.append(e) }

        expect { aggregate.hydrate(id: aggregate_id) }.to change {
          aggregate.isLive?
        }.from(false).to(true)
      end
      it 'should raise an exception if the aggregate is already live' do
        aggregate.hydrate(id: aggregate_id)
        expect { aggregate.hydrate(id: aggregate_id) }.to raise_error(RuntimeError, 'Aggregate is already live')
      end
    end
  end

  describe 'Aggregates::Cart' do
    let(:store) { EventStore.new }
    let(:cart) { Aggregates::Cart.new(store) }
    let(:cart_id) { 'cart-123' }
    let(:item_id) { 'item-456' }
    let(:create_cart_event) { DomainEvents::CartCreated.new(aggregate_id: cart_id) }
    let(:add_item_event) { DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_id) }

    it 'should include Aggregate module' do
      expect(cart).to be_a(Aggregate)
    end

    describe '#initialize' do
      it 'should initialize with an empty item list' do
        expect(cart.items).to eq({})
      end
    end

    describe '#on(event)' do
      it 'should handle CartCreated' do
        cart.on(create_cart_event)
        expect(cart.id).to eq(cart_id)
      end
      it 'should handle ItemAdded' do
        cart.on(add_item_event)
        expect(cart.items).to include(item_id)
      end
    end

    describe '#hydrate(id)' do
      before do
        store.append(create_cart_event)
        store.append(add_item_event)
      end
      it 'should replay all events for the given cart' do
        cart.hydrate(id: cart_id)
        expect(cart.id).to eq(cart_id)
        expect(cart.items).to eq({ item_id => 1 }) # Assuming one item added
        expect(cart.version).to eq(store.get_stream_version(cart.id))
      end
    end

    describe '#handle(command)' do
      context 'when handling CreateCart command' do
        let(:command) { Commands::CreateCart.new }

        it 'should create a cart and return a CartCreated event' do
          result = cart.handle(command)
          expect(result).to be_a(DomainEvents::CartCreated)
          expect(result.aggregate_id).not_to be_nil
          expect(cart.isLive?).to eq(true)
        end
      end

      context 'when handling AddItem command' do
        let(:command) { Commands::AddItem.new(aggregate_id: cart_id, item_id: item_id) }

        it 'should add an item to the cart' do
          store.append(create_cart_event) # Ensure cart exists
          result = cart.handle(command)
          expect(result).to be_a(DomainEvents::ItemAdded)
          expect(cart.items[item_id]).to eq(1)
        end
      end

      context 'when handling an unknown command type' do
        let(:unknown_command) { Commands::Unknown.new(aggregate_id: nil) }

        it 'should raise an error' do
          expect do
            cart.handle(unknown_command)
          end.to raise_error(RuntimeError, "Unknown command type: #{unknown_command.class}")
        end
      end
    end

    describe 'GWTs for Cart' do
      it 'should create a cart if none is specified when adding an item' do
        given_events([])
        when_command(cart, Commands::AddItem.new(nil, item_id))
        then_events([
                      be_a(DomainEvents::CartCreated).and(have_attributes(version: 1)),
                      be_a(DomainEvents::ItemAdded).and(have_attributes(version: 2, data: { item: item_id }))
                    ])
      end

      it 'should error if more than 3 items are added' do
        cart_id = SecureRandom.uuid
        given_events([
                       DomainEvents::CartCreated.new(aggregate_id: cart_id),
                       DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_id),
                       DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_id),
                       DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_id)
                     ])
        expect do
          when_command(cart, Commands::AddItem.new(cart_id, item_id))
        end.to raise_error(InvalidCommandError, /Too many items in cart/)
      end
    end
  end
end
