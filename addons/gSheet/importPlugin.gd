@tool
extends EditorImportPlugin

enum PRESETS { DEFAULT }

func _get_importer_name():
	return "csvToGsheet"

func _get_visible_name():#this is the name that appears  in the "Import As:" dropdown
	return "gsheet"

func _get_recognized_extensions():
	return ["csv"]
	
func _get_save_extension():
	return "tres"

func _get_resource_type():
	return "Resource"

func _get_preset_count():
	return 1


func _get_preset_name(preset):
	#if preset == PRESETS.DEFAULT:
	#	return
	return "Default"

func _get_import_options(preset,index):
	#if preset == PRESETS.DEFAULT:
	#	return [{}]
	return [{"name": "my_option", "default_value": false}]

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	print("im importing as: ",save_path + ".tres")
	var sheet = load("res://addons/gSheet/scenes/gsheet.gd").new()
	
	return ResourceSaver.save(save_path + ".tres",sheet)
	
