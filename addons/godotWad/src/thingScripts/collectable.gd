extends Spatial
export var itemName = "nullItem"

var velo = Vector3.ZERO
var toInventory = false

export(String) var giveString = ""
export(float) var giveAmount = 0
export(bool) var persistant = true
export(float) var limit = -1

var h = 0

func _ready():
	#sleeping = true
	$Area.connect("body_entered",self,"bodyIn")
	h = WADG.getCollisionShapeHeight($CollisionShape)
	#$groundCast.translation.y = h/2.0
	#$groundCast.cast_to.y = -WADG.getCollisionShapeHeight($CollisionShape)*0.51
	#$groundCast.cast_to.y = -3
	

func _physics_process(delta):
	pass
	
	#if $groundCast.get_collider() == null:
	#	translation.y += $groundCast.cast_to.y

func bodyIn(body):
	
	if "inventory" in body  and toInventory:
		var bodyInventory = body.inventory
		
		#if !bodyInventory.has(itemName):
		#	bodyInventory[itemName] = {}
		#	bodyInventory[itemName]["count"] = 0
			
			
		#bodyInventory[itemName]["count"] = bodyInventory[itemName]["count"]+1
		#bodyInventory[itemName]["persistant"] = persistant
		#bodyInventory[itemName]["sprite"] = $Sprite3D.texture
	
	var ret = false
	
	if body.has_method("pickup"):
		if limit == -1:
			ret = body.pickup({"giveName":giveString,"giveAmount":giveAmount,"persistant":persistant,"sprite":$Sprite3D.texture})
		else:
			ret = body.pickup({"giveName":giveString,"giveAmount":giveAmount,"persistant":persistant,"sprite":$Sprite3D.texture,"limit":limit})
			
	
	
	
	if ret == false:
		return
	if "inventory" in body or body.has_method("pickup"):
		var audioNode = $AudioStreamPlayer3D
		if is_instance_valid(audioNode):
			addToNode(body,audioNode)
			audioNode.play()
			audioNode.connect("finished",audioNode,"queue_free")
			
		queue_free()



func addToNode(targetNode,toAdd):
	remove_child(toAdd)
	targetNode.add_child(toAdd)
	
