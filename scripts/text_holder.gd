class_name TextHolder extends Node

@export_multiline var texts: Array[String]

func get_text(id: int) -> String:
	return texts[id]
