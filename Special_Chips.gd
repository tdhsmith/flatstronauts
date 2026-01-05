extends Node

class Chip: 
	var name: String
	var value: int
	var target: String #"self" only effects returns on this chip, "bet" effects return of the whole bet, "etc" has effects outside of the bets' return
	var multiplier: int
	var rollsuccess: Array[int] #If this requires a specific number to be rolled for the effect to take place, the number is stored here.  If it's empty, this condition will be ignored
	var specificbet: Array[String] #If this requires the chip to win on a certain bet for the effect, the bet names are stored here

func chip_applies(c: Chip, number_rolled: int, bet_name: String) -> bool:
	return (
		(c.rollsuccess == [] or c.rollsuccess.has(number_rolled)) 
		and 
		(c.specificbet == null or c.specificbet.has(bet_name))
	)

var specialchips: Array[Chip] = []

func test() -> void:
	
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var plusOne: Chip = Chip.new()
	plusOne.name = "+1"
	plusOne.value = 1
	plusOne.target = "self"
	plusOne.multiplier = 2
	specialchips.append(plusOne)
	
	var plusFive: Chip
	plusFive.name = "+5"
	plusFive.value = 5
	plusFive.target = "self"
	plusFive.multiplier = 2
	specialchips.append(plusFive)
	
	var plusTen: Chip
	plusTen.name = "+10"
	plusTen.value = 10
	plusTen.target = "self"
	plusTen.multiplier = 2
	specialchips.append(plusTen)
	
