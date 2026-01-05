class_name PositionalPlayOnce
extends AudioStreamPlayer2D
 
static var REGEX_NUM_RANGE = RegEx.create_from_string("\\[(?<min>\\d+)-(?<max>\\d+)\\]")
static var EXPLODE_PATH = "res://sfx/crunch/crunch[1-7].mp3"

func randomize_path(path: String) -> NodePath:
	var result = REGEX_NUM_RANGE.search(path)
	if result:
		var a = result.get_string("min").to_int()
		var b = result.get_string("max").to_int()
		var val = randi_range(a, b)
		path = path.replace(result.get_string(0), "%d" % val )
	return NodePath(path)

func _init(path: String, pos: Vector2, play_now: bool = true) -> void:
	position = pos
	stream = load(randomize_path(path))
	autoplay = play_now

func erase_self() -> void:
	print("removing audio %s with path %s" % [name, stream.resource_path])
	queue_free()

func _ready() -> void:
	finished.connect(erase_self)
