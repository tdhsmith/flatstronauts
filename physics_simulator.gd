class_name PhysicsSimulator
extends Node2D

# how strong is gravity; unit would be canvas_pixel^3/(pixel_mass*tick^2)
@export var gravitational_constant: float = 9.8
# whether to apply the "tiered" model, where forces apply unidirectionally when
# masses are of different overall tiers
@export var use_tiered_physics: bool = true
# ratio that bodies of the exact same tier affect each other; this can be
# reduced to help prevent e.g. planets from interacting too much compared to
# following an orbit around a star
@export_range(0, 1) var same_tier_effect: float = 1.0

@export var show_debug_lines: bool = true

# the size of the current scene's "playable area"
@export var playable_area: Vector2 = Vector2(1200, 800)
# whether a Body leaving the playable area should be held to its bounds
@export var clamp_all_bodies: bool = true

# array tracking all of the Body nodes in the scene
var bodies: Array[Body] = []
# dictionary that stratifies the Body arrays by their MassTier
var bodies_by_tier: Dictionary[Body.MassTier, Array] = {}

func sort_bodies_into_tiers() -> void:
	for tier in Body.MassTier.values():
		bodies_by_tier[tier] = bodies.filter(func (b: Body): return b.massTier == tier)

static func v32 (v: Vector3) -> Vector2:
	return Vector2(v.x, v.y)

func find_all_body_descendants() -> Array[Body]:
	var body_nodes = find_children("*", "Body", true)
	var out: Array[Body] = []
	# this might be overly defensive: I'm not yet sure if the string "Body" in
	# find_children will truly only return Body nodes. In any case, the static
	# typing was getting mad anyway
	for node in body_nodes:
		if node is Body:
			out.push_back(node)
	return out

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make the physics process fire earlier than default. Since the simulator is
	# currently expected to be the root and _physics_process fires in pre-trav
	# order, this wouldn't typically matter, but I do it simply to express that
	# this node is designed to calculate global forces FIRST for all children
	# and then those children can apply said forces to themselves.
	process_physics_priority = -5
	# get all initial bodies
	bodies = find_all_body_descendants()
	var psa = PackedStringArray(bodies.map(func (b: Body): return b.name))
	print("bodies: ", ",".join(psa))
	sort_bodies_into_tiers()

static func apply_grav(b: Body, force_scalar: float, dir: Vector2) -> void:
	var scaled = Vector3(dir[0] * force_scalar, dir[1] * force_scalar, 0)
	b.f_gravity += scaled

func _physics_process(_delta: float) -> void:
	# note that forces should not take delta into account, since they will be
	# scaled by it when they are *applied*
	
	# nodes don't automatically redraw themselves, so we help the debug drawer
	# here. TODO reconsider this management? That class could just be queueing
	# itself and this is unnecessary interaction.
	if show_debug_lines && %DebugDrawings != null:
		%DebugDrawings.queue_redraw()
	
	# reset all gravity
	for b in bodies:
		b.f_gravity = Vector3(0, 0, 0)
	
	# determine gravity between every pair of bodies
	for i in range(bodies.size()):
		var b1 = bodies[i]
		for j in range(i):
			var b2 = bodies[j]
			if b1 == b2:
				# stop gravitating yourself, bro
				continue
			if !Body.state_exerts_gravity(b1) || !Body.state_exerts_gravity(b2):
				# if either shouldn't exert gravity, skip this whole step
				continue
			var r_squared = b1.position.distance_squared_to(b2.position)
			var f = gravitational_constant * b1.mass * b2.mass / r_squared
			var dir = b1.position.direction_to(b2.position)
			if use_tiered_physics:
				if (b1.massTier > b2.massTier):
					apply_grav(b2, -1 * f, dir)
					#print("%s exerting %2f N on %s (unilateral)" % [b1.name, f, b2.name])
				elif (b1.massTier < b2.massTier):
					apply_grav(b1, f, dir)
					#print("%s exerting %2f N on %s (unilateral)" % [b2.name, f, b1.name])
				else:
					#print("%s+%s exerting %2f N on each other at %2f ratio" % [b1.name, b2.name, f, same_tier_effect])
					f *= same_tier_effect
					apply_grav(b1, f, dir)
					apply_grav(b2, -1 * f, dir)
			else:
				apply_grav(b1, f, dir)
				apply_grav(b2, -1 * f, dir)
	
	# when the setting is on, stop all bodies that have left the area
	if clamp_all_bodies:
		# this is written naively, but it's not a long-term measure anyway
		for body in bodies:
			if body.position.x > playable_area.x:
				body.velocity = Vector3.ZERO
				body.position.x = playable_area.x
			if body.position.y > playable_area.y:
				body.velocity = Vector3.ZERO
				body.position.y = playable_area.y
			if body.position.x < 0:
				body.velocity = Vector3.ZERO
				body.position.x = 0
			if body.position.y < 0:
				body.velocity = Vector3.ZERO
				body.position.y = 0
