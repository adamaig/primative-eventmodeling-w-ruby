# frozen_string_literal: true

module EventModeling
  # Base error class for all EventModeling errors
  class Error < StandardError; end

  # Custom error for concurrency conflicts when expected version doesn't match current version
  class ConcurrencyError < Error; end

  # Error raised when attempting to operate on a non-existent stream
  class StreamNotFoundError < Error; end

  # Error raised for invalid event data
  class InvalidEventError < Error; end
end
