extends Node3D

## Hedef bölge — vagon ateşle birlikte buraya girince oyun sonu.

func _ready():
	$DetectionArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Vagon (Wagon) karakteri mi?
	if body.has_method("get_fire_level") and body.get_fire_level() > 0:
		print("VICTORY! Wagon brought fire to target!")
		# İleride burada sinematik başlayacak
