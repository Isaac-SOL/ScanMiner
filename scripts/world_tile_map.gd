class_name WorldTileMap extends TileMapLayer

signal companion_arrows_set

enum ConduitInfo {
	EMPTY = 0,
	LEFT = 1, DOWN, RIGHT, UP,
	LEFT_P = 5, DOWN_P, RIGHT_P, UP_P,
	SOURCE = 10,
	SOURCE_EMPTY = 11,
	CRYSTALLIZER = 15,
	LIGHT_OFF = 16, LIGHT_ON,
	LASER_LEFT = 21, LASER_DOWN, LASER_RIGHT, LASER_UP,
	LASER_LEFT_S = 31, LASER_DOWN_S, LASER_RIGHT_S, LASER_UP_S,
	LEFT_PS = 35, DOWN_PS, RIGHT_PS, UP_PS,
	OPENABLE = 40,
	PRISM = 60
}

signal echo_hit(text: Array)

@export var shadow_layer: TileMapLayer
@export var update_debug_layer: bool = false
@export var light_source_parent: Node2D
@export var light_source_object: PackedScene
@export var gem_object: PackedScene
@export var arrow_audio_object: PackedScene
@export var audio_parent: Node2D
@export var furnace_particles_object: PackedScene
@export var glowstone_particles_object: PackedScene
@export var redstone_particles_object: PackedScene
@export var arrow_particles_object: PackedScene
@export var eye_particle_object: PackedScene
@export var furnace_audio_object: PackedScene
@export var door_audio_object: PackedScene
@export var light_audio_object: PackedScene

var hp_grid: Array[Array] = []
var neg_hp_grid: Array[Array] = []
var power_grid: Array[Array] = []
var rect_offset: Vector2i
var rect_size: Vector2i
var companion_activated: bool = false
var crystallizer_pos: Vector2i
var last_gem: Gem
var lights: Dictionary[Vector2i, PointLight2D] = {}
var crown_door_opened: bool = false
var audios: Dictionary[Vector2i, Node2D] = {}
var particles: Dictionary[Vector2i, Node2D] = {}

const NORMAL_ARROW_LEFT_POS := Vector2i(15, 2)
const NORMAL_ARROW_RIGHT_POS := Vector2i(15, 0)
const SHADOW_OCCLUDER_POS := Vector2i(2, 4)
const XRAY_FRAGILE_POS := Vector2i(12, 0)
const XRAY_SOURCE_POS := Vector2i(12, 1)
const NEGATIVE_BREAKABLE_POS := Vector2i(12, 0)
const NEGATIVE_UNBREAKABLE_POS := Vector2i(7, 0)
const CROWN_LOCK_POSITIONS: Array[Vector2i] = [Vector2i(-45, -2), Vector2i(-45, -4), Vector2i(-45, -6), Vector2i(-45, -8)]
const CROWN_DOOR_POSITIONS: Array[Vector2i] = [Vector2i(-43, 1), Vector2i(-43, 2), Vector2i(-43, 3)]
const CROWN_BUTTON_POSITIONS: Array[Vector2i] = [Vector2i(-42, -2), Vector2i(-42, -4), Vector2i(-42, -6), Vector2i(-42, -8)]

func create_particles(scene: PackedScene, map_pos: Vector2i) -> Node2D:
	var new_particles: Node2D = scene.instantiate()
	add_child(new_particles)
	new_particles.position = map_to_local(map_pos)
	particles[map_pos] = new_particles
	return new_particles

func create_audio(scene: PackedScene, map_pos: Vector2i) -> Node2D:
	var new_audio: Node2D = scene.instantiate()
	audio_parent.add_child(new_audio)
	new_audio.global_position = to_global(map_to_local(map_pos))
	audios[map_pos] = new_audio
	return new_audio

func create_light(scene: PackedScene, map_pos: Vector2i) -> PointLight2D:
	var new_light: PointLight2D = scene.instantiate()
	light_source_parent.add_child(new_light)
	new_light.global_position = to_global(map_to_local(map_pos))
	lights[map_pos] = new_light
	return new_light

