@tool
class_name WADG
extends Node

const destPath = "res://game_imports/"

enum SHADER_TYPE {
	GEOMETRY,
	SPRITE,
	SPRITE_FOV,
	SKY
}

enum TEXTUREDRAW{
	BOTTOMTOP,
	TOPBOTTOM,
	GRID,
}

enum DIR{
	UP,
	DOWN
}

enum KEY{
	RED,
	GREEN,
	BLUE,
	YELLOW,
}

enum LTYPE {
	DOOR,
	FLOOR,
	LIFT,
	CRUSHER,
	STAIR,
	EXIT,
	LIGHT,
	SCROLL,
	TELEPORT,
	CEILING,
	DUMMY,
	STOPPER,
	ALPHA,
	
}

enum TTYPE{
	DOOR,
	DOOR1,
	SWITCH1,
	SWITCHR,
	WALK1,
	WALKR,
	GUN1,
	GUNR,
	NONE,
}

enum DEST{
	LOWEST_ADJ_CEILING,
	LOWEST_ADJ_FLOOR,
	NEXT_HIGHEST_FLOOR,
	NEXT_LOWEST_FLOOR,
	up8,
	up24,
	up32,
	up512,
	NEXT_HIGHEST_FLOOR_up8,
	LOWEST_ADJ_CEILING_DOWN8,
	HIGHEST_ADJ_CEILING,
	FLOOR,
	FLOOR_up8,
	HIGHEST_ADJ_FLOOR,
	HIGHEST_NFLOOR_EXC,
	SHORTEST_LOWER_TEXTURE
}

enum LIGHT_TYPE{
	NONE,
	BLINK,
	GLOW,
	STROBE
}



static func getDest(dest,sector,scaleFactor):
	
	
	
	if dest == DEST.LOWEST_ADJ_CEILING: 
		return sector["lowestNeighCeilExc"]
	if dest == DEST.NEXT_HIGHEST_FLOOR: 
		return sector["nextHighestFloor"]
		
	if dest == DEST.NEXT_LOWEST_FLOOR: 
		return sector["nextLowestFloor"]
	if dest == DEST.LOWEST_ADJ_FLOOR: 
		return sector["lowestNeighFloorInc"]
	if dest == DEST.up24: 
		return min(sector["floorHeight"]+24.0*scaleFactor,sector["ceilingHeight"])
		#return sector["floorHeight"]+24.0*scaleFactor
	if dest == DEST.up32: 
		return min(sector["floorHeight"]+32.0*scaleFactor,sector["ceilingHeight"])
		#return sector["floorHeight"]+32.0*scaleFactor
	if dest == DEST.up512: 
		return min(sector["floorHeight"]+512.0*scaleFactor,sector["ceilingHeight"])
		#return sector["floorHeight"]+512.0*scaleFactor
	if dest == DEST.LOWEST_ADJ_CEILING_DOWN8: 
		return sector["lowestNeighCeilExc"]-8.0*scaleFactor
	if dest == DEST.up8:
		return sector["floorHeight"]+8.0*scaleFactor
	if dest == DEST.LOWEST_ADJ_CEILING_DOWN8:
		return sector["lowestNeighCeilExc"]-8.0*scaleFactor
	if dest == DEST.NEXT_HIGHEST_FLOOR_up8:
		return sector["nextLowestFloor"]+8.0*scaleFactor
	if dest == DEST.HIGHEST_ADJ_CEILING:
		return sector["highestNeighCeilInc"]
	if dest == DEST.FLOOR:
		return sector["floorHeight"]
	if dest == DEST.HIGHEST_ADJ_FLOOR:
		return sector["highestNeighFloorInc"]
	if dest == DEST.HIGHEST_NFLOOR_EXC:
		return sector["highestNeighFloorExc"]
	if dest == DEST.FLOOR_up8:
		return sector["floorHeight"]+8.0*scaleFactor
	if dest == DEST.SHORTEST_LOWER_TEXTURE:
		return sector["floorHeight"] + sector["lowestTextureHeight"]*scaleFactor
	return null
	




static func getDestStages(dest,startFloor,sectorTuples : Array[Array],scaleFactor,stage):
	
	
	
	var tuples = sectorTuples.duplicate()
	
	for i in tuples:
		if i[0] < startFloor:
			tuples.erase(i)
	
	tuples.sort_custom(func (a, b):return a[0] < b[0])
	
	
	if dest == DEST.NEXT_HIGHEST_FLOOR:
		return tuples[stage%tuples.size()][0]
	else:
		breakpoint
	
	
	

