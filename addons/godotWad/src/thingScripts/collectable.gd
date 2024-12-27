@tool
extends Node3D
@export var itemName = "nullItem"

var toInventory = false

@export var giveString: Array[String] = []
@export var giveAmount: Array[float] = []
@export var persistant: Array[bool] = []
@export var limit: Array[float] = []
@export var pickupSound : AudioStream = null
@export var uiTextureName : Array = []
@export var uiTarget : Array = []
@export var gameName : String = ""
@export var entityName : String = ""
@export var isStaticItem = false
@onready var isEditor = Engine.is_editor_hint()
@onready var soundManager = ENTG.getSoundManager(get_tree())
@onready var area := $Area3D
@onready var areaCollision = $Area3D/CollisionShape3D
@export var countsTowardsPercent = false
@export var mapHandlesDisable : bool = true

@export var oscillationHeight : float= 0
@export var oscillationSpeed : float= 0

var activationDistance := 17
var isEnabled := true
var itt = 0
var h = 0
var overlapping : Array[Node]= []
var mapNode : Node = null
var allPlayerPos :PackedVector3Array = []
func _ready():
	
	if isEditor:
		return
	
	if oscillationSpeed > 0:
		$MeshInstance3D.position.y -= $MeshInstance3D.mesh.size.y
	
	$Area3D.connect("body_entered", Callable(self, "bodyIn"))
	$Area3D.connect("body_exited", Callable(self, "bodyOut"))
	h = WADG.getCollisionShapeHeight($Area3D/CollisionShape3D)
	$groundCast.setHeight(h/2.0)
	
	if mapNode == null:
		if get_node_or_null("../../") != null:
			mapNode = $"../../"
	
	
	if isStaticItem:
		if mapNode != null:
			if countsTowardsPercent:
				mapNode.registerItemCreation(itemName)
	

	if "allPlayersPos" in mapNode:
		allPlayerPos = mapNode.allPlayersPos
	

func _physics_process(delta):
	
	
	
	if isEditor:
		return
	
	itt += delta
	
	if oscillationSpeed > 0:
		$MeshInstance3D.position.y = oscillationHeight*sin(itt*oscillationSpeed) + $MeshInstance3D.mesh.size.y/2.0
	
	var skip = true
	var anyPlayerNear = false
	
	#if allPlayerPos.size() == 0:
		#anyPlayerNear = true
	#
	#for i in allPlayerPos:
		#if( (global_position - i).length_squared() < 300):
			#anyPlayerNear = true
		#
		#
	#if anyPlayerNear:
		#if area.monitoring == false:
			#enable()
	#else:
		#if area.monitoring == true:
			#disable()
		
	
	#for node in get_tree().get_nodes_in_group("player"):
	#	var diff : Vector3 = node.position - position

	#	if diff.length_squared() <= 10000:#100^2
	#		skip = false
	#		break
			
	for i in overlapping:
		pickedUp(i)


func bodyIn(body):
	if !overlapping.has(body):
		overlapping.append(body)
		
	
	
	
func bodyOut(body):
	if overlapping.has(body):
		overlapping.erase(body)
		

func pickedUp(body):
	if "inventory" in body and toInventory:
		var bodyInventory = body.inventory
	
	var ret = false
	
	
	for idx in giveString.size():
		var dict = {"giveName":giveString[idx],"giveAmount":giveAmount[idx],"persistant":persistant[idx],"sprite":$MeshInstance3D.mesh.material.get_shader_parameter("texture_albedo")}
		
		if limit[idx] != -1:
			dict["limit"] = limit[idx]
		
		if !uiTextureName.is_empty():
			dict["uiTexture"] =[uiTarget[idx],uiTextureName[idx],gameName,entityName]
		
		if body.has_method("pickup"):
			ret = body.pickup(dict)
	
	if ret == false:
		return
	if "inventory" in body or body.has_method("pickup"):
	
		soundManager.play(pickupSound,self,{"unique":true})
		
		if isStaticItem:
			mapNode.registerItemDeletion(itemName)
		queue_free()
	

func addToNode(targetNode,toAdd):
	remove_child(toAdd)
	targetNode.add_child(toAdd)
	
func serializeSave():
	return {"isStaticItem":isStaticItem}
	
	
func serializeLoad(dict):
	isStaticItem = dict["isStaticItem"]

func disable():
	area.set_physics_process(false)
	area.monitoring = false
	areaCollision.disabled = true
	
func enable():
	area.set_physics_process(true)
	area.monitoring = true
	areaCollision.disabled = false
