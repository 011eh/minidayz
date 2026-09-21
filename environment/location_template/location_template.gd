@tool
class_name LocationTemplate
extends Node2D


enum Category { VILLAGE, CITY, MILITARY, HOSPITAL, FIRESTATION, SECRET }

@export var category: Category = Category.VILLAGE

const TILE_PX := 60
const BLOCK_SIZE_IN_TILE := 17
const BLOCK_PX := BLOCK_SIZE_IN_TILE * TILE_PX

const STANDALONE_PREVIEW_PATH := "res://dev_res/location_template_preview.gd"

var footprint: TileMapLayer:
	get: return get_node_or_null(^"Footprint") as TileMapLayer

var slots: Node2D:
	get: return get_node_or_null(^"Slots") as Node2D


## 单独运行本场景（F6）时自建一次并挂上调试视图；被 ground.gd 实例化时挂在 Locations 下，不触发。
func _ready() -> void:
	if Engine.is_editor_hint() or get_parent() != get_tree().root:
		return
	var rng := RandomNumberGenerator.new()
	var used_seed := rng.seed
	build(rng, {})
	var preview_script: GDScript = load(STANDALONE_PREVIEW_PATH)
	if preview_script == null:
		return
	var preview: Node = preview_script.new()
	preview.seed_value = used_seed
	add_child(preview)

func build(rng: RandomNumberGenerator, pavement_cells: Dictionary) -> void:
	_collect_footprint(pavement_cells)
	_build_slots(rng)

func _collect_footprint(pavement_cells: Dictionary) -> void:
	var footprint := self.footprint
	if footprint == null:
		return
	
	# 1个 block 为17个 cell，除以 TILE_PX 得 cell 的全局偏移量
	var tile_origin := Vector2i(roundi(position.x / TILE_PX), roundi(position.y / TILE_PX))
	for cell in footprint.get_used_cells():
		pavement_cells[tile_origin + cell] = true
	footprint.queue_free()

func _build_slots(rng: RandomNumberGenerator) -> void:
	var slots := self.slots
	if slots == null:
		return
	# 先快照槽位列表，避免边遍历边 add_child / queue_free。
	var template_slots: Array[TemplateSlot] = []
	for child in slots.get_children():
		if child is TemplateSlot:
			template_slots.append(child as TemplateSlot)
	for t_slot in template_slots:
		var choice := t_slot.pick(rng)
		if choice != null:
			var inst := choice.scene.instantiate()
			slots.add_child(inst)
			var inst_2d := inst as Node2D
			if inst_2d != null:
				inst_2d.position = choice.position
		t_slot.queue_free()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_node_or_null("Footprint") == null:
		warnings.append("缺少 Footprint (TileMapLayer) 子节点。")
	if get_node_or_null("Slots") == null:
		warnings.append("缺少 Slots (Node2D) 子节点。")
	return warnings


@export_group("Editor Preview", "preview_")
@export var preview_bounds: bool = true:
	set(value):
		preview_bounds = value
		queue_redraw()

@export_group("", "")
func _draw() -> void:
	if not Engine.is_editor_hint() or not preview_bounds:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(BLOCK_PX, BLOCK_PX)), _editor_grid_color(), false, 1.0)


## 取编辑器 2D 网格线的颜色，让地块框与画布网格视觉一致。
## 导出版本不存在 EditorInterface 这个标识符，故走 get_singleton 动态取，避免解析期报错。
func _editor_grid_color() -> Color:
	return Engine.get_singleton(&"EditorInterface") \
		.get_editor_settings() \
		.get_setting("editors/3d/primary_grid_color")