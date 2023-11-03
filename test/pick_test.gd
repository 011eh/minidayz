extends Node2D


func _ready():
	var inventory_ui := $CanvasLayer/InventoryUI
	inventory_ui.setup($Player)

	for item in ItemCreator.create_all(NumberItem):
		$NumberItem.position.x += 25
		item.position = $NumberItem.position
		add_child(item)

	for item in ItemCreator.create_all(Craft):
		$Craft.position.x += 25
		item.position = $Craft.position
		add_child(item)

	for item in ItemCreator.create_all(Gear):
		$Gear.position.x += 25
		item.position = $Gear.position
		add_child(item)

	for item in ItemCreator.create_all(Knife):
		$Knife.position.x += 25
		item.position = $Knife.position
		add_child(item)

	for item in ItemCreator.create_all(MeleeWeapon):
		$MeleeWeapon.position.x += 25
		item.position = $MeleeWeapon.position
		add_child(item)

	for item in ItemCreator.create_all(Pistol):
		$Pistol.position.x += 25
		item.position = $Pistol.position
		add_child(item)

	for item in ItemCreator.create_all(MainWeapon):
		$MainWeapon.position.x += 25
		item.position = $MainWeapon.position
		add_child(item)

func _draw():
	PlayerStatus.hunger = 40
	PlayerStatus.thirst = 40
	draw_circle($Area1.position, $Area1/CollisionShape2D.shape.radius, Color.html('4ef4441d'))
	draw_circle($Area2.position, $Area2/CollisionShape2D.shape.radius,Color.html('64d8645e'))
	draw_circle($Area3.position, $Area3/CollisionShape2D.shape.radius,Color.html('da484927'))
	draw_circle($Area4.position, $Area4/CollisionShape2D.shape.radius,Color.html('426a2e'))
	draw_circle($Area5.position, $Area5/CollisionShape2D.shape.radius,Color.html('acbfc46a'))
	
	var restore_old_rate := PlayerStatus.health_restore_rate
	$Area1.body_entered.connect(func(body: Node2D) -> void:
		PlayerStatus.to_restore(PlayerStatus.health_restore_rate, 9999)
		print('enter area1')
	)
	$Area1.body_exited.connect(func(body: Node2D) -> void:
		PlayerStatus.restoring = false
		PlayerStatus.restore_timer.stop()
		PlayerStatus.restore_timer.timeout.emit()
		print('exit area1')
	)
	
	$Area2.body_entered.connect(func(body: Node2D) -> void:
		PlayerStatus.to_restore(20, 9999)
		print('enter area2')
	)
	$Area2.body_exited.connect(func(body: Node2D) -> void:
		PlayerStatus.restoring = false
		PlayerStatus.restore_timer.stop()
		PlayerStatus.restore_timer.timeout.emit()
		print('exit area2')
	)
	
	
	$Area3.body_entered.connect(func(body: Node2D) -> void:
		PlayerStatus.is_bleeding = true
		PlayerStatus.bleed_rate = 20
		print('enter area3')
	)
	$Area3.body_exited.connect(func(body: Node2D) -> void:
		PlayerStatus.is_bleeding = false
		print('exit area3')
	)
	
	$Area4.body_entered.connect(func(body: Node2D) -> void:
		PlayerStatus.is_sick = true
		print('enter area4')
	)
	$Area4.body_exited.connect(func(body: Node2D) -> void:
		PlayerStatus.is_sick = false
		print('exit area4')
	)
	
	$Area4.body_entered.connect(func(body: Node2D) -> void:
		PlayerStatus.is_sick = true
		print('enter area4')
	)
	
	var old_rate := PlayerStatus.hunger_decrease_rate
	$Area5.body_entered.connect(func(body: Node2D) -> void:
		PlayerStatus.thirst_decrease_rate = 10
		PlayerStatus.hunger_decrease_rate = 10
		
	)
	$Area5.body_exited.connect(func(body: Node2D) -> void:
		PlayerStatus.hunger_decrease_rate = old_rate
		PlayerStatus.thirst_decrease_rate = old_rate
	)
	
func stack_test():
	var item: Item
	item = ItemCreator.create_item(NumberItem, 0)
	item.number = 60
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)

	item = ItemCreator.create_item(NumberItem, 0)
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)

	item = ItemCreator.create_item(NumberItem, 0)
	item.number = 30
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)

	item = ItemCreator.create_item(Craft, 85)
	$ItemPosition.position.x += 20
	item.position = $ItemPosition.position
	add_child(item)

	item = ItemCreator.create_item(Knife, 11)
	$ItemPosition.position.x += 200
	item.position = $ItemPosition.position
	add_child(item)

	item = ItemCreator.create_item(Gear, 0)
	$ItemPosition.position.x += 200
	item.position = $EquipmentPosition.position
	add_child(item)

	item = ItemCreator.create_item(Gear, 1)
	$EquipmentPosition.position.x += 200
	item.position = $EquipmentPosition.position
	add_child(item)
