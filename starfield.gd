@tool
# a dynamic background that randomizes simple stars and fills the play area
class_name Starfield
extends Node2D

const CAMERA_BUFFER = Vector2(200, 200)

# what color the base rectange should be
@export var background: Color = Color.BLACK
# raw number of stars to spread in the play area
@export var quantity: int = 400
# how transparent are stars
@export var star_opacity: float = 0.7
# how random is the coloration of the stars; if 0, they will be pure white
@export var star_color_variance: float = 0.3

# this will be overridden on entry
var bounds_min: Vector2 = Vector2.ZERO
var bounds_max: Vector2 = Vector2(1000, 1000)

static func rand_between_vecs (ul: Vector2, br: Vector2) -> Vector2:
	return Vector2(
		randf_range(ul.x, br.x),
		randf_range(ul.y, br.y)
	)

class Star:
	var r: float = randf_range(0.1, 2.5)
	var p: Vector2 = Vector2.ZERO
	var c: Color = Color.WHITE
	func _init(ip: Vector2, color_var: float = 0.2, opac: float = 0.7):
		p = ip
		c = Color(
			randf_range(1 - color_var, 1.0),
			randf_range(1 - color_var, 1.0),
			randf_range(1 - color_var, 1.0),
			opac
		)

var stars: Array[Star] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()

func setup():
	stars = []
	bounds_min = Vector2.ZERO - CAMERA_BUFFER
	bounds_max = Simulator.playable_area + CAMERA_BUFFER
	for i in range(quantity):
		stars.push_back(Star.new(
			rand_between_vecs(bounds_min, bounds_max),
			star_color_variance,
			star_opacity))
	#print("Made %d stars" % quantity)
	queue_redraw()

# expose a button that redraws the background (useful if the play area changes)
@export_tool_button("Remake") var setup_fn = setup

func _draw() -> void:
	draw_rect(Rect2(bounds_min, bounds_max + CAMERA_BUFFER), background)
	for star in stars:
		draw_circle(star.p, star.r, star.c, false)
