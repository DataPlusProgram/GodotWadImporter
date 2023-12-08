tool
extends HSplitContainer
signal hDraw
signal hDrag
onready var lastAmount = split_offset


func _ready():
	connect("draw",self,"draw")
	connect("dragged",self,"dragged")
	
func draw():
	emit_signal("hDraw",self)
	
func dragged(amt):
	emit_signal("hDrag",amt,self)

#func _input(event):
#	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT:
#			if !event.is_pressed():
#				print("released")
