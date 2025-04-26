class_name EyeEffect extends Node2D

@export var vibration: float = 1.0

var revealed: bool

func _process(delta: float) -> void:
	var theta := randf() * TAU
	var r := randf() * vibration
	%Sprite2D.position = Vector2(sin(theta), cos(theta)) * r

func reveal():
	if not revealed:
		revealed = true
		vibration *= 7
		var tween := create_tween().set_parallel().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
		tween.tween_property(%Sprite2D, "scale", %Sprite2D.scale * 5, 1.0)
		tween.tween_property(%Sprite2D, "modulate", Color.TRANSPARENT, 1.0)
		tween.chain().tween_callback(func(): visible = false)
