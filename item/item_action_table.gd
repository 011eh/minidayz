extends Node


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
	var result: ItemResource
	var is_number_item: bool
	
	
	func add_component(item_id: int, quantitiy: int = 1, consumed: bool = true) -> CraftingRecipe:
		components.append(Component.new(item_id, quantitiy, consumed))
		return self
	
	func get_component(item_id: int) -> Component:
		return components.filter(func(c: Component) -> bool: return c.item_id == item_id).front()
	
	func set_result(res: ItemResource, is_number_item: bool = true):
		result = res
		self.is_number_item = is_number_item
		return self
	
	func is_components(item: Item) -> bool:
		return components.any(func(component: Component) -> bool: return item.get_item_id() == component.item_id)
	
	func can_craft(item1: Item, item2: Item) -> bool:
		if is_components(item1) and is_components(item2):
			var c1 := get_component(item1.get_item_id())
			var c2 := get_component(item2.get_item_id())
			return (not (c1.consumed and item1 is NumberItem) or item1.number >= c1.quantitiy) \
				and (not (c2.consumed and item2 is NumberItem) or item2.number >= c2.quantitiy)
		return false


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
		CraftingRecipe.new().add_component(17).add_component(19)
		.set_result(Gear.RES_TABLE.get(143)),
		CraftingRecipe.new().add_component(14, 3).add_component(143, 1)
		.set_result(Gear.RES_TABLE.get(146)),
		CraftingRecipe.new().add_component(15).add_component(22)
		.set_result(NumberItem.RES_TABLE.get(16)),
		CraftingRecipe.new().add_component(15).add_component(18)
		.set_result(NumberItem.RES_TABLE.get(16)),
		CraftingRecipe.new().add_component(15).add_component(14, 3)
		.set_result(NumberItem.RES_TABLE.get(16)),
		CraftingRecipe.new().add_component(14).add_component(162, 1, false)
		.set_result(NumberItem.RES_TABLE.get(11)),
		CraftingRecipe.new().add_component(14).add_component(163, 1, false)
		.set_result(NumberItem.RES_TABLE.get(11)),
		CraftingRecipe.new().add_component(14).add_component(164, 1, false)
		.set_result(NumberItem.RES_TABLE.get(11)),
		CraftingRecipe.new().add_component(13).add_component(17)
		.set_result(MainWeapon.RES_TABLE.get(165)),
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
		if item.get_resource() is StatusItemResource:
			options.append(ItemAction.new('Consume', func() -> void:
				PlayerStatus.health += item.get_resource().health
				PlayerStatus.hunger += item.get_resource().hunger
				PlayerStatus.thirst += item.get_resource().drink
				PlayerStatus.temperature += item.get_resource().heat
				if item.get_resource().stackable:
					item.number -= 1
				else:
					item.queue()
				update_inventory_ui.call()
			))
	if item is RangedWeapon and item.get_round_count() > 0:
		options.append(ItemAction.new('Eject', eject_ammo_to_inventory.bind(item)))
	return options

func create_reload_options(ammo: NumberItem) -> Array[ItemAction]:
	var options: Array[ItemAction]
	var weapon := equipment_slots[PlayerInventory.EquipmentType.MAIN_WEAPON]
	var ammo_id := ammo.get_item_id()
	if is_instance_valid(weapon) and ammo_id in weapon.resource.ammo_type:
		options.append(ItemAction.new('Load into main', weapon_reload.bind(weapon, ammo)))

	weapon = equipment_slots[PlayerInventory.EquipmentType.PISTOL]
	if is_instance_valid(weapon) and ammo_id in weapon.resource.ammo_type:
		options.append(ItemAction.new('Load into sidearm', weapon_reload.bind(weapon, ammo)))
	return options

func get_recipes(item1: Item, item2: Item) -> Array[CraftingRecipe]:
	return crafting_recipes.filter(func(c: CraftingRecipe) -> bool: return c.can_craft(item1, item2))

func create_crafting_options(intance1_id: int, intance2_id: int) -> Array[ItemAction]:
	var options: Array[ItemAction]
	var item1 := instance_from_id(intance1_id)
	var item2 := instance_from_id(intance2_id)
	for recipe in get_recipes(item1, item2):
		options.append(ItemAction.new('Craft %s' % recipe.result.item_name, func() -> void:
			var c1 := recipe.get_component(item1.get_item_id())
			var c2 := recipe.get_component(item2.get_item_id())
			if c1.consumed:
				if item1 is NumberItem:
					item1.number -= c1.quantitiy
				else:
					item1.queue_free()
			if c2.consumed:
				if item2 is NumberItem:
					item2.number -= c2.quantitiy
				else:
					item2.queue_free()
			var item := ItemCreator.create_item_from_id(recipe.result.id)
			item.global_position = get_tree().root.get_node('World/Player').global_position
			get_tree().root.get_node('World').add_child.call_deferred(item)
			update_inventory_ui.call()
		))
	return options
