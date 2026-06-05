extends Node3D

## Takip edilecek oyuncuların NodePath'leri
@export var players: Array[NodePath] = []

## Pivot'un orta noktaya ne kadar hızlı yaklaştığı (0=sabit, yüksek=ani)
@export var follow_speed: float = 5.0

func _ready():
	# İlk frame'de direkt orta noktaya ışınla (sıçrama olmasın)
	global_position = _calculate_midpoint()

func _process(delta: float) -> void:
	var target := _calculate_midpoint()

	# Smooth lerp ile orta noktaya yaklaş
	var factor := clampf(follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target, factor)

## Tüm oyuncuların ortalama pozisyonunu döndürür.
## Hiç oyuncu yoksa pivot'un mevcut pozisyonunu korur.
func _calculate_midpoint() -> Vector3:
	var sum := Vector3.ZERO
	var count := 0

	for path in players:
		var node := get_node_or_null(path) as Node3D
		if node != null and is_instance_valid(node):
			sum += node.global_position
			count += 1

	if count > 0:
		var avg := sum / count
		# Sadece xz'yi al, y'yi sabit tut (pivot yerden yüksekte durmasın)
		return Vector3(avg.x, global_position.y, avg.z)

	return global_position
