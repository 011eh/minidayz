extends 'res://gui/inventory_card.gd'

class_name ItemUI


signal pick_pile_item_slotted
signal item_index_changed
signal item_clicked


const EQUIPMENT_TYPE = PlayerInventory.EquipmentType
const NUMBER_FORMAT = '%d'
const ATLAS_REGION = Rect2(0, 320, 32, 32)


var item_id: int
var has_data := true
var owning_gear_equipment_type: PlayerInventory.EquipmentType
@export
var atlas_texture:= preload('res://asset/images/item/gui_slot_item.png')
@export
var atlas_texture_id_offset := 0
@export
var column_number := 5
@export
var icon_size := Vector2(32, 32)
@export
var can_drop_item_list:Array[GDScript] = [NumberItem, Craft, Knife]
@onready
var icon := $Icon
@onready
var number_or_durability := $Info/NumberOrDurability


func _ready():
	var atlas := AtlasTexture.new()
	icon.texture = atlas
	atlas.atlas = atlas_texture

func update_item_ui(item: Item) -> void:
	if not is_instance_valid(item):
		change_ui_visible(false)
		return
	item_id = item.get_instance_id()
	if item is Knife:
		update_general_ui(item, 84)
	else:
		update_general_ui(item)
	change_ui_visible(true)

func update_general_ui(item: Item, offset: int = 0) -> void:
	var index := item.resource.id + offset
	icon.texture.region = Rect2(
		(index + atlas_texture_id_offset) % column_number * icon_size.x,
		(index + atlas_texture_id_offset) / column_number * icon_size.y,
		icon_size.x,
		icon_size.y)

	var label_text: String
	if item is NumberItem:
		label_text = NUMBER_FORMAT % item.number
	else:
		label_text = (NUMBER_FORMAT + '%%') % item.durability
	number_or_durability.text = label_text
	if item is RangedWeapon:
		$Info/BulletNumber.text = NUMBER_FORMAT % item.get_bullet_number()

func change_ui_visible(visible: bool) -> void:
	has_data = visible
	icon.visible = visible
	$Info.visible = visible

func _get_drag_data(at_position):
	if has_data:
		var rect := TextureRect.new()
		rect.texture = icon.texture
		set_drag_preview(rect)
#		icon.visible = false
#		$Info.visible = false
		return self

func _can_drop_data(at_position, ui):
	if ui is PickPileItemUI:
		return not has_data and ui.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM
	else:
		return ui.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM or not has_data \
			and ui.equipment_type == EQUIPMENT_TYPE.MELEE_WEAPON \
			and instance_from_id(ui.item_id) is Knife

func _drop_data(at_position, ui):
	if ui is PickPileItemUI:
		pick_pile_item_slotted.emit( owning_gear_equipment_type, get_index(), ui.item_id)
	elif ui != self:
		var ui_type := ui.owning_gear_equipment_type if ui.equipment_type == EQUIPMENT_TYPE.SIMPLE_ITEM \
		else ui.equipment_type as EQUIPMENT_TYPE
		var slot_index := ui.get_index() if not ui is ItemCardUI else -1 as int
		item_index_changed.emit( owning_gear_equipment_type, get_index(), ui_type, slot_index)

func _gui_input(event):
	if  has_data and event.is_action_pressed('toggle_item_menu') and not self is PickPileItemUI:
		item_clicked.emit(get_instance_id(), item_id, get_global_mouse_position())
		accept_event()
