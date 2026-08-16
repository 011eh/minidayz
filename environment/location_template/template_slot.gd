@tool
class_name TemplateSlot
extends Marker2D


enum Type { BUILDING, VEHICLE, TREE, PROP, CONTAINER }

@export
var type: Type = Type.BUILDING:
	set(value):
		type = value
		queue_redraw()

@export
var choices: Array[PackedScene] = []:
	set(value):
		choices = value
		_footprint_cache.clear()
		_layer_cache.clear()
		update_configuration_warnings()
		queue_redraw()

## 与 [member choices] 索引一一对应的逐候选微调；长度可短于 choices，缺省项视为 ZERO。
##
## 建筑锚点统一为「地板底边中心」（见 todo/04-建筑锚点统一.md）后，同族候选（5 种村屋、
## 各种车、各种树）底边自动对齐，此项留空即可。仅当同一槽位塞进体量差异极大的两栋楼
## （如教堂 292×281 与红砖房 326×142）时，才需要手填 y 分量做最后微调。
@export
var choice_offsets: Array[Vector2] = []:
	set(value):
		choice_offsets = value
		update_configuration_warnings()
		queue_redraw()

@export
var position_jitter: Vector2 = Vector2.ZERO:
	set(value):
		position_jitter = value
		queue_redraw()

# 编辑器 _draw 每次重绘都要候选轮廓/贴图，缓存避免重复 instantiate。
var _footprint_cache: Dictionary = {}
var _layer_cache: Dictionary = {}


## 抽一个候选的索引；空 choices 返回 -1。
## 返回索引而非场景，是为了让 [method spawn_position] 能取到对应的 choice_offsets。
func pick_index(rng: RandomNumberGenerator) -> int:
	if choices.is_empty():
		return -1
	return rng.randi() % choices.size()


func scene_at(index: int) -> PackedScene:
	if index < 0 or index >= choices.size():
		return null
	return choices[index]


func spawn_position(rng: RandomNumberGenerator, index: int) -> Vector2:
	var base := position
	if index >= 0 and index < choice_offsets.size():
		base += choice_offsets[index]
	if position_jitter == Vector2.ZERO:
		return base
	return base + Vector2(
		rng.randf_range(-position_jitter.x, position_jitter.x),
		rng.randf_range(-position_jitter.y, position_jitter.y),
	)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if choices.is_empty():
		warnings.append("choices 为空：此槽位不会生成任何东西。")
	if choice_offsets.size() > choices.size():
		warnings.append("choice_offsets 比 choices 长，多出的项不会生效。")
	return warnings


## 预览用的候选下标；改这个数就能在画布上切换看哪一个候选，不影响运行时随机。
@export_range(0, 16) var preview_index: int = 0:
	set(value):
		preview_index = value
		queue_redraw()

## 是否把未预览的候选也叠出淡影，用于比较体量差异。
@export var preview_all_choices: bool = true:
	set(value):
		preview_all_choices = value
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if position_jitter != Vector2.ZERO:
		var jitter_rect := Rect2(-position_jitter, position_jitter * 2.0)
		draw_rect(jitter_rect, Color(1.0, 1.0, 1.0, 0.06))
		draw_rect(jitter_rect, Color(1.0, 1.0, 1.0, 0.25), false, 1.0)

	var color := _type_color()
	var main := clampi(preview_index, 0, maxi(choices.size() - 1, 0))

	# 先叠其余候选的淡影 + 轮廓：摆位时按「最大的那个」判断是否越界或压到邻居槽位，
	# 而不是只看当前预览的那一个。
	if preview_all_choices:
		for i in choices.size():
			if i == main:
				continue
			_draw_choice(i, Color(1, 1, 1, 0.22))
			var rect := _footprint_rect(choices[i])
			if rect.size != Vector2.ZERO:
				if i < choice_offsets.size():
					rect.position += choice_offsets[i]
				draw_rect(rect, Color(color, 0.55), false, 1.0)

	# 预览候选画成不透明实图 —— 所见即所得。
	_draw_choice(main, Color.WHITE)

	draw_circle(Vector2.ZERO, 6.0, color)
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 20, Color.BLACK, 1.0)


