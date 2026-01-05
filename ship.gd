@tool
# a Ship is a body that can apply thrust, take damage, hold cargo, and other
# features
class_name Ship
extends Body

# how much force can the ship apply to itself
@export var MAX_THRUST: float = 1.0
# what is the ratio between max thrust and the maximum *angular* thrust.
# this is a denominator, so larger numbers reduce the turning speed.
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

const SHIP_GLOW_FACTOR = 3.0

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
	modulate = Color(SHIP_GLOW_FACTOR, SHIP_GLOW_FACTOR, SHIP_GLOW_FACTOR)

var thrust_ratio: float = 0 # 0.0 to 1.0
var angular_thrust_ratio: float = 0  # -1.0 to 1.0

func is_thrustable() -> bool:
	return true

func apply_thrust(forward: float, rotational: float, delta: float) -> bool:
	forward = clamp(forward, 0.0, 1.0)
	rotational = clamp(rotational, -1.0, 1.0)
	var has_enough: bool = true
	if forward > 0.0:
		has_enough = fuel.deduct(fuel_spend_rate * forward * delta)
	if has_enough:
		thrust_ratio = forward
		angular_thrust_ratio = rotational
		return true
	else:
		thrust_ratio = 0.0
		angular_thrust_ratio = 0.0
		return false

func apply_damage(amt: float, reason: String = "") -> void:
	print("ship %s took %.0f damage from %s" % [label, amt, reason])
	if current_health > amt:
		current_health -= amt
	else:
		explode()

func explode() -> void:
	const EXPLOSIVENESS = 1.5
	for i in range(randi_range(4,7)):
		var d = Debris.new()
		d.radius = randi_range(2,8)
		var velo = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		d.velocity = Vector3(velo.x, velo.y, randf_range(-0.1, 0.1)) * EXPLOSIVENESS
		d.position = global_position + velo
		# TODO okay Body spawning needs to be standardized or this will be a mess
		Simulator.container.add_child(d)
		Simulator.bodies.push_back(d)
	var sfx = PositionalPlayOnce.new(PositionalPlayOnce.EXPLODE_PATH, global_position)
	sfx.bus = &"Explosions"
	Simulator.container.add_child(sfx)
	super.explode()

func get_thrust_vector () -> Vector3:
	thrust_ratio = clampf(thrust_ratio, 0.0, 1.0)
	angular_thrust_ratio = clampf(angular_thrust_ratio, -1.0, 1.0)
	return Vector3(
		cos(global_rotation) * thrust_ratio * MAX_THRUST,
		sin(global_rotation) * thrust_ratio * MAX_THRUST,
		angular_thrust_ratio * (MAX_THRUST / ANGULAR_THRUST_SCALE)
	)

func get_thrust_rotation_dir() -> String:
	if angular_thrust_ratio < 0:
		return "↺"
	elif angular_thrust_ratio > 0:
		return "↻"
	return "◦"
func thrust_descriptor() -> String:
	#var angle = Vector2(f_own.x, f_own.y).angle()
	#var is_thrusting = thrust_ratio > 0.0 or angular_thrust_ratio > 0.0
	return "[i]thrust[/i]\n\t%03.0f↑\t%03.0f%s\n\n%.0f/%.0f fuel (-%.0f)" % [
		thrust_ratio * 100,
		abs(angular_thrust_ratio * 100),
		get_thrust_rotation_dir(),
		fuel.amount,
		fuel.capacity,
		fuel_spend_rate
	]
	
func get_rich_description(section: Body.RichDescriptor) -> String:
	match section:
		Body.RichDescriptor.TITLE:
			return "[b]Ship %s[/b]\n%.1f@%s" % [label, mass, MassTier.find_key(massTier)]
		Body.RichDescriptor.MOVEMENT:
			return _move_state(self)
		Body.RichDescriptor.CONTROL:
			return thrust_descriptor()
		Body.RichDescriptor.CARGO:
			return "%.0f/%.0f %s" % [cargo.amount, cargo.capacity, cargo.cTypeLabel.to_lower()]
		Body.RichDescriptor.PROGRESS:
			return "%.0f/%.0f HP" % [current_health, max_health]
	return "<unknown descriptor %d>" % section

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# don't actually apply physics in editor mode
		return
		
	if p_state == PhysicsState.ATTACHED:
		#breakpoint
		pass
	f_own = get_thrust_vector()
	# the _physics_process on Body handles turning force into accel & veloc
	super(delta)
	
func _draw() -> void:
	pass
	#draw_arc(position, radius, 0.0, PI/2.0, 12, Color.WEB_GREEN, -2.0)
