# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventModeling::Error do
  describe 'inheritance' do
    it 'inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'instantiation' do
    it 'can be raised with a message' do
      expect { raise described_class, 'test error' }.to raise_error(described_class, 'test error')
    end

    it 'can be raised without a message' do
      expect { raise described_class }.to raise_error(described_class)
    end
  end
end

RSpec.describe EventModeling::ConcurrencyError do
  describe 'inheritance' do
    it 'inherits from EventModeling::Error' do
      expect(described_class).to be < EventModeling::Error
    end

    it 'indirectly inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'usage' do
    it 'can be raised with a concurrency message' do
      message = "Expected version 1, but current version is 2 for stream 'user-123'"
      expect { raise described_class, message }.to raise_error(described_class, message)
    end

    it 'can be caught as EventModeling::Error' do
      expect do
        raise described_class, 'concurrency conflict'
      rescue EventModeling::Error => e
        expect(e).to be_a(described_class)
        raise 'caught successfully'
      end.to raise_error('caught successfully')
    end
  end
end

RSpec.describe EventModeling::StreamNotFoundError do
  describe 'inheritance' do
    it 'inherits from EventModeling::Error' do
      expect(described_class).to be < EventModeling::Error
    end

    it 'indirectly inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'usage' do
    it 'can be raised with a stream not found message' do
      message = "Stream 'user-456' not found"
      expect { raise described_class, message }.to raise_error(described_class, message)
    end

    it 'can be caught as EventModeling::Error' do
      expect do
        raise described_class, 'stream not found'
      rescue EventModeling::Error => e
        expect(e).to be_a(described_class)
        raise 'caught successfully'
      end.to raise_error('caught successfully')
    end
  end
end

RSpec.describe EventModeling::InvalidEventError do
  describe 'inheritance' do
    it 'inherits from EventModeling::Error' do
      expect(described_class).to be < EventModeling::Error
    end

    it 'indirectly inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'usage' do
    it 'can be raised with an invalid event message' do
      message = 'Event type must be a String'
      expect { raise described_class, message }.to raise_error(described_class, message)
    end

    it 'can be caught as EventModeling::Error' do
      expect do
        raise described_class, 'invalid event data'
      rescue EventModeling::Error => e
        expect(e).to be_a(described_class)
        raise 'caught successfully'
      end.to raise_error('caught successfully')
    end
  end
end

RSpec.describe EventModeling::InvalidCommandError do
  describe 'inheritance' do
    it 'inherits from EventModeling::Error' do
      expect(described_class).to be < EventModeling::Error
    end

    it 'indirectly inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'usage' do
    it 'can be raised with an invalid command message' do
      message = 'Command type must be a String'
      expect { raise described_class, message }.to raise_error(described_class, message)
    end

    it 'can be caught as EventModeling::Error' do
      expect do
        raise described_class, 'invalid command data'
      rescue EventModeling::Error => e
        expect(e).to be_a(described_class)
        raise 'caught successfully'
      end.to raise_error('caught successfully')
    end
  end
end