func _ready() -> void:
	rect_offset = get_used_rect().position
	rect_size = get_used_rect().size
	for x in rect_size.x:
		hp_grid.append([] as Array[int])
		neg_hp_grid.append([] as Array[int])
		power_grid.append([] as Array[ConduitInfo])
		for y in rect_size.y:
			var map_pos := grid_to_map(Vector2i(x, y))
			var data := get_cell_tile_data(map_pos)
			if data != null:
				hp_grid[x].append(data.get_custom_data("hp"))
				power_grid[x].append(data.get_custom_data("conduit") as ConduitInfo)
				if power_grid[x][y] == ConduitInfo.CRYSTALLIZER:
					crystallizer_pos = map_pos
				if power_grid[x][y] >= ConduitInfo.LEFT and power_grid[x][y] <= ConduitInfo.UP:
					create_audio(arrow_audio_object, map_pos)
					create_particles(arrow_particles_object, map_pos)
				if power_grid[x][y] in [ConduitInfo.SOURCE, ConduitInfo.SOURCE_EMPTY]:
					var new_particles := create_particles(furnace_particles_object, map_pos)
					var furnace_audio := create_audio(furnace_audio_object, map_pos)
					if power_grid[x][y] == ConduitInfo.SOURCE_EMPTY:
						new_particles.emitting = false
						furnace_audio.stop()
				if power_grid[x][y] == ConduitInfo.OPENABLE:
					create_audio(door_audio_object, map_pos)
				if update_debug_layer:
					update_debug_layer_at(map_pos, data.get_custom_data("conduit") as ConduitInfo)
				if data.get_occluder_polygons_count(0) > 0:
					shadow_layer.set_cell(map_pos, 0, SHADOW_OCCLUDER_POS)
				if not data.get_custom_data("text").is_empty() and data.get_collision_polygons_count(0) > 0:
					create_particles(eye_particle_object, map_pos)
				if data.get_custom_data("light"):
					var new_light := create_light(light_source_object, map_pos)
					if power_grid[x][y] in [ConduitInfo.LIGHT_OFF, ConduitInfo.LIGHT_ON] or get_cell_atlas_coords(map_pos) == Vector2i(0, 10):
						new_light.scale *= 1.5
						var new_particles := create_particles(redstone_particles_object, map_pos)
						var light_audio := create_audio(light_audio_object, map_pos)
						if power_grid[x][y] == ConduitInfo.LIGHT_OFF:
							new_light.visible = false
							new_particles.emitting = false
							light_audio.stop()
					if get_cell_atlas_coords(map_pos) == Vector2i(4, 0):
						create_particles(glowstone_particles_object, map_pos)
				if data.get_custom_data("fragile"):
					%XRayLayer.set_cell(map_pos, 0, XRAY_FRAGILE_POS)
				if data.get_custom_data("hidden_source"):
					%XRayLayer.set_cell(map_pos, 0, XRAY_SOURCE_POS)
				if data.get_custom_data("bifull") \
				   or data.get_collision_polygons_count(0) == 0 and not data.get_custom_data("text").is_empty():
					# Bedrock or negative echo rock
					%NegativeLayer.set_cell(map_pos, 0, NEGATIVE_UNBREAKABLE_POS)
					neg_hp_grid[x].append(1000)
				else:
					neg_hp_grid[x].append(0)
			else:
				hp_grid[x].append(0)
				neg_hp_grid[x].append(1)
				power_grid[x].append(ConduitInfo.EMPTY)
				%NegativeLayer.set_cell(map_pos, 0, NEGATIVE_BREAKABLE_POS)

func _process(delta: float) -> void:
	if not companion_activated:
		if get_cell_atlas_coords(Vector2i(2, 32)) == NORMAL_ARROW_LEFT_POS \
		   and get_cell_atlas_coords(Vector2i(8, 32)) == NORMAL_ARROW_RIGHT_POS:
			companion_arrows_set.emit()
			companion_activated = true

func map_to_grid(map_pos: Vector2i) -> Vector2i:
	return map_pos - rect_offset

func grid_to_map(grid_pos: Vector2i) -> Vector2i:
	return grid_pos + rect_offset

func coords_in_grid(grid_pos: Vector2i) -> bool:
	return 0 <= grid_pos.x and grid_pos.x < rect_size.x \
		   and 0 <= grid_pos.y and grid_pos.y < rect_size.y

func coords_in_map(map_pos: Vector2i) -> bool:
	return coords_in_grid(map_to_grid(map_pos))

