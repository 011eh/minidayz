extends Node2D


@onready
var ground := $Ground
var size = 224

func _ready():
	PlayerStatus.speed = 5000
	pass
