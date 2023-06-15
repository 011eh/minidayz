extends Node2D

class_name Building


var player: Player
var interior_zone: Rect2

func _ready():
	y_sort_enabled = true
	
	var origin_size := %Inside.get_rect().size as Vector2
	interior_zone = Rect2(%Inside.position, origin_size + %Inside.offset)
	
	%DetectionArea.body_entered.connect(func(player: Node2D) -> void:
		self.player = player
	)
	%DetectionArea.body_exited.connect(func(player: Node2D) -> void:
		change_transparent(1)
		self.player = null
	)

func _process(delta):
	if is_instance_valid(player):
		if in_building(player.position):
			change_transparent(0, true)
			return
		
		var player_y := player.position.y
		if player_y < %Inside.position.y:
			change_transparent(0.2)
			return
		change_transparent(1)

func change_transparent(value: float, only_outside: bool = false) -> void:
	if only_outside:
		%Outside.modulate.a = value
	else:
		get_tree().call_group('building_sprites', 'set_indexed', 'modulate:a', value)

func in_building(position: Vector2) -> bool:
	return interior_zone.has_point(position)
