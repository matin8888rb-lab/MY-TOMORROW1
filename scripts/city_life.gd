extends Node3D
class_name CityLifeSystem

const NPC_COLORS: Array[Color] = [
	Color(0.72, 0.35, 0.25),
	Color(0.25, 0.42, 0.68),
	Color(0.72, 0.62, 0.35),
	Color(0.28, 0.52, 0.40)
]

var player: CharacterBody3D
var npc_data: Array[Dictionary] = []
var route_stops: Array[Vector3] = [Vector3(5.1, 0.12, 13.0), Vector3(65.0, 0.12, 13.0)]
var current_district: int = 0
var npc_clock_bucket: int = -1
const NPC_NAMES: Array[String] = ["اِما", "جیمز", "سوفیا", "الیور", "میا", "نوآ"]

func setup(target_player: CharacterBody3D) -> void:
	player = target_player
	_build_second_district()
	_build_bus_stops()
	_build_npcs()

func _process(delta: float) -> void:
	_update_npc_routines()
	for data in npc_data:
		var actor: Node3D = data["actor"]
		var target: Vector3 = data["target"]
		actor.position = actor.position.move_toward(target, float(data["speed"]) * delta)
		if actor.position.distance_to(target) < 0.3:
			data["target"] = _pick_waypoint(int(data["district"]))

func _build_second_district() -> void:
	_add_box("Riverside district ground", Vector3(68.0, -0.55, 0.0), Vector3(62.0, 1.0, 100.0), Color(0.30, 0.36, 0.34))
	_add_box("Riverside main road", Vector3(68.0, 0.015, 0.0), Vector3(7.0, 0.08, 88.0), Color(0.105, 0.12, 0.13))
	_add_box("Riverside pavement west", Vector3(63.5, 0.08, 0.0), Vector3(1.9, 0.22, 88.0), Color(0.48, 0.49, 0.45))
	_add_box("Riverside pavement east", Vector3(72.5, 0.08, 0.0), Vector3(1.9, 0.22, 88.0), Color(0.48, 0.49, 0.45))
	for i in range(5):
		var z := -31.0 + float(i) * 15.0
		_build_district_building(57.0, z, i)
		_build_district_building(79.0, z, i + 1)
	_add_box("Riverside park lawn", Vector3(91.0, -0.02, 18.0), Vector3(20.0, 0.12, 24.0), Color(0.22, 0.38, 0.26))
	for i in range(5):
		_create_tree(Vector3(84.0 + float(i % 2) * 5.0, 0.0, 9.0 + float(i) * 4.0))
	_add_box("Library building", Vector3(92.0, 4.0, -22.0), Vector3(12.0, 8.0, 10.0), Color(0.48, 0.48, 0.43))
	_add_box("Library sign", Vector3(92.0, 5.5, -16.8), Vector3(7.0, 0.7, 0.18), Color(0.15, 0.27, 0.30), false)

func _build_district_building(x: float, z: float, variant: int) -> void:
	var colors: Array[Color] = [Color(0.55,0.48,0.40), Color(0.43,0.47,0.48), Color(0.60,0.55,0.46)]
	var h := 7.0 + float(variant % 3) * 1.5
	_add_box("Riverside building", Vector3(x, h * 0.5, z), Vector3(8.0, h, 9.0), colors[variant % colors.size()])
	var front := x + (4.05 if x < 68.0 else -4.05)
	for floor_index in range(1, int(h / 2.2)):
		_add_box("Riverside window", Vector3(front, 1.6 + float(floor_index) * 2.1, z), Vector3(0.08, 0.9, 1.4), Color(0.18,0.29,0.34), false)

func _build_bus_stops() -> void:
	for index in range(route_stops.size()):
		var p: Vector3 = route_stops[index]
		_add_box("Bus stop pole", p + Vector3(0.0, 1.2, 0.0), Vector3(0.12, 2.4, 0.12), Color(0.15,0.20,0.21), false)
		_add_box("Bus stop sign", p + Vector3(0.0, 2.25, 0.0), Vector3(0.75, 0.65, 0.12), Color(0.72,0.18,0.16), false)
		var label := Label3D.new()
		label.text = "BUS"
		label.position = p + Vector3(0.0, 2.25, 0.1)
		label.font_size = 32
		label.modulate = Color.WHITE
		add_child(label)

