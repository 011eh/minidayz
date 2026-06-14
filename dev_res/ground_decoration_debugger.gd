extends Node2D

## Dev tool for inspecting DecorationLayer generation one clicked block at a time.
## Add it as a child of Ground. Left click a block to animate its decoration scatter.

@export var ground_path: NodePath
@export var clear_on_start := true
@export var clear_selected_block_on_click := true
@export var placements_per_frame := 12
@export var show_hud := true
@export var show_grid_info := true
@export var grid_info_position := Vector2(12, 220)
@export var show_water_blocks := true
@export var show_band_rects := true
@export var show_generated_cells := true

const INVALID_BLOCK := Vector2i(-1, -1)
const INVALID_CELL := Vector2i(-999999, -999999)

const SOURCE_COLORS := {
	0: Color(0.35, 0.95, 0.35, 1.0),
	1: Color(0.95, 0.80, 0.35, 1.0),
	2: Color(0.30, 0.80, 1.00, 1.0),
	3: Color(1.00, 0.45, 0.25, 1.0),
	4: Color(1.00, 0.25, 0.25, 1.0),
	5: Color(0.20, 0.65, 1.00, 1.0),
}

var ground: Node
var decoration_layer: TileMapLayer
var _font: Font
var _hud_layer: CanvasLayer
var _hud_label: Label
var _grid_label: Label

var _pick_by_source := {}
var _bands: Array[Dictionary] = []
var _generated_cells: Array[Dictionary] = []
var _written_cells := {}
var _source_counts := {}

var _hover_block := INVALID_BLOCK
var _hover_cell := INVALID_CELL
var _selected_block := INVALID_BLOCK
var _selected_org := Vector2i.ZERO
var _active_band_index := 0
var _running := false
var _ready_ok := false

func _ready() -> void:
	z_index = 1000
	_font = ThemeDB.fallback_font
	ground = get_parent() if ground_path.is_empty() else get_node_or_null(ground_path)
	_create_hud()
	call_deferred("_after_ground_ready")

func _after_ground_ready() -> void:
	if ground == null:
		push_warning("GroundDecorationDebugger: ground node not found.")
		return
	decoration_layer = ground.get("decoration_layer") as TileMapLayer
	if decoration_layer == null:
		decoration_layer = ground.get_node_or_null("%DecorationLayer") as TileMapLayer
	if decoration_layer == null:
		push_warning("GroundDecorationDebugger: DecorationLayer not found.")
		return
	_ready_ok = true
	_rebuild_picks()
	if clear_on_start and not _ground_auto_renders_decoration():
		clear_all_debug_decoration()
	_update_hud()
	queue_redraw()

func _process(_delta: float) -> void:
	if not _ready_ok:
		return
	_update_hover()
	if _running:
		var budget: int = maxi(1, placements_per_frame)
		while budget > 0 and _running:
			_apply_next_placement()
			budget -= 1
	_update_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _ready_ok:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_and_generate(get_global_mouse_position(), event.ctrl_pressed)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_select_only(get_global_mouse_position())
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			clear_all_debug_decoration()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			_finish_current_generation()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_clear_selection()
			get_viewport().set_input_as_handled()

func _draw() -> void:
	if not _ready_ok:
		return
	if show_water_blocks:
		_draw_water_block_rects()
	if _is_valid_block(_hover_block) and _hover_block != _selected_block:
		_draw_block_rect(_hover_block, Color(1, 1, 1, 0.45), false, 3.0)
	if _is_valid_block(_selected_block):
		_draw_block_rect(_selected_block, Color(1.0, 0.95, 0.25, 0.18), true, 1.0)
		_draw_block_rect(_selected_block, Color(1.0, 0.95, 0.25, 0.95), false, 6.0)
	if show_band_rects:
		_draw_band_rects()
	if show_generated_cells:
		_draw_generated_cells()
	if _is_valid_deco_cell(_hover_cell):
		draw_rect(_deco_cell_rect(_hover_cell), Color(1, 1, 1, 0.8), false, 2.0)

