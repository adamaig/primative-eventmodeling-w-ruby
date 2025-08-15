# frozen_string_literal: true

require 'securerandom'

module SimpleEventModeling
  module Cart
    module DomainEvents
      class CartCreated < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:)
          super(type: self.class, aggregate_id: aggregate_id, version: 1)
        end
      end

      class ItemAdded < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:, version:, item_id:)
          super(type: self.class, aggregate_id: aggregate_id, version: version, data: { item: item_id })
        end
      end

      class ItemRemoved < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:, version:, item_id:)
          super(type: self.class, aggregate_id: aggregate_id, version: version, data: { item: item_id })
        end
      end

      class CartCleared < SimpleEventModeling::Common::Event
        def initialize(aggregate_id:, version:)
          super(type: self.class, aggregate_id: aggregate_id, version: version)
        end
      end
    end
  end
end
