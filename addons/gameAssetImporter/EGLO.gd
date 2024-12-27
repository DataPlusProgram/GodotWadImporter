@tool
class_name EGLO
extends Node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

static var curPoint : ColorRect = null

static func drawPoint2D(tree : SceneTree,position : Vector2):
	var point = ColorRect.new()
	point.size = Vector2(2,2)
	point.position = position - point.size*0.5
	point.color = Color.RED
	point.z_index = 3
	
	if is_instance_valid(curPoint):
		curPoint.queue_free()
	
	curPoint = point
	
	tree.get_root().add_child(point)

static func bindConsole(tree):
	
	if Engine.is_editor_hint():
		return
	
	if tree.has_meta("bindedConsole"):
		return tree.get_meta("bindedConsole")
	
	var node = Node.new()
	node.set_script(load("res://addons/gameAssetImporter/scenes/console/consoleActivateBind.gd"))
	tree.get_root().add_child(node)
	return node
	
	
static func fetchConsole(tree : SceneTree) -> Node:
	if tree.has_meta("consoleNode"):
		return tree.get_meta("consoleNode")
		
	var consoleNode : Node = load("res://addons/gameAssetImporter/scenes/console/consoleWindow.tscn").instantiate()
	consoleNode.visible = false
	
	tree.get_root().call_deferred("add_child",consoleNode)
	tree.set_meta("consoleNode",consoleNode)
	#consoleNode.popup_centered_ratio()
	
	return consoleNode

static func registerConsoleCommands(tree:SceneTree,script):
	fetchConsole(tree).registerScript(script)

static func rgbToHSV(r: float, g: float, b: float) -> Array:
	r /= 255.0
	g /= 255.0
	b /= 255.0

	var max_val = max(r, g, b)
	var min_val = min(r, g, b)
	var h = 0.0
	var s = 0.0
	var v = max_val

	var d = max_val - min_val
	s = 0 if max_val == 0 else d / max_val

	if max_val == min_val:
		h = 0.0 # achromatic
	else:
		match max_val:
			r:
				h = (g - b) / d + (6 if g < b else 0)
			g:
				h = (b - r) / d + 2
			b:
				h = (r - g) / d + 4
		h /= 6.0

	return [h, s, v]

static  func printFileAsHex(filePath : StringName):
		var data = FileAccess.get_file_as_bytes(filePath)
	
		var file
		
		var hex = ""
		
		for i in data:
			hex += "%0x," % i
		
		print(hex)
		
		