func clear_all_debug_decoration() -> void:
	_running = false
	_bands.clear()
	_generated_cells.clear()
	_written_cells.clear()
	_source_counts.clear()
	_active_band_index = 0
	if decoration_layer != null:
		decoration_layer.clear()
	_update_hud()
	queue_redraw()

func _select_only(world_pos: Vector2) -> void:
	var block := _world_to_block(world_pos)
	if not _is_valid_block(block):
		return
	_running = false
	_generated_cells.clear()
	_written_cells.clear()
	_source_counts.clear()
	_active_band_index = 0
	_selected_block = block
	_selected_org = block * _deco_block_size()
	_rebuild_picks()
	_rebuild_bands_for_block(block)

func _select_and_generate(world_pos: Vector2, finish_immediately: bool) -> void:
	var block := _world_to_block(world_pos)
	if not _is_valid_block(block):
		return
	_selected_block = block
	_selected_org = block * _deco_block_size()
	_running = false
	_generated_cells.clear()
	_written_cells.clear()
	_source_counts.clear()
	_active_band_index = 0
	if clear_selected_block_on_click:
		_clear_decoration_block(block)
	_rebuild_picks()
	_rebuild_bands_for_block(block)
	_running = not _bands.is_empty()
	if finish_immediately:
		_finish_current_generation()
	_update_hud()
	queue_redraw()

func _clear_selection() -> void:
	_running = false
	_selected_block = INVALID_BLOCK
	_selected_org = Vector2i.ZERO
	_bands.clear()
	_generated_cells.clear()
	_written_cells.clear()
	_source_counts.clear()
	_active_band_index = 0

func _finish_current_generation() -> void:
	while _running:
		_apply_next_placement()

func _apply_next_placement() -> void:
	while _active_band_index < _bands.size():
		var remaining: int = _bands[_active_band_index]["remaining"]
		if remaining <= 0:
			_active_band_index += 1
			continue

		var band: Dictionary = _bands[_active_band_index]
		_bands[_active_band_index]["remaining"] = remaining - 1
		var cursor: int = band["cursor"]
		_bands[_active_band_index]["cursor"] = cursor + 1

		var pick: Callable = band["pick"]
		var atlas_coords: Vector2i = pick.call()
		if atlas_coords == Vector2i(-1, -1):
			return

		var x0: int = band["x0"]
		var y0: int = band["y0"]
		var height: int = band["y1"] - y0
		var source_id: int = band["source_id"]
		var cell := _selected_org + Vector2i(x0 + int(cursor / height), y0 + cursor % height)

		decoration_layer.set_cell(cell, source_id, atlas_coords)
		_generated_cells.append({
			"cell": cell,
			"source_id": source_id,
			"atlas": atlas_coords,
			"label": band["label"],
		})
		_written_cells[cell] = true
		_source_counts[source_id] = int(_source_counts.get(source_id, 0)) + 1
		return

	_running = false

func _rebuild_bands_for_block(block: Vector2i) -> void:
	_bands.clear()
	_active_band_index = 0
	var type := _block_type(block)
	if type == -1:
		return
	if ground.is_road(type):
		_add_road_block_bands(type)
	elif ground.is_location(type):
		var source_id: int = ground._location_deco_source(type)
		var scattering: float = ground._location_deco_scattering(type)
		_add_band("location %s" % _block_type_name(type), source_id, scattering, 0, _deco_block_size(), 0, _deco_block_size())
	elif ground.is_water(type):
		_add_band("water edge %s" % _block_type_name(type), int(ground.DECO_SRC_WATER_EDGE), ground.water_edge_scattering, 0, _deco_block_size(), 0, _deco_block_size())
	else:
		_add_band("grass / secret %s" % _block_type_name(type), int(ground.DECO_SRC_GRASS), ground.grass_scattering, 0, _deco_block_size(), 0, _deco_block_size())