## 把某个候选的全部 Sprite2D 按其在场景内的相对变换画出来（贴图预览）。
func _draw_choice(index: int, modulate_color: Color) -> void:
	if index < 0 or index >= choices.size():
		return
	for layer in _sprite_layers(choices[index]):
		var offset: Vector2 = layer.offset
		if index < choice_offsets.size():
			offset += choice_offsets[index]
		draw_texture_rect_region(
			layer.texture,
			Rect2(offset, layer.size),
			layer.region,
			modulate_color,
		)


## 候选的占地矩形（相对槽位原点）。
## 依赖锚点约定「根原点 = 地板底边中心」，故矩形恒为 (-w/2, -h, w, h)：底边贴 y=0，向上长 h。
func _footprint_rect(scene: PackedScene) -> Rect2:
	if scene == null:
		return Rect2()
	if _footprint_cache.has(scene):
		return _footprint_cache[scene]

	var instance := scene.instantiate()
	var size := _anchor_sprite_size(instance)
	# 该实例从未进入场景树，必须 free() —— queue_free() 对树外节点无效。
	instance.free()

	var rect := Rect2(-size.x * 0.5, -size.y, size.x, size.y)
	_footprint_cache[scene] = rect
	return rect


## 建筑取 Inside 地板贴图；其它物件退化为第一个有贴图的 Sprite2D。
func _anchor_sprite_size(instance: Node) -> Vector2:
	var inside := instance.get_node_or_null(^"Inside") as Sprite2D
	if inside != null and inside.texture != null:
		return inside.texture.get_size()
	for child in instance.get_children():
		var sprite := child as Sprite2D
		if sprite != null and sprite.texture != null:
			return sprite.texture.get_size()
	return Vector2.ZERO


## 抽取候选场景里所有 Sprite2D 的绘制信息（相对根原点），供 _draw 直接画。
## 只在 choices 变更时算一次并缓存 —— 每帧 instantiate 会让编辑器卡顿。
func _sprite_layers(scene: PackedScene) -> Array:
	if scene == null:
		return []
	if _layer_cache.has(scene):
		return _layer_cache[scene]

	var instance := scene.instantiate()
	var layers: Array = []
	_collect_sprites(instance, Transform2D.IDENTITY, layers)
	instance.free()

	_layer_cache[scene] = layers
	return layers


func _collect_sprites(node: Node, parent_xform: Transform2D, layers: Array) -> void:
	var xform := parent_xform
	var node_2d := node as Node2D
	if node_2d != null:
		xform = parent_xform * node_2d.transform

	var sprite := node as Sprite2D
	if sprite != null and sprite.texture != null and sprite.visible:
		var tex_size := sprite.texture.get_size()
		var region := Rect2(Vector2.ZERO, tex_size)
		if sprite.region_enabled:
			region = sprite.region_rect
		# 多帧图集（hframes/vframes）只取当前 frame，避免整张 sheet 糊上去。
		if sprite.hframes > 1 or sprite.vframes > 1:
			var cell := Vector2(tex_size.x / sprite.hframes, tex_size.y / sprite.vframes)
			var fx := sprite.frame % sprite.hframes
			var fy := sprite.frame / sprite.hframes
			region = Rect2(Vector2(fx, fy) * cell, cell)
		var size := region.size
		var offset: Vector2 = sprite.offset
		if sprite.centered:
			offset -= size * 0.5
		layers.append({
			"texture": sprite.texture,
			"region": region,
			"size": size,
			"offset": xform.origin + offset,
		})

	for child in node.get_children():
		_collect_sprites(child, xform, layers)


func _type_color() -> Color:
	match type:
		Type.BUILDING: return Color(0.90, 0.55, 0.20)
		Type.VEHICLE: return Color(0.30, 0.55, 0.95)
		Type.TREE: return Color(0.30, 0.75, 0.35)
		Type.PROP: return Color(0.85, 0.80, 0.30)
		Type.CONTAINER: return Color(0.70, 0.40, 0.80)
		_: return Color.WHITE
