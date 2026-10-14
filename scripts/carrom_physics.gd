extends RefCounted
class_name CarromPhysics

# All distances are expressed in board-local pixels. 680 px represents
# approximately 74 cm of playing surface. This intentionally independent
# simulation is shared by human and computer turns.
const SURFACE: float = 680.0
const COIN_RADIUS: float = 13.88
const QUEEN_RADIUS: float = 14.00
const STRIKER_RADIUS: float = 18.98
const POCKET_RADIUS: float = 23.0
const FRICTION: float = 360.0
const RAIL_BOUNCE: float = 0.78
const COIN_BOUNCE: float = 0.92
const MIN_SPEED: float = 9.0
# Duboo is modeled as a larger relative surface: its carrommen are much
# smaller compared with the table, and the shooter is an oversized HOLLOW ring.
# These values are original play-tuning choices, not measured club constants.
const DUBOO_COIN_RADIUS: float = 8.8
const DUBOO_QUEEN_RADIUS: float = 9.0
const DUBOO_STRIKER_RADIUS: float = 29.0
const DUBOO_RING_INNER_RADIUS: float = 19.7
const DUBOO_POCKET_RADIUS: float = 15.5
const DUBOO_COIN_FRICTION: float = 112.0
const DUBOO_RING_FRICTION: float = 137.0
const DUBOO_RAIL_BOUNCE: float = 0.77
const DUBOO_RING_RAIL_BOUNCE: float = 0.72
const DUBOO_COIN_BOUNCE: float = 0.91
const DUBOO_RING_BOUNCE: float = 0.57
const DUBOO_MIN_SPEED: float = 7.5
const DUBOO_STRIKER_MASS: float = 3.15
const POCKETS: Array[Vector2] = [Vector2(21, 21), Vector2(659, 21), Vector2(21, 659), Vector2(659, 659)]

static func coin_mass(kind: String, duboo: bool = false) -> float:
	return (DUBOO_STRIKER_MASS if duboo else 2.25) if kind == "striker" else 1.0

static func radius_for(kind: String, duboo: bool = false) -> float:
	if kind == "striker":
		return DUBOO_STRIKER_RADIUS if duboo else STRIKER_RADIUS
	if kind == "queen":
		return DUBOO_QUEEN_RADIUS if duboo else QUEEN_RADIUS
	return DUBOO_COIN_RADIUS if duboo else COIN_RADIUS

# Every impact operates on ring geometry in Duboo: a smaller counter can sit in
# the empty centre without colliding with an imaginary solid disc. Classic uses
# the untouched ordinary-disc solver below.
static func _resolve_ring_contact(ring: Dictionary, coin: Dictionary, feedback: Array) -> void:
	var offset: Vector2 = coin["pos"] - ring["pos"]
	var dist: float = maxf(0.0001, offset.length())
	var n: Vector2 = offset / dist
	var cr: float = float(coin["radius"])
	var outside_limit: float = float(ring["radius"]) + cr
	var inside_limit: float = DUBOO_RING_INNER_RADIUS - cr
	# Track whether a coin is already inside the open aperture. It can move
	# freely there until its edge reaches the inner wall.
	var inside: bool = bool(coin.get("ring_inside", false))
	# Prefer the nearest physical surface if a fast shot crosses a fraction
	# of the ring wall between substeps, rather than snapping a piece across
	# the entire acrylic band.
	if dist < (inside_limit + outside_limit) * 0.5:
		inside = true
	elif dist >= (inside_limit + outside_limit) * 0.5:
		inside = false
	coin["ring_inside"] = inside
	var normal: Vector2 = n
	var penetration := 0.0
	if inside:
		if dist <= inside_limit:
			return
		penetration = dist - inside_limit
		normal = -n  # Inner wall pushes coins back toward the open centre.
	else:
		if dist >= outside_limit:
			return
		penetration = outside_limit - dist
	var inverse_ring: float = 1.0 / float(ring["mass"])
	var inverse_coin: float = 1.0 / float(coin["mass"])
	var inverse_total := inverse_ring + inverse_coin
	ring["pos"] -= normal * penetration * inverse_ring / inverse_total
	coin["pos"] += normal * penetration * inverse_coin / inverse_total
	var normal_speed: float = (coin["vel"] - ring["vel"]).dot(normal)
	if normal_speed < 0.0:
		if -normal_speed > 65.0:
			feedback.append({"type": "collision", "speed": -normal_speed})
		var impulse: float = -(1.0 + DUBOO_RING_BOUNCE) * normal_speed / inverse_total
		ring["vel"] -= normal * impulse * inverse_ring
		coin["vel"] += normal * impulse * inverse_coin

