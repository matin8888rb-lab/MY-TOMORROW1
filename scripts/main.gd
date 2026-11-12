extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const CharacterCreatorScript = preload("res://scripts/character_creator.gd")
const HomeWorldScript = preload("res://scripts/home_world.gd")
const LifeHUDScript = preload("res://scripts/life_hud.gd")
const CityLifeScript = preload("res://scripts/city_life.gd")

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var sun_light: DirectionalLight3D
var joystick: Control
var hud_label: Label
var hint_label: Label
var time_label: Label
var home_world: HomeWorld
var life_hud: LifeHUD
var city_life: CityLifeSystem
var look_touch_id: int = -1
var look_last_position: Vector2 = Vector2.ZERO
var camera_pitch: float = -0.16
var character_creator: CanvasLayer
var player_display_name: String = "بازیکن"

func _ready() -> void:
	_setup_environment()
	_build_city_block()
	_create_player()
	_create_city_life()
	_create_camera()
	_create_hud()
	_create_home_and_life_ui()
	_create_input_actions()
	_open_character_creator()

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(hud_label):
		hud_label.text = "%s  •  لندن ۲۰۱۸     |     موقعیت: %.0f ، %.0f" % [player_display_name, player.global_position.x, player.global_position.z]
	if is_instance_valid(time_label):
		time_label.text = "روز %d  |  %s" % [LifeSystem.day_number, LifeSystem.get_clock_text()]
	_update_daylight()

func _setup_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.20, 0.36, 0.48)
	sky_material.sky_horizon_color = Color(0.72, 0.78, 0.76)
	sky_material.ground_bottom_color = Color(0.16, 0.19, 0.18)
	sky_material.ground_horizon_color = Color(0.55, 0.60, 0.57)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.68, 0.74, 0.78)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun_light.light_energy = 1.15
	sun_light.shadow_enabled = true
	add_child(sun_light)

func _build_city_block() -> void:
	_add_box("Ground", Vector3(0, -0.55, 0), Vector3(100, 1, 100), Color(0.29, 0.34, 0.32))
	_add_box("Road", Vector3(0, 0.015, 0), Vector3(7.0, 0.08, 76.0), Color(0.105, 0.12, 0.13))
	_add_box("Left pavement", Vector3(-4.45, 0.08, 0), Vector3(1.9, 0.22, 76.0), Color(0.48, 0.49, 0.45))
	_add_box("Right pavement", Vector3(4.45, 0.08, 0), Vector3(1.9, 0.22, 76.0), Color(0.48, 0.49, 0.45))
	_add_box("Road marking left", Vector3(-3.2, 0.07, 0), Vector3(0.10, 0.025, 76.0), Color(0.86, 0.82, 0.65), false)
	_add_box("Road marking right", Vector3(3.2, 0.07, 0), Vector3(0.10, 0.025, 76.0), Color(0.86, 0.82, 0.65), false)

	for index in range(6):
		var z := -27.0 + float(index) * 10.8
		_create_building(-10.2, z, index)
		_create_building(10.2, z, index + 2)
		_create_street_lamp(-4.65, z + 4.5)
		_create_street_lamp(4.65, z - 1.0)

	for index in range(5):
		_create_tree(Vector3(6.7 + float(index % 2) * 1.4, 0.0, -24.0 + float(index) * 10.0))

	_add_box("Square sign board", Vector3(0, 3.2, -34.0), Vector3(5.4, 1.2, 0.18), Color(0.12, 0.22, 0.24), false)
	_add_box("Bus stop post", Vector3(5.1, 1.35, 13.0), Vector3(0.12, 2.7, 0.12), Color(0.16, 0.22, 0.23), false)
	_add_box("Bus stop sign", Vector3(5.1, 2.65, 13.0), Vector3(0.72, 0.82, 0.12), Color(0.78, 0.22, 0.18), false)

func _create_building(x: float, z: float, variant: int) -> void:
	var palettes: Array[Color] = [
		Color(0.55, 0.48, 0.40),
		Color(0.43, 0.47, 0.48),
		Color(0.60, 0.55, 0.46),
		Color(0.39, 0.43, 0.42)
	]
	var height := 8.0 + float(variant % 3) * 1.7
	var width := 7.0 + float(variant % 2) * 1.0
	_add_box("London brick building", Vector3(x, height * 0.5, z), Vector3(width, height, 8.5), palettes[variant % palettes.size()])
	var face_x := x + (3.5 if x < 0.0 else -3.5)
	for floor_index in range(1, int(height / 2.1)):
		for window_index in range(2):
			var wz := z - 2.1 + float(window_index) * 3.8
			_add_box("Window", Vector3(face_x, 1.45 + float(floor_index) * 2.05, wz), Vector3(0.08, 0.95, 1.25), Color(0.18, 0.29, 0.34), false)
	_add_box("Shopfront", Vector3(face_x, 1.0, z + 0.2), Vector3(0.10, 1.45, 3.2), Color(0.16, 0.28, 0.30), false)
	_add_box("Awning", Vector3(face_x, 1.95, z + 0.2), Vector3(0.75, 0.16, 3.7), Color(0.62, 0.28, 0.20), false)

