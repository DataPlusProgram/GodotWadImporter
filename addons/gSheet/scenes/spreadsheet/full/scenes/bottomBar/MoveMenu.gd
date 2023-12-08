tool
extends MenuButton


var popup
onready var sheet = $"../../../HBoxContainer/Spreadsheet/Control"

func _ready():
	popup = get_popup()
	popup.connect("id_pressed", self, "_on_item_pressed")


func _on_item_pressed(id):
	if id == 0:
		sheet.moveColLeft(sheet.curCol)
		
	if id == 1:
		sheet.moveColRight(sheet.curCol)
		
	if id == 2:
		pass
	
	if id == 3: 
		pass
	
