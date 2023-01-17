extends Area2D


var nearby_items = {}
var nearest_item: Item

@onready
var timer := $Timer as Timer

func _ready():
	area_entered.connect(record_item_position)
	area_exited.connect(erase_item_position)
	timer.timeout.connect(set_nearest_item)

func record_item_position(area: Area2D) -> void:
	var item := area.owner as Item
	nearby_items[item.get_instance_id()] = item
	if timer.is_stopped():
		timer.start()

func erase_item_position(area : Area2D) -> void:
	var item := area.owner as Item
	nearby_items.erase(item.get_instance_id())
	if nearest_item == item:
		nearest_item = null
	if nearby_items.is_empty():
		nearby_items
		timer.stop()

func set_nearest_item() -> void:
	var sort_by_distance = func(i1: Item, i2: Item) -> bool:
		var pos := owner.global_position as Vector2
		return i1.global_position.distance_to(pos) < i2.global_position.distance_to(pos)
	var items := nearby_items.values()
	items.sort_custom(sort_by_distance)
	nearest_item = items.front()
