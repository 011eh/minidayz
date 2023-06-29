extends Node2D

class_name Building


var global_visiable_rect: Rect2
@export
var building_sprites: Array[NodePath]


func _ready():
	y_sort_enabled = true
	
	%InteriorArea.body_entered.connect(func(player: Node2D) -> void:
		change_transparent(0, true)
	)
	%InteriorArea.body_exited.connect(func(player: Node2D) -> void:
		change_transparent(1)
	)
	
	set_process(false)
	if is_instance_valid(get_tree().get_first_node_in_group('player')):
		global_visiable_rect = %VisibleNotifier.rect
		global_visiable_rect.size *= %VisibleNotifier.scale
		global_visiable_rect.position = to_global(%VisibleNotifier.position)
		%VisibleNotifier.screen_entered.connect(func()-> void:
			set_process(true)
		)
		%VisibleNotifier.screen_exited.connect(func()-> void:
			set_process(false)
		)

func _process(delta):
	var player_pos := get_tree().get_first_node_in_group('player').global_position as Vector2
	if global_visiable_rect.has_point(player_pos):
		change_transparent(0.2)
	elif %InteriorArea.get_overlapping_bodies().is_empty():
		change_transparent(1)

func change_transparent(value: float, only_outside: bool = false) -> void:
	if only_outside:
		%Outside.modulate.a = value
		return
	
	for sprite in building_sprites:
		get_node(sprite).modulate.a = value
