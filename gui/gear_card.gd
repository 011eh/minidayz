extends TextureRect


const SlotTexture := preload('res://asset/images/gui/inventory/gui_inv_slot_shadow.png')
const GEAR_ICON_REGION := Rect2(0, 320, 32, 32)
const DURABILITY_OFFSET := 11


func _ready():
	update(ItemCreator.create_item(Gear, 6))

func update(gear: Gear) -> void:
	var resource := gear.resource
	var atlas := AtlasTexture.new()
	atlas.atlas = resource.texture
	atlas.region = GEAR_ICON_REGION
	$Icon.texture = atlas
	var name := $Name
	name.text = 'fffffffffffffffffaa'
	$Durability.text = '%.0f%%' % gear.durability
	if name.get_line_count() == 2:
		$Durability.offset_top += DURABILITY_OFFSET
	for i in range(0):
		var icon := TextureRect.new()
		icon.texture = SlotTexture
		$Slots.add_child(icon)
	visible = true
