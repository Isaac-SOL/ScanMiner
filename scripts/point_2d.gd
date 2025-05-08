class_name Point2D extends Sprite2D

@export var lifetime: float = 0.8
@export var modulate_over_time: Curve
@export var temp_gradient: Gradient
@export var speed: float = 20.0

var time: float = 100.0
var direction: Vector2 = Vector2.ZERO

func start_anim(temp: float = 1.0, dir: Vector2 = Vector2.ZERO):
	direction = dir
	time = 0.0
	if temp > 1.1:
		modulate = Color.from_hsv(randf(), 1.0, 1.0)
	else:
		if temp < 1.0:
			temp = clampf(temp + randf_range(-0.05, 0.05), 0.0, 1.0)
		modulate = temp_gradient.sample(temp)
	visible = true

func _process(delta: float) -> void:
	if visible:
		if time >= lifetime:
			visible = false
			return
		time += delta
		modulate.a = modulate_over_time.sample(time / lifetime)
		position = position + direction * speed * delta
