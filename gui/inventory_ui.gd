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
var item_menu := preload('res://gui/item_ui_menu.tscn').instantiate() as TextureRect
@onready
var player_slot := %PlayerSlot as GearUI
@onready
var clothes_card := %ClothesCard as GearUI
@onready
var pants_card := %PantsCard as GearUI
@onready
var vest_card := %VestCard as GearUI
@onready
var backpack_card := %BackpackCard as GearUI
@onready
var helmet_card_card := %HelmetCard as ItemCardUI
@onready
var main_wepaon_card := %MainWeaponCard as ItemCardUI
@onready
var pistol_card := %PistolCard as ItemCardUI
@onready
var melee_weapon_card := %MeleeWeaponCard as ItemCardUI
@onready
var pick_pile_item_ui := %PickPileItems
@onready
var equip_area := Rect2(%EquipArea.get_global_rect())
@onready
var knife_equip_area := Rect2(melee_weapon_card.get_global_rect())


func setup(inventory: PlayerInventory) -> void:
	item_dropped.connect(inventory.drop_item)
	equipment_changed.connect(inventory.equip_item)
	inventory.slot_item_changed.connect(update_inventory_ui)
	ItemActionTable.setup(inventory, show_spin_box)
	
	for item_ui in get_tree().get_nodes_in_group('item_ui_group'):
		item_ui.pick_pile_item_slotted.connect(inventory.put_item_to_slot)
		item_ui.item_index_changed.connect(inventory.swap_item)
		item_ui.item_clicked.connect(toggle_item_menu)
	
	for item_card in get_tree().get_nodes_in_group('item_cards'):
		item_card.item_clicked.connect(toggle_item_menu)

	item_menu.visible = false
	add_child(item_menu)

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
		equipment_changed.emit(ui.equipment_type, ui.item_id)
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
		item_dropped.emit(type, slot_index, true)

func is_slot_item_ui(ui: Variant) -> bool:
	return ui is ItemUI and ui.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM

func toggle_item_menu(ui_id: int, item_id: int, g_position: Vector2) -> void:
	if not item_menu.visible or item_menu.get_meta('ui_id', -1) != ui_id:
		var item := instance_from_id(item_id) as Item
		item_menu.set_active(ui_id, g_position, item.get_item_name(), ItemActionTable.create_options(item))
		item_menu.visible = true
	else:
		item_menu.visible = false

func show_spin_box() -> void:
	print('show_spin_box')

func _gui_input(event):
	if event.is_action_pressed('toggle_inventory'):
		visible = not visible
		return
	if item_menu.visible and event.is_action_pressed('toggle_item_menu'):
		item_menu.visible = false