func _build_npcs() -> void:
	for i in range(6):
		var district := 0 if i < 3 else 1
		var start := _pick_waypoint(district)
		var actor := Node3D.new()
		actor.name = "CityResident_%d" % i
		actor.position = start
		var skin := StandardMaterial3D.new()
		skin.albedo_color = [Color(0.88,0.68,0.52),Color(0.63,0.42,0.30),Color(0.40,0.27,0.20)][i % 3]
		var outfit := StandardMaterial3D.new()
		outfit.albedo_color = NPC_COLORS[i % NPC_COLORS.size()]
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.10,0.12,0.15)
		_add_actor_capsule(actor,"Torso",0.25,0.72,outfit,Vector3(0,1.02,0))
		_add_actor_capsule(actor,"Neck",0.075,0.16,skin,Vector3(0,1.48,0))
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.19
		head_mesh.height = 0.39
		head.mesh = head_mesh
		head.position.y = 1.68
		head.material_override = skin
		actor.add_child(head)
		var hair := MeshInstance3D.new()
		var hair_mesh := SphereMesh.new()
		hair_mesh.radius = 0.195
		hair_mesh.height = 0.16
		hair.mesh = hair_mesh
		hair.position = Vector3(0,1.83,0)
		hair.material_override = dark
		actor.add_child(hair)
		for side in [-1.0,1.0]:
			var eye_mat := StandardMaterial3D.new()
			eye_mat.albedo_color = Color(0.06,0.07,0.08)
			_add_actor_sphere(actor,"Eye",0.025,eye_mat,Vector3(side*0.065,1.70,-0.17))
			_add_actor_capsule(actor,"Arm",0.075,0.56,outfit,Vector3(side*0.31,1.04,0))
			_add_actor_capsule(actor,"Leg",0.09,0.62,dark,Vector3(side*0.13,0.39,0))
		_add_actor_capsule(actor,"Shoe",0.095,0.20,dark,Vector3(-0.13,0.10,-0.04))
		_add_actor_capsule(actor,"Shoe",0.095,0.20,dark,Vector3(0.13,0.10,-0.04))
		add_child(actor)
		npc_data.append({"actor": actor, "district": district, "target": _pick_waypoint(district), "speed": 1.0 + float(i % 3) * 0.18, "routine": -1, "person_id": i})

func _add_actor_capsule(parent: Node3D, node_name: String, radius: float, height: float, material: Material, position: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	parent.add_child(mesh_instance)

func _add_actor_sphere(parent: Node3D, node_name: String, radius: float, material: Material, position: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	parent.add_child(mesh_instance)

func _update_npc_routines() -> void:
	var hour := int(LifeSystem.minutes_of_day / 60)
	var bucket := 0 if hour < 8 else (1 if hour < 17 else 2)
	if bucket == npc_clock_bucket:
		return
	npc_clock_bucket = bucket
	for i in range(npc_data.size()):
		var data: Dictionary = npc_data[i]
		var district := int(data["district"])
		# Residents gather near the high street in the day and move toward homes/park later.
		if bucket == 1:
			data["target"] = Vector3(68.0 + (3.0 if district == 1 else -3.0), 0.12, -4.0 + float(i) * 2.0)
		elif bucket == 2:
			data["target"] = Vector3(68.0 + (22.0 if district == 1 else -22.0), 0.12, 16.0 - float(i) * 2.0)
		else:
			data["target"] = _pick_waypoint(district)
		data["routine"] = bucket
		npc_data[i] = data

func _pick_waypoint(district: int) -> Vector3:
	var center_x := 68.0 if district == 1 else 0.0
	var side := 1.0 if district == 1 else -1.0
	var x := center_x + side * float(randi_range(5, 17))
	var z := float(randi_range(-30, 30))
	return Vector3(x, 0.12, z)

func get_nearest_person(target_player: CharacterBody3D, max_distance: float = 4.5) -> int:
	var nearest_id := -1
	var best_distance := max_distance
	for data in npc_data:
		var actor: Node3D = data["actor"]
		var distance := target_player.global_position.distance_to(actor.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest_id = int(data["person_id"])
	return nearest_id

func take_bus(target_player: CharacterBody3D) -> String:
	if not is_instance_valid(target_player):
		return "امکان استفاده از اتوبوس وجود ندارد."
	var nearest := -1
	var best_distance := 9999.0
	for i in range(route_stops.size()):
		var distance := target_player.global_position.distance_to(route_stops[i])
		if distance < best_distance:
			best_distance = distance
			nearest = i
	if best_distance > 7.0:
		return "برای سوار شدن باید به ایستگاه اتوبوس نزدیک شوی."
	var destination_index := 1 - nearest
	var destination: Vector3 = route_stops[destination_index]
	if not EconomySystem.pay_transport_fare():
		return "برای بلیت اتوبوس £3 لازم داری."
	target_player.global_position = destination + Vector3(2.0, 0.0, 0.0)
	target_player.velocity = Vector3.ZERO
	current_district = destination_index
	return "با اتوبوس به %s رفتی؛ هزینه بلیت £3 بود." % ("محله ریورساید" if destination_index == 1 else "مرکز شهر")

func _create_tree(p: Vector3) -> void:
	_add_box("Park tree trunk", p + Vector3(0, 1.0, 0), Vector3(0.25, 2.0, 0.25), Color(0.30,0.22,0.16), false)
	var crown := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.15
	mesh.height = 2.3
	crown.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20,0.35,0.25)
	crown.material_override = mat
	crown.position = p + Vector3(0,2.7,0)
	add_child(crown)

func _add_box(node_name: String, position: Vector3, dimensions: Vector3, color: Color, collision: bool = true) -> Node3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh_instance.material_override = material
	if collision:
		var body := StaticBody3D.new()
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		shape_node.shape = shape
		body.position = position
		body.add_child(shape_node)
		mesh_instance.position = Vector3.ZERO
		body.add_child(mesh_instance)
		add_child(body)
		return body
	mesh_instance.position = position
	add_child(mesh_instance)
	return mesh_instance
