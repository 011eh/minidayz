@tool
extends EditorScript
## 开发期一次性重绘当前打开的地块模板的 Footprint 路面。
##
## 矩形不在这里登记：脚本直接去 map_generation.decoded.txt 里读原版 create_map_location
## 对该地点类型执行的 SetTileRange 序列，所以任何地点类型都能用，加新模板不用改本文件。
## 地点类型取自场景文件名末尾的数字（village_17.tscn → 地点类型 17）。
##
## 用法：打开目标模板场景 → File > Run（Ctrl+Shift+X）→ Ctrl+S 存盘。

enum Op { PAVE, ERASE }

const DECODED_PATH := "res://origin/others/文档/datajs_export/map_generation.decoded.txt"

## 原版地面 tile 编号：路面 15、草地 6。Footprint 只存路面 cell，
## 所以原版"往已铺好的路面里写回草地"那一步在这里是擦除，而不是画一层草。
const TILE_PAVEMENT := 15
const TILE_GRASS := 6

## 只在邻格是水平路（12）/垂直路（13）/路口（14）时才铺的那几条 SetTileRange 是道路接口臂，
## 依赖邻居、属于地图生成期的事，已由 ground.gd 的接口臂逻辑处理，这里跳过。
const ROAD_NEIGHBOR_TYPES: Array[int] = [12, 13, 14]

const TERRAIN_SET := 0
const PATH_TERRAIN := 1
const BLOCK_RECT := Rect2i(
	Vector2i.ZERO, Vector2i.ONE * LocationTemplate.BLOCK_SIZE_IN_TILE)

## 原版和 Godot 角匹配对"边界在哪"的约定差一格，读出来的矩形要按这个量校正。
##
## 原版：SetTileRange 写进去的格子是纯路面 tile，过渡 tile 由 Repeat(289) 后处理写在矩形
## *外面*那圈草地格上，所以渲染出来的路面比矩形大约一格。
## Godot：set_cells_terrain_connect 把过渡画在*被涂的格子自己*身上，边界落在它们的外沿顶点，
## 渲染出来的路面比涂的格子小约半格。
##
## 两边相差一格：路面矩形外扩 1、草地矩形内缩 1，范围才对得上。道路是同一回事——
## 原版 2 格宽的横路在 ground.gd 里写成 ROAD_WIDTH = 4，校正后 17 号村落的环路同样是 4 格宽。
const CONVENTION_GROW := 1

const TYPE_PATTERN := r"^(\s*)- IF t507\.Sprite:cnd\.CompareInstanceVar\(iv\[0\], =, (\d+)\)\s*$"
const ACTION_PATTERN := r"^(\s*)> t945\.Tilemap:act\.SetTileRange\((.*), combo#\d+\)\s*$"
const NEIGHBOR_PATTERN := r"CompareXY\(.*, =, (\d+)\)"
const OFFSET_PATTERN := r"^\(Tilemapspot[XY] \+ (\d+)\)$"
const SCENE_TYPE_PATTERN := r"(\d+)$"


func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("[footprint_painter] 没有正在编辑的场景。")
		return
	var layer := root.get_node_or_null(^"Footprint") as TileMapLayer
	if layer == null:
		push_error("[footprint_painter] 场景里没有 Footprint (TileMapLayer) 节点。")
		return
	var location_type := location_type_of(root.scene_file_path)
	if location_type < 0:
		push_error("[footprint_painter] 场景名末尾没有地点类型编号，无法确定读哪段原版数据。")
		return
	var steps := read_steps(location_type)
	if steps.is_empty():
		push_error("[footprint_painter] 原版没有给地点类型 %d 铺任何路面。" % location_type)
		return
	var count := paint(layer, steps)
	print("[footprint_painter] 地点类型 %d：%s → %d 个路面 cell，记得存盘。" % [
		location_type, describe(steps), count])
	EditorInterface.mark_scene_as_unsaved()


## 场景文件名末尾的数字就是原版的地点类型（iv[0]）。
static func location_type_of(scene_path: String) -> int:
	var m := RegEx.create_from_string(SCENE_TYPE_PATTERN).search(scene_path.get_file().get_basename())
	return m.get_string(1).to_int() if m != null else -1


## 取原版该地点类型那段事件里的 SetTileRange 序列，转成 [Op, Rect2i] 列表。
static func read_steps(location_type: int) -> Array:
	var text := FileAccess.get_file_as_string(DECODED_PATH)
	if text.is_empty():
		push_error("[footprint_painter] 读不到 %s。" % DECODED_PATH)
		return []
	var lines := text.split("\n")
	var block := find_block(lines, location_type)
	if block.x < 0:
		return []
	return steps_in_block(lines, block)


