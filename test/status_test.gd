extends Node

func _ready():
	$PlayerStatus.hunger = 0 
	$PlayerStatus.thirst = 0 
	$CanvasLayer/StatusUI.setup($PlayerStatus)

func _unhandled_input(event):
	if event.is_pressed():
		$PlayerStatus.to_restore(1,2)
