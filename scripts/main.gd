class_name Main extends Node

enum VisionMode { NORMAL, XRAY, THERMAL }

signal entering_negative_world
signal exiting_negative_world

var vision_mode := VisionMode.NORMAL
var has_companion: bool = false
var xray_shader: ShaderMaterial
var negative_world: bool = false
var xray_target_alpha: float = 0.0

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
	Singletons.companion = %Companion
	Singletons.camera = %MainCamera
			
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
	
	# Activate/deactivate xray progressively
	%XRayMixer.modulate.a = Util.decayf(%XRayMixer.modulate.a, xray_target_alpha, 6 * delta)
	%TileMapLayer.get_node("%XRayLayer").modulate.a = %XRayMixer.modulate.a

func set_vision(new_mode: VisionMode):
	vision_mode = new_mode
	if negative_world:
		get_tree().root.get_viewport().canvas_cull_mask = 1
		%XRayMixer.visible = false
		%ThermalScanner.set_active(false)
		%NegativeMixer.visible = true
	else:
		%NegativeMixer.visible = false
		%XRayMixer.visible = true
		match vision_mode:
			VisionMode.NORMAL:
				get_tree().root.get_viewport().canvas_cull_mask = 1
				xray_target_alpha = 0.0
				%ThermalScanner.set_active(false)
			VisionMode.XRAY:
				# get_tree().root.get_viewport().canvas_cull_mask = 1 | 8
				xray_target_alpha = 1.0
				%ThermalScanner.set_active(false)
			VisionMode.THERMAL:
				get_tree().root.get_viewport().canvas_cull_mask = 4
				xray_target_alpha = 0.0
				%ThermalScanner.set_active(true)

func _on_companion_activated() -> void:
	has_companion = true

func upgrade_companion() -> void:
	xray_shader.set_shader_parameter("strength", 1.0)
	xray_shader.set_shader_parameter("screen_edge", 0.6)
	xray_shader.set_shader_parameter("shadow_factor_min", 1.0)
	xray_shader.set_shader_parameter("shadow_factor_max", 2.0)
	%ThermalScanner.upgrade()

func enter_negative_world():
	negative_world = true
	set_vision(vision_mode)
	Singletons.player.enter_negative_world()
	%Companion.enter_negative_world()
	entering_negative_world.emit()
	AudioServer.set_bus_effect_enabled(0, 0, true)

func exit_negative_world():
	negative_world = false
	set_vision(VisionMode.NORMAL)
	Singletons.player.exit_negative_world()
	%Companion.exit_negative_world()
	exiting_negative_world.emit()
	AudioServer.set_bus_effect_enabled(0, 0, false)

func _on_audio_area_body_entered(body: Node2D) -> void:
	if not negative_world:
		AudioServer.set_bus_effect_enabled(0, 0, true)

func _on_audio_area_body_exited(body: Node2D) -> void:
	if not negative_world:
		AudioServer.set_bus_effect_enabled(0, 0, false)
