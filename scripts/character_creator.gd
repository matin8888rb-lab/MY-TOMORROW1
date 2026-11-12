extends CanvasLayer

signal profile_confirmed(profile: Dictionary)

var first_name_input: LineEdit
var last_name_input: LineEdit
var skin_option: OptionButton
var hair_option: OptionButton
var style_option: OptionButton
var outfit_option: OptionButton
var message_label: Label
var saved_profile: Dictionary = {}

func _ready() -> void:
	saved_profile = ProfileManager.load_profile()
	_build_interface()
	if not saved_profile.is_empty():
		first_name_input.text = str(saved_profile.get("first_name", ""))
		last_name_input.text = str(saved_profile.get("last_name", ""))
		skin_option.select(int(saved_profile.get("skin_tone", 0)))
		hair_option.select(int(saved_profile.get("hair_color", 0)))
		style_option.select(int(saved_profile.get("hair_style", 0)))
		outfit_option.select(int(saved_profile.get("outfit_color", 0)))

func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.045, 0.06, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300.0
	panel.offset_top = -325.0
	panel.offset_right = 300.0
	panel.offset_bottom = 325.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.13, 0.16, 0.98)
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin_all(20.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	var title := Label.new()
	title.text = "ساخت شخصیت"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 0.91))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "هویت خودت را برای زندگی تازه در لندن انتخاب کن"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.81, 0.81))
	column.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var form_column := VBoxContainer.new()
	form_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_column.add_theme_constant_override("separation", 8)
	scroll.add_child(form_column)

	first_name_input = _add_text_field(form_column, "نام")
	last_name_input = _add_text_field(form_column, "نام خانوادگی")
	skin_option = _add_option(form_column, "رنگ پوست", ["روشن", "گندمی", "سبزه", "تیره"])
	hair_option = _add_option(form_column, "رنگ مو", ["مشکی", "قهوه‌ای", "بلوند", "قرمز تیره"])
	style_option = _add_option(form_column, "مدل مو", ["کوتاه", "معمولی", "بلند"])
	outfit_option = _add_option(form_column, "رنگ لباس", ["آبی", "سبز", "قرمز", "خاکستری"])

	message_label = Label.new()
	message_label.text = ""
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color(1.0, 0.66, 0.54))
	column.add_child(message_label)

	var save_button := Button.new()
	save_button.text = "تأیید و ادامه"
	save_button.custom_minimum_size = Vector2(0, 50)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_confirm_new_profile)
	column.add_child(save_button)

	var continue_button := Button.new()
	continue_button.text = "ادامه با شخصیت ذخیره‌شده"
	continue_button.custom_minimum_size = Vector2(0, 44)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.visible = not saved_profile.is_empty()
	continue_button.pressed.connect(_continue_saved_profile)
	column.add_child(continue_button)

func _add_text_field(parent: VBoxContainer, field_title: String) -> LineEdit:
	var label := Label.new()
	label.text = field_title
	label.add_theme_color_override("font_color", Color(0.87, 0.91, 0.89))
	parent.add_child(label)
	var field := LineEdit.new()
	field.placeholder_text = field_title
	field.custom_minimum_size = Vector2(0, 38)
	parent.add_child(field)
	return field

func _add_option(parent: VBoxContainer, field_title: String, choices: Array) -> OptionButton:
	var label := Label.new()
	label.text = field_title
	label.add_theme_color_override("font_color", Color(0.87, 0.91, 0.89))
	parent.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(0, 38)
	for choice in choices:
		option.add_item(choice)
	parent.add_child(option)
	return option

func _confirm_new_profile() -> void:
	var first_name := first_name_input.text.strip_edges()
	var last_name := last_name_input.text.strip_edges()
	if first_name.is_empty() or last_name.is_empty():
		message_label.text = "نام و نام خانوادگی را وارد کن."
		return
	var profile := {
		"first_name": first_name,
		"last_name": last_name,
		"skin_tone": skin_option.selected,
		"hair_color": hair_option.selected,
		"hair_style": style_option.selected,
		"outfit_color": outfit_option.selected
	}
	if not ProfileManager.save_profile(profile):
		message_label.text = "ذخیره انجام نشد؛ فضای ذخیره‌سازی را بررسی کن."
		return
	profile_confirmed.emit(profile)
	queue_free()

func _continue_saved_profile() -> void:
	if saved_profile.is_empty():
		return
	profile_confirmed.emit(saved_profile)
	queue_free()
