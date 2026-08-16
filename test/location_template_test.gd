@tool
extends Node2D
## 地块模板测试。
##
## 场景里直接摆着 [LocationTemplate] 实例 —— 编辑器打开即可见槽位贴图预览，
## 可直接拖动 Slots 下的 [TemplateSlot] 调位置，保存即生效（所见即所得）。
##
## 运行时对场景内每个模板调 build()：槽位按 rng 抽候选、实例化、自身 queue_free。
## 按 R 重掷种子重建，用于确认同一建筑槽能落到不同建筑。

const BLOCK_PX := 1020

## 0 = 每次运行随机；非 0 = 固定种子，便于复现某次布局。
@export var fixed_seed: int = 0

## 画出 1020×1020 的地块边界，确认没有槽位越界。
@export var draw_block_bounds: bool = true:
	set(value):
		draw_block_bounds = value
		queue_redraw()

var _sources: Array[PackedScene] = []
var _origins: Array[Vector2] = []
var _label: Label


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# 记下场景里摆好的模板（场景资源 + 位置），重建时照原样还原。
	for child in get_children():
		var block := child as LocationTemplate
		if block == null:
			continue
		_sources.append(load(block.scene_file_path))
		_origins.append(block.position)
		block.free()

	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)
	add_child(layer)

	_rebuild(fixed_seed if fixed_seed != 0 else randi())


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_R:
		_rebuild(randi())
		get_viewport().set_input_as_handled()


func _rebuild(seed_value: int) -> void:
	for child in get_children():
		if child is LocationTemplate:
			child.free()

	var lines: PackedStringArray = ["seed = %d    (R 重掷)" % seed_value]
	for i in _sources.size():
		var block := _sources[i].instantiate() as LocationTemplate
		add_child(block)
		block.position = _origins[i]

		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + i
		# 第二参是 ground.gd 用来汇总路面 cells 的共享字典；本测试无全局 GroundLayer，丢弃即可。
		block.build(rng, {})

		lines.append("%s: %s" % [block.name, _describe(block)])

	if _label != null:
		_label.text = "\n".join(lines)
	queue_redraw()


## 报告各建筑槽实际落成了什么，用于确认候选确实在变。
func _describe(block: LocationTemplate) -> String:
	var slots := block.get_node_or_null(^"Slots")
	if slots == null:
		return "?"
	var names: PackedStringArray = []
	for child in slots.get_children():
		if child is Building:
			names.append(child.scene_file_path.get_file().get_basename())
	return ", ".join(names)


func _draw() -> void:
	if not draw_block_bounds:
		return
	for child in get_children():
		var block := child as LocationTemplate
		if block == null:
			continue
		draw_rect(Rect2(block.position, Vector2(BLOCK_PX, BLOCK_PX)),
			Color(1, 1, 1, 0.35), false, 2.0)
