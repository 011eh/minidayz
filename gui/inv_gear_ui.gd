extends 'res://gui/inventory_card.gd'

class_name GearUI


const SLOT_TEXTURE = preload('res://asset/images/gui/inventory/gui_inv_slot_shadow.png')
const GEAR_ICON_REGION = Rect2(0, 320, 32, 32)
const DURABILITY_LABEL_OFFSET = 8
const ItemUISence = preload('res://gui/item_ui.tscn')
const DURABILITY_Y = 14


var atlas := AtlasTexture.new()
@export_range(1, 7)
var max_slot_number: int
@onready
var slots := $Slots


func _ready():
	for i in range(max_slot_number):
		var slot := TextureRect.new()
		slot.texture = SLOT_TEXTURE
		slot.visible = false
		slots.add_child(slot)
		var item_ui := ItemUISence.instantiate() as ItemUI
		$Items.add_child(item_ui)
		item_ui.change_ui_visible(false)
		item_ui.add_to_group('item_ui_group')
		item_ui.equipment_type = PlayerInventory.EquipmentType.SIMPLE_ITEM
		item_ui.owning_gear_equipment_type = equipment_type

func update_gear_ui(gear: Gear) -> void:
	await get_tree().process_frame
	if not is_instance_valid(gear):
		has_data = false
		visible = false
		return
	
	has_data = true
	item_id = gear.get_instance_id()
	var resource := gear.resource as GearResource
	atlas.atlas = resource.texture
	atlas.region = GEAR_ICON_REGION
	$Icon.texture = atlas
	var name := $Name
	var durability := $Durability as Label
	name.text = resource.item_name
	durability.text = '%.0f%%' % gear.durability
	durability.position.y = DURABILITY_Y if not name.get_line_count() > 1 else DURABILITY_Y + DURABILITY_LABEL_OFFSET

	for i in range(max_slot_number):
		var slot := $Slots.get_child(i)
		var item_ui := $Items.get_child(i)
		if i < resource.slot_number:
			slot.visible = true
			item_ui.visible = true
			item_ui = item_ui as ItemUI
			var item := gear.slots[i]
			item_ui.update_item_ui(item if is_instance_valid(item) else null)
		else:
			item_ui.visible = false
			slot.visible = false
	visible = true

func _get_drag_data(at_position):
	var icon := $Icon as TextureRect
	if equipment_type != PlayerInventory.EquipmentType.PLAYER_SLOT and \
		Rect2(icon.position, icon.size).has_point(at_position):
		var rect := TextureRect.new()
		rect.texture = $Icon.texture
		set_drag_preview(rect)
		return self

func _can_drop_data(at_position, ui):
	return has_data and $Icon.get_rect().has_point(at_position) and \
		not ItemActionTable.get_recipes(instance_from_id(item_id), instance_from_id(ui.item_id)).is_empty()

func _drop_data(at_position, ui):
	item_ui_dropped.emit(self, ui)
