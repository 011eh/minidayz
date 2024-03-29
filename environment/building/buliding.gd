extends Node2D

class_name Building

# 向 Door 发射的信号
signal transparency_changed


var global_visiable_rect: Rect2
@export
var building_sprites: Array[NodePath]


func _ready():
	y_sort_enabled = true
	
	%InteriorArea.body_entered.connect(func(player: Node2D) -> void:
		change_transparency(0, true)
		transparency_changed.emit(0.2)
	)
	%InteriorArea.body_exited.connect(func(player: Node2D) -> void:
		change_transparency(1)
		transparency_changed.emit(1)
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
	if %InteriorArea.get_overlapping_bodies().is_empty():
		var player_pos := get_tree().get_first_node_in_group('player').global_position as Vector2
		if global_visiable_rect.has_point(player_pos):
			change_transparency(0.2)
			transparency_changed.emit(0.2)
		else:
			change_transparency(1)
			transparency_changed.emit(1)

func change_transparency(value: float, only_outside: bool = false) -> void:
	if only_outside:
		for name in building_sprites:
			var sprite := get_node(name) as Sprite2D
			sprite.self_modulate.a = value if sprite == %Outside else 1
		return
	
	for sprite in building_sprites:
		get_node(sprite).self_modulate.a = value
	
	
