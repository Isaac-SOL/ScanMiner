class_name PointCloud extends Node2D

@export var point2d: PackedScene
@export var pool_size: int = 100

var pool: Array[Point2D] = []
var used: Array[bool] = []

func _ready() -> void:
	for i in range(pool_size):
		var new_point: Point2D = point2d.instantiate()
		add_child(new_point)
		new_point.visible = false
		pool.append(new_point)
		used.append(false)
		new_point.visibility_changed.connect(_on_point_visibility_changed.bind(i))

func _on_point_visibility_changed(id: int):
	if not pool[id].visible:
		used[id] = false

func spawn_point_at(global_pos: Vector2, temp: float = 1.0):
	var i: int = 0
	while used[i] and i < pool_size:
		i += 1
	if i < pool_size:
		pool[i].global_position = global_pos
		pool[i].start_anim(temp)
		used[i] = true