static func advance(discs: Array, dt: float, duboo: bool = false, feedback: Array = []) -> Array[int]:
	var rail_bounce := DUBOO_RAIL_BOUNCE if duboo else RAIL_BOUNCE
	var coin_bounce := DUBOO_COIN_BOUNCE if duboo else COIN_BOUNCE
	var stop_speed := DUBOO_MIN_SPEED if duboo else MIN_SPEED
	var fallen: Array[int] = []
	for i in range(discs.size()):
		var a: Dictionary = discs[i]
		if a["pocketed"]:
			continue
		for j in range(i + 1, discs.size()):
			var b: Dictionary = discs[j]
			if b["pocketed"]:
				continue
			if duboo and (a["kind"] == "striker" or b["kind"] == "striker"):
				var ring: Dictionary = a if a["kind"] == "striker" else b
				var coin: Dictionary = b if a["kind"] == "striker" else a
				_resolve_ring_contact(ring, coin, feedback)
				continue
			var offset: Vector2 = b["pos"] - a["pos"]
			var radii: float = a["radius"] + b["radius"]
			var dist_sq: float = offset.length_squared()
			if dist_sq >= radii * radii:
				continue
			var dist: float = sqrt(maxf(dist_sq, 0.0001))
			var n: Vector2 = offset / dist if dist > 0.001 else Vector2.RIGHT
			var overlap: float = radii - dist
			var total_inv_mass: float = 1.0 / a["mass"] + 1.0 / b["mass"]
			a["pos"] -= n * overlap * (1.0 / a["mass"]) / total_inv_mass
			b["pos"] += n * overlap * (1.0 / b["mass"]) / total_inv_mass
			var normal_speed: float = (b["vel"] - a["vel"]).dot(n)
			if normal_speed < 0.0:
				if -normal_speed > (65.0 if duboo else 55.0):
					feedback.append({"type": "collision", "speed": -normal_speed})
				var impulse: float = -(1.0 + coin_bounce) * normal_speed / total_inv_mass
				a["vel"] -= n * impulse / a["mass"]
				b["vel"] += n * impulse / b["mass"]
	for disc in discs:
		if disc["pocketed"]:
			continue
		var friction: float = (DUBOO_RING_FRICTION if disc["kind"] == "striker" else DUBOO_COIN_FRICTION) if duboo else FRICTION
		var bounce: float = DUBOO_RING_RAIL_BOUNCE if duboo and disc["kind"] == "striker" else rail_bounce
		var velocity: Vector2 = disc["vel"]
		var speed: float = velocity.length()
		if speed <= stop_speed:
			velocity = Vector2.ZERO
		else:
			velocity = velocity * maxf(0.0, 1.0 - friction * dt / speed)
		var position: Vector2 = disc["pos"] + velocity * dt
		var pocketed_now := false
		# The oversize Duboo ring cannot fall through a counter-sized pocket.
		if not (duboo and disc["kind"] == "striker"):
			var hole_r: float = DUBOO_POCKET_RADIUS if duboo else POCKET_RADIUS
			for pocket in POCKETS:
				if position.distance_squared_to(pocket) < hole_r * hole_r:
					disc["pocketed"] = true
					disc["pos"] = position
					disc["vel"] = Vector2.ZERO
					fallen.append(disc["id"])
					pocketed_now = true
					break
		if pocketed_now:
			continue
		var radius: float = disc["radius"]
		if position.x < radius:
			if velocity.x < (-110.0 if duboo else -95.0):
				feedback.append({"type": "rail", "speed": -velocity.x})
			position.x = radius
			velocity.x = absf(velocity.x) * bounce
		elif position.x > SURFACE - radius:
			if velocity.x > (110.0 if duboo else 95.0):
				feedback.append({"type": "rail", "speed": velocity.x})
			position.x = SURFACE - radius
			velocity.x = -absf(velocity.x) * bounce
		if position.y < radius:
			if velocity.y < (-110.0 if duboo else -95.0):
				feedback.append({"type": "rail", "speed": -velocity.y})
			position.y = radius
			velocity.y = absf(velocity.y) * bounce
		elif position.y > SURFACE - radius:
			if velocity.y > (110.0 if duboo else 95.0):
				feedback.append({"type": "rail", "speed": velocity.y})
			position.y = SURFACE - radius
			velocity.y = -absf(velocity.y) * bounce
		disc["pos"] = position
		disc["vel"] = velocity
	return fallen

