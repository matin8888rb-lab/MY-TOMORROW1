extends Control
class_name VirtualJoystick

signal vector_changed(value: Vector2)

@export var deadzone: float = 0.12
@export var knob_limit: float = 68.0

var _touch_index: int = -1
var _vector: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	if size == Vector2.ZERO:
		size = Vector2(196.0, 196.0)
		_center = size * 0.5
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_from_position(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_set_vector(Vector2.ZERO)
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_from_position(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_index == -1:
			_touch_index = -2
			_update_from_position(event.position)
			accept_event()
		elif not event.pressed and _touch_index == -2:
			_touch_index = -1
			_set_vector(Vector2.ZERO)
			accept_event()
	elif event is InputEventMouseMotion and _touch_index == -2:
		_update_from_position(event.position)
		accept_event()

func _update_from_position(local_position: Vector2) -> void:
	var offset := local_position - _center
	if offset.length() > knob_limit:
		offset = offset.normalized() * knob_limit
	var next_value := Vector2(offset.x, -offset.y) / knob_limit
	if next_value.length() < deadzone:
		next_value = Vector2.ZERO
	_set_vector(next_value)

func _set_vector(value: Vector2) -> void:
	_vector = value
	vector_changed.emit(_vector)
	queue_redraw()

func get_vector() -> Vector2:
	return _vector

func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.5 - 5.0
	draw_circle(_center, radius, Color(0.04, 0.10, 0.15, 0.34))
	draw_arc(_center, radius, 0.0, TAU, 64, Color(0.72, 0.88, 0.91, 0.55), 3.0, true)
	var knob_position := _center + Vector2(_vector.x, -_vector.y) * knob_limit
	draw_circle(knob_position, 31.0, Color(0.73, 0.88, 0.87, 0.78))
	draw_arc(knob_position, 31.0, 0.0, TAU, 48, Color(0.94, 0.98, 0.96, 0.95), 2.0, true)