func get_hp(map_pos: Vector2i) -> int:
	var grid_pos := map_to_grid(map_pos)
	return hp_grid[grid_pos.x][grid_pos.y] if coords_in_grid(grid_pos) else 0

func set_hp(map_pos: Vector2i, hp: int):
	var grid_pos := map_to_grid(map_pos)
	assert(coords_in_grid(grid_pos))
	hp_grid[grid_pos.x][grid_pos.y] = hp

func get_neg_hp(map_pos: Vector2i) -> int:
	var grid_pos := map_to_grid(map_pos)
	return neg_hp_grid[grid_pos.x][grid_pos.y] if coords_in_grid(grid_pos) else 0

func set_neg_hp(map_pos: Vector2i, hp: int):
	var grid_pos := map_to_grid(map_pos)
	assert(coords_in_grid(grid_pos))
	neg_hp_grid[grid_pos.x][grid_pos.y] = hp

func get_power(map_pos: Vector2i) -> ConduitInfo:
	var grid_pos := map_to_grid(map_pos)
	return power_grid[grid_pos.x][grid_pos.y] if coords_in_grid(grid_pos) else ConduitInfo.EMPTY

func set_power(map_pos: Vector2i, power: ConduitInfo):
	var grid_pos := map_to_grid(map_pos)
	assert(coords_in_grid(grid_pos))
	power_grid[grid_pos.x][grid_pos.y] = power
	if update_debug_layer:
		update_debug_layer_at(map_pos, power)

func get_laser_dir(map_pos: Vector2i) -> Vector2i:
	var data: TileData = %ConduitDebugLayer.get_cell_tile_data(map_pos)
	return data.get_custom_data("laser_dir") if data else Vector2i.ZERO

func get_laser_super(map_pos: Vector2i) -> bool:
	var data: TileData = %ConduitDebugLayer.get_cell_tile_data(map_pos)
	return data.get_custom_data("super") if data else false

func get_audio(map_pos: Vector2i) -> Node2D:
	return audios[map_pos]

func update_debug_layer_at(coords: Vector2i, power: ConduitInfo):	if update_debug_layer:
	match power:
		ConduitInfo.LEFT_P, ConduitInfo.RIGHT_P, ConduitInfo.UP_P, ConduitInfo.DOWN_P:
			%ConduitDebugLayer.set_cell(coords, 0, Vector2i(15, 12 + (power as int) - (ConduitInfo.LEFT_P as int)))
		ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN:
			%ConduitDebugLayer.set_cell(coords, 0, Vector2i(14, 12 + (power as int) - (ConduitInfo.LASER_LEFT as int)))
		ConduitInfo.LEFT_PS, ConduitInfo.RIGHT_PS, ConduitInfo.UP_PS, ConduitInfo.DOWN_PS:
			%ConduitDebugLayer.set_cell(coords, 0, Vector2i(15, 8 + (power as int) - (ConduitInfo.LEFT_PS as int)))
		ConduitInfo.LASER_LEFT_S, ConduitInfo.LASER_RIGHT_S, ConduitInfo.LASER_UP_S, ConduitInfo.LASER_DOWN_S:
			%ConduitDebugLayer.set_cell(coords, 0, Vector2i(14, 8 + (power as int) - (ConduitInfo.LASER_LEFT_S as int)))
		_:
			%ConduitDebugLayer.erase_cell(coords)

func get_temp(map_pos: Vector2i) -> float:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("temp")
	return 0.0

func get_text_id(map_pos: Vector2i) -> String:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("text")
	return ""

func get_conduit_info(map_pos: Vector2i) -> ConduitInfo:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("conduit") as ConduitInfo
	return ConduitInfo.EMPTY

func get_particle_type(map_pos: Vector2i) -> PlayerCharacter.ParticleType:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("particle_type") as PlayerCharacter.ParticleType
	return PlayerCharacter.ParticleType.DIRT

func get_mining_sound_type(map_pos: Vector2i) -> PlayerCharacter.MiningSoundType:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("mining_type") as PlayerCharacter.MiningSoundType
	return PlayerCharacter.MiningSoundType.DIRT

func get_footstep_type(map_pos: Vector2i) -> PlayerCharacter.FootstepSoundType:
	var data: TileData = %BGLayer.get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("type") as PlayerCharacter.FootstepSoundType
	return PlayerCharacter.FootstepSoundType.DIRT

