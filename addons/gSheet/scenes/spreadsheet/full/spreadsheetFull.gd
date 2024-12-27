@tool
extends Control
signal dictChangedSignal
signal nowAWindow
signal fileLoadedSignal

@export var allowImportTres = false
@export var showSaveButton = false

@export var maxX : int = 9999

var saveCooldown = false
var defualtFont = null
@onready var mainSheet = %sheet.get_node("Control")

func _ready():
	

	
	var dim = mainSheet.getDim()
	if dim.x > maxX:
		mainSheet.setNumRows(maxX)
	
	mainSheet.dictChangedSignal.connect(dictChanged)
	mainSheet.fileLoadedSignal.connect(fileLoaded)
	#$DataFromText.confirmed.connect(_on_data_from_text_confirmed)
	#$DataFromText.confirmed
	#$DataFromText.connect("confirmed",_on_data_from_text_confirmed)
	if !allowImportTres:
		#var menu : MenuButton = $VBoxContainer/Panel/HBoxContainer2/ButtonFile
		var menu : MenuButton = %toolBar.get_node("%importFileDropDown")
		
		#menu.get_popup().remove_item(2)
		
	if showSaveButton:
		$VBoxContainer/Panel/HBoxContainer2/ButtonSave.visible = true

func dictChanged(dict):
	emit_signal("dictChangedSignal",dict)

func setTitle(text):
	%pathLabel.text = text

func getTitle(text):
	return %pathLabel.text



func _physics_process(delta):
	saveCooldown = false




func _on_path_label_gui_input(event):
	if !event is InputEventMouseButton:
		return
		
	if event.button_index != MOUSE_BUTTON_RIGHT:
		return
	
	if event.pressed:
		return
	
	var pathText : String = %pathLabel.text
	
	if pathText.is_empty():
		return
	
	pathText = ProjectSettings.globalize_path(pathText)
	OS.shell_open(pathText)
	


func _on_top_bar_popup_index_pressed(index):
	if index == 0:
		%sheet.get_node("Control").forceKeysToInt()
	
func fileLoaded(path : String):
	emit_signal("fileLoadedSignal",path)
