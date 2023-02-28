extends ItemCardUI


const LABEL_OFFSET := 7
const SLOT_ITEM_TEXTURE := preload('res://asset/images/item/gui_slot_item.png')
const MAIN_WEAPON_TEXTURE := preload('res://asset/images/equipment/weapon/main/gui_main_weapon.png')
const PISTOL_TEXTURE := preload('res://asset/images/equipment/weapon/pistol/gui_pistol.png')
const MELEE_WEAPON_TEXTURE := preload('res://asset/images/equipment/weapon/melee/gui_melee.png')


@onready
var name_label := $Name


func update_item_ui(item: Item) -> void:
	if item is MeleeWeapon or item is Knife:
		change_atlas_data(7, 0, Vector2(44, 44), MELEE_WEAPON_TEXTURE)
	elif item is Pistol:
		change_atlas_data(4, -25, Vector2(82, 82), PISTOL_TEXTURE)
	elif item is MainWeapon:
		change_atlas_data(5, 0, Vector2(68, 185), MAIN_WEAPON_TEXTURE)
	else:
		change_atlas_data(5, 0, Vector2(32, 32), SLOT_ITEM_TEXTURE)

	name_label.text = item.resource.item_name
	if name_label.get_line_count() > 1:
		number_or_durability.position.y += LABEL_OFFSET
	super.update_item_ui(item)

func change_atlas_data(col_number: int, id_offset: int, icon_size: Vector2, texture: Texture2D) -> void:
	column_number = col_number
	self.icon_size = icon_size
	atlas_texture_id_offset = id_offset
	icon.texture.atlas = texture
