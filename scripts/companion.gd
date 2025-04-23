class_name Companion extends CharacterBody2D

signal activated

@export var active: bool = false
@export var max_velocity: float = 200
@export var min_distance: float = 50
@export var max_distance: float = 200

var modes: Array[Main.VisionMode] = [Main.VisionMode.NORMAL, Main.VisionMode.XRAY, Main.VisionMode.THERMAL]
var unlocked_modes: Array[bool] = [true, false, false]
var mode_position: int = 0

func _process(delta: float) -> void:
	if active and Singletons.player:
		var target_vector := Singletons.player.global_position - global_position
		var norm_distance := (target_vector.length() - min_distance) / (max_distance - min_distance)
		norm_distance = sqrt(clampf(norm_distance, 0, 1))
		var weighted_target_vector := target_vector.normalized() * max_velocity * norm_distance
		velocity = weighted_target_vector
		move_and_slide()

func activate():
	active = true
	$Sprite2D.modulate = Color.WHITE
	activated.emit()

func add_mode(new_mode: Main.VisionMode):
	unlocked_modes[modes.find(new_mode)] = true
	%PingSprite.visible = true

func on_hit():
	mode_position = (mode_position + 1) % unlocked_modes.size()
	while not unlocked_modes[mode_position]:
		mode_position = (mode_position + 1) % unlocked_modes.size()
	Singletons.main.set_vision(modes[mode_position])
	%PingSprite.visible = false

func enter_negative_world():
	collision_mask = 0

func exit_negative_world():
	collision_mask = 1
