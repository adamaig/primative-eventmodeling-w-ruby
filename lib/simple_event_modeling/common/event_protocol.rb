# frozen_string_literal: true

module SimpleEventModeling
  module Common
    # Protocol for event objects stored in EventStore.
    # Any event must respond to :aggregate_id and :version.
    #
    # @example
    #   class MyEvent
    #     include SimpleEventModeling::Common::EventProtocol
    #     attr_reader :aggregate_id, :version
    #   end
    module EventProtocol
      # @return [String] aggregate identifier
      def aggregate_id; end

      # @return [Integer] event version
      def version; end
    end
  end
end
