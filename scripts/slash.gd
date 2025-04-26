class_name Slash extends Area2D

@export var lifetime: float = 0.2

var scan_points: Array[Vector2]

func _ready() -> void:
	for point in %ScanPoints.get_children():
		scan_points.append(point.position)

func _process(delta: float) -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		var coords := get_hit_coordinates(body)
		if not coords.is_empty():
			for coord in coords:
				body.get_hit(coord)

func get_hit_coordinates(tile_map: TileMapLayer) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for point in scan_points:
		var point_global := to_global(point)
		var coord := tile_map.local_to_map(tile_map.to_local(point_global))
		if coord not in coords:
			coords.append(coord)
	return coords

func _on_companion_detector_body_entered(body: Node2D) -> void:
	if body is Companion:
		body.on_hit()
	if body is Gem:
		body.on_hit()
