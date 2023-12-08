tool
extends Control
var target = null



func _on_tetureFiltering_toggled(value):
	if target == null:
		return
	
	ENTG.clearEntityCaches(get_tree())
	target.textureFiltering = value
	target.get_node("LumpParser").sectorToRenderables = {}
	target.get_node("LumpParser").wallMatEntries = {}
	target.get_node("LumpParser").sectorToSides = {}
	target.get_node("ResourceManager").materialCache = {}
	target.get_node("ResourceManager").textureCache = {}
	
	target.wadInit = false

func scaleChangedValue(value):
	scaleChanged()

func scaleChanged():
	target == null
	target.scaleFactor = Vector3($v/scaleFactor/x.value,$v/scaleFactor/y.value,$v/scaleFactor/z.value)



func _on_difficultyOption_item_selected(index):
	target.difficultyFlags = index


func _on_createOccluder_toggled(button_pressed):
	target.addOccluder = button_pressed


func _on_mergeMeshOption_item_selected(index):
	target.mergeMesh = index



func _on_surroundingSkybox_toggled(button_pressed):
	target.createSurroundingSkybox = button_pressed
