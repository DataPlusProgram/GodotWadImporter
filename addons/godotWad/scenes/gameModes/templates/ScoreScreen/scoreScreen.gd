extends Control

signal goNext


var intermissionData : Dictionary


# Called when the node enters the scene tree for the first time.
func _ready():
	if intermissionData.is_empty():
		return
		
	$TextureRect.texture = intermissionData.values()[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass




func _input(event):
	if !visible:
		return
	
	if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("openMenu"):
		visible = false
		emit_signal("goNext")

func setKillPercent(percent :float):
	percent = roundf(percent)
	$GridContainer/killsCount.text = str(percent) + "%"

func setItemPercent(percent : float):
	percent = roundf(percent)
	$GridContainer/itemsCount.text = str(percent) + "%"

func setTime(timeSec : float):
	#timeSec = roundf(timeSec)
	var hours = int(timeSec / 3600)
	var minutes = int((fmod(timeSec,3600)) / 60)
	var remainingSeconds = int(fmod(timeSec,60))
	
	if hours > 0:
		$GridContainer/timeCount.text ="%02d:%02d:%02d" % [hours, minutes, remainingSeconds]
	else:
		$GridContainer/timeCount.text ="%02d:%02d" % [minutes, remainingSeconds]
	
func setSecretPercent(percent : float):
	percent = roundf(percent)
	$GridContainer/secretCount.text = str(percent) + "%"


func setImageForMap(mapName : String):
	
	mapName = mapName.to_upper()
	if intermissionData.is_empty():
		return
		
	for i : String in intermissionData.keys():
		if mapName.match(i):
			$TextureRect.texture = intermissionData[i]
			return
		
		
	
