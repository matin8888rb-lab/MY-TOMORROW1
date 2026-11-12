extends Node3D

const PlayerController = preload("res://scripts/player.gd")
var player: CharacterBody3D
var status_label: Label
var quest_label: Label
var vc: int = 40
var quest_done: bool = false
var has_job: bool = false
var worked_today: bool = false
var job_label: Label
var hint_label: Label
var needs_label: Label
var hunger: float = 100.0
var energy: float = 100.0
var day_number: int = 1
var minute_of_day: float = 480.0
var needs_tick: float = 0.0
var autosave_tick: float = 0.0
var hint_message_time: float = 0.0
var has_saved_position: bool = false
var saved_position: Vector3 = Vector3(0, 1.1, 12)
const SAVE_PATH := "user://valora_save.json"

func _ready() -> void:
	_load_game()
	_build_world()
	_build_player()
	_build_hud()
	_update_hud()
	_update_sun()

func _process(delta: float) -> void:
	if player == null:
		return
	if hint_message_time > 0.0:
		hint_message_time = maxf(0.0, hint_message_time - delta)
	minute_of_day += delta * 2.0
	if minute_of_day >= 1440.0:
		minute_of_day -= 1440.0
		day_number += 1
		worked_today = false
		_save_game()
	needs_tick += delta
	if needs_tick >= 30.0:
		needs_tick = 0.0
		hunger = maxf(0.0, hunger - 1.0)
		energy = maxf(0.0, energy - (1.5 if hunger <= 0.0 else 0.7))
		_update_hud()
	autosave_tick += delta
	if autosave_tick >= 20.0:
		autosave_tick = 0.0
		_save_game()
	_update_sun()
	player.set("move_speed", maxf(2.5, 5.2 * (0.45 + energy / 180.0)))
	_update_hint()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.79, 0.86)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(120, 120)
	ground.mesh = ground_mesh
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.34, 0.48, 0.34)
	ground.material_override = grass
	ground.position.y = -0.08
	add_child(ground)
	var ground_body := StaticBody3D.new()
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(120, 0.2, 120)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.1
	ground_body.add_child(ground_collision)
	add_child(ground_body)

	_add_box(Vector3(0, 0.01, 0), Vector3(10, 0.12, 100), Color(0.18, 0.19, 0.21), false)
	_add_box(Vector3(0, 0.02, -8), Vector3(100, 0.12, 8), Color(0.22, 0.23, 0.24), false)
	_add_box(Vector3(0, 0.09, 0), Vector3(0.16, 0.02, 100), Color(0.86, 0.78, 0.49), false)

	_add_building("تالار شهر", Vector3(0, 0, -18), Vector3(11, 6, 8), Color(0.72, 0.68, 0.57))
	_add_building("کتابخانه", Vector3(-18, 0, -12), Vector3(9, 4.5, 8), Color(0.63, 0.69, 0.72))
	_add_building("کافه", Vector3(18, 0, -10), Vector3(8, 4, 7), Color(0.62, 0.42, 0.31))
	_add_building("فروشگاه", Vector3(-18, 0, 12), Vector3(9, 4, 8), Color(0.55, 0.61, 0.48))
	_add_building("خانه", Vector3(18, 0, 14), Vector3(9, 5, 9), Color(0.72, 0.53, 0.43))
	_add_building("مرکز کاریابی", Vector3(0, 0, 30), Vector3(10, 4.5, 8), Color(0.55, 0.62, 0.69))

	for x in [-28.0, -12.0, 13.0, 29.0]:
		for z in [-28.0, 4.0, 29.0]:
			_add_tree(Vector3(x, 0, z))

func _add_box(pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
	var holder: Node3D
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		holder = body
	else:
		holder = Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	mesh_instance.material_override = material
	holder.add_child(mesh_instance)
	holder.position = pos
	add_child(holder)

func _add_building(title: String, pos: Vector3, size: Vector3, color: Color) -> void:
	_add_box(pos + Vector3(0, size.y / 2.0, 0), size, color, true)
	_add_box(pos + Vector3(0, size.y + 0.35, 0), Vector3(size.x + 0.8, 0.7, size.z + 0.8), color.darkened(0.25), true)
	var sign := Label3D.new()
	sign.text = title
	sign.font_size = 48
	sign.pixel_size = 0.012
	sign.position = pos + Vector3(0, size.y + 1.5, size.z / 2.0 + 0.25)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign)

