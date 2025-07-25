# frozen_string_literal: true

# Require all *.rb files in lib directory
Dir[File.expand_path('../lib/**/*.rb', __dir__)].each { |file| require file }
