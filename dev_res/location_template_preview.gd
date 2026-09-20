extends Node


const CAMERA_ZOOM := 0.62

var seed_value: int = 0


func _ready() -> void:
	var block := get_parent() as LocationTemplate
	if block == null:
		return

	var camera := Camera2D.new()
	camera.position = Vector2.ONE * (LocationTemplate.BLOCK_PX * 0.5)
	camera.zoom = Vector2.ONE * CAMERA_ZOOM
	add_child(camera)

	var label := Label.new()
	label.position = Vector2(12, 8)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.text = "\n".join(_report(block))

	var layer := CanvasLayer.new()
	layer.add_child(label)
	add_child(layer)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_R:
		return
	# reload 会立刻把本节点摘出场景树，之后 get_viewport() 返回 null，所以先标记已处理再重载。
	get_viewport().set_input_as_handled()
	# 重载整个场景即可重跑 _ready，拿到新的随机种子。
	get_tree().reload_current_scene()


func _report(block: LocationTemplate) -> PackedStringArray:
	var lines: PackedStringArray = ["seed = %d    (R 重掷)" % seed_value]
	var slots := block.slots
	if slots == null:
		return lines
	for child in slots.get_children():
		# queue_free 要到帧末才生效，此刻已抽完的槽位还挂在树上，跳过。
		if child is TemplateSlot or child.is_queued_for_deletion():
			continue
		var spawned := child as Node2D
		if spawned == null or spawned.scene_file_path.is_empty():
			continue
		lines.append("%s  @ (%d, %d)" % [
			spawned.scene_file_path.get_file().get_basename(),
			spawned.position.x, spawned.position.y])
	return lines
