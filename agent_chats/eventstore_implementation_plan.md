# EventStore Implementation Plan - BDD Cycle for All Methods

**Date**: July 25, 2025  
**Project**: EventModeling Ruby - EventStore Interface Implementation  
**Approach**: Red-Green-Refactor BDD with Agent Chat Documentation

## Implementation Strategy

Each method will follow this cycle:
1. **RED**: Write failing specs (convert pending specs to complete tests)
2. **GREEN**: Implement minimal code to make specs pass
3. **REFACTOR**: Clean up implementation while keeping tests green
4. **DOCUMENT**: Create agent chat session summary for the cycle

## Method Implementation Order

### Phase 1: Core Event Retrieval (Foundation)
These methods are dependencies for other features and should be implemented first.

#### 1. `get_events_from_version(stream_id, version)`
- **Priority**: High (needed for other methods)
- **Specs to Write**:
  - Returns events from specific version onwards
  - Returns empty array if version is higher than stream
  - Returns all events if version is 1 or 0
  - Handles non-existent streams
- **Implementation Notes**: Filter existing `@streams[stream_id]` by version
- **Chat Session**: `implementing_get_events_from_version.md`

#### 2. `get_all_events(from_position = 0)`
- **Priority**: High (global event access)
- **Specs to Write**:
  - Returns all events across all streams
  - Maintains chronological order by timestamp
  - Supports optional from_position parameter
  - Returns empty array when no events exist
- **Implementation Notes**: Flatten all streams, sort by timestamp
- **Chat Session**: `implementing_get_all_events.md`

### Phase 2: Stream Management (Core Operations)
Basic stream lifecycle and metadata management.

#### 3. `stream_exists?(stream_id)`
- **Priority**: High (used by other methods)
- **Specs to Write**:
  - Returns true for streams with events
  - Returns false for non-existent streams
  - Returns false after stream deletion
- **Implementation Notes**: Check if `@streams[stream_id]` exists and not empty
- **Chat Session**: `implementing_stream_exists.md`

#### 4. `get_stream_version(stream_id)`
- **Priority**: High (needed for concurrency control)
- **Specs to Write**:
  - Returns current version number for existing streams
  - Returns 0 for non-existent streams
  - Updates correctly after events are appended
- **Implementation Notes**: Return `@streams[stream_id].length` or 0
- **Chat Session**: `implementing_get_stream_version.md`

#### 5. `get_stream_metadata(stream_id)`
- **Priority**: Medium (concurrency support)
- **Specs to Write**:
  - Returns hash with version, created_at, last_event_timestamp
  - Returns nil for non-existent streams
  - Updates metadata after events are appended
- **Implementation Notes**: Build metadata hash from stream data
- **Chat Session**: `implementing_get_stream_metadata.md`

### Phase 3: Advanced Event Retrieval (Query Features)
More sophisticated querying capabilities.

#### 6. `get_events_by_type(event_type)`
- **Priority**: Medium (filtering capability)
- **Specs to Write**:
  - Filters events across all streams by type
  - Returns events in chronological order
  - Returns empty array for non-existent types
  - Case-sensitive type matching
- **Implementation Notes**: Filter all events by `event[:type]`
- **Chat Session**: `implementing_get_events_by_type.md`

#### 7. `get_events_in_range(from_timestamp, to_timestamp)`
- **Priority**: Medium (time-based queries)
- **Specs to Write**:
  - Returns events within time range (inclusive)
  - Handles edge cases (nil timestamps, reverse order)
  - Returns empty array for invalid ranges
  - Maintains chronological order
- **Implementation Notes**: Filter all events by timestamp range
- **Chat Session**: `implementing_get_events_in_range.md`

### Phase 4: Concurrency Control (Advanced Features)
Optimistic concurrency and version management.

#### 8. `append_event_with_expected_version(stream_id, event, expected_version)`
- **Priority**: High (concurrency safety)
- **Specs to Write**:
  - Appends event when expected version matches current
  - Raises ConcurrencyError when versions don't match
  - Handles non-existent streams (expected_version = 0)
  - Updates version correctly after successful append
- **Implementation Notes**: Check version before append, raise custom error
- **Chat Session**: `implementing_append_event_with_expected_version.md`

### Phase 5: Pub/Sub Subscriptions (Real-time Features)
Observer pattern for real-time event notifications.

#### 9. `subscribe_to_stream(stream_id, callback)`
- **Priority**: Medium (real-time notifications)
- **Specs to Write**:
  - Stores callback for stream notifications
  - Calls callback when events are appended to stream
  - Supports multiple subscribers per stream
  - Handles callback errors gracefully
