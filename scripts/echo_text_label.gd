class_name EchoTextLabel extends RichTextLabel

@export var fade_time: float = 2.0

var tween: Tween
var target_pos := Vector2.ZERO

func _process(delta: float) -> void:
	position = Util.decayv2(position, target_pos, delta)

func display_anim(txt: String):
	scale = Vector2(2.0, 2.0)
	visible = true
	modulate = Color.TRANSPARENT
	text = txt
	var theta := randf_range(-PI/10, PI/10)
	rotation = -theta
	theta += PI/2
	if randf() < 0.5:
		theta += PI
	var r := randf_range(100, 250)
	position = Vector2(sin(theta), cos(theta)) * r
	tween = replace_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate", Color.WHITE, 2.0).set_ease(Tween.EASE_OUT)

func hide_anim():
	tween = replace_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate", Color.DIM_GRAY, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 1.0).set_ease(Tween.EASE_IN)

func vanish_anim():
	tween = replace_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): visible = false)

func replace_tween() -> Tween:
	if tween:
		tween.kill()
	return create_tween()
