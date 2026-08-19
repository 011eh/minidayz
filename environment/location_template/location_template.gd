@tool
class_name LocationTemplate
extends Node2D
## 一个地块（村庄/城市/医院…）的模板场景根。
##
## build() 时做两件事：
##   ① 把 Footprint 的路面格收集进全局 pavement 字典（由 ground.gd 统一 terrain-connect）；
##   ② 实例化 Slots 下每个 [TemplateSlot] 的对象。
## 道路、草地、装饰、水均不在此 —— 见 ground.gd 的程序化生成。

## 地点类型，供 ground.gd 注册表匹配（镜像 ground.gd 的 BlockType 地点子集）。
enum Category { VILLAGE, CITY, MILITARY, HOSPITAL, FIRESTATION, SECRET }

@export var category: Category = Category.VILLAGE

## 与 ground.gd 一致；用于把节点像素位置换算成全局 tile 坐标。
const TILE_PX := 60
## 与 ground.gd 的 BLOCK_SIZE_IN_TILE / BLOCK_PX 一致：一个地块 17×60 = 1020 px 见方。
const BLOCK_SIZE_IN_TILE := 17
const BLOCK_PX := BLOCK_SIZE_IN_TILE * TILE_PX

var footprint: TileMapLayer:
	get: return get_node_or_null(^"Footprint") as TileMapLayer
var slots: Node2D:
	get: return get_node_or_null(^"Slots") as Node2D


## 生成此地块的全部内容。
## [param pavement_cells]: 共享字典，键为全局 tile 坐标；ground.gd 收齐所有地块后统一
## set_cells_terrain_connect，与道路共用同一路面 terrain。
func build(rng: RandomNumberGenerator, pavement_cells: Dictionary) -> void:
	_collect_footprint(pavement_cells)
	_build_slots(rng)


func _collect_footprint(pavement_cells: Dictionary) -> void:
	var footprint := self.footprint
	if footprint == null:
		return
	# position = block坐标 × 1020 = block × 17 × 60，故 position / 60 = block 的 tile 原点。
	var tile_origin := Vector2i(roundi(position.x / TILE_PX), roundi(position.y / TILE_PX))
	for cell in footprint.get_used_cells():
		pavement_cells[tile_origin + cell] = true
	# Footprint 仅作设计期遮罩，运行时不渲染（全局 GroundLayer 负责出图）。
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
	for slot in template_slots:
		var index := slot.pick_index(rng)
		var scene := slot.scene_at(index)
		if scene != null:
			var inst := scene.instantiate()
			slots.add_child(inst)
			var inst_2d := inst as Node2D
			if inst_2d != null:
				# 建筑锚点为地板底边中心，故此处不分尺寸、无条件赋值即可对齐。
				inst_2d.position = slot.spawn_position(rng, index)
		slot.queue_free()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_node_or_null("Footprint") == null:
		warnings.append("缺少 Footprint (TileMapLayer) 子节点。")
	if get_node_or_null("Slots") == null:
		warnings.append("缺少 Slots (Node2D) 子节点。")
	return warnings


# --- 编辑器预览：以下成员仅设计期生效，运行时不参与生成逻辑 ---

@export_group("Editor Preview", "preview_")

## 在画布上画出地块的实际范围（1020×1020），摆槽位时用来判断是否越界。
@export var preview_bounds: bool = true:
	set(value):
		preview_bounds = value
		queue_redraw()

@export_group("", "")


# 引擎回调，名字不可改；实际职责属于编辑器辅助。
func _draw() -> void:
	if not Engine.is_editor_hint() or not preview_bounds:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(BLOCK_PX, BLOCK_PX)), _editor_grid_color(), false, 1.0)


## 取编辑器 2D 网格线的颜色，让地块框与画布网格视觉一致。
## 导出版本不存在 EditorInterface 这个标识符，故走 get_singleton 动态取，避免解析期报错。
func _editor_grid_color() -> Color:
	return Engine.get_singleton(&"EditorInterface") \
		.get_editor_settings() \
		.get_setting("editors/2d/grid_color")