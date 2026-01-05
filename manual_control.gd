@tool
extends Node

# which entity is currently selecteds
@export var selected: Body = null:
	set (new_selected):
		if selected != new_selected:
			prev_selected = selected
			selected = new_selected
var prev_selected: Body = null

@export_range(-10, 50, 1, "suffix:%") var clickable_radius: float = 10

const DELTA_APPROXIMATOR: float = 1.0/60.0
@export_range(0.5, 5.0) var tracker_oversize_ratio: float = 1.3
const TRACKER_ROTATION_SPEED: float = 1.0 / 40.0

func _input(event: InputEvent) -> void:
	# NOTE we need to be careful about when selection changes
	if event is InputEventMouseButton:
		if event.is_action_pressed("selectBody"):
			var p = %Camera.camera_to_scene_coords(event.position)
			#print("click at %v -> %v" % [event.position, p])
			assert(Simulator.bodies.size() > 1, "simulator has at least 2 bodies")
			var closest: Body = null
			var closest_dist = INF
			for body: Body in Simulator.bodies:
				var current_dist = body.global_position.distance_squared_to(p)
				if current_dist < closest_dist:
					closest = body
					closest_dist = current_dist
			#print("closest body was %s at distance %.1f from %v" % [closest.label, closest_dist, p])
			var clickable_dist = closest.radius * closest.radius * (100 + clickable_radius) / 100
			if closest_dist <= clickable_dist:
				# TODO "change selection"
				selected = closest
			else:
				selected = null

	if !selected:
		return

	# TODO halting probably needs a dedicated func in body?
	if Input.is_action_pressed("haltMovement"):
		if Input.is_key_pressed(KEY_SHIFT):
			selected.reset_to_initial()
		selected.halt()
		return

	if selected.is_thrustable():
		var is_going_forward = Input.is_action_pressed("thrustForward")
		var forward_thrust = 1.0 if is_going_forward else 0.0
		# TODO someday we should allow variable percentages
		var angular_thrust = 0.0
		if Input.is_action_pressed("thrustRotateCW"):
			angular_thrust = 1.0
		elif Input.is_action_pressed("thrustRotateCCW"):
			angular_thrust = -1.0
		selected.apply_thrust(forward_thrust, angular_thrust, DELTA_APPROXIMATOR)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if selected:
		%Tracker.visible = true
		%Tracker.global_position = selected.global_position
		%Tracker.scale = 2.0 * tracker_oversize_ratio * Vector2(
			selected.radius / %Tracker.texture.get_width(),
			selected.radius / %Tracker.texture.get_height()
			)
		%Tracker.rotation = fmod(Engine.get_process_frames() * TRACKER_ROTATION_SPEED, 2.0*PI)
	else:
		%Tracker.visible = false
