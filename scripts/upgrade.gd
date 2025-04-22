class_name Upgrade extends Area2D

signal activated

@export var added_mode: Main.VisionMode
@export var companion: Node2D
@export var max_velocity: float = 100
@export var min_distance: float = 0
@export var max_distance: float = 50

func _process(delta: float) -> void:
	if companion:
		var target_vector := companion.global_position - global_position
		var norm_distance := (target_vector.length() - min_distance) / (max_distance - min_distance)
		if norm_distance > 1.0:
			return
		norm_distance = sqrt(clampf(norm_distance, 0, 1))
		var weighted_target_vector := target_vector.normalized() * max_velocity * norm_distance
		position += weighted_target_vector * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Companion:
		body.add_mode(added_mode)
		queue_free()
