@tool
class_name TemplateSlot
extends Marker2D


@export
var pool: SlotPool = null:
	set(value):
		if pool != null and pool.changed.is_connected(_editor_on_pool_changed):
			pool.changed.disconnect(_editor_on_pool_changed)
		pool = value
		if pool != null and not pool.changed.is_connected(_editor_on_pool_changed):
			pool.changed.connect(_editor_on_pool_changed)
		_editor_on_pool_changed()

@export
var position_jitter: Vector2 = Vector2.ZERO:
	set(value):
		position_jitter = value
		queue_redraw()

## 只登记落点与 marker 不同的候选，其余候选按 marker 原位生成。
## 原版有的槽位是"二选一、两个候选各有自己的坐标"（村落 17 的教堂/红砖），靠这张表还原。
@export
var entry_offsets: Array[SlotEntryOffset] = []:
	set(value):
		entry_offsets = value
		_editor_watch_entry_offsets()
		queue_redraw()


## 候选和位置必须一次定下：位置依赖到底选中了哪个候选，分两次取会错位。
func pick(rng: RandomNumberGenerator) -> SlotPick:
	var scene := pool.pick(rng) if pool != null else null
	if scene == null:
		return null
	return SlotPick.new(scene, spawn_position(rng) + entry_offset(scene))


func entry_offset(scene: PackedScene) -> Vector2:
	for entry in entry_offsets:
		if entry != null and entry.scene == scene:
			return entry.offset
	return Vector2.ZERO


func spawn_position(rng: RandomNumberGenerator) -> Vector2:
	if position_jitter == Vector2.ZERO:
		return position
	return position + Vector2(
		rng.randf_range(-position_jitter.x, position_jitter.x),
		rng.randf_range(-position_jitter.y, position_jitter.y),
	)


@export_group("Editor Preview", "preview_")
@export_range(0, 16) var preview_index: int = 0:
	set(value):
		preview_index = clampi(value, 0, maxi(_entry_count() - 1, 0))
		queue_redraw()

@export_group("", "")
var _editor_layer_cache: Dictionary = {}


func _entry_count() -> int:
	return pool.entries.size() if pool != null else 0

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_editor_draw_choice(clampi(preview_index, 0, maxi(_entry_count() - 1, 0)))

func _validate_property(property: Dictionary) -> void:
	if property.name == "preview_index":
		var count := _entry_count()
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "0,%d,1" % maxi(count - 1, 0)
		if count <= 1:
			property.usage |= PROPERTY_USAGE_READ_ONLY

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if pool == null:
		warnings.append("未设置 pool：此槽位不会生成任何东西。")
	elif pool.entries.is_empty():
		warnings.append("pool 的 entries 为空：此槽位不会生成任何东西。")
	return warnings

func _editor_on_pool_changed() -> void:
	_editor_layer_cache.clear()
	# 候选变少时先夹取下标，再让检查器按新上限重建滑条。
	preview_index = preview_index
	if Engine.is_editor_hint():
		_editor_sync_entry_offsets()
	notify_property_list_changed()
	update_configuration_warnings()
	queue_redraw()

## 候选被移出 pool 后，它那条偏移就是死数据，顺手清掉；不替还在的候选补零条目。
func _editor_sync_entry_offsets() -> void:
	var live: Array[SlotEntryOffset] = []
	if pool != null:
		for entry in entry_offsets:
			if entry != null and pool.entries.has(entry.scene):
				live.append(entry)
	if live != entry_offsets:
		entry_offsets = live

func _editor_watch_entry_offsets() -> void:
	for entry in entry_offsets:
		if entry != null and not entry.changed.is_connected(queue_redraw):
			entry.changed.connect(queue_redraw)

func _editor_draw_choice(index: int) -> void:
	if pool == null or index < 0 or index >= pool.entries.size():
		return
	var offset := entry_offset(pool.entries[index])
	for layer in _editor_sprite_layers(pool.entries[index]):
		draw_texture_rect_region(layer.texture, Rect2(layer.offset + offset, layer.size), layer.region)

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

		# 多帧处理
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