func _add_road_block_bands(type: int) -> void:
	var size := _deco_block_size()
	var road_start := int(ground.DECO_ROAD_MIN)
	var road_end := int(ground.DECO_ROAD_MAX)
	var side_scattering: float = ground.grass_scattering
	var connections: Dictionary = ground._road_connections_for_type(type)

	if type in [
		int(ground.BlockType["ROAD_V"]),
		int(ground.BlockType["ROAD_V_LEFT"]),
		int(ground.BlockType["ROAD_V_RIGHT"]),
	]:
		if connections["left"]:
			_add_band("road side grass left/up", int(ground.DECO_SRC_GRASS), side_scattering, 0, road_start, 0, road_start)
			_add_band("road side grass left/down", int(ground.DECO_SRC_GRASS), side_scattering, 0, road_start, road_end, size)
		else:
			_add_band("road side grass left", int(ground.DECO_SRC_GRASS), side_scattering, 0, road_start, 0, size)
		if connections["right"]:
			_add_band("road side grass right/up", int(ground.DECO_SRC_GRASS), side_scattering, road_end, size, 0, road_start)
			_add_band("road side grass right/down", int(ground.DECO_SRC_GRASS), side_scattering, road_end, size, road_end, size)
		else:
			_add_band("road side grass right", int(ground.DECO_SRC_GRASS), side_scattering, road_end, size, 0, size)
	elif type in [
		int(ground.BlockType["ROAD_H"]),
		int(ground.BlockType["ROAD_H_UP"]),
		int(ground.BlockType["ROAD_H_DOWN"]),
		int(ground.BlockType["ROAD_CROSS"]),
	]:
		if connections["up"]:
			_add_band("road side grass up/left", int(ground.DECO_SRC_GRASS), side_scattering, 0, road_start, 0, road_start)
			_add_band("road side grass up/right", int(ground.DECO_SRC_GRASS), side_scattering, road_end, size, 0, road_start)
		else:
			_add_band("road side grass up", int(ground.DECO_SRC_GRASS), side_scattering, 0, size, 0, road_start)
		if connections["down"]:
			_add_band("road side grass down/left", int(ground.DECO_SRC_GRASS), side_scattering, 0, road_start, road_end, size)
			_add_band("road side grass down/right", int(ground.DECO_SRC_GRASS), side_scattering, road_end, size, road_end, size)
		else:
			_add_band("road side grass down", int(ground.DECO_SRC_GRASS), side_scattering, 0, size, road_end, size)

	_add_road_debris_bands(connections)

func _add_road_debris_bands(connections: Dictionary) -> void:
	var size := _deco_block_size()
	var road_start := int(ground.DECO_ROAD_MIN)
	var road_end := int(ground.DECO_ROAD_MAX)
	var debris_scattering: float = ground.road_debris_scattering

	if connections["left"] and connections["right"]:
		_add_band("road debris horizontal", int(ground.DECO_SRC_ROAD), debris_scattering, 0, size, road_start, road_end)
	else:
		if connections["left"]:
			_add_band("road debris left", int(ground.DECO_SRC_ROAD), debris_scattering, 0, road_end, road_start, road_end)
		if connections["right"]:
			_add_band("road debris right", int(ground.DECO_SRC_ROAD), debris_scattering, road_start, size, road_start, road_end)

	if connections["up"] and connections["down"]:
		_add_band("road debris vertical", int(ground.DECO_SRC_ROAD), debris_scattering, road_start, road_end, 0, size)
	else:
		if connections["up"]:
			_add_band("road debris up", int(ground.DECO_SRC_ROAD), debris_scattering, road_start, road_end, 0, road_end)
		if connections["down"]:
			_add_band("road debris down", int(ground.DECO_SRC_ROAD), debris_scattering, road_start, road_end, road_start, size)