func _create_street_lamp(x: float, z: float) -> void:
	_add_box("Lamp post", Vector3(x, 2.0, z), Vector3(0.09, 4.0, 0.09), Color(0.12, 0.16, 0.16), false)
	_add_box("Lamp head", Vector3(x, 4.0, z), Vector3(0.55, 0.18, 0.32), Color(0.84, 0.78, 0.58), false)

func _create_tree(position: Vector3) -> void:
	var trunk := _add_box("Tree trunk", position + Vector3(0, 1.1, 0), Vector3(0.28, 2.2, 0.28), Color(0.30, 0.22, 0.16), false)
	var crown := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.25
	mesh.height = 2.5
	crown.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.35, 0.25)
	material.roughness = 1.0
	crown.material_override = material
	crown.position = position + Vector3(0, 3.0, 0)
	add_child(crown)

func _add_box(node_name: String, position: Vector3, dimensions: Vector3, color: Color, collision: bool = true) -> Node3D:
	var parent: Node3D = self
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	mesh_instance.position = position
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name.replace(" ", "") + "Body"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		shape_node.shape = shape
		body.position = position
		body.add_child(shape_node)
		mesh_instance.position = Vector3.ZERO
		body.add_child(mesh_instance)
		parent.add_child(body)
		return body
	parent.add_child(mesh_instance)
	return mesh_instance

func _create_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.12, 20.0)
	add_child(player)

func _create_city_life() -> void:
	city_life = CityLifeScript.new()
	city_life.name = "CityLife"
	add_child(city_life)
	city_life.setup(player)

func _create_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0.0, 1.5, 0.0)
	player.add_child(camera_pivot)
	camera = Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.position = Vector3(0.0, 1.0, 5.8)
	camera.rotation.x = camera_pitch
	camera.current = true
	camera.fov = 68.0
	camera_pivot.add_child(camera)
	player.camera_pivot = camera_pivot

func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(22.0, 18.0)
	top_panel.custom_minimum_size = Vector2(520.0, 58.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.09, 0.78)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	top_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(top_panel)

	hud_label = Label.new()
	hud_label.text = "لندن  •  ۲۰۱۸     |     در حال آماده‌سازی شهر..."
	hud_label.add_theme_font_size_override("font_size", 22)
	hud_label.add_theme_color_override("font_color", Color(0.91, 0.94, 0.89))
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_panel.add_child(hud_label)

	hint_label = Label.new()
	hint_label.text = "حرکت: جوی‌استیک سمت چپ     |     چرخش دوربین: کشیدن سمت راست"
	hint_label.position = Vector2(22.0, 84.0)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.92, 0.91, 0.82))
	root.add_child(hint_label)

	time_label = Label.new()
	time_label.text = "روز اول  |  ۰۸:۰۰"
	time_label.position = Vector2(1010.0, 24.0)
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	root.add_child(time_label)

	joystick = JoystickScript.new()
	joystick.name = "VirtualJoystick"
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 28.0
	joystick.offset_top = -208.0
	joystick.offset_right = 208.0
	joystick.offset_bottom = -28.0
	joystick.vector_changed.connect(_on_joystick_changed)
	root.add_child(joystick)

	var look_hint := Label.new()
	look_hint.text = "برای چرخاندن دوربین لمس و بکش"
	look_hint.position = Vector2(930.0, 650.0)
	look_hint.add_theme_font_size_override("font_size", 14)
	look_hint.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 0.8))
	root.add_child(look_hint)

	var edit_character_button := Button.new()
	edit_character_button.text = "ویرایش شخصیت"
	edit_character_button.position = Vector2(1060.0, 78.0)
	edit_character_button.custom_minimum_size = Vector2(190.0, 42.0)
	edit_character_button.pressed.connect(_open_character_creator)
	root.add_child(edit_character_button)

func _update_daylight() -> void:
	if not is_instance_valid(sun_light):
		return
	var hour := float(LifeSystem.minutes_of_day) / 60.0
	var daylight := 0.16
	if hour >= 6.0 and hour <= 19.0:
		daylight = 1.15
	elif hour > 19.0 and hour < 21.0:
		daylight = lerpf(1.15, 0.16, (hour - 19.0) / 2.0)
	elif hour >= 4.0 and hour < 6.0:
		daylight = lerpf(0.16, 1.15, (hour - 4.0) / 2.0)
	sun_light.light_energy = daylight
	sun_light.rotation_degrees.x = lerpf(-8.0, -72.0, clampf((hour - 6.0) / 13.0, 0.0, 1.0))

