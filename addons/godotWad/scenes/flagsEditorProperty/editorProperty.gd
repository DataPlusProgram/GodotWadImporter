@tool
extends EditorProperty
class_name FlagProperty


func _ready():
	var scene = load("res://addons/godotWad/scenes/flagsEditorProperty/flagEditorSecene.tscn").instantiate()
	var values = get_edited_object()[get_edited_property()]
	
	
	scene.setValues(values)
	scene.connect("valueChange", Callable(self, "valueChange"))
	add_child(scene)


func valueChange(arr : Array):
	var obj = get_edited_property()
	print(get_edited_object())
	
	var easy = arr[0]
	var medium =arr[1]
	var hard =arr[2]
	var multi =arr[3]
	
	var res = (easy * 0b1) +(medium * 0b10) + (hard * 0b100) + (multi * 0b1000) 

	
	#get_edited_object()[get_edited_property()] = 
	emit_changed(get_edited_property(),res)
	#get_edited_object()[get_edited_property()] = true
	
