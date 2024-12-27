@tool
extends MenuButton


var popup
var sheet = null

func _ready():
	
	await $"../../../".ready
	sheet = $"../../../".get_node("%sheet").get_node("Control")
	popup = get_popup()
	popup.id_pressed.connect(_on_item_pressed)

func _on_item_pressed(id):
	if id == 0:
		sheet.moveColLeft(sheet.curCol)
		
	if id == 1:
		sheet.moveColRight(sheet.curCol)
		
	if id == 2:
		pass
	
	if id == 3: 
		pass
	
