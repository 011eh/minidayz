@tool
class_name TemplateSlot
extends Marker2D
## 地块模板里的一个「待填坑位」：运行时由 [LocationTemplate] 抽一个候选实例化，然后自毁。
##
## 「编辑器预览」一节之后全部是设计期辅助（画布贴图预览、场景面板警告），
## 以 `_editor_` 前缀区分，运行时不参与任何逻辑。


enum Type { BUILDING, VEHICLE, TREE, PROP, CONTAINER }

## 槽位语义标签。目前仅用于 dev_res/_verify_bounds.gd 分组，尚无运行时消费者。
@export var type: Type = Type.BUILDING

@export
var choices: Array[PackedScene] = []:
	set(value):
		choices = value
		_editor_layer_cache.clear()
		# 候选变少时先夹取下标，再让检查器按新上限重建滑条。
		preview_index = preview_index
		notify_property_list_changed()
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


# 编辑器预览

@export_group("Editor Preview", "preview_")

## 预览用的候选下标；改这个数就能在画布上切换看哪一个候选，不影响运行时随机。
@export_range(0, 16) var preview_index: int = 0:
	set(value):
		preview_index = clampi(value, 0, maxi(choices.size() - 1, 0))
		queue_redraw()

@export_group("", "")

# _draw 每帧都要候选贴图，缓存避免重复 instantiate。
var _editor_layer_cache: Dictionary = {}


# 引擎回调，名字不可改；实际职责属于编辑器辅助。
func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	_editor_draw_choice(clampi(preview_index, 0, maxi(choices.size() - 1, 0)))
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 20, Color.BLACK, 1.0)


# 引擎回调，名字不可改；把 preview_index 的滑条上限压到当前候选数。
func _validate_property(property: Dictionary) -> void:
	if property.name == "preview_index":
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "0,%d,1" % maxi(choices.size() - 1, 0)
		if choices.size() <= 1:
			property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if choices.is_empty():
		warnings.append("choices 为空：此槽位不会生成任何东西。")
	if choice_offsets.size() > choices.size():
		warnings.append("choice_offsets 比 choices 长，多出的项不会生效。")
	return warnings


## 把某个候选的全部 Sprite2D 按其在场景内的相对变换画出来（贴图预览）。
func _editor_draw_choice(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	for layer in _editor_sprite_layers(choices[index]):
		var offset: Vector2 = layer.offset
		if index < choice_offsets.size():
			offset += choice_offsets[index]
		draw_texture_rect_region(layer.texture, Rect2(offset, layer.size), layer.region)


## 抽取候选场景里所有 Sprite2D 的绘制信息（相对根原点），供 _draw 直接画。
## 只在 choices 变更时算一次并缓存 —— 每帧 instantiate 会让编辑器卡顿。
## 另被 dev_res/_verify_bounds.gd 用于离线对称性校验，改返回结构时需同步该脚本。
func _editor_sprite_layers(scene: PackedScene) -> Array:
	if scene == null:
		return []
	if _editor_layer_cache.has(scene):
		return _editor_layer_cache[scene]

	var instance := scene.instantiate()
	var layers: Array = []
	_editor_collect_sprites(instance, Transform2D.IDENTITY, layers)
	instance.free()

	_editor_layer_cache[scene] = layers
	return layers


func _editor_collect_sprites(node: Node, parent_xform: Transform2D, layers: Array) -> void:
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
		_editor_collect_sprites(child, xform, layers)
