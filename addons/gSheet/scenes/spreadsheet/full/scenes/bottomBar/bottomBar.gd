tool
extends HBoxContainer

var sheet : Node

func _on_Save_pressed():
	sheetGlobal.saveNodeAsScene(get_parent())



func _ready():
	if get_node_or_null("../../HBoxContainer/Spreadsheet/Control") != null:
		sheet = $"../../HBoxContainer/Spreadsheet/Control"

func _on_ButtonFromArray_pressed():
	var t : WindowDialog= $"../../DataFromText" 
	t.popup_centered_ratio(0.5)


var csvPath = ""

func _on_FileDialog_file_selected(path):
	#$ButtonFromCSV/csvHeadings.popup_centered()
	$ButtonFromCSV/csvOptions.popup_centered()
	
	var file = File.new()
	file.open(path,File.READ)
	var content = file.get_as_text()
	var countA = content.count(",")
	var countB = content.count(";")
	
	if countA > countB:
		$ButtonFromCSV/csvOptions/VBoxContainer/Delimeter/OptionButton.selected = 0
	else:
		$ButtonFromCSV/csvOptions/VBoxContainer/Delimeter/OptionButton.selected = 1
	
	csvPath = path
	


func _on_ButtonFromCSV_pressed():
	$ButtonFromCSV/FileDialog.popup()


func _on_ButtonSave_pressed():
	var dialog = FileDialog.new()
	dialog.filters = ["*.tres"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.MODE_SAVE_FILE
	dialog.current_path = $"../../Label".text
	#dialog.current_path = $"../../../Label".text
	add_child(dialog)
	var e  = dialog.connect("file_selected",self,"saveSheet")
	dialog.rect_size =  Vector2(600,600)
	dialog.popup_centered_ratio()
	

func saveSheet(string):
	var data = sheet.serializeData()
	var res = load("res://addons/gSheet/scenes/gsheet.gd").new()
	res.data = data
	ResourceSaver.save(string,res)

func _on_ButtonLoad_pressed():
	sheet.loadFromFile("res://dbg/savedFormat2.tres")
	sheet.updateSizings()


func _on_addCategory_pressed():
	sheet.addColumn("")
	sheet.updateSizings()





func _on_ButtonDeleteCurSol_pressed():
	sheet.deleteCurRow()
	pass # Replace with function body.


func _on_ButtonDeleteCurCol_pressed():
	sheet.deleteCurCol()


func _on_ButtonAddRow_pressed():
	sheet.addRow()
	sheet.updateSizings()
	


func _on_ButtonUndo_pressed():
	sheet.undo()
	pass # Replace with function body.


func _on_Button_pressed():
	sheet.serializeData()


func _unhandled_input(event):

	if event.get_class() != "InputEventKey":
		return
	
	var just_pressed = event.is_pressed() and !event.is_echo()
	
	if event.scancode == KEY_ENTER and just_pressed:
		if get_focus_owner() != null:get_focus_owner().release_focus()

	


func _on_ButtonCancel_pressed():
	$ButtonFromCSV/csvOptions.hide()
	pass # Replace with function body.


func _on_ButtonOk_pressed():
	var optionButton = $ButtonFromCSV/csvOptions/VBoxContainer/Delimeter/OptionButton
	var headings = $ButtonFromCSV/csvOptions/VBoxContainer/hasHeadings/CheckBoxHeadings.pressed
	var delimeter = optionButton.get_item_text(optionButton.get_selected_id())
	sheet.csvImport(csvPath,headings,delimeter)
	$ButtonFromCSV/csvOptions.hide()


func _on_ButtonSearch_pressed():
	$SearchDiag/WindowDialog.popup_centered()
	$SearchDiag/WindowDialog/MarginContainer/v/h/LineEdit.grab_focus()





func _on_ButtonFind_pressed():
	
	var caseSensitive = $SearchDiag/WindowDialog/MarginContainer/v/h2/caseButton.pressed
	var lookForText = $SearchDiag/WindowDialog/MarginContainer/v/h/LineEdit.text
	
	var ret = sheet.grabFocusIfTextFound(lookForText,caseSensitive)
	
	
	if ret == false:
		$SearchDiag/WindowDialog/MarginContainer/v/Label.text = "Match not found"
	else:
		$SearchDiag/WindowDialog/MarginContainer/v/Label.text = ""



func _on_ButtonAddRowAbove_pressed():
	var idx = sheet.curRow
	
	#if idx == -1: idx = 0
	
	var focus = sheet.addRow(true,idx,true,sheet.curCol)
	
	if focus != null:
		focus.grab_focus()
		



func _on_ButtonAddRowBelow_pressed():
	var idx = sheet.curRow+1
	var focus = sheet.addRow(true,idx,true,sheet.curCol)
	
	if focus != null:
		focus.grab_focus()


func _on_TextureButton_pressed():
	var idx = sheet.curCol
	var focus = sheet.addColumn("",true,idx)
	
	if focus != null:
		sheet.addColumn("",true,idx).grab_focus()



func _on_TextureButton2_pressed():
	var idx = sheet.curCol+1
	var focus = sheet.addColumn("",true,idx)
	
	if focus != null:
		focus.grab_focus()



func _on_TextureButtonColClose_pressed():
	sheet.deleteCurCol()


func _on_TextureButtonDeleCurRow_pressed():
	sheet.deleteCurRow()



