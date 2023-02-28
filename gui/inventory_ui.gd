extends TextureRect


var equipment_slots: Array[Item]
@onready
var clothes_card := $Cards/ClothesCard
@onready
var pants_card := $Cards/PantsCard
@onready
var vest_card := $Cards/VestCard
@onready
var backpack_card := $Cards/BackpackCard
@onready
var helmet_card_card := $Cards/HelmetCard
@onready
var main_wepaon_card := $Cards/MainWeaponCard
@onready
var pistol_card := $Cards/PistolCard
@onready
var melee_weapon_card := $Cards/MeleeWeaponCard
@onready
var player_slot:= $Cards/PlayerSlot as GearUI


func setup(equipment_slots: Array[Item]) -> void:
	self.equipment_slots = equipment_slots
	for item_ui in get_tree().get_nodes_in_group('item_ui_group'):
		item_ui.item_ui_placed.connect(swap_item)

func _unhandled_input(event):
	if event.is_action_pressed('open_inventory'):
		visible = not visible

func update_inventory_ui(equipment_type: int, item: Item) -> void:
	match equipment_type:
		PlayerInventory.EQUIPMENT_TYPE.PLAYER_SLOT:
			player_slot.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.CLOTHES:
			clothes_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.PANTS:
			pants_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.VEST:
			vest_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.BACKPACK:
			backpack_card.update_gear_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.HELMET:
			helmet_card_card.update_item_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.MAIN_WEAPON:
			main_wepaon_card.update_item_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.PISTOL:
			pistol_card.update_item_ui(item)
		PlayerInventory.EQUIPMENT_TYPE.MELEE_WEAPON:
			melee_weapon_card.update_item_ui(item)

func swap_item(dropped_equipment: PlayerInventory.EQUIPMENT_TYPE,
	dropped_item_index: int,
	replaced_equipment: PlayerInventory.EQUIPMENT_TYPE,
	replaced_index: int) ->void:
	pass
#	var d_type := replaced_ui.item_owner.equipment_type
#	var r_type := replaced_ui.item_owner.equipment_type
#
#	match d_type:
#		PlayerInventory.EQUIPMENT_TYPE.PLAYER_SLOT,\
#		PlayerInventory.EQUIPMENT_TYPE.CLOTHES,\
#		PlayerInventory.EQUIPMENT_TYPE.PANTS,\
#		PlayerInventory.EQUIPMENT_TYPE.VEST,\
#		PlayerInventory.EQUIPMENT_TYPE.BACKPACK:
#			var r_index := replaced_ui.get_index()
#			var r_slots := equipment_slots[r_type].slots as Array[Item]
#			var r_before := r_slots[r_index] as Item
#			var d_index := dropped_ui.get_index()
#			var d_slots := equipment_slots[d_type].slots as Array[Item]
#			var d_before := d_slots[d_index] as Item
#			r_slots[r_index] = d_before
#			d_slots[d_index] = r_before
#			dropped_ui.update_item_ui(r_before)
#			replaced_ui.update_item_ui(d_before)
