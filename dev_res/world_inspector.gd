extends Node2D

## 世界调试叠加工具：跑真实 ground 全图时，在每个地点(城镇)地块上画出
## 「block 边界(大小)」+「类型文字」。和 dev_camera 一样，作为节点挂进场景即可。
##
## 用法：挂到 Ground 场景下当子节点（ground_path 留空则自动取父节点），
## 运行 ground.tscn 就能在世界地图上看到每个城镇的范围与类型。

@export var ground_path: NodePath           # 指向 Ground 节点(含 ground.gd)；留空=父节点
@export var show_block_grid := true         # 画 16×16 的 block 网格(看整体地块划分)
@export var show_fill := true               # 地点块半透明填充
@export var font_size := 120                # 类型文字大小(世界像素)
@export var border_width := 6.0             # 地块边框粗细

# 类型名(来自 ground.BlockType) → 颜色
const TYPE_COLORS := {
	"VILLAGE": Color.LIME_GREEN,
	"CITY": Color.ORANGE,
	"MILITARY": Color.RED,
	"HOSPITAL": Color.CYAN,
	"FIRESTATION": Color.YELLOW,
	"SECRET": Color.MAGENTA,
	"WATER": Color.DODGER_BLUE,
}

var ground: Node
var _font: Font

func _ready() -> void:
	z_index = 100  # 画在所有 tilemap 之上
	_font = ThemeDB.fallback_font
	ground = get_node_or_null(ground_path) if ground_path else get_parent()
	# 等 ground 在自己的 _ready 里生成完地图后再画
	call_deferred("queue_redraw")

func _process(_delta: float) -> void:
	# dev 工具：每帧重画，确保 regenerate 后也跟着更新（开销可忽略，~26 个地点）
	queue_redraw()

func _draw() -> void:
	if not ground or ground.locations.is_empty():
		return
	var bpx: int = ground.BLOCK_PX
	var n: int = ground.MAP_SIZE_IN_BLOCKS
	var type_names: Array = ground.BlockType.keys()

	# 整体 block 网格(淡)
	if show_block_grid:
		var total := float(n * bpx)
		for i in range(n + 1):
			var p := float(i * bpx)
			draw_line(Vector2(p, 0), Vector2(p, total), Color(1, 1, 1, 0.06), 1.0)
			draw_line(Vector2(0, p), Vector2(total, p), Color(1, 1, 1, 0.06), 1.0)

	# 每个地点：边框(大小) + 类型文字
	for loc in ground.locations:
		var type_name: String = type_names[loc.type]
		var col: Color = TYPE_COLORS.get(type_name, Color.WHITE)
		_draw_block_marker(loc.block, type_name, col, bpx)

	# 水域块：不在 locations 里，直接扫 grid 标出范围 + 类型 + 坐标
	var water_type: int = ground.BlockType.WATER
	var water_col: Color = TYPE_COLORS.get("WATER", Color.DODGER_BLUE)
	for by in range(n):
		for bx in range(n):
			if ground.grid[by][bx] == water_type:
				_draw_block_marker(Vector2i(bx, by), "WATER", water_col, bpx)

func _draw_block_marker(block: Vector2i, type_name: String, col: Color, bpx: int) -> void:
	var rect := Rect2(Vector2(block) * bpx, Vector2(bpx, bpx))
	if show_fill:
		draw_rect(rect, Color(col.r, col.g, col.b, 0.12), true)
	draw_rect(rect, col, false, border_width)
	draw_string(_font, rect.position + Vector2(24, font_size + 12), type_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
	# 角标：block 坐标(小字)
	draw_string(_font, rect.position + Vector2(24, font_size * 2), "block %d,%d" % [block.x, block.y],
		HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size * 0.5), Color(1, 1, 1, 0.7))
