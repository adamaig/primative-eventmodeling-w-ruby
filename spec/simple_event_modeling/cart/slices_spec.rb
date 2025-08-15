# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../spec/support/cart_spec_helpers'
require_relative '../../../lib/simple_event_modeling/cart/aggregate'
require_relative '../../../lib/simple_event_modeling/cart/commands'
require_relative '../../../lib/simple_event_modeling/cart/domain_events'
require_relative '../../../lib/simple_event_modeling/common/event_store'
require_relative '../../../lib/simple_event_modeling/common/errors'

RSpec.describe 'Cart GWT Slices' do
  include CartSpecHelpers

  let(:store) { SimpleEventModeling::Common::EventStore.new }
  let(:cart) { SimpleEventModeling::Cart::Aggregate.new(store) }
  let(:cart_id) { 'cart-123' }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }

  describe 'Adding items to a cart' do
    it 'should add an item to the cart' do
      cart_id = SecureRandom.uuid
      given_events([
                     SimpleEventModeling::Cart::DomainEvents::CartCreated.new(aggregate_id: cart_id)
                   ])
      when_command(cart, SimpleEventModeling::Cart::Commands::AddItem.new(cart_id, item_1_id))
      then_events([
                    be_a(SimpleEventModeling::Cart::DomainEvents::CartCreated).and(have_attributes(version: 1)),
                    be_a(SimpleEventModeling::Cart::DomainEvents::ItemAdded).and(have_attributes(version: 2,
                                                                                                 data: { item: item_1_id }))
                  ])
    end

    it 'should create a cart if none is specified when adding an item' do
      given_events([])
      when_command(cart, SimpleEventModeling::Cart::Commands::AddItem.new(nil, item_1_id))
      then_events([
                    be_a(SimpleEventModeling::Cart::DomainEvents::CartCreated).and(have_attributes(version: 1)),
                    be_a(SimpleEventModeling::Cart::DomainEvents::ItemAdded).and(have_attributes(version: 2,
                                                                                                 data: { item: item_1_id }))
                  ])
    end

    it 'should error if more than 3 items are added' do
      cart_id = SecureRandom.uuid
      given_events([
                     SimpleEventModeling::Cart::DomainEvents::CartCreated.new(aggregate_id: cart_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                                                            item_id: item_1_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                                                            item_id: item_1_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                                                            item_id: item_1_id)
                   ])
      expect do
        when_command(cart, SimpleEventModeling::Cart::Commands::AddItem.new(cart_id, item_1_id))
      end.to raise_error(SimpleEventModeling::Common::Errors::InvalidCommandError, /Too many items in cart/)
    end
  end

  describe 'Removing Items from a Cart' do
    xit 'should support removing items' do
      cart_id = SecureRandom.uuid
      given_events([
                     SimpleEventModeling::Cart::DomainEvents::CartCreated.new(aggregate_id: cart_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                                                            item_id: item_1_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                                                            item_id: item_2_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                                                            item_id: item_1_id)
                   ])
      when_command(cart, SimpleEventModeling::Cart::Commands::RemoveItem.new(cart_id, item_1_id))
      then_events_include(
        be_a(SimpleEventModeling::Cart::DomainEvents::ItemRemoved).and(have_attributes(version: 5,
                                                                                       data: { item: item_1_id }))
      )
    end

    it 'should error when attempting to remove an item that is not in the cart' do
      cart_id = SecureRandom.uuid
      given_events([
                     SimpleEventModeling::Cart::DomainEvents::CartCreated.new(aggregate_id: cart_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                                                            item_id: item_1_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                                                            item_id: item_1_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                                                            item_id: item_1_id)
                   ])
      expect do
        when_command(cart, SimpleEventModeling::Cart::Commands::RemoveItem.new(cart_id, item_2_id))
      end.to raise_error(SimpleEventModeling::Common::Errors::InvalidCommandError,
                         /Item #{item_2_id} is not in the cart/)
    end
  end

  describe 'Clearing the cart' do
    it 'should support clearing the cart' do
      cart_id = SecureRandom.uuid
      given_events([
                     SimpleEventModeling::Cart::DomainEvents::CartCreated.new(aggregate_id: cart_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 2,
                                                                            item_id: item_1_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 3,
                                                                            item_id: item_2_id),
                     SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: cart_id, version: 4,
                                                                            item_id: item_1_id)
                   ])
      when_command(cart, SimpleEventModeling::Cart::Commands::ClearCart.new(cart_id))
      then_events_include(
        be_a(SimpleEventModeling::Cart::DomainEvents::CartCleared).and(have_attributes(version: 5, data: {}))
      )
    end
  end
end
