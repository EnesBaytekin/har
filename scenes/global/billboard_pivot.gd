extends Node3D

## Bu Node3D'yi Y ekseninde kameraya döndürür (billboard).
## Child sprite'ları da beraber döner, tek bir pivot'tan döndüğü için
## tüm sprite'lar mükemmel hizalanır.

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	# Kameranın dünya Y'sindeki yönü (sprite'tan kameraya)
	var dir := cam.global_position - global_position
	dir.y = 0
	if dir.length_squared() < 0.001:
		return
	# Y'de sadece döndür
	look_at(global_position + dir, Vector3.UP)