static func getLightLevel(light) -> float:
	#var lightLevel = max(light-65,0)
	#lightLevel = remap(lightLevel,0,255-62,0,15)
	#lightLevel = remap(lightLevel,0,16,0.0,1.0)
	
	var lightLevel : float = max(light-62,0)
	lightLevel = remap(lightLevel,0,255-62,0,15)
	lightLevel = remap(lightLevel,0,16,0.0,1.0)
	return lightLevel


static func incMap(mapName :  String,secret = false):
	
	mapName = mapName.to_upper()
	
	if secret:
		var secrets = load("res://addons/godotWad/resources/secretRoutes.tres") 
		var mapsWithSecrets = secrets.getRowKeys()
	
		if mapsWithSecrets.has(mapName):
			return secrets.getRow(mapName)["dest"]
		else:
			return ""
	
	
	if mapName[0] == 'E' and mapName[2] == 'M':
		return incrementDoom1Map(mapName)
	
	if mapName.substr(0,3) == "MAP":
		return incrementDoom2Map(mapName)
	
	return ""

static func incrementDoom1Map(nameStr : String,isSecret : bool = false):
	var ret = nameStr
	

		
	var lastDigit = int(nameStr[3])
	


	if lastDigit >= 8:
		var firstDigit = int(nameStr[1])
		
		if firstDigit == 1 and lastDigit == 9:
			return "E1M4"
		
		if firstDigit < 4:
			firstDigit += 1
			ret = "E" + str(firstDigit) + "M1"
		return ret
	
	if lastDigit < 9:
		lastDigit+= 1
		nameStr[3] = str(lastDigit)
		return(nameStr)
		
	
		
		
static func incrementDoom2Map(nameStr,isSecret = false):
	var digitsStr = nameStr[3] + nameStr[4]
	var digits = int(digitsStr)
	
	
	
	digits += 1
	
	if digits < 10:
		digitsStr = "0" + str(digits)
	else:
		digitsStr = str(digits)
	
	return "MAP" + digitsStr
	


static func getAreaFromExtrudedMesh(mesh,h):
	var area = Area3D.new()
	var collisionShape = CollisionShape3D.new()
	
	var shape = extrudeMeshIntoTrimeshShape(mesh,h)
	collisionShape.shape = shape
	area.add_child(collisionShape)
	return area

static func extrudeMeshIntoTrimeshShape(mesh,h):
	var meshInstance = MeshInstance3D.new()
	var eMesh = getExtrudedMesh(mesh,h)
	
	#return eMesh.create_convex_shape()
	return eMesh.create_trimesh_shape()
	#return meshInstance

static func getExtrudedMeshInstance(mesh,h):
	var meshInstance = MeshInstance3D.new()
	var eMesh = getExtrudedMesh(mesh,h)
	
	meshInstance.mesh = eMesh
	return meshInstance

static func getExtrudedMesh(mesh,h):
	var faces = getExtrudedFaces(mesh,h)
	mesh = createMesh(faces)
	return mesh

static func getExtrudedFaces(mesh,h):
	
	var meshData = MeshDataTool.new()
	meshData.create_from_surface(mesh,0)
	
	var vcount = meshData.get_vertex_count()
	var ecount = meshData.get_vertex_count()
	var fcount = meshData.get_face_count()
	var tcount = meshData.get_face_count()
	var verts = []
	var edges = []
	var faces =  []
	var outerEdges = []
	var sides = []
	var bottom = []
	
	for i in vcount:
		verts.append(meshData.get_vertex(i))
	
	
	for i in ecount:
		var v1 = meshData.get_edge_vertex(i,0)
		var v2 = meshData.get_edge_vertex(i,1)
		
		edges.append([verts[v1],verts[v2]])
	for i in fcount:
		var x = meshData.get_face_vertex(i,0)
		var y = meshData.get_face_vertex(i,1)
		var z = meshData.get_face_vertex(i,2)
		
		var v1 = meshData.get_vertex(x)
		var v2 = meshData.get_vertex(y)
		var v3 = meshData.get_vertex(z)
		
		faces.append([v1,v2,v3])
	
	
	for i in edges:
		var opp = [i[1],i[0]]
		
		if !edges.has(opp):
			outerEdges.append(i)
		
	var top = faces.duplicate(true)
	for triIdx in top.size():
		top[triIdx][0].y += h
		top[triIdx][1].y += h
		top[triIdx][2].y += h
		
	
	
	
	for i in outerEdges:
		var v1 = i[0]
		var v2 = i[1]
		
		var hVector = Vector3(0,h,0)
		
		sides.append([v1,v2,v2+hVector])
		sides.append([v2+hVector,v1+hVector,v1])
	
	
	for i in faces.size():
		var v1 = faces[i][0]
		var v2 = faces[i][1]
		var v3 = faces[i][2]
		
		bottom.append([v3,v2,v1])
		#bottom.append([flipFace(f1),flipFace(2),flipF])
		
	
	var concat = bottom+top + sides
	return concat


