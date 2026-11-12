extends CharacterBody3D
class_name PlayerController

@export var walk_speed: float = 4.2
@export var acceleration: float = 18.0
@export var gravity: float = 9.8

var move_input: Vector2 = Vector2.ZERO
var camera_pivot: Node3D
var body_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var pants_material: StandardMaterial3D
var shoe_material: StandardMaterial3D
var hair_mesh_instance: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var walk_phase: float = 0.0

const SKIN_COLORS: Array[Color] = [Color(0.91,0.73,0.59),Color(0.72,0.49,0.34),Color(0.48,0.31,0.22),Color(0.27,0.18,0.14)]
const HAIR_COLORS: Array[Color] = [Color(0.075,0.055,0.045),Color(0.25,0.13,0.075),Color(0.67,0.48,0.23),Color(0.34,0.12,0.09)]
const OUTFIT_COLORS: Array[Color] = [Color(0.18,0.36,0.52),Color(0.19,0.39,0.29),Color(0.55,0.20,0.18),Color(0.32,0.35,0.38)]

func _ready() -> void:
	_build_character()

func _make_material(color: Color, roughness_value: float = 0.82) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _add_capsule(node_name: String, radius: float, height: float, material: Material, position: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 6
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance

func _build_character() -> void:
	body_material = _make_material(OUTFIT_COLORS[0])
	skin_material = _make_material(SKIN_COLORS[0], 0.9)
	hair_material = _make_material(HAIR_COLORS[0], 0.95)
	pants_material = _make_material(Color(0.12,0.16,0.20))
	shoe_material = _make_material(Color(0.055,0.065,0.075), 0.72)

	_add_capsule("Jacket torso", 0.29, 0.82, body_material, Vector3(0,1.02,0))
	_add_capsule("Neck", 0.105, 0.22, skin_material, Vector3(0,1.48,0))
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.235
	head_mesh.height = 0.49
	head_mesh.radial_segments = 16
	head_mesh.rings = 10
	head.mesh = head_mesh
	head.material_override = skin_material
	head.position = Vector3(0,1.72,0)
	add_child(head)

	hair_mesh_instance = MeshInstance3D.new()
	hair_mesh_instance.name = "Hair"
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.245
	hair_mesh.height = 0.25
	hair_mesh.radial_segments = 16
	hair_mesh.rings = 8
	hair_mesh_instance.mesh = hair_mesh
	hair_mesh_instance.material_override = hair_material
	hair_mesh_instance.position = Vector3(0,1.91,-0.015)
	add_child(hair_mesh_instance)

	left_arm = _add_capsule("Left sleeve",0.105,0.66,body_material,Vector3(-0.36,1.08,0))
	right_arm = _add_capsule("Right sleeve",0.105,0.66,body_material,Vector3(0.36,1.08,0))
	left_arm.rotation.z = -0.12
	right_arm.rotation.z = 0.12
	_add_capsule("Left hand",0.075,0.20,skin_material,Vector3(-0.39,0.68,0))
	_add_capsule("Right hand",0.075,0.20,skin_material,Vector3(0.39,0.68,0))

	left_leg = _add_capsule("Left trouser leg",0.125,0.72,pants_material,Vector3(-0.15,0.43,0))
	right_leg = _add_capsule("Right trouser leg",0.125,0.72,pants_material,Vector3(0.15,0.43,0))
	_add_capsule("Left shoe",0.13,0.28,shoe_material,Vector3(-0.15,0.12,-0.07))
	_add_capsule("Right shoe",0.13,0.28,shoe_material,Vector3(0.15,0.12,-0.07))

	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.85
	collider.shape = shape
	collider.position.y = 0.92
	add_child(collider)

func apply_profile(profile: Dictionary) -> void:
	if body_material == null:
		return
	var skin_index := clampi(int(profile.get("skin_tone",0)),0,SKIN_COLORS.size()-1)
	var hair_index := clampi(int(profile.get("hair_color",0)),0,HAIR_COLORS.size()-1)
	var outfit_index := clampi(int(profile.get("outfit_color",0)),0,OUTFIT_COLORS.size()-1)
	var style_index := clampi(int(profile.get("hair_style",0)),0,2)
	skin_material.albedo_color = SKIN_COLORS[skin_index]
	hair_material.albedo_color = HAIR_COLORS[hair_index]
	body_material.albedo_color = OUTFIT_COLORS[outfit_index]
	var hair_scales: Array[Vector3] = [Vector3(1.0,0.68,1.0),Vector3(1.0,1.0,1.0),Vector3(1.08,1.32,1.08)]
	hair_mesh_instance.scale = hair_scales[style_index]

func set_move_input(value: Vector2) -> void:
	move_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
	var input_vector := move_input
	if not OS.has_feature("mobile"):
		input_vector = Input.get_vector("move_left","move_right","move_forward","move_back")
		if input_vector == Vector2.ZERO:
			input_vector = move_input
	var basis := global_transform.basis
	if is_instance_valid(camera_pivot):
		basis = camera_pivot.global_transform.basis
	var forward := -basis.z
	var right := basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input_vector.x + forward * input_vector.y).normalized()
	var target_velocity := direction * walk_speed
	velocity.x = move_toward(velocity.x,target_velocity.x,acceleration*delta)
	velocity.z = move_toward(velocity.z,target_velocity.z,acceleration*delta)
	if not is_on_floor():
		velocity.y -= gravity*delta
	else:
		velocity.y = 0.0
	if direction.length_squared() > 0.001:
		var target_angle := atan2(direction.x,direction.z)
		rotation.y = lerp_angle(rotation.y,target_angle,minf(10.0*delta,1.0))
		walk_phase += delta * (8.0 if input_vector.length() > 0.7 else 5.5)
	else:
		walk_phase = lerpf(walk_phase,0.0,delta*5.0)
	_animate_walk()
	move_and_slide()

func _animate_walk() -> void:
	var swing := sin(walk_phase) * minf(Vector2(velocity.x,velocity.z).length()/walk_speed,1.0) * 0.48
	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing
	left_arm.rotation.x = -swing * 0.72
	right_arm.rotation.x = swing * 0.72