# Predict only the first striker-to-counter impact. The striker's travel is
# solved analytically until contact, then the existing impulse solver is used
# for the actual impact. This avoids an expensive full-board shot simulation
# whenever the player nudges the aim or adjusts power.
static func _preview_ray_entry(origin: Vector2, direction: Vector2, center: Vector2, radius: float) -> float:
	var toward: Vector2 = center - origin
	var projected: float = toward.dot(direction)
	if projected < 0.0:
		return INF
	var cross_squared: float = toward.length_squared() - projected * projected
	var radius_squared: float = radius * radius
	if cross_squared >= radius_squared:
		return INF
	return maxf(0.0, projected - sqrt(maxf(0.0, radius_squared - cross_squared)))

static func _preview_rail_distance(origin: Vector2, direction: Vector2, radius: float) -> float:
	var distance: float = INF
	if direction.x > 0.00001:
		distance = minf(distance, (SURFACE - radius - origin.x) / direction.x)
	elif direction.x < -0.00001:
		distance = minf(distance, (radius - origin.x) / direction.x)
	if direction.y > 0.00001:
		distance = minf(distance, (SURFACE - radius - origin.y) / direction.y)
	elif direction.y < -0.00001:
		distance = minf(distance, (radius - origin.y) / direction.y)
	return maxf(0.0, distance)

