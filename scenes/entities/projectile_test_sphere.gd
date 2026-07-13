extends RigidBody3D
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var shield = body.get_parent()
	if shield.has_method("hit"):
		#shield.take_damage(damage)
		shield.hit(15)
		queue_free()