static func createMesh(faces):
	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#for i in faces:
	#	surf.add_vertex(i[0])
	#	surf.add_vertex(i[1])
	#	surf.add_vertex(i[2])
		
	for i in faces:
		surf.add_vertex(i[2])
		surf.add_vertex(i[1])
		surf.add_vertex(i[0])

	var mesh = surf.commit()
	return mesh
	

func flipFace(face):
	var temp = face.x
	face.x = face.z
	face.z = face.z
	

static func getVertsFromMeshArrayMesh(mesh : ArrayMesh,position :Vector3) -> Dictionary:
	var mdt : MeshDataTool = MeshDataTool.new()
	mdt.create_from_surface(mesh,0)
	var vertArr : Array= []
	var normArr : Array= []
	var uvArr : Array= []
	
	
	for idx in mdt.get_face_count():
		for i in range(0,3):
			var v : = mdt.get_face_vertex(idx,i)
			vertArr.append(mdt.get_vertex(v)+position)
			normArr.append(mdt.get_vertex_normal(v))
			uvArr.append(mdt.get_vertex_uv(v))
	
	
	return {"verts":vertArr,"normals":normArr,"uv":uvArr,"material":mdt.get_material()}




static func keyNameToNumber(keyName):
	if keyName == "Red keycard": return KEY.RED
	if keyName == "Red skull key": return KEY.RED
	
	if keyName == "Blue keycard": return KEY.BLUE
	if keyName == "Blue skull key": return KEY.BLUE
	
	if keyName == "Yellow keycard": return KEY.BLUE
	if keyName == "Yellow skull key": return KEY.BLUE
		

static func keyNumberToColorStr(keyNumber):
	if keyNumber == KEY.RED: return "red"
	if keyNumber == KEY.BLUE: return "blue"
	if keyNumber == KEY.YELLOW: return "yellow"

static func keyNunmberToNameArr(keyNumber):
	
	if keyNumber == KEY.RED: return ["Red keycard","Red skull key"]
	if keyNumber == KEY.BLUE: return ["Blue keycard","Blue skull key"]
	if keyNumber == KEY.YELLOW: return ["Yellow keycard","Yellow skull key"]
	
	
static func drawLine(node : Node,start : Vector3 ,end : Vector3,color = Color.RED):
	var ig : ImmediateMesh = ImmediateMesh.new()
	var meshInstance = MeshInstance3D.new()
	
	for i in node.get_children():
		if i.get_class() == "ImmediateMesh":
			i.queue_free()

	ig.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	ig.surface_add_vertex(start)
	ig.surface_add_vertex(end)
	#var random_color = Color(randf(), randf(), randf())
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	
	meshInstance.material_override = mat
	ig.surface_end()
	meshInstance.mesh = ig
	node.call_deferred("add_child",meshInstance)
	return meshInstance

#static func drawLineRelative(node : Node,end : Vector3,color = Color.RED):
	#drawLine(node,node.global_position,end,color)

static func drawVector(node,vector,length = 1):
	var ig = ImmediateMesh.new()
	
	for i in node.get_children():
		if i.get_class() == "ImmediateMesh":
			i.queue_free()
			
		if i.get_class() == "CSGCylinder3D":
			i.queue_free()


	var x = node.global_transform.basis * (vector.normalized()*length)
	ig.begin(Mesh.PRIMITIVE_LINE_STRIP)
	ig.add_vertex(Vector3.ZERO)
	ig.add_vertex(x)
	
	
	
	#var cone : CSGCylinder  =  CSGCylinder.new()
	#cone.cone = true
	#cone.radius = 0.1
	#cone.height = 0.5
	#cone.sides = 16
	
	#cone.transform = cone.transform.looking_at(node.global_transform.origin+vector.normalized()*length,Vector3.UP)
	#cone.translation = vector.normalized()*length
	
	
	
	ig.end()
	node.call_deferred("add_child",ig)
