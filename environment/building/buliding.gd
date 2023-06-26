extends Node2D

class_name Building


var player: Player
@onready
var interior_zone := Rect2(%Inside.global_position, %Inside.get_rect().size + %Inside.offset)

func _ready():
	y_sort_enabled = true
	
	%Inside.add_to_group('building_sprites_%d' % get_instance_id())
	%Outside.add_to_group('building_sprites_%d' % get_instance_id())
	
	var outside_rect := Rect2(%Outside.position + %Outside.offset, %Outside.get_rect().size)
	%DetectionArea/CollisionShape2D.shape.size = outside_rect.size + Vector2(
		ProjectSettings.get_setting('display/window/size/viewport_width'),
		ProjectSettings.get_setting('display/window/size/viewport_height') / 2
	)
	%DetectionArea/CollisionShape2D.position = Vector2(
		outside_rect.get_center().x,
		outside_rect.get_center().y - (%DetectionArea/CollisionShape2D.shape.size.y - outside_rect.size.y) / 2
		)
	%DetectionArea.body_entered.connect(func(player: Node2D) -> void:
		self.player = player
	)
	%DetectionArea.body_exited.connect(func(player: Node2D) -> void:
		change_transparent(1)
		self.player = null
	)

func _process(delta):
	if is_instance_valid(player):
		if in_building(player.global_position):
			change_transparent(0, true)
			return
		
		var player_y := player.global_position.y
		if player_y < %Inside.global_position.y:
			change_transparent(0.2)
			return
		change_transparent(1)

func change_transparent(value: float, only_outside: bool = false) -> void:
	if only_outside:
		%Outside.modulate.a = value
	else:
		get_tree().call_group('building_sprites_%d' % get_instance_id(), 'set_indexed', 'modulate:a', value)

func in_building(position: Vector2) -> bool:
	return interior_zone.has_point(position)
