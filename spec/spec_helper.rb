# frozen_string_literal: true

require 'faker'

# Require all *.rb files in lib directory
Dir[File.expand_path('../lib/**/*.rb', __dir__)].each { |file| require file }

RSpec.configure do |config|
  config.filter_run_when_matching :focus
end
