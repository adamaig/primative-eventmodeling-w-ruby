# frozen_string_literal: true

require 'securerandom'

module SimpleEventModeling
  module Cart
    module DomainEvents
      # Event representing cart creation
      #
      # @!attribute [r] aggregate_id
      #   @return [String] The cart identifier
      # @!attribute [r] version
      #   @return [Integer] The event version (always 1)
      # @example
      #   CartCreated.new(aggregate_id: 'cart-123')
      class CartCreated < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:)
          super(type: self.class, aggregate_id: aggregate_id, version: 1)
        end
      end

      # Event representing an item being added to the cart
      #
      # @!attribute [r] aggregate_id
      #   @return [String] The cart identifier
      # @!attribute [r] version
      #   @return [Integer] The event version
      # @!attribute [r] item_id
      #   @return [String] The item identifier
      # @example
      #   ItemAdded.new(aggregate_id: 'cart-123', version: 2, item_id: 'sku123')
      class ItemAdded < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:, version:, item_id:)
          super(type: self.class, aggregate_id: aggregate_id, version: version, data: { item: item_id })
        end
      end

      # Event representing an item being removed from the cart
      #
      # @!attribute [r] aggregate_id
      #   @return [String] The cart identifier
      # @!attribute [r] version
      #   @return [Integer] The event version
      # @!attribute [r] item_id
      #   @return [String] The item identifier
      # @example
      #   ItemRemoved.new(aggregate_id: 'cart-123', version: 3, item_id: 'sku123')
      class ItemRemoved < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:, version:, item_id:)
          super(type: self.class, aggregate_id: aggregate_id, version: version, data: { item: item_id })
        end
      end

      # Event representing the cart being cleared
      #
      # @!attribute [r] aggregate_id
      #   @return [String] The cart identifier
      # @!attribute [r] version
      #   @return [Integer] The event version
      # @example
      #   CartCleared.new(aggregate_id: 'cart-123', version: 4)
      class CartCleared < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:, version:)
          super(type: self.class, aggregate_id: aggregate_id, version: version)
        end
      end
    end
  end
end
