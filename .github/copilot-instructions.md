# EventModeling Ruby - Copilot Instructions

## Project Overview
This is an educational Ruby library exploring event-driven architecture patterns using EventStore concepts. The project follows a test-driven development approach with comprehensive specs defining the EventStore interface before implementation.

## Architecture & Design Patterns

### Core Module Structure
- **`EventModeling`** - Main module containing all components
- **`EventModeling::EventStore`** - Central class implementing event persistence and retrieval
- Events are structured as hashes with `type`, `data`, `version`, and `timestamp` fields
- Streams are identified by string IDs and contain sequentially versioned events

### Event Store Interface Pattern
The EventStore follows a comprehensive interface pattern with these core method groups:
1. **Event Persistence**: `append_event(stream_id, event)`, `append_events(stream_id, events)`, `commit`
2. **Event Retrieval**: `get_events(stream_id)`, `get_events_from_version`, `get_all_events`
3. **Stream Management**: `stream_exists?`, `get_stream_version`, `delete_stream`
4. **Concurrency Control**: `append_event_with_expected_version`, `get_stream_metadata`
5. **Querying**: `get_events_by_type`, `get_events_in_range`, `subscribe_to_stream`
6. **Snapshots**: `save_snapshot`, `get_snapshot` (optional optimization)

## Development Workflow

### Test-First Development
- Specs in `/spec/event_modeling_spec.rb` define the complete EventStore interface
- Most methods have pending specs - implement specs first, then make them pass
- Use `bundle exec rspec` to run tests
- Use `bundle exec guard` for continuous testing during development

### Event Structure Convention
```ruby
# Standard event format (input)
event = {
  type: 'UserCreated',        # Event type as string
  data: { name: 'John' }      # Event payload as hash
}

# Enhanced format (after EventStore processing)
stored_event = {
  type: 'UserCreated',        # Original event type
  data: { name: 'John' },     # Original event payload
  version: 1,                 # Sequential version (added by EventStore)
  timestamp: Time.now         # Added by EventStore on append
}

# Subscription callback format
subscription = ->(event) { puts "New event: #{event[:type]}" }
event_store.subscribe_to_stream(stream_id, subscription)
```

### Stream Versioning Rules
- Events within a stream get sequential version numbers starting from 1
- `append_events` maintains version sequence across the batch
- Version numbers continue from existing events in the stream
- Different streams maintain independent version sequences

## Key Implementation Guidelines

### In-Memory Persistence Strategy
- **Storage**: All events stored in memory only (no database/file persistence)
- **Data Structure**: Use Hash for stream storage with arrays for event sequences
- **Lifecycle**: Event data persists only during application runtime
- **Testing**: Each test gets a fresh EventStore instance

### Event Persistence Behavior
- `append_event` adds single events with automatic versioning and timestamping
- `append_events` handles batches while maintaining order and sequential versioning
- Events are immutable once appended
- Streams are created implicitly when first event is appended

### Snapshot Implementation
- **Manual Triggers**: Snapshots created explicitly via `save_snapshot` calls
- **Storage Strategy**: Store snapshots alongside events in memory structures
- **Version Linking**: Snapshots reference specific stream versions for consistency
- **Retrieval**: `get_snapshot` returns most recent snapshot for optimization

### Pub/Sub Subscription Model
- **Pattern**: Use observer/pub-sub pattern for `subscribe_to_stream`
- **Callbacks**: Store callback functions/blocks for stream notifications
- **Real-time**: Notify subscribers immediately when events are appended
- **Scope**: Subscriptions are stream-specific, not global

### Testing Patterns
- Use `let` blocks for shared test data: `stream_id`, `event`, `event_store`
- Test both single operations and batch operations
- Verify version numbering, timestamps, and stream isolation
- Include edge cases like empty arrays and non-existent streams
- Mock/stub Time.now for timestamp testing consistency

### Ruby Conventions
- Use `frozen_string_literal: true` pragma
- Follow module namespacing: `EventModeling::ClassName`
- Auto-require all lib files via `spec_helper.rb` pattern
- Use RSpec matchers like `have(n).items` for collection assertions

## Agent Conversation Tracking
- **Session Documentation**: Save all AI pair programming sessions in `/agent_chats/` directory
- **File Naming**: Create new file for each git commit cycle, named by session theme (e.g., `adding_eventstore_interfaces.md`, `implementing_stream_management.md`)
- **Header Format**: Include date with timestamp, agent name with model (e.g., "GitHub Copilot (GPT-4)", "Claude Sonnet 3.5"), and session theme
- **Content Structure**: Two main sections:
  1. **Summary Section**: Key insights, implementation decisions, architecture changes, and next steps
  2. **Full Conversation**: Direct copy of the complete chat session with all user requests and AI responses
- **Session Continuity**: Reference previous chat files when continuing work on related EventStore features
- **Documentation Purpose**: These files serve as context for future AI agents and development decisions

## Development Environment
- Docker-based dev container with Ruby, RSpec, Guard, and RuboCop pre-installed
- Use Guard for continuous testing: `bundle exec guard`
- RuboCop for code style: `bundle exec rubocop`
- Auto-loading of lib files configured in spec_helper
