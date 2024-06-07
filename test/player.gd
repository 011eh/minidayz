extends CharacterBody2D


const SPEED = 300.0


var target_pos: Vector2


func _ready():
	pass

func _physics_process(delta):
	var direction = Input.get_vector('move_left', 'move_right', 'move_up', 'move_down')
	if direction:
		target_pos = Vector2.ZERO
		velocity = direction * SPEED
	elif target_pos != Vector2.ZERO:
		direction = global_position.direction_to(target_pos)
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	move_and_slide()

func set_target_pos(pos: Vector2) -> void:
	target_pos = pos
