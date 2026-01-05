extends Camera2D

# which mouse button performs the drag
@export var drag_button = MouseButton.MOUSE_BUTTON_RIGHT
# whether drag is "physical" (your pointer pulls the map in the same direction)
# or non (your pointer drags in the direction you want the viewport to go)
@export var physical_drag: bool = true
# what percentage change should apply to zoom on every mousewheel event
@export_range(0.1, 10, 0.1, "suffix:%") var zoom_speed: float = 2

# whether a drag is currently happening
var drag_active: bool = false
# where the pointer was when the drag started
var drag_start_pointer: Vector2 = Vector2.ZERO
# where the camera was when the drag started
var drag_start_camera: Vector2 = Vector2.ZERO

@export var follow_mode: bool = false
@export var follow_target: Body

#func _ready() -> void:
	#var listener = find_child("AudioListener2D") as AudioListener2D
	#listener.make_current()

func _process(_delta: float):
	if follow_mode:
		if !follow_target:
			follow_mode = false
		else:
			position = follow_target.global_position

# convert a camera event's positional vector (relative to the viewport) to one
# based in the game space. There's definitely a way to do this with built-ins
# but all the various transforms got to me. TODO
func camera_to_scene_coords(pos: Vector2) -> Vector2:
	return ((pos - get_viewport_rect().size / 2) / zoom) + global_position

func _input(event: InputEvent) -> void:
	if event.is_action("cameraViewAll"):
		follow_mode = false
		drag_active = false
		var psn = PhysicsSimulator.find(self)
		position = psn.playable_area / 2  # move to the midpoint
		var zoom_adjustment = get_viewport_rect().size / psn.playable_area 
		var min_to_cover = min(zoom_adjustment.x, zoom_adjustment.y)
		zoom = Vector2(min_to_cover, min_to_cover)
		return
	if event.is_action("cameraViewSelected"):
		drag_active = false
		var target = %ManualControl.selected
		if target != null:
			position = target.global_position
			if Input.is_key_pressed(KEY_SHIFT):
				# start following!
				follow_target = target
				follow_mode = true
				return 
		follow_mode = false
		return
	if event is InputEventMouseButton:
		follow_mode = false
		if event.button_index == drag_button && event.is_pressed():
			#print("dragging started at %f,%f" % [event.position.x, event.position.y])
			drag_active = true
			drag_start_pointer = event.position
			drag_start_camera = position
		else:
			drag_active = false
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			zoom = zoom * (100 + zoom_speed) / 100
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			zoom = zoom * (100 - zoom_speed) / 100
	elif drag_active && event is InputEventMouseMotion:
		position = drag_start_camera + (-1.0 if physical_drag else 1.0) * (event.position - drag_start_pointer) / zoom
