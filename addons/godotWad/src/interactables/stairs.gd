extends Spatial


var type
export(Array) var info
export(float) var inc = 0
var targetNodes = []
var stairGroups = []
var stairPos = []

var active = false
#var speed = 2
var targets = []
var triggerType = 0
var state  = STATE.TOP
var speed = 0.5
# Called when the node enters the scene tree for the first time.

enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}


func _ready():
	

	var t = info
	for i in info:
		
		var nodesInStair = []
		for target in i["targets"]:
			
			var node =$"../../../".get_node(target)
			nodesInStair.append(node)
		stairGroups.append(nodesInStair)
		stairPos.append(0)
	
	




func _physics_process(delta):
	
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			#if c.get_class()
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)
	
	if active:
		for idx in stairGroups.size():
			if stairPos[idx] < inc*(idx+1):
				for node in stairGroups[idx]:
					node.translation.y += speed
					#print(node.name)
			stairPos[idx] += speed
		
		
	
			

func bodyIn(body):
	if body.get_class() != "StaticBody":
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
			if "interactPressed" in body:
				if body.interactPressed == false:
					return
				else:
					if get_node_or_null("buttonSound") != null:
						if state != STATE.GOING_DOWN and state != STATE.GOING_UP:
							get_node("buttonSound").play()
		
		
		active = true
	
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
				for i in get_children():
					i.queue_free()

