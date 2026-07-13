extends CharacterBody3D

#@onready var health_bar = $"../../HealthBar"
@onready var stamina_bar = $"../../StaminaBar"

@export_group("Movement")
@export var base_speed := 1.0
@export var run_speed := 6.0
@export var defend_speed := 2.0
@export var deceleration: float = 4.0
@export var skin_rotation_speed : float = 6.0

@export_group("Stamina System")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 20.0 # Points per second
@export var stamina_regen_delay: float = 2.0 # Seconds to wait before regen starts
var stamina: float = 100.0
var regen_timer: float = 0.0

@export_group("Jump Settings")
@export var jump_height : float = 2.25
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.3

@onready var jump_stamina_cost : float = 20
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export_group("Dodge Settings")
@export var roll_speed : float = 12.0
@export var roll_duration : float = 0.5 
@export var roll_stamina_cost : float = 10.0
var is_rolling : bool = false

@onready var skin = $PlayerSkin
@onready var camera = $CameraController/Camera3D



var speed_modifier := 1.0
var movement_input := Vector2.ZERO
var last_movement_input := Vector2(0,1)

var defend := false:
	set(value):
		if not defend and value: skin.defend(true)
		if defend and not value: skin.defend(false)
		defend = value

func _ready():
	stamina = max_stamina
	stamina_bar.init_target_value(stamina)
	#health_bar.init_target_value()
	
func _physics_process(delta: float) -> void:
	
	stamina_regen(delta)

	if not is_rolling:
		move_logic(delta)
		jump_logic(delta)
		ability_logic()
		roll_input_check()
	else:
		apply_gravity(delta)
	
	move_and_slide()
	physics_logic()

# STAMINA LOGIC
func use_stamina(amount: float):
	stamina = clamp(stamina - amount, 0, max_stamina)
	regen_timer = stamina_regen_delay # Reset the 4-second wait
	stamina_bar.target_value = stamina # Update UI

func stamina_regen(delta: float):
	if regen_timer > 0:
		regen_timer -= delta # Count down the 4 seconds
	elif stamina < max_stamina:
		# Start regening once timer is 0
		stamina = move_toward(stamina, max_stamina, stamina_regen_rate * delta)
		stamina_bar.target_value = stamina

# STAMINA USING ACTIONS
func jump_logic(delta) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and stamina >= 20:
			velocity.y = -jump_velocity
			use_stamina(jump_stamina_cost) # Using unified stamina function
	else:
		skin.set_move_state('Jumping')
	apply_gravity(delta)

func roll_input_check() -> void:
	if Input.is_action_just_pressed("dodge") and stamina >= roll_stamina_cost:
		start_roll()

func start_roll() -> void:
	is_rolling = true
	use_stamina(roll_stamina_cost) # Using unified stamina function
	skin.set_move_state('Roll')
	
	var skin_forward = skin.global_transform.basis.z
	skin_forward.y = 0
	skin_forward = skin_forward.normalized()
	
	velocity.x = skin_forward.x * roll_speed
	velocity.z = skin_forward.z * roll_speed
	skin.rotation.y = atan2(skin_forward.x, skin_forward.z)
	
	await get_tree().create_timer(roll_duration).timeout
	is_rolling = false

# LOCOMOTION
func move_logic(delta) -> void:
	movement_input = Input.get_vector("left","right","forward","backward").rotated(-camera.global_rotation.y)
	var vel_2d = Vector2(velocity.x, velocity.z)
	var is_running: bool = Input.is_action_pressed("run")
	
	if movement_input != Vector2.ZERO:
		var speed = run_speed if is_running else base_speed
		speed = defend_speed if defend else speed
		
		vel_2d += movement_input * speed * delta * 8.0
		vel_2d = vel_2d.limit_length(speed) * speed_modifier
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		
		skin.set_move_state('Walk')
		var target_angle = -movement_input.angle() + PI/2
		skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, skin_rotation_speed * delta)
	else:
		vel_2d = vel_2d.move_toward(Vector2.ZERO, base_speed * deceleration * delta)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		skin.set_move_state('Idle')

func apply_gravity(delta):
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta

func ability_logic() -> void:
	if Input.is_action_just_pressed("ability"): # One shot actions
		skin.attack()
		
	defend = Input.is_action_pressed("block") # Held actions

func physics_logic() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider is RigidBody3D:
			collider.apply_central_impulse(-get_slide_collision(i).get_normal())
