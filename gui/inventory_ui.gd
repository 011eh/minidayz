extends Control


signal item_dropped
signal equipment_changed
signal knife_dropped
signal item_index_changed


const EQUIPMENT_TYPE = PlayerInventory.EquipmentType
const PickPileUI = preload('res://gui/pick_pile_item_ui.tscn')
const GEAR_TYPES = [
		PlayerInventory.EquipmentType.PLAYER_SLOT,
		PlayerInventory.EquipmentType.CLOTHES,
		PlayerInventory.EquipmentType.PANTS,
		PlayerInventory.EquipmentType.VEST,
		PlayerInventory.EquipmentType.BACKPACK,
	]


var pick_pile_ui_dict = {}
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
var equip_area := %EquipArea.get_global_rect() as Rect2
@onready
var knife_equip_area := %MeleeWeaponCard.get_global_rect() as Rect2


func _ready():
	clothes_card.visible = false
	pants_card.visible = false
	vest_card.visible = false
	backpack_card.visible = false
	helmet_card_card.visible = false
	main_wepaon_card.visible = false
	pistol_card.visible = false
	melee_weapon_card.visible = false
	%SplitItemDialog.visible = false

func setup(player: Player) -> void:
	var inventory := player.inventory
	item_dropped.connect(inventory.drop_item)
	knife_dropped.connect(inventory.ui_equip_knife)
	item_index_changed.connect(inventory.ui_swap_item)
	%SplitItemDialog.item_splitted.connect(inventory.ui_split_item)
	equipment_changed.connect(inventory.ui_equip_item)
	ItemActionTable.setup(inventory, show_spin_box)
	inventory.slot_item_changed.connect(update_inventory_ui)
	
	var detection_area := player.detection_area
	detection_area.area_entered.connect(func(area: InteractionArea) -> void:
		if area.owner_type != InteractionArea.OwnerType.ITEM:
			return
		
		var ui := PickPileUI.instantiate()
		pick_pile_item_ui.add_child(ui)
		ui.update_item_ui(area.owner)
		pick_pile_ui_dict[area.get_instance_id()] = ui
	)
	detection_area.area_exited.connect(func(area: InteractionArea) -> void:
		pick_pile_ui_dict.get(area.get_instance_id()).queue_free()
		pick_pile_ui_dict.erase(area.get_instance_id())
	)
	
	for item_ui in get_tree().get_nodes_in_group('item_ui_group'):
		item_ui.pick_pile_item_slotted.connect(inventory.ui_put_item_to_slot)
		item_ui.item_clicked.connect(toggle_item_menu)
		item_ui.item_ui_dropped.connect(handle_item_ui_dropped)
	
	for item_card in get_tree().get_nodes_in_group('item_cards'):
		item_card.item_clicked.connect(toggle_item_menu)
	
	%BackpackCard.item_ui_dropped.connect(handle_item_ui_dropped)
	
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
		var index := ui.get_index() if not ui is PickPileItemUI else -1 as int
		knife_dropped.emit(ui.item_id, ui.owning_gear_equipment_type, index)
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

func handle_item_ui_dropped(ui_replaced, ui_from) -> void:
	if ui_replaced.has_data:
		var options := ItemActionTable.create_crafting_options(ui_replaced.item_id, ui_from.item_id)
		toggle_item_menu(ui_replaced.get_instance_id(), ui_replaced.global_position, 'Craft', options)
	else:
		var ui_type := ui_from.owning_gear_equipment_type if ui_from.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM \
		else ui_from.equipment_type as EQUIPMENT_TYPE
		var slot_index := ui_from.get_index() if not ui_from is ItemCardUI else -1 as int
		item_index_changed.emit(ui_replaced.owning_gear_equipment_type, ui_replaced.get_index(), ui_type, slot_index)

func is_slot_item_ui(ui: Variant) -> bool:
	return ui is ItemUI and ui.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM

func toggle_item_menu(ui_id: int, g_position: Vector2, title: StringName, options: Array[ItemActionTable.ItemAction]) -> void:
	if not item_menu.visible or item_menu.get_meta('ui_id', -1) != ui_id:
		item_menu.set_active(ui_id, g_position, title, options)
		item_menu.visible = true
	else:
		item_menu.visible = false

func show_spin_box(item: NumberItem) -> void:
	%SplitItemDialog.show_dialog(item)

func _input(event):
	if event.is_action_pressed('toggle_inventory'):
		visible = not visible
		if visible:
			item_menu.visible = false
			%SplitItemDialog.visible = false
		return

func _gui_input(event):
	if item_menu.visible and event.is_pressed():
		item_menu.visible = false
