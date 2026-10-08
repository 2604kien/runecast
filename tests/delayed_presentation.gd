extends "res://scripts/ui/combat_presentation.gd"

var batches: Array = []
var completions: Array[Callable] = []
var cancellations := 0
var on_cancel: Callable

func present(result: Dictionary, completed: Callable) -> void:
	batches.append(result)
	completions.append(completed)

func complete(index: int = -1) -> void:
	completions[index].call()

func cancel() -> void:
	cancellations += 1
	# Deliberately hostile seam: cancel synchronously completes, and keeps old callbacks.
	if not completions.is_empty():
		complete()
	if on_cancel.is_valid():
		on_cancel.call()