#	node.add_child(cone)
	


static func drawSphere(node : Node,pos : Vector3,color = Color.WHITE,radius = 0.1):
	
	
	
	var shape : SphereMesh = SphereMesh.new()
	shape.radius = radius/2
	shape.height = radius
	
	var meshInstance = MeshInstance3D.new()
	meshInstance.mesh = shape
	if color != Color.WHITE:
		meshInstance.mesh.material = StandardMaterial3D.new()
		meshInstance.mesh.material.albedo_color = color
		meshInstance.mesh.material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	meshInstance.position = pos
	meshInstance.name = "deubgSphere"
	node.call_deferred("add_child",meshInstance)
	return meshInstance
	#node.add_child(meshInstance)
	

static func isASwitchTexture(texName,switchTextureDict):
	if texName == "-":
		return false
		
	if texName == "":
		return false
	
	for img in switchTextureDict.values():
		for i in img:
			if i == texName:
				return true
			
	return false

static func drawPath(node,arr):
	
	var pathPar =  node.get_node_or_null("path")
	
	if pathPar == null:
		pathPar = Node3D.new()
		pathPar.name = "path"
		node.add_child(pathPar)
		
	
	for i in pathPar.get_children():
		i.queue_free()
	
	var running = Vector3.ZERO
	var prev =  null

	for i in arr:
		if prev == null:
			prev = i
		drawSphere(pathPar,i)
		drawLine(pathPar,prev,i)
		prev = i
	

static func drawForward(node):
	var pathPar =  node.get_node_or_null("path")
	 
	if pathPar == null:
		pathPar = Node3D.new()
		pathPar.name = "path"
		node.add_child(pathPar)
		
	var forward =  -node.transform.basis.z
	var nodePos = Vector3.ZERO
	

	
	var dest = forward
	if "height" in node:
		nodePos.y = node.height/2.0
		dest.y = node.height/2.0
	
	
	drawLine(pathPar,nodePos,dest)
	
static func saveNodeAsScene(node,path = "res://dbg/"):
	
	recursiveOwn(node,node)
	var packedScene = PackedScene.new()
	packedScene.pack(node)
	
	if path.find(".tscn") != -1:
	#	print("saving as:",path)
		ResourceSaver.save(packedScene,path)
	else:
	#	print("saving as:",path+node.name+".tscn")
		ResourceSaver.save(packedScene,path+node.name+".tscn")

static func recursiveOwn(node,newOwner):
	
	for i in node.get_children():
		recursiveOwn(i,newOwner)
	
	
	
	if node != newOwner:#you get error if you set something as owning itself
		node.owner = newOwner


static func recursiveSetInput(node,value):
	
	node.set_physics_process(value) 
	node.set_process_input(value)
	node.set_process_unhandled_input(value)
	node.set_process_unhandled_key_input(value) 
	
	for i in node.get_children():
		recursiveSetInput(i,value)



static func recursiveDestroyFilename(node):

	node.filename = ""

	for i in node.get_children():
		recursiveDestroyFilename(i)
	
	


static func recurisveRemoveNotOfOwner(node,targetOwner):
	
	var nom = node.name
	var nowner = node.owner
	
	var x = nowner
	if x != null:
		x = nowner.name
	
	
	if node.owner != targetOwner and node != targetOwner and node.owner != null:
		node.get_parent().remove_child(node)
		node.queue_free()
	
	for i in node.get_children():
		recurisveRemoveNotOfOwner(i,targetOwner)



static func removeAllChildren(node):
	for i in node.get_children():
		node.remove_child(i)
		i.queue_free()
	

static func setCollisionShapeHeight(node,height):
	
	var shape = node.shape
	
	if shape == null:
		return
		
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape3D":
		
		if shape.extents.y !=  height/2.0:
			shape.extents.y = height/2.0
		return
	
	
	elif shapeClass == "CylinderShape3D" or shapeClass == "CapsuleShape3D":
		shape.height = height
		return
	