func erase_cell_multilayer(coords):
	erase_cell(coords)
	%XRayLayer.erase_cell(coords)
	shadow_layer.erase_cell(coords)
	%NegativeLayer.set_cell(coords, 0, NEGATIVE_BREAKABLE_POS)
	set_neg_hp(coords, 1)
	if get_power(coords) == ConduitInfo.PRISM:
		set_power(coords, ConduitInfo.EMPTY)
		for neighbor in get_surrounding_cells(coords):
			conduit_update(neighbor)

func get_hit(coords: Vector2i):
	# Destruction
	var hp := get_hp(coords)
	if hp > 0:
		Singletons.player.impact(get_mining_sound_type(coords))
		if hp < 900:
			hp -= 1
			set_hp(coords, hp)
			if hp <= 0:
				Singletons.player.emit_particles(get_particle_type(coords), false)
				erase_cell_multilayer(coords)
			else:
				Singletons.player.emit_particles(get_particle_type(coords), true)
			return
	
	# Echo stones
	var data: = get_cell_tile_data(coords)
	if data and data.get_collision_polygons_count(0) > 0:
		var text_id := get_text_id(coords)
		if not text_id.is_empty():
			echo_hit.emit(%TextHolder.get_text_json(text_id))
			particles[coords].reveal()
			return
	
	# Conduits
	var conduit_info := get_conduit_info(coords)
	if conduit_info >= ConduitInfo.LEFT and conduit_info <= ConduitInfo.UP:
		turn_arrow_at(coords, conduit_info)
		return
	
	# Empty sources
	if conduit_info == ConduitInfo.SOURCE_EMPTY and Singletons.companion.is_carrying_gem():
		var glob_coords := to_global(map_to_local(coords))
		Singletons.companion.carrying_gem.move_to_furnace(glob_coords)
	
	# Buttons
	if coords in CROWN_BUTTON_POSITIONS:
		var idx := CROWN_BUTTON_POSITIONS.find(coords)
		turn_arrow_at(CROWN_LOCK_POSITIONS[idx], get_conduit_info(CROWN_LOCK_POSITIONS[idx]))
		check_crown_lock()

func _on_negative_layer_hit(coords: Vector2i) -> void:
	# Destruction
	var hp := get_neg_hp(coords)
	if hp > 0 and hp < 900:
		hp -= 1
		if hp <= 0:
			%NegativeLayer.erase_cell(coords)
			shadow_layer.set_cell(coords, 0, SHADOW_OCCLUDER_POS)
			set_cell(coords, 1, Vector2i.ZERO)  # Dirt
			set_hp(coords, 1)
		else:
			set_neg_hp(coords, hp)
	
	# Echo stones
	if get_cell_tile_data(coords).get_collision_polygons_count(0) == 0:
		var text_id := get_text_id(coords)
		if not text_id.is_empty():
			echo_hit.emit(%TextHolder.get_text_json(text_id))
			return

func check_crown_lock():
	if not crown_door_opened:
		for lock_arrow_coords in CROWN_LOCK_POSITIONS:
			if get_conduit_info(lock_arrow_coords) != ConduitInfo.LEFT:
				return
		for door_coords in CROWN_DOOR_POSITIONS:
			erase_cell_multilayer(door_coords)
		crown_door_opened = true

func create_pos_residue(coords: Vector2i):
	if not get_cell_tile_data(coords):
		set_cell(coords, 1, Vector2i(9, 0))

func create_neg_residue(coords: Vector2i, retry: bool = true):
	# Note: bug when creating right next to an arrow
	if get_hp(coords) < 900:
		set_cell(coords, 1, Vector2i(8, 0))
		set_hp(coords, 1)
		%XRayLayer.erase_cell(coords)
		shadow_layer.erase_cell(coords)
		set_power(coords, ConduitInfo.PRISM)
		for neighbor in get_surrounding_cells(coords):
			conduit_update(neighbor)

