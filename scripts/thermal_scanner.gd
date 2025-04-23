class_name thermal_scanner extends Node2D

@export var active: bool = false
@export var interval: float = 0.02
@export var point_cloud: PointCloud
@export var laser_detection_distance: float = 200.0
@export var laser_checks: int = 2
@export var tilemap: WorldTileMap

var next_scan: float = 0.0

func _physics_process(delta: float) -> void:
	if active:
		next_scan -= delta
		while next_scan <= 0.0:
			next_scan += interval
			var theta := randf_range(0.0, TAU)
			
			# Surfaces
			var raycast_result := raycast_direction(theta)
			if not raycast_result.is_empty():
				var temp_check: Vector2 = raycast_result.position + Vector2(0, 0.01).rotated(theta)
				var coords := Singletons.tilemap.local_to_map(Singletons.tilemap.to_local(temp_check))
				var temp := Singletons.tilemap.get_temp(coords)
				point_cloud.spawn_point_at(raycast_result.position, temp)
			
			# Lasers
			for i in range(laser_checks):
				var dist := randf_range(0.0, laser_detection_distance)
				var detection_point_global = Vector2(cos(theta), sin(theta)) * dist + global_position
				var detection_coords = tilemap.local_to_map(tilemap.to_local(detection_point_global))
				var laser_dir = tilemap.get_laser_dir(detection_coords)
				if laser_dir != Vector2i.ZERO:
					var cell_center_local = tilemap.map_to_local(detection_coords)
					var cell_start_local = (cell_center_local + tilemap.map_to_local(detection_coords - laser_dir)) / 2.0
					point_cloud.spawn_point_at(tilemap.to_global(cell_start_local), 1.0, laser_dir)

func raycast_direction(angle: float) -> Dictionary:
	var space_rid = get_world_2d().space
	var space_state := PhysicsServer2D.space_get_direct_state(space_rid)
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 1000).rotated(angle), 1)
	var result := space_state.intersect_ray(query)
	return result

func set_active(a: bool):
	active = a