static func getShapeHeight(node):
	
	var shape = node.shape
	
	if shape == null:
		return
		
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape3D":
		return shape.extents.y * 2.0

	
	
	if  shapeClass == "CylinderShape3D" or shapeClass == "CapsuleShape3D":
		return shape.height

static func getCollisionShape(node : Node) -> CollisionShape3D:
	for i : Node in node .get_children():
		if i is CollisionShape3D:
			return i
	
	return null
	
static func setShapeThickness(node : Node,radius : float) -> void:
	
	if node == null:
		return
	
	if node.shape == null:
		return 
		
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape3D":
		shape.extents.z = radius
		shape.extents.x = radius
		
	if shapeClass == "CylinderShape3D":
		shape.radius = radius

static func getShapeThickness(node: Node) -> float:
	
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape3D":
		return shape.extents.z
		
		
	if shapeClass == "CylinderShape3D":
		return shape.radius
	
	return 0

static func getCollisionShapeFootprint(node : Shape3D):
	if node is BoxShape3D:
		var hW = node.size.x / 2.0
		var hH = node.size.z / 2.0
		return [Vector2(-hW, -hH), Vector2(hW, -hH), Vector2(hW, hH), Vector2(-hW, hH)]
		#return [Vector2(0, 0), Vector2(node.size.x, 0), Vector2(node.size.x, node.size.z), Vector2(0, node.size.z)]
	else:
		return []

static func getCollisionShapeHeight(node : Node) -> float:
	
	if node == null:
		return 0 
	
	var shape = node.shape
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape3D":
		return shape.extents.y * 2.0
	
	
	elif shapeClass == "CylinderShape3D" or shapeClass == "CapsuleShape3D":
		return shape.height
		
	return 0.0

static func scaleCollisionShape(node,scale):
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape3D":
		shape.extents*= scale
	
	

static func yieldWait(tree,delay):
	await tree.create_timer(delay).timeout



static func indexCircular(arr,index):
	if arr.size() == 0:
		return 0
	return (index + arr.size() + arr.size()) % arr.size()


static func getChildOfClass(node,type):
	for c in node.get_children():
		if c.get_class() == type:
			return c
			
	return null

static func createInheritedScene(inherits, nameOfRootNode := "Scene") -> PackedScene:
	inherits = load(inherits)
	var scene := PackedScene.new()
	scene._bundled = {"base_scene": 0, "conn_count": 0, "conns": [], "editable_instances": [], "names": [nameOfRootNode], "node_count": 1, "node_paths": [], "nodes": [-1, -1, 2147483647, 0, -1, 0, 0], "variants": [inherits], "version": 2}
	
	return scene






static func getDirFromDic(input,target : String):
	if typeof(input) == TYPE_DICTIONARY:
		
		for i in input.keys():
			var f = i.get_file()
			if f == target:
				return i

		for i in input.values():
			var got = getDirFromDic(i,target)
			if got !=null:
				return got
			
			
	
	if typeof(input) == TYPE_ARRAY:
		for i in input:
			var got = getDirFromDic(i,target)
			if got != null:
				return got
			
	return null

static func allInDirectory(path,filter=null):
	var files = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		return []
		
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			
			if file.find(".") == -1:
				files.append(file)
			else:
				if filter != null:
					var ext = file.split(".")
					if ext[ext.size()-1].find(filter)!= -1:
						files.append(file)
				else:
					files.append(file)

	dir.list_dir_end()

	return files

static func getAllInDirRecursive(path,filter=null):
	var all = allInDirectory(path,filter)
	var ret = {}
	ret[path] = []
	
	for i in all:
		if i.find(".") != -1:
			ret[path].append(path+"/"+i)
		else:
			ret[path].append(getAllInDirRecursive(path+"/"+i,filter))
	
	
	return ret

static func getAllFlat(path):
	var ret = []
	var all = allInDirectory(path)
	
	for i in all:
		if i.find(".") == -1:
			ret += getAllFlat(path + "/" + i)
		
		else:
			ret.append(path + "/" + i)
			
	return ret

static func getImportPath() -> String:
	return "res://wadFiles"

static func normalToDegree(normal : Vector3):
	return rad_to_deg(normal.angle_to(Vector3.UP))

