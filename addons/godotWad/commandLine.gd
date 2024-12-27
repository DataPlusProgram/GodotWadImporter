extends Node



	
func test():
	return "this is test"

#func spawn(entStr,gameStr = "Doom"):
	#entStr = entStr.to_lower()
	#var ent = ENTG.spawn(get_tree(),entStr,Vector3.ZERO,Vector3.ZERO,gameStr)
	#
	#if ent == null:
		#print('Failed to spawn ' + entStr)



func idfa():
	
	var allWeapons = ["shotgun","super shotgun","chaingun","plasma gun","rocket launcher","chainsaw","BFG"]
	
	for player in get_tree().get_nodes_in_group("player"):
		
		
		for weaponStr in allWeapons:
			var node = ENTG.fetchEntity(weaponStr,get_tree(),"Doom",false)
			
			if node == null:
				return null
			
			node.visible = true
			player.weaponManager.pickup(node,true,true)
			player.hp = 200
		

func iddqd():
	for player in get_tree().get_nodes_in_group("player"):
		player.hp = 99999

func idmus(index:int):
	var node : Node = get_tree().get_nodes_in_group("gameMode")[0]
	
	if !"loader" in node:
		return
	
	var loader = node.loader
	var mapToMusic = loader.mapToMusic
	
	
	var targetSong = null
	var curMapName = loader.mapName
	var count = 0
	for i in mapToMusic.keys():
		if i[0] == curMapName[0]:
			count+= 1
			
		if count == index:
			targetSong = mapToMusic[i]
	
	
	if targetSong == null:
		return "song not found"
		
	var data = loader.resourceManager.fetchMidiOrMus(targetSong)
	
	if data != null:
		var midiPlayer = ENTG.fetchMidiPlayer(get_tree())
		ENTG.setMidiPlayerData(midiPlayer,data)
		midiPlayer.play()
		#loader.mapNode.rawMidiData = data
	#breakpoint
	
