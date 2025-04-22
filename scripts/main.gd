class_name Main extends Node

enum VisionMode { NORMAL, XRAY, THERMAL }

var vision_mode := VisionMode.NORMAL
var has_companion: bool = false
var xray_shader: ShaderMaterial

func _ready() -> void:
	# Hide shadow receiver
	get_tree().root.get_viewport().canvas_cull_mask = 1
	xray_shader = %XRayMixer.material

func _process(delta: float) -> void:
	Singletons.main = self
	Singletons.shaker = %Shaker2D
	Singletons.world = %World
	Singletons.tilemap = %TileMapLayer
	Singletons.player = %PlayerCharacter
			
	#if Input.is_action_just_pressed("act2"):
		#match vision_mode:
			#VisionMode.NORMAL:
				#set_vision(VisionMode.XRAY)
			#VisionMode.XRAY:
				#set_vision(VisionMode.THERMAL)
			#VisionMode.THERMAL:
				#set_vision(VisionMode.NORMAL)
	
	# Update shader with companion position relative to screen
	var companion_pos: Vector2 = %Companion.global_position
	companion_pos -= %Shaker2D.global_position
	companion_pos /= Vector2(640, 360)
	companion_pos += Vector2(0.5, 0.5)
	xray_shader.set_shader_parameter("emitter_position", companion_pos)

func set_vision(new_mode: VisionMode):
	vision_mode = new_mode
	match vision_mode:
		VisionMode.NORMAL:
			get_tree().root.get_viewport().canvas_cull_mask = 1
			%XRayMixer.visible = false
			%ThermalScanner.set_active(false)
		VisionMode.XRAY:
			get_tree().root.get_viewport().canvas_cull_mask = 1 | 8
			%XRayMixer.visible = true
			%ThermalScanner.set_active(false)
		VisionMode.THERMAL:
			get_tree().root.get_viewport().canvas_cull_mask = 4
			%XRayMixer.visible = false
			%ThermalScanner.set_active(true)

func _on_companion_activated() -> void:
	has_companion = true
