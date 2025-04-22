class_name EchoTextLabel extends RichTextLabel

@export var fade_time: float = 2.0
@export var stay_time: float = 5.0
@export var min_time_diff: float = 3.0

var last_hit_time: int = 0
var tween: Tween

func display_text(txt: String):
	if Time.get_ticks_msec() - last_hit_time > min_time_diff * 1000:
		last_hit_time = Time.get_ticks_msec()
		text = txt
		if tween != null:
			tween.kill()
		tween = create_tween().set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "modulate", Color.WHITE, fade_time).set_ease(Tween.EASE_IN)
		tween.tween_interval(stay_time)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_time).set_ease(Tween.EASE_OUT)
