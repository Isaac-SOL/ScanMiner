@icon("res://leeklib/icons/Shaker3D.svg")
class_name Shaker3D extends Node3D

enum ShakeAxis { FORWARD, UP, RIGHT, ALL }

@export var target_node: Node3D
@export var follow_position: bool = true
@export var follow_rotation: bool = false
@export var shake_interval: float = 0.035
@export var shake_factor: float = 10
@export var move_speed: float = 20
@export var rotation_speed: float = 20
@export var shake_around_axis: ShakeAxis = ShakeAxis.FORWARD

var shake_tween: Tween
var current_radius: float

@onready var next_shake: float = shake_interval
@onready var base_pos: Vector3 = position
@onready var base_rot: Quaternion = quaternion
@onready var target_position: Vector3 = position

func _process(delta):
	# Move target
	if target_node:
		base_pos = target_node.position
		base_rot = target_node.quaternion
	
	# Apply impulsions
	next_shake -= delta
	while next_shake < 0:
		if shake_around_axis == ShakeAxis.ALL:
			target_position = base_pos + Util.rand_on_sphere(current_radius * shake_factor)
		else:
			var rand_pos := Util.rand_on_circle(current_radius * shake_factor)
			match shake_around_axis:
				ShakeAxis.FORWARD:
					target_position = base_pos + basis * Vector3(rand_pos.x, rand_pos.y, 0)
				ShakeAxis.UP:
					target_position = base_pos + basis * Vector3(rand_pos.x, 0, rand_pos.y)
				ShakeAxis.RIGHT:
					target_position = base_pos + basis * Vector3(0, rand_pos.x, rand_pos.y)
		next_shake += shake_interval
	
	# Move object
	if follow_position:
		position = Util.decayv3(position, target_position, move_speed * delta)
	if follow_rotation:
		quaternion = Util.decayq(quaternion, base_rot, rotation_speed * delta)

func shake(amount: float, duration: float):
	if amount < current_radius: return
	current_radius = amount
	if shake_tween:
		shake_tween.kill()
	shake_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake_tween.tween_property(self, "current_radius", 0, duration).from_current()
