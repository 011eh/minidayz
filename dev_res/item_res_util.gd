extends Node2D


enum ItemType {
	SLOT_ITEM,
	STATE_ITEM,
	CRAFT,
	MELEE_WEAPON,
	RANGED_WEAPON,
	GEAR
}


var dict := {
	ItemType.SLOT_ITEM: {
		'csv_dir': 'res://dev_res/data/背包物品.CSV',
		'res_dir': 'res://item/res/slot_item/',
		'resource_class': NumberItem.new()
	},
	ItemType.STATE_ITEM: {
		'csv_dir': 'res://dev_res/data/状态物品.CSV',
		'res_dir': 'res://item/res/state_item/',
		'resource_class': StateItemResource.new()
	},
	ItemType.CRAFT: {
		'csv_dir': 'res://dev_res/data/工具.CSV',
		'res_dir': 'res://item/res/craft/',
		'resource_class': DurabilityItemResource.new()
	},
	ItemType.MELEE_WEAPON: {
		'csv_dir': 'res://dev_res/data/近战武器.CSV',
		'res_dir': 'res://item/res/melee_weapon/',
		'resource_class': MeleeWeaponResource.new()
	},
	ItemType.RANGED_WEAPON: {
		'csv_dir': 'res://dev_res/data/远程武器.CSV',
		'res_dir': 'res://item/res/ranged_weapon/',
		'resource_class': RangedWeaponResource.new()
	},
	ItemType.GEAR: {
		'csv_dir': 'res://dev_res/data/穿戴物品.CSV',
		'res_dir': 'res://item/res/gear/',
		'resource_class': GearResource.new()
	}
}


func _ready():
	var container1 := $Control/ResGenerate
	var container2 := $Control/ResFileInfoPrinter
	for i in range(container1.get_child_count()):
		(container1.get_child(i) as Button).pressed.connect(create_res_file_by_csv.bind(i))
	for i in range(container2.get_child_count()):
		(container2.get_child(i) as Button).pressed.connect(print_res_dictionary.bind(i))

func create_res_file_by_csv(item_type: ItemType):
	print('Item Type: %s' % item_type)
	var item_res_info := dict.get(item_type) as Dictionary
	var file_path := dict.get(item_type).get('csv_dir') as String
	var file := FileAccess.open(item_res_info.get('csv_dir'), FileAccess.READ)
	assert(file != null,'%s打开失败' % file_path)

	var res := item_res_info.get('resource_class') as ItemResource
	var properties := file.get_csv_line()
	print(properties)
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values[0] != "":
			var size := properties.size()
			for i in range(size):
				var value = values[i]

				# 加载 Texture
				if properties[i] == 'texture':
					value = load(value)

				# 远程武器弹药类型
				if properties[i] == 'ammo_type':
					value = JSON.parse_string(value) as PackedInt32Array
				res.set(properties[i], value)

			var file_name := res.item_name.to_lower().replace(' ','_') as String
			var path := '%s%s.tres' % [item_res_info.get('res_dir'), file_name]
			if FileAccess.file_exists(path):
				var res_in_disk := ResourceLoader.load(path) as ItemResource
				for i in range(size):
					res_in_disk.set(properties[i],res.get(properties[i]))
				res = res_in_disk
			print(path)
			ResourceSaver.save(res, path)
	print('创建资源文件完成')

func print_res_dictionary(type: ItemType):
	var dir := dict.get(type).get('res_dir') as String
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
			print('\t%d: preload(\'%s\'),' % [key, dict[key]])
		print('}')
