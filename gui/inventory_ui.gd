extends TextureRect


signal item_dropped
signal item_slotted
signal equipment_changed


const EQUIPMENT_TYPE = PlayerInventory.EquipmentType
const PickPileUI = preload('res://gui/pick_pile_item_ui.tscn')
const GEAR_TYPES = [
		PlayerInventory.EquipmentType.PLAYER_SLOT,
		PlayerInventory.EquipmentType.CLOTHES,
		PlayerInventory.EquipmentType.PANTS,
		PlayerInventory.EquipmentType.VEST,
		PlayerInventory.EquipmentType.BACKPACK,
	]


@onready
var item_menu := preload('res://gui/item_ui_menu.tscn').instantiate()
@onready
var player_slot := $Cards/PlayerSlot as GearUI
@onready
var clothes_card := $Cards/ClothesCard as GearUI
@onready
var pants_card := $Cards/PantsCard as GearUI
@onready
var vest_card := $Cards/VestCard as GearUI
@onready
var backpack_card := $Cards/BackpackCard as GearUI
@onready
var helmet_card_card := $Cards/HelmetCard as ItemCardUI
@onready
var main_wepaon_card := $Cards/MainWeaponCard as ItemCardUI
@onready
var pistol_card := $Cards/PistolCard as ItemCardUI
@onready
var melee_weapon_card := $Cards/MeleeWeaponCard as ItemCardUI
@onready
var pick_pile_item_ui := $ItemOnGround/PickPileItems
@onready
var equip_area := Rect2($EquipArea.get_global_rect())
@onready
var knife_equip_area := Rect2(melee_weapon_card.get_global_rect())

func setup(inventory: PlayerInventory) -> void:
	item_dropped.connect(inventory.drop_item)
	equipment_changed.connect(inventory.equip_item)
	inventory.slot_item_changed.connect(update_inventory_ui)
	for item_ui in get_tree().get_nodes_in_group('item_ui_group'):
		item_ui.pick_pile_item_slotted.connect(inventory.put_item_to_slot)
		item_ui.item_index_changed.connect(inventory.swap_item)
	
	item_menu.visible = false
	add_child(item_menu)

func _unhandled_input(event):
	if event.is_action_pressed('open_inventory'):
		visible = not visible

func update_inventory_ui(equipment_type: int, item: Item) -> void:
	match equipment_type:
		EQUIPMENT_TYPE.PLAYER_SLOT:
			player_slot.update_gear_ui(item)
		EQUIPMENT_TYPE.CLOTHES:
			clothes_card.update_gear_ui(item)
		EQUIPMENT_TYPE.PANTS:
			pants_card.update_gear_ui(item)
		EQUIPMENT_TYPE.VEST:
			vest_card.update_gear_ui(item)
		EQUIPMENT_TYPE.BACKPACK:
			backpack_card.update_gear_ui(item)
		EQUIPMENT_TYPE.HELMET:
			helmet_card_card.update_item_ui(item)
		EQUIPMENT_TYPE.MAIN_WEAPON:
			main_wepaon_card.update_item_ui(item)
		EQUIPMENT_TYPE.PISTOL:
			pistol_card.update_item_ui(item)
		EQUIPMENT_TYPE.MELEE_WEAPON:
			melee_weapon_card.update_item_ui(item)

func update_pick_pile_ui(items: Array[Item]) -> void:
	for item in items:
		var ui := PickPileUI.instantiate()
		pick_pile_item_ui.add_child(ui)
		ui.update_item_ui(item)

func _can_drop_data(at_position, ui):
	return (ui is PickPileItemUI and ui.equipment_type != PlayerInventory.EquipmentType.SIMPLE_ITEM) \
		or not equip_area.has_point(at_position) \
		or not ui is GearUI and knife_equip_area.has_point(at_position) and instance_from_id(ui.item_id) is Knife

func _drop_data(at_position, ui):
	if ui is PickPileItemUI and ui.equipment_type != PlayerInventory.EquipmentType.SIMPLE_ITEM \
		and equip_area.has_point(at_position):
		emit_signal('equipment_changed',ui.equipment_type, ui.item_id)
		return 
	if knife_equip_area.has_point(at_position) and instance_from_id(ui.item_id) is Knife:
		print('刀具处理')
		return
	if not ui is PickPileItemUI:
		var slot_index: int
		var type: PlayerInventory.EquipmentType
		if is_slot_item_ui(ui):
			slot_index = ui.get_index()
			type = ui.owning_gear_equipment_type
		else:
			slot_index = -1
			type = ui.equipment_type
		emit_signal('item_dropped', type, slot_index, true)

func is_slot_item_ui(ui: Variant) -> bool:
	return ui is ItemUI and ui.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM

func _gui_input(event):
	if event.is_action_pressed('open_item_menu'):
		print(name, ' ', event.get_instance_id())
