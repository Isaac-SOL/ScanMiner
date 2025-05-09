class_name Companion extends CharacterBody2D

signal activated
signal upgradeable

@export var active: bool = false
@export var max_velocity: float = 200
@export var min_distance: float = 50
@export var max_distance: float = 200
@export var location_info: RichTextLabel

var modes: Array[Main.VisionMode] = [Main.VisionMode.NORMAL, Main.VisionMode.XRAY, Main.VisionMode.THERMAL]
var unlocked_modes: Array[bool] = [true, false, false]
var mode_position: int = 0
var carrying_gem: Gem
var upgraded: bool = false
var mode_sounds: Array[AudioStreamPlayer]

const CARDINALS: Array[String] = ["E", "SE", "S", "SO", "O", "NO", "N", "NE"]
const MODE_NAMES: Array[String] = ["VIS", "RADIO", "IR"]

func _ready() -> void:
	mode_sounds = [%Turnoff, %RadioStart, %ThermalStart]

func _process(delta: float) -> void:
	if active and Singletons.player:
		var target_vector := Singletons.player.global_position - global_position
		var norm_distance := (target_vector.length() - min_distance) / (max_distance - min_distance)
		norm_distance = sqrt(clampf(norm_distance, 0, 1))
		var weighted_target_vector := target_vector.normalized() * max_velocity * norm_distance
		velocity = weighted_target_vector
		move_and_slide()
		
		# Update location info
		var angle := fposmod(global_position.angle() + PI/8, TAU)
		var norm_angle := floori((angle / TAU) * 8) % 8
		var card := CARDINALS[norm_angle]
		var dist_blocks := global_position.length() / 32.0
		if dist_blocks <= 7:
			card = "C.S."
		var dist_blocks_str := str(floorf(dist_blocks * 10.0) / 10.0)
		if Singletons.main.negative_world:
			dist_blocks_str = "-" + dist_blocks_str + " ?"
		location_info.text = card + "\n" + "D : " + dist_blocks_str + "\nF : " + MODE_NAMES[mode_position]
		
		# Check for super lasers
		if not upgraded:
			var detection_coords := Singletons.tilemap.local_to_map(Singletons.tilemap.to_local(global_position))
			var laser_dir := Singletons.tilemap.get_laser_dir(detection_coords)
			var laser_super := Singletons.tilemap.get_laser_super(detection_coords)
			if laser_dir != Vector2i.ZERO and laser_super:
				upgraded = true
				upgradeable.emit()
				%LevelupParticles.emitting = true
				%BaseSprite.visible = false
				%AdvSprite.visible = true
				%LaserAudio.play()
				await %LevelupParticles.finished
				%LevelupAudio.play()
				play_levelup_anim()

func activate():
	active = true
	%BaseSprite.modulate = Color.WHITE
	%LevelupParticles.emitting = true
	%LaserAudio.play()
	activated.emit()
	await %LevelupParticles.finished
	%LevelupAudio.play()
	location_info.visible = true

func add_mode(new_mode: Main.VisionMode):
	unlocked_modes[modes.find(new_mode)] = true
	%PingSprite.visible = true
	%LevelupParticles.emitting = true
	%LaserAudio.play()
	await %LevelupParticles.finished
	%LevelupAudio.play()
	play_levelup_anim()

func on_hit():
	mode_position = (mode_position + 1) % unlocked_modes.size()
	while not unlocked_modes[mode_position]:
		mode_position = (mode_position + 1) % unlocked_modes.size()
	Singletons.main.set_vision(modes[mode_position])
	mode_sounds[mode_position].play()
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

func play_levelup_anim():
	%LevelupAnim.visible = true
	%LevelupAnim.play("levelup")
	await %LevelupAnim.animation_finished
	%LevelupAnim.visible = false