static func createCastShapeForBody(node,target = Vector3.ZERO):

	if node == null:
		return
	var cast = ShapeCast3D.new()
	var collisionShape = null
	
	
	cast.max_results =7
	for i in node.get_children():
		if i.get_class() == "CollisionShape3D":
			collisionShape = i
			break
			
	if collisionShape == null:
		return
	
	
	cast.shape = node.get_parent().mesh.create_convex_shape()
	
#	cast.scale *= Vector3(0.8,1,0.8) why did i scale it down?
	
	cast.target_position = target
	cast.enabled = false
	node.add_child(cast)
	cast.collision_mask = 3
	return cast



static func getBoundingBox(vertices: PackedVector2Array) -> Rect2:
	var minPoint = Vector2(INF, INF)
	var maxPoint = Vector2(-INF, -INF)
	
	for vertex : Vector2 in vertices:
		minPoint.x = min(minPoint.x, vertex.x)
		minPoint.y = min(minPoint.y, vertex.y)
		maxPoint.x = max(maxPoint.x, vertex.x)
		maxPoint.y = max(maxPoint.y, vertex.y)
	
	return Rect2(minPoint, maxPoint - minPoint)

static func findOverlappingCells(boundingBox: Rect2,bbIndex,gridSize : float = 20) -> PackedVector2Array:
	var overlappingCells : PackedVector2Array= []

	var minCellX : int= int(floor(boundingBox.position.x / gridSize))
	var minCellY : int= int(floor(boundingBox.position.y / gridSize))
	var maxCellX : int= int(floor(boundingBox.end.x / gridSize))
	var maxCellY : int= int(floor(boundingBox.end.y / gridSize))

	for x : float in range(minCellX, maxCellX + 1):
		for y : float in range(minCellY, maxCellY + 1):
			overlappingCells.append(Vector2(x, y))

	return overlappingCells
	
static func getBBsForCell(grid : Dictionary, position: Vector2, gridSize : float = 20) -> Array:
	var cellPos = Vector2(int(floor(position.x / gridSize)),int(floor(position.y / gridSize)))
	
	var relevantPolygons = []
	
	if grid.has(cellPos):
		relevantPolygons = grid[cellPos]
		
	return relevantPolygons

static func getSectorInfo(curMap : Node,sectorIndex : int):
	var polyIdxToInfo = curMap.get_meta("polyIdxToInfo")
		
	return polyIdxToInfo[sectorIndex]

static func getSectorInfoForPoint(curMap : Node,posXZ : Vector2):
	
	
	if !curMap.has_meta("polyGrid"):
		return
	
	var polyGrid = curMap.get_meta("polyGrid")
	var sectorPolyArr : Array = curMap.get_meta("sectorPolyArr")
	var polyIdxToInfo = curMap.get_meta("polyIdxToInfo")
	var bbArray = curMap.get_meta("polyBB")

	
	if polyGrid == null:
		return
	
	var cellBBS = getBBsForCell(polyGrid,posXZ)
			
	for bbIdx in cellBBS:
		if bbArray[bbIdx].has_point(posXZ):

			if Geometry2D.is_point_in_polygon(posXZ,sectorPolyArr[bbIdx]):
				return  polyIdxToInfo[bbIdx]
				
	return null



	
static func transformToRotDegrees(t : Transform3D):
	return t.basis.get_euler() * (180.0 / PI)


static func getDamageInfoFromSectorType2(dict : Dictionary) -> Dictionary:
	
	var amt : float = 0
	var tickRateMS : = 0
	var secret : bool = false
	var elemental : Array[String] = []
	
	if !dict.has("dmg amt"):
		if !dict.has("secret"):
			return {}
		else:
			secret = dict["secret"]
	else:
		amt = dict["dmg amt"]
		tickRateMS = dict["dmg tick"]*Engine.physics_ticks_per_second

	var retDict : Dictionary = {"amt":amt,"everyNframe":tickRateMS}
	if secret: elemental.append("secret")
	if dict.has("elemental"): elemental.append(dict["elemental"])
	
	if !elemental.is_empty():
		retDict["specific"] = elemental
	
	if dict.has("levelChangeHp"):
		retDict["atHp"] = "nextLevel"
		retDict["atHpAmt"] = dict["levelChangeHp"]
		
	 
	return retDict


static func printOwner(node,prefix=""):
	var nodeOwner = "null"
	if node.owner != null:
		nodeOwner = node.owner.name
		
	print(prefix+node.name+" ("+nodeOwner+","+node.filename+")")
	
	for i in node.get_children():
		printOwner(i,prefix+" ")

