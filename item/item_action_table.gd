extends Node

class_name ItemActionTable


class ItemAction:
	
	
	var name: StringName
	var action: Callable


	func _init(name: StringName,action: Callable):
		self.name = name
		self.action = action

class CraftingRecipe:
	
	
	class Component:
		
		
		var item_id: int
		var quantitiy: int
		var consumed: bool
		
		
		func _init(item_id: int, quantitiy: int, consumed: bool):
			self.item_id = item_id
			self. quantitiy = quantitiy
			self.consumed = consumed
	
	
	var components: Array[Component]
	var result: int
	
	
	func add_component(item_id: int, quantitiy: int = 1, consumed: bool = true) -> CraftingRecipe:
		components.append(Component.new(item_id, quantitiy, consumed))
		return self
	
	func set_result(item_id: int):
		result = item_id


const EQUIPMENT_TYPE = PlayerInventory.EquipmentType


var crafting_recipes: Array[CraftingRecipe]
var equipment_slots: Array[Item]
var show_spin_box: Callable
var update_inventory_ui: Callable
var put_to_inventory: Callable

var weapon_reload = func(weapon: RangedWeapon,ammo: NumberItem) -> void:
	weapon.reload.call(ammo)
	update_inventory_ui.call()

var eject_ammo_to_inventory = func(weapon: RangedWeapon):
	var ammo := weapon.eject()
	put_to_inventory.call(ammo)


func _init():
	crafting_recipes = [
		CraftingRecipe.new().add_component(17).add_component(19).set_result(143),
		CraftingRecipe.new().add_component(14).add_component(143).set_result(146),
		CraftingRecipe.new().add_component(15).add_component(22).set_result(16),
		CraftingRecipe.new().add_component(15).add_component(18).set_result(16),
		CraftingRecipe.new().add_component(15).add_component(14, 3).set_result(16),
	]

func setup(inventory: PlayerInventory, show_spin_box: Callable) -> void:
	equipment_slots = inventory.equipment_slots
	put_to_inventory = inventory.put_to_inventory
	update_inventory_ui = inventory.update_inventory_ui
	self.show_spin_box = show_spin_box

func create_options(item: Item) -> Array[ItemAction]:
	var options: Array[ItemAction]
	if item is NumberItem:
		if item.resource.stackable and item.number > 1:
			options.append(ItemAction.new('Split', show_spin_box.bind(item)))

		if item.get_item_id() in range(12):
			options.append_array(create_reload_options(item))
		return options
	if item is RangedWeapon and item.get_round_count() > 0:
		options.append(ItemAction.new('Eject', eject_ammo_to_inventory.bind(item)))
	return options

func create_reload_options(ammo: NumberItem) -> Array[ItemAction]:
	var options: Array[ItemAction]
	var weapon := equipment_slots[EQUIPMENT_TYPE.MAIN_WEAPON] as RangedWeapon
	var ammo_id := ammo.get_item_id()
	if is_instance_valid(weapon) and ammo_id in weapon.resource.ammo_type:
		options.append(ItemAction.new('Load into main', weapon_reload.bind(weapon, ammo)))
	
	weapon = equipment_slots[EQUIPMENT_TYPE.PISTOL]
	if is_instance_valid(weapon) and ammo_id in weapon.resource.ammo_type:
		options.append(ItemAction.new('Load into sidearm', weapon_reload.bind(weapon, ammo)))
	return options
