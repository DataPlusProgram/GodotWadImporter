extends Area



var sectorTag = -1
var sectorInfo
var triggerType
var overlappingBodies = []

func _ready():
	sectorTag = get_meta("sectorTag")
	sectorInfo = get_meta("sectorIdx")
	

func bin(body):
	if body.get_class() == "StaticBody": return
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
	var mySectorType = -1
	if has_meta("fTextureName"):
		myTexture = get_meta("fTextureName")
		
	if has_meta("fType"):
		mySectorType = get_meta("fType")
	
	get_parent().body_entered(body,myTexture,sectorInfo,mySectorType)
	
	
