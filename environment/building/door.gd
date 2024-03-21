extends Sprite2D


var tween: Tween
var is_opened := false
var tween_callable: Callable


func _ready():
	print(%StaticBody2D.get_child_count())
	if %StaticBody2D.get_child_count() == 1:
		$InteractionArea.interaction_inputted.connect(func():
			tween = create_tween()
			tween.tween_property(%Door1, 'rotation', deg_to_rad(0 if is_opened else 90), 0)
			tween.tween_property(self, 'frame', 0 if is_opened else 1, 0)
			is_opened = not is_opened
			tween.play()
		)
	else:
		$InteractionArea.interaction_inputted.connect(func():
			tween = create_tween()
			tween.tween_property(%Door1, 'rotation', deg_to_rad(0 if is_opened else 90), 0)
			tween.tween_property(%Door2, 'rotation', deg_to_rad(0 if is_opened else -90), 0)
			tween.tween_property(self, 'frame', 1 if is_opened else 0, 0)
			is_opened = not is_opened
			tween.play()
		)
