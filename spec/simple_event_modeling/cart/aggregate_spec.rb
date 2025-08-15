# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleEventModeling::Cart::Aggregate do # rubocop:disable Metrics/BlockLength
  # Shortened namespace for cart events and commands
  let(:cart_event) { SimpleEventModeling::Cart::DomainEvents }
  let(:cart_command) { SimpleEventModeling::Cart::Commands }

  let(:store) { SimpleEventModeling::Common::EventStore.new }
  let(:cart) { described_class.new(store) }
  let(:cart_id) { 'cart-123' }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }
  let(:create_cart_event) { cart_event::CartCreated.new(aggregate_id: cart_id) }
  let(:add_item_event) { cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id) }

  it 'should include Aggregate module' do
    expect(cart).to be_a(SimpleEventModeling::Common::Aggregate)
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
      expect(cart.items).to include(item_1_id)
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
      expect(cart.items).to eq({ item_1_id => 1 })
      expect(cart.version).to eq(store.get_stream_version(cart.id))
    end
  end

  describe '#handle(command)' do
    context 'when handling CreateCart command' do
      let(:command) { cart_command::CreateCart.new }

      it 'should create a cart and return a CartCreated event' do
        result = cart.handle(command)
        expect(result).to be_a(cart_event::CartCreated)
        expect(result.aggregate_id).not_to be_nil
        expect(cart.isLive?).to eq(true)
      end
    end

    context 'when handling AddItem command' do
      let(:command) { cart_command::AddItem.new(aggregate_id: cart_id, item_id: item_1_id) }

      it 'should add an item to the cart' do
        store.append(create_cart_event)
        result = cart.handle(command)
        expect(result).to be_a(cart_event::ItemAdded)
        expect(cart.items[item_1_id]).to eq(1)
      end
    end

    context 'when handling RemoveItem command' do
      let(:command) { cart_command::RemoveItem.new(aggregate_id: cart_id, item_id: item_1_id) }

      before do
        store.append(create_cart_event)
        store.append(add_item_event)
      end

      it 'should remove an item from the cart if the quantity is > 0' do
        store.append(add_item_event)
        result = cart.handle(command)
        expect(result).to be_a(cart_event::ItemRemoved)
        expect(cart.items[item_1_id]).to eq(1)
      end

      it 'should remove an item from the cart if the quantity is 0' do
        result = cart.handle(command)
        expect(result).to be_a(cart_event::ItemRemoved)
        expect(cart.items[item_1_id]).to eq(nil)
      end

      it 'should not raise an error if the item does not exist' do
        command = cart_command::RemoveItem.new(aggregate_id: cart_id, item_id: 'nonexistent-item')
        expect do
          cart.handle(command)
        end.to raise_error(SimpleEventModeling::Common::Errors::InvalidCommandError,
                           /Item nonexistent-item is not in the cart/)
      end
    end

    context 'when handling an unknown command type' do
      let(:unknown_command) { Struct.new(:aggregate_id).new(aggregate_id: nil) }

      it 'should raise an error' do
        expect do
          cart.handle(unknown_command)
        end.to raise_error(RuntimeError, "Unknown command type: #{unknown_command.class}")
      end
    end
  end
end
