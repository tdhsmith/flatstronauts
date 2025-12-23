@tool
# a Ship is a body that can apply thrust, take damage, hold cargo, and other
# features
class_name Ship
extends Body

# whether this ship accepts user input; this is very very temporary handling!
@export var selected: bool = true
# we store initial position so we can reset it with specual debug functions
var initial_position: Vector2 = position

# how much force can the ship apply to itself
@export var MAX_THRUST: float = 1.0
# what is the ratio between max thrust and the maximum *angular* thrust
const ANGULAR_THRUST_SCALE: float = 15

@export var max_fuel: float = 100.0
var current_fuel: float = 0
@export var max_health: float = 10.0
var current_health: float = 0
@export var init_cargo_capacity: float = 100.0
@export var cargo_type: Cargo.CargoType = Cargo.CargoType.ORE
var cargo: Cargo

const START_WITH_MAX_FUEL_AND_HEALTH: bool = true

func _init() -> void:
	cargo = Cargo.new(cargo_type, init_cargo_capacity)
	if START_WITH_MAX_FUEL_AND_HEALTH:
		current_health = max_health
		current_fuel = max_fuel

func getThrustByRotation (percentage: float) -> Vector2:
	# rotation = 0 means UP not RIGHT, and Y is measured from screen top so this
	# is diferent than standard cartesian coordinates
	return Vector2(
		sin(rotation) * percentage * MAX_THRUST,
		-1 * cos(rotation) * percentage * MAX_THRUST
	)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# don't actually apply physics in editor mode
		return
	
	if selected:
		if Input.is_action_pressed("haltMovement"):
			f_own = Vector3(0, 0, 0)
			velocity = Vector3(0, 0, 0)
			if Input.is_key_pressed(KEY_SHIFT):
				position = initial_position
			return
		
		if Input.is_action_pressed("thrustForward"):
			var ft = getThrustByRotation(1.0)
			#print("thrusting [", ft[0], ",", ft[1], "]")
			f_own[0] = ft[0]
			f_own[1] = ft[1]
		else:
			f_own = Vector3(0, 0, 0)
		
		if Input.is_action_pressed("thrustRotateCW"):
			f_own[2] = MAX_THRUST / ANGULAR_THRUST_SCALE
		elif Input.is_action_pressed("thrustRotateCCW"):
			f_own[2] = -1 * MAX_THRUST / ANGULAR_THRUST_SCALE
		else:
			f_own[2] = 0
	
	# the _physics_process on Body handles turning force into accel & veloc
	super(delta)
