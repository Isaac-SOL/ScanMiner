class_name Companion extends CharacterBody2D

signal activated
signal upgradeable

@export var active: bool = false
@export var max_velocity: float = 200
@export var min_distance: float = 50
@export var max_distance: float = 200

var modes: Array[Main.VisionMode] = [Main.VisionMode.NORMAL, Main.VisionMode.XRAY, Main.VisionMode.THERMAL]
var unlocked_modes: Array[bool] = [true, false, false]
var mode_position: int = 0
var carrying_gem: Gem
var upgraded: bool = false

func _process(delta: float) -> void:
	if active and Singletons.player:
		var target_vector := Singletons.player.global_position - global_position
		var norm_distance := (target_vector.length() - min_distance) / (max_distance - min_distance)
		norm_distance = sqrt(clampf(norm_distance, 0, 1))
		var weighted_target_vector := target_vector.normalized() * max_velocity * norm_distance
		velocity = weighted_target_vector
		move_and_slide()
		
		# Check for super lasers
		if not upgraded:
			var detection_coords := Singletons.tilemap.local_to_map(Singletons.tilemap.to_local(global_position))
			var laser_dir := Singletons.tilemap.get_laser_dir(detection_coords)
			var laser_super := Singletons.tilemap.get_laser_super(detection_coords)
			if laser_dir != Vector2i.ZERO and laser_super:
				upgraded = true
				upgradeable.emit()

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

func is_carrying_gem() -> bool:
	return true if carrying_gem else false

func start_carry_gem(new_gem: Gem):
	if carrying_gem:
		carrying_gem.on_hit()
	carrying_gem = new_gem
