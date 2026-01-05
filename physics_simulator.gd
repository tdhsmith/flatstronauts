class_name PhysicsSimulator
extends Node2D

# how strong is gravity; unit would be canvas_pixel^3/(pixel_mass*tick^2)
@export var gravitational_constant: float = 100.0
# whether to apply the "tiered" model, where forces apply unidirectionally when
# masses are of different overall tiers
@export var use_tiered_physics: bool = true
# ratio that bodies of the exact same tier affect each other; this can be
# reduced to help prevent e.g. planets from interacting too much compared to
# following an orbit around a star
@export_range(0, 1) var same_tier_effect: float = 1.0

# the size of the current scene's "playable area"
@export var playable_area: Vector2 = Vector2(2000, 2000)
# whether a Body leaving the playable area should be held to its bounds
@export var clamp_all_bodies: bool = true
# what node should be used as the primary container for bodies
@export var container: Node = self

# array tracking all of the Body nodes in the scene
var bodies: Array[Body] = []
# dictionary that stratifies the Body arrays by their MassTier
var bodies_by_tier: Dictionary[Body.MassTier, Array] = {}

static var SIM_NAME = "Physics"
static func find (_n: Node) -> PhysicsSimulator:
	var psn = Simulator
	assert(psn is PhysicsSimulator)
	breakpoint
	return psn

func sort_bodies_into_tiers() -> void:
	for tier in Body.MassTier.values():
		bodies_by_tier[tier] = bodies.filter(func (b: Body): return b.massTier == tier)

static func v32 (v: Vector3) -> Vector2:
	return Vector2(v.x, v.y)

func find_all_body_descendants() -> Array[Body]:
	var body_nodes = container.find_children("*", "Body", true)
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

func start_on(new_container: Node) -> void:
	container = new_container
	bodies = find_all_body_descendants()
	var psa = PackedStringArray(bodies.map(func (b: Body): return b.label))
	print("found %d bodies on %s [%s]" % [bodies.size(), container.name, ",".join(psa)])
	sort_bodies_into_tiers()

static func apply_grav(b: Body, force_scalar: float, dir: Vector2) -> void:
	var scaled = Vector3(dir[0] * force_scalar, dir[1] * force_scalar, 0)
	b.f_gravity += scaled

func has_relevant_collision(a: Body, b: Body) -> bool:
	# ignore bodies with null collision
	if !a.collision || !b.collision:
		return false
	# ignore states that opt out of collision entirely
	if !Body.body_has_collisions(a) || !Body.body_has_collisions(b):
		return false
	# ignore collisions between parent and child
	if Body.body_requires_parent(a) && a.parent_body == b:
		return false
	if Body.body_requires_parent(b) && b.parent_body == a:
		return false
	# finally, run the shape collision detector
	return a.collision.collide(a.global_transform, b.collision, b.global_transform)

func is_separating(a: Body, b: Body) -> bool:
	if Body.body_requires_parent(a) && a.parent_body == b:
		var a_accel_normal = v32(a.f_total).project(a.global_position - b.global_position) / a.mass
		#if a_accel_normal.length() > 0:
			#print("%s accel %.2f" % [a.label, a_accel_normal.length()])
		if a_accel_normal.length() > b.get_surface_accel_for(gravitational_constant):
			return true
	elif Body.body_requires_parent(b) && b.parent_body == a:
		var b_accel_normal = v32(b.f_total).project(b.global_position - a.global_position) / b.mass
		#if b_accel_normal.length() > 0:
			#print("%s accel %.2f" % [b.label, b_accel_normal.length()])
		if b_accel_normal.length() > a.get_surface_accel_for(gravitational_constant):
			return true
	return false

const LANDING_SPEED_MAX: float = 40
func get_landing_speed_damage(speed: float) -> float:
	if speed > LANDING_SPEED_MAX:
		return speed - LANDING_SPEED_MAX
	return 0

