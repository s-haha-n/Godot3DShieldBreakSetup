extends MeshInstance3D

@export var max_health := 100.0
@export var initial_color := Color(0.55, 0.9, 1.0, 1.0)
@export var final_color := Color(4.0, 0.35, 0.25, 1.0)
@export var shake_strength := 0.03
@export var shake_decay := 10.0
@export var base_fresnel_power := 3.0
@export var burst_duration := 1.6
@export var explode_curve: Curve
@export var fade_curve: Curve
@export var fresnel_curve: Curve

@export var test_mode := false
@export var test_min_interval := 0.4
@export var test_max_interval := 1.2
@export var test_damage := 10.0

var health := max_health
var material: ShaderMaterial
var rest_position := Vector3.ZERO
var shake_magnitude := 0.0
var shatter_progress := 0.0
var fade_amount := 0.0
var burst_time := 0.0
var bursting := false

func _ready() -> void:
	material = get_active_material(0)
	rest_position = position
	if not explode_curve:
		explode_curve = Curve.new()
		explode_curve.add_point(Vector2(0.0, 0.0))
		explode_curve.add_point(Vector2(0.15, 1.2))
		explode_curve.add_point(Vector2(0.4, 0.9))
		explode_curve.add_point(Vector2(1.0, 1.0))
	if not fade_curve:
		fade_curve = Curve.new()
		fade_curve.add_point(Vector2(0.0, 0.0))
		fade_curve.add_point(Vector2(0.25, 0.05))
		fade_curve.add_point(Vector2(1.0, 1.0))
	if not fresnel_curve:
		fresnel_curve = Curve.new()
		fresnel_curve.add_point(Vector2(0.0, base_fresnel_power))
		fresnel_curve.add_point(Vector2(0.3, base_fresnel_power * 2.0))
		fresnel_curve.add_point(Vector2(1.0, base_fresnel_power * 0.6))
	update_color()
	material.set_shader_parameter("fresnel_power", base_fresnel_power)
	if test_mode:
		run_test_sequence()

func hit(damage: float) -> void:
	if bursting:
		return
	health = max(health - damage, 0.0)
	shake_magnitude = shake_strength
	update_color()
	if health <= 0.0:
		burst()

func burst() -> void:
	bursting = true
	burst_time = 0.0

func reset() -> void:
	health = max_health
	bursting = false
	shatter_progress = 0.0
	fade_amount = 0.0
	burst_time = 0.0
	position = rest_position
	visible = true
	update_color()
	material.set_shader_parameter("shatter_progress", 0.0)
	material.set_shader_parameter("fade_amount", 0.0)
	material.set_shader_parameter("fresnel_power", base_fresnel_power)

func update_color() -> void:
	var t := 1.0 - health / max_health
	material.set_shader_parameter("shield_color", initial_color.lerp(final_color, t))

func _process(delta: float) -> void:
	if shake_magnitude > 0.0001:
		position = rest_position + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_magnitude
		shake_magnitude -= shake_magnitude * shake_decay * delta
	else:
		position = rest_position

	if bursting:
		burst_time = min(burst_time + delta, burst_duration)
		var t := burst_time / burst_duration
		shatter_progress = explode_curve.sample(t)
		fade_amount = fade_curve.sample(t)
		material.set_shader_parameter("fresnel_power", fresnel_curve.sample(t))
		if t >= 1.0:
			visible = false

	material.set_shader_parameter("shatter_progress", shatter_progress)
	material.set_shader_parameter("fade_amount", fade_amount)

func run_test_sequence() -> void:
	
	await get_tree().create_timer(4.0).timeout
	while true:
		await get_tree().create_timer(randf_range(test_min_interval, test_max_interval)).timeout
		hit(test_damage)
		if health <= 0.0:
			await get_tree().create_timer(burst_duration + 0.5).timeout
			reset()