func _add_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 2.0
	trunk.mesh = trunk_mesh
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.30, 0.20, 0.13)
	trunk.material_override = bark
	trunk.position = pos + Vector3(0, 1, 0)
	add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.25
	crown_mesh.height = 2.5
	crown.mesh = crown_mesh
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.19, 0.38, 0.22)
	crown.material_override = leaves
	crown.position = pos + Vector3(0, 2.8, 0)
	add_child(crown)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PlayerController)
	player.position = saved_position if has_saved_position else Vector3(0, 1.1, 12)
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var visual := MeshInstance3D.new()
	visual.mesh = capsule
	var suit := StandardMaterial3D.new()
	suit.albedo_color = Color(0.22, 0.45, 0.72)
	visual.material_override = suit
	visual.position.y = 0.9
	player.add_child(visual)

	var collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.42
	capsule_shape.height = 1.8
	collision.shape = capsule_shape
	collision.position.y = 0.9
	player.add_child(collision)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 4.8, 7.5)
	camera.current = true
	player.add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	status_label = Label.new()
	status_label.position = Vector2(24, 18)
	status_label.add_theme_font_size_override("font_size", 25)
	status_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1))
	root.add_child(status_label)

	needs_label = Label.new()
	needs_label.position = Vector2(24, 48)
	needs_label.add_theme_font_size_override("font_size", 18)
	needs_label.add_theme_color_override("font_color", Color(0.83, 0.94, 0.91))
	root.add_child(needs_label)

	job_label = Label.new()
	job_label.position = Vector2(24, 108)
	job_label.add_theme_font_size_override("font_size", 17)
	job_label.add_theme_color_override("font_color", Color(0.77, 0.88, 1.0))
	root.add_child(job_label)

	quest_label = Label.new()
	quest_label.position = Vector2(24, 78)
	quest_label.add_theme_font_size_override("font_size", 18)
	quest_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58))
	root.add_child(quest_label)

	hint_label = Label.new()
	hint_label.anchor_left = 0.5
	hint_label.anchor_right = 0.5
	hint_label.offset_left = -270
	hint_label.offset_right = 270
	hint_label.offset_top = 18
	hint_label.offset_bottom = 52
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(hint_label)

	_make_button(root, "▲", Vector2(100, -172), "move_forward")
	_make_button(root, "▼", Vector2(100, -82), "move_back")
	_make_button(root, "◀", Vector2(8, -82), "move_left")
	_make_button(root, "▶", Vector2(192, -82), "move_right")
	_make_button(root, "پرش", Vector2(-190, -94), "jump")
	_make_button(root, "تعامل", Vector2(-190, -174), "interact")

func _make_button(root: Control, caption: String, offset: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.size = Vector2(78, 70)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_right = offset.x + 78
	button.offset_top = offset.y
	button.offset_bottom = offset.y + 70
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color(0.08, 0.13, 0.18))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.78, 0.88, 0.91, 0.92)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.48, 0.76, 0.72, 0.98)))
	button.button_down.connect(func(): _press_action(action))
	button.button_up.connect(func(): _release_action(action))
	root.add_child(button)

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.42, 0.50, 0.9)
	return style

func _press_action(action: String) -> void:
	if action == "interact":
		_interact()
	else:
		Input.action_press(action)

func _release_action(action: String) -> void:
	if action != "interact":
		Input.action_release(action)

func _nearest_place() -> String:
	var p := player.global_position
	if p.distance_to(Vector3(0, 0, -18)) < 10.0:
		return "town_hall"
	if p.distance_to(Vector3(18, 0, -10)) < 10.0:
		return "cafe"
	if p.distance_to(Vector3(18, 0, 14)) < 10.0:
		return "home"
	if p.distance_to(Vector3(-18, 0, 12)) < 10.0:
		return "shop"
	if p.distance_to(Vector3(-18, 0, -12)) < 10.0:
		return "library"
	if p.distance_to(Vector3(0, 0, 30)) < 10.0:
		return "employment"
	return ""

