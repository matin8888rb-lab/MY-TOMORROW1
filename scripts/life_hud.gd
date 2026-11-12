extends CanvasLayer
class_name LifeHUD

signal home_button_pressed
signal eat_button_pressed
signal sleep_button_pressed
signal shop_button_pressed
signal work_button_pressed
signal rent_button_pressed
signal transport_button_pressed

var status_label: Label
var home_button: Button
var message_label: Label
var money_label: Label
var economy_label: Label

func _ready() -> void:
	_build_ui()
	LifeSystem.life_changed.connect(update_status)
	EconomySystem.economy_changed.connect(update_economy)
	update_status()
	update_economy()

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
	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 17)
	money_label.add_theme_color_override("font_color", Color(0.93, 0.84, 0.56))
	column.add_child(money_label)
	economy_label = Label.new()
	economy_label.add_theme_font_size_override("font_size", 14)
	economy_label.add_theme_color_override("font_color", Color(0.85, 0.89, 0.85))
	column.add_child(economy_label)

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

	var economy_actions := HBoxContainer.new()
	column.add_child(economy_actions)
	var shop_button := Button.new()
	shop_button.text = "خرید غذا £8"
	shop_button.custom_minimum_size = Vector2(130.0, 38.0)
	shop_button.pressed.connect(func(): shop_button_pressed.emit())
	economy_actions.add_child(shop_button)
	var work_button := Button.new()
	work_button.text = "رفتن به کار"
	work_button.custom_minimum_size = Vector2(120.0, 38.0)
	work_button.pressed.connect(func(): work_button_pressed.emit())
	economy_actions.add_child(work_button)
	var transport_button := Button.new()
	transport_button.text = "اتوبوس £3"
	transport_button.custom_minimum_size = Vector2(130.0, 38.0)
	transport_button.pressed.connect(func(): transport_button_pressed.emit())
	column.add_child(transport_button)

	var rent_button := Button.new()
	rent_button.text = "پرداخت اجاره"
	rent_button.custom_minimum_size = Vector2(130.0, 38.0)
	rent_button.pressed.connect(func(): rent_button_pressed.emit())
	column.add_child(rent_button)

	message_label = Label.new()
	message_label.position = Vector2(22.0, 258.0)
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.62))
	add_child(message_label)

func set_home_state(inside: bool) -> void:
	home_button.text = "خروج از خانه" if inside else "ورود به خانه"

func show_message(value: String) -> void:
	message_label.text = value

func update_economy() -> void:
	if not is_instance_valid(money_label):
		return
	money_label.text = "کیف پول: %s" % EconomySystem.get_money_text()
	economy_label.text = "غذا: %d وعده  |  شیفت‌ها: %d" % [EconomySystem.food_stock, EconomySystem.shifts_completed]

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
