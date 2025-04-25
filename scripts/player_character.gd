class_name PlayerCharacter extends CharacterBody2D

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

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	var move_vec := get_move_vector() * move_speed
	direction = move_vec
	velocity = move_vec
	move_and_slide()
	next_slash -= delta
	if Input.is_action_just_pressed("act1") and next_slash <= 0.0 and ui_text.displaying.is_empty():
		next_slash = slash_cooldown
		slash(get_global_mouse_position() - global_position)

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

func enter_negative_world():
	collision_mask = 16

func exit_negative_world():
	collision_mask = 1