func _add_band(label: String, source_id: int, scattering: float, x0: int, x1: int, y0: int, y1: int) -> void:
	if x1 <= x0 or y1 <= y0:
		return
	var scattering_density := clampf(scattering / 100.0, 0.0, 1.0)
	if scattering_density <= 0.0:
		return
	var cell_count := (x1 - x0) * (y1 - y0)
	var normalized_scattering := scattering_density * 100.0
	var scattering_factor: float = ground._scattering_density_to_factor(scattering_density)
	_bands.append({
		"label": label,
		"source_id": source_id,
		"pick": _pick_for_source(source_id, scattering_factor),
		"scattering": normalized_scattering,
		"count": cell_count,
		"remaining": cell_count,
		"cursor": 0,
		"x0": x0,
		"x1": x1,
		"y0": y0,
		"y1": y1,
	})

func _rebuild_picks() -> void:
	_pick_by_source.clear()

func _pick_for_source(source_id: int, scattering_factor: float) -> Callable:
	var key := "%d:%.6f" % [source_id, scattering_factor]
	if not _pick_by_source.has(key):
		_pick_by_source[key] = ground.create_pick_random_tile_callable(decoration_layer, -1, scattering_factor, source_id)
	return _pick_by_source[key]

func _clear_decoration_block(block: Vector2i) -> void:
	var org := block * _deco_block_size()
	var size := _deco_block_size()
	for y in range(org.y, org.y + size):
		for x in range(org.x, org.x + size):
			decoration_layer.erase_cell(Vector2i(x, y))

func _update_hover() -> void:
	_hover_cell = _world_to_deco_cell(get_global_mouse_position())
	_hover_block = _deco_cell_to_block(_hover_cell)

func _world_to_deco_cell(world_pos: Vector2) -> Vector2i:
	if decoration_layer == null:
		return INVALID_CELL
	return decoration_layer.local_to_map(decoration_layer.to_local(world_pos))

func _world_to_block(world_pos: Vector2) -> Vector2i:
	return _deco_cell_to_block(_world_to_deco_cell(world_pos))

func _deco_cell_to_block(cell: Vector2i) -> Vector2i:
	if cell == INVALID_CELL:
		return INVALID_BLOCK
	var size := _deco_block_size()
	return Vector2i(floori(float(cell.x) / float(size)), floori(float(cell.y) / float(size)))

func _is_valid_block(block: Vector2i) -> bool:
	return block.x >= 0 and block.y >= 0 and block.x < int(ground.MAP_SIZE_IN_BLOCKS) and block.y < int(ground.MAP_SIZE_IN_BLOCKS)

func _is_valid_deco_cell(cell: Vector2i) -> bool:
	if cell == INVALID_CELL:
		return false
	var total := int(ground.MAP_SIZE_IN_BLOCKS) * _deco_block_size()
	return cell.x >= 0 and cell.y >= 0 and cell.x < total and cell.y < total

func _block_type(block: Vector2i) -> int:
	if not _is_valid_block(block):
		return -1
	return int(ground.get_block(block.x, block.y))

func _block_type_name(type: int) -> String:
	var names: Array = ground.BlockType.keys()
	if type >= 0 and type < names.size():
		return names[type]
	return "UNKNOWN_%d" % type

func _deco_block_size() -> int:
	return int(ground.DECO_BLOCK_SIZE)

func _deco_tile_px() -> int:
	return int(ground.DECO_TILE_PX)

func _source_color(source_id: int, alpha: float = 1.0) -> Color:
	var c: Color = SOURCE_COLORS.get(source_id, Color.WHITE)
	return Color(c.r, c.g, c.b, alpha)

