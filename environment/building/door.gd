extends Sprite2D


@export 
var double_door := false

var tween: Tween


func _ready():
	tween = create_tween()
	tween.tween_property(%Door1, 'rotation', deg_to_rad(90), 0)
	if double_door:
		tween.tween_property(%Door2, 'rotation', deg_to_rad(-90), 0)
	else:
		%Door2.queue_free()
	tween.play()
	tween.stop()

func _process(delta):
	pass
