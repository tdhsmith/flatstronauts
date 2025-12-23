class_name Cargo

enum CargoType {
	NONE,
	FUEL,
	ENERGY,
	ROCK,
	ORE
}

var cType: CargoType = CargoType.NONE
var capacity: float = 100.0
var amount: float = 0.0
var free_space: float:
	get():
		return capacity - amount

func _init(t: CargoType, cap: float, amt: float = 0) -> void:
	cType = t
	capacity = cap
	amount = amt

# attempt to remove an amount from cargo, returning whether it was successful
func deduct(to_remove: float) -> bool:
	if to_remove > amount:
		return false
	else:
		amount -= to_remove
		return true

# attempts to draw an amount from another Cargo into this one, return the
# amount that was actually transferred (which will be 0 in any fail condition)
func pull_from (source: Cargo, to_pull: float, fail_on_overdraw: bool = true) -> float:
	if source.cType != cType:
		# cannot mix cargo types
		return 0
	if to_pull <= 0:
		return 0
	if fail_on_overdraw && source.amount < to_pull:
		# depending on usage, it may be more helpful to fail if we ask for too
		# much cargo (e.g. if the logic is expecting sums to add up)
		return 0
	var transferable = min(free_space, to_pull, source.amount)
	var did_extract = source.deduct(transferable)
	if did_extract:
		amount += transferable
		return transferable
	return 0