func _source_name(source_id: int) -> String:
	if decoration_layer == null or decoration_layer.tile_set == null:
		return "source %d" % source_id
	var tile_set: TileSet = decoration_layer.tile_set
	if not tile_set.has_source(source_id):
		return "source %d" % source_id
	var source := tile_set.get_source(source_id)
	if source.resource_name != "":
		return source.resource_name
	return "source %d" % source_id

func _ground_auto_renders_decoration() -> bool:
	return bool(ground.get("auto_render_decoration"))

func _draw_block_rect(block: Vector2i, color: Color, filled: bool, width: float) -> void:
	var tile_px := _deco_tile_px()
	var size_px := _deco_block_size() * tile_px
	var rect := Rect2(Vector2(block.x * size_px, block.y * size_px), Vector2(size_px, size_px))
	if filled:
		draw_rect(rect, color, true)
	else:
		draw_rect(rect, color, false, width)

func _draw_water_block_rects() -> void:
	var source_id := int(ground.DECO_SRC_WATER_EDGE)
	for y in range(int(ground.MAP_SIZE_IN_BLOCKS)):
		for x in range(int(ground.MAP_SIZE_IN_BLOCKS)):
			if ground.is_water(int(ground.get_block(x, y))):
				var block := Vector2i(x, y)
				_draw_block_rect(block, _source_color(source_id, 0.16), true, 1.0)
				_draw_block_rect(block, _source_color(source_id, 0.85), false, 4.0)

func _draw_band_rects() -> void:
	for i in range(_bands.size()):
		var band: Dictionary = _bands[i]
		var source_id: int = band["source_id"]
		var color := _source_color(source_id, 0.10 if i != _active_band_index else 0.22)
		var rect := _deco_rect(
			_selected_org + Vector2i(band["x0"], band["y0"]),
			Vector2i(band["x1"] - band["x0"], band["y1"] - band["y0"])
		)
		draw_rect(rect, color, true)
		draw_rect(rect, _source_color(source_id, 0.65), false, 2.0)

func _draw_generated_cells() -> void:
	var start: int = maxi(0, _generated_cells.size() - 1200)
	for i in range(start, _generated_cells.size()):
		var item: Dictionary = _generated_cells[i]
		var cell: Vector2i = item["cell"]
		var source_id: int = item["source_id"]
		var rect: Rect2 = _deco_cell_rect(cell)
		draw_rect(rect, _source_color(source_id, 0.28), true)
		draw_rect(rect, _source_color(source_id, 0.85), false, 1.0)

func _deco_rect(org: Vector2i, size: Vector2i) -> Rect2:
	var tile_px := _deco_tile_px()
	return Rect2(
		Vector2(org.x * tile_px, org.y * tile_px),
		Vector2(size.x * tile_px, size.y * tile_px)
	)

func _deco_cell_rect(cell: Vector2i) -> Rect2:
	return _deco_rect(cell, Vector2i.ONE)

func _create_hud() -> void:
	if not show_hud and not show_grid_info:
		return
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 100
	add_child(_hud_layer)
	if show_hud:
		_hud_label = _create_overlay_label(Vector2(12, 12), 16)
	if show_grid_info:
		_grid_label = _create_overlay_label(grid_info_position, 13)

