extends Area2D


var interactable_list: Array[InteractionArea]
@onready
var timer := $Timer
@onready
var interaction_area := $InteractionArea


func _ready():
	area_entered.connect(func(area):
		interactable_list.append(area)
	)
	area_exited.connect(func(area):
		interactable_list.erase(area)
	)
	timer.timeout.connect(func():
		interactable_list.sort_custom(func(a1, a2):
			return global_position.distance_to(a1.global_position) < global_position.distance_to(a2.global_position)
		)
	)
	timer.start()
	
	interaction_area.area_entered.connect(func(area):
		if owner.target_pos != Vector2.ZERO:
			owner.target_pos = Vector2.ZERO
			var input := InputEventAction.new()
			input.action = 'interact'
			input.pressed = true
			Input.parse_input_event(input)
	)

func _unhandled_input(event):
	if event.is_action('interact'):
		var areas := interaction_area.get_overlapping_areas() as Array[Area2D]
		if not areas.is_empty():
			areas.front().interaction_inputted.emit()
			return
		
		if not interactable_list.is_empty():
			owner.target_pos = interactable_list.front().global_position
