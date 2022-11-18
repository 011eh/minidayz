extends Node2D

func _process(delta):
	if Input.is_action_pressed('ui_up'):
		var animation = $AnimationPlayer.get_animation('run_down') as Animation
		animation.track_set_path(0, "Skin:frame")
		animation.track_set_key_value(0,0,1)
		
	if Input.is_action_pressed('ui_down'):
		var animation = $AnimationPlayer.get_animation('run_down') as Animation
		animation.track_set_path(0, "Skin:frame")
		animation.track_set_key_value(0,0,4)
		
