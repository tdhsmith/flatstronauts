extends RichTextLabel

const NONE_SELECTED_MSG: String = "NO SELECTION"
func build_text(b: Body) -> String:
	var sections = Body.RichDescriptor.values().map(
		func (rd: Body.RichDescriptor): return b.get_rich_description(rd))
	return "\n\n".join(PackedStringArray(sections))

func _draw() -> void:
	#var ps = PhysicsSimulator.find(self)
	var selected_body = %ManualControl.selected
	if selected_body == null:
		text = NONE_SELECTED_MSG
		(get_parent() as Control).size.y = 100
		return
	text = build_text(selected_body)
	(get_parent() as Control).size.y = 400

func _process(_delta: float) -> void:
	queue_redraw()
