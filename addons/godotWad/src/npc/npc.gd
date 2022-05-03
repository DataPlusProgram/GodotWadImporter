extends KinematicBody


var moveVec = Vector3.ZERO
var gravity =Vector3(0,-10,0)
var speed = 5
var deltaSum = 0
var hp = 30
var timeJitter = 0
var deathSounds : Array = []
var alive = true
export var npcName = ""

export var deathSprites = []

func _ready():
	setTarget()
	timeJitter = rand_range(0,5)
	

func _physics_process(delta):
	
	#var col = get_node("CollisionShape")

	if !alive:
		return
		
	for node in  get_tree().get_nodes_in_group("player"):
		var dist = global_transform.origin.distance_to(node.global_transform.origin)
		
		if dist > 90:
			return
			
			
	deltaSum += delta

	if hp <= 0:
		die()
		
	
	var vel = moveVec# + gravity
	
	

func damage(amt):
	hp -= amt


func die():
	if !alive: return
	
	
	var mapNode = $"../../"
	var curCount = mapNode.get_meta(npcName)-1
	
	mapNode.set_meta(npcName,curCount)
	
	if curCount == 0:
		for trigger in get_tree().get_nodes_in_group("counter_"+npcName):
			trigger.activate()
	
	#get_node("CollisionShape").queue_free()
	
	alive = false
	if get_node_or_null("deathSounds"):
		var numDeathSounds = $"deathSounds".get_child_count()
		if numDeathSounds > 0:
			randomize()
			var node = $"deathSounds".duplicate()
			node.transform = transform
			get_parent().add_child(node)
			node.get_child(randi() % numDeathSounds).play()
			#$"deathSounds".get_child(randi() % numDeathSounds).play()
	
	if !deathSprites.empty():
		var deadS 
		
		
		for i in get_children():
			if i.get_class() == "Sprite3D":
				deadS = i.duplicate()
				i.visible = false
				
				
				
				deadS.texture = deathSprites[0]
				deadS.transform = transform * i.transform
				deadS.transform.origin.y -= i.texture.get_height()/2.0 - deadS.texture.get_height()/4.0
				var par = get_parent()
				par.add_child(deadS)
				

				if par.has_method("reset_physics_interpolation"):
					 par.reset_physics_interpolation()
				

				break
	queue_free()
		
	
	


func setTarget():
	moveVec.x = rand_range(-1,1)*speed
	moveVec.z = rand_range(-1,1)*speed
	

func randomMove():
	var vec = Vector3.ZERO
	vec.x = rand_range(-1,1)
	vec.z = rand_range(-1,1)
