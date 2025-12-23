@tool
# The baseline handling for all physics objects
class_name Body
extends Node2D

# The simulator can be set to have "tiered" interactions, such that bodies
# are only affected by entities of their tier or greater. For more details
# see the simulator (assuming I one day write those details TODO).
# The specific names are not important but simply to help guide us.
enum MassTier {
	JUNK,
	SHIP,
	MOON,
	PLANET,
	STAR,
	COSMIC
}

# Basic state for how an object will interact with physics
# >>> NOTE only FREE & FIXED are implemented at present!!! <<<
enum PhysicsState {
	# a FREE body moves according to the forces on it
	FREE,
	# an ATTACHED body is linked to a parent body and only moves when the parent
	# moves, keeping the same relative position/rotation. This state is not
	# terminated until handled by a script event (such as a Structure breaking)
	ATTACHED,
	# a LANDED body is linked to a parent body and only moves when the parent
	# moves, keeping the same relative position/rotation. This state ends when
	# the body applies enough force to separate ("lift off").
	LANDED,
	# a body in STABLE_ORBIT runs simplified physics to represent being captured
	# by a gravitationally dominant body. This allows it to be more predictable
	# when the true FREE orbit would be chaotic due to the presence of many-body
	# interactions. A body will leave a stable orbit when sufficiently perturbed
	# or when its parent body's mass or area of dominance change.
	STABLE_ORBIT,
	# a FIXED body does not move, however it still contributes to forces overall
	# such as applying gravitational pull or collisions. There are no natural
	# transitions in or out of this state.
	FIXED,
	# a SCRIPTED body is completely managed by a program; it is effectively
	# removed from the simulator for the time being. There are no natural
	# transitions in or out of this state.
	SCRIPTED
}

static func state_exerts_gravity(s: PhysicsState) -> bool:
	return s != PhysicsState.SCRIPTED

static func state_calculates_accel(s: PhysicsState) -> bool:
	return s == PhysicsState.FREE

static func state_moves_by_veloc(s: PhysicsState) -> bool:
	return s == PhysicsState.FREE

# Whether child Sprite2D nodes are automatically rescaled to match this Body's
# current radius
@export var autoscale_sprites: bool = true

# The radius represents the bounding circle of an object, as well as the (half-)
# side length of any auto-scaled sprites
@export var radius: float = 20:
	set(newRadius):
		radius = newRadius
		if autoscale_sprites:
			update_child_sprites()
	get():
		return radius

func update_child_sprites() -> void:
	for child in get_children():
		if child is Sprite2D:
			var targetScale = Vector2(2*radius, 2*radius) / child.texture.get_size()
			print("setting %s to scale %2f,%2f" % [child.name, targetScale[0], targetScale[1]])
			child.scale = targetScale
		else:
			print("non sprite2d %s" % child.name)

# A user-facing name for this body
@export var label: String = "":
	get():
		if label == "":
			return name
		else:
			return label
# The current state of the body, see PhysicsState for details
@export var physicsState: PhysicsState = PhysicsState.FREE

# helper to get the enum key for the current state, useful for debug output
func get_state_label() -> String:
	return PhysicsState.find_key(physicsState)

# The maximum tier of bodies that this Body can exert influence on
@export var massTier: MassTier = MassTier.JUNK
# The Body's mass, which scales all forces upon it
@export_range(0, 10000, 1, "exp", "or_greater") var mass: float = 1
# The Body's directional speed, where z is the rotation
@export var velocity: Vector3 = Vector3.ZERO

@export_group("Attachement & Orbits")
@export var parent_body: Body = null
@export var stable_orbit_number: int = -1
@export var stable_orbit_phase: float = 0

# The current gravity felt by this Body, with z being rotation (unused)
var f_gravity: Vector3 = Vector3.ZERO
# Other external forces felt by this Body, with z being rotation
var f_other: Vector3 = Vector3.ZERO
# This body's "own" forces, such as the thrust created by a pilotable ship
var f_own: Vector3 = Vector3.ZERO
# A getter to retrieve the sum total force acting on this Body
var f_total: Vector3 = Vector3.ZERO:
	get():
		return f_gravity + f_other + f_own

# Helper function to recursively find all Bodies within this part of the node
# ALERT this code has a double-counting bug in it, so I switched to a diff
# implementation until it was needed (the root can use simpler code anyway)

#static func get_child_bodies(base: Node, acc: Array[Body] = []) -> Array[Body]:
	#var children: Array[Body] = [];
	#for child in base.get_children():
		#if child is Body:
			#children.push_back(child)
	#acc.append_array(children);
	#var child_count = children.size()
	#for i in range(child_count):
		#var grandchilden = Body.get_child_bodies(children[i], children)
		#if grandchilden.size() > 0:
			#acc.append_array(grandchilden)
	#return acc

# 
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() || delta == 0:
		# don't apply physics in editor mode
		return
	
	var totalAccel = f_total / mass
	
	if Body.state_calculates_accel(physicsState):
		#print("apply accel to %s in state %s" % [label, get_state_label()])
		velocity += totalAccel

	if Body.state_moves_by_veloc(physicsState):
		# add velocity vector to position
		position.x += velocity[0] * delta
		position.y += velocity[1] * delta
		rotation += (velocity[2] / 360)
	
