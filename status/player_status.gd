extends CharacterStatus


signal status_changed
signal bleeding_state_changed
signal sick_state_changed
signal restore_state_changed


enum {NOT_RESTORING, RESTORING, FAST_RESTORING}


const STATUS_UPDATE_INTERVAL = 1
const BAD_STATUS_HEALTH_DECREASE := 0.3
const MAX_STATUS_VALUE = 100.0
const NORMAL_RESTORE_RATE = 0.46


var restoring := false
var is_sick := false:
	set(value):
		is_sick = value
		sick_state_changed.emit(value)
var is_bleeding := false:
	set(value):
		is_bleeding = value
		bleeding_state_changed.emit(value)

var hunger_decrease_rate := 0.24
var thirst_decrease_rate := 0.24
var health_restore_rate := NORMAL_RESTORE_RATE
var bleed_rate := 0.82
var hunger := MAX_STATUS_VALUE:
	set(value):
		hunger = clamp(value, 0, MAX_STATUS_VALUE)

var thirst := MAX_STATUS_VALUE:
	set(value):
		thirst = clamp(value, 0, MAX_STATUS_VALUE)

var temperature := MAX_STATUS_VALUE:
	set(value):
		temperature = clamp(value, 0, MAX_STATUS_VALUE)

var restore_timer := Timer.new()


func _ready():
	super._ready()
	speed = 130
	restore_timer.one_shot = true
	restore_timer.timeout.connect(func() -> void:
		restoring = false
		health_restore_rate = NORMAL_RESTORE_RATE
	)
	add_child(restore_timer)
	
	var timer = Timer.new()
	timer.wait_time = STATUS_UPDATE_INTERVAL
	timer.timeout.connect(func() -> void:
		update_status()
		status_changed.emit()
	)
	add_child(timer)
	timer.start()

func update_status() -> void:
	hunger -= hunger_decrease_rate * STATUS_UPDATE_INTERVAL
	thirst -= thirst_decrease_rate * STATUS_UPDATE_INTERVAL
	var decrease := BAD_STATUS_HEALTH_DECREASE * (int(hunger == 0) + int(thirst == 0) + int(temperature == 0)) \
		+ bleed_rate * int(is_bleeding)
	health -= decrease * STATUS_UPDATE_INTERVAL
	try_restore()
	if is_sick and is_good_status():
		is_sick = false

func try_restore() -> void:
	if restoring or is_health():
		health += health_restore_rate * STATUS_UPDATE_INTERVAL
		restore_state_changed.emit(RESTORING if health_restore_rate <= NORMAL_RESTORE_RATE else FAST_RESTORING)
	else:
		restore_state_changed.emit(NOT_RESTORING)

func to_restore(rate: float, time: float) -> void:
	if rate > health_restore_rate:
		health_restore_rate = rate
	if not restore_timer.is_stopped():
		restore_timer.stop()
	restoring = true
	restore_timer.start(time)

func is_health() -> bool:
	return hunger >= 50 and thirst >= 50 and temperature >= 50 and not (is_bleeding or is_sick)

func is_good_status() -> bool:
	return hunger >= 75 and thirst >= 75 and temperature >= 75
