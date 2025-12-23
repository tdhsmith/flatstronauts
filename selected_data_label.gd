# temporary way of displaying details about the selected ship

extends Label

const NONE_SELECTED_MSG: String = "Selected: NO SHIP"

func thrust_descriptor(s: Ship) -> String:
	var angle = Vector2(s.f_own.x, s.f_own.y).angle()
	if s.thrust_ratio == 0:
		angle = s.rotation
	return " thrusting %.0f%% at %.0fdeg" % [
		s.thrust_ratio * 100,
		angle * 180 / PI
	]

func build_text(s: Ship) -> String:
	return "Selected: %s  |  HP: %.0f/%.0f |  Fuel: %.0f/%.0f |  Cargo: %.0f/%.0f %s | %s" % [
		s.label,
		s.current_health,
		s.max_health,
		s.fuel.amount,
		s.fuel.capacity,
		s.cargo.amount,
		s.cargo.capacity,
		s.cargo.cTypeLabel,
		thrust_descriptor(s)
	]

func _draw() -> void:
	var ps = PhysicsSimulator.find(self)
	var selected_ship = Ship.find_selected(ps)
	if selected_ship == null:
		text = NONE_SELECTED_MSG
		return
	text = build_text(selected_ship)

func _process(_delta: float) -> void:
	queue_redraw()
