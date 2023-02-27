extends Control


signal test


var equipment_slots: Array[Item]
@onready
var inventory_ui = $InventoryUI

func _ready():
	ui_test()
	pass

func ui_test():
	inventory_ui.setup(equipment_slots)
	equipment_slots.resize(9)
	test.connect(inventory_ui.update_inventory_ui)
	set_item(PlayerInventory.EQUIPMENT_TYPE.PLAYER_SLOT)
	set_item(PlayerInventory.EQUIPMENT_TYPE.CLOTHES)
	set_item(PlayerInventory.EQUIPMENT_TYPE.PANTS)
	set_item(PlayerInventory.EQUIPMENT_TYPE.HELMET)
	set_item(PlayerInventory.EQUIPMENT_TYPE.VEST)
	set_item(PlayerInventory.EQUIPMENT_TYPE.BACKPACK)
	set_item(PlayerInventory.EQUIPMENT_TYPE.MAIN_WEAPON)
	set_item(PlayerInventory.EQUIPMENT_TYPE.PISTOL)
	set_item(PlayerInventory.EQUIPMENT_TYPE.MELEE_WEAPON)

func set_item(type: PlayerInventory.EQUIPMENT_TYPE):
	equipment_slots[type] = ItemCreator.create_equipment_random(type)
	emit_signal('test', type, equipment_slots[type])
