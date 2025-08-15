# frozen_string_literal: true

module SimpleEventModeling
  module Cart
    module Commands
      Unknown = Struct.new(:aggregate_id)
      CreateCart = Struct.new(:aggregate_id)
      AddItem = Struct.new(:aggregate_id, :item_id)
      RemoveItem = Struct.new(:aggregate_id, :item_id)
      ClearCart = Struct.new(:aggregate_id)
    end
  end
end
