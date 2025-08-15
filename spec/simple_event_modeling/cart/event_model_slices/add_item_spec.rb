# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Add item to a cart' do
  # Shortened namespace for cart events and commands
  let(:cart_event) { SimpleEventModeling::Cart::DomainEvents }
  let(:cart_command) { SimpleEventModeling::Cart::Commands }

  let(:store) { SimpleEventModeling::Common::EventStore.new }
  let(:cart) { SimpleEventModeling::Cart::Aggregate.new(store) }
  let(:cart_id) { 'cart-123' }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }

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
