extends SceneTree

const TEMPLATE := preload("res://environment/location_template/village_17.tscn")
const BLOCK := 1020.0
const MID := BLOCK * 0.5


func _initialize() -> void:
	var block := TEMPLATE.instantiate() as LocationTemplate
	root.add_child(block)

	var rows: Array = []
	for child in block.get_node(^"Slots").get_children():
		var slot := child as TemplateSlot
		if slot == null:
			continue
		var bb := _slot_bounds(slot)
		if bb.size == Vector2.ZERO:
			continue
		var vis_cx := bb.position.x + bb.size.x * 0.5
		rows.append({
			"name": slot.name,
			"type": _pool_name(slot),
			"px": slot.position.x,
			"py": slot.position.y,
			"cx": vis_cx,
			"bb": bb,
		})

	print("=== 各槽位 X 对称性（地块 0..1020，中线 510）===")
	print("%-14s %-20s %8s %8s %10s %10s" % ["槽位", "候选池", "posX", "视觉cx", "镜像posX", "偏中线"])
	for r in rows:
		print("%-14s %-20s %8.0f %8.0f %10.0f %+10.0f" % [
			r["name"], r["type"], r["px"], r["cx"], BLOCK - r["px"], r["cx"] - MID])

	print("\n=== 按候选池配对检查 ===")
	var by_type := {}
	for r in rows:
		by_type.get_or_add(r["type"], []).append(r)
	for t in by_type:
		var list: Array = by_type[t]
		list.sort_custom(func(a, b): return a["cx"] < b["cx"])
		print("\n[%s] %d 个，按视觉中心排序：" % [t, list.size()])
		var i := 0
		var j := list.size() - 1
		while i < j:
			var a: Dictionary = list[i]
			var b: Dictionary = list[j]
			var sum: float = a["cx"] + b["cx"]
			var err: float = sum - BLOCK
			print("   %-12s cx=%-6.0f  <->  %-12s cx=%-6.0f   和=%.0f  误差=%+.0f %s" % [
				a["name"], a["cx"], b["name"], b["cx"], sum, err,
				"" if absf(err) <= 8 else "  <<< 不对称"])
			i += 1
			j -= 1
		if i == j:
			var m: Dictionary = list[i]
			var dev: float = m["cx"] - MID
			print("   %-12s cx=%-6.0f  (居中项)  偏中线=%+.0f %s" % [
				m["name"], m["cx"], dev,
				"" if absf(dev) <= 8 else "  <<< 未居中"])

	block.free()
	quit()


func _slot_bounds(slot: TemplateSlot) -> Rect2:
	var bb := Rect2()
	var first := true
	if slot.pool == null:
		return bb
	for scene in slot.pool.entries:
		for l in slot._editor_sprite_layers(scene):
			var r := Rect2(Vector2(l["offset"]) + slot.position, Vector2(l["size"]))
			bb = r if first else bb.merge(r)
			first = false
	return bb


func _pool_name(slot: TemplateSlot) -> String:
	if slot.pool == null:
		return "<无>"
	var path := slot.pool.resource_path
	return path.get_slice("::", 1) if path.contains("::") else path.get_file()
