extends Control

func _process(_delta: float) -> void:
	if Simulator.is_paused != visible:
		visible = Simulator.is_paused