## 定位 `- IF CompareInstanceVar(iv[0], =, N)` 那段的正文行区间 [起, 止)。
## 连写的多行同缩进条件是"这几个地点类型共用一段"，任一命中都算。
static func find_block(lines: PackedStringArray, location_type: int) -> Vector2i:
	var type_re := RegEx.create_from_string(TYPE_PATTERN)
	var i := 0
	while i < lines.size():
		var head := type_re.search(lines[i])
		if head == null:
			i += 1
			continue
		var indent := head.get_string(1).length()
		var types: Array[int] = []
		var j := i
		while j < lines.size():
			var m := type_re.search(lines[j])
			if m == null or m.get_string(1).length() != indent:
				break
			types.append(m.get_string(2).to_int())
			j += 1
		var body_start := j
		while j < lines.size():
			var m := type_re.search(lines[j])
			if m != null and m.get_string(1).length() <= indent:
				break
			j += 1
		if types.has(location_type):
			return Vector2i(body_start, j)
		i = j
	return Vector2i(-1, -1)


static func steps_in_block(lines: PackedStringArray, block: Vector2i) -> Array:
	var action_re := RegEx.create_from_string(ACTION_PATTERN)
	var steps := []
	for k in range(block.x, block.y):
		var m := action_re.search(lines[k])
		if m == null:
			continue
		if is_road_arm(lines, block.x, k, m.get_string(1).length()):
			continue
		var step := parse_step(m.get_string(2))
		if step.is_empty():
			push_warning("[footprint_painter] 跳过读不懂的一行：%s" % lines[k].strip_edges())
			continue
		steps.append(step)
	return steps


## 动作的生效条件是紧贴它上方、同缩进的那串 `- IF`；其中出现邻格是道路的判断就是接口臂。
static func is_road_arm(lines: PackedStringArray, block_start: int, action: int, indent: int) -> bool:
	var neighbor_re := RegEx.create_from_string(NEIGHBOR_PATTERN)
	var k := action - 1
	while k >= block_start:
		var line := lines[k]
		var stripped := line.lstrip(" \t")
		if line.length() - stripped.length() != indent or not stripped.begins_with("- IF"):
			break
		var m := neighbor_re.search(line)
		if m != null and ROAD_NEIGHBOR_TYPES.has(m.get_string(1).to_int()):
			return true
		k -= 1
	return false


## SetTileRange(x, y, w, h, tile) → [Op, Rect2i]；坐标是相对地块原点 Tilemapspot 的偏移。
static func parse_step(args_text: String) -> Array:
	var args := split_top_level(args_text)
	if args.size() < 5:
		return []
	var x := parse_offset(args[0])
	var y := parse_offset(args[1])
	if x < 0 or y < 0:
		return []
	match args[4].to_int():
		TILE_PAVEMENT:
			return [Op.PAVE, Rect2i(x, y, args[2].to_int(), args[3].to_int())]
		TILE_GRASS:
			return [Op.ERASE, Rect2i(x, y, args[2].to_int(), args[3].to_int())]
	return []


## `TilemapspotX` 是地块原点，`(TilemapspotX + 3)` 是原点右边第 3 格。
static func parse_offset(token: String) -> int:
	var text := token.strip_edges()
	if text == "TilemapspotX" or text == "TilemapspotY":
		return 0
	var m := RegEx.create_from_string(OFFSET_PATTERN).search(text)
	return m.get_string(1).to_int() if m != null else -1


## 参数里有嵌套括号，不能直接按逗号切。
static func split_top_level(text: String) -> PackedStringArray:
	var parts := PackedStringArray()
	var depth := 0
	var current := ""
	for i in text.length():
		var ch := text[i]
		if ch == "(":
			depth += 1
		elif ch == ")":
			depth -= 1
		if ch == "," and depth == 0:
			parts.append(current.strip_edges())
			current = ""
		else:
			current += ch
	parts.append(current.strip_edges())
	return parts


static func paint(layer: TileMapLayer, steps: Array) -> int:
	var cells := resolve_cells(steps)
	layer.clear()
	# ignore_empty_terrains 必须是 false：Footprint 是空图层，置 true 时约束求解找不到相邻地形，一格都画不出来。
	layer.set_cells_terrain_connect(cells, TERRAIN_SET, PATH_TERRAIN, false)
	return cells.size()


## 排序只为固定写入顺序：重跑能得到字节一致的 tile_map_data，版本库里不会出现无意义 diff。
static func resolve_cells(steps: Array) -> Array[Vector2i]:
	var kept := {}
	for step in steps:
		var op: Op = step[0]
		var rect := convert_rect(step[1], op)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if op == Op.PAVE:
					kept[Vector2i(x, y)] = true
				else:
					kept.erase(Vector2i(x, y))
	var cells: Array[Vector2i] = []
	cells.assign(kept.keys())
	cells.sort()
	return cells


## 读出来的是原版 SetTileRange 的原始参数，这里统一做约定校正并裁到地块范围内
## （原版靠 17×17 tilemap 自己裁，越界的写入直接丢掉）。
static func convert_rect(rect: Rect2i, op: Op) -> Rect2i:
	var grown := rect.grow(CONVENTION_GROW if op == Op.PAVE else -CONVENTION_GROW)
	return grown.intersection(BLOCK_RECT)


static func describe(steps: Array) -> String:
	var parts := PackedStringArray()
	for step in steps:
		var rect: Rect2i = step[1]
		parts.append("%s(%d, %d, %d, %d)" % [
			"铺" if step[0] == Op.PAVE else "擦",
			rect.position.x, rect.position.y, rect.size.x, rect.size.y])
	return " ".join(parts)
