extends CanvasLayer

@onready var label := $HealthLabel

func _process(_delta: float) -> void:
	var texts: Array[String] = []
	for p in get_tree().get_nodes_in_group(&"players"):
		if not is_instance_valid(p):
			continue
		var pid = p.get("player_id") as int
		var hp = p.get("health") as int
		var max_hp = p.get("max_health") as int
		if pid != null and hp != null and max_hp != null:
			texts.append("P%s: %s/%s" % [pid, hp, max_hp])
	if texts.is_empty():
		label.text = "HP: ?/?"
	else:
		label.text = " | ".join(texts)
