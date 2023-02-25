extends Node2D

class_name PlayerInventory


signal equipment_changed
signal slot_item_changed


enum EQUIPMENT_TYPE {
	PLAYER_SLOT,
	CLOTHES,
	PANTS,
	HELMET,
	VEST,
	BACKPACK,
	MAIN_WEAPON,
	PISTOL,
	MELEE_WEAPON
}


const EQUIPMENT_SLOT_NUMBER = 9
const WEPAON_OFFSET = 6


var target_item: Item
var equipment_slots: Array[Item]
@onready
var pickup_area := $PickupArea
@onready
var detection_area := $DetectionArea


func _ready():
	pickup_area.area_entered.connect(pickup)
	equipment_slots.resize(EQUIPMENT_SLOT_NUMBER)
	var player_slot := Gear.create_player_slot()
	equipment_slots[0] = player_slot

func _process(delta):
	if Input.is_action_pressed('pickup'):
		var item:Item = detection_area.nearest_item
		if is_instance_valid(item):
			pickup_area.set_deferred('monitoring', true)
			owner.target_position = item.global_position

func pickup(area: Area2D) -> void:
	var item := area.owner as Item
	if item != detection_area.nearest_item:
		return
	pickup_area.set_deferred('monitoring', false)
	owner.target_position = Vector2.ZERO

	if item.is_equipment():
		var index := get_equipment_slot_index(item)
		var item_in_equment_slot := equipment_slots[index]
		if is_instance_valid(item_in_equment_slot):
			item_in_equment_slot.position = owner.global_position
			owner.get_parent().call_deferred('add_child', item_in_equment_slot)
		equipment_slots[index] = item
		item.get_parent().remove_child(item)
		emit_signal('equipment_changed', index, item)
		emit_signal('slot_item_changed', index, item)
	else:
		var gears = equipment_slots.slice(0, WEPAON_OFFSET)\
		.filter(func(gear: Gear) -> bool: return is_instance_valid(gear))
		gears.sort_custom(func(g1: Gear, g2: Gear): g1.durability > g2.durability)

		# 尝试进行堆叠
		if item is NumberItem:
			var inventory_items:Array[NumberItem] = []
			for gear in gears:
				var same_item := func(inventory_item):
					if is_instance_valid(inventory_item) and item.get_item_id() == inventory_item.get_item_id()\
					and inventory_item.number < inventory_item.get_resource().stack_limit:
						return inventory_item
					else:
						return null
				inventory_items.append_array(gear.slots.map(same_item))
				inventory_items = inventory_items.filter(func(item: Item) -> bool: return is_instance_valid(item))

			if not inventory_items.is_empty() and stack_item(item, inventory_items):
				update_inventory_ui()
				return

		# 需要放到背包空槽位上
		gears = gears.filter(func(gear: Gear): return gear.has_empty_slot())
		if not gears.is_empty():
			gears.pop_front().add_to_slot(item)
			update_inventory_ui()
			item.get_parent().remove_child(item)

func stack_item(item: NumberItem,inventory_items: Array[NumberItem]) -> bool:
	while not inventory_items.is_empty():
		var inventory_item := inventory_items.pop_front() as NumberItem
		var item_number := item.number
		var inventory_item_number := inventory_item.number
		var stack_limit := inventory_item.get_resource().stack_limit
		var residual_capacity := stack_limit - inventory_item_number
		inventory_item.number = clamp(inventory_item_number + item_number, inventory_item_number + 1, stack_limit)
		item.number = clamp(item_number - residual_capacity, 0, item_number - 1)
		if item.number == 0:
			# 释放物品实例
			item.queue_free()
			return true
	return false

func get_equipment_slot_index(item: Item) -> int:
	if item is Gear:
		return item.resource.type
	if item is MainWeapon:
		return EQUIPMENT_TYPE.MAIN_WEAPON
	if item is Pistol:
		return EQUIPMENT_TYPE.PISTOL
	return EQUIPMENT_TYPE.MELEE_WEAPON

func update_inventory_ui() -> void:
	for i in range(equipment_slots.size()):
		var item := equipment_slots[i] as Item
		if is_instance_valid(item):
			emit_signal('slot_item_changed', i, item)
