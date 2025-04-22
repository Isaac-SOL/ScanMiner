class_name WorldTileMap extends TileMapLayer

signal companion_arrows_set

enum ConduitInfo {
	EMPTY = 0,
	LEFT = 1, DOWN, RIGHT, UP,
	LEFT_P = 5, DOWN_P, RIGHT_P, UP_P,
	SOURCE = 10,
	SOURCE_EMPTY = 11,
	LASER_LEFT = 21, LASER_DOWN, LASER_RIGHT, LASER_UP,
	OPENABLE = 40,
	PRISM = 50
}

signal echo_hit(text: String)

@export var shadow_layer: TileMapLayer
@export var conduit_debug_layer: TileMapLayer
@export var update_debug_layer: bool = false
@export var light_source_parent: Node2D
@export var light_source_object: PackedScene

var hp_grid: Array[Array] = []
var power_grid: Array[Array] = []
var rect_offset: Vector2i
var rect_size: Vector2i
var companion_activated: bool = false

func _ready() -> void:
	rect_offset = get_used_rect().position
	rect_size = get_used_rect().size
	for x in rect_size.x:
		hp_grid.append([] as Array[int])
		power_grid.append([] as Array[ConduitInfo])
		for y in rect_size.y:
			var map_pos := grid_to_map(Vector2i(x, y))
			var data := get_cell_tile_data(map_pos)
			if data != null:
				hp_grid[x].append(data.get_custom_data("hp"))
				power_grid[x].append(data.get_custom_data("conduit") as ConduitInfo)
				if update_debug_layer:
					update_debug_layer_at(map_pos, data.get_custom_data("conduit") as ConduitInfo)
				if data.get_occluder_polygons_count(0) > 0:
					shadow_layer.set_cell(map_pos, 0, Vector2i(2, 4))
				if data.get_custom_data("light"):
					var new_light: PointLight2D = light_source_object.instantiate()
					light_source_parent.add_child(new_light)
					new_light.global_position = to_global(map_to_local(map_pos))
				if data.get_custom_data("fragile"):
					%XRayLayer.set_cell(map_pos, 0, Vector2i(12, 0))
			else:
				hp_grid[x].append(0)
				power_grid[x].append(ConduitInfo.EMPTY)

func _process(delta: float) -> void:
	if not companion_activated:
		if get_cell_atlas_coords(Vector2i(2, 21)) == Vector2i(15, 2) \
		   and get_cell_atlas_coords(Vector2i(8, 21)) == Vector2i(15, 0):
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

func get_power(map_pos: Vector2i) -> ConduitInfo:
	var grid_pos := map_to_grid(map_pos)
	return power_grid[grid_pos.x][grid_pos.y] if coords_in_grid(grid_pos) else ConduitInfo.EMPTY

func set_power(map_pos: Vector2i, power: ConduitInfo):
	var grid_pos := map_to_grid(map_pos)
	assert(coords_in_grid(grid_pos))
	power_grid[grid_pos.x][grid_pos.y] = power
	if update_debug_layer:
		update_debug_layer_at(map_pos, power)

func update_debug_layer_at(coords: Vector2i, power: ConduitInfo):	if update_debug_layer:
	if power in [ConduitInfo.LEFT_P, ConduitInfo.RIGHT_P, ConduitInfo.UP_P, ConduitInfo.DOWN_P]:
		conduit_debug_layer.set_cell(coords, 0, Vector2i(15, 12 + (power as int) - (ConduitInfo.LEFT_P as int)))
	elif power in [ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN]:
		conduit_debug_layer.set_cell(coords, 0, Vector2i(14, 12 + (power as int) - (ConduitInfo.LASER_LEFT as int)))
	else:
		conduit_debug_layer.erase_cell(coords)

func get_temp(map_pos: Vector2i) -> float:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("temp")
	return 0.0

func get_text_id(map_pos: Vector2i) -> int:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("text")
	return 0

func get_conduit_info(map_pos: Vector2i) -> ConduitInfo:
	var data := get_cell_tile_data(map_pos)
	if data != null:
		return data.get_custom_data("conduit") as ConduitInfo
	return ConduitInfo.EMPTY

func get_hit(coords: Vector2i):
	# Destruction
	var hp := get_hp(coords)
	if hp > 0 and hp < 900:
		hp -= 1
		if hp <= 0:
			erase_cell(coords)
			%XRayLayer.erase_cell(coords)
			shadow_layer.erase_cell(coords)
		else:
			set_hp(coords, hp)
		return
	
	# Echo stones
	var text_id := get_text_id(coords) - 1
	if text_id != -1:
		echo_hit.emit(%TextHolder.get_text(text_id))
		return
	
	# Conduits
	var conduit_info := get_conduit_info(coords)
	if conduit_info >= ConduitInfo.LEFT and conduit_info <= ConduitInfo.UP:
		turn_arrow_at(coords, conduit_info)

func turn_arrow_at(coords: Vector2i, arrow_type: ConduitInfo):
	var power := get_power(coords)
	var next_arrow := (arrow_type as int) % 4
	var next_power := ((power as int - ConduitInfo.LEFT_P + 1) % 4) + ConduitInfo.LEFT_P
	if power >= ConduitInfo.LEFT_P and power <= ConduitInfo.UP_P:
		remove_laser_from(coords, arrow_type)
	set_cell(coords, 1, Vector2i(15, next_arrow))
	set_power(coords, next_power)
	conduit_update(coords)

