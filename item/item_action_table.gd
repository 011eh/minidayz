extends Node


class ItemAction:
	
	var name: StringName
	var action: Callable
	
	
	func _init(name: StringName,action: Callable):
		self.name = name
		self.action = action


var equipment_slots: Array[Item]
var show_spin_box: Callable


func setup(inventory, show_spin_box: Callable) -> void:
	equipment_slots = inventory.equipment_slots
	self.show_spin_box = show_spin_box

func create_options(item: Item) -> Array[ItemAction]:
	var options: Array[ItemAction]
	if item is NumberItem:
		options.append(ItemAction.new('split', show_spin_box))
	return options
