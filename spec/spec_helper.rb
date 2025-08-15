# frozen_string_literal: true

require 'faker'
require 'pry'

# Require all *.rb files in lib directory
Dir[File.expand_path('../lib/*.rb', __dir__)].sort.each do |file|
  require file
end

RSpec.configure do |config|
  config.filter_run_when_matching :focus
end
