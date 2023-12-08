tool
signal pathSet
extends Control

var required = false
var many = true
var popupStrings = []
var popupMenu : PopupMenu = null


func _ready():
	$h/Button2.visible = false

func setText(txt):
	$h/Label.text = txt

func setExt(arr):
	$FileDialog.filters = arr

func setAsDir():
	$FileDialog.mode = FileDialog.MODE_OPEN_DIR

func _on_Button_pressed():
	$FileDialog.popup_centered_ratio(0.5)


func _on_FileDialog_file_selected(path):
	if !OS.has_feature("standalone"):
		path = ProjectSettings.localize_path(path)
	$h/pathTxt.text = path


func getPath():
	return $h/pathTxt.text

func setPathText(txt):
	 $h/pathTxt.text = txt

func _on_pathTxt_text_changed(path):
	emit_signal("pathSet",path)


func setErrorText(txt):
	$ErrorText.bbcode_text = "[color=red] "+txt

func _draw():
	if popupMenu != null:
		var rect = popupMenu.get_global_rect()
		var w = rect.size.x
		
		var xRes = get_viewport().size.x
		if (rect.position.x + w )> xRes:
			var diff = (rect.position + rect.size).x - xRes
			popupMenu.rect_position.x -= diff
			
func _physics_process(delta):
	if $ErrorText.text.empty():
		$ErrorText.visible = false
	else:
		$ErrorText.visible = true
	
	if $ErrorText.visible and !getPath().empty():
		$ErrorText.visible = false
	
	
	
	var x = $h/pathTxt.text
	if !$h/pathTxt.text.empty() and many:
		$h/Button2.visible = true
		
	

	
	

func _on_Button3_pressed():
	
	if popupMenu == null:
		popupMenu = load("res://addons/gameAssetImporter/scenes/makeUI/optionList.tscn").instance()
		add_child(popupMenu)
	
	popupMenu.clear()
	
	popupMenu.connect("id_pressed",self,"optionPathSelect")
	
	popupMenu.popup_centered_ratio(0.1)
	popupMenu.rect_position = get_global_mouse_position()
	
	for i in popupStrings:
		popupMenu.add_item(i)
	
	update()

func optionPathSelect(var id):
	setPathText(popupMenu.get_item_text(id))

	


func _on_Button2_pressed():
	var dupe = self.duplicate()
	dupe.setText("")
	get_parent().add_child(dupe)


func _on_FileDialog_dir_selected(dir):
	$h/pathTxt.text = dir

