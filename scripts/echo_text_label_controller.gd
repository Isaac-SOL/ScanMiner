extends Control

@export var fade_time: float = 1.5
@export var stay_time: float = 4.0
@export var min_time_diff: float = 0.5

var labels: Array[EchoTextLabel] = []

func _ready() -> void:
	for child in get_children():
		labels.append(child as EchoTextLabel)

var last_hit_time: int = 0
var displaying: Array = []
var displaying_pos: int = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("act1") and not displaying.is_empty() and Time.get_ticks_msec() - last_hit_time > min_time_diff * 1000:
		last_hit_time = Time.get_ticks_msec()
		displaying_pos += 1
		if displaying_pos < displaying.size():
			display_single_text()
		else:
			displaying = []
			for label in labels:
				label.vanish_anim()

func display_multi_text(txt_multi: Array):
	if displaying.is_empty() and Time.get_ticks_msec() - last_hit_time > min_time_diff * 1000:
		last_hit_time = Time.get_ticks_msec()
		displaying = txt_multi
		displaying_pos = 0
		display_single_text()
		visible = true

func display_single_text():
	labels[displaying_pos].display_anim(displaying[displaying_pos])
	if displaying_pos > 0:
		labels[displaying_pos - 1].hide_anim()
	
