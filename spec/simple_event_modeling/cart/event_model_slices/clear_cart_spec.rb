# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Clear a Cart' do
  # Shortened namespace for cart events and commands
  let(:cart_event) { SimpleEventModeling::Cart::DomainEvents }
  let(:cart_command) { SimpleEventModeling::Cart::Commands }

  let(:store) { SimpleEventModeling::Common::EventStore.new }
  let(:cart) { SimpleEventModeling::Cart::Aggregate.new(store) }
  let(:cart_id) { 'cart-123' }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }

  it 'should support clearing the cart' do
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
