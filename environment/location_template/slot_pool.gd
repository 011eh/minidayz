@tool
class_name SlotPool
extends Resource


## 一组可互换的候选场景。多个槽位引用同一个池，改池即改全部。
## 跨模板复用的存成 .tres；只用于单个模板的直接在检查器里新建，会内嵌进场景文件。
@export
var entries: Array[PackedScene] = []:
	set(value):
		entries = value
		emit_changed()

## 留空 = 等概率；否则长度需与 entries 一致。
@export
var weights: PackedFloat32Array = []:
	set(value):
		weights = value
		emit_changed()


func pick(rng: RandomNumberGenerator) -> PackedScene:
	var index := pick_index(rng)
	return entries[index] if index >= 0 else null


func pick_index(rng: RandomNumberGenerator) -> int:
	if entries.is_empty():
		return -1
	if weights.size() != entries.size():
		return rng.randi() % entries.size()

	var total := 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return rng.randi() % entries.size()

	var roll := rng.randf() * total
	for i in entries.size():
		roll -= weights[i]
		if roll < 0.0:
			return i
	return entries.size() - 1
