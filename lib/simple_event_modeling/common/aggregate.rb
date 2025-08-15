# frozen_string_literal: true

module SimpleEventModeling
  module Common
    # Aggregate lifecycle and event replay logic for event-sourced domain models.
    #
    # Provides hydration, event handling, and command handling interfaces.
    #
    # @example
    #   class MyAggregate
    #     include SimpleEventModeling::Common::Aggregate
    #     # ...
    #   end
    module Aggregate
      attr_accessor :live

      def self.included(base)
        base.class_eval do
          attr_accessor :id, :version, :live, :store
        end
      end

      def initialize(store)
        @store = store
        @live = false
      end

      def isLive?
        @live ||= false
        @live
      end

      def on(event)
        raise NotImplementedError, 'You must implement the on method'
      end

      def handle(command)
        raise NotImplementedError, 'You must implement the handle method'
      end

      def hydrate(id:)
        raise 'Aggregate is already live' if isLive?

        begin
          events = store.get_stream(id)
          events.each do |event|
            on(event)
          end
        rescue Errors::StreamNotFoundError => _e
          # Log the error or handle it as needed
        end
        @live = true
      end
    end
  end
end
