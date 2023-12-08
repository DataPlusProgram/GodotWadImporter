tool
extends MenuButton


var popup
onready var sheet = $"../../../HBoxContainer/Spreadsheet/Control"

func _ready():
	popup = get_popup()
	popup.connect("id_pressed", self, "_on_item_pressed")



func _on_item_pressed(id):
	if id == 0:
		var curCol = sheet.curCol
		sheet.addColumn("",true,curCol,true)
		sheet.updateSizings()
	elif id == 1:
		#var actionDict = {"action":"delectColumn","index":cIdx}
		sheet.deleteCurCol()
	elif id == 2:
		sheet.moveCurColRight()
	elif id == 3:
		sheet.moveColLeft(sheet.curCol)
