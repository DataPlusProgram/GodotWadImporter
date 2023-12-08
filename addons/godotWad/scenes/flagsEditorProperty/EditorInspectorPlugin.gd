extends EditorInspectorPlugin



func can_handle(object):
	return false
	return object is WAD_Map
	
	
func parse_property(object, type, path, hint, hint_text, usage):
	if path != "difficultyFlags":
		return


	add_property_editor(path,FlagProperty.new())
	
