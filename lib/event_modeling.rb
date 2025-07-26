# frozen_string_literal: true

module EventModeling
  # Custom error for concurrency conflicts when expected version doesn't match current version
  class ConcurrencyError < StandardError; end

  end
end
