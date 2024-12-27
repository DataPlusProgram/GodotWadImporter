extends Window

@export var isNewWindow = false
@export var showInternal : bool = false : set = showInternalSet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$ObjectInspector.size = size
	
	if isNewWindow:
		visible = true
	
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	


func _on_close_requested() -> void:
	visible = false
	
func set_object(object):
	$ObjectInspector.set_object(object)

func showInternalSet(value : bool):
	$ObjectInspector.show_internal = value
