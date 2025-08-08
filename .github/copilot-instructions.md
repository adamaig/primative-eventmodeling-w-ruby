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

### Implementation Process
1. **Write Tests**: Implement comprehensive specs before writing code
2. **Implement Methods**: Make tests pass with clean, idiomatic Ruby code
3. **Add Documentation**: Include comprehensive YARD documentation for all public methods
4. **Validate**: Run full test suite to ensure everything works correctly

### Code Quality Standards
- **Ruby Style**: Follow established library conventions and RuboCop rules
- **YARD Documentation**: Comprehensive docs for all public methods and classes  
- **Error Handling**: Consistent error patterns following library standards
- **Immutability**: Follow library patterns for immutable objects
- **Version Control**: Use atomic commits for each spec implementation
- **Session Boundaries**: Each session should focus on a single conceptual change

### Refactoring Guidelines
- **Single Responsibility Per Commit**: Each commit should contain exactly one conceptual change
- **Atomic Changes**: Complete one logical unit of work before moving to the next
- **Test-Driven Refactoring**: Write failing tests first, then make them pass
- **Incremental Steps**: Break large refactorings into small, verifiable steps
- **Backward Compatibility**: Maintain all existing interfaces during incremental changes
- **Validation Between Steps**: Run full test suite after each atomic change

### Commit Message Guidelines
- Use present tense imperative mood ("Add feature" not "Added feature")
- Start with a verb (Add, Extract, Refactor, Fix, Update)
- Keep first line under 50 characters
- Include detailed description if needed
- Reference relevant specs or documentation changes

### Maximum Change Limits Per Session
- **Files Created**: Maximum 2 new files per session
- **Files Modified**: Maximum 3 existing files per session
- **Lines Changed**: Maximum 100 lines of functional code per session
- **Test Files**: 1 new test file per session, covering the single change
- **Concepts**: Exactly 1 conceptual change per session

### Red Flags for Oversized Changes
- Creating more than 2 files at once
- Modifying the main module AND creating new classes
- Adding both new functionality AND refactoring existing code
- Writing specs for multiple new components simultaneously
- Making changes that span multiple architectural layers

### Documentation Requirements
- All public methods must include comprehensive YARD documentation
- Include `@param`, `@return`, `@raise`, and `@example` tags where applicable
- Document expected behavior, edge cases, and usage patterns
- Use descriptive class and module documentation explaining purpose and patterns
- Include `@since` tags for version tracking
- Mark private methods with `@api private` tag

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
- Comprehensive YARD documentation for all public methods and classes
- Include examples in YARD docs showing typical usage patterns

## Agent Workflow Guidelines

### Incremental Development Approach
- **One Concept Per Session**: Focus on a single, well-defined change per coding session
- **Validate Before Proceeding**: Always run tests after each atomic change
- **Document Progress**: Update chat logs with clear commit boundaries
- **Ask for Confirmation**: Before large changes, propose the specific steps and get user approval

### Refactoring Session Structure
1. **Propose the Change**: Clearly describe what will be modified and why
2. **Break Into Steps**: List specific atomic steps with expected outcomes
3. **Execute One Step**: Implement only the first step
4. **Validate**: Run tests to ensure nothing breaks
5. **Commit**: Create commit with descriptive message
6. **Repeat**: Move to next step only after validation

### When to Stop and Commit
- After extracting a single class or module
- After adding a new feature with its tests
- After fixing a specific bug or issue
- When tests all pass and code is working
- Before making any breaking changes
- When a logical unit of work is complete

### Agent Guidelines for Large Requests

When a user requests a change that would violate the incremental development guidelines:

1. **Acknowledge the Request**: Confirm understanding of the overall goal
2. **Propose Breakdown**: Suggest specific atomic steps to achieve the goal
3. **Explain Benefits**: Briefly explain why smaller steps are better
4. **Get Approval**: Ask user to confirm the first step before proceeding
5. **Execute One Step**: Complete only the first atomic change
6. **Return for Next Step**: After validation, ask for permission to continue

### Example Response Pattern
```
I understand you want to [overall goal]. This is a great improvement that will [benefits].

To ensure quality and maintainability, I recommend breaking this into these atomic steps:

1. [First step] - This will [specific outcome]
2. [Second step] - This will [specific outcome]  
3. [Third step] - This will [specific outcome]

This approach reduces risk and makes each change easier to review and debug.

Should I proceed with step 1: [specific description]?
```

### Session Documentation Pattern
Each agent session should follow this pattern:
```markdown
## Session Goal
Single sentence describing the specific change

## Planned Steps
1. Step 1 with expected outcome
2. Step 2 with expected outcome
3. Step 3 with expected outcome

## Execution
- [ ] Step 1 completed, tests pass
- [ ] Step 2 completed, tests pass  
- [ ] Step 3 completed, tests pass
- [ ] Final validation, ready for commit

## Commit Message
"Verb: specific change description"
```
- **Session Documentation**: Save all AI pair programming sessions in `/agent_chats/` directory
- **File Naming**: Create new file for each git commit cycle, with datetime prefix in format `YYYYMMDD-HH.MM_session_theme.md` (e.g., `20250726-12.30_library_refactoring_plan.md`, `20250726-14.15_implementing_stream_management.md`)
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
