tool
extends Control
signal dictChanged

export var allowImportTres = false
export var showSaveButton = false

func _ready():
	if !allowImportTres:
		var menu : MenuButton = $VBoxContainer/Panel/HBoxContainer2/ButtonFile
		menu.get_popup().remove_item(2)
		
	if showSaveButton:
		$VBoxContainer/Panel/HBoxContainer2/ButtonSave.visible = true

func dictChanged(dict):
	emit_signal("dictChanged",dict)

func setTitle(text):
	$VBoxContainer/Label.text = text

