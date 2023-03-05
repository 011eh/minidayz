extends Button


signal test

@export
var n := 1
func _ready():
	var f = await f()
	print(f)

func f():
	await button_up
	print(await button_up)
	return 3
