class_name SlotPick
extends RefCounted


var scene: PackedScene
var position: Vector2


func _init(p_scene: PackedScene, p_position: Vector2) -> void:
	scene = p_scene
	position = p_position
