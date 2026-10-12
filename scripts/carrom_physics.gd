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
const POCKETS: Array[Vector2] = [Vector2(21, 21), Vector2(659, 21), Vector2(21, 659), Vector2(659, 659)]

static func coin_mass(kind: String) -> float:
	return 2.25 if kind == "striker" else 1.0

static func radius_for(kind: String) -> float:
	if kind == "striker":
		return STRIKER_RADIUS
	if kind == "queen":
		return QUEEN_RADIUS
	return COIN_RADIUS

static func advance(discs: Array, dt: float) -> Array[int]:
	var fallen: Array[int] = []
	# Disc-to-disc impulses and separation. Fixed substeps in the game loop
	# keep the solver stable even on a fast opening break.
	for i in range(discs.size()):
		var a: Dictionary = discs[i]
		if a["pocketed"]:
			continue
		for j in range(i + 1, discs.size()):
			var b: Dictionary = discs[j]
			if b["pocketed"]:
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
				var impulse: float = -(1.0 + COIN_BOUNCE) * normal_speed / total_inv_mass
				a["vel"] -= n * impulse / a["mass"]
				b["vel"] += n * impulse / b["mass"]

	for disc in discs:
		if disc["pocketed"]:
			continue
		var velocity: Vector2 = disc["vel"]
		var speed: float = velocity.length()
		if speed <= MIN_SPEED:
			velocity = Vector2.ZERO
		else:
			velocity = velocity * maxf(0.0, 1.0 - FRICTION * dt / speed)
		var position: Vector2 = disc["pos"] + velocity * dt
		var pocketed_now := false
		for pocket in POCKETS:
			if position.distance_squared_to(pocket) < POCKET_RADIUS * POCKET_RADIUS:
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
			position.x = radius
			velocity.x = absf(velocity.x) * RAIL_BOUNCE
		elif position.x > SURFACE - radius:
			position.x = SURFACE - radius
			velocity.x = -absf(velocity.x) * RAIL_BOUNCE
		if position.y < radius:
			position.y = radius
			velocity.y = absf(velocity.y) * RAIL_BOUNCE
		elif position.y > SURFACE - radius:
			position.y = SURFACE - radius
			velocity.y = -absf(velocity.y) * RAIL_BOUNCE
		disc["pos"] = position
		disc["vel"] = velocity
	return fallen

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
