class_name NegativePortal extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerCharacter:
		if Singletons.main.negative_world:
			Singletons.main.exit_negative_world()
		else:
			Singletons.main.enter_negative_world()
		%PortalAudio.play()
