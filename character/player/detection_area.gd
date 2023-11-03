extends Area2D


var detectable_list: Array[InteractionArea]
@onready
var timer := $Timer
@onready
var interaction_area := $InteractionArea
var inventory: PlayerInventory

func _ready():
	area_entered.connect(func(area):
		detectable_list.append(area)
	)
	area_exited.connect(func(area):
		detectable_list.erase(area)
	)
	timer.timeout.connect(func():
		detectable_list.sort_custom(func(a1, a2):
			return global_position.distance_to(a1.global_position) < global_position.distance_to(a2.global_position)
		)
	)
	timer.start()
	
	interaction_area.area_entered.connect(func(area):
		if owner.target_position != Vector2.ZERO:
			owner.target_position = Vector2.ZERO
			if area.owner_type == InteractionArea.OwnerType.ITEM:
				inventory.put_to_inventory(area.owner)
				return 
			area.interaction_inputted.emit()
	)

func get_interactable_list() -> Array[Area2D]:
	return interaction_area.get_overlapping_areas()

func _unhandled_input(event):
	if event.is_action('interact') and event.pressed == true:
		var areas := get_interactable_list()
		if not areas.is_empty():
			var interactable := areas.front() as InteractionArea
			if interactable.owner_type == InteractionArea.OwnerType.ITEM:
				inventory.put_to_inventory(interactable.owner)
				return
			interactable.interaction_inputted.emit()
			return
		
		if not detectable_list.is_empty():
			owner.target_position = detectable_list.front().global_position
