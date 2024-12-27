@tool
extends MenuButton

var popup
var sheet = null


func _ready():
	await $"../../../../".ready
	sheet = $"../../../../".get_node("%sheet").get_node("Control")
	
	popup = get_popup()
	popup.id_pressed.connect(_on_item_pressed)


func _on_item_pressed(id):
	
	if id == 0:
		$"../ButtonFromCSV/FileDialog".popup_centered_ratio(0.5)
	elif id == 1:
		$"../../../../DataFromText".popup_centered_ratio(0.5)
	elif id == 2:
		var fileDiag : FileDialog= FileDialog.new()
		
		fileDiag.filters = ["*.tres"]
		fileDiag.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		fileDiag.access = FileDialog.ACCESS_FILESYSTEM
		fileDiag.use_native_dialog = true
		fileDiag.file_selected.connect(open)
		add_child(fileDiag)
		fileDiag.popup_centered_ratio()

		


func open(path):
	var r = load(path)
	if !"data" in r:
		
		var acceptDialog = AcceptDialog.new()
		add_child(acceptDialog)
		acceptDialog.dialog_text = "Not a gSheet resource"
		acceptDialog.popup_centered() 
		return
	
	var filePathLabel = $"../../../pathLabel"
	filePathLabel.text = path
	sheet.loadFromFile(path)
	
