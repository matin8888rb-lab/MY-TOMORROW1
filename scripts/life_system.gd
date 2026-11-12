extends Node

signal life_changed

const SAVE_PATH := "user://life_state.cfg"
const STARTING_MINUTES := 8 * 60

var day_number: int = 1
var minutes_of_day: int = STARTING_MINUTES
var hunger: float = 88.0
var energy: float = 92.0
var rent_due_in_days: int = 7
var _minute_accumulator: float = 0.0
var _save_accumulator: float = 0.0

func _ready() -> void:
	_load_state()
	life_changed.emit()

func _process(delta: float) -> void:
	_minute_accumulator += delta
	_save_accumulator += delta
	while _minute_accumulator >= 1.0:
		_minute_accumulator -= 1.0
		_advance_minute()
	if _save_accumulator >= 8.0:
		_save_accumulator = 0.0
		save_state()

func _advance_minute() -> void:
	minutes_of_day += 1
	if minutes_of_day >= 1440:
		minutes_of_day = 0
		day_number += 1
		rent_due_in_days = maxi(0, rent_due_in_days - 1)
	hunger = maxf(0.0, hunger - 0.025)
	energy = maxf(0.0, energy - 0.018)
	life_changed.emit()

func eat_meal() -> void:
	hunger = minf(100.0, hunger + 38.0)
	energy = minf(100.0, energy + 3.0)
	save_state()
	life_changed.emit()

func sleep_for_night() -> void:
	minutes_of_day = (minutes_of_day + 480) % 1440
	if minutes_of_day < STARTING_MINUTES:
		day_number += 1
		rent_due_in_days = maxi(0, rent_due_in_days - 1)
	energy = 100.0
	hunger = maxf(0.0, hunger - 12.0)
	save_state()
	life_changed.emit()

func get_clock_text() -> String:
	return "%02d:%02d" % [minutes_of_day / 60, minutes_of_day % 60]

func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("life", "day_number", day_number)
	config.set_value("life", "minutes_of_day", minutes_of_day)
	config.set_value("life", "hunger", hunger)
	config.set_value("life", "energy", energy)
	config.set_value("life", "rent_due_in_days", rent_due_in_days)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	day_number = maxi(1, int(config.get_value("life", "day_number", 1)))
	minutes_of_day = clampi(int(config.get_value("life", "minutes_of_day", STARTING_MINUTES)), 0, 1439)
	hunger = clampf(float(config.get_value("life", "hunger", 88.0)), 0.0, 100.0)
	energy = clampf(float(config.get_value("life", "energy", 92.0)), 0.0, 100.0)
	rent_due_in_days = clampi(int(config.get_value("life", "rent_due_in_days", 7)), 0, 7)
