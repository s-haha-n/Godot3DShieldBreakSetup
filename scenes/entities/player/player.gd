extends CharacterBody3D

#jump
@export var jump_height : float = 2.25
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
# source: https://youtu.be/IOe1aGY6hXA?feature=shared

@onready var skin = $XBotSkin
@export var skin_rotation_speed : float = 6.0

@export_group("Movement") # Organizes your inspector
@export var base_speed := 4.0
@export var run_speed := 6.0
@export var defend_speed := 2.0
@export var deceleration: float = 4.0

var speed_modifier := 1.0

@onready var camera = $CameraController/Camera3D
var movement_input := Vector2.ZERO
var last_movement_input := Vector2(0,1)
var stamina = 100

var defend := false:
	set(value):
		if not defend and value:
			skin.defend(true)
		if defend and not value:
			skin.defend(false)
		defend = value

func _physics_process(delta: float) -> void:
	#RenderingServer.global_shader_parameter_set("player_position", global_position)
	move_logic(delta)
	jump_logic(delta)
	ability_logic()
	#if Input.is_action_just_pressed("ui_accept"):
		#hit()
	move_and_slide()
	physics_logic()

func move_logic(delta) -> void:
	movement_input = Input.get_vector("left","right","forward","backward").rotated(-camera.global_rotation.y)
	var vel_2d = Vector2(velocity.x, velocity.z)
	var is_running: bool = Input.is_action_pressed("run")
	
	if movement_input != Vector2.ZERO:
		var speed = run_speed if is_running else base_speed
		#speed = defend_speed if defend else speed
		#if is_running:
			#skin.set_move_state('Run')
				
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

	if movement_input:
		last_movement_input = movement_input.normalized()

	#run_particles.emitting = is_on_floor() and is_running and movement_input != Vector2.ZERO
	
	#w
	#else:
		#$Sounds/StepSound.playing = false

func jump_logic(delta) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and stamina >= 20:
			velocity.y = -jump_velocity
			#do_squash_and_stretch(1.2, 0.15)
			stamina -= 2
	else:
		skin.set_move_state('Jumping')
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta

func ability_logic() -> void:
	# actual attack
	if Input.is_action_just_pressed("ability"):
		skin.attack()
		
	defend = Input.is_action_pressed("block")

func stop_movement(start_duration: float, end_duration: float):
	var tween = create_tween()
	tween.tween_property(self, "speed_modifier", 0.0, start_duration)
	tween.tween_property(self, "speed_modifier", 1.0, end_duration)

#func hit():
	#if not $Timers/InvulTimer.time_left:
		##skin.hit()
		#stop_movement(0.3,0.3)
		##health -= 1
		#$Timers/InvulTimer.start()

func physics_logic() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider is RigidBody3D:
			collider.apply_central_impulse(-get_slide_collision(i).get_normal())
