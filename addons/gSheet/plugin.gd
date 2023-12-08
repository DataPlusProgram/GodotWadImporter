tool
extends EditorPlugin
signal dictChanged

var interface =  preload("res://addons/gSheet/scenes/spreadsheet/full/spreadsheetFull.tscn").instance()
var curObj = null
var objectLastSaved = null
var importPlugin

  

func get_importer_name():
	return "csv to gsheet"
	


func _enter_tree():
	interface.connect("dictChanged",self,"dictChanged")
	
	
	get_editor_interface().get_editor_viewport().add_child(interface)
	
	make_visible(false)
	interface.get_parent().connect("draw",self,"draw")
	
	importPlugin = preload("res://addons/gSheet/importPlugin.gd").new()
	add_import_plugin(importPlugin)


func get_plugin_name():
	return "Sheet"

func handles(object):
	return object is gsheet

func _exit_tree():
	if is_instance_valid(interface):
		interface.queue_free()
		
	remove_import_plugin(importPlugin)
	importPlugin = null

func has_main_screen():
	return true

func edit(object):
	curObj = object
	interface.setTitle(curObj.get_path())
	
	var file = File.new()
	objectLastSaved = file.get_modified_time(curObj.get_path())
	
	if curObj.data.empty():
		var tmp = gsheet.new()
		curObj.data = tmp.data.duplicate()
		
		
	interface.get_node("VBoxContainer/HBoxContainer/Spreadsheet/Control").dataIntoSpreadsheet(curObj.data.duplicate(true))
	


func make_visible(visible):#this dictates what type of node will bring you to the toolbar:
	if interface:
		interface.visible = visible

func draw():
	interface.rect_size = interface.get_parent().rect_size

var timer = 0

func _process(delta):
	interface.rect_size = interface.get_parent().rect_size

func dictChanged(dict):

	if curObj == null:
		return
		
	curObj.data = dict
	
	

var counter = 0

#func _physics_process(delta):
#	if curObj == null:
#		return
#	counter += delta
#
#	if counter > 2:
#		var file = File.new()
#		var saveTime = file.get_modified_time(curObj.get_path())
#
#		print(interface.get_node("VBoxContainer/HBoxContainer/Spreadsheet/Control").needsSaving)
#		if saveTime != objectLastSaved and interface.get_node("VBoxContainer/HBoxContainer/Spreadsheet/Control").needsSaving:
#			saveTime = objectLastSaved
#			interface.get_node("VBoxContainer/HBoxContainer/Spreadsheet/Control").needsSaving = false
#			#interface.setTitle("diofj")
#
#		counter = 0
