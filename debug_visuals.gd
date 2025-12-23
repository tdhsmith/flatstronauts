extends Node2D

# This class handles the drawing of special debugging & visualization elements
# onto the screen. We separate it from PhysicsSimulator to 1) keep it from being
# cluttered, and 2) to make the drawing layers simpler (the simulator node, as
# a root, has a hard time drawing to the "top layer")

# ratio between force values and their displayed length in canvas units
const FORCE_VECTOR_VISUAL_SCALE: float = 40.0

# whether the overall debug drawing is on
@export var rendering: bool = false
@export_group("Draw Options", "draw")
# whether to visualize force and velocity vectors as arrows
@export var physics_vectors: bool = true
# whether to draw a visible boundary for the playable area
@export var playable_area: bool = true

@export var body_radius: bool = true

#@export_tool_button("Force Update") var update_fn = queue_redraw

# Helper function to create arrows. It also allows a "maximum length": if an
# arrow would be over that length, we limit it and then draw a second "head" to
# indicate it is going beyond the scale
func draw_arrow (a: Vector2, b: Vector2, c: Color, headSize: float = 5, doubleCapMaxLen: float = 50) -> void:
	var to = b - a
	var rev = b.direction_to(a)
	var h1 = rev.rotated(PI/8) * headSize
	var h2 = rev.rotated(PI/-8) * headSize
	if to.length() > doubleCapMaxLen:
		b = a + to.limit_length(doubleCapMaxLen)
		var x = b + to.normalized() * headSize
		draw_line(x, x+h1, c)
		draw_line(x, x+h2, c)
	draw_line(a, b, c)
	draw_line(b, b+h1, c)
	draw_line(b, b+h2, c)

#func update_for_editor():
	#queue_redraw()

func _draw() -> void:
	var physicsManager = PhysicsSimulator.find(self)
	if physicsManager:
		if physics_vectors || body_radius:
			for body in physicsManager.bodies:
				if physics_vectors:
					draw_arrow(
						body.global_position,
						body.global_position + PhysicsSimulator.v32(body.velocity),
						Color.RED)
					draw_arrow(
						body.global_position,
						body.global_position + PhysicsSimulator.v32(body.f_total * FORCE_VECTOR_VISUAL_SCALE),
						Color.YELLOW)
				if body_radius:
					draw_circle(
						body.global_position,
						body.radius,
						Color.AQUA,
						false,
						1.0
					)
		if playable_area:
			draw_dashed_line(Vector2.ZERO, Vector2(0, physicsManager.playable_area.y), Color.GRAY)
			draw_dashed_line(Vector2.ZERO, Vector2(physicsManager.playable_area.x, 0), Color.GRAY)
			draw_dashed_line(Vector2(0, physicsManager.playable_area.y), physicsManager.playable_area, Color.GRAY)
			draw_dashed_line(Vector2(physicsManager.playable_area.x, 0), physicsManager.playable_area, Color.GRAY)
	else:
		print("DebugDrawings is not child of PhysicsSimulator!")
		rendering = false
