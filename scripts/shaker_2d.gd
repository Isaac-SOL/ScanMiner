class_name Shaker2D extends Node2D

@export var target_node: Node2D
@export var shake_interval: float = 0.035
@export var shake_factor: float = 10
@export var move_speed: float = 20

var shake_tween: Tween
var current_radius: float

@onready var next_shake: float = shake_interval
@onready var base_pos: Vector2 = position
@onready var target_position: Vector2 = position

func _process(delta):
	# Move to target
	if target_node:
		base_pos = target_node.position
	# Apply impulsions
	next_shake -= delta
	while next_shake < 0:
		target_position = base_pos + Util.rand_on_circle(current_radius * shake_factor)
		next_shake += shake_interval
	# Move object
	position = Util.decayv2(position, target_position, move_speed * delta)

func shake(amount: float, duration: float):
	if amount < current_radius: return
	current_radius = amount
	if shake_tween:
		shake_tween.kill()
	shake_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake_tween.tween_property(self, "current_radius", 0, duration).from_current()
