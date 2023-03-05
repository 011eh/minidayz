extends Control


signal test

#@export
#var n := 1
#
#func _init():
#	print_info()
#	print(n)
#
#func _enter_tree():
#	print_info()
#	print(n)
#
#func _ready():
#	print(n)
#	print_info()
#
#func _exit_tree():
#	print_info()
#
#func _input(event):
#	print_info()
#
#func _unhandled_input(event):
#	print_info()
#
#func _unhandled_key_input(event):
#	print_info()
#
#
#func _shortcut_input(event):
#	print_info()
#func _notification(what):
#	print_info()
#	print(what)

#func _process(delta):
#	print_info()
#
#func _physics_process(delta):
#	print_info()

func _gui_input(event):
	if event.is_action_pressed('open_item_menu'):
		print_info()

func print_info():
	print(name, ' ', get_stack()[1]['function'])
