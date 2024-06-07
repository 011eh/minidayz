extends HSplitContainer


@export
var gui_texture: Texture2D
@export
var frame_size: Vector2i
@export
var frame_offset: int
@export
var item_script: GDScript
@export
var properties: PackedStringArray
var item_info_dict := {}

@onready
var item_list := $ItemList as ItemList
@onready
var label := $RichTextLabel as RichTextLabel

func _ready():
	var h_frames := gui_texture.get_width() / frame_size.x
	var table := item_script.RES_TABLE as Dictionary
	var keys := table.keys()
	for i in range(keys.size()):
		var id := keys[i] as int
		var texture := AtlasTexture.new()
		texture.atlas = gui_texture
		var offset := id + frame_offset
		texture.region = Rect2(
			offset % h_frames * frame_size.x,
			offset / h_frames * frame_size.y,
			frame_size.x,
			frame_size.y
			)
		item_list.add_icon_item(texture)
		
		var item_info := String()
		var res := table[id] as ItemResource
		for property in properties:
			var value = res.get(property)
			if value != null:
				if property == 'texture':
					value = value.resource_path
				property = property.to_pascal_case()
				item_info += '%s: %s\n' % [property, value]
		item_info_dict[i] = item_info
	
	item_list.item_selected.connect(show_item_info)

func show_item_info(index :int) -> void:
	label.text = item_info_dict[index]

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
