@tool
extends Control


func _process(delta):
	var sum = 0
	
	
	for i in get_children():
		if "size" in i:
			sum += i.size.x
	
	size.x = sum



func _ready():
	$TextureButton.connect("toggled", Callable(self, "toggled"))

func setAudio(stream):
	$AudioStreamPlayer.stream = stream


func setText(txt):
	$LineEdit.text = txt



func toggled(button_pressed):
	if button_pressed:
		$AudioStreamPlayer.play()
	else:
		$AudioStreamPlayer.stop()
	
