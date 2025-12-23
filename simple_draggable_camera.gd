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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
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
