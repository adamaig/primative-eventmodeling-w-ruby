# frozen_string_literal: true

require 'securerandom'

module EventModeling
  # Command class represents user intent in a CQRS (Command Query Responsibility Segregation) system.
  #
  # Commands are immutable data containers that express what a user wants to do,
  # as opposed to Events which record what actually happened. Commands contain
  # no behavior and serve as pure data transfer objects.
  #
  # Each command is automatically assigned a unique command_id and created_at timestamp
  # for tracking and auditing purposes. Commands are frozen after creation to ensure
  # immutability and data integrity.
  #
  # @example Creating a basic command
  #   command = Command.new(type: 'CreateUser', data: { name: 'John', email: 'john@example.com' })
  #   puts command.type        # => "CreateUser"
  #   puts command.data        # => { name: 'John', email: 'john@example.com' }
  #   puts command.command_id  # => "550e8400-e29b-41d4-a716-446655440000" (auto-generated UUID)
  #
  # @example Creating application-specific commands through subclassing
  #   class CreateUserCommand < EventModeling::Command
  #     def initialize(name:, email:)
  #       super(type: 'CreateUser', data: { name: name, email: email })
  #     end
  #   end
  #
  #   command = CreateUserCommand.new(name: 'John', email: 'john@example.com')
  #
  # @example Command with explicit metadata
  #   command = Command.new(
  #     type: 'CreateUser',
  #     data: { name: 'John' },
  #     command_id: 'my-custom-id',
  #     created_at: Time.parse('2025-01-01 12:00:00 UTC')
  #   )
  #
  # @since 1.0.0
  class Command
    # @return [String] the command type identifier expressing user intent
    attr_reader :type

    # @return [Hash] the command payload data (frozen)
    attr_reader :data

    # @return [String] unique identifier for this command instance
    attr_reader :command_id

    # @return [Time] timestamp when the command was created
    attr_reader :created_at

    # Initialize a new Command instance.
    #
    # Creates an immutable command with the specified type and data. If command_id
    # or created_at are not provided, they will be auto-generated with a UUID and
    # current timestamp respectively.
    #
    # The data hash is deeply frozen to prevent any modifications after creation.
    # The entire command object is also frozen to ensure complete immutability.
    #
    # @param type [String] the command type identifier
    # @param data [Hash] the command payload data
    # @param command_id [String, nil] unique command identifier (auto-generated if nil)
    # @param created_at [Time, nil] command creation timestamp (auto-generated if nil)
    # @raise [InvalidCommandError] if type is not a String or data is not a Hash
    #
    # @example Basic command creation
    #   command = Command.new(type: 'CreateUser', data: { name: 'John' })
    #
    # @example Command with explicit metadata
    #   command = Command.new(
    #     type: 'ProcessPayment',
    #     data: { amount: 100, currency: 'USD' },
    #     command_id: 'payment-123',
    #     created_at: Time.now
    #   )
    def initialize(type:, data:, command_id: nil, created_at: nil)
      validate_parameters(type, data)

      @type = type
      @data = deep_freeze(data.dup)
      @command_id = command_id || SecureRandom.uuid
      @created_at = created_at || Time.now

      freeze
    end

    # Convert command to hash representation.
    #
    # Returns a new hash containing all command attributes including metadata.
    # The returned hash is not frozen and can be modified, but the original
    # command remains immutable.
    #
    # @return [Hash] hash representation with :type, :data, :command_id, :created_at keys
    #
    # @example Converting to hash
    #   command = Command.new(type: 'CreateUser', data: { name: 'John' })
    #   hash = command.to_h
    #   # => { type: 'CreateUser', data: { name: 'John' }, command_id: '...', created_at: ... }
    def to_h
      {
        type: @type,
        data: @data,
        command_id: @command_id,
        created_at: @created_at
      }
    end

    # Compare commands for equality.
    #
    # Two commands are considered equal if they have the same type, data, and command_id.
    # The created_at timestamp is intentionally ignored in equality comparison to allow
    # for commands with identical intent but different creation times to be considered equal.
    #
    # @param other [Object] object to compare with
    # @return [Boolean] true if commands are equal, false otherwise
    #
    # @example Equality comparison
    #   command1 = Command.new(type: 'CreateUser', data: { name: 'John' }, command_id: 'id-1')
    #   command2 = Command.new(type: 'CreateUser', data: { name: 'John' }, command_id: 'id-1')
    #   command1 == command2  # => true (same type, data, and command_id)
    def ==(other)
      other.is_a?(Command) &&
        type == other.type &&
        data == other.data &&
        command_id == other.command_id
    end

    private

    # Validate command initialization parameters.
    #
    # Ensures type is a String and data is a Hash, raising descriptive errors
    # if validation fails. This maintains consistency with Event validation patterns.
    #
    # @param type [Object] the type parameter to validate
    # @param data [Object] the data parameter to validate
    # @raise [InvalidCommandError] if validation fails
    # @api private
    def validate_parameters(type, data)
      raise InvalidCommandError, 'Command type must be a String' unless type.is_a?(String)
      raise InvalidCommandError, 'Command data must be a Hash' unless data.is_a?(Hash)
    end

    # Deep freeze a data structure to prevent any modifications.
    #
    # Recursively freezes the provided object and all nested objects to ensure
    # complete immutability. Handles Hash, Array, and other object types.
    # Creates deep copies before freezing to avoid modifying the original data.
    #
    # @param obj [Object] the object to deep freeze
    # @return [Object] the frozen object
    # @api private
    def deep_freeze(obj)
      case obj
      when Hash
        frozen_hash = {}
        obj.each { |key, value| frozen_hash[key] = deep_freeze(value) }
        frozen_hash.freeze
      when Array
        frozen_array = obj.map { |item| deep_freeze(item) }
        frozen_array.freeze
      else
        obj.freeze
      end
    end
  end
end
