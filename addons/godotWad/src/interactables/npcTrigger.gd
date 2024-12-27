extends Node


var targetNpc = ""
var sectorTag = -1
var sectorInfo


func _ready():
	sectorTag = get_meta("sectorTag")
	targetNpc = get_meta("npcTrigger")
	add_to_group("npcTrigger")
	
	
func activate():
	get_parent().activate()

	
