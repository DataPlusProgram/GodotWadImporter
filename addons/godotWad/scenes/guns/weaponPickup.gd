#tool
extends RigidBody

export(String) var pickupEntityStr = ""
export(String) var pickupEntityPath = ""
export(AudioStreamSample) var pickupSound

export(String) var pickupSoundName = "DSSGCOCK"
var weaponNode

func _ready():
	if Engine.editor_hint: 
		return
	
	$Area.connect("body_entered",self,"bodyIn")


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

