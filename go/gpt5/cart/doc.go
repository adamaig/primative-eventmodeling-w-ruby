// Package cart implements a simple shopping cart domain using the common
// SimpleEventModeling primitives. Commands and events are data-only; the
// aggregate validates and emits events, hydrating by replay.
package cart
