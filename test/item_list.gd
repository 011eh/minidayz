extends HSplitContainer


@export
var gui_texture: Texture2D
@export
var frame_size: int
@onready
var item_list := $ItemList as ItemList
@onready
var label := $RichTextLabel as RichTextLabel
var id_dict := {}
func _ready():
	var h_frames := gui_texture.get_width() / frame_size
	var keys := SlotItem.RES_TABLE.keys()
	for i in range(keys.size()):
		var id := keys[i] as int
		var texture := AtlasTexture.new()
		texture.atlas = gui_texture
		texture.region = Rect2(
			id % h_frames * frame_size,
			id / h_frames * frame_size,
			frame_size,
			frame_size
			)
		item_list.add_icon_item(texture)

#	ids = SlotItem.RES_TABLE.keys()
#	for id in ids:
#		add_child(SlotItem.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
#
#	ids = Craft.RES_TABLE.keys()
#	for id in ids:
#		add_child(Craft.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
#
#	ids = Knife.RES_TABLE.keys()
#	for id in ids:
#		add_child(Knife.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
#
#	ids = MeleeWeapon.RES_TABLE.keys()
#	for id in ids:
#		add_child(MeleeWeapon.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
#
#	ids = MainWeapon.RES_TABLE.keys()
#	for id in ids:
#		add_child(MainWeapon.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
#
#	ids = Pistol.RES_TABLE.keys()
#	for id in ids:
#		add_child(Pistol.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
#
#	ids = Gear.RES_TABLE.keys()
#	for id in ids:
#		add_child(Gear.create_item(id))
#	count += ids.size()
#	print(count == get_child_count())
