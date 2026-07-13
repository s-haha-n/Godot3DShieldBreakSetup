extends Node3D

@onready var move_state_machine = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var attack_state_machine = $AnimationTree.get("parameters/AttackStateMachine/playback")
#@onready var extra_animation = $AnimationTree.get_tree_root().get_node('ExtraAnimation')
#@onready var face_material: StandardMaterial3D = $Rig/Skeleton3D/Godette_Head.get_surface_override_material(0)

var attacking := false
var squash_and_stretch := 1.0:
	set(value):
		squash_and_stretch = value
		var negative = 1.0 + (1.0 - squash_and_stretch)
		scale = Vector3(negative,squash_and_stretch,negative)
const faces = {
	'default': Vector3.ZERO,
	'blink': Vector3(0,0.5,0)
}
var rng = RandomNumberGenerator.new()

func set_move_state(state_name: String) -> void:
	move_state_machine.travel(state_name)

func attack() -> void:
	if not attacking:
		attack_state_machine.travel('jab' if $SecondAttackTimer.time_left else 'swing')
		$AnimationTree.set("parameters/AttackOneShot/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

#at 2:40:26 in botw tutorial he explains this and it needs
#a LOT of gui editing and KEYING in track editor in godot
func attack_toggle(value: bool):
	attacking = value
	
func defend(forward: bool) -> void:
	var tween = create_tween()
	tween.tween_method(_defend_change, 1.0 - float(forward), float(forward), 0.25)
	#fade shield with forward hold


func _defend_change(value: float) -> void:
	$AnimationTree.set("parameters/ShieldBlend/blend_amount", value)