func turn_arrow_at(coords: Vector2i, arrow_type: ConduitInfo):
	var power := get_power(coords)
	var next_arrow := (arrow_type as int) % 4
	if (power >= ConduitInfo.LEFT_P and power <= ConduitInfo.UP_P) or (power >= ConduitInfo.LEFT_PS and power <= ConduitInfo.UP_PS):
		remove_laser_from(coords, arrow_type)
	set_cell(coords, 1, Vector2i(15, next_arrow))
	if is_super(power):
		var next_super := ((power as int - ConduitInfo.LEFT_PS + 1) % 4) + ConduitInfo.LEFT_PS
		set_power(coords, next_super)
	else:
		var next_power := ((power as int - ConduitInfo.LEFT_P + 1) % 4) + ConduitInfo.LEFT_P
		set_power(coords, next_power)
	get_audio(coords).play_turn()
	conduit_update(coords)

func is_power_incoming(coords: Vector2i) -> bool:
	var incoming := false
	incoming = incoming or get_power(coords + Vector2i.UP) in [ConduitInfo.LASER_DOWN, ConduitInfo.SOURCE]
	incoming = incoming or get_power(coords + Vector2i.DOWN) in [ConduitInfo.LASER_UP, ConduitInfo.SOURCE]
	incoming = incoming or get_power(coords + Vector2i.RIGHT) in [ConduitInfo.LASER_LEFT, ConduitInfo.SOURCE]
	incoming = incoming or get_power(coords + Vector2i.LEFT) in [ConduitInfo.LASER_RIGHT, ConduitInfo.SOURCE]
	return incoming or is_super_power_incoming(coords)

func is_super_power_incoming(coords: Vector2i) -> bool:
	var incoming := false
	incoming = incoming or get_power(coords + Vector2i.UP) == ConduitInfo.LASER_DOWN_S
	incoming = incoming or get_power(coords + Vector2i.DOWN) == ConduitInfo.LASER_UP_S
	incoming = incoming or get_power(coords + Vector2i.RIGHT) == ConduitInfo.LASER_LEFT_S
	incoming = incoming or get_power(coords + Vector2i.LEFT) == ConduitInfo.LASER_RIGHT_S
	return incoming

func power_to_dir(power: ConduitInfo) -> Vector2i:
	match power:
		ConduitInfo.LEFT, ConduitInfo.LEFT_P, ConduitInfo.LASER_LEFT, ConduitInfo.LASER_LEFT_S, ConduitInfo.LEFT_PS:
			return Vector2i.LEFT
		ConduitInfo.RIGHT, ConduitInfo.RIGHT_P, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_RIGHT_S, ConduitInfo.RIGHT_PS:
			return Vector2i.RIGHT
		ConduitInfo.UP, ConduitInfo.UP_P, ConduitInfo.LASER_UP, ConduitInfo.LASER_UP_S, ConduitInfo.UP_PS:
			return Vector2i.UP
		ConduitInfo.DOWN, ConduitInfo.DOWN_P, ConduitInfo.LASER_DOWN, ConduitInfo.LASER_DOWN_S, ConduitInfo.DOWN_PS:
			return Vector2i.DOWN
	return Vector2i.ZERO

func power_to_laser(power: ConduitInfo, sup: bool) -> ConduitInfo:
	match power:
		ConduitInfo.LEFT, ConduitInfo.LEFT_P, ConduitInfo.LASER_LEFT, ConduitInfo.LASER_LEFT_S, ConduitInfo.LEFT_PS:
			return ConduitInfo.LASER_LEFT_S if sup else ConduitInfo.LASER_LEFT
		ConduitInfo.RIGHT, ConduitInfo.RIGHT_P, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_RIGHT_S, ConduitInfo.RIGHT_PS:
			return ConduitInfo.LASER_RIGHT_S if sup else ConduitInfo.LASER_RIGHT
		ConduitInfo.UP, ConduitInfo.UP_P, ConduitInfo.LASER_UP, ConduitInfo.LASER_UP_S, ConduitInfo.UP_PS:
			return ConduitInfo.LASER_UP_S if sup else ConduitInfo.LASER_UP
		ConduitInfo.DOWN, ConduitInfo.DOWN_P, ConduitInfo.LASER_DOWN, ConduitInfo.LASER_DOWN_S, ConduitInfo.DOWN_PS:
			return ConduitInfo.LASER_DOWN_S if sup else ConduitInfo.LASER_DOWN
	return ConduitInfo.EMPTY

func power_up_arrow(power: ConduitInfo, sup: bool) -> ConduitInfo:
	assert(power in [ConduitInfo.LEFT, ConduitInfo.RIGHT, ConduitInfo.UP, ConduitInfo.DOWN])
	return (power as int + (34 if sup else 4)) as ConduitInfo

