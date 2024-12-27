@tool
extends HBoxContainer

var sheet : Node

func _on_Save_pressed():
	sheetGlobal.saveNodeAsScene(get_parent())



func _ready():
	
	await $"../../".ready
	sheet =  $"../../".get_node("lower/sheet").get_node("Control")

func _on_ButtonFromArray_pressed():
	var t : Window= $"../../DataFromText" 
	t.popup_centered_ratio(0.5)


var csvPath = ""

func _on_FileDialog_file_selected(path):
	#$ButtonFromCSV/csvHeadings.popup_centered()
	$ButtonFromCSV/csvOptions.popup_centered()
	
	var file = FileAccess#File.new()
	#file.open(path,FileAccess.READ)
	var content = file.get_file_as_string(path)
	var countA = content.count(",")
	var countB = content.count(";")
	
	if countA > countB:
		%csvOptions.selected = 0
	else:
		%csvOptions.selected = 1
	
	csvPath = path
	


func _on_ButtonFromCSV_pressed():
	$ButtonFromCSV/FileDialog.popup()


func _on_ButtonSave_pressed():
	var dialog = FileDialog.new()
	dialog.filters = ["*.tres"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	
	dialog.current_path = $"../../pathLabel".text

	add_child(dialog)
	
	var e  = dialog.file_selected.connect(saveSheet)
	#dialog.size =  Vector2(600,600)
	dialog.popup_centered_ratio()
	

func saveSheet(string):
	var data = sheet.serializeData()
	var res = load("res://addons/gSheet/scenes/gsheet.gd").new()
	res.data = data
	$"../../pathLabel".text = string
	ResourceSaver.save(res,string)

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



#func _input(event : InputEvent):
	#if event.get_class() != "InputEventMouseButton":
		#return
		#
	#if event.button_index != 2:
		#return
		#
	#$"../../../topBarPopup".visible = true
	#$"../../../topBarPopup".position = event.position
	

func _unhandled_input(event : InputEvent):

	

	if event.get_class() != "InputEventKey":
		return
	
	var just_pressed = event.is_pressed() and !event.is_echo()
	
	
	
	if event.keycode == KEY_ENTER and just_pressed:
		
		if $SearchDiag/Window.get_viewport().gui_get_focus_owner() != null:
			$SearchDiag/Window.get_viewport().gui_get_focus_owner().release_focus()
		
		
		
		if get_viewport().gui_get_focus_owner() != null:
			get_viewport().gui_get_focus_owner().release_focus()

	


func _on_ButtonCancel_pressed():
	$ButtonFromCSV/csvOptions.hide()
	pass # Replace with function body.


func _on_ButtonOk_pressed():
	#var optionButton = $ButtonFromCSV/csvOptions/VBoxContainer/Delimeter/OptionButton
	var headings = %CheckBoxHeadings.button_pressed
	var delimeter = %csvOptions.get_item_text(%csvOptions.get_selected_id())
	sheet.csvImport(csvPath,headings,delimeter)
	$ButtonFromCSV/csvOptions.hide()


func _on_ButtonSearch_pressed():
	if !$SearchDiag/Window.visible:
		$SearchDiag/Window.popup_centered()
		$SearchDiag/Window/MarginContainer/v/h/LineEdit.grab_focus()
	else:
		$SearchDiag/Window.hide()
		searchResults = []
		searchIndex = 0
		$SearchDiag/Window/MarginContainer/v/h2/searchIndexLabel.text = ""



var searchResults = []
var searchIndex = 0


func _on_ButtonFind_pressed():
	
	var caseSensitive = $SearchDiag/Window/MarginContainer/v/h2/caseButton.button_pressed
	var lookForText = $SearchDiag/Window/MarginContainer/v/h/LineEdit.text
	
	var ret : Array= sheet.getArrayOfMatches(lookForText,caseSensitive)
	
	
	if ret.is_empty():
		$SearchDiag/Window/MarginContainer/v/Label.text = "Match not found"
		$SearchDiag/Window/MarginContainer/v/h2/prev.visible = false
		$SearchDiag/Window/MarginContainer/v/h2/next.visible = false
		$SearchDiag/Window/MarginContainer/v/h2/searchIndexLabel.text = ""
		return
	else:
		$SearchDiag/Window/MarginContainer/v/Label.text = ""
	
	$SearchDiag/Window/MarginContainer/v/h2/prev.visible = true
	$SearchDiag/Window/MarginContainer/v/h2/next.visible = true
	
	searchResults = ret
	ret[0].grab_focus()
	updateSearchIndexLabel()



func _on_ButtonAddRowAbove_pressed():
	var idx = sheet.curRow
	
	#if idx == -1: idx = 0
	var numInOrder = sheet.areRowsNumericalProgression()
	var focus = sheet.addRow(true,idx,true,sheet.curCol)
	
	if numInOrder:
		sheet.setSideLabelsToNumericProgression()
	
	if focus != null:
		focus.grab_focus()
		



func _on_ButtonAddRowBelow_pressed():
	var idx = sheet.curRow+1
	
	var numInOrder = sheet.areRowsNumericalProgression()
	
	var focus = sheet.addRow(true,idx,true,sheet.curCol)
	
	if numInOrder:
		sheet.setSideLabelsToNumericProgression()
	
	if focus != null:
		focus.call_deferred("grab_focus")
		#focus.grab_focus()
		


func _on_TextureButton_pressed():
	var idx = sheet.curCol
	var colsNumeric = sheet.areColsNumericalProgression()
	var focus = sheet.addColumn("",true,idx)
	
	if colsNumeric:
		sheet.setColLabelsToNumericProgression()

	if focus != null:
		focus.call_deferred("grab_focus")


func _on_TextureButton2_pressed():
	var idx = sheet.curCol+1
	var colsNumeric = sheet.areColsNumericalProgression()
	var focus = sheet.addColumn("",true,idx,true)
	
	if colsNumeric:
		sheet.setColLabelsToNumericProgression()
	
	if focus != null:
		focus.call_deferred("grab_focus")



func _on_TextureButtonColClose_pressed():
	sheet.deleteCurCol()


func _on_TextureButtonDeleCurRow_pressed():
	sheet.deleteCurRow()





func _on_csv_options_close_requested():
	$ButtonFromCSV/csvOptions.hide()
	pass # Replace with function body.


func _on_window_dialog_close_requested():
	$SearchDiag/Window.hide()
	pass # Replace with function body.


func _on_window_button_pressed():
	
	var par = get_node("../../../../")
	var everything = get_node("../../../")
	
	par.remove_child(everything)
	var window : Window= Window.new()
	window.title = $"../../pathLabel".text
	window.add_child(everything)
	par.add_child(window)
	
	
	window.close_requested.connect(unWindowify)
	
	window.popup_centered_ratio()
	everything.emit_signal("nowAWindow")
	%WindowButton.disabled = true
	
func unWindowify():
	var window = get_node("../../../../")
	var everything = get_node("../../../")
	window.remove_child(everything)
	window.get_parent().add_child(everything)
	window.queue_free()
	%WindowButton.disabled = false
	
	


func _on_next_pressed():
	if searchResults.size() == 0:
		return
	
	
	searchIndex = (searchIndex+1) % searchResults.size()  
	searchResults[searchIndex].grab_focus()
	updateSearchIndexLabel()
	

func updateSearchIndexLabel():
	var label = $SearchDiag/Window/MarginContainer/v/h2/searchIndexLabel
	label.text = str(searchIndex+1) + "/" + str(searchResults.size())
	
	
	
	
	


func _on_window_window_input(event):#searchbar input
	
	if $SearchDiag/Window.visible == false:
		return
		
	_unhandled_input(event)