func is_power_incoming(coords: Vector2i) -> bool:
	var incoming := false
	incoming = incoming or get_power(coords + Vector2i.UP) in [ConduitInfo.LASER_DOWN, ConduitInfo.SOURCE]
	incoming = incoming or get_power(coords + Vector2i.DOWN) in [ConduitInfo.LASER_UP, ConduitInfo.SOURCE]
	incoming = incoming or get_power(coords + Vector2i.RIGHT) in [ConduitInfo.LASER_LEFT, ConduitInfo.SOURCE]
	incoming = incoming or get_power(coords + Vector2i.LEFT) in [ConduitInfo.LASER_RIGHT, ConduitInfo.SOURCE]
	return incoming

func power_to_dir(power: ConduitInfo) -> Vector2i:
	match power:
		ConduitInfo.LEFT, ConduitInfo.LEFT_P, ConduitInfo.LASER_LEFT:
			return Vector2i.LEFT
		ConduitInfo.RIGHT, ConduitInfo.RIGHT_P, ConduitInfo.LASER_RIGHT:
			return Vector2i.RIGHT
		ConduitInfo.UP, ConduitInfo.UP_P, ConduitInfo.LASER_UP:
			return Vector2i.UP
		ConduitInfo.DOWN, ConduitInfo.DOWN_P, ConduitInfo.LASER_DOWN:
			return Vector2i.DOWN
	return Vector2i.ZERO

func power_to_laser(power: ConduitInfo) -> ConduitInfo:
	match power:
		ConduitInfo.LEFT, ConduitInfo.LEFT_P, ConduitInfo.LASER_LEFT:
			return ConduitInfo.LASER_LEFT
		ConduitInfo.RIGHT, ConduitInfo.RIGHT_P, ConduitInfo.LASER_RIGHT:
			return ConduitInfo.LASER_RIGHT
		ConduitInfo.UP, ConduitInfo.UP_P, ConduitInfo.LASER_UP:
			return ConduitInfo.LASER_UP
		ConduitInfo.DOWN, ConduitInfo.DOWN_P, ConduitInfo.LASER_DOWN:
			return ConduitInfo.LASER_DOWN
	return ConduitInfo.EMPTY

func power_up_arrow(power: ConduitInfo) -> ConduitInfo:
	assert(power in [ConduitInfo.LEFT, ConduitInfo.RIGHT, ConduitInfo.UP, ConduitInfo.DOWN])
	return (power as int + 4) as ConduitInfo

func power_down_arrow(power: ConduitInfo) -> ConduitInfo:
	assert(power in [ConduitInfo.LEFT_P, ConduitInfo.RIGHT_P, ConduitInfo.UP_P, ConduitInfo.DOWN_P])
	return (power as int - 4) as ConduitInfo

func laser_sides(power: ConduitInfo) -> Array[Vector2i]:
	match power:
		ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN:
			return [Vector2i.LEFT, Vector2i.RIGHT]
		ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT:
			return [Vector2i.UP, Vector2i.DOWN]
	return []

func send_laser_from(coords: Vector2i, power: ConduitInfo):
	var laser_dir := power_to_dir(power)
	var next_laser_pos := coords + laser_dir
	var laser_to_set := power_to_laser(power)
	while get_power(next_laser_pos) == ConduitInfo.EMPTY and coords_in_map(next_laser_pos):
		set_power(next_laser_pos, laser_to_set)
		next_laser_pos += laser_dir
	if get_power(next_laser_pos) == laser_to_set:
		return
	conduit_update(next_laser_pos)

func remove_laser_from(coords: Vector2i, power: ConduitInfo):
	var laser_dir := power_to_dir(power)
	var next_laser_pos := coords + laser_dir
	var laser_to_erase := power_to_laser(power)
	var sides_to_check := laser_sides(laser_to_erase)
	print("START REMOVE LASER")
	while get_power(next_laser_pos) == laser_to_erase:
		set_power(next_laser_pos, ConduitInfo.EMPTY)
		for side in sides_to_check:
			conduit_update(next_laser_pos + side)
		print(next_laser_pos)
		next_laser_pos += laser_dir
	conduit_update(next_laser_pos)

func open_door(coords: Vector2i):
	erase_cell(coords)
	%XRayLayer.erase_cell(coords)
	shadow_layer.erase_cell(coords)
	set_power(coords, ConduitInfo.EMPTY)
	for neigh in get_surrounding_cells(coords):
		if get_power(neigh) == ConduitInfo.OPENABLE:
			open_door(neigh)
		else:
			conduit_update(neigh)

func conduit_update(coords: Vector2i):
	var power := get_power(coords)
	match power:
		# No contraption
		ConduitInfo.EMPTY:
			pass
		
		# Unpowered Arrow
		ConduitInfo.LEFT, ConduitInfo.DOWN, ConduitInfo.RIGHT, ConduitInfo.UP:
			if is_power_incoming(coords):  # Power Up
				set_power(coords, power_up_arrow(power))
				send_laser_from(coords, power)
		
		# Powered Arrow
		ConduitInfo.LEFT_P, ConduitInfo.DOWN_P, ConduitInfo.RIGHT_P, ConduitInfo.UP_P:
			if is_power_incoming(coords): # Still powered, recheck that laser was sent
				if get_power(coords + power_to_dir(power)) == ConduitInfo.EMPTY:
					send_laser_from(coords, power)
			else:  # Power Down
				set_power(coords, power_down_arrow(power))
				remove_laser_from(coords, power)
		
		# Laser
		ConduitInfo.LASER_LEFT, ConduitInfo.LASER_RIGHT, ConduitInfo.LASER_UP, ConduitInfo.LASER_DOWN:
			# Should not need to recheck its source
			# Only recheck front laser
			if get_power(coords + power_to_dir(power)) != power:
				send_laser_from(coords, power)
		
		# Doors
		ConduitInfo.OPENABLE:
			if is_power_incoming(coords):
				open_door(coords)