func power_down_arrow(power: ConduitInfo, sup: bool) -> ConduitInfo:
	if sup:
		assert(power in [ConduitInfo.LEFT_PS, ConduitInfo.RIGHT_PS, ConduitInfo.UP_PS, ConduitInfo.DOWN_PS])
		return (power as int - 34) as ConduitInfo
	else:
		assert(power in [ConduitInfo.LEFT_P, ConduitInfo.RIGHT_P, ConduitInfo.UP_P, ConduitInfo.DOWN_P])
		return (power as int - 4) as ConduitInfo

func super_laser(power: ConduitInfo) -> ConduitInfo:
	assert(power in [ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN])
	return (power as int + 10) as ConduitInfo

func infra_laser(power: ConduitInfo) -> ConduitInfo:
	assert(power in [ConduitInfo.LASER_LEFT_S, ConduitInfo.LASER_RIGHT_S, ConduitInfo.LASER_UP_S, ConduitInfo.LASER_DOWN_S])
	return (power as int - 10) as ConduitInfo

func laser_sides(power: ConduitInfo) -> Array[Vector2i]:
	match power:
		ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN, ConduitInfo.LASER_UP_S, ConduitInfo.LASER_DOWN_S:
			return [Vector2i.LEFT, Vector2i.RIGHT]
		ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_LEFT_S, ConduitInfo.LASER_RIGHT_S:
			return [Vector2i.UP, Vector2i.DOWN]
	return []

func is_super(power: ConduitInfo) -> bool:
	return power in [
		ConduitInfo.LASER_LEFT_S, ConduitInfo.LASER_DOWN_S, ConduitInfo.LASER_RIGHT_S, ConduitInfo.LASER_UP_S,
		ConduitInfo.LEFT_PS, ConduitInfo.RIGHT_PS, ConduitInfo.UP_PS, ConduitInfo.DOWN_PS
	]

func send_laser_from(coords: Vector2i, power: ConduitInfo, sup: bool):
	var laser_dir := power_to_dir(power)
	var next_laser_pos := coords + laser_dir
	var laser_to_set := power_to_laser(power, sup)
	var laser_can_remove := infra_laser(laser_to_set) if sup else super_laser(laser_to_set)
	while get_power(next_laser_pos) in [ConduitInfo.EMPTY, laser_can_remove] and coords_in_map(next_laser_pos):
		set_power(next_laser_pos, laser_to_set)
		next_laser_pos += laser_dir
	if get_power(next_laser_pos) == laser_to_set:
		return
	conduit_update(next_laser_pos)

func remove_laser_from(coords: Vector2i, power: ConduitInfo):
	var laser_dir := power_to_dir(power)
	var next_laser_pos := coords + laser_dir
	var laser_to_erase := power_to_laser(power, false)
	var sides_to_check := laser_sides(laser_to_erase)
	while get_power(next_laser_pos) in [laser_to_erase, super_laser(laser_to_erase)]:
		set_power(next_laser_pos, ConduitInfo.EMPTY)
		for side in sides_to_check:
			conduit_update(next_laser_pos + side)
		next_laser_pos += laser_dir
	conduit_update(next_laser_pos)

func open_door(coords: Vector2i):
	erase_cell_multilayer(coords)
	set_power(coords, ConduitInfo.EMPTY)
	for neigh in get_surrounding_cells(coords):
		if get_power(neigh) == ConduitInfo.OPENABLE:
			open_door(neigh)
		else:
			conduit_update(neigh)

func activate_source_at(coords: Vector2i):
	set_cell(coords, 1, Vector2i(13, 0))
	%NegativeLayer.erase_cell(coords)
	%XRayLayer.erase_cell(coords)
	set_power(coords, ConduitInfo.SOURCE)
	particles[coords].emitting = true
	audios[coords].play()
	for neighbor in get_surrounding_cells(coords):
		conduit_update(neighbor)

