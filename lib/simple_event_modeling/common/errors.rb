# frozen_string_literal: true

module SimpleEventModeling
  module Common
    module Errors
      # Error raised for invalid command data
      class InvalidCommandError < StandardError; end

      # Error raised when a stream is not found
      class StreamNotFound < StandardError
        def initialize(stream_id)
          super("Stream #{stream_id} not found")
        end
      end
    end
  end
end
