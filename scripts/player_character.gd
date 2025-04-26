class_name PlayerCharacter extends CharacterBody2D

enum ParticleType { DIRT = 0, STONE, ROCK, METAL, CRYSTAL }

@export var move_speed: float = 10
@export var slash_object: PackedScene
@export var neg_slash_object: PackedScene
@export var slash_distance: float = 20
@export var slash_cooldown: float = 0.5
@export var ui_text: EchoTextLabel

var direction: Vector2
var controller_mode: bool = false
var touchpad_mode: bool = false
var next_slash: float = 0.0
var pioche_target_rot: float = PI / 4
var smooth_mouse_position: Vector2 = Vector2.ZERO
var particles: Array[Array]
var particles_ping_pong: Array[int] = [0, 0, 0, 0, 0]
var particles_lock: Array[bool] = [false, false, false, false, false]
var impact_played: bool = false

func _ready() -> void:
	particles = [
		[%DirtParticles1, %DirtParticles2],
		[%StoneParticles1, %StoneParticles2],
		[%RockParticles1, %RockParticles2],
		[%MetalParticles1, %MetalParticles2],
		[%CrystalParticles1, %CrystalParticles2]
	]

func _process(delta: float) -> void:
	smooth_mouse_position = Util.decayv2(smooth_mouse_position, get_global_mouse_position(), 15 * delta)
	look_at(smooth_mouse_position)
	var move_vec := get_move_vector() * move_speed
	direction = move_vec
	velocity = move_vec
	move_and_slide()
	next_slash -= delta
	if Input.is_action_just_pressed("act1") and next_slash <= 0.0 and ui_text.displaying.is_empty():
		next_slash = slash_cooldown
		particles_lock = [false, false, false, false, false]
		impact_played = false
		slash(get_global_mouse_position() - global_position)
	# Mouvement pioche
	%PiochePivot.rotation = Util.decayf(%PiochePivot.rotation, pioche_target_rot, 20 * delta)

func get_move_vector() -> Vector2:
	if touchpad_mode and not controller_mode:
		return Vector2(0, 0)
		#return Singletons.joystick_touch_pad.get_joystick_left().normalized()
	else:
		var move_vec := Vector2.ZERO
		move_vec.y -= Input.get_action_strength("up")
		move_vec.y += Input.get_action_strength("down")
		move_vec.x -= Input.get_action_strength("left")
		move_vec.x += Input.get_action_strength("right")
		move_vec = move_vec.normalized()
		return move_vec

func slash(dir: Vector2):
	var new_slash: Node2D = neg_slash_object.instantiate() if Singletons.main.negative_world else slash_object.instantiate()
	Singletons.world.add_child(new_slash)
	new_slash.global_position = global_position + dir.normalized() * slash_distance
	new_slash.global_rotation = global_rotation
	pioche_target_rot = -pioche_target_rot

func emit_particles(type: ParticleType, half: bool):
	var idx := type as int
	if not particles_lock[idx]:
		var p: GPUParticles2D = particles[idx][particles_ping_pong[idx]]
		p.amount_ratio = 0.5 if half else 1.0
		p.restart()
		p.emitting = true
		particles_ping_pong[idx] = 1 - particles_ping_pong[idx]
		particles_lock[idx] = true

func impact():
	if not impact_played:
		Singletons.shaker.shake(0.6, 0.2)
		%MiningAudio.play()
		Util.hitstop(self, 0.1, 0.05)
		impact_played = true

func enter_negative_world():
	collision_mask = 16

func exit_negative_world():
	collision_mask = 1

func _on_steps_timer_timeout() -> void:
	if velocity != Vector2.ZERO:
		%StepsAudio.play()
		%Sprite2D.frame = (%Sprite2D.frame + 1) % %Sprite2D.vframes
