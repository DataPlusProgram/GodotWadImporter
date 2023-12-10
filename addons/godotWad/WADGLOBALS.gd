tool
class_name WADG
extends Node

const destPath = "res://game_imports/"



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
		return sector["floorHeight"]+24.0*scaleFactor
	if dest == DEST.up32: 
		return sector["floorHeight"]+32.0*scaleFactor
	if dest == DEST.up512: 
		return sector["floorHeight"]+512.0*scaleFactor
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
	
		
	

static func getLightLevel(light):
	var lightLevel = max(light-62,0)
	lightLevel = range_lerp(lightLevel,0,255-62,0,15)
	return lightLevel


static func incMap(mapName,secret = false):
	
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

static func incrementDoom1Map(nameStr,isSecret = false):
	var ret = nameStr
	

		
	var lastDigit = int(nameStr[3])
	

	if lastDigit >= 8:
		var firstDigit = int(nameStr[1])
		if firstDigit < 4:
			firstDigit += 1
			ret = "E" + String(firstDigit) + "M1"
		return ret
	
	if lastDigit < 9:
		lastDigit+= 1
		nameStr[3] = String(lastDigit)
		return(nameStr)
		
	
		
		
static func incrementDoom2Map(nameStr,isSecret = false):
	var digitsStr = nameStr[3] + nameStr[4]
	var digits = int(digitsStr)
	
	
	
	digits += 1
	
	if digits < 10:
		digitsStr = "0" + String(digits)
	else:
		digitsStr = String(digits)
	
	return "MAP" + digitsStr
	


static func getAreaFromExtrudedMesh(mesh,h):
	var area = Area.new()
	var collisionShape = CollisionShape.new()
	
	var shape = extrudeMeshIntoTrimeshShape(mesh,h)
	collisionShape.shape = shape
	area.add_child(collisionShape)
	return area

static func extrudeMeshIntoTrimeshShape(mesh,h):
	var meshInstance = MeshInstance.new()
	var eMesh = getExtrudedMesh(mesh,h)
	
	#return eMesh.create_convex_shape()
	return eMesh.create_trimesh_shape()
	#return meshInstance

static func getExtrudedMeshInstance(mesh,h):
	var meshInstance = MeshInstance.new()
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
	

static func getVertsFromMeshArrayMesh(mesh,translation):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh,0)
	var vertArr = []
	var normArr = []
	var uvArr = []
	
	
	for idx in mdt.get_face_count():
		for i in range(0,3):
			var v = mdt.get_face_vertex(idx,i)
			vertArr.append(mdt.get_vertex(v)+translation)
			normArr.append(mdt.get_vertex_normal(v))
			uvArr.append(mdt.get_vertex_uv(v))
	
	var dict = {"verts":vertArr,"normals":normArr,"uv":uvArr,"material":mdt.get_material()}
	return dict



static func keyNameToNumber(keyName):
	if keyName == "Red keycard": return KEY.RED
	if keyName == "Red skull key": return KEY.RED
	
	if keyName == "Blue keycard": return KEY.BLUE
	if keyName == "Blue skull key": return KEY.BLUE
	
	if keyName == "Yellow keycard": return KEY.BLUE
	if keyName == "Yellow skull key": return KEY.BLUE
		

static func keyNunmberToNameArr(keyNumber):
	
	if keyNumber == KEY.RED: return ["Red keycard","Red skull key"]
	if keyNumber == KEY.BLUE: return ["Blue keycard","Blue skull key"]
	if keyNumber == KEY.YELLOW: return ["Yellow keycard","Yellow skull key"]
	
	
static func drawLine(node,start,end):
	var ig = ImmediateGeometry.new()
	
	for i in node.get_children():
		if i.get_class() == "ImmediateGeometry":
			i.queue_free()

	ig.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	ig.add_vertex(start)
	ig.add_vertex(end)
	#var random_color = Color(randf(), randf(), randf())
	
	#var mat = SpatialMaterial.new()
	#mat.albedo_color = random_color
	#mat = load("res://new_spatialmaterial.tres")
	#ig.material_override = mat
	ig.end()
	node.call_deferred("add_child",ig)
	

