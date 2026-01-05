class_name PhysicsRoot
extends Node

func _ready() -> void:
	Simulator.start_on(self)
