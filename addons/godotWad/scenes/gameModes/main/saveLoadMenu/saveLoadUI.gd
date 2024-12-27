extends Control

signal gameLoadedSignal

var img = null

enum MODE{
	SAVE,
	LOAD
}

@export var mode : MODE:
	set = modeChange



var isReady = false
var customFont : FontFile = null : set = setFont
var gameName = ""
func _ready():
	isReady = true
	%fileList.selectedSignal.connect(saveSelected)
	mode = mode




func _process(delta):
	
	
	if %fileList.selectedItem == null:
		%DeleteButton.disabled = true
		%LoadButton.disabled = true
		%SaveButton.disabled = true
	else:
		%DeleteButton.disabled = false
		%LoadButton.disabled = false
		%SaveButton.disabled = false
	
	if mode == MODE.SAVE:
		%SaveButton.visible = $Node.canSave()
		
	if Input.is_action_just_pressed("ui_accept"):
		if mode == MODE.LOAD:
			if visible and !%DeleteConfirmationDialog.visible:
				if is_instance_valid(%fileList.selectedItem):
					if %fileList.selectedItem.has_meta("filePath"):
			
						$Node.loadJ(get_parent().mainMode.get_node("WadLoader"),%fileList.selectedItem.get_meta("filePath"))
		else:
			if visible:
				if %fileList.selectedItem.has_meta("filePath"):
					if !%DeleteConfirmationDialog.visible:
						var wadLoader = get_parent().mainMode.get_node("WadLoader")
						$Node.saveJ(wadLoader.params,wadLoader.config,"",img)
						populateList()
						%fileList.selectIdx(2)
	
func setFont(font : FontFile):
	%DeleteButton.set("theme_override_fonts/font",customFont)
	

func canSave():
	return $Node.canSave()

func _on_visibility_changed():
	
	if !isReady:
		await ready
	
	if visible == false:
		if $"..".cur == null:
			return
			
		$"..".cur.grab_click_focus()
		$"..".cur.grab_focus()
		return
	
	populateList()
	
	if %fileList.itemCount() > 0:
		%fileList.selectIdx(0)
	
	var selectedItem = %fileList.selectedItem
	
	if selectedItem != null:
		
		if is_instance_valid(selectedItem):
			saveItemSelected(selectedItem.get_meta("filePath"),selectedItem)
	
var curSelected = null

func saveItemSelected(filePath,node):
	curSelected = node
	
	if mode == MODE.SAVE:
		if node.text != "[new save]":
			%SaveButton.text = "Overwrite"
		else:
			%SaveButton.text = "Save"
			
	var image = $Node.getImage(filePath)
			
	if image != null:
		if %previewImage.texture == null:
			%previewImage.texture = ImageTexture.new()
		
		if %previewImage.texture.get_class() == "CompressedTexture2D":
			%previewImage.texture = ImageTexture.new()
		
		%previewImage.texture.image = image
	else:
		%previewImage.texture = null
		
		
	var meta = $Node.getMeta(filePath)

	if meta.is_empty():
		return
	
	
	var dateTime : Dictionary = meta["dateTime"]
	
	%dateTime.text = str(dateTime["day"]) + "/"+ str(dateTime["month"])+"/" + str(dateTime["year"])
	%dateTime.text += "         "
	%dateTime.text += str(dateTime["hour"]) + ":"+ str(dateTime["minute"])+":" + str(dateTime["second"])
	
	%mapName.text = meta["mapName"]
	



func populateList(focusMostRectent = false):
	
	%fileList.clear()
	
	if mode == MODE.SAVE:
		var item : Node = %fileList.add_item("[new save]")
		item.set_meta("filePath","")
	
	var saveFile : Dictionary = WADG.getAllInDirRecursive("user://gameSaves/"+gameName,"save")
	var files = saveFile.values()
	#files.reverse()
	files = [sortByModifyDate(files[0])]
	
	for i in files:
		for file : String in i:
			if FileAccess.open(file,FileAccess.READ).get_length() > 0:
				var item : Node = %fileList.add_item(file.get_file())
				item.set_meta("filePath",file)
	
	%fileList.selectIdx(0)


func _on_load_button_pressed():
	var loader : Node = get_parent().mainMode.get_node("WadLoader")
	$Node.loadJ(loader,%fileList.selectedItem.get_meta("filePath"))
	
	
func sortByModifyDate(paths : Array):
	
	var ret = []
	
	for path in paths:
		ret.append([FileAccess.get_modified_time(path),path])
	
	ret.sort_custom(compareFiles)
	var ret2 = []
	
	for i in ret:
		ret2.append(i[1])
		
	return ret2
	
func compareFiles(a, b):
	return a[0] > b[0]
	
func modeChange(newMode : MODE):
	
	if !isReady:
		await ready
	
	mode = newMode
	
	if newMode == MODE.SAVE:
		
		%LoadButton.visible = false
		%SaveButton.visible = true
	
	
	if newMode == MODE.LOAD:
		
		%LoadButton.visible = true
		%SaveButton.visible = false
	


func _on_node_load_finished_signal():
	visible = false
	emit_signal("gameLoadedSignal")


func _on_close_button_pressed():
	hide()

func saveSelected(node):
	var path : String = node.get_meta("filePath")
	saveItemSelected(path,node)
	updateScrollManual(curSelected)


	

func updateScrollManual(curSelected):
	if curSelected != null:
		var scroll : ScrollContainer = $VBoxContainer/MarginContainer/SplitContainer/VBoxContainer2/ScrollContainer
			
		var start = scroll.scroll_vertical
		var end = scroll.size.y + scroll.scroll_vertical
		var cur = curSelected.position.y
			
		if cur +  curSelected.size.y > end:
			scroll.scroll_vertical += (cur+(curSelected.size.y*2)) -end
			
		if cur -  curSelected.size.y < start:
			scroll.scroll_vertical += (cur-curSelected.size.y) -start
	
func _on_save_button_pressed():
	if !$Node.canSave():
		return
	
	var path = ""
	
	if curSelected != null:
		path = curSelected.get_meta("filePath")
		
		if WADG.doesFileExist(path):
			DirAccess.remove_absolute(path)
		
	
	for i in get_tree().get_nodes_in_group("player"):
		if "processInput" in i:
			i.processInput = true
				
		if i.has_method("enableInput"):
			i.enableInput()
		
	
	var wadLoader : Node = get_parent().mainMode.get_node("WadLoader")
	$Node.saveJ(wadLoader.params,wadLoader.config,"",img)
		
	for i in get_tree().get_nodes_in_group("player"):
		if "processInput" in i:
			i.processInput = true
				
		if i.has_method("disableInput"):
			i.disableInput()

		
	populateList()
	%fileList.selectIdx(2)
		
func getImage():
	img = $Node.getSavePictureData()


func _on_dekete_button_pressed():
	%DeleteConfirmationDialog.popup_centered()
	get_viewport().gui_get_focus_owner().release_focus()
	pass # Replace with function body.



func _input(event):
	var just_pressed = event.is_pressed() and !event.is_echo()

	if Input.is_key_pressed(KEY_DELETE) and just_pressed:
		if %fileList.selectedItem != null:
			if visible:
				%DeleteConfirmationDialog.popup_centered()

func _on_delete_confirmation_dialog_confirmed():
	if %fileList.selectedItem != null:
		$Node.deleteSaveFile(%fileList.selectedItem.get_meta("filePath"))
		populateList()
	
