tool
extends MenuButton


var popup
onready var sheet = $"../../../HBoxContainer/Spreadsheet/Control"

func _ready():
	popup = get_popup()
	popup.connect("id_pressed", self, "_on_item_pressed")


func _on_item_pressed(id):
	if id == 0:
		
		sheet.addRow(true,sheet.curRow,true)
		sheet.updateSizings()
	elif id == 1:
		sheet.deleteCurRow()
