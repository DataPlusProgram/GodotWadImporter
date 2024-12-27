extends Area3D

var allPlayerPos : PackedVector3Array = []
var mapNode : Node = null

func _ready():
	
	if get_node_or_null("../../../") != null:
		mapNode = $"../../../"
		
	if "allPlayersPos" in mapNode:
		allPlayerPos = mapNode.allPlayersPos

func _physics_process(delta):
	var anyPlayerNear = false
	
	if allPlayerPos.size() == 0:
		anyPlayerNear = true
	
	for i in allPlayerPos:
		if( (global_position - i).length_squared() < 900):
			anyPlayerNear = true
		
	
		
	if anyPlayerNear:
		get_child(0).disabled = false

	else:
		get_child(0).disabled = true
