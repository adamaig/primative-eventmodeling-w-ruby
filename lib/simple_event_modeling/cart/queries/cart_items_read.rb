# frozen_string_literal: true

module SimpleEventModeling
  module Cart
    module Queries
      # Query object for projecting the current state of a cart from its event stream.
      #
      # Iterates over all cart-related events and builds a projection of items, quantities, and totals.
      #
      # @example
      #   query = Queries::CartItemsRead.new(cart_id, store)
      #   result = query.execute
      #   # => { cart: { cart_id: ..., items: {...}, totals: {...} } }
      #
      # @param aggregate_id [String] The cart's aggregate ID.
      # @param store [EventStore] The event store containing cart events.
      # @return [Hash] The projected cart state.
      class CartItemsRead
        attr_accessor :aggregate_id, :store, :projection

        def initialize(aggregate_id, store)
          @aggregate_id = aggregate_id
          @store = store
          @projection = {}
        end

        def execute
          events = store.get_stream(aggregate_id)
          events.each do |event|
            on(event)
          end
          { cart: @projection }
        end

        def on(event)
          case event
          when DomainEvents::CartCreated
            on_cart_created(event)
          when DomainEvents::ItemAdded
            on_add_item(event)
          when DomainEvents::ItemRemoved
            on_item_removed(event)
          when DomainEvents::CartCleared
            on_cart_cleared(event)
          else
            raise "Unhandled event type: #{event.class}"
          end
        end

        def on_cart_created(event)
          @projection[:cart_id] = event.aggregate_id
          @projection[:items] = {}
          @projection[:totals] = {
            total: 0.0
          }
        end

        def on_add_item(event)
          @projection[:items] ||= {}
          item_id = event.data[:item]
          @projection[:items][item_id] ||= { quantity: 0 }
          @projection[:items][item_id][:quantity] += 1
        end

        def on_item_removed(event)
          item_id = event.data[:item]
          return unless projection[:items].has_key?(item_id)

          projection[:items][item_id][:quantity] -= 1

          projection[:items].delete(item_id) if projection[:items][item_id][:quantity] < 1
        end

        def on_cart_cleared(_event)
          @projection[:items] = {}
        end
      end
    end
  end
end
