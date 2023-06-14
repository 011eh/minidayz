extends Node2D

class_name Building


var player: Player
var camera_entered := false
@onready
var area := %DetectionArea as Area2D


func _ready():
	
	y_sort_enabled = true
	area.area_entered.connect(func(area: Area2D) -> void:
		camera_entered = true
		player = area.owner
	)
	area.area_exited.connect(func(area: Area2D) -> void:
		camera_entered = false
		change_transparent(1)
	)

func _process(delta):
	if camera_entered:
		var player_y := player.position.y
		if player_y < %Inside.position.y:
			change_transparent(0.2)
			return
		if player_y >= %Inside.position.y and player_y < %Outside.position.y:
			change_transparent(1)
			return

func change_transparent(value: float, only_outside: bool = false) -> void:
	if only_outside:
		%Outside.modulate.a = value
	else:
		get_tree().call_group('building_sprites', 'set_indexed', 'modulate:a', value)
