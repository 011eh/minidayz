extends Node2D

class_name PlayerInventory


signal equipment_changed
signal slot_item_changed


enum EquipmentType {
	PLAYER_SLOT,
	CLOTHES,
	PANTS,
	HELMET,
	VEST,
	BACKPACK,
	MAIN_WEAPON,
	PISTOL,
	MELEE_WEAPON,
	SIMPLE_ITEM
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
	put_to_inventory(item)

func put_to_inventory(item: Item, from_world: bool = true) -> bool:
	if item.is_equipment():
		var type := get_equipment_type(item)
		var item_in_slot := equipment_slots[type]
		if is_instance_valid(item_in_slot):
			if type == EquipmentType.MELEE_WEAPON and item_in_slot is Knife:
				put_to_inventory(item_in_slot, false)
			drop_item(type)
		equipment_slots[type] = item
		item.get_parent().remove_child(item)
		emit_signal('equipment_changed', type, item)
		emit_signal('slot_item_changed', type, item)
		return true
	else:
		var gears = get_gear_sort_by_durability()
		
		# 尝试进行堆叠
		if item is NumberItem:
			var inventory_items := find_stackable_items(item, gears)
			if not inventory_items.is_empty() and stack_item(item, inventory_items):
				update_inventory_ui()
				return true
		
		# 需要放到背包空槽位上
		var success := put_to_slot(item, from_world, gears)
		if success:
			update_inventory_ui()
		return success

func get_gear_sort_by_durability() -> Array[Gear]:
	var gears: Array[Gear] = []
	for gear in equipment_slots.slice(0, WEPAON_OFFSET):
		if is_instance_valid(gear):
			gears.append(gear)
	gears.sort_custom(func(g1: Gear, g2: Gear): g1.durability > g2.durability)
	return gears

func find_stackable_items(item: Item, gears: Array[Gear]) -> Array[NumberItem]:
	var inventory_items:Array[NumberItem] = []
	for gear in gears:
		var same_item := func(inventory_item):
			if is_instance_valid(inventory_item) and item.get_item_id() == inventory_item.get_item_id()\
			and inventory_item.number < inventory_item.get_resource().stack_limit:
				return inventory_item
			else:
				return null
		inventory_items.append_array(gear.slots.map(same_item))
	return inventory_items.filter(func(item: Item) -> bool: return is_instance_valid(item))

func put_to_slot(item: Item, from_world: bool = false, gears: Array[Gear] = []) -> bool:
	if gears == []:
		gears = get_gear_sort_by_durability()
	gears = gears.filter(func(gear: Gear): return gear.has_empty_slot())
	if not gears.is_empty():
		gears.pop_front().add_to_slot(item)
		if from_world:
			item.get_parent().remove_child(item)
		return true
	return false

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

func get_equipment_type(item: Item) -> int:
	if item is Gear:
		return item.resource.type
	if item is MainWeapon:
		return EquipmentType.MAIN_WEAPON
	if item is Pistol:
		return EquipmentType.PISTOL
	return EquipmentType.MELEE_WEAPON

func ui_equip_item(type: EquipmentType, item_id: int) -> void:
	var item_in_slot := equipment_slots[type]
	if is_instance_valid(item_in_slot):
		if item_in_slot is Knife:
			if not put_to_inventory(item_in_slot, false):
				drop_item(type)
	var item := instance_from_id(item_id)
	equipment_slots[type] = item
	equipment_changed.emit(type, item)
	slot_item_changed.emit(type, item)

func drop_item(type: EquipmentType, slot_index: int = -1, update_ui: bool = false) -> void:
	var item: Item
	if slot_index == -1:
		item = equipment_slots[type]
		equipment_slots[type] = null
	else:
		var slots := equipment_slots[type].slots as Array[Item]
		item = slots[slot_index]
		slots[slot_index] = null
	item.position = owner.global_position
	owner.get_parent().call_deferred('add_child', item)
	if update_ui:
		slot_item_changed.emit(type, equipment_slots[type])
		equipment_changed.emit(type, equipment_slots[type])

func ui_put_item_to_slot(type: EquipmentType, index: int, item_id: int) -> void:
	var gear := equipment_slots[type] as Gear
	gear.slots[index] = instance_from_id(item_id)
	emit_signal('slot_item_changed', type, gear)

func ui_swap_item(type: EquipmentType, index: int, from_type: EquipmentType, from_index: int = -1) -> void:
	var gear = equipment_slots[type] as Gear
	if from_index == -1:
		gear.slots[index] = equipment_slots[from_type]
		equipment_slots[from_type] = null
		emit_signal('equipment_changed', from_type, null)
		emit_signal('slot_item_changed', from_type, null)
	else:
		var temp := gear.slots[index] as Item
		var from_gear = equipment_slots[from_type]
		gear.slots[index] = from_gear.slots[from_index]
		from_gear.slots[from_index] = temp
		emit_signal('slot_item_changed', from_type, from_gear)
	emit_signal('slot_item_changed', type, gear)

func ui_split_item(item: NumberItem) -> void:
	if not put_to_slot(item):
		item.position = owner.global_position
		owner.get_parent().call_deferred('add_child', item)
	update_inventory_ui()

func update_inventory_ui() -> void:
	for i in range(equipment_slots.size()):
		var item := equipment_slots[i] as Item
		if is_instance_valid(item):
			emit_signal('slot_item_changed', i, item)
