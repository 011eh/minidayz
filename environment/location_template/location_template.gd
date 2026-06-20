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

@onready var footprint: TileMapLayer = $Footprint
@onready var slots: Node2D = $Slots


## 生成此地块的全部内容。
## [param pavement_cells]: 共享字典，键为全局 tile 坐标；ground.gd 收齐所有地块后统一
## set_cells_terrain_connect，与道路共用同一路面 terrain。
func build(rng: RandomNumberGenerator, pavement_cells: Dictionary) -> void:
	_collect_footprint(pavement_cells)
	_build_slots(rng)


func _collect_footprint(pavement_cells: Dictionary) -> void:
	if footprint == null:
		return
	# position = block坐标 × 1020 = block × 17 × 60，故 position / 60 = block 的 tile 原点。
	var tile_origin := Vector2i(roundi(position.x / TILE_PX), roundi(position.y / TILE_PX))
	for cell in footprint.get_used_cells():
		pavement_cells[tile_origin + cell] = true
	# Footprint 仅作设计期遮罩，运行时不渲染（全局 GroundLayer 负责出图）。
	footprint.queue_free()


func _build_slots(rng: RandomNumberGenerator) -> void:
	if slots == null:
		return
	# 先快照槽位列表，避免边遍历边 add_child / queue_free。
	var template_slots: Array[TemplateSlot] = []
	for child in slots.get_children():
		if child is TemplateSlot:
			template_slots.append(child as TemplateSlot)
	for slot in template_slots:
		var scene := slot.pick(rng)
		if scene != null:
			var inst := scene.instantiate()
			slots.add_child(inst)
			var inst_2d := inst as Node2D
			if inst_2d != null:
				inst_2d.position = slot.spawn_position(rng)
		slot.queue_free()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if get_node_or_null("Footprint") == null:
		warnings.append("缺少 Footprint (TileMapLayer) 子节点。")
	if get_node_or_null("Slots") == null:
		warnings.append("缺少 Slots (Node2D) 子节点。")
	return warnings
