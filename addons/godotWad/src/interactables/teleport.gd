extends Node3D

var disabled = false
@export var globalScale: Vector3 = Vector3.ONE
@export var sectorIdx: int = -1
@export var targets: Dictionary = {}
@export var pointTarget : Vector2 = Vector2(-INF,-INF)

var animTextureNode = null
var spriteNode = null
var initSpritePos = null
var floorNode = null
var ceilNode = null


var mapNode = null
func _ready():
	
	if targets.size() <0:
		return
	mapNode = get_node("../../../")
	var keys = targets.keys()
	keys.sort()

	
	for i in keys:
		
	
		floorNode =  mapNode.get_node(targets[i]["floor"])
		ceilNode = mapNode.get_node(targets[i]["ceiling"])
		break
		#var node = mapNode.get_node(i)
				#
		#if node.has_meta("ceil"):
			#ceilNode = node
				#
		#if node.has_meta("floor"):
			#floorNode = node

func _physics_process(delta: float) -> void:
	if animTextureNode == null:
		return

	if animTextureNode.current_frame == animTextureNode.frames-1:
		if is_instance_valid(spriteNode):
			spriteNode.visible = false
		else:
			spriteNode = null

func body_entered(body,tag):
	if disabled:
		return
	
	
	if mapNode == null:
		return
	
	var destTargets = {}
	 
	if body.get_class() != "StaticBody3D":
		var possibleDests = []
			
		
		var destNodes = get_tree().get_nodes_in_group("destination:"+str(tag))
		
		for i in destNodes:
			var pos = i.global_transform.origin
			var sectorInfo = WADG.getSectorInfoForPoint(mapNode,Vector2(pos.x,pos.z))
			var secIdx = sectorInfo["sectorIdx"]
			if  !destTargets.has(secIdx): 
				destTargets[secIdx] = []
			
			destTargets[secIdx].append(i)
			
		
		var secSorted : Array = destTargets.keys()
		secSorted.sort()
		
		
		if pointTarget.x != -INF:
			var posY = floorNode.global_position.y
			teleportBody(body,Vector3(pointTarget.x,posY,pointTarget.y),null)
		
		for secIdx in secSorted:
			for target in destTargets[secIdx]:
				if destTargets.size()>0:
					var destNode = target
					
					
					var pos = destNode.global_transform.origin
					var path = targets[secIdx]["floor"]
					
					if path == null:
						print("error:teleport destination not found")
						continue
					
					var cFloorNode = mapNode.get_node_or_null(path)
					
					
					
					#var t = mapNode.get_node("Geometry/sector 3/floor FLOOR0_1")
					
					if cFloorNode == null:
						for i in destNode.get_children():
							if i is RayCast3D:
								i.enabled = true
								i.force_raycast_update()
								i.enabled = false
								pos.y = i.get_collision_point().y
					else:
						pos.y = cFloorNode.global_position.y
						
						
					
					
					
					if body.has_method("teleport"):
						
						if destNode.damageArea !=null:
							for i in destNode.damageArea.get_overlapping_bodies():
								if i.has_method("takeDamage"):
									i.takeDamage({"amt":10000 ,"position":destNode.global_position})
						
						
				
						
						spriteNode = destNode.get_child(0)
						
						
						if initSpritePos == null:
							initSpritePos = spriteNode.position
					
						#spriteNode.position = initSpritePos - body.global_transform.basis.z * 0.6

						spriteNode.texture.current_frame = 0
						spriteNode.visible = true
						animTextureNode = spriteNode.texture
						
						teleportBody(body,pos,destNode.rotation)
						
						if "velocity" in body:
							spriteNode.position = initSpritePos - body.velocity.normalized() * 0.7
						
						if "velocity" in body:
							body.velocity = Vector3.ZERO
						
						if get_node_or_null("sound")!= null:
							get_node("sound").play()


func teleportBody(body,pos,rot):
	body.teleport(pos,rot,200)
	
	
	
	