func _interact() -> void:
	match _nearest_place():
		"employment":
			if not has_job:
				has_job = true
				hint_label.text = "استخدام شدی! شغل تو کمک‌کار فروشگاه است. از فردا شیفت بگیر."
			elif worked_today:
				hint_label.text = "شیفت امروزت را انجام داده‌ای؛ فردا دوباره بیا."
			elif energy < 25.0 or hunger < 20.0:
				hint_label.text = "برای شروع شیفت به انرژی ۲۵٪ و گرسنگی ۲۰٪ نیاز داری."
			else:
				worked_today = true
				vc += 18
				energy = maxf(0.0, energy - 20.0)
				hunger = maxf(0.0, hunger - 12.0)
				minute_of_day = fmod(minute_of_day + 180.0, 1440.0)
				hint_label.text = "شیفت ۳ ساعته تمام شد؛ ۱۸ VC دستمزد گرفتی."
		"town_hall":
			if not quest_done:
				quest_done = true
				vc += 12
				hint_label.text = "مأموریت کامل شد! ۱۲ VC دریافت کردی."
			else:
				hint_label.text = "کار اداری امروزت تمام شده است."
		"cafe":
			if vc >= 5:
				vc -= 5
				hunger = minf(100.0, hunger + 38.0)
				hint_label.text = "یک وعده غذا خوردی؛ ۵ VC پرداخت شد."
			else:
				hint_label.text = "برای خرید غذا به ۵ VC نیاز داری."
		"home":
			energy = 100.0
			hunger = maxf(25.0, hunger)
			day_number += 1
			worked_today = false
			minute_of_day = 480.0
			hint_label.text = "استراحت کردی؛ روز تازه‌ای در والورا آغاز شد."
		"shop":
			if vc >= 4:
				vc -= 4
				hunger = minf(100.0, hunger + 25.0)
				hint_label.text = "خوراکی خریدی؛ ۴ VC پرداخت شد."
			else:
				hint_label.text = "برای خرید خوراکی به ۴ VC نیاز داری."
		"library":
			energy = minf(100.0, energy + 5.0)
			hint_label.text = "کمی مطالعه کردی و ۵ انرژی به دست آوردی."
		_:
			hint_label.text = "به یکی از ساختمان‌ها نزدیک شو و تعامل را بزن."
	hint_message_time = 3.5
	_update_hud()
	_save_game()

func _update_hint() -> void:
	if not is_instance_valid(hint_label) or hint_message_time > 0.0:
		return
	match _nearest_place():
		"town_hall": hint_label.text = "تالار شهر: تعامل برای مأموریت"
		"cafe": hint_label.text = "کافه: غذا بخور (۵ VC)"
		"home": hint_label.text = "خانه: استراحت و شروع روز بعد"
		"shop": hint_label.text = "فروشگاه: خرید خوراکی (۴ VC)"
		"library": hint_label.text = "کتابخانه: مطالعه و بازیابی انرژی"
		"employment": hint_label.text = "مرکز کاریابی: استخدام یا انجام شیفت روزانه"
		_: hint_label.text = "شهر را بگرد و ساختمان‌ها را پیدا کن"

func _update_hud() -> void:
	if not is_instance_valid(status_label):
		return
	var hour := int(minute_of_day / 60.0)
	var minute := int(minute_of_day) % 60
	status_label.text = "VALORA  |  روز %d  |  %02d:%02d  |  %d VC" % [day_number, hour, minute, vc]
	needs_label.text = "گرسنگی: %d%%    انرژی: %d%%" % [int(hunger), int(energy)]
	job_label.text = "شغل: کمک‌کار فروشگاه" if has_job else "شغل: بیکار"
	quest_label.text = "مأموریت: به تالار شهر برو" if not quest_done else "مأموریت اول: تکمیل شد  ✓"

func _update_sun() -> void:
	var light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light == null:
		return
	var angle := minute_of_day / 1440.0 * TAU
	light.rotation_degrees.x = -15.0 - sin(angle - PI / 2.0) * 55.0
	light.light_energy = 0.18 + maxf(0.0, sin(angle - PI / 2.0))

func _save_game() -> void:
	var position_data := [0.0, 1.1, 12.0]
	if is_instance_valid(player):
		position_data = [player.position.x, player.position.y, player.position.z]
	var data := {"version": 3, "vc": vc, "quest_done": quest_done, "hunger": hunger, "energy": energy, "day": day_number, "minute": minute_of_day, "has_job": has_job, "worked_today": worked_today, "player_position": position_data}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	vc = clampi(int(data.get("vc", 40)), 0, 999999)
	quest_done = bool(data.get("quest_done", false))
	has_job = bool(data.get("has_job", false))
	worked_today = bool(data.get("worked_today", false))
	hunger = clampf(float(data.get("hunger", 100.0)), 0.0, 100.0)
	energy = clampf(float(data.get("energy", 100.0)), 0.0, 100.0)
	day_number = maxi(1, int(data.get("day", 1)))
	minute_of_day = clampf(float(data.get("minute", 480.0)), 0.0, 1439.9)
	var pos: Variant = data.get("player_position", [])
	if pos is Array and pos.size() == 3:
		saved_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
		has_saved_position = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_game()
