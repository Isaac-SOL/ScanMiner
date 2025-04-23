class_name NegativeLayer extends TileMapLayer

signal hit(coords: Vector2i)

func get_hit(coords: Vector2i):
	hit.emit(coords)
