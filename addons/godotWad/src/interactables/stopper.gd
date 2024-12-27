@tool
extends Node3D

var overlappingBodies = []
var walkOverBodies : Array = []

@export var triggerType :WADG.TTYPE

func _physics_process(delta):
	#if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
	for i in overlappingBodies:
		bodyIn(i)
	
	for body in walkOverBodies:
		bodyIn(body)
	
	walkOverBodies = []





func bodyIn(body):
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if body.interactPressed == false:
			return
	
	if body.get_class() != "StaticBody3D" and "interactPressed" in body:
		for c in get_parent().get_children():
			if c == self : continue
			
			if "active" in c:
				c.active = false
				
			if c.get_parent().has_meta("owner"):
				c.get_parent().set_meta("owner",false)
					
				

func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)
	

func bin(body):
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if !"interactPressed" in body:
			return
			
	if body.get_class() == "StaticBody3D": return
	
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)
	
	
func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