func _create_overlay_label(label_position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = label_position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	_hud_layer.add_child(label)
	return label

func _update_hud() -> void:
	if _hud_label != null:
		_hud_label.text = _format_debug_hud()
	if _grid_label != null:
		_grid_label.text = _format_grid_info()

func _format_debug_hud() -> String:
	var lines: Array[String] = []
	lines.append("Decoration Debugger")
	lines.append("LMB: generate block   RMB: inspect bands   Ctrl+LMB/Enter: finish   C: clear   Esc: unselect")
	if _is_valid_block(_hover_block):
		lines.append("hover block=%s cell=%s" % [_hover_block, _hover_cell])
		var hover_source := decoration_layer.get_cell_source_id(_hover_cell)
		if hover_source >= 0:
			lines.append("hover tile source=%d %s atlas=%s alt=%d" % [
				hover_source,
				_source_name(hover_source),
				decoration_layer.get_cell_atlas_coords(_hover_cell),
				decoration_layer.get_cell_alternative_tile(_hover_cell),
			])
	if _is_valid_block(_selected_block):
		var type := _block_type(_selected_block)
		lines.append("selected block=%s type=%s deco_origin=%s" % [_selected_block, _block_type_name(type), _selected_org])
		lines.append("bands=%d active=%d placed=%d unique_cells=%d running=%s" % [
			_bands.size(),
			_active_band_index,
			_generated_cells.size(),
			_written_cells.size(),
			str(_running),
		])
		if not _source_counts.is_empty():
			lines.append("placed by source: %s" % _format_source_counts())
		if _active_band_index < _bands.size():
			var band: Dictionary = _bands[_active_band_index]
			lines.append("active band: %s source=%d %s scan_remaining=%d/%d scattering=%.2f rect=[%d,%d)-[%d,%d)" % [
				band["label"],
				band["source_id"],
				_source_name(band["source_id"]),
				band["remaining"],
				band["count"],
				band["scattering"],
				band["x0"],
				band["y0"],
				band["x1"],
				band["y1"],
			])
	return "\n".join(lines)

func _format_grid_info() -> String:
	if ground == null:
		return "Grid: ground not found"
	var size := int(ground.MAP_SIZE_IN_BLOCKS)
	var lines: Array[String] = []
	lines.append("Grid data: grid[y][x]  %dx%d" % [size, size])

	var header := "y\\x "
	for x in range(size):
		header += "%02d " % x
	lines.append(header)

	for y in range(size):
		var row := "%02d  " % y
		for x in range(size):
			row += "%s " % _grid_code_for_type(int(ground.get_block(x, y)))
		lines.append(row)

	lines.append("Legend: __ EMPTY  VI VILLAGE  CI CITY  MI MILITARY")
	lines.append("        HO HOSPITAL  FI FIRESTATION  SE SECRET  WA WATER")
	lines.append("Roads:  RH ROAD_H  RV ROAD_V  RC CROSS")
	lines.append("        HU H_UP  HD H_DOWN  VL V_LEFT  VR V_RIGHT")
	lines.append("Counts: %s" % _format_block_type_counts())
	return "\n".join(lines)

func _grid_code_for_type(type: int) -> String:
	match _block_type_name(type):
		"EMPTY": return "__"
		"VILLAGE": return "VI"
		"CITY": return "CI"
		"MILITARY": return "MI"
		"HOSPITAL": return "HO"
		"FIRESTATION": return "FI"
		"ROAD_H": return "RH"
		"ROAD_V": return "RV"
		"ROAD_CROSS": return "RC"
		"ROAD_H_UP": return "HU"
		"ROAD_H_DOWN": return "HD"
		"ROAD_V_LEFT": return "VL"
		"ROAD_V_RIGHT": return "VR"
		"SECRET": return "SE"
		"WATER": return "WA"
		_: return "??"

func _format_block_type_counts() -> String:
	if ground == null:
		return ""
	var counts := {}
	var size := int(ground.MAP_SIZE_IN_BLOCKS)
	for y in range(size):
		for x in range(size):
			var type := int(ground.get_block(x, y))
			counts[type] = int(counts.get(type, 0)) + 1

	var parts: Array[String] = []
	var names: Array = ground.BlockType.keys()
	for type in range(names.size()):
		var count := int(counts.get(type, 0))
		if count > 0:
			parts.append("%s=%d" % [_grid_code_for_type(type), count])
	return ", ".join(parts)

func _format_source_counts() -> String:
	var parts: Array[String] = []
	var keys := _source_counts.keys()
	keys.sort()
	for source_id in keys:
		parts.append("%d %s=%d" % [source_id, _source_name(source_id), _source_counts[source_id]])
	return ", ".join(parts)
