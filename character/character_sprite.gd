extends Node2D


func set_texture(node_name: String,texture :Texture) -> void:
	var sprite = get_node(node_name) as Sprite2D
	sprite.texture = texture 