func conduit_update(coords: Vector2i):
	var power := get_power(coords)
	match power:
		# No contraption
		ConduitInfo.EMPTY:
			pass
		
		# Unpowered Arrow
		ConduitInfo.LEFT, ConduitInfo.DOWN, ConduitInfo.RIGHT, ConduitInfo.UP:
			var sup := is_super_power_incoming(coords)
			if is_power_incoming(coords):  # Power Up
				set_power(coords, power_up_arrow(power, sup))
				send_laser_from(coords, power, sup)
				get_audio(coords).play_powerup()
				particles[coords].emitting = true
		
		# Powered Arrow
		ConduitInfo.LEFT_P, ConduitInfo.DOWN_P, ConduitInfo.RIGHT_P, ConduitInfo.UP_P:
			if is_super_power_incoming(coords):  # Upgrade to super power
				set_power(coords, power_up_arrow(power_down_arrow(power, false), true))
				if get_power(coords + power_to_dir(power)) in [ConduitInfo.EMPTY, power_to_laser(power, false)]:
					send_laser_from(coords, power, true)
			elif is_power_incoming(coords):  # Still powered, recheck that laser was sent
				if get_power(coords + power_to_dir(power)) in [ConduitInfo.EMPTY, super_laser(power_to_laser(power, false))]:
					send_laser_from(coords, power, false)
			else:  # Power Down
				set_power(coords, power_down_arrow(power, false))
				remove_laser_from(coords, power)
		
		# Super Powered Arrow
		ConduitInfo.LEFT_PS, ConduitInfo.DOWN_PS, ConduitInfo.RIGHT_PS, ConduitInfo.UP_PS:
			if is_super_power_incoming(coords):  # Still super powered, recheck that laser was sent
				if get_power(coords + power_to_dir(power)) in [ConduitInfo.EMPTY, power_to_laser(power, false)]:
					send_laser_from(coords, power, true)
			elif is_power_incoming(coords):  # Downgrade to normal power
				set_power(coords, power_up_arrow(power_down_arrow(power, true), false))
				if get_power(coords + power_to_dir(power)) in [ConduitInfo.EMPTY, super_laser(power_to_laser(power, false))]:
					send_laser_from(coords, power, false)
			else:  # Power Down
				set_power(coords, power_down_arrow(power, true))
				remove_laser_from(coords, power)
		
		# Laser
		ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN,\
		ConduitInfo.LASER_LEFT_S, ConduitInfo.LASER_RIGHT_S, ConduitInfo.LASER_UP_S, ConduitInfo.LASER_DOWN_S:
			# Should not need to recheck its source
			# Only recheck front laser
			if get_power(coords + power_to_dir(power)) != power:
				send_laser_from(coords, power, is_super(power))
		
		# Doors
		ConduitInfo.OPENABLE:
			if is_power_incoming(coords):
				open_door(coords)
				audios[coords].play()
		
		# Lights
		ConduitInfo.LIGHT_OFF:
			if is_power_incoming(coords):
				set_cell(coords, 1, Vector2i(13, 4))
				set_power(coords, ConduitInfo.LIGHT_ON)
				lights[coords].visible = true
				particles[coords].emitting = true
				audios[coords].play()
		ConduitInfo.LIGHT_ON:
			if not is_power_incoming(coords):
				set_cell(coords, 1, Vector2i(13, 3))
				set_power(coords, ConduitInfo.LIGHT_OFF)
				lights[coords].visible = false
				particles[coords].emitting = false
				audios[coords].stop()
		
		# Prism
		ConduitInfo.PRISM:
			# Recheck all 4 directions
			for laser in [ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN]:
				var outgoing_dir = power_to_dir(laser)
				var laser_s = super_laser(laser)
				if get_power(coords + outgoing_dir) in [laser, ConduitInfo.EMPTY]:
					if get_power(coords - outgoing_dir) in [laser, laser_s, ConduitInfo.SOURCE]:
						send_laser_from(coords, laser_s, true)
				elif get_power(coords + outgoing_dir) == laser_s:
					if get_power(coords - outgoing_dir) not in [laser, laser_s, ConduitInfo.SOURCE]:
						remove_laser_from(coords, laser_s)
		
		# Crystallizer
		ConduitInfo.CRYSTALLIZER:
			call_deferred("create_crystal")

func create_crystal():
	if not last_gem and is_power_incoming(crystallizer_pos):
		last_gem = gem_object.instantiate()
		add_sibling(last_gem)
		last_gem.global_position = to_global(map_to_local(crystallizer_pos))

func _on_crystallizer_timer_timeout() -> void:
	call_deferred("create_crystal")
