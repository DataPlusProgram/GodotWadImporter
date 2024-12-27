extends Button
@onready var rootNode = $"../../../../../../"

var ignorePressFlag = false

func _physics_process(delta):
	
	
	if rootNode.midiPlayer == null:
		visible = false
		return
	
	visible = true
	var midiPlayer = rootNode.midiPlayer
	
	
	
	if button_pressed == midiPlayer.playing:
		button_pressed = !midiPlayer.playing
		ignorePressFlag = true
	
	
	if button_pressed:
		text = "⏵"
	else:
		text = "||"


func _on_toggled(toggled_on):
	
	if ignorePressFlag:
		ignorePressFlag = false
		return
	
	var midiPlayer = rootNode.midiPlayer
	
	if midiPlayer.playing:
		midiPlayer.stop()
	else:
		midiPlayer.play()
	
