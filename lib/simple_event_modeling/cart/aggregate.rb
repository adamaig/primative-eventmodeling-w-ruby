# frozen_string_literal: true

module SimpleEventModeling
  module Cart
    # Cart aggregate for event-sourced shopping cart domain.
    # Implements event replay, command handling, and state management.
    class Aggregate
      include SimpleEventModeling::Common::Aggregate

      attr_reader :items

      def initialize(store)
        super(store)
        @items = {}
      end

      def handle(command)
        hydrate(id: command.aggregate_id)

        case command
        when SimpleEventModeling::Cart::Commands::CreateCart
          handle_create_cart_command
        when SimpleEventModeling::Cart::Commands::AddItem
          handle_add_item_command(command)
        when SimpleEventModeling::Cart::Commands::RemoveItem
          handle_remove_item_command(command)
        when SimpleEventModeling::Cart::Commands::ClearCart
          handle_clear_cart_command(command)
        else
          raise "Unknown command type: #{command.class}"
        end
      end

      def on(event)
        case event
        when SimpleEventModeling::Cart::DomainEvents::CartCreated
          on_cart_created(event)
        when SimpleEventModeling::Cart::DomainEvents::ItemAdded
          on_add_item(event)
        when SimpleEventModeling::Cart::DomainEvents::CartCleared
          on_cart_cleared(event)
        else
          raise "Unhandled event type: #{event.class}"
        end
        @version = event.version
      end

      def on_cart_created(event)
        @id = event.aggregate_id
      end

      def on_add_item(event)
        @items[event.data[:item]] ||= 0
        @items[event.data[:item]] += 1
      end

      def on_remove_item(event)
        raise 'handle me'
      end

      def on_cart_cleared(event)
        @items = []
      end

      def handle_create_cart_command
        cart_id = SecureRandom.uuid
        event = SimpleEventModeling::Cart::DomainEvents::CartCreated.new(aggregate_id: cart_id)
        on(event)
        store.append(event)
        event
      end

      def handle_add_item_command(command)
        handle_create_cart_command if command.aggregate_id.nil?
        raise 'Cart not initialized' unless @id

        raise SimpleEventModeling::Common::Errors::InvalidCommandError.new('Too many items in cart') if items.sum(0) do |_item, count|
          count
        end >= 3

        item_id = command.item_id
        event = SimpleEventModeling::Cart::DomainEvents::ItemAdded.new(aggregate_id: @id, version: @version + 1,
                                                                       item_id: item_id)
        on(event)
        store.append(event)
        event
      end

      def handle_remove_item_command(command)
        raise 'Cart not initialized' unless @id

        item_id = command.item_id

        unless items.include?(item_id)
          raise SimpleEventModeling::Common::Errors::InvalidCommandError.new("Item #{item_id} is not in the cart")
        end

        event = SimpleEventModeling::Cart::DomainEvents::ItemRemoved.new(aggregate_id: @id, version: @version + 1,
                                                                         item_id: item_id)
        on(event)
        store.append(event)
        event
      end

      def handle_clear_cart_command(command)
        raise 'Cart not initialized' unless @id

        event = SimpleEventModeling::Cart::DomainEvents::CartCleared.new(aggregate_id: @id, version: @version + 1)
        on(event)
        store.append(event)
        event
      end
    end
  end
end
