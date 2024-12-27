@tool
extends EditorPlugin
signal dictChangedSignal

var interface =  null#load("res://addons/gSheet/scenes/spreadsheet/full/spreadsheetFull.tscn").instantiate()

var curObj = null
var objectLastSaved = null
var importPlugin
var saveCooldown = false
var internalModifiedTime = 0
func _get_importer_name():
	return "csv to gsheet"
	


func _enter_tree():
	get_tree().set_meta("baseControl",EditorInterface.get_base_control())
	importPlugin = load("res://addons/gSheet/importPlugin.gd").new()
	add_import_plugin(importPlugin)
	
	_make_visible(false)
	
	if interface == null:
		createInterface()
	
	

	
func createInterface():
	var interfacePackedScene = load("res://addons/gSheet/scenes/spreadsheet/full/spreadsheetFull.tscn")
	
	if interfacePackedScene == null:
		return
	
	interface = interfacePackedScene.instantiate()
	setInterface(interface)
	

func setInterface(inter):
	inter.dictChanged
	inter.dictChangedSignal.connect(dictChanged)
	inter.connect("nowAWindow",becameAWindow)
	interface.defualtFont = get_editor_interface().get_base_control().get_theme_default_font()
	EditorInterface.get_editor_main_screen().add_child(interface)
	interface.get_parent().resized.connect(draw)
	
	

func _get_plugin_name():
	return "Sheet"

func _handles(object):

	return object is gsheet

func _exit_tree():
	if is_instance_valid(interface):
		interface.queue_free()
		
	remove_import_plugin(importPlugin)
	importPlugin = null

func _has_main_screen():
	return true

func _edit(object):
	if object == null:
		return
	curObj = object
	
	
	interface.setTitle(curObj.resource_path)
	
	var file = FileAccess
	objectLastSaved = file.get_modified_time(curObj.get_path())
	
	if curObj.data.is_empty():
		var tmp = gsheet.new()
		curObj.data = tmp.data.duplicate()
		
		
	interface.get_node("%sheet").get_node("Control").dataIntoSpreadsheet(curObj.data.duplicate(true))
	


func _make_visible(visible):#this dictates what type of node will bring you to the toolbar:
	
	if interface == null:
		createInterface()
		if interface == null:
			return
	
	if interface.get_parent().get_class() == "Window":
		interface.visible = true
		
		if visible:
			if interface.get_parent().mode == Window.MODE_MINIMIZED:
				interface.get_parent().mode = Window.MODE_WINDOWED
			interface.get_parent().grab_focus()
		
		return
	
	
	
	if interface:
		interface.visible = visible

func draw():
	interface.size = interface.get_parent().size

var timer = 0

func _process(delta):
	if interface == null:
		return
	interface.size = interface.get_parent().size

func dictChanged(dict):
	if curObj == null:
		return
	
	
	internalModifiedTime = Time.get_time_dict_from_system()
	curObj.data = dict
	
	

var counter = 0

func _physics_process(delta):
	saveCooldown = false

func  _unhandled_input(event):
	
	if saveCooldown: 
		return
	
	if !Input.is_key_pressed(KEY_CTRL):
		return
	
	if !event is InputEventKey:
		return
	
	if event.key_label != KEY_S:
		return
	
	if event.is_echo():
		return
	
	if !event.pressed:
		return

	if curObj == null:
		return
		
	ResourceSaver.save(curObj,curObj.resource_path)
	interface.setTitle(curObj.resource_path)
	
func becameAWindow():
	interface.get_parent().window_input.connect(_unhandled_input)
