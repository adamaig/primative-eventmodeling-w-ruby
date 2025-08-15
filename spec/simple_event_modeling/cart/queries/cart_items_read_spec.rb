# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleEventModeling::Cart::Queries::CartItemsRead do # rubocop:disable Metrics/BlockLength
  # Shortened namespace for cart events
  let(:cart_event) { SimpleEventModeling::Cart::DomainEvents }

  let(:cart_id) { SecureRandom.uuid }
  let(:item_1_id) { 'item-456' }
  let(:item_2_id) { 'item-789' }
  let(:store) { SimpleEventModeling::Common::EventStore.new }

  let(:query) { described_class.new(cart_id, store) }

  it 'should be the basic projection when the cart is created' do
    given_events([
                   cart_event::CartCreated.new(aggregate_id: cart_id)
                 ])

    expected_result = {
      cart: {
        cart_id: cart_id,
        items: {},
        totals: {
          total: 0.0
        }
      }
    }

    expect(query.execute).to eq(expected_result)
  end

  it 'should read the cart items' do
    given_events([
                   cart_event::CartCreated.new(aggregate_id: cart_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_2_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_1_id)
                 ])

    expected_result = {
      cart: {
        cart_id: cart_id,
        items: {
          item_1_id => {
            quantity: 2
          },
          item_2_id => {
            quantity: 1
          }
        },
        totals: {
          total: 0.0
        }
      }
    }

    expect(query.execute).to eq(expected_result)
  end

  it 'should project the expected quantity and cost of items in the cart' do
    given_events([
                   cart_event::CartCreated.new(aggregate_id: cart_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_2_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_1_id),
                   cart_event::ItemRemoved.new(aggregate_id: cart_id, version: 5, item_id: item_1_id),
                   cart_event::ItemRemoved.new(aggregate_id: cart_id, version: 6, item_id: item_2_id)
                 ])

    expected_result = {
      cart: {
        cart_id: cart_id,
        totals: {
          total: 0.0
        },
        items: {
          item_1_id => { quantity: 1 }
        }
      }
    }

    expect(query.execute).to eq(expected_result)
  end

  it 'should have an empty item list when cleared' do
    given_events([
                   cart_event::CartCreated.new(aggregate_id: cart_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 2, item_id: item_1_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 3, item_id: item_2_id),
                   cart_event::ItemAdded.new(aggregate_id: cart_id, version: 4, item_id: item_1_id),
                   cart_event::CartCleared.new(aggregate_id: cart_id, version: 5)
                 ])

    expected_result = {
      cart: {
        cart_id: cart_id,
        items: {},
        totals: {
          total: 0.0
        }
      }
    }

    expect(query.execute).to eq(expected_result)
  end
end
