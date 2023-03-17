extends Node2D


var offset := 165

var type := Pistol

func _ready():
	for key in type.RES_TABLE.keys():
		var res := type.RES_TABLE.get(key) as ItemResource
		res.id += offset
		ResourceSaver.save(res)
	print_info()

func print_info():
	print('{')
	for key in type.RES_TABLE.keys():
		var res := type.RES_TABLE.get(key) as ItemResource
		print('	%d: preload(\'%s\'),' % [res.id, res.resource_path])
	print('}')
