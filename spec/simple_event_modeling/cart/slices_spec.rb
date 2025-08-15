# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cart GWT Slices' do
  # Shortened namespace for cart events and commands
  let(:cart_event) { SimpleEventModeling::Cart::DomainEvents }
  let(:cart_command) { SimpleEventModeling::Cart::Commands }

  let(:store) { SimpleEventModeling::Common::EventStore.new }
  let(:cart) { SimpleEventModeling::Cart::Aggregate.new(store) }
  let(:cart_id) { 'cart-123' }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }

  describe 'Adding items to a cart' do
    it 'should add an item to the cart' do
      cart_id = SecureRandom.uuid
      given_events([
                     cart_event::CartCreated.new(aggregate_id: cart_id)
                   ])
      when_command(cart, cart_command::AddItem.new(cart_id, item_1_id))
      then_events([
                    be_a(cart_event::CartCreated).and(have_attributes(version: 1)),
                    be_a(cart_event::ItemAdded).and(have_attributes(version: 2,
                                                                    data: { item: item_1_id }))
                  ])
    end

    it 'should create a cart if none is specified when adding an item' do
      given_events([])
      when_command(cart, cart_command::AddItem.new(nil, item_1_id))
      then_events([
                    be_a(cart_event::CartCreated).and(have_attributes(version: 1)),
                    be_a(cart_event::ItemAdded).and(have_attributes(version: 2,
                                                                    data: { item: item_1_id }))
                  ])
    end

    it 'should error if more than 3 items are added' do
      cart_id = SecureRandom.uuid
      given_events([
                     cart_event::CartCreated.new(aggregate_id: cart_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                               item_id: item_1_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                               item_id: item_1_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                               item_id: item_1_id)
                   ])
      expect do
        when_command(cart, cart_command::AddItem.new(cart_id, item_1_id))
      end.to raise_error(SimpleEventModeling::Common::Errors::InvalidCommandError, /Too many items in cart/)
    end
  end

  describe 'Removing Items from a Cart' do
    let(:cart_id) { SecureRandom.uuid }
    before do
      given_events([
                     cart_event::CartCreated.new(aggregate_id: cart_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                               item_id: item_1_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                               item_id: item_1_id)
                   ])
    end

    it 'should support reduce the quantity of items' do
      when_command(cart, cart_command::RemoveItem.new(cart_id, item_1_id))
      then_events_include(
        be_a(cart_event::ItemRemoved).and(have_attributes(version: 4,
                                                          data: { item: item_1_id }))
      )
    end

    it 'should remove the item if quantity reaches zero' do
      given_events([
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                               item_id: item_2_id)
                   ])
      when_command(cart, cart_command::RemoveItem.new(cart_id, item_2_id))
      then_events_include(
        be_a(cart_event::ItemRemoved).and(have_attributes(version: 5,
                                                          data: { item: item_2_id }))
      )
    end

    it 'should error when attempting to remove an item that is not in the cart' do
      expect do
        when_command(cart, cart_command::RemoveItem.new(cart_id, item_2_id))
      end.to raise_error(SimpleEventModeling::Common::Errors::InvalidCommandError,
                         /Item #{item_2_id} is not in the cart/)
    end
  end

  describe 'Clearing the cart' do
    it 'should support clearing the cart' do
      cart_id = SecureRandom.uuid
      given_events([
                     cart_event::CartCreated.new(aggregate_id: cart_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                               item_id: item_1_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                               item_id: item_2_id),
                     cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                               item_id: item_1_id)
                   ])
      when_command(cart, cart_command::ClearCart.new(cart_id))
      then_events_include(
        be_a(cart_event::CartCleared).and(have_attributes(version: 5, data: {}))
      )
    end
  end
end
