tool
extends MenuButton

var popup
onready var sheet = $"../../../HBoxContainer/Spreadsheet/Control"


func _ready():
	popup = get_popup()
	popup.connect("id_pressed", self, "_on_item_pressed")


func _on_item_pressed(id):
	if id == 0:
		$"../ButtonFromCSV/FileDialog".popup_centered_ratio(0.5)
	elif id == 1:
		$"../../../../DataFromText".popup_centered_ratio(0.5)
	elif id == 2:
		var fileDiag = FileDialog.new()
		
		fileDiag.filters = ["*.tres"]
		fileDiag.mode = FileDialog.MODE_OPEN_FILE
		fileDiag.access = FileDialog.ACCESS_FILESYSTEM
		fileDiag.connect("file_selected",self,"open")
		add_child(fileDiag)
		fileDiag.popup_centered_ratio()
		#sheet.loadFromFile("res://things.tres")
		
		


func open(path):
	var r = load(path)
	if !"data" in r:
		
		var acceptDialog = AcceptDialog.new()
		add_child(acceptDialog)
		acceptDialog.dialog_text = "Not a gSheet resource"
		acceptDialog.popup_centered() 
		return
	
	var filePathLabel = $"../../../Label"
	filePathLabel.text = path
	sheet.loadFromFile(path)
	
