# frozen_string_literal: true

require 'spec_helper'
require 'time'

RSpec.describe EventModeling do
  describe 'module structure' do
    it 'defines the main EventModeling module' do
      expect(defined?(EventModeling)).to eq('constant')
      expect(EventModeling).to be_a(Module)
    end

    it 'includes EventStore class' do
      expect(defined?(EventModeling::EventStore)).to eq('constant')
      expect(EventModeling::EventStore).to be_a(Class)
    end

    it 'includes Event class' do
      expect(defined?(EventModeling::Event)).to eq('constant')
      expect(EventModeling::Event).to be_a(Class)
    end

    it 'includes Command class' do
      expect(defined?(EventModeling::Command)).to eq('constant')
      expect(EventModeling::Command).to be_a(Class)
    end

    it 'includes error hierarchy' do
      expect(defined?(EventModeling::Error)).to eq('constant')
      expect(defined?(EventModeling::ConcurrencyError)).to eq('constant')
      expect(defined?(EventModeling::StreamNotFoundError)).to eq('constant')
      expect(defined?(EventModeling::InvalidEventError)).to eq('constant')
      expect(defined?(EventModeling::InvalidCommandError)).to eq('constant')
    end

    it 'includes version constant' do
      expect(defined?(EventModeling::VERSION)).to eq('constant')
      expect(EventModeling::VERSION).to be_a(String)
      expect(EventModeling::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe '.new_event_store' do
    it 'creates a new EventStore instance' do
      event_store = described_class.new_event_store

      expect(event_store).to be_a(EventModeling::EventStore)
    end

    it 'creates independent EventStore instances' do
      event_store1 = described_class.new_event_store
      event_store2 = described_class.new_event_store

      expect(event_store1).not_to equal(event_store2)

      # Test independence
      event_store1.append_event('stream1', { type: 'Event1', data: {} })

      expect(event_store1.get_events('stream1')).not_to be_empty
      expect(event_store2.get_events('stream1')).to be_empty
    end
  end

  describe '.new_event' do
    let(:event_type) { 'UserCreated' }
    let(:event_data) { { name: 'John', email: 'john@example.com' } }

    it 'creates a new Event instance' do
      event = described_class.new_event(type: event_type, data: event_data)

      expect(event).to be_a(EventModeling::Event)
      expect(event.type).to eq(event_type)
      expect(event.data).to eq(event_data)
    end

    it 'creates events with validation' do
      expect do
        described_class.new_event(type: 123, data: event_data)
      end.to raise_error(EventModeling::InvalidEventError, 'Event type must be a String')
    end

    it 'creates events without version or timestamp' do
      event = described_class.new_event(type: event_type, data: event_data)

      expect(event.version).to be_nil
      expect(event.timestamp).to be_nil
    end

    it 'creates independent Event instances' do
      event1 = described_class.new_event(type: event_type, data: event_data)
      event2 = described_class.new_event(type: event_type, data: event_data)

      expect(event1).not_to be(event2)
      expect(event1).to eq(event2)
    end
  end

  describe '.new_command' do
    let(:command_type) { 'CreateUser' }
    let(:command_data) { { name: 'John', email: 'john@example.com' } }

    it 'creates a new Command instance' do
      command = described_class.new_command(type: command_type, data: command_data)

      expect(command).to be_a(EventModeling::Command)
      expect(command.type).to eq(command_type)
      expect(command.data).to eq(command_data)
      expect(command.command_id).to be_a(String)
      expect(command.created_at).to be_a(Time)
    end

    it 'creates commands with validation' do
      expect do
        described_class.new_command(type: 123, data: command_data)
      end.to raise_error(EventModeling::InvalidCommandError, 'Command type must be a String')
    end

    it 'accepts explicit command_id and created_at' do
      custom_id = 'custom-command-id'
      custom_time = Time.parse('2025-01-01 12:00:00 UTC')

      command = described_class.new_command(
        type: command_type,
        data: command_data,
        command_id: custom_id,
        created_at: custom_time
      )

      expect(command.command_id).to eq(custom_id)
      expect(command.created_at).to eq(custom_time)
    end

    it 'creates independent Command instances' do
      command1 = described_class.new_command(type: command_type, data: command_data)
      command2 = described_class.new_command(type: command_type, data: command_data)

      expect(command1).not_to be(command2)
      expect(command1).not_to eq(command2) # Different command_ids
      expect(command1.command_id).not_to eq(command2.command_id)
    end
  end

  describe 'integration between components' do
    it 'allows Event instances to be used with EventStore' do
      event_store = described_class.new_event_store
      event = described_class.new_event(type: 'UserCreated', data: { name: 'John' })
      stream_id = 'user-123'

      # Use Event#to_h to convert to hash format for EventStore
      event_store.append_event(stream_id, event.to_h)

      stored_events = event_store.get_events(stream_id)
      expect(stored_events.size).to eq(1)

      stored_event = stored_events.first
      expect(stored_event[:type]).to eq('UserCreated')
      expect(stored_event[:data]).to eq({ name: 'John' })
      expect(stored_event[:version]).to eq(1)
      expect(stored_event[:timestamp]).to be_a(Time)
    end

    it 'allows backward compatibility with hash-based events' do
      event_store = described_class.new_event_store
      hash_event = { type: 'UserCreated', data: { name: 'John' } }
      stream_id = 'user-123'

      event_store.append_event(stream_id, hash_event)

      stored_events = event_store.get_events(stream_id)
      expect(stored_events.size).to eq(1)

      stored_event = stored_events.first
      expect(stored_event[:type]).to eq('UserCreated')
      expect(stored_event[:data]).to eq({ name: 'John' })
      expect(stored_event[:version]).to eq(1)
      expect(stored_event[:timestamp]).to be_a(Time)
    end

    it 'maintains proper error handling across components' do
      # Test that ConcurrencyError from EventStore can be caught as EventModeling::Error
      event_store = described_class.new_event_store
      event = { type: 'UserCreated', data: { name: 'John' } }
      stream_id = 'user-123'

      event_store.append_event(stream_id, event) # Version becomes 1

      expect do
        # Try to append with expected version 0, but actual is 1
        event_store.append_event_with_expected_version(stream_id, event, 0)
      rescue EventModeling::Error => e
        expect(e).to be_a(EventModeling::ConcurrencyError)
        raise 'caught as expected'
      end.to raise_error('caught as expected')
    end
  end
end
