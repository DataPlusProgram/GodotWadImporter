@tool
extends MenuButton


var popup
var sheet = null

func _ready():

	await  $"../../../".ready
	var sheet = $"../../../".get_node("%sheet").get_node("Control")
	popup = get_popup()
	#popup.connect("id_pressed", self, "_on_item_pressed")
	popup.id_pressed.connect(_on_item_pressed)


func _on_item_pressed(id):
	if id == 0:
		
		sheet.addRow(true,sheet.curRow,true)
		sheet.updateSizings()
	elif id == 1:
		sheet.deleteCurRow()
