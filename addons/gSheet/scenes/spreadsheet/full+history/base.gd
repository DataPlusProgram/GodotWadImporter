extends HSplitContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	$root3.fileLoadedSignal.connect(fileOpened)
	
	
	
	populate()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func populate():
	$RichList.add_item("[unsaved]")
	
func fileOpened(path : String):
	$RichList.add_item(path)
	
