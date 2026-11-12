extends CanvasLayer
class_name LifeHUD

signal home_button_pressed
signal eat_button_pressed
signal sleep_button_pressed

var status_label: Label
var home_button: Button
var message_label: Label

func _ready() -> void:
	_build_ui()
	LifeSystem.life_changed.connect(update_status)
	update_status()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(22.0, 116.0)
	panel.custom_minimum_size = Vector2(300.0, 132.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.09, 0.86)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.88))
	column.add_child(status_label)

	home_button = Button.new()
	home_button.text = "ورود به خانه"
	home_button.custom_minimum_size = Vector2(210.0, 38.0)
	home_button.pressed.connect(func(): home_button_pressed.emit())
	column.add_child(home_button)

	var actions := HBoxContainer.new()
	column.add_child(actions)
	var eat_button := Button.new()
	eat_button.text = "غذا خوردن"
	eat_button.custom_minimum_size = Vector2(130.0, 38.0)
	eat_button.pressed.connect(func(): eat_button_pressed.emit())
	actions.add_child(eat_button)
	var sleep_button := Button.new()
	sleep_button.text = "خوابیدن"
	sleep_button.custom_minimum_size = Vector2(120.0, 38.0)
	sleep_button.pressed.connect(func(): sleep_button_pressed.emit())
	actions.add_child(sleep_button)

	message_label = Label.new()
	message_label.position = Vector2(22.0, 258.0)
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.62))
	add_child(message_label)

func set_home_state(inside: bool) -> void:
	home_button.text = "خروج از خانه" if inside else "ورود به خانه"

func show_message(value: String) -> void:
	message_label.text = value

func update_status() -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = "روز %d  |  %s\nگرسنگی: %d%%\nانرژی: %d%%\nاجاره: %d روز دیگر" % [
		LifeSystem.day_number,
		LifeSystem.get_clock_text(),
		roundi(LifeSystem.hunger),
		roundi(LifeSystem.energy),
		LifeSystem.rent_due_in_days
	]
