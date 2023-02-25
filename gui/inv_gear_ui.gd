extends TextureRect

class_name GearUI


const ItemIcon := preload('res://gui/item_ui.tscn')
const SlotTexture := preload('res://asset/images/gui/inventory/gui_inv_slot_shadow.png')
const ItemUIContent := preload('res://gui/item_ui.tscn')
const GEAR_ICON_REGION := Rect2(0, 320, 32, 32)
const DURABILITY_LABEL_OFFSET := 8


var atlas := AtlasTexture.new()
var gear: Gear
@export_range(1, 7)
var max_slot_number: int
@onready
var slots := $Slots


func _ready():
	for i in range(max_slot_number):
		var slot := TextureRect.new()
		slot.texture = SlotTexture
		slot.visible = false
		slots.add_child(slot)
		var item_ui := ItemUIContent.instantiate() as ItemUI
		item_ui.item_owner = self
		item_ui.item_dropped.connect(swap_item)
		item_ui.visible = false
		$Items.add_child(item_ui)

func update_gear_ui(gear: Gear) -> void:
	self.gear = gear
	if not is_instance_valid(gear):
		visible = false
		return

	var resource := gear.resource as GearResource
	atlas.atlas = resource.texture
	atlas.region = GEAR_ICON_REGION
	$Icon.texture = atlas
	var name := $Name
	var durability := $Durability
	name.text = resource.item_name
	durability.text = '%.0f%%' % gear.durability
	if name.get_line_count() > 1:
		durability.offset_top += DURABILITY_LABEL_OFFSET

	for i in range(max_slot_number):
		var slot := $Slots.get_child(i)
		var item_ui := $Items.get_child(i)
		if i < resource.slot_number:
			slot.visible = true
			item_ui.visible = true
			var item := gear.slots[i] as Item
			item_ui.update_item_ui(gear.slots[i])
		else:
			item_ui.visible = false
			slot.visible = false
	visible = true

func swap_item(ui_dropped: ItemUI, ui_replaced: ItemUI) -> void:
	var d_slots := ui_dropped.item_owner.gear.slots
	var r_slots := ui_replaced.item_owner.gear.slots
	var d_index := ui_dropped.get_index()
	var r_index := ui_replaced.get_index()
	var temp := r_slots[r_index]
	r_slots[r_index] = d_slots[d_index]
	d_slots[d_index] = temp
	ui_dropped.update_item_ui(temp)
	ui_replaced.update_item_ui(r_slots[r_index])
