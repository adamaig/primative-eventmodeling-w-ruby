# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleEventModeling::Cart::Queries::CartItemsRead do # rubocop:disable Metrics/BlockLength
  # Shortened namespace for cart events
  let(:cart_event) { SimpleEventModeling::Cart::DomainEvents }

  let(:cart_id) { SecureRandom.uuid }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }
  let(:store) { SimpleEventModeling::Common::EventStore.new }

  it 'should be the basic projection when the cart is created' do
    events = [
      cart_event::CartCreated.new(aggregate_id: cart_id)
    ]
    events.each { |event| store.append(event) }
    expect(
      described_class.new(cart_id, store).execute
    ).to eq({
              cart: {
                cart_id: cart_id,
                items: {},
                totals: {
                  total: 0.0
                }
              }
            })
  end

  it 'should read the cart items' do
    events = [
      cart_event::CartCreated.new(aggregate_id: cart_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_2_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_1_id)
    ]
    events.each { |event| store.append(event) }
    expect(
      described_class.new(cart_id, store).execute
    ).to eq({
              cart: {
                cart_id: cart_id,
                totals: {
                  total: 0.0
                },
                items: {
                  item_1_id => {
                    quantity: 2
                  },
                  item_2_id => {
                    quantity: 1
                  }
                }
              }
            })
  end

  it 'should project the expected quantity and cost of items in the cart' do
    events = [
      cart_event::CartCreated.new(aggregate_id: cart_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_2_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_1_id),
      cart_event::ItemRemoved.new(aggregate_id: cart_id, version: 5, item_id: item_1_id),
      cart_event::ItemRemoved.new(aggregate_id: cart_id, version: 6, item_id: item_2_id)
    ]
    events.each { |event| store.append(event) }
    expect(
      described_class.new(cart_id, store).execute
    ).to eq({
              cart: {
                cart_id: cart_id,
                totals: {
                  total: 0.0
                },
                items: {
                  item_1_id => { quantity: 1 }
                }
              }
            })
  end

  it 'should have an empty item list when cleared' do
    events = [
      cart_event::CartCreated.new(aggregate_id: cart_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_2_id),
      cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_1_id),
      cart_event::CartCleared.new(aggregate_id: cart_id, version: 5)
    ]
    events.each { |event| store.append(event) }
    expect(
      described_class.new(cart_id, store).execute
    ).to eq({
              cart: {
                cart_id: cart_id,
                totals: {
                  total: 0.0
                },
                items: {}
              }
            })
  end
end
