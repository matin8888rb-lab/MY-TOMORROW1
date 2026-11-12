extends CharacterBody3D
class_name PlayerController

@export var walk_speed: float = 4.2
@export var acceleration: float = 18.0
@export var gravity: float = 9.8

var move_input: Vector2 = Vector2.ZERO
var camera_pivot: Node3D

func _ready() -> void:
	_build_character()

func _build_character() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.36
	capsule.height = 1.75
	var body_mesh := MeshInstance3D.new()
	body_mesh.name = "PlayerVisual"
	body_mesh.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.22, 0.39, 0.48)
	material.roughness = 0.82
	body_mesh.material_override = material
	body_mesh.position.y = 0.88
	add_child(body_mesh)

	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.88
	add_child(collider)

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
