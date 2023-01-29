extends Node2D


const EQUIPMENT_SLOT_NUMBER = 9
const WEPAON_OFFSET = 6


signal equipment_changed


var equipment_slots: Array[Item]
@onready
var pickup_area := $PickupArea as Area2D

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
			# todo，丢弃装备
			pass
		equipment_slots[index] = item
		item.get_parent().remove_child(item)
		emit_signal('equipment_changed', index, item.texture)
	else:
		var gears: Array[Item]
		if item is NumberItem:
			gears = equipment_slots.slice(0, WEPAON_OFFSET) as Array[Gear]
			var items:Array[NumberItem] = []
			for gear in gears:
				if is_instance_valid(gear):
					var same_item := func(item_in_slot: NumberItem) -> NumberItem:
						if item.get_item_id() == item_in_slot.resource.id:
							return item_in_slot
						else:
							return null
					items.append_array(gear.slots.map(same_item))
			# todo，将物品堆叠到背包物品
		
		var not_full = func(gear: Gear) -> bool:
			return is_instance_valid(gear) and gear.has_empty_slot()
		gears = equipment_slots.slice(0, WEPAON_OFFSET).filter(not_full) as Array[Item]
		var sort_by_stackable_and_durability = func(g1: Gear, g2: Gear) -> bool:
			var item_id := item.get_item_id()
			var g1_stackable := is_instance_valid(g1.get_item_to_stack(item_id))
			var g2_stackable := is_instance_valid(g2.get_item_to_stack(item_id))
			if g1_stackable == g1_stackable:
				return g1.durability > g2.durability
			return g1_stackable > g2_stackable
		gears.sort_custom(sort_by_stackable_and_durability)
		if not gears.is_empty():
			gears.pop_front().add_to_slot(item)
			item.get_parent().remove_child(item)

func get_slot_index(item: Item) -> int:
	if item is Gear:
		return item.resource.type
	if item is MainWeapon:
		return 6
	if item is Pistol:
		return 7
	return 8
