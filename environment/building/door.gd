extends Sprite2D

class_name Door


var tween: Tween
var is_opened := false
var tween_callable: Callable


func _ready():
	
	get_parent().transparency_changed.connect(func(value) -> void:
		self_modulate.a = value
	)
	
	if %StaticBody2D.get_child_count() == 1:
		$InteractionArea.interaction_inputted.connect(func():
			is_opened = not is_opened
			tween = create_tween()
			tween.tween_property(%Door1, 'rotation', deg_to_rad(0 if is_opened else 90), 0)
			tween.tween_property(self, 'frame', 1 if is_opened else 0, 0)
			tween.play()
		)
	else:
		# double door
		$InteractionArea.interaction_inputted.connect(func():
			is_opened = not is_opened
			tween = create_tween()
			tween.tween_property(%Door1, 'rotation', deg_to_rad(0 if is_opened else 90), 0)
			tween.tween_property(%Door2, 'rotation', deg_to_rad(0 if is_opened else -90), 0)
			tween.tween_property(self, 'frame', 1 if is_opened else 0, 0)
			tween.play()
		)