func _create_home_and_life_ui() -> void:
	home_world = HomeWorldScript.new()
	home_world.name = "StarterApartment"
	add_child(home_world)
	life_hud = LifeHUDScript.new()
	life_hud.name = "LifeHUD"
	life_hud.home_button_pressed.connect(_on_home_button_pressed)
	life_hud.eat_button_pressed.connect(_on_eat_button_pressed)
	life_hud.sleep_button_pressed.connect(_on_sleep_button_pressed)
	life_hud.shop_button_pressed.connect(_on_shop_button_pressed)
	life_hud.work_button_pressed.connect(_on_work_button_pressed)
	life_hud.rent_button_pressed.connect(_on_rent_button_pressed)
	life_hud.transport_button_pressed.connect(_on_transport_button_pressed)
	life_hud.talk_button_pressed.connect(_on_talk_button_pressed)
	life_hud.dialogue_choice_pressed.connect(_on_dialogue_choice_pressed)
	SocialStory.dialogue_changed.connect(life_hud.show_dialogue)
	add_child(life_hud)

func _on_home_button_pressed() -> void:
	if not is_instance_valid(home_world) or not is_instance_valid(player):
		return
	if home_world.is_inside:
		home_world.leave_home(player)
		life_hud.set_home_state(false)
		life_hud.show_message("از خانه خارج شدی.")
	else:
		home_world.enter_home(player)
		life_hud.set_home_state(true)
		life_hud.show_message("به خانه اجاره‌ای خودت خوش آمدی.")

func _on_sleep_button_pressed() -> void:
	if not is_instance_valid(home_world) or not home_world.is_inside:
		life_hud.show_message("برای خوابیدن باید به خانه برگردی.")
		return
	LifeSystem.sleep_for_night()
	life_hud.show_message("استراحت کردی و انرژی‌ات بازیابی شد.")

func _on_shop_button_pressed() -> void:
	life_hud.show_message(EconomySystem.buy_food())

func _on_work_button_pressed() -> void:
	life_hud.show_message(EconomySystem.work_shift())

func _on_rent_button_pressed() -> void:
	life_hud.show_message(EconomySystem.pay_rent())

func _on_talk_button_pressed() -> void:
	if not is_instance_valid(city_life) or not is_instance_valid(player):
		return
	var person_id := city_life.get_nearest_person(player)
	if person_id < 0:
		life_hud.show_message("برای گفت‌وگو باید به یکی از ساکنان نزدیک شوی.")
		return
	life_hud.show_message(SocialStory.begin_conversation(person_id))

func _on_dialogue_choice_pressed(choice_index: int) -> void:
	SocialStory.choose_dialogue(choice_index)

func _on_transport_button_pressed() -> void:
	if not is_instance_valid(city_life):
		return
	life_hud.show_message(city_life.take_bus(player))

func _on_eat_button_pressed() -> void:
	if not is_instance_valid(home_world) or not home_world.is_inside:
		life_hud.show_message("برای غذا خوردن باید داخل خانه باشی.")
		return
	life_hud.show_message(EconomySystem.consume_food())

func _open_character_creator() -> void:
	if is_instance_valid(character_creator):
		return
	character_creator = CharacterCreatorScript.new()
	character_creator.name = "CharacterCreator"
	character_creator.profile_confirmed.connect(_on_profile_confirmed)
	add_child(character_creator)

func _on_profile_confirmed(profile: Dictionary) -> void:
	if is_instance_valid(player):
		player.apply_profile(profile)
	player_display_name = "%s %s" % [str(profile.get("first_name", "")), str(profile.get("last_name", ""))]
	if is_instance_valid(hud_label):
		hud_label.text = "%s  •  لندن ۲۰۱۸" % player_display_name
	character_creator = null

func _create_input_actions() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)

func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

func _on_joystick_changed(value: Vector2) -> void:
	if is_instance_valid(player):
		player.set_move_input(value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.48:
			look_touch_id = event.index
			look_last_position = event.position
		elif not event.pressed and event.index == look_touch_id:
			look_touch_id = -1
	elif event is InputEventScreenDrag and event.index == look_touch_id:
		_apply_camera_drag(event.position - look_last_position)
		look_last_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			look_touch_id = -2
		else:
			look_touch_id = -1
	elif event is InputEventMouseMotion and look_touch_id == -2:
		_apply_camera_drag(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _apply_camera_drag(delta_position: Vector2) -> void:
	if not is_instance_valid(camera_pivot):
		return
	camera_pivot.rotation.y -= delta_position.x * 0.006
	camera_pitch = clampf(camera_pitch - delta_position.y * 0.004, -0.62, 0.28)
	camera.rotation.x = camera_pitch
