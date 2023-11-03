extends Sprite2D


var tween: Tween
var is_opened := false
@export 
var double_door := false


func _ready():
	if not double_door:
		%Door2.queue_free()
	
	$InteractionArea.interaction_inputted.connect(func():
		play_door_tween(is_opened)
		is_opened = not is_opened
	)

func play_door_tween(is_opened: bool) -> void:
	tween = create_tween()
	tween.tween_property(%Door1, 'rotation', deg_to_rad(0 if is_opened else 90), 0)
	if double_door:
		tween.tween_property(%Door2, 'rotation', deg_to_rad(0 if is_opened else -90), 0)
	tween.play()

