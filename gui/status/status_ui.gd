extends Control


const SICK_ICON_OFFSET = 15
const NORMAL_RESTORE_ICON_OFFSET = 73
const FAST_RESTORE_ICON_OFFSET = 90


var status: PlayerStatus
var bleeding_tween: Tween
var sick_tween: Tween


func _ready():
	%BleedingIcon.hide()
	%SickIcon.hide()
	bleeding_tween = %HealthPanel.create_tween()
	bleeding_tween.tween_callback(%BleedingIcon.show).set_delay(1)
	bleeding_tween.tween_callback(%BleedingIcon.hide).set_delay(1)
	bleeding_tween.set_loops()
	bleeding_tween.stop()
	
	sick_tween = %HealthPanel.create_tween()
	sick_tween.tween_callback(func() -> void: %SickIcon.texture.region.position.x = 108).set_delay(1)
	sick_tween.tween_callback(func() -> void: %SickIcon.texture.region.position.x = 123).set_delay(1)
	sick_tween.set_loops()
	sick_tween.stop()
	
	setup(PlayerStatus)

func setup(status: PlayerStatus):
	self.status = status
	status.status_changed.connect(update_status_ui)
	status.bleeding_state_changed.connect(func(is_bleeding: bool) -> void:
		if is_bleeding:
			bleeding_tween.play()
		else:
			%BleedingIcon.hide()
			bleeding_tween.stop()
	)
	status.sick_state_changed.connect(func(is_sick: bool) -> void:
		if is_sick:
			%SickIcon.show()
			sick_tween.play()
		else:
			%SickIcon.hide()
			sick_tween.stop()
	)
	status.restore_state_changed.connect(func(state) -> void:
		match state:
			PlayerStatus.NOT_RESTORING:
				%RestoreIcon.hide()
			PlayerStatus.RESTORING:
				%RestoreIcon.show()
				%RestoreIcon.texture.region.position.x = NORMAL_RESTORE_ICON_OFFSET
			PlayerStatus.FAST_RESTORING:
				%RestoreIcon.show()
				%RestoreIcon.texture.region.position.x = FAST_RESTORE_ICON_OFFSET
	)

func update_status_ui() -> void:
	%HealthPanel.set_value(status.health)
	%ThirstPanel.set_value(status.thirst)
	%HungerPanel.set_value(status.hunger)
	%TemperaturePanel.set_value(status.temperature)
#	if status.is_bleeding and not bleeding_tween.is_running():
#		bleeding_tween.play()
#	else:
#		sick_tween.stop()
#
#
#	if status.is_sick and not sick_tween.is_running():
#		print('sick')
#		sick_tween.play()
#	elif sick_tween.is_running():
#		sick_tween.stop()
