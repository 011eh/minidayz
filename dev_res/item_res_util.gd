extends Node2D

enum ItemType { SLOT_ITEM, STATE_ITEM, CRAFT}


const res_dict := {
	ItemType.SLOT_ITEM: 'res://item/res/slot_item/',
	ItemType.STATE_ITEM: 'res://item/res/state_item/',
	ItemType.CRAFT: 'res://item/res/craft/',
}
const file_dict := {
	ItemType.SLOT_ITEM: 'res://dev_res/data/背包物品.CSV',
	ItemType.STATE_ITEM: 'res://dev_res/data/状态物品.CSV',
	ItemType.CRAFT: 'res://dev_res/data/工具.CSV',
}


func _ready():
#	print_res_dictionary(ItemType.SLOT_ITEM)
#	print_res_dictionary(ItemType.STATE_ITEM)
#	print_res_dictionary(ItemType.CRAFT)
	create_res_file_by_csv(ItemType.SLOT_ITEM)

func create_res_file_by_csv(item_type: ItemType):
	var file := FileAccess.open(file_dict.get(item_type), FileAccess.READ)
	var item := SlotItemResource.new()
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
			var path := '%s%s.tres' % [res_dict.get(item_type) ,file_name]
			ResourceSaver.save(item, path)

func print_res_dictionary(type: ItemType):
	var dir := res_dict.get(type) as String
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
