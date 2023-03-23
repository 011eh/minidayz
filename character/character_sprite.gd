extends Node2D


func set_texture(index: int, item: Item) -> void:
	var sprite: Sprite2D = get_child(index)
	sprite.texture = item.resource.texture if is_instance_valid(item) else null
