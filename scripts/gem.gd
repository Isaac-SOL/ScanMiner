class_name Gem extends CharacterBody2D

@export var companion: Node2D
@export var max_velocity: float = 200
@export var min_distance: float = 20
@export var max_distance: float = 75

var carrying := false
var moving_to_furnace := false
var target: Vector2
var negative: bool = false
var breaking: bool = false

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	Singletons.main.entering_negative_world.connect(enter_negative_world)
	Singletons.main.exiting_negative_world.connect(exit_negative_world)
	companion = Singletons.companion

func _process(delta: float) -> void:
	if breaking:
		return
	if companion and not moving_to_furnace:
		target = companion.global_position
	if target != Vector2.ZERO:
		var target_vector := target - global_position
		var norm_distance := (target_vector.length() - min_distance) / (max_distance - min_distance)
		if not carrying and not moving_to_furnace and norm_distance < 1.0:
			carrying = true
			Singletons.companion.start_carry_gem(self)
			if Singletons.main.negative_world:
				enter_negative_world()
		if carrying or moving_to_furnace:
			norm_distance = sqrt(clampf(norm_distance, 0, 1))
			var weighted_target_vector := target_vector.normalized() * max_velocity * norm_distance
			velocity = weighted_target_vector
			move_and_slide()
	if moving_to_furnace:
		var coords := Singletons.tilemap.local_to_map(Singletons.tilemap.to_local(global_position))
		if Singletons.tilemap.get_power(coords) == WorldTileMap.ConduitInfo.SOURCE_EMPTY:
			Singletons.tilemap.activate_source_at(coords)
			destroy()

func destroy():
	breaking = true
	var coords := Singletons.tilemap.local_to_map(Singletons.tilemap.to_local(global_position))
	if negative:
		Singletons.tilemap.create_neg_residue(coords)
	else:
		Singletons.tilemap.create_pos_residue(coords)
	%Sprite2D.visible = false
	%Point2D.visible = false
	set_deferred("collision_mask", 0)
	%BreakSound.play()
	%BreakParticles.emitting = true
	await %BreakParticles.finished
	queue_free()

func on_hit():
	if not moving_to_furnace:
		destroy()

func move_to_furnace(pos: Vector2):
	if carrying and not moving_to_furnace:
		target = pos
		collision_mask = 0
		min_distance = 0
		moving_to_furnace = true

func enter_negative_world():
	if carrying and not moving_to_furnace:
		collision_mask = 0
		negative = true

func exit_negative_world():
	if carrying and not moving_to_furnace:
		collision_mask = 1
		negative = false
