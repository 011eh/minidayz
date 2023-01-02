extends Node2D


const SLOT_ITEM_DIR = 'res://item/res/slot_item/'
const STATE_ITEM_DIR = 'res://item/res/state_item/'
const CRAFT_DIR = 'res://item/res/craft/'

enum ItemType { SLOT_ITEM, STATE_ITEM, CRAFT}

func _ready():
	print_res_dictionary(ItemType.SLOT_ITEM)
	print_res_dictionary(ItemType.STATE_ITEM)
	print_res_dictionary(ItemType.CRAFT)

func create_res_file_by_csv(item_type: ItemType):
	var file: FileAccess
	var item: ItemResource

	match item_type:
		ItemType.SLOT_ITEM:
			file = FileAccess.open('res://dev_res/背包物品.csv',FileAccess.READ)
			item = SlotItemResource.new()

		ItemType.STATE_ITEM:
			file = FileAccess.open('res://dev_res/状态物品.csv',FileAccess.READ)
			item = StateItemResource.new()

		ItemType.CRAFT:
			file = FileAccess.open('res://dev_res/工具.csv',FileAccess.READ)
			item = CraftResource.new()

	var properties := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values[0] != "":
			for i in range(properties.size()):
				var value = values[i]
				
				# 加载 Texture
				if i == 2:
					value = load(value)
				item.set(properties[i], value)
			
			var file_name := item.item_name.to_lower().replace(' ','_')
			if item is SlotItemResource and not item is StateItemResource:
				var path := '%s%s.tres' % [SLOT_ITEM_DIR ,file_name]
				ResourceSaver.save(item, path)
			
			if item is StateItemResource:
				var path := '%s%s.tres' % [STATE_ITEM_DIR ,file_name]
				ResourceSaver.save(item, path)
			
			if item is CraftResource:
				var path := '%s%s.tres' % [CRAFT_DIR ,file_name]
				ResourceSaver.save(item, path)

func print_res_dictionary(type: ItemType):
	var dir: String
	match type:
		ItemType.SLOT_ITEM:
			dir = SLOT_ITEM_DIR
			
		ItemType.STATE_ITEM:
			dir = STATE_ITEM_DIR
			
		ItemType.CRAFT:
			dir = CRAFT_DIR

	var file_names := DirAccess.get_files_at(dir)
	if file_names.size() > 0:
		var dict := {}
		for name in file_names:
			var res := load(dir + name)
			dict[res.id] = res.resource_path
		var keys := dict.keys()
		keys.sort()
		
		print('{')
		for key in keys:
			print('%d: preload(\'%s\'),' % [key, dict[key]])
		print('}')
		print()
