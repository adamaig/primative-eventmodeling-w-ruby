# frozen_string_literal: true

require 'spec_helper'
require 'time'

RSpec.describe EventModeling::Command do
  let(:command_type) { 'CreateUser' }
  let(:command_data) { { name: 'John', email: 'john@example.com' } }
  let(:fixed_time) { Time.parse('2025-07-26 14:30:00 UTC') }
  let(:fixed_command_id) { 'test-command-123' }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates a command with type and data' do
        command = described_class.new(type: command_type, data: command_data)

        expect(command.type).to eq(command_type)
        expect(command.data).to eq(command_data)
        expect(command.command_id).to be_a(String)
        expect(command.created_at).to be_a(Time)
      end

      it 'creates a command with explicit command_id and created_at' do
        command = described_class.new(
          type: command_type,
          data: command_data,
          command_id: fixed_command_id,
          created_at: fixed_time
        )

        expect(command.type).to eq(command_type)
        expect(command.data).to eq(command_data)
        expect(command.command_id).to eq(fixed_command_id)
        expect(command.created_at).to eq(fixed_time)
      end

      it 'auto-generates a UUID for command_id when not provided' do
        command = described_class.new(type: command_type, data: command_data)

        expect(command.command_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
      end

      it 'auto-generates created_at timestamp when not provided' do
        before_time = Time.now
        command = described_class.new(type: command_type, data: command_data)
        after_time = Time.now

        expect(command.created_at).to be_between(before_time, after_time)
      end

      it 'freezes the data to prevent modification' do
        command = described_class.new(type: command_type, data: command_data)

        expect(command.data).to be_frozen
        expect { command.data[:name] = 'Jane' }.to raise_error(FrozenError)
      end

      it 'creates a copy of data to prevent external modification' do
        original_data = { name: 'John', email: 'john@example.com' }
        command = described_class.new(type: command_type, data: original_data)

        original_data[:name] = 'Jane'
        original_data[:email] = 'jane@example.com'

        expect(command.data[:name]).to eq('John')
        expect(command.data[:email]).to eq('john@example.com')
      end

      it 'handles empty data gracefully' do
        command = described_class.new(type: command_type, data: {})

        expect(command.type).to eq(command_type)
        expect(command.data).to eq({})
        expect(command.data).to be_frozen
      end
    end

    context 'with invalid parameters' do
      it 'raises InvalidCommandError when type is not a String' do
        expect do
          described_class.new(type: 123, data: command_data)
        end.to raise_error(EventModeling::InvalidCommandError, 'Command type must be a String')
      end

      it 'raises InvalidCommandError when type is nil' do
        expect do
          described_class.new(type: nil, data: command_data)
        end.to raise_error(EventModeling::InvalidCommandError, 'Command type must be a String')
      end

      it 'raises InvalidCommandError when data is not a Hash' do
        expect do
          described_class.new(type: command_type, data: 'not a hash')
        end.to raise_error(EventModeling::InvalidCommandError, 'Command data must be a Hash')
      end

      it 'raises InvalidCommandError when data is nil' do
        expect do
          described_class.new(type: command_type, data: nil)
        end.to raise_error(EventModeling::InvalidCommandError, 'Command data must be a Hash')
      end

      it 'raises InvalidCommandError when data is an array' do
        expect do
          described_class.new(type: command_type, data: %w[not a hash])
        end.to raise_error(EventModeling::InvalidCommandError, 'Command data must be a Hash')
      end
    end
  end

  describe 'immutability' do
    let(:command) { described_class.new(type: command_type, data: command_data) }

    it 'freezes the command object after creation' do
      expect(command).to be_frozen
    end

    it 'prevents modification of command attributes' do
      expect { command.instance_variable_set(:@type, 'Modified') }.to raise_error(FrozenError)
    end

    it 'prevents modification of data hash' do
      expect { command.data[:new_key] = 'new_value' }.to raise_error(FrozenError)
    end

    it 'prevents modification of nested data structures' do
      nested_data = { user: { name: 'John', details: { age: 30 } } }
      command_with_nested = described_class.new(type: command_type, data: nested_data)

      expect(command_with_nested.data[:user]).to be_frozen
      expect { command_with_nested.data[:user][:name] = 'Jane' }.to raise_error(FrozenError)
    end
  end

  describe '#to_h' do
    it 'returns a hash representation of the command' do
      command = described_class.new(
        type: command_type,
        data: command_data,
        command_id: fixed_command_id,
        created_at: fixed_time
      )

      expected_hash = {
        type: command_type,
        data: command_data,
        command_id: fixed_command_id,
        created_at: fixed_time
      }

      expect(command.to_h).to eq(expected_hash)
    end

    it 'includes all metadata fields' do
      command = described_class.new(type: command_type, data: command_data)
      hash = command.to_h

      expect(hash).to have_key(:type)
      expect(hash).to have_key(:data)
      expect(hash).to have_key(:command_id)
      expect(hash).to have_key(:created_at)
    end

    it 'returns a new hash instance each time' do
      command = described_class.new(type: command_type, data: command_data)

      hash1 = command.to_h
      hash2 = command.to_h

      expect(hash1).to eq(hash2)
      expect(hash1).not_to be(hash2) # Different object instances
    end
  end

  describe '#==' do
    let(:command1) do
      described_class.new(
        type: command_type,
        data: command_data,
        command_id: fixed_command_id,
        created_at: fixed_time
      )
    end

    let(:command2) do
      described_class.new(
        type: command_type,
        data: command_data,
        command_id: fixed_command_id,
        created_at: fixed_time
      )
    end

    it 'returns true for commands with identical type, data, and command_id' do
      expect(command1).to eq(command2)
    end

    it 'returns false for commands with different types' do
      different_type_command = described_class.new(
        type: 'UpdateUser',
        data: command_data,
        command_id: fixed_command_id,
        created_at: fixed_time
      )

      expect(command1).not_to eq(different_type_command)
    end

    it 'returns false for commands with different data' do
      different_data_command = described_class.new(
        type: command_type,
        data: { name: 'Jane', email: 'jane@example.com' },
        command_id: fixed_command_id,
        created_at: fixed_time
      )

      expect(command1).not_to eq(different_data_command)
    end

    it 'returns false for commands with different command_ids' do
      different_id_command = described_class.new(
        type: command_type,
        data: command_data,
        command_id: 'different-id',
        created_at: fixed_time
      )

      expect(command1).not_to eq(different_id_command)
    end

    it 'ignores created_at timestamp in equality comparison' do
      later_time_command = described_class.new(
        type: command_type,
        data: command_data,
        command_id: fixed_command_id,
        created_at: fixed_time + 3600 # 1 hour later
      )

      expect(command1).to eq(later_time_command)
    end

    it 'returns false when comparing with non-Command objects' do
      expect(command1).not_to eq('not a command')
      expect(command1).not_to eq(nil)
      expect(command1).not_to eq({})
    end

    it 'returns false when comparing with Event objects' do
      event = EventModeling::Event.new(type: command_type, data: command_data)
      expect(command1).not_to eq(event)
    end
  end

  describe 'inheritance and subclassing' do
    # Define test subclasses within the spec
    let!(:create_user_command_class) do
      Class.new(described_class) do
        def initialize(name:, email:)
          super(
            type: 'CreateUser',
            data: { name: name, email: email }
          )
        end
      end
    end

    let!(:update_user_command_class) do
      Class.new(described_class) do
        def initialize(user_id:, name: nil, email: nil)
          super(
            type: 'UpdateUser',
            data: { user_id: user_id, name: name, email: email }.compact
          )
        end
      end
    end

    it 'supports creating application-specific command subclasses' do
      command = create_user_command_class.new(name: 'John', email: 'john@example.com')

      expect(command).to be_a(described_class)
      expect(command.type).to eq('CreateUser')
      expect(command.data).to eq({ name: 'John', email: 'john@example.com' })
      expect(command.command_id).to be_a(String)
      expect(command.created_at).to be_a(Time)
    end

    it 'inherits all base functionality in subclasses' do
      command = create_user_command_class.new(name: 'John', email: 'john@example.com')

      expect(command).to be_frozen
      expect(command.data).to be_frozen
      expect(command.to_h).to include(:type, :data, :command_id, :created_at)
    end

    it 'supports custom constructors with optional parameters' do
      command = update_user_command_class.new(user_id: 123, name: 'John')

      expect(command.type).to eq('UpdateUser')
      expect(command.data).to eq({ user_id: 123, name: 'John' })
    end

    it 'handles nil values in custom constructors correctly' do
      command = update_user_command_class.new(user_id: 123, name: nil, email: nil)

      expect(command.data).to eq({ user_id: 123 })
    end

    it 'maintains equality semantics for subclassed commands' do
      command1 = create_user_command_class.new(name: 'John', email: 'john@example.com')
      command2 = create_user_command_class.new(name: 'John', email: 'john@example.com')

      # Different command_ids, so they should not be equal
      expect(command1).not_to eq(command2)

      # Create with same command_id
      command3 = described_class.new(
        type: 'CreateUser',
        data: { name: 'John', email: 'john@example.com' },
        command_id: command1.command_id
      )

      expect(command1).to eq(command3)
    end
  end

  describe 'metadata handling' do
    it 'generates unique command_ids for each command' do
      command1 = described_class.new(type: command_type, data: command_data)
      command2 = described_class.new(type: command_type, data: command_data)

      expect(command1.command_id).not_to eq(command2.command_id)
    end

    it 'uses provided command_id when specified' do
      custom_id = 'my-custom-command-id'
      command = described_class.new(
        type: command_type,
        data: command_data,
        command_id: custom_id
      )

      expect(command.command_id).to eq(custom_id)
    end

    it 'uses provided created_at when specified' do
      custom_time = Time.parse('2025-01-01 12:00:00 UTC')
      command = described_class.new(
        type: command_type,
        data: command_data,
        created_at: custom_time
      )

      expect(command.created_at).to eq(custom_time)
    end

    it 'preserves timestamp precision' do
      precise_time = Time.now
      command = described_class.new(
        type: command_type,
        data: command_data,
        created_at: precise_time
      )

      expect(command.created_at).to eq(precise_time)
      expect(command.created_at.to_f).to eq(precise_time.to_f)
    end
  end

  describe 'edge cases and error conditions' do
    it 'handles empty string type gracefully' do
      command = described_class.new(type: '', data: command_data)

      expect(command.type).to eq('')
      expect(command.data).to eq(command_data)
    end

    it 'handles complex nested data structures' do
      complex_data = {
        user: {
          personal: { name: 'John', age: 30 },
          contact: { email: 'john@example.com', phone: '555-1234' }
        },
        metadata: {
          tags: %w[important user],
          created_by: 'admin'
        }
      }

      command = described_class.new(type: command_type, data: complex_data)

      expect(command.data).to eq(complex_data)
      expect(command.data).to be_frozen
      expect(command.data[:user]).to be_frozen
      expect(command.data[:user][:personal]).to be_frozen
      expect(command.data[:metadata][:tags]).to be_frozen
    end

    it 'handles symbols in data keys and values' do
      symbol_data = { status: :active, type: :premium }
      command = described_class.new(type: command_type, data: symbol_data)

      expect(command.data).to eq(symbol_data)
      expect(command.data[:status]).to eq(:active)
      expect(command.data[:type]).to eq(:premium)
    end

    it 'maintains data integrity when original hash is modified after command creation' do
      mutable_data = { name: 'John', tags: ['user'] }
      command = described_class.new(type: command_type, data: mutable_data)

      # Modify original data
      mutable_data[:name] = 'Jane'
      mutable_data[:tags] << 'modified'

      # Command data should be unchanged
      expect(command.data[:name]).to eq('John')
      expect(command.data[:tags]).to eq(['user'])
    end
  end
end
