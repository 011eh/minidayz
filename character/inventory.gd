extends Node2D


const EQUIPMENT_SLOT_NUMBER = 9
const WEPAON_OFFSET = 6


signal equipment_changed


var equipment_slots: Array[Item]
@onready
var pickup_area := $PickupArea as Area2D


#func _process(delta):
#	for i in range(WEPAON_OFFSET):
#		print(equipment_slots[i].slots)

func _ready():
	pickup_area.area_entered.connect(pickup)
	equipment_slots.resize(EQUIPMENT_SLOT_NUMBER)
	var charact_slot := Gear.create_character_slot()
	equipment_slots[0] = charact_slot

func pickup(area: Area2D) -> void:
	var item := area.owner as Item
	if item.is_equipment():
		var index := get_slot_index(item)
		var item_in_equment_slot := equipment_slots[index]
		if is_instance_valid(item_in_equment_slot):
			# todo drop item
			pass
		equipment_slots[index] = item
		print(index)
		emit_signal('equipment_changed', index, item.texture)

	else:
		var not_full = func(gear: Gear) -> bool:
			return is_instance_valid(gear) and gear.not_full()
		var gears: Array[Item] = equipment_slots.slice(0, WEPAON_OFFSET).filter(not_full)
		var sort_by_durability = func(g1: Gear, g2: Gear) -> bool:
			return g1.durability > g2.durability
		gears.sort_custom(sort_by_durability)
		if not gears.is_empty():
			gears.front().add_to_slot(item)
			item.get_parent().remove_child(item)

func get_slot_index(item: Item) -> int:
	if item is Gear:
		return item.resource.type
	if item is MainWeapon:
		return 6
	if item is Pistol:
		return 7
	return 8
