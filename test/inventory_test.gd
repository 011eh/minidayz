extends Node


signal test


var equipment_slots: Array[Item]
@onready
var inventory_ui := $CanvasLayer/Control/InventoryUI
@onready
var inventory := $Inventory as PlayerInventory


func _ready():
	ui_test()
	pass

func ui_test():
	equipment_slots = inventory.equipment_slots
	inventory_ui.setup(inventory)
	equipment_slots[PlayerInventory.EquipmentType.PLAYER_SLOT] = Gear.create_player_slot()
	equipment_slots[PlayerInventory.EquipmentType.PLAYER_SLOT].slots[0] = ItemCreator.create_item(NumberItem, 26)
	inventory.emit_signal('slot_item_changed', PlayerInventory.EquipmentType.PLAYER_SLOT, equipment_slots[PlayerInventory.EquipmentType.PLAYER_SLOT])
	set_item(PlayerInventory.EquipmentType.CLOTHES)
	set_item(PlayerInventory.EquipmentType.PANTS)
	set_item(PlayerInventory.EquipmentType.HELMET)
	set_item(PlayerInventory.EquipmentType.VEST)
	set_item(PlayerInventory.EquipmentType.BACKPACK)
	set_item(PlayerInventory.EquipmentType.MAIN_WEAPON)
	set_item(PlayerInventory.EquipmentType.PISTOL)
	set_item(PlayerInventory.EquipmentType.MELEE_WEAPON)
	var items := ItemCreator.create_slot_item_list(20)
	for i in range(200):
		items.append(ItemCreator.create_random([
			NumberItem,
			Craft,
			Gear,
			MainWeapon,
			Pistol,
			MeleeWeapon
			].pick_random()))
	inventory_ui.update_pick_pile_ui(items.filter(func(item): return is_instance_valid(item)))

func set_item(type: PlayerInventory.EquipmentType):
	equipment_slots[type] = ItemCreator.create_equipment_random(type)
	inventory.emit_signal('slot_item_changed', type, equipment_slots[type])
