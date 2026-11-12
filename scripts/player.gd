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
var hair_mesh_instance: MeshInstance3D

const SKIN_COLORS: Array[Color] = [
	Color(0.91, 0.73, 0.59),
	Color(0.72, 0.49, 0.34),
	Color(0.48, 0.31, 0.22),
	Color(0.27, 0.18, 0.14)
]
const HAIR_COLORS: Array[Color] = [
	Color(0.075, 0.055, 0.045),
	Color(0.25, 0.13, 0.075),
	Color(0.67, 0.48, 0.23),
	Color(0.34, 0.12, 0.09)
]
const OUTFIT_COLORS: Array[Color] = [
	Color(0.18, 0.36, 0.52),
	Color(0.19, 0.39, 0.29),
	Color(0.55, 0.20, 0.18),
	Color(0.32, 0.35, 0.38)
]

func _ready() -> void:
	_build_character()

func _build_character() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.36
	capsule.height = 1.75
	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "PlayerVisual"
	body_mesh.mesh = capsule
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = OUTFIT_COLORS[0]
	body_material.roughness = 0.82
	body_mesh.material_override = body_material
	body_mesh.position.y = 0.88
	add_child(body_mesh)

	var head := MeshInstance3D.new()
	head.name = "PlayerHead"
	var head_shape := SphereMesh.new()
	head_shape.radius = 0.25
	head_shape.height = 0.5
	head.mesh = head_shape
	skin_material = StandardMaterial3D.new()
	skin_material.albedo_color = SKIN_COLORS[0]
	skin_material.roughness = 0.9
	head.material_override = skin_material
	head.position = Vector3(0.0, 1.53, 0.0)
	add_child(head)

	hair_mesh_instance = MeshInstance3D.new()
	hair_mesh_instance.name = "PlayerHair"
	var hair_shape := SphereMesh.new()
	hair_shape.radius = 0.255
	hair_shape.height = 0.28
	hair_mesh_instance.mesh = hair_shape
	hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = HAIR_COLORS[0]
	hair_material.roughness = 0.95
	hair_mesh_instance.material_override = hair_material
	hair_mesh_instance.position = Vector3(0.0, 1.76, 0.0)
	add_child(hair_mesh_instance)

	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.88
	add_child(collider)

func apply_profile(profile: Dictionary) -> void:
	if body_material == null or skin_material == null or hair_material == null:
		return
	var skin_index := clampi(int(profile.get("skin_tone", 0)), 0, SKIN_COLORS.size() - 1)
	var hair_index := clampi(int(profile.get("hair_color", 0)), 0, HAIR_COLORS.size() - 1)
	var outfit_index := clampi(int(profile.get("outfit_color", 0)), 0, OUTFIT_COLORS.size() - 1)
	var style_index := clampi(int(profile.get("hair_style", 0)), 0, 2)
	skin_material.albedo_color = SKIN_COLORS[skin_index]
	hair_material.albedo_color = HAIR_COLORS[hair_index]
	body_material.albedo_color = OUTFIT_COLORS[outfit_index]
	var hair_scales: Array[Vector3] = [
		Vector3(1.0, 0.68, 1.0),
		Vector3(1.0, 1.0, 1.0),
		Vector3(1.08, 1.32, 1.08)
	]
	hair_mesh_instance.scale = hair_scales[style_index]

func set_move_input(value: Vector2) -> void:
	move_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
	var input_vector := move_input
	if not OS.has_feature("mobile"):
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if direction.length_squared() > 0.001:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, minf(10.0 * delta, 1.0))

	move_and_slide()
