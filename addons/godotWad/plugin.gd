@tool
extends EditorPlugin

var dock
var inspectoPluginFlags = preload("res://addons/godotWad/scenes/flagsEditorProperty/EditorInspectorPlugin.gd")

func _enter_tree():
	dock = load("res://addons/gameAssetImporter/scenes/toolbar.tscn").instantiate()
	dock.get_node("createAll").connect("pressed", Callable(self, "openMaker"))
	
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	dock.visible = false
	inspectoPluginFlags = inspectoPluginFlags.new()
	add_inspector_plugin(inspectoPluginFlags)
	