func _handle_collision(a: Body, b: Body) -> void:
	var bigger: Body
	var smaller: Body
	if a.massTier == b.massTier:
		return
	if a.massTier > b.massTier:
		bigger = a
		smaller = b
	else:
		bigger = b
		smaller = a
	var relative_velocity = v32(a.velocity - b.velocity)
	var lift_angle = relative_velocity.angle_to(smaller.global_position - bigger.global_position)
	var speed = relative_velocity.length()
	print("collision had %.2f speed (%.2fr %.0fdeg)" % [speed,lift_angle, posmod(lift_angle * 180/PI, 360)])
	if lift_angle < PI / 2 && lift_angle > -PI / 2:
		#breakpoint
		return
	var collision_damage = get_landing_speed_damage(speed)
	a.apply_damage(collision_damage)
	b.apply_damage(collision_damage)
	if a.massTier != b.massTier && speed < LANDING_SPEED_MAX:
		if smaller.p_state == Body.PhysicsState.FREE:
			_attach_to(smaller, bigger, Body.PhysicsState.LANDED)

func _attach_to (child: Body, parent: Body, state: Body.PhysicsState) -> void:
	child.p_state = state
	child.parent_body = parent
	var unrotated_pos = child.global_position - parent.global_position
	child.position = unrotated_pos.rotated(-parent.global_rotation)
	child.rotation = child.global_rotation - parent.global_rotation
	child.get_parent().remove_child(child)
	parent.add_child(child)
	
func _detach (b1: Body, b2: Body, state: Body.PhysicsState) -> void:
	var child = b1 if b1.parent_body == b2 else b2
	var parent = b2 if b1.parent_body == b2 else b1
	assert(Body.body_requires_parent(child))
	assert(child.parent_body == parent)
	child.p_state = state
	child.parent_body = null
	child.position = child.global_position
	child.rotation = child.global_rotation
	child.get_parent().remove_child(child)
	container.add_child(child)

static func _notnull (x: Variant) -> bool:
	return x != null

func _destroy_from_queue() -> void:
	for i in range(bodies.size()):
		if !bodies[i] or bodies[i].destroyed:
			if bodies[i]:
				bodies[i].queue_free()
			bodies[i] = null
	bodies = bodies.filter(PhysicsSimulator._notnull)

func _physics_process(_delta: float) -> void:
	# note that forces should not take delta into account, since they will be
	# scaled by it when they are *applied*
	
	# start by destroying anything that should be gone
	_destroy_from_queue()
	
	# reset all gravity
	for b in bodies:
		b.f_gravity = Vector3(0, 0, 0)
		
	for i in range(bodies.size()):
		var b1 = bodies[i]
		for j in range(i - 1):
			var b2 = bodies[j]
			if has_relevant_collision(b1, b2):
				_handle_collision(b1, b2)
			elif is_separating(b1, b2):
				_detach(b1, b2, Body.PhysicsState.FREE)
	
	# determine gravity between every pair of bodies
	for i in range(bodies.size()):
		var b1 = bodies[i]
		for j in range(i):
			var b2 = bodies[j]
			if b1 == b2:
				# stop gravitating yourself, bro
				continue
			if !Body.body_exerts_gravity(b1) || !Body.body_exerts_gravity(b2):
				# if either shouldn't exert gravity, skip this whole step
				continue
			var r_squared = b1.global_position.distance_squared_to(b2.global_position)
			var f = gravitational_constant * b1.mass * b2.mass / r_squared
			var dir = b1.global_position.direction_to(b2.global_position)
			if use_tiered_physics:
				if (b1.massTier > b2.massTier):
					apply_grav(b2, -1 * f, dir)
					#print("%s exerting %2f N on %s (unilateral)" % [b1.name, f, b2.name])
				elif (b1.massTier < b2.massTier):
					apply_grav(b1, f, dir)
					#print("%s exerting %2f N on %s (unilateral)" % [b2.name, f, b1.name])
				else:
					if b1.massTier == Body.MassTier.JUNK:
						continue # don't gravitate junk to itself
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
		for body in bodies.filter(Body.body_moves_by_veloc):
			if body.global_position.x > playable_area.x:
				body.velocity = Vector3.ZERO
				body.global_position.x = playable_area.x
			if body.global_position.y > playable_area.y:
				body.velocity = Vector3.ZERO
				body.global_position.y = playable_area.y
			if body.global_position.x < 0:
				body.velocity = Vector3.ZERO
				body.global_position.x = 0
			if body.global_position.y < 0:
				body.velocity = Vector3.ZERO
				body.global_position.y = 0
