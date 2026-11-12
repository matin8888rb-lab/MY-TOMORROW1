extends Node3D
class_name HomeWorld

const HOME_CENTER := Vector3(20.0, 0.0, 20.0)
const ENTRY_POSITION := Vector3(20.0, 0.12, 27.0)
var is_inside: bool = false

func _ready() -> void:
	_build_apartment()
	LifestyleSystem.home_upgrade_purchased.connect(_on_home_upgrade_purchased)
	for upgrade_id in LifestyleSystem.owned_upgrades:
		_apply_home_upgrade(upgrade_id)

func _on_home_upgrade_purchased(upgrade_id: String) -> void:
	_apply_home_upgrade(upgrade_id)

func _apply_home_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"lamp":
			_add_box("چراغ ایستاده", Vector3(24.0, 1.25, 17.2), Vector3(0.32, 2.5, 0.32), Color(0.88, 0.72, 0.38), false)
			_add_box("سرچراغ", Vector3(24.0, 2.45, 17.2), Vector3(0.72, 0.18, 0.72), Color(1.0, 0.88, 0.58), false)
		"bookshelf":
			_add_box("قفسه کتاب", Vector3(15.8, 1.15, 22.2), Vector3(0.55, 2.3, 2.2), Color(0.30, 0.20, 0.13), false)
			for shelf_index in range(4):
				var book_colors: Array[Color] = [Color(0.55, 0.20, 0.16), Color(0.18, 0.34, 0.48), Color(0.72, 0.55, 0.22), Color(0.24, 0.42, 0.30)]
				_add_box("کتاب قفسه", Vector3(15.48, 0.45 + float(shelf_index) * 0.48, 22.2), Vector3(0.12, 0.32, 1.65), book_colors[shelf_index], false)
		"plant":
			_add_box("گلدان", Vector3(24.0, 0.35, 23.2), Vector3(0.7, 0.7, 0.7), Color(0.58, 0.30, 0.20), false)
			_add_box("گیاه آپارتمانی", Vector3(24.0, 1.05, 23.2), Vector3(0.25, 1.1, 0.25), Color(0.20, 0.48, 0.25), false)

func enter_home(player: CharacterBody3D) -> void:
	if not is_inside:
		player.velocity = Vector3.ZERO
		player.global_position = HOME_CENTER + Vector3(0.0, 0.12, 0.0)
		is_inside = true

func leave_home(player: CharacterBody3D) -> void:
	if is_inside:
		player.velocity = Vector3.ZERO
		player.global_position = ENTRY_POSITION
		is_inside = false

func _build_apartment() -> void:
	_add_box("کف خانه", Vector3(20.0, -0.12, 20.0), Vector3(10.0, 0.24, 8.0), Color(0.56, 0.48, 0.37))
	_add_box("دیوار پشتی", Vector3(20.0, 1.65, 16.0), Vector3(10.0, 3.3, 0.22), Color(0.72, 0.69, 0.61))
	_add_box("دیوار چپ", Vector3(15.0, 1.65, 20.0), Vector3(0.22, 3.3, 8.0), Color(0.72, 0.69, 0.61))
	_add_box("دیوار راست", Vector3(25.0, 1.65, 20.0), Vector3(0.22, 3.3, 8.0), Color(0.72, 0.69, 0.61))
	_add_box("دیوار جلویی چپ", Vector3(17.0, 1.65, 24.0), Vector3(4.0, 3.3, 0.22), Color(0.72, 0.69, 0.61))
	_add_box("دیوار جلویی راست", Vector3(23.0, 1.65, 24.0), Vector3(4.0, 3.3, 0.22), Color(0.72, 0.69, 0.61))
	_add_box("تخت", Vector3(17.6, 0.48, 17.8), Vector3(2.2, 0.65, 3.1), Color(0.30, 0.39, 0.53), false)
	_add_box("بالش", Vector3(17.6, 0.88, 16.7), Vector3(1.55, 0.18, 0.65), Color(0.85, 0.84, 0.76), false)
	_add_box("میز غذاخوری", Vector3(22.3, 0.9, 18.2), Vector3(2.0, 0.16, 1.2), Color(0.34, 0.23, 0.16), false)
	_add_box("یخچال", Vector3(23.4, 1.05, 22.0), Vector3(0.9, 2.1, 0.85), Color(0.72, 0.75, 0.75), false)
	_add_box("مبل", Vector3(20.4, 0.55, 22.3), Vector3(2.6, 0.85, 0.95), Color(0.32, 0.39, 0.36), false)
	_add_box("پنجره", Vector3(20.0, 2.0, 16.12), Vector3(2.4, 1.1, 0.06), Color(0.32, 0.52, 0.62), false)
	_add_box("تابلوی خانه", Vector3(20.0, 2.65, 23.82), Vector3(1.6, 0.65, 0.08), Color(0.24, 0.34, 0.38), false)
	_add_box("نشان ورودی", Vector3(20.0, 0.035, 26.1), Vector3(2.0, 0.04, 0.7), Color(0.72, 0.58, 0.28), false)

func _add_box(node_name: String, position: Vector3, dimensions: Vector3, color: Color, collision: bool = true) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	if collision:
		var body := StaticBody3D.new()
		body.position = position
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collider.shape = shape
		body.add_child(collider)
		mesh_instance.position = Vector3.ZERO
		body.add_child(mesh_instance)
		add_child(body)
	else:
		mesh_instance.position = position
		add_child(mesh_instance)
