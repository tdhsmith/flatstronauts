@tool
# a Ship is a body that can apply thrust, take damage, hold cargo, and other
# features
class_name Ship
extends Body

# whether this ship accepts user input; this is very very temporary handling!
@export var selected: bool = true
# we store initial position so we can reset it with special debug functions
var initial_position: Vector2 = position
var initial_rotation: float = rotation

# how much force can the ship apply to itself
@export var MAX_THRUST: float = 1.0
# what is the ratio between max thrust and the maximum *angular* thrust
const ANGULAR_THRUST_SCALE: float = 15

@export var max_fuel: float = 100.0
var fuel: Cargo
@export var max_health: float = 10.0
var current_health: float = 0
# the amount of units spent per second
@export var fuel_spend_rate: float = 10.0
@export var init_cargo_capacity: float = 100.0
@export var cargo_type: Cargo.CargoType = Cargo.CargoType.ORE
var cargo: Cargo

const START_WITH_MAX_FUEL_AND_HEALTH: bool = true

func _init() -> void:
	cargo = Cargo.new(cargo_type, init_cargo_capacity)
	var current_fuel = 0
	if START_WITH_MAX_FUEL_AND_HEALTH:
		current_health = max_health
		current_fuel = max_fuel
	fuel = Cargo.new(Cargo.CargoType.FUEL, max_fuel, current_fuel)

func _ready() -> void:
	add_to_group("ships")

var thrust_ratio: float = 0 # 0.0 to 1.0
var angular_thrust_ratio: float = 0  # -1.0 to 1.0

func apply_damage(amt: float, reason: String = "") -> void:
	print("ship %s took %.0f damage from %s" % [label, amt, reason])
	if current_health > amt:
		current_health -= amt
	else:
		explode()

func explode() -> void:
	const EXPLOSIVENESS = 1.5
	var psn = PhysicsSimulator.find(self)
	for i in range(randi_range(4,7)):
		var d = Debris.new()
		d.radius = randi_range(2,8)
		var velo = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		d.velocity = Vector3(velo.x, velo.y, randf_range(-0.1, 0.1)) * EXPLOSIVENESS
		d.position = global_position + velo
		# TODO okay Body spawning needs to be standardized or this will be a mess
		psn.container.add_child(d)
		psn.bodies.push_back(d)
	super.explode()

func get_thrust_vector () -> Vector3:
	thrust_ratio = clampf(thrust_ratio, 0.0, 1.0)
	angular_thrust_ratio = clampf(angular_thrust_ratio, -1.0, 1.0)
	return Vector3(
		cos(global_rotation) * thrust_ratio * MAX_THRUST,
		sin(global_rotation) * thrust_ratio * MAX_THRUST,
		angular_thrust_ratio * (MAX_THRUST / ANGULAR_THRUST_SCALE)
	)

static func find_selected (ps: PhysicsSimulator) -> Ship:
	var ships = ps.bodies.filter(func (b: Body): return b and (b is Ship) and (b as Ship).selected)
	if (ships.size() > 0):
		return ships[0] as Ship
	return null

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# don't actually apply physics in editor mode
		return
		
	if p_state == PhysicsState.ATTACHED:
		#breakpoint
		pass
	
	if selected:
		if Input.is_action_pressed("haltMovement"):
			f_own = Vector3(0, 0, 0)
			velocity = Vector3(0, 0, 0)
			if Input.is_key_pressed(KEY_SHIFT):
				position = initial_position
				rotation = initial_rotation
				p_state = Body.PhysicsState.FREE
			return
		
		if Input.is_action_pressed("thrustForward"):
			var intended_thrust = 1.0
			var has_enough = fuel.deduct(fuel_spend_rate * intended_thrust * delta)
			if has_enough:
				thrust_ratio = intended_thrust
			else:
				thrust_ratio = 0.0
		else:
			thrust_ratio = 0.0
		
		# NOTE for now rotating doesn't require fuel
		if Input.is_action_pressed("thrustRotateCW"):
			angular_thrust_ratio = 1.0
		elif Input.is_action_pressed("thrustRotateCCW"):
			angular_thrust_ratio = -1.0
		else:
			angular_thrust_ratio = 0.0

		f_own = get_thrust_vector()
	
	# the _physics_process on Body handles turning force into accel & veloc
	super(delta)
