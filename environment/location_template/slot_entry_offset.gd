@tool
class_name SlotEntryOffset
extends Resource


@export
var scene: PackedScene = null:
	set(value):
		scene = value
		emit_changed()

@export
var offset: Vector2 = Vector2.ZERO:
	set(value):
		offset = value
		emit_changed()
