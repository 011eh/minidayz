extends Node

class_name ItemCreator


const ItemScene := preload('res://item/item.tscn')


static func create_item(item_script: GDScript, item_id: int) -> Item:
	var item := ItemScene.instantiate()
	item.set_script(item_script)
	item.resource = item_script.get_item_resource(item_id)
	return item

static func create_random(item_script: GDScript) -> Item:
	return create_item(item_script, item_script.RES_TABLE.keys().pick_random())

static func create_equipment_random(type: PlayerInventory.EquipmentType) -> Item:
	match type:
		PlayerInventory.EquipmentType.MAIN_WEAPON:
			return create_random(MainWeapon)
		PlayerInventory.EquipmentType.PISTOL:
			return create_random(Pistol)
		PlayerInventory.EquipmentType.MELEE_WEAPON:
			return create_random([MeleeWeapon, Knife].pick_random())
		_:
			return create_gear_random(type)

static func create_gear_random(type: PlayerInventory.EquipmentType) -> Gear:
	var gear: Gear
	match type:
		PlayerInventory.EquipmentType.CLOTHES:
			gear = ItemCreator.create_item(Gear, randi_range(0, 16))
		PlayerInventory.EquipmentType.PANTS:
			gear = ItemCreator.create_item(Gear, randi_range(17, 23))
		PlayerInventory.EquipmentType.HELMET:
			gear = ItemCreator.create_item(Gear, randi_range(24, 41))
		PlayerInventory.EquipmentType.VEST:
			gear = ItemCreator.create_item(Gear, randi_range(42, 47))
		PlayerInventory.EquipmentType.BACKPACK:
			gear = ItemCreator.create_item(Gear, randi_range(48, 55))
		_:
			return null
	var slot_number := gear.get_resource().slot_number
	for i in range(slot_number):
		gear.slots[randi_range(0, slot_number - 1)] = create_slot_item_random()
	return gear

static func create_slot_item_random() -> Item:
	return create_random([NumberItem, Craft, Knife].pick_random())

static func create_slot_item_list(size := 1) -> Array[Item]:
	var list: Array[Item] = []
	for i in range(size):
		list.append(create_slot_item_random())
	return list