static func doesFileExist(path : String) -> bool:
	#var f : File = File.new()
	#var ret = f.file_exists(path)
	#f.close()
	return FileAccess.file_exists(path)


static func test():
	print("test")

static func funcGetMergedSectorMeshInstance(geomNode : Node,sectorIdx : int) -> Array[MeshInstance3D]:
	
	var ret : Array[MeshInstance3D] = []
	
	for i in geomNode.get_children():
		if i.has_meta("sectorIdx"):
			if i.get_meta("sectorIdx") == sectorIdx:
				if i.get_class() == "MeshInstance3D":
					ret.append(i)

					
	return ret

static func getSpritesAndFrames(stateData,textureList : Dictionary):
	
	var allLetters = getSpritesFromStates(stateData)
	return findWhatSpritesExist(allLetters,textureList)

static func getFlashSpritesAndFrames(stateData,textureList : Dictionary):
	
	var allLetters = getFlashSpritesFromStates(stateData)
	return findWhatSpritesExist(allLetters,textureList)

static func getSpritesFromStates(stateData):
	var ret : Array[String] = []
	
	
	
	for i : Dictionary in stateData:
		var spriteName : String = i["Sprite"]
		if !spriteName.is_empty():
			
			var sprName = spriteName.substr(0,5)
			if !ret.has(sprName):
				ret.append(sprName)
			
	
	return ret
	
static func getFlashSpritesFromStates(stateData):
	var ret : Array[String] = []
	
	for i : Dictionary in stateData:
		if !i.has("flashSprite"):
			continue
		var spriteName : String = i["flashSprite"]
		

		
		if !spriteName.is_empty():
			
			var sprName = spriteName.substr(0,5)
			if !ret.has(sprName):
				ret.append(sprName)
			
	
	return ret

static func findWhatSpritesExist(spriteNames : Array[String],textureList : Dictionary):
	var frames = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[','\\',']']
	var allFrames : Dictionary = {}
	var potentials = [] 
	var uniqueSprites = []
	
	var numToDir = {
	"0": "All",
	"1": "S",
	"2": "SW",
	"3": "W",
	"4": "NW",
	"5": "N",
	"6": "NE",
	"7": "East",
	"8": "SE"
	}

	
	for i in textureList:
		for j in spriteNames:
			if i.find(j) != -1:
				potentials.append(i)
	
	for i : String in potentials:
		if i.length()<6 or i.length() > 8:
			continue 
		
		#if i.length()>?
			#continue
		
		var sprName : String = i.substr(0,4)
		var frame : String = i[4]
		var angle : String = i[5]
		
		
		if !numToDir.has(angle):
			continue
		
		#if frame.has(frame):
			#continue
		if !allFrames.has(frame):
			allFrames[frame] = {}
		var hack = false
		
		if i.length() < 8:
			uniqueSprites.append(sprName + frame + angle)
			
			if !allFrames[frame].is_empty():#hack for cases such as plasma gun which has 2 A frames but with different sprites
				if allFrames[frame].has(numToDir[angle]):
					allFrames[frame + "2"] = {}
					allFrames[frame + "2"]["All"] = sprName + frame + "0"
					continue
				
			
			allFrames[frame][numToDir[angle]] = sprName + frame + angle
			continue
			
		var frame2 : String = i[6]
		var angle2 : String = i[7]
		
		
		if !numToDir.has(angle2):
			continue
		
		uniqueSprites.append(sprName + frame + angle + frame2 +angle2)
		uniqueSprites.append(sprName + frame + angle + frame2 +angle2 + "_flipped")

		
		
		if !allFrames.has(frame2):
			allFrames[frame2] = {}
		

		allFrames[frame][numToDir[angle]] = sprName + frame + angle + frame2 +angle2
		allFrames[frame2][numToDir[angle2]] = sprName + frame + angle + frame2 +angle2 + "_flipped"

		
	
	
	for frame in allFrames:
		var unordered = allFrames[frame]
		var ordered = {}
		
		for i in numToDir.values():
			if unordered.has(i):
				ordered[i] = unordered[i]
			else:
				ordered[i] = null
			
		allFrames[frame] = ordered
		

	
 
		
	return {"sprites":uniqueSprites,"frames":allFrames}