static func drawVector(node,vector,length = 1):
	var ig = ImmediateGeometry.new()
	
	for i in node.get_children():
		if i.get_class() == "ImmediateGeometry":
			i.queue_free()
			
		if i.get_class() == "CSGCylinder":
			i.queue_free()


	var x = node.global_transform.basis.xform(vector.normalized()*length)
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
	
static func drawSphere(node : Node,pos : Vector3,color = Color.white,radius = 0.1):
	
	var shape : SphereMesh = SphereMesh.new()
	shape.radius = radius/2
	shape.height = radius
	
	var meshInstance = MeshInstance.new()
	meshInstance.mesh = shape
	if color != Color.white:
		meshInstance.material_override = SpatialMaterial.new()
		meshInstance.material_override.albedo_color = color
	meshInstance.translation = pos
	meshInstance.name = "deubgSphere"
	node.call_deferred("add_child",meshInstance)
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
		pathPar = Spatial.new()
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
		pathPar = Spatial.new()
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
		ResourceSaver.save(path,packedScene)
	else:
	#	print("saving as:",path+node.name+".tscn")
		ResourceSaver.save(path+node.name+".tscn",packedScene)

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
	
	print(nom,",",x)
	
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

	
	if shapeClass == "BoxShape":
		
		if shape.extents.y !=  height/2.0:
			shape.extents.y = height/2.0
		return
	
	
	elif shapeClass == "CylinderShape" or shapeClass == "CapsuleShape":
		shape.height = height
		return
	

static func getShapeHeight(node):
	
	var shape = node.shape
	
	if shape == null:
		return
		
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape":
		return shape.extents.y * 2.0

	
	
	if  shapeClass == "CylinderShape" or shapeClass == "CapsuleShape":
		return shape.height

static func setShapeThickness(node : Node,radius : float) -> void:
	
	if node == null:
		return
	
	if node.shape == null:
		return 
		
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape":
		shape.extents.z = radius
		shape.extents.x = radius
		
	if shapeClass == "CylinderShape":
		shape.radius = radius
		
static func getCollisionShapeHeight(node : Node) -> float:
	
	var shape = node.shape
	var shapeClass =  node.shape.get_class()

	
	if shapeClass == "BoxShape":
		return shape.extents.y * 2.0
	
	
	elif shapeClass == "CylinderShape" or shapeClass == "CapsuleShape":
		return shape.height
		
	return 0.0

static func scaleCollisionShape(node,scale):
	var shape = node.shape
	var shapeClass =  node.shape.get_class()
	
	if shapeClass == "BoxShape":
		shape.extents*= scale
	
	

static func yieldWait(tree,delay):
	yield(tree.create_timer(delay),"timeout")



static func indexCircular(arr,index):
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
	var dir = Directory.new()
	var res = dir.open(path)
	
	if res != 0:
		return []
		
	dir.list_dir_begin()

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
	return rad2deg(normal.angle_to(Vector3.UP))

static func createCastShapeForBody(node,target = Vector3.ZERO):


	var cast = ShapeCast.new()
	var collisionShape = null
	
	
	cast.max_results = 10
	for i in node.get_children():
		if i.get_class() == "CollisionShape":
			collisionShape = i
			break
			
	if collisionShape == null:
		return
	
	
	cast.shape = node.get_parent().mesh.create_convex_shape()
	#cast.visible = true
	#cast.debug_shape_custom_color = Color.palevioletred
	cast.scale *= Vector3(0.8,1,0.8) 
	cast.target_position = target
	cast.enabled = false
	node.add_child(cast)
	cast.collision_mask = 3
	return cast



static func getBoundingBox(vertices: PoolVector2Array) -> Rect2:
	var minPoint = Vector2(INF, INF)
	var maxPoint = Vector2(-INF, -INF)
	
	for vertex in vertices:
		minPoint.x = min(minPoint.x, vertex.x)
		minPoint.y = min(minPoint.y, vertex.y)
		maxPoint.x = max(maxPoint.x, vertex.x)
		maxPoint.y = max(maxPoint.y, vertex.y)
	
	return Rect2(minPoint, maxPoint - minPoint)

