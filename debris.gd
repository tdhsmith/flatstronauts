@tool
class_name Debris
extends Body

var pts: PackedVector2Array = []
var base_color: Color = Color.WHEAT
#var colors: PackedColorArray = []
const CLOSE_LOOP: bool = true

func _update_radius(r: float) -> void:
	print("UPDATE R %f" % r)
	#random_poly()
	super._update_radius(r)

func _ready() -> void:
	random_poly()

func random_poly():
	pts = []
	#colors = []
	var count = randi_range(4,8)
	for i in range(count):
		var theta = randf_range(i*(2*PI/count), i*(2*PI/count + 1))
		#var rad = randf_range(1, radius)
		var vec = (Vector2.from_angle(theta) * radius)
		pts.push_back(vec)
		#colors.push_back(Color.WHITE)
	if CLOSE_LOOP:
		pts.push_back(pts[0])
		#colors.push_back(colors[0])
		
func apply_damage(_amt: float, _reason: String = "") -> void:
	# no matter what, it just gets destroyed
	explode()

func _proces(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_polyline(pts, base_color)
