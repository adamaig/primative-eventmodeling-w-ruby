# frozen_string_literal: true

module CartSpecHelpers
  def given_events(events)
    events.each { |event| store.append(event) }
  end

  def when_command(aggregate, command)
    aggregate.handle(command)
  end

  def then_events(events)
    expect(store.events).to match(events)
  end

  def then_events_include(events)
    expect(store.events).to include(events)
  end

  def then_query_result(query, result)
    expect(query.execute).to match(result)
  end
end
