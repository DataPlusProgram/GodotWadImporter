#tool
extends Node3D

@export var pickupEntityStr: String = ""
@export var pickupEntityPath: String = ""
@export var pickupSound: AudioStreamWAV

@export var pickupSoundName: String = "DSSGCOCK"
var weaponNode

func _ready():
	if Engine.is_editor_hint(): 
		return
	
	$Area3D.connect("body_entered", Callable(self, "bodyIn"))


func bodyIn(body):
	
	var node : Node
	if "weaponManager" in body:
		
		node = ENTG.fetchEntity(pickupEntityStr,get_tree(),"Doom",false)
		
		
		
		if node == null:
			return null
		
		node.visible = true
		body.weaponManager.pickup(node)
		
		if node.get_parent() == null:
			node.queue_free()
		
		var audio = $AudioStreamPlayer3D
		
		audio.playPickup()
		queue_free()
	
	
func addToNode(targetNode,toAdd):
	
	remove_child(toAdd)
	targetNode.add_child(toAdd)