static func findOverlappingCells(boundingBox: Rect2,bbIndex,gridSize : float = 20) -> Array:
	var overlappingCells = []

	var minCellX = int(floor(boundingBox.position.x / gridSize))
	var minCellY = int(floor(boundingBox.position.y / gridSize))
	var maxCellX = int(floor(boundingBox.end.x / gridSize))
	var maxCellY = int(floor(boundingBox.end.y / gridSize))

	for x in range(minCellX, maxCellX + 1):
		for y in range(minCellY, maxCellY + 1):
			overlappingCells.append(Vector2(x, y))

	return overlappingCells
	
static func getBBsForCell(var grid : Dictionary,var position: Vector2,gridSize : float = 20) -> Array:
	var cellPos = Vector2(int(floor(position.x / gridSize)),int(floor(position.y / gridSize)))
	
	var relevantPolygons = []
	
	if grid.has(cellPos):
		relevantPolygons = grid[cellPos]
		
	return relevantPolygons


static func getSectorInfoForPoint(curMap : Node,posXZ : Vector2):
	
	var polyGrid = curMap.get_meta("polyGrid")
	var sectorPolyArr = curMap.get_meta("sectorPolyArr")
	var polyIdxToInfo = curMap.get_meta("polyIdxToInfo")
	var bbArray = curMap.get_meta("polyBB")

	
	if polyGrid == null:
		return
	
	var cellBBS = getBBsForCell(polyGrid,posXZ)
			
	for bbIdx in cellBBS:
		if bbArray[bbIdx].has_point(posXZ):
			if Geometry.is_point_in_polygon(posXZ,sectorPolyArr[bbIdx]):
				return  polyIdxToInfo[bbIdx]
				
	return null


static func setTimeLog(var tree,var valName,var startTime):
	if !tree.has_meta("timings"):
		tree.set_meta("timings",{})
	
	
	var dict = tree.get_meta("timings")
	dict[valName] = OS.get_system_time_msecs() - startTime
	tree.set_meta("timings",dict)
	


static func incTimeLog(tree,valName,startTime):
	if !tree.has_meta("timings"):
		tree.set_meta("timings",{})
	
	
	
	var dict = tree.get_meta("timings")
	
	if !dict.has(valName):
		dict[valName] = 0
		
	
	var curValue = dict[valName] + OS.get_system_time_msecs() - startTime
	dict[valName] = curValue
	
	
	tree.set_meta("timings",dict)

	
	#tree.get_root().set_meta(valName,value)
static func getTimeData(tree):
	if !tree.has_meta("timings"):
		return {}
		
	return tree.get_meta("timings")
	
static func transformToRotDegrees(t : Transform):
	return t.basis.get_euler() * (180.0 / PI)


static func getDamageInfoFromSectorType(var type : int):
	if type == 4:  return {"amt":10,"tickRateMS":500,"graceMS":100,"everyNframe":55,"specific":"nukage"}
	if type == 5:  return {"amt":10,"tickRateMS":500,"graceMS":100,"everyNframe":55,"specific":"nukage"}
	if type == 7:  return {"amt":2,"tickRateMS":500,"graceMS":100,"everyNframe":55,"specific":"nukage"}
	if type == 11: return {"amt":10,"tickRateMS":500,"atHp":"nextLevel","graceMS":100,"everyNframe":55,"specific":"nukage","atHpAmt":20}
	if type == 16: return {"amt":10,"tickRateMS":500,"graceMS":100,"everyNframe":55,"specific":"nukage"}
	return null

static func printOwner(node,prefix=""):
	var nodeOwner = "null"
	if node.owner != null:
		nodeOwner = node.owner.name
		
	print(prefix+node.name+" ("+nodeOwner+","+node.filename+")")
	
	for i in node.get_children():
		printOwner(i,prefix+" ")

static func doesFileExist(path : String) -> bool:
	var f : File = File.new()
	var ret = f.file_exists(path)
	f.close()
	return ret


