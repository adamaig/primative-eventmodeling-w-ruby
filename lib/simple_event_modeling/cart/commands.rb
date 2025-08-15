# frozen_string_literal: true

module SimpleEventModeling
  module Cart
    # Cart Commands for SimpleEventModeling
    #
    # This module defines command objects for cart operations in the event modeling example.
    # Each command is an immutable value object representing an intent to change cart state.
    #
    # @example Add an item to cart
    #   AddItem.new(cart_id: 'abc', item_id: 'sku123', quantity: 2)
    #
    module Commands
      # Command to create a new cart
      #
      # @!attribute [rw] aggregate_id
      #   @return [String] The aggregate identifier
      # @example
      #   CreateCart.new('cart-123')
      CreateCart = Struct.new(:aggregate_id)

      # Command to add an item to the cart
      #
      # @!attribute [rw] aggregate_id
      #   @return [String] The cart identifier
      # @!attribute [rw] item_id
      #   @return [String] The item identifier
      # @example
      #   AddItem.new('cart-123', 'sku123')
      AddItem = Struct.new(:aggregate_id, :item_id)

      # Command to remove an item from the cart
      #
      # @!attribute [rw] aggregate_id
      #   @return [String] The cart identifier
      # @!attribute [rw] item_id
      #   @return [String] The item identifier
      # @example
      #   RemoveItem.new('cart-123', 'sku123')
      RemoveItem = Struct.new(:aggregate_id, :item_id)

      # Command to clear all items from the cart
      #
      # @!attribute [rw] aggregate_id
      #   @return [String] The cart identifier
      # @example
      #   ClearCart.new('cart-123')
      ClearCart = Struct.new(:aggregate_id)
    end
  end
end
