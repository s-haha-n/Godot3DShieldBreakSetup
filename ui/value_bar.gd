extends ProgressBar

@onready var tween_bar = $TweenBar
@onready var timer = $Timer

var target_value = 0 : set = _set_target_value
var tween: Tween

func _set_target_value(new_target_value): 
	var prev_target_value = target_value
	target_value = clamp(new_target_value, 0, max_value)
	value = target_value # Front bar snaps immediately
	
	if not is_inside_tree() or tween_bar == null:
		return
			
	if target_value < prev_target_value:
		# If we took damage, start/restart the delay timer
		timer.start()
	else:
		# If we are regenerating, make the back bar follow the front bar instantly
		if tween: tween.kill()
		tween_bar.value = target_value

func init_target_value(_target_value):
	max_value = _target_value
	target_value = _target_value 
	value = _target_value
	if tween_bar:
		tween_bar.max_value = _target_value
		tween_bar.value = _target_value
	
func _on_timer_timeout() -> void:
	# This handles the smooth catch-up
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(tween_bar, "value", target_value, 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
