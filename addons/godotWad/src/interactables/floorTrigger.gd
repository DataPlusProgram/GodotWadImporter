@tool
extends Node



var sectorTag = -1
var sectorInfo
var triggerType
var overlappingBodies = []
var ftexture : Texture2D = null
func _ready():
	
	if Engine.is_editor_hint():
		return
	
	sectorTag = get_meta("sectorTag")
	sectorInfo = get_meta("sectorIdx")
	
	
	

func bin(body):
	if body.get_class() == "StaticBody3D": return
	#if !body.is_in_group("player"): return
	
	
	#if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
	if !"interactPressed" in body:
		return
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)

func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
	
	
func _physics_process(delta):
	for body in overlappingBodies:
		bodyIn(body)
		
func bodyIn(body):
	#if body.get_class() != "StaticBody":
	var myTexture = null
	var mySectorType : Dictionary = {}
	if has_meta("fTextureName"):
		myTexture = get_meta("fTextureName")
		
	if has_meta("fType"):
		mySectorType = get_meta("fType")
	mySectorType["lightLevel"] = sectorInfo["lightLevel"]
	get_parent().bodyIn(body,myTexture,int(sectorInfo["index"]),mySectorType)
	
	
