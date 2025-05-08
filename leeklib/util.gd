class_name Util

static func decay(a, b, d: float):
	return b + (a - b) * exp(-d)

static func decayf(a: float, b: float, d: float) -> float:
	return b + (a - b) * exp(-d)

static func decayv2(a: Vector2, b: Vector2, d: float) -> Vector2:
	return b + (a - b) * exp(-d)

static func decayv3(a: Vector3, b: Vector3, d: float) -> Vector3:
	return b + (a - b) * exp(-d)

static func decayq(a: Quaternion, b: Quaternion, d: float) -> Quaternion:
	return b + (a - b) * exp(-d)

static func clamp_angle(angle: float, custom_center: float = 0) -> float:
	angle -= custom_center
	if angle > PI:
		angle = fmod(angle + PI, TAU) - PI
	elif angle < -PI:
		angle = fmod(angle - PI, TAU) + PI
	return angle + custom_center

static func rand_on_circle(radius: float) -> Vector2:
	var angle: float = randf_range(0, TAU)
	return Vector2(sin(angle), cos(angle)) * radius

## Not uniform (clumped in center)
static func rand_in_circle(min_radius: float, max_radius: float) -> Vector2:
	var r: float = randf_range(min_radius, max_radius)
	return rand_on_circle(r)

## Uniform but randomly more expensive
static func rand_in_circle_uniform(min_radius: float, max_radius: float) -> Vector2:
	var res := Vector2.ONE * max_radius * 2
	while res.length() > max_radius or min_radius > res.length():
		res = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	return res

static func rand_on_sphere(radius: float) -> Vector3:
	var res := Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1))
	if res == Vector3.ZERO:
		return Vector3.UP
	return res.normalized() * radius

## Not uniform (clumped in center)
static func rand_in_sphere(min_radius: float, max_radius: float) -> Vector3:
	var r := randf_range(min_radius, max_radius)
	return rand_on_sphere(r)

## Uniform but randomly more expensive
static func rand_in_sphere_uniform(min_radius: float, max_radius: float) -> Vector3:
	var res := Vector3.ONE * max_radius * 2
	while res.length() > max_radius or min_radius > res.length():
		res = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	return res

static func hitstop(source: Node, secs: float, amount: float = 0.1):
	var prev_scale := Engine.time_scale
	Engine.time_scale = amount
	await source.get_tree().create_timer(secs, true, false, true).timeout
	if Engine.time_scale == amount:
		Engine.time_scale = prev_scale

static func on_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")

static func on_web() -> bool:
	return OS.has_feature("web")
