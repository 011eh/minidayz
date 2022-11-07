extends Node2D

@onready var player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	var animation = Animation.new()
	var track=animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track,"Zed:frame")
	animation.track_insert_key(track,0,4)
	animation.track_insert_key(track,0.1,5)
	animation.track_insert_key(track,0.2,6)
	animation.track_insert_key(track,0.3,7)
	animation.length=0.4
	animation.loop_mode=1
	player.get_animation_library(player.get_animation_library_list()[0]).add_animation('run_up',animation)
	animation.value_track_set_update_mode(track,2)
	player.play('run_up')
