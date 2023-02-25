extends ItemUI


var update_helmet_ui = func(gear: Gear) -> void:
	icon.texture.atlas = gear.get_resource().texture
	icon.texture.region = ATLAS_REGION
	number_or_durability.text = (NUMBER_FORMAT + '%%') % gear.durability


func update_item_ui(item: Item) -> void:
	if not is_instance_valid(item):
		change_ui_visible(false)
		return

	if item is Gear and item.resource.type == GearResource.GearType.HELMET:
		update_helmet_ui.call(item)
	else:
		update_general_ui.call(item)
	change_ui_visible(true)

func change_ui_visible(visible: bool) -> void:
	has_data = visible
	self.visible = visible
