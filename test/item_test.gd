extends Node2D


@export_dir
var dir: String

func _ready():
	var count := 0
	var ids: PackedInt32Array

	ids = SlotItem.RES_TABLE.keys()
	for id in ids:
		add_child(SlotItem.create_item(id))
	count += ids.size()
	print(count == get_child_count())
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
