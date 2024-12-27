@tool
extends HSplitContainer
signal hDraw
signal hDrag

@onready var lastAmount = split_offset


func _ready():
	#connect("draw",self,"draw")
	#connect("dragged",self,"dragged")
	
	draw.connect(draw1)
	dragged.connect(dragged1)
	
func draw1():
	emit_signal("hDraw",self)
	
func dragged1(amt):
	emit_signal("hDrag",amt,self)

#func _input(event):
#	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT:
#			if !event.is_pressed():
#				print("released")
