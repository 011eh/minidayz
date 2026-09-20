@tool
class_name SlotPool
extends Resource


@export
var entries: Array[PackedScene] = []:
	set(value):
		entries = value
		emit_changed()


func pick(rng: RandomNumberGenerator) -> PackedScene:
	var index := pick_index(rng)
	return entries[index] if index >= 0 else null


func pick_index(rng: RandomNumberGenerator) -> int:
	if entries.is_empty():
		return -1
	return rng.randi() % entries.size()
