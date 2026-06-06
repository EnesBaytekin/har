extends RigidBody3D

## Fırlatılan taş — bir yere çarpınca yerde item olarak kalır.
## Direkt ayıya çarparsa sinirlenme event'i gönderir.

var _timer: float = 0.0

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	_timer = 5.0

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		_land()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if linear_velocity.length_squared() > 0.5:
		angular_velocity = Vector3(5.0, 0.0, 2.0)

func _on_body_entered(body: Node) -> void:
	if body.has_method("bear_hit_by_stone"):
		body.bear_hit_by_stone()
		queue_free()
		return
	_land()

func _land():
	var di_scene := preload("res://scenes/item/dropped_item.tscn")
	var di := di_scene.instantiate() as DroppedItem
	di.item_type = 1
	di.global_position = global_position
	get_tree().current_scene.add_child(di)

	var bears := get_tree().get_nodes_in_group(&"bears")
	for b in bears:
		if is_instance_valid(b) and b.has_method("bear_notice_stone"):
			var d := global_position.distance_squared_to(b.global_position)
			if d < 36.0:
				b.bear_notice_stone(global_position)

	queue_free()
