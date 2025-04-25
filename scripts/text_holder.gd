class_name TextHolder extends Node

@export_multiline var texts: Array[String]

var texts_json: Dictionary

func _ready() -> void:
	var res: JSON = load("res://assets/text.json")
	texts_json = res.data

func get_text(id: int) -> String:
	return texts[id]

func get_text_json(id: String) -> Array:
	return texts_json[id]
