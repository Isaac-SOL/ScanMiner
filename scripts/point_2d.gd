class_name Point2D extends Sprite2D

@export var lifetime: float = 0.8
@export var modulate_over_time: Curve
@export var temp_gradient: Gradient

var time: float = 100.0

func start_anim(temp: float = 1.0):
	time = 0.0
	modulate = temp_gradient.sample(temp)
	visible = true

func _process(delta: float) -> void:
	if visible:
		if time >= lifetime:
			visible = false
			return
		time += delta
		modulate.a = modulate_over_time.sample(time / lifetime)
