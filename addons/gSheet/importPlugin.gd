tool
extends EditorImportPlugin

enum PRESETS { DEFAULT }

func get_importer_name():
	return "csvToGsheet"

func get_visible_name():#this is the name that appears  in the "Import As:" dropdown
	return "gsheet"


func get_recognized_extensions():
	return ["csv9"]
	
func get_save_extension():
	return "tres"

func get_resource_type():
	return "Resource"

func get_preset_count():
	return 1

func get_preset_name(preset):
	#if preset == PRESETS.DEFAULT:
	#	return
	return "Default"

func get_import_options(preset):
	#if preset == PRESETS.DEFAULT:
	#	return [{}]
	 return [{"name": "my_option", "default_value": false}]

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	print("im importing as: ",save_path + ".tres")
	var sheet = load("res://addons/gSheet/scenes/gsheet.gd").new()
	
	return ResourceSaver.save(save_path + ".tres",sheet)
	
