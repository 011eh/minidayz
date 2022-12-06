extends Node2D

signal em(a)

func _ready():
	var c1= Callable($N2,'print1').bind('a','1')
	var c2= Callable($N2,'print1')
	c1.call()
	c2.call('a',2)
	
