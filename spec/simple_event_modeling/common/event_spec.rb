# frozen_string_literal: true

require 'spec_helper'

describe SimpleEventModeling::Common::Event do
  describe '#initialize' do
    it 'should have an id, type, payload, metadata, and timestamp' do
      event = described_class.new(type: 'Test',
                                  aggregate_id: '123',
                                  version: 1,
                                  data: { key: 'value' },
                                  metadata: { source: 'test' })
      expect(event).to respond_to(:id)
      expect(event).to respond_to(:type)
      expect(event).to respond_to(:created_at)
      expect(event).to respond_to(:aggregate_id)
      expect(event).to respond_to(:version)
      expect(event).to respond_to(:data)
      expect(event).to respond_to(:metadata)
    end
  end
end
