extends Node3D

@export var min_limit_x: float
@export var max_limit_x: float
@export var horizontal_acceleration := 2.0
@export var vertical_acceleration := 1.0
@export var mouse_acceleration := 0.005
@export var rotation_smoothing := 12.0  # higher = snappier, lower = floatier

var target_rotation: Vector2  # x = pitch, y = yaw

func _ready() -> void:
	target_rotation = Vector2(rotation.x, rotation.y)
	
#func _process(delta: float) -> void:
	#var joy_dir = Input.get_vector("pan_left","pan_right","pan_up","pan_down")
	#rotate_from_vector(joy_dir * delta * Vector2(horizontal_acceleration, vertical_acceleration))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_from_vector(event.relative * mouse_acceleration)

func _process(delta: float) -> void:
	# exponential smoothing toward the target — framerate independent
	var t = 1.0 - exp(-rotation_smoothing * delta)
	rotation.x = lerp_angle(rotation.x, target_rotation.x, t)
	rotation.y = lerp_angle(rotation.y, target_rotation.y, t)
	
func rotate_from_vector(v: Vector2) -> void:
	if v.length() == 0:
		return
	target_rotation.y -= v.x
	target_rotation.x -= v.y
	target_rotation.x = clamp(target_rotation.x, min_limit_x, max_limit_x)
