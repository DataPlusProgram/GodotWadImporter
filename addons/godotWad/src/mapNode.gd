extends Spatial

enum{
	PLAYER1,
	PLAYER2,
	PLAYER3,
	PLAYER4,
	DEATH_MATCH
}

export(String, FILE, "*.tscn,*.scn") var nextMapTscn = null

var spawns

func _ready():
	add_to_group("levels",true)
	clearFullscreenImage()


func get_spawn(teamIdx,spawnIdx):
	
	if spawns == null:
		spawns = get_node("Entities/Player Spawns")
	
	if spawns == null:
		return null
	if teamIdx == PLAYER1:
		var spawnNode : Position3D = spawns.get_node("Player 1 start").get_child(0)
		return {"pos":spawnNode.global_transform.origin,"rot":spawnNode.global_transform.basis.get_euler()}
		



func setFullscreenImage():
	var buff = get_tree().get_nodes_in_group("fullscreenTexture")
	if !buff.empty():
		var tex = ImageTexture.new()
		var data = get_viewport().get_texture().get_data()
		data.flip_y()
		tex.create_from_image(data)
		buff[0].texture=tex
		
func clearFullscreenImage():
	var buff = get_tree().get_nodes_in_group("fullscreenTexture")
	if !buff.empty():
		buff[0].texture = null

func _physics_process(delta):
	if name == "E2M8" and has_meta("Cyberdemon"):
		if get_meta("Cyberdemon") <= 0:
			nextMap()
			

func nextMap():
	var mapName = name

	if nextMapTscn != null:
		setFullscreenImage()
		var newMap = load(nextMapTscn).instance()
		get_parent().add_child(newMap)
		queue_free()


	var nextMap = WADG.incMap(mapName)
	var wadLoader = get_node("../WadLoader")
	
	setFullscreenImage()
	
	for i in get_children():
		i.queue_free()
	
	
	yield(get_tree(), "physics_frame")

	var t = wadLoader.textureEntries
	if wadLoader == null:
		return
	else:
		if wadLoader.textureEntries == null:
			wadLoader.createMap(nextMap,true)
		else:
			wadLoader.createMap(nextMap,false)
	
	queue_free()


func getAnimTextures(caller,animMeshPath):
	var animTextures = []
	
	for path in animMeshPath:
		if caller.get_node_or_null(path) == null:
			return
		var p2 = path.replace("../../../","")
		var node = get_node(p2)
		#var node = caller.get_node(path)
		var mesh : ArrayMesh = node.mesh 
		var mat = mesh.surface_get_material(0)
		
		var newMat = mat.duplicate(true)
		
		mesh.surface_set_material(0,newMat)
		
		if  newMat.get_shader_param("texture_albedo") != null:
			var texture = newMat.get_shader_param("texture_albedo")
			
			if "current_frame" in texture:
				animTextures.append(texture)
			
	return animTextures
