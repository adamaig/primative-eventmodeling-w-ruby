package common_test

import (
	"testing"

	"gpt5/common"
)

type testEvent struct {
	aggregateID string
	version     int
}

func (e testEvent) AggregateID() string { return e.aggregateID }
func (e testEvent) Version() int        { return e.version }

func TestEventStore_AppendAndStreams(t *testing.T) {
	es := common.NewEventStore()
	e1 := common.NewEvent("T", "1", 1, nil, nil)
	e2 := common.NewEvent("T", "1", 2, nil, nil)
	e3 := common.NewEvent("T", "2", 1, nil, nil)

	es.Append(e1)
	es.Append(e2)
	es.Append(e3)

	if len(es.All()) != 3 {
		t.Fatalf("expected 3 events, got %d", len(es.All()))
	}

	s1, err := es.GetStream("1")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(s1) != 2 {
		t.Fatalf("expected 2 events in stream 1, got %d", len(s1))
	}

	s2, err := es.GetStream("2")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(s2) != 1 {
		t.Fatalf("expected 1 event in stream 2, got %d", len(s2))
	}
}

func TestEventStore_GetStream_NotFound(t *testing.T) {
	es := common.NewEventStore()
	if _, err := es.GetStream("non_existent"); err == nil {
		t.Fatal("expected StreamNotFoundError, got nil")
	}
}

func TestEventStore_GetStreamVersion(t *testing.T) {
	es := common.NewEventStore()
	es.Append(common.NewEvent("T", "1", 1, nil, nil))
	es.Append(common.NewEvent("T", "1", 2, nil, nil))
	if v := es.GetStreamVersion("1"); v != 2 {
		t.Fatalf("expected version 2, got %d", v)
	}
}