static func predict_first_contact(discs: Array, shot_direction: Vector2, shot_speed: float, duboo: bool = false) -> Dictionary:
	if shot_direction.length_squared() < 0.5 or shot_speed <= 0.0:
		return {}
	var striker: Dictionary = {}
	for piece in discs:
		if piece["kind"] == "striker" and not piece["pocketed"]:
			striker = piece
			break
	if striker.is_empty():
		return {}
	var direction: Vector2 = shot_direction.normalized()
	var origin: Vector2 = striker["pos"]
	var striker_radius: float = float(striker["radius"])
	var striker_friction: float = DUBOO_RING_FRICTION if duboo else FRICTION
	var stop_speed: float = DUBOO_MIN_SPEED if duboo else MIN_SPEED
	var max_roll: float = maxf(0.0, (shot_speed * shot_speed - stop_speed * stop_speed) / (2.0 * striker_friction))
	var nearest: float = minf(max_roll, _preview_rail_distance(origin, direction, striker_radius))
	# In Classic, the striker can fall into a corner pocket before it hits a coin.
	if not duboo:
		for pocket in POCKETS:
			nearest = minf(nearest, _preview_ray_entry(origin, direction, pocket, POCKET_RADIUS))
	var target: Dictionary = {}
	for piece in discs:
		if piece["pocketed"] or piece["kind"] == "striker":
			continue
		var reach: float = striker_radius + float(piece["radius"])
		var entry: float = _preview_ray_entry(origin, direction, piece["pos"], reach)
		if entry < nearest:
			nearest = entry
			target = piece
	if target.is_empty():
		return {}
	# Very soft tangencies do not give a useful visible prediction.
	var impact_speed: float = sqrt(maxf(0.0, shot_speed * shot_speed - 2.0 * striker_friction * nearest))
	if impact_speed < 40.0:
		return {}

	# Begin a couple of pixels before contact and ask the REAL collision solver
	# for the outgoing velocity. Nothing in the live match state is modified.
	var test: Array = discs.duplicate(true)
	var test_striker: Dictionary = {}
	var test_target: Dictionary = {}
	for test_piece in test:
		if test_piece["kind"] == "striker":
			test_striker = test_piece
		elif int(test_piece["id"]) == int(target["id"]):
			test_target = test_piece
	if test_striker.is_empty() or test_target.is_empty():
		return {}
	var before_impact: float = maxf(0.0, nearest - 1.25)
	test_striker["pos"] = origin + direction * before_impact
	test_striker["vel"] = direction * sqrt(maxf(0.0, shot_speed * shot_speed - 2.0 * striker_friction * before_impact))
	var step_time: float = 1.0 / (240.0 if duboo else 120.0)
	var outgoing_velocity := Vector2.ZERO
	for _step in range(36):
		advance(test, step_time, duboo)
		outgoing_velocity = test_target["vel"]
		if outgoing_velocity.length_squared() > 16.0:
			break
		if test_striker["pocketed"] or (test_striker["vel"] as Vector2).length_squared() < stop_speed * stop_speed:
			return {}
	if outgoing_velocity.length_squared() <= 16.0:
		return {}

	# With constant sliding friction, v^2 / (2a) is the travel distance.
	# Stop this ONE straight arrow at the first obstruction, rail or pocket;
	# later rebounds and chain reactions are intentionally not previewed.
	var travel_direction: Vector2 = outgoing_velocity.normalized()
	var coin_speed: float = outgoing_velocity.length()
	var coin_friction: float = DUBOO_COIN_FRICTION if duboo else FRICTION
	var coin_radius: float = float(target["radius"])
	var impact_position: Vector2 = test_target["pos"]
	var travel: float = maxf(0.0, (coin_speed * coin_speed - stop_speed * stop_speed) / (2.0 * coin_friction))
	travel = minf(travel, _preview_rail_distance(impact_position, travel_direction, coin_radius))
	for other in discs:
		if other["pocketed"] or other["kind"] == "striker" or int(other["id"]) == int(target["id"]):
			continue
		travel = minf(travel, _preview_ray_entry(impact_position, travel_direction, other["pos"], coin_radius + float(other["radius"])))
	if travel <= coin_radius + 15.0:
		return {}
	var pocket_radius: float = DUBOO_POCKET_RADIUS if duboo else POCKET_RADIUS
	for pocket in POCKETS:
		travel = minf(travel, _preview_ray_entry(impact_position, travel_direction, pocket, pocket_radius))
	if travel <= coin_radius + 15.0:
		return {}
	return {"origin": target["pos"], "direction": travel_direction, "distance": travel, "radius": coin_radius}

static func is_still(discs: Array) -> bool:
	for disc in discs:
		if not disc["pocketed"] and disc["vel"].length_squared() > 100.0:
			return false
	return true

static func find_open_position(discs: Array, desired: Vector2, r: float, ignore_id: int = -1) -> Vector2:
	var mid: Vector2 = Vector2(SURFACE / 2.0, SURFACE / 2.0)
	for ring in range(0, 32):
		var count: int = maxi(1, ring * 10)
		for k in range(count):
			var angle: float = TAU * float(k) / float(count)
			var pos: Vector2 = desired + Vector2.from_angle(angle) * float(ring) * 7.5
			pos.x = clampf(pos.x, r + 9.0, SURFACE - r - 9.0)
			pos.y = clampf(pos.y, r + 9.0, SURFACE - r - 9.0)
			var open := true
			for other in discs:
				if other["pocketed"] or other["id"] == ignore_id:
					continue
				if pos.distance_squared_to(other["pos"]) < pow(r + other["radius"] + 1.7, 2):
					open = false
					break
			if open:
				return pos
	return mid