- **Implementation Notes**: Store callbacks in `@subscriptions` hash, notify on append
- **Chat Session**: `implementing_subscribe_to_stream.md`

### Phase 6: Stream Lifecycle (Data Management)
Stream deletion and cleanup operations.

#### 10. `delete_stream(stream_id)`
- **Priority**: Low (cleanup operations)
- **Specs to Write**:
  - Marks stream as deleted (soft delete)
  - Prevents new events from being appended
  - Stream still exists but is marked deleted
  - Returns success/failure status
- **Implementation Notes**: Add `@deleted_streams` set, check before append
- **Chat Session**: `implementing_delete_stream.md`

### Phase 7: Performance Optimization (Optional Features)
Snapshot functionality for aggregate optimization.

#### 11. `save_snapshot(stream_id, version, snapshot_data)`
- **Priority**: Low (optimization)
- **Specs to Write**:
  - Stores snapshot for specific stream version
  - Overwrites existing snapshots for same version
  - Validates version exists in stream
  - Returns success confirmation
- **Implementation Notes**: Store in `@snapshots` hash with composite key
- **Chat Session**: `implementing_save_snapshot.md`

#### 12. `get_snapshot(stream_id)`
- **Priority**: Low (optimization)
- **Specs to Write**:
  - Returns most recent snapshot for stream
  - Returns nil if no snapshots exist
  - Includes snapshot version and data
  - Helps optimize aggregate reconstruction
- **Implementation Notes**: Find latest snapshot by version
- **Chat Session**: `implementing_get_snapshot.md`

### Phase 8: Transaction Support (Future Enhancement)
Optional commit functionality for transaction-like behavior.

#### 13. `commit`
- **Priority**: Low (advanced feature)
- **Specs to Write**:
  - No-op implementation (events already persisted)
  - Could support batching in future
  - Returns success status
  - Maintains compatibility with transaction patterns
- **Implementation Notes**: Simple success return for in-memory store
- **Chat Session**: `implementing_commit.md`

## BDD Cycle Template for Each Method

### Red Phase (Failing Tests)
```ruby
describe '#method_name' do
  it 'does something specific' do
    # Arrange - set up test data
    # Act - call the method
    # Assert - expect specific behavior
    expect { event_store.method_name }.to raise_error(NoMethodError)
  end
end
```

### Green Phase (Minimal Implementation)
```ruby
def method_name(params)
  # Minimal implementation to make tests pass
  # Focus on making tests green, not perfect code
end
```

### Refactor Phase (Clean Implementation)
```ruby
def method_name(params)
  # Clean, well-structured implementation
  # Proper error handling
  # Clear variable names
  # Follows Ruby conventions
end
```

## Chat Session Documentation Template

Each session should follow this structure:

```markdown
# Implementing [method_name] Method - Chat Session

**Date**: [date] - [time] UTC  
**Agent**: GitHub Copilot (GPT-4)  
**Theme**: Implementing EventStore [method_name] with BDD cycle

## Summary

### BDD Cycle Completion
- **RED**: [Description of failing specs written]
- **GREEN**: [Description of minimal implementation]
- **REFACTOR**: [Description of clean-up improvements]

### Technical Decisions Made
- [Key implementation choices]
- [Data structure decisions]
- [Error handling approach]

### Testing Strategy
- [Spec coverage approach]
- [Edge cases tested]
- [Integration with existing methods]

### Next Steps
- [What methods to implement next]
- [Dependencies resolved]
- [Future considerations]

---

## Full Conversation
[Complete chat transcript]
```

## Integration Testing Strategy

After every 3-4 methods, run integration tests to ensure:
- Methods work together correctly
- Performance is acceptable
- Memory usage is reasonable
- All existing specs still pass

## Completion Metrics

- **Total Methods**: 13 methods to implement
- **Estimated Sessions**: 13 chat sessions (one per method)
- **Test Coverage**: 100% of EventStore interface
- **Documentation**: Complete chat history for each implementation cycle

## Dependencies Map

```
get_events_from_version → append_event_with_expected_version
get_stream_version → append_event_with_expected_version
stream_exists? → delete_stream
get_all_events → get_events_by_type, get_events_in_range
subscribe_to_stream → append_event, append_events (notification triggers)
```

This plan ensures systematic implementation following TDD principles while maintaining comprehensive documentation for future AI agents and developers.
