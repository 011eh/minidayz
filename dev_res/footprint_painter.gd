@tool
extends EditorScript
## 按原版 create_map_location 里的 SetTileRange 序列重绘地块模板的 Footprint。
##
## 用法：在编辑器里打开目标模板场景 → File > Run（Ctrl+Shift+X）→ Ctrl+S 存盘。
##
## Footprint 只存路面 cell（LocationTemplate._collect_footprint 读的是 get_used_cells），
## 所以原版"往已铺好的路面里写回另一种 tile"那一步，若那种 tile 不是路面就用 ERASE 表示。

enum Op { PAVE, ERASE }

const TERRAIN_SET := 0
const PATH_TERRAIN := 1

## 场景路径 -> 按顺序执行的 [Op, Rect2i]；Rect2i 的四个参数与原版 SetTileRange(x, y, w, h) 一一对应。
const RECIPES := {
	"res://environment/location_template/village_17.tscn": [
		# map_generation.decoded.txt:2963（地点类型 iv[0] = 17）。
		# 原版紧接着还有一条 SetTileRange(+5, +7, 6, 5, tile 6) 写在这块路面内部，
		# 但 tile 6 在游戏里仍是路面（仓库里没有原版 tileset 图，无法从索引反推材质），
		# 所以整块 10×9 铺满，不做挖空。
		[Op.PAVE, Rect2i(3, 5, 10, 9)],
	],
}


func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("[footprint_painter] 没有正在编辑的场景。")
		return
	if not RECIPES.has(root.scene_file_path):
		push_error("[footprint_painter] RECIPES 里没有 %s 的配方。" % root.scene_file_path)
		return
	var block := root as LocationTemplate
	if block == null or block.footprint == null:
		push_error("[footprint_painter] 场景根不是带 Footprint 的 LocationTemplate。")
		return
	var count := paint(block.footprint, RECIPES[root.scene_file_path])
	print("[footprint_painter] %s：%d 个路面 cell，记得存盘。" % [root.scene_file_path, count])
	EditorInterface.mark_scene_as_unsaved()


static func paint(layer: TileMapLayer, steps: Array) -> int:
	var cells := resolve_cells(steps)
	layer.clear()
	# ignore_empty_terrains 必须是 false：Footprint 是空图层，置 true 时约束求解找不到相邻地形，一格都画不出来。
	layer.set_cells_terrain_connect(cells, TERRAIN_SET, PATH_TERRAIN, false)
	return cells.size()


## 排序只为固定写入顺序：同一份配方重跑能得到字节一致的 tile_map_data，版本库里不会出现无意义 diff。
static func resolve_cells(steps: Array) -> Array[Vector2i]:
	var kept := {}
	for step in steps:
		var op: Op = step[0]
		var rect: Rect2i = step[1]
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
