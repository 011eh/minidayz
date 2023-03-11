extends Node

var o:=[]

func _ready():
	$NinePatchRect/Panel.set_button_action(print33.bind(3))

func print33(n):
	print(n)
