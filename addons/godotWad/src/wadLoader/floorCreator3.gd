tool
extends Node
var vertsl= []
var parent = null
var navMeshs = []

var floorMap
var mapDict : Dictionary
var luArr = []
var colArr = []
var mapName = ""
var allFloorMesh : ArrayMesh = ArrayMesh.new()
var scaleFactor

func _ready():
	scaleFactor = get_parent().scaleFactor
	set_meta("hidden",true)


var floorNavMeshArr = []
var lines = []
var verts = []
var sidedefs = []
var polyArr = []
var polyBB = []
var polyIdxToInfo = []
var polyGrid = {}
var specialNode
var modifiedCeils = {}

func instance(mapDict,geomNode,specialNode):
	
	mapName = mapDict["name"]
	var startTime = OS.get_system_time_msecs()
	self.specialNode = specialNode
	floorNavMeshArr = []
	lines = []
	verts = []
	sidedefs = []
	polyArr = []
	polyBB = []
	polyIdxToInfo = []
	polyGrid = {}
	modifiedCeils = {}

	sidedefs = mapDict["SIDEDEFS"]
	var sectors = mapDict["SECTORS"]
	var sides = mapDict["SIDEDEFS"]
	verts = mapDict["VERTEXES"]
	lines = mapDict["LINEDEFS"]
	
	vertsl = verts
	mapDict = mapDict
	allFloorMesh = ArrayMesh.new()
	
	if get_parent().generateFloorMap:
		floorMap = Control.new()
		floorMap.name = "floorPlan"
		floorMap.set_script(load("res://floorPlan.gd"))
		
		var shapeCast = ShapeCast2D.new()
		shapeCast.shape = CircleShape2D.new()
		shapeCast.shape.radius = 0.1
		shapeCast.target_position = Vector2.ZERO
		shapeCast.collide_with_bodies = false
		shapeCast.collide_with_areas = true
		shapeCast.name = "ShapeCast2D"
		floorMap.add_child(shapeCast)
		floorNavMeshArr = []
		get_parent().mapNode.add_child(floorMap)

	
	if get_parent().generateNav != get_parent().NAV.OFF:
		var nav = Navigation.new()
		nav.cell_size = scaleFactor.x/0.031
		nav.cell_height = scaleFactor.y/0.038
		nav.name = "Navigation"

		var navMesh = NavigationMeshInstance.new()
		navMesh.name = "NavMesh"

		nav.add_child(navMesh)
		geomNode.get_parent().add_child(nav)

	var secToLines = createSectorToLineArray(sectors,lines,sides)["sectorLines"]
	var guessPoly = null

	
	var sectorToLoops = []
	
	
	var sectorToLoopsFloors : Array = []
	var sectorToLoopsFloorsInfo : Array = []
	
	var sectorToLoopsCeilings: Array  = []
	var sectorToLoopsCeilingsInfo: Array  = []
	
	for sectorIndex in sectors.size():
		var currentSector = sectors[sectorIndex]
		var secLines = secToLines[sectorIndex]
		var tag = currentSector["tagNum"]
		var type = currentSector["type"]
		
		
			
		if secLines == null:#somne maps have an error wehere the sector dosen't exist
			sectorToLoopsFloors.append([])
			sectorToLoopsCeilings.append([])
			sectorToLoopsFloorsInfo.append([])
			sectorToLoopsCeilingsInfo.append([])
			continue

		if secLines.size() < 3:
			sectorToLoopsFloors.append([])
			sectorToLoopsCeilings.append([])
			sectorToLoopsFloorsInfo.append([])
			sectorToLoopsCeilingsInfo.append([])
			print("found sector with less than 3 vertices. skiping")
				
			continue

		sectorToLoopsFloors.append(createSectorClosedLoop4(secLines))
		sectorToLoopsCeilings.append(createSectorClosedLoop4(secLines))
		
		var infoFloor = {"height": currentSector["floorHeight"],"texture": currentSector["floorTexture"],"lightLevel":currentSector["lightLevel"],"type":currentSector["type"],"darkestNeighValue":currentSector["darkestNeighValue"]}
		sectorToLoopsFloorsInfo.append(infoFloor)
		
		var infoCeiling = {"height": currentSector["ceilingHeight"],"texture": currentSector["ceilingTexture"],"lightLevel":currentSector["lightLevel"],"type":currentSector["type"],"darkestNeighValue":currentSector["darkestNeighValue"]}
		
		if currentSector["ceilingTexture"] == "F_SKY1":
			var heighestSkyNeigh = infoCeiling["height"]
			for i in currentSector["nieghbourSectors"]:
				var oSector = sectors[i]
				if oSector["ceilingTexture"] == "F_SKY1":
					heighestSkyNeigh = max(heighestSkyNeigh,oSector["ceilingHeight"])
					
				if modifiedCeils.has(i):
					heighestSkyNeigh = max(heighestSkyNeigh,modifiedCeils[i])
					
			
			modifiedCeils[sectorIndex] = heighestSkyNeigh
			
			infoCeiling["highestSkyNeigh"] = heighestSkyNeigh
			
		sectorToLoopsCeilingsInfo.append(infoCeiling)
		
		
	
	var allStairSector = getStairDict(mapDict["stairLookup"])
	if get_parent().meshSimplify:
		mergeTest(sectors,sectorToLoopsFloors,sectorToLoopsFloorsInfo,allStairSector,true)
		mergeTest(sectors,sectorToLoopsCeilings,sectorToLoopsCeilingsInfo,[],false)

	

	
	for sectorIndex in sectors.size():
		
		var secNode = Spatial.new()
		var currentSector = sectors[sectorIndex]
		var tag = currentSector["tagNum"]
		
		
		
		secNode.name = "sector " + String(sectorIndex)
		secNode.set_meta("floorHeight",currentSector["floorHeight"])
		secNode.set_meta("ceilingHeight",currentSector["ceilingHeight"])
		secNode.set_meta("oSides",[])
		secNode.set_meta("tag",String(tag))
		secNode.set_meta("sectorIdx",sectorIndex)
		secNode.set_meta("light",currentSector["lightLevel"])
		secNode.set_meta("darkestNeighValue",currentSector["ceilingHeight"])
		secNode.add_to_group("sector_tag_" + String(tag))

		geomNode.add_child(secNode)
	
	
	for sectorIdx in sectorToLoopsFloors.size():
		loopToMesh(sectorToLoopsFloors[sectorIdx],sectorToLoopsFloorsInfo[sectorIdx],sectors,sectorIdx,secToLines,geomNode,true)
	
	
	
	for sectorIdx in sectorToLoopsCeilings.size():
		loopToMesh(sectorToLoopsCeilings[sectorIdx],sectorToLoopsCeilingsInfo[sectorIdx],sectors,sectorIdx,secToLines,geomNode,false)


	var runCol = 0.0

	for i in colArr:
		runCol+=i

	#print("create_trimesh_collision called ",colArr.size()," times, on average taking ",runCol/colArr.size(),"ms")

	var runLU = 0.0

	for i in luArr:
		runLU+=i

	if get_parent().unwrapLightmap:
		print("lightmap_unwrap called ",luArr.size()," times, on average taking ",runLU/luArr.size(),"ms")
	
	if floorMap!= null:
		floorMap.visible = false
	navStuff(geomNode)
	
	get_parent().mapNode.set_meta("sectorPolyArr",polyArr)
	get_parent().mapNode.set_meta("polyIdxToInfo",polyIdxToInfo)
	get_parent().mapNode.set_meta("polyBB",polyBB)
	get_parent().mapNode.set_meta("polyGrid",polyGrid)
	
	WADG.setTimeLog(get_tree(),"floorCreation",startTime)


var secToLinesIdx


func loopToMesh(loops,loopInfo,sectors,sectorIdx,secToLines,geomNode,isFloor):
	var currentSector = sectors[sectorIdx]
	var secNode = geomNode.get_node("sector " + String(sectorIdx))
	var guessPoly

	if loops.empty():
		return
	

	if typeof(loops[0]) == TYPE_STRING:#unclosed sectors don't really work but we do what we can
		guessPoly = guessConvexHull(loops[2])
		loops=loops[1]

	var workingSet = []#getLopAsVerts(loops[0],verts)
	workingSet = null

	if guessPoly != null:
		#renderLoop(currentSector,secNode,guessPoly,Vector3(0,-0.01,0)*scaleFactor,specialNode)
		renderLoopForLoop(currentSector,secNode,guessPoly,Vector3(0,-0.01,0)*scaleFactor)
		guessPoly=null

		if loops == null:#a polygon had failed to be generated
			return

	
	var secNodeL =Control.new()
	
	
	if get_parent().generateFloorMap:
		secNodeL.name = String(sectorIdx)
		floorMap.add_child(secNodeL)
		secNodeL.set_owner(floorMap)

	
	for i in loops.size():
		loops[i] = getLoopAsVerts(loops[i],verts)
		removeUnnecessaryVerts(loops[i])
		

	
	var all = []

	var poly = []
	var holes = []

	for i in loops:
		if(!Geometry.is_polygon_clockwise(i)):
			poly = i
		else:
			holes.append(i)


	
	var tree = createTree(loops)
	
	for i in tree:#for each loop in sector
		if i[1] == null:

			var tex = $"../ResourceManager".fetchFlat(currentSector["floorTexture"])

			workingSet = i[0]
			var children = getNodeChildren(i,tree,currentSector)
			children.sort_custom(self,"shapeXaxisCompare")


			for j in children:
				if j.size()<3:
					print("found a sub area with less than 3 vertices")
					continue


				for s in workingSet.size():
					workingSet[s]/= scaleFactor.x

				for s in j.size():
					j[s]  /= scaleFactor.x
				workingSet = createCanal(workingSet,j,String(sectorIdx))

				for s in workingSet.size():
					workingSet[s] *= scaleFactor.x

				for s in j.size():
					j[s]  *= scaleFactor.x


			workingSet = easeOverlapping(workingSet)
			#removeUnnecessaryVerts(workingSet)
			
			
			addPolyTofloorMap(workingSet,secNodeL,secNode,null)
			
			#renderLoop(currentSector,secNode,workingSet,Vector3.ZERO,specialNode)
			renderLoopForLoop(loopInfo,secNode,workingSet,Vector3.ZERO,isFloor)
			
	
	if secNodeL.get_child_count() == 0:
		secNodeL.queue_free()
	
	if !get_parent().generateFloorMap:
		secNodeL.queue_free()
		
	
	

func navStuff(geomNode):
	return
	var staticMesh = MeshInstance.new()



	var shape = allFloorMesh.create_trimesh_shape()
	var colShapeNode = CollisionShape.new()
	var col = StaticBody.new()


	colShapeNode.shape = shape

	col.name = "floorMap3D"
	col.add_child(colShapeNode)
	geomNode.get_parent().add_child(col)
	staticMesh.mesh = allFloorMesh

	col.collision_layer = 32768
	col.collision_mask = 0
	
	if get_parent().generateNav == get_parent().NAV.LARGE_MESH:
		createNav(geomNode,staticMesh)

	if get_parent().generateNav == get_parent().NAV.SINGLE_MESH:
		for i in floorNavMeshArr:
			var t = geomNode.get_node("../Navigation/NavMesh")
			t.add_child(i)


func createNav(geomNode,mesh):
	var navigation  = geomNode.get_node("../Navigation")
	var navMeshInstance = NavigationMeshInstance.new()
	var meshD = mesh.duplicate()

	navMeshInstance.add_child(meshD)
	navigation.add_child(navMeshInstance)
	#var navigationMesh = NavigationMesh.new()

	#navigationMesh.create_from_mesh(mesh)
	#navigation.add_child(navigationMesh)

	geomNode.get_parent().add_child(navigation)


func getNodeChildren(node,treeArr,sector):
	var arr = []
	var index = treeArr.find(node)
	for i in treeArr:
		if i[1] == index:
			arr.append(i[0])
	return arr

func getMaxX(shape):
	var shapeMaxX = Vector2(-INF,0)
	for vert in shape:
		if vert.x > shapeMaxX.x:
			shapeMaxX = vert

	if shapeMaxX.x != -INF:
		return shapeMaxX
	else:
		return


func createCanal(shape1,shape2,dbg = false):
	
	
	shape1 = Array(shape1)
	shape2 = Array(shape2)
	
	var shape2MaxX = Vector2(-INF,0)
	var shape2MaxIndex = -1
	var shapae1closestIndex = -1
	var shape1closestVert
	var shape1nextIndex
	var fiddleVector = Vector2(0,0)
	var isVertex = false

	shape2MaxX = getMaxX(shape2)
	shape2MaxIndex = shape2.find(shape2MaxX)

	var shape1close = getClosetXpoint(shape2MaxX,shape1)
	if shape1close == null:
		print("failed to created canal")
		return shape1
	shape1closestVert = shape1close[0]
	shapae1closestIndex = shape1close[1]
	shape1nextIndex = shape1close[2]


	if shape1closestVert == shape1[shapae1closestIndex] or shape1closestVert == shape1[shape1nextIndex]:
		isVertex = true

	var s1Sfter


	var s1Before = shape1.slice(0,shapae1closestIndex)
	if shapae1closestIndex != shape1.size()-1:
		s1Sfter = shape1.slice(shapae1closestIndex+1,shape1.size())
	else:
		s1Sfter = []


	var half1 = []
	var half2 = []

	if shape2MaxIndex != 0:
		half1 = shape2.slice(0,shape2MaxIndex-1)#everything up untill the split point
	else:
		half1 = []#giving slice a negative number will just loop it back over to the end of the array
	half2 = shape2.slice(shape2MaxIndex,shape2.size()-1)#everyting after the split point(including the split point itself)


	var increasingY = 1
	if (shape1[shapae1closestIndex].y -shape1[shape1nextIndex].y) > 0:
		increasingY =-1


	var newS2EndPoint = scaleLine([ (half2 + half1).back(),shape2MaxX],1)

	var newS1EndPoint = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.000001) #- Vector2(0,0.01)
	if increasingY == 1:
		 newS1EndPoint = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.000001) #+ Vector2(0,0.01)
	if isVertex:#if we are a vertice we need to look one point foward than we usually do

		var nextPointAfterEnd = (shape1nextIndex+1)%shape1.size()

		var line = [shape1closestVert,shape1[nextPointAfterEnd]]
		newS1EndPoint = scaleLine(line,0.000001)



	var s2combine = half2 + half1 + [newS2EndPoint]

	var s2lastLine = [s2combine[s2combine.size()-1],shape2MaxX]
	#var transitionLine = [s2newOrder.back(), shape1closestVert]
	var combinedPoly

	combinedPoly = s1Before + [shape1closestVert] + s2combine + [newS1EndPoint]  + s1Sfter


	removeDuplicateVerts(combinedPoly)
	removeUnnecessaryVerts(combinedPoly)
	
	
#	createDbgPoly(combinedPoly,dbgName)


	return combinedPoly





func createCanal5(shape,holes,debug = false):
	
	if !Geometry.is_polygon_clockwise(shape): shape.invert()
	
	var j = 0
	for i in holes:
		if Geometry.is_polygon_clockwise(i): i.invert()

		shape =polyUtil.rev(shape,i)

		
		if debug:
			polyUtil.saveVertArrAsScene(shape,"ij")
			
		
		#breakpoint
		#breakpoint
		j += 1
		if j == 3:
			break
		
	return shape
	
	

func getSlope(a,b):

	var diff = b - a
	var slope


	if diff.x != 0:
		slope = diff.y/diff.x
	else:
		slope = sign(diff.y)*99999999999

	return slope


func canalTwoPolys(polyA,polyB,leaveA,enterB,leaveB,enterA):





	#	WADG.saveNodeAsScene(createPoly2DFromVerts(polyB,"pewirwe"))
	#	polyB.invert()

	var leaveIdxA =  polyA.find(leaveA)
	var enterIdxB =  polyB.find(enterB)

	var exitIdxB =  polyB.find(leaveB)
	var enterIdxA = polyA.find(enterA)


	if leaveIdxA == -1: leaveIdxA = addPointToPoly(polyA,leaveA)
	if enterIdxB == -1: enterIdxB =addPointToPoly(polyB,enterB)
	if exitIdxB == -1: exitIdxB =addPointToPoly(polyB,leaveB)
	if enterIdxA == -1: enterIdxA =addPointToPoly(polyA,enterA)

	#if Geometry.is_polygon_clockwise(polyA):
	#	polyA.invert()

	#if Geometry.is_polygon_clockwise(polyB):
#		polyB.invert()
#

	
	leaveIdxA =  polyA.find(leaveA)
	enterIdxB =  polyB.find(enterB)

	exitIdxB =  polyB.find(leaveB)
	enterIdxA = polyA.find(enterA)






	var shapeHalf1 = polyA.slice(0,leaveIdxA)
	var shapeHalf2 = polyA.slice(enterIdxA,polyA.size())



	var newPolyB = []

	for i in polyB.size():
		print((enterIdxB +i)%polyB.size())
		var idx = (enterIdxB +i)%polyB.size()#here we are assuming polygon is CCW
		newPolyB.append(polyB[idx])



	

	return shapeHalf1 + newPolyB + shapeHalf2



func addPointToPoly(poly,point):

	var minDist = INF
	var closestPoint = Vector2.ZERO
	var closestSeg = [0,1]

	for i in poly.size():
		var segA = poly[i]
		var segB = poly[(i+1)%poly.size()]

		var closest = Geometry.get_closest_point_to_segment_2d(point,segA,segB)
		var dist = point.distance_squared_to(closest)

		if dist < minDist:
			minDist = dist
			closestPoint = closest
			closestSeg = [i,(i+1)%poly.size()]


		if is_equal_approx(0,dist):
			break


	poly.insert(closestSeg[1],closestPoint)




func getLoopAsVerts(loop,verts):
	var vertArray = []
	for i in loop:
		var vert = verts[i[1]]
		vertArray.append(vert)
	return vertArray

func vertIndexArrToVertArr(loop,verts):
	var vertArray = []
	for vertIdx in loop:
		vertArray.append(verts[vertIdx])
		
	return vertArray



func renderLoopForLoop(currentSector,sectorNode,verts,offset = Vector3(0,0,0),isFloor = true):
	
	var height = currentSector["height"]
	var textureName = currentSector["texture"]
	var texture
	
	
	
	if currentSector.has("highestSkyNeigh"):
		height = currentSector["highestSkyNeigh"]
	if textureName != "F_SKY1":
		texture = $"../ResourceManager".fetchFlat(textureName,!get_parent().dontUseShader)
		if texture == null:
			texture = $"../ResourceManager".fetchPatchedTexture(textureName,!get_parent().dontUseShader)
	
	
	if get_parent().skyCeil == get_parent().SKYVIS.DISABLED:#the floor can be a ceiling too
		if textureName == "F_SKY1":
			return


	
		
	var vertArray= triangulate(verts)#if the sector is complete this should return a non-empty array
	
	if vertArray == []:
		vertArray = Geometry.convex_hull_2d(verts)
		vertArray = triangulate(vertArray)

	if vertArray == []:
		return

	


	var dim = Vector3(-INF,0,-INF)
	var mini = Vector3(INF,0,INF)
	var finalArr =[]
	var origin = offset

	for i in vertArray.size()/3:
		var t1 = Vector3(vertArray[i*3].x,0,vertArray[i*3].y)  - origin
		var t2 = Vector3(vertArray[i*3+1].x,0,vertArray[i*3+1].y) - origin
		var t3 = Vector3(vertArray[i*3+2].x,0,vertArray[i*3+2].y) - origin

		if t1.x > dim.x: dim.x = t1.x
		if t2.x > dim.x: dim.x = t2.x
		if t2.x > dim.x: dim.x = t3.x
		if t1.z > dim.z: dim.z = t1.z
		if t2.z > dim.z: dim.z = t2.z
		if t2.z > dim.z: dim.z = t3.z

		if t1.x < mini.x: mini.x = t1.x
		if t2.x < mini.x: mini.x = t2.x
		if t2.x < mini.x: mini.x = t3.x
		if t1.z < mini.z: mini.z = t1.z
		if t2.z < mini.z: mini.z = t2.z
		if t2.z < mini.z: mini.z = t3.z


		finalArr.append(t1)
		finalArr.append(t2)
		finalArr.append(t3)

	var light = currentSector["lightLevel"]


				
	
	var dir = 1
	
	if !isFloor:
		dir = -1
	
	var ret = createMesh(finalArr,height,dir,dim,mini,textureName,texture,currentSector,true)
	
	
	
	var mesh : MeshInstance= ret["mesh"]
	var center = ret["center"]

	if isFloor:
		mesh.name = "floor " + textureName
		mesh.set_meta("floor",true)
	else:
		mesh.name = "ceil " + textureName
		mesh.set_meta("ceil",true)

	mesh.translation = (center + Vector3(0,height,0))

	
	if isFloor:
		funcHandleFakeFloor(mesh,sectorNode,currentSector)
	
	mesh.create_trimesh_collision()

	
	if mesh.get_child_count() >0:
		#mesh.get_child(0).set_collision_layer_bit(0,0)
		#mesh.get_child(0).set_mask_layer_bit(0,0)
	#if mesh.has_node("_col"):
	##	mesh.get_node("_col").set_meta("floor","true")
		#mesh.get_child(0).set_collision_layer_bit(0,0)
		mesh.get_child(0).set_collision_mask_bit(0,0)
		mesh.get_child(0).set_collision_layer_bit(1,1)
		
	#	mesh.get_child()

	if textureName == "F_SKY1":
		mesh.get_child(0).collision_layer = 0


	
	
	#floorMesh.set_meta("sector",currentSector["index"])#this requred for teleports to work
	mesh.add_to_group(sectorNode.name)
	sectorNode.add_child(mesh)

	
	var type = currentSector["type"]


	if type != 0:

		var lightLevel = currentSector["lightLevel"]
		var script = load("res://addons/godotWad/src/sectorType.gd")
		
			
		
		if isFloor:
			var node = Node.new()
			var dmgInfo = WADG.getDamageInfoFromSectorType(type)
			mesh.set_meta("damage",dmgInfo)

			node.name = "sectorType-" + sectorNode.name
			node.set_script(script)


			var lePath = "../../Geometry/" + sectorNode.name + "/" + mesh.name
	
			node.darkValue = currentSector["darkestNeighValue"]
			node.brightValue = currentSector["lightLevel"]
			node.meshPath = lePath
			node.type = type
			mesh.set_meta("special",node)
			specialNode.add_child(node)
		


func makeMesh(arr,sector,textureName,dir):
	var surf = SurfaceTool.new()
	var surfAbs = SurfaceTool.new()
	var sum = Vector3.ZERO
	var tempMesh = Mesh.new()
	var mat : Material
	var texture

	if textureName !="F_SKY1":
		texture = $"../ResourceManager".fetchFlat(textureName)
		mat = $"../ResourceManager".fetchMaterial(textureName,texture,sector["lightLevel"],Vector2(0,0),1,false)
	else:
		var texName : String = $"../ImageBuilder".getSkyboxTextureForMap(mapName) 
		mat = $"../ResourceManager".fetchSkyMat(texName)

	for vert in arr:
		sum += vert

	var center = sum/arr.size()
	sector["center"] = center

	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_material(mat)
	
	if dir == 1:
		arr.invert()
	
	for v in arr:
		surf.add_normal(Vector3(0,dir,0))
		if texture != null:
			if texture.get_width() != 0 and texture.get_height()!=0:
				var uvX = (v.x)/(texture.get_width() * scaleFactor)
				var uvY = (v.z)/(texture.get_height() * scaleFactor)
				surf.add_uv(Vector2(uvX,uvY))

		
		surf.add_vertex((v-center))

	surf.commit(tempMesh)
	return {"mesh":tempMesh,"translation":center}

func createMesh(arr,height,dir,dim,mini,textureName,texture,sector,toAllMesh = false):
	var surf = SurfaceTool.new()
	var surfAbs = SurfaceTool.new()
	var tmpMesh = Mesh.new()
	var scaleFactor = get_parent().scaleFactor
	var textureKey = textureName
	var center
	var sum = Vector3.ZERO
	for vert in arr:
		sum += vert

	center = sum/arr.size()
	sector["center"] = center
	var mat


	var matKey= textureName +"," + String(sector["lightLevel"])+ "," + String(Vector2(0,0))



	if textureName !="F_SKY1":
		mat = $"../ResourceManager".fetchMaterial(textureName,texture,sector["lightLevel"],Vector2(0,0),1,false)
	else:
		
		mat = $"../ResourceManager".fetchSkyMat($"../ImageBuilder".getSkyboxTextureForMap(mapName),true)

	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfAbs.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_material(mat)

	if dir == -1:
		arr.invert()
	var count = 0


	for v in arr:
		surf.add_normal(Vector3(0,dir,0))
		if texture != null:
			if texture.get_width() != 0 and texture.get_height()!=0:

				var uvX = (v.x)/(texture.get_width() * scaleFactor.x)
				var uvY = (v.z)/(texture.get_height() * scaleFactor.z)

				surf.add_uv(Vector2(uvX,uvY))
		surf.add_vertex((v-center))

		surfAbs.add_vertex((v+Vector3(0,height,0)))



	surf.commit(tmpMesh)
	tmpMesh.surface_set_name(tmpMesh.get_surface_count()-1,textureName)

	if toAllMesh:
		surfAbs.commit(allFloorMesh)

	if get_parent().unwrapLightmap:
		var a = OS.get_system_time_msecs()
		tmpMesh.lightmap_unwrap(Transform.IDENTITY,1)
		luArr.append(OS.get_system_time_msecs()-a)

	var meshNode = MeshInstance.new()
	meshNode.mesh = tmpMesh


	meshNode.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	meshNode.use_in_baked_light = true


	return {"mesh":meshNode,"center":center}





func triangulate(arr):
	var triangualted = Geometry.triangulate_polygon(arr)
	#var triangualted = Geometry.triangulate_delaunay_2d(arr)
	#triangualted.invert()
	var vertArrTri = []
	for i in triangualted:
		vertArrTri.append(arr[i])

	return vertArrTri


func triangualteDelaunay(arr):
	var triangualted = Geometry.triangulate_polygon(arr)

func createSectorClosedLoop(sectorLines):#gets all closed loops in sector
	var soup = sectorLines.duplicate(true)
	var loops = []
	var curloop = []
	var badVerts = []
	var first = [INF,INF]
	for line in sectorLines: #we start with the line that hasw the smallest vert index
		if line[0] < first[0]:
			first = line






func createSectorClosedLoop3(sectorLines):
	var lines = sectorLines.duplicate(true)
	var allLoops = []
	while(lines.size()>0):# as long as we have a vertex

		#if lines[0] == [4,5]:
		#	breakpoint
		var runningLoop = [lines[0]]#the start of loop is set
		var foundNext = true
		lines.erase(lines[0])

		while foundNext:
			foundNext = addNextToLoop(runningLoop[runningLoop.size()-1],lines,runningLoop)

		if runningLoop.size() > 2:
			allLoops.append(runningLoop)




	return allLoops


func createSectorClosedLoop4(sectorLines):
	var lines = sectorLines.duplicate(true)
	var allLoops = []
	while(lines.size()>0):# as long as we have a vertex

		var runningLoop = [lines[0]]#the start of loop is set
		var foundNext = true
		lines.erase(lines[0])

		while foundNext:
			foundNext = addNextToLoopOld(runningLoop[runningLoop.size()-1],lines,runningLoop)

		if runningLoop.size() > 2:
			allLoops.append(runningLoop)


	return allLoops




func addNextToLoop(cur,lineList,runningLoop):

	var bestCandidate = null
	#if cur[0] == 2:
	#	breakpoint
	for l in lineList:
		var b = cur[1]

		if l == [cur[1],cur[0]]:
			continue



		elif b == l[0]:
			if bestCandidate == null:
				bestCandidate = l
				break
				#runningLoop.append(l)
				#lines.erase(l)
			else:
				var c1 = verts[cur[0]]
				var c2 = verts[cur[1]]

				var b1 = verts[l[0]]
				var b2 = verts[l[1]]

				var curDx = (c2-c1).x
				var canDx = (b2-b1).x

				var curDy = (c2-c1).y
				var canDy = (b2-b1).y

				if canDx > curDx:
					bestCandidate = l
				elif canDx == curDx:
					if canDy < curDy:
						bestCandidate = l


			#return true

	if bestCandidate != null:

		runningLoop.append(bestCandidate)

		var key0 = String(String(bestCandidate[0]) + "," + String(bestCandidate[1]))
		var curOside = lines[secToLinesIdx[key0]].backSideDef
		lineList.erase(bestCandidate)



		return true

	return false


func addNextToLoopOld(cur,lines,runningLoop):
	for l in lines:
		var b = cur[1]
			
		if b == l[0]:
			runningLoop.append(l)
			lines.erase(l)
			return true
		
	return false

func commitToLoop(value,curLoop,soup):
	curLoop.append(value)
	soup.erase(value)
	if soup.size()>0:
		return true
	else:
		return false




func createSectorToLineArray(sectors,lines,sides):
	var linNum = 0
	var sectorLines = []
	var sectorLineIdx = {}

	sectorLines.resize(sectors.size())
	#sectorLineIdx.resize(sectors.size())

	for line in lines:

		var frontSideIndex = line["frontSideDef"]
		var backSideIndex = line["backSideDef"]


		if backSideIndex != -1:


			var frontSide = sides[frontSideIndex]
			var fsectorId = frontSide["frontSector"]

			var backSide = sides[backSideIndex]
			var bsectorId = backSide["frontSector"]

			if bsectorId == fsectorId:
				continue


		var frontSide = sides[frontSideIndex]
		var sectorId = frontSide["sector"]

		if typeof(sectorLines[sectorId]) != TYPE_ARRAY: sectorLines[sectorId] = []

		sectorLines[sectorId].append([line["startVert"],line["endVert"]])
		var key = String(line["startVert"]) + "," +  String(line["endVert"])
		sectorLineIdx[key] = line["index"]

		if backSideIndex != -1 :
			var backSide = sides[backSideIndex]
			var backSectorId = backSide["sector"]

			if backSectorId == sectorId:
				continue
			if typeof(sectorLines[backSectorId]) != TYPE_ARRAY: sectorLines[backSectorId] = []


			sectorLines[backSectorId].append([line["endVert"],line["startVert"]])
			key = String(line["endVert"]) + "," +  String(line["startVert"])
			sectorLineIdx[key] = line["index"]
			#sectorLineIdx[sectorId].append([line["index"]])

		linNum += 1
	return {"sectorLines":sectorLines,"sectorLinesIdx":sectorLineIdx}

func createTree(loops):
	var arr = loops.duplicate(true)

	var tree = []
	for i in arr:
		tree.append([i,null,[]])

	for i in tree.size()-1:
		for j in range(i+1,arr.size()):
			var p1 = tree[i][0]
			var p2 = tree[j][0]
			var isP1withinP2 = (Geometry.clip_polygons_2d(p1,p2)) == []
			var isP2withinP1 = (Geometry.clip_polygons_2d(p2,p1)) == []

			if isP1withinP2:
				tree[i][1] = j

			if isP2withinP1:
				tree[j][1] = i

	return tree


func createTree2(loops,loopsLineIdx):
	var loopArr = loops.duplicate(true)

	var root = Control.new()
	root.name = "stage1"
	for i in loopArr.size():
		treeRecursive2(root,root,loopArr[i],loopsLineIdx[i])

	return root


func treeRecursive(root,current,poly):

	var polyName = "polygon"
	var temp = poly.duplicate()

	#if isHole(poly):
	#	poly.set_meta("hole",true)
	#	polyName = "hole"

	if current.get_children().size() == 0:
		if current == root:
			root.add_child(createPoly2DFromVerts(poly,polyName))#if root has no children add self and return
			return

		elif Geometry.clip_polygons_2d(poly,current.polygon)== []:#poly is contained by current:
			current.add_child(createPoly2DFromVerts(poly,polyName))
			return

		elif Geometry.clip_polygons_2d(current.polygon,poly) == []:#this poly contains the current
			var polyNode = createPoly2DFromVerts(poly,polyName)
			swapParent(current.get_parent(),polyNode)
			current.get_parent().add_child(polyNode)
			return
		else:
			root.add_child(createPoly2DFromVerts(poly,polyName))#poly is its own island
			return


	for c in current.get_children():
		var cPolygon = c.polygon

		if Geometry.clip_polygons_2d(poly,cPolygon) == []:#poly is contained by c:
			var inv = poly.duplicate()
			inv.invert()
			inv = PoolVector2Array(inv)
			if inv == cPolygon:#case where polygon is adentical but vert orders reversed (a.k.a its a hole)
				current.add_child(createPoly2DFromVerts(poly,polyName))
				return
			else:
				treeRecursive(root,c,poly)
				return
		elif Geometry.clip_polygons_2d(cPolygon,poly) == []:#this poly actually contains c
			var polyNode = createPoly2DFromVerts(poly,polyName)
			swapParent(c,polyNode)
			current.add_child(polyNode)
			return



	var polyNode = createPoly2DFromVerts(poly,polyName)
	current.add_child(polyNode)

var polyCount = 0

func treeRecursive2(root,current,poly,loopsLineIdx):

	var polyName = "polygon" + String(polyCount)
	polyCount += 1


	#if polyName == "polygon2":
	#	breakpoint

	if isHole(poly,loopsLineIdx) and current != root:
		polyName = "hole"

	if current.get_children().size() == 0:

		var polyNode = createPoly2DFromVerts(poly,polyName)

		if isHole(poly,loopsLineIdx) and current != root:
			polyNode.set_meta("hole",true)


		if current == root:
			root.add_child(polyNode)#if root has no children add self and return
			return

		elif Geometry.clip_polygons_2d(poly,current.polygon)== []:#poly is contained by current:
			current.add_child(polyNode)
			return

		elif Geometry.clip_polygons_2d(current.polygon,poly) == []:#this poly contains the current
			swapParent(current.get_parent(),polyNode)
			current.get_parent().add_child(polyNode)
			return
		else:
			root.add_child(polyNode)#poly is its own island
			return


	for c in current.get_children():
		var cPolygon = c.polygon

		if Geometry.clip_polygons_2d(poly,cPolygon) == []:#poly is contained by c:
			var inv = poly.duplicate()
			inv.invert()
			inv = PoolVector2Array(inv)



			if inv == cPolygon:#case where polygon is adentical but vert orders reversed (a.k.a its a hole)
				#current.add_child(createPoly2DFromVerts(poly,polyName))

				return
			else:
				treeRecursive2(root,c,poly,loopsLineIdx)
				return
		elif Geometry.clip_polygons_2d(cPolygon,poly) == []:#this poly actually contains c
			var polyNode = createPoly2DFromVerts(poly,polyName)

			if isHole(poly,loopsLineIdx) and current != root:
				polyNode.set_meta("hole",true)

			swapParent(c,polyNode)
			current.add_child(polyNode)
			return



	var polyNode = createPoly2DFromVerts(poly,polyName)
	if isHole(poly,loopsLineIdx) and current != root:
		polyNode.set_meta("hole",true)
	current.add_child(polyNode)



func treeStage2(root,current):#remove sub shapes that dont need to exist and categorize holes



	#print("-------")
	for c in current.get_children():
		#if c.name == "hole":
		if c.has_meta("hole"):
			for gc in c.get_children():
				swapParent(gc,root)
		treeStage2(root,c)

	#print(current.name)
	#if onlyHoles(current) and current.name != "hole" and current.get_parent()!= root:
	if onlyHoles(current) and !current.has_meta("hole") and current.get_parent()!= root and current!=root:
		print(current.name)
		for i in current.get_children():
			swapParent(i,current.get_parent())#make all holes siblings
		
		current.get_parent().remove_child(current)
		current.queue_free()
		return

	if current.get_children().size() == 0:#if we are at an end node
		#if current.name != "hole" and current.get_parent()!= root and current.get_parent().name != "hole":
		if !current.has_meta("hole") and current.get_parent()!= root and !current.get_parent().has_meta("hole"):
			current.get_parent().remove_child(current)
			current.queue_free()



func treeTriangulation(root,dbg = false):
	var test = Node2D.new()
	test.name = "triangualtionFinal"
	var count = 0
	var arr = []
	var fillerArr = []
	var holes : Array = []

	
	
	for poly in root.get_children():

		poly.name = "final"
		for i in poly.get_children():
			holes.append(i.polygon)
		
		
		
		
		#holes.sort_custom(self,"shapeXaxisCompare")
		#for h in holes:
		while holes.size() > 0:
			var h = holes[0]
#
			
			#poly.polygon = createCanal4(Array(poly.polygon),Array(h),fillerArr,holes,dbg)

			holes.erase(h)
		#	count += 1
			

			
			
			var t = 3
		
		#if dbg:
		#	WADG.saveNodeAsScene(poly)
		arr.append(poly.polygon)
		



	var tris = []

	for k in arr:
		#var p = createPoly2DFromVerts(k,"r")
		var indices = Geometry.triangulate_polygon(k)
		for i in indices:
			tris.append(Vector3(k[i].x,0,k[i].y))

		#test.add_child(p)


	for k in fillerArr:
		var indices = Geometry.triangulate_polygon(k)
		for i in indices:
			tris.append(Vector3(k[i].x,0,k[i].y))



	return tris


	
	
	

func isHole(verts,loopsLineIdx):
	var key = String(loopsLineIdx[0][0])+ "," +String(loopsLineIdx[0][1])
	var lineIdx = secToLinesIdx[key]
	var line = lines[lineIdx]
	if line["backSideDef"] == -1 or line["frontSideDef"] == -1:
		return true

	if line["backSideDef"] != -1:
		var s1 =sidedefs[line["frontSideDef"]]
		var s2 = sidedefs[line["backSideDef"]]

		if s1["frontSector"] != s2["frontSector"]:
			return true

	return false
	#return Geometry.is_polygon_clockwise(verts)


func onlyHoles(node):

	if node.get_children().size() == 0:
		return false

	for i in node.get_children():
		if !i.has_meta("hole"):
		#if i.name != "hole":
			return false

	return true


func swapParent(child,newParent):
	child.get_parent().remove_child(child)
	newParent.add_child(child)

func getClosetXpoint(point,poly):
	var maxX = getMaxX(poly)
	var closestDist = INF
	var ret = null
	for i in poly.size():
		var line1 = [poly[i],poly[(i+1)%poly.size()]]
		var line2 = [point,Vector2(maxX.x+10*scaleFactor.y,point.y)]
		var closestPoint = Geometry.segment_intersects_segment_2d(line1[0],line1[1],line2[0],line2[1])
		if closestPoint != null:
			if point.distance_squared_to(closestPoint) < closestDist:
				closestDist =  point.distance_squared_to(closestPoint)

				ret = [closestPoint,i,(i+1)%poly.size()]

	if ret != null:
		return [Vector2(round(ret[0].x),round(ret[0].y)),ret[1],ret[2]]
	return ret

func scaleLine(line,factor):
	var slope = line[1] - line[0]
	return line[0] + (slope*factor)


func shapeXaxisCompare(a,b):
	if getMaxX(a) > getMaxX(b):
		return true
	else:
		return false

func guessConvexHull(arr):
	var tmp = []

	for i in arr:

		if tmp.find(vertsl[i[0]]) == -1:
			tmp.append(vertsl[i[0]])
		if tmp.find(vertsl[i[1]])  == -1:
			tmp.append(vertsl[i[1]])
	var hull = Geometry.convex_hull_2d(tmp)


	return hull

func removeDuplicateVerts(arr):
	var end = arr.size()
	var i = 0
	while(i<end):
		if arr.size()<4:
			return
		var a = stepifyVector(arr[i],0.1)
		var b = stepifyVector(arr[(i+1)%arr.size()],0.1)

		if a == b:
			arr.remove((i+1)%arr.size())
			i-=1
			end = arr.size()
		i+=1

func removeUnnecessaryVerts(arr):

	var end = arr.size()
	var i = 0
	while(i<end):
		if arr.size()<4:
			return
		var a = stepifyVector(arr[i],0.1)
		var b = stepifyVector(arr[(i+1)%arr.size()],0.1)
		var c = stepifyVector(arr[(i+2)%arr.size()],0.1)
		var slopeA
		var slopeB
		var aDeltaX = (b.x-a.x)
		var bDeltaY = (c.x-b.x)

		if aDeltaX == 0:
			slopeA = INF
		else:
			slopeA = (b.y-a.y)/(b.x-a.x)

		if bDeltaY == 0:
			slopeB = INF
		else:
			slopeB = (c.y-b.y)/(c.x-b.x)

		if slopeA == slopeB:

			arr.remove((i+1)%arr.size())
			i-=1
			end = arr.size()

		i+=1

func stepifyVector(v,step):
	v = Vector2(stepify(v.x,step),stepify(v.y,step))
	return v

func stepifyVector3(v,step):
	v = Vector3(stepify(v.x,step),stepify(v.y,step),stepify(v.z,step))
	return v


func savefloorMap():

	get_parent().add_child(floorMap)
	var pack = PackedScene.new()
	pack.pack(floorMap)
	ResourceSaver.save("res://dbg/"+"floorMap"+".tscn",pack)




func addPolyTofloorMap(arr,sectorNodeL : Node,sectorNode,texture=null):
	polyArr.append(arr)
	var bb = WADG.getBoundingBox(arr)
	polyBB.append(bb)
	var overlappingCells = WADG.findOverlappingCells(bb,polyBB.size())
	
	for cell in overlappingCells:
		if !polyGrid.has(cell):
			polyGrid[cell] = []
	
		polyGrid[cell].append(polyBB.size()-1)
	
	var m = sectorNode.get_meta_list()
	polyIdxToInfo.append({"floorHeight":sectorNode.get_meta("floorHeight"),"ceilingHeight":sectorNode.get_meta("ceilingHeight"),"sectorIdx":sectorNode.get_meta("sectorIdx"),"tag":sectorNode.get_meta("tag"),"light":sectorNode.get_meta("light")})
	
	return
	
#	var centerArr = arr.duplicate()
#	var center = Vector2.ZERO
#
#	for v in arr:
#		center += v
#
#	center /= arr.size()
#
#	for i in centerArr.size():
#		centerArr[i] -= center
#
#
#
#	var poly = Polygon2D.new()
#	poly.name = "Polygon2D"
#	poly.polygon = centerArr
#	poly.texture = texture
#
#
#	poly.position = center
#	var area = Area2D.new()
#	area.name = "Area2D"
#
#	var colPoly = CollisionPolygon2D.new()
#
#	colPoly.name = "CollisionPolygon2D"
#	colPoly.polygon = centerArr
#
#	area.set_meta("index",sectorNode.name)
#
#	area.add_child(colPoly)
#	poly.add_child(area)
#	colPoly.scale = Vector2.ONE
#	sectorNodeL.add_child(poly)




func makePolyShape(pointsAsVerts):
	var vector2pool = PoolVector2Array(pointsAsVerts)

	var segs :  PoolVector2Array= []


	for v in vector2pool.size():
		segs.append(vector2pool[v])

		if v != 0:
			segs.append(vector2pool[v])

		if v == vector2pool.size()-1:
			segs.append(vector2pool[0])

	var polyShape = ConcavePolygonShape2D.new()
	polyShape.segments = segs

	var collisionShape = CollisionShape2D.new()
	collisionShape.shape = polyShape


	return collisionShape



func easeOverlapping(arr):
	var size = arr.size()

	for i in arr:
		if arr.count(i) >1:
			var a = arr.find(i)
			var b = arr.find_last(i)

			var aLine = [(a-1)%size,a,(a+1)%size]
			var bLine = [(b-1)%size,b,(b+1)%size]
			if a == 0: aLine[0] += size
			if b == 0: bLine[0] += size

			var aBefore = min(aLine[0],aLine[2])
			var aAfter = max(aLine[0],aLine[2])
			var bBefore = min(bLine[0],bLine[2])
			var bAfter = max(bLine[0],bLine[2])


			var aLineV = [arr[aBefore],arr[aLine[1]],arr[aAfter]]
			var bLineV = [arr[bBefore],arr[bLine[1]],arr[bAfter]]
			#var bLineV = [arr[bLine[0]],arr[bLine[1]],arr[bLine[2]]]


			arr[aLine[1]] = scaleLine([aLineV[0],aLineV[1]],0.99999)
			arr[bLine[1]] = scaleLine([bLineV[0],bLineV[1]],0.99999)


	return arr



func createPoly2DFromVerts(arr,polyName,texture=null):
	var poly = Polygon2D.new()
	poly.polygon = arr
	poly.name = polyName
	poly.texture = texture
	return poly




func funcHandleFakeFloor(mesh,sectorNode,secInfo):
	return
	var mapInfo = $"../LevelBuilder".mapDict

	var sectorIdx = secInfo["index"]


	#var neighs = secInfo["nieghbourSectors"]
	var nieghSides = mapInfo["sectorToSides"][sectorIdx]


	for i in nieghSides:
		var line = mapInfo["SIDEDEFS"][i]
		if line["upperName"] != "-" and line["upperName"] != "AASTINKY":
			return
		if line["lowerName"] != "-" and line["lowerName"] != "AASTINKY":
			return
		if line["middleName"]!= "-" and line["middleName"] != "AASTINKY":
			return



	var mesh2 : MeshInstance = mesh.duplicate()


	var neighIdx = secInfo["nieghbourSectors"][0]
	var neighInfo = mapInfo["SECTORS"][neighIdx]
	var neighTexture= neighInfo["floorTexture"]
	var matKey= neighTexture +"," + String(neighInfo["lightLevel"])+ "," + String(Vector2(0,0))

	var neighFloorTextureRes = $"../ResourceManager".fetchFlat(neighInfo["floorTexture"],!get_parent().dontUseShader)
	var neighFloorMat = $"../ResourceManager".fetchMaterial(neighTexture,neighFloorTextureRes,neighInfo["lightLevel"],Vector2(0,0),0,false)

	mesh2.set_surface_material(0,neighFloorMat)



	mesh2.translation.y = secInfo["nextHighestFloor"]
	sectorNode.add_child(mesh2)


func handleSelfRefSector(lines):
	breakpoint




func getFurthestPointOnPoly(poly,axis = Vector2.RIGHT):
	
	var furthestPoint = Vector2.ZERO
	var furthestDist = -INF
	
	for v in poly:
		if v.dot(axis) > furthestDist:
			furthestPoint = v
			furthestDist = v.dot(axis)
			
	return furthestPoint
	
func getFurthestSegOnPoly(poly,axis = Vector2.RIGHT):
	
	var furthestPoint = Vector2.ZERO
	var furthestDist = -INF
	
	for vi in poly.size():
		var v1 = poly[vi]
		var v2 = poly[(vi +1)%poly.size()]
		
		var mid1 = v1 + ((v2 - v1)/2.0)
		
		if mid1.dot(axis) > furthestDist:
			furthestPoint = poly[vi]
			furthestDist = mid1.dot(axis)
			
	return furthestPoint

func rightmostPolyCompare(a,b):
	var ap = getFurthestPointOnPoly(a)
	var bp = getFurthestPointOnPoly(b)
	
	if ap.x > bp.x:
		return true
	if ap.x == bp.x:
		if ap.y < bp.y:
			return true
	
	return false
		
func rightmostPolySegMidCompare(a,b):
	if getFurthestSegOnPoly(a).x > getFurthestSegOnPoly(b).x:
		return true
	else:
		return false


func mergeTest(sectors,sectorLoops : Array,sectorLoopsInfo,stairLookup : Array,isFloor):
	var mergeCount = 0
	var mapDict = get_parent().maps[get_parent().mapName]
	var sectorToInteraction = mapDict["sectorToInteraction"]
	
	var sectorsDupe = sectors.duplicate(true)

	var sectorIndex = -1
	
		
	while sectorIndex < sectorsDupe.size()-1:
		
		sectorIndex+=1
		
		
		if sectorLoops[sectorIndex].empty():
			continue
		
		if sectorToInteraction.has(sectorIndex):
			continue
		
		
		if stairLookup.has(sectorIndex):
			continue
		
		
		var currentSector = sectorsDupe[sectorIndex]
		var neighIdx = currentSector["nieghbourSectors"]
		var info = sectorLoopsInfo[sectorIndex]
		
		if info["type"] != 0:
			continue
		
		#if sectorLoopsInfo[76]["height"] != 76:
		#	breakpoint

		
		for neighSecIdx in neighIdx:
			
			#if sectorLoopsInfo[76]["height"] != 76:
			#	breakpoint
			#print(sectorLoopsInfo[76])
			
			if sectorToInteraction.has(neighSecIdx):#if its an interaction sectior we will probably skip
				
				
				var lineType = null
				
				if sectorToInteraction[neighSecIdx].size() == 1: 
					lineType = sectorToInteraction[neighSecIdx][0]["type"]
				
				if lineType != null and !isFloor:
					var typeInfo = $"../LevelBuilder".typeSheet.data[String(lineType)]#unless we are ceiling and interaction is floor
					
					if typeInfo["type"] != WADG.LTYPE.LIFT and typeInfo["type"] != WADG.LTYPE.FLOOR:
						continue
					
					
				else:
					continue
			
			
			if stairLookup.has(neighSecIdx):
				continue
			
			var secBloops : Array = sectorLoops[neighSecIdx]
			var secAloops : Array = sectorLoops[sectorIndex]
			
			if secAloops.empty():
				continue
			
			if secBloops.empty():
				continue
			
			var neighSector = sectorsDupe[neighSecIdx]
			
			
			var neighInfo = sectorLoopsInfo[neighSecIdx]
			
			if neighInfo["type"] != 0:
				continue
			
			if info["height"] != neighInfo["height"]:
				continue
			
			if info["texture"] != neighInfo["texture"]:
				continue
			
			
			
			if info["texture"] != "F_SKY1":
				if info["lightLevel"] != neighInfo["lightLevel"] :
					continue
			
			
			
			var commonLine = null
			
			
			
			var continueFlag = false
			
			if secBloops.size() == 1 and secAloops.size() > 1:
				var t2 = secBloops[0]
				var bFlat = lineTupleTovVertIndices(t2)
				bFlat.sort()
				
				for i in secAloops.size():
					var iFlat = lineTupleTovVertIndices(secAloops[i])
					iFlat.sort()
					
					if bFlat == iFlat:
						sectorLoops[sectorIndex].remove(i)
						sectorLoops[neighSecIdx] = []
						continueFlag = true
						break
						
				
			if continueFlag:
				sectorLoops[neighSecIdx] = []
				
			
				for i in neighSector["nieghbourSectors"]:
					if i != sectorIndex and !currentSector["nieghbourSectors"].has(i):
					 !currentSector["nieghbourSectors"].append(i)
			

		
				currentSector["nieghbourSectors"].erase(neighSecIdx)

				mergeCount +=1 
				sectorIndex -= 1
				continue
			
			if secAloops.size() > 1 or secBloops.size() > 1:
				continue
			
			
			
			var aLoop = secAloops[0]
			var bLoop = secBloops[0]
			
			
			
			
			var commonLineArr = []
			
			
			for aVert in aLoop:
				for bVert in bLoop:
					if aVert[0] == bVert[1] and aVert[1] == bVert[0]:
						#commonLine = aVert
						commonLineArr.append(aVert)
						

			
			if commonLineArr.size() > 1 or commonLineArr.size()<1:
				continue
				
			commonLine = commonLineArr[0]
			
			if commonLine == null:
				continue
			
			
			
			var aI = lineTupleTovVertIndices(aLoop)
			var bI = lineTupleTovVertIndices(bLoop)
			
			
			var m = join(aI,bI,aI.find(commonLine[0]),bI.find(commonLine[0]))
			
			var mL = vertArrToLineIndices(m)
			
			
			sectorLoops[neighSecIdx] = []
			sectorLoops[sectorIndex] = [mL]
			
			for i in neighSector["nieghbourSectors"]:
				if i != sectorIndex and !currentSector["nieghbourSectors"].has(i):
					 !currentSector["nieghbourSectors"].append(i)
			

		
			currentSector["nieghbourSectors"].erase(neighSecIdx)

			mergeCount +=1 
			sectorIndex -= 1
			break


func join(vertsA,vertsB,aPointIdx,bPointIdx):#aPoint is vert whre A enters B, bPoint is where b is entered into 
	
	var ret = []
	var i = 0
	
	if Geometry.is_polygon_clockwise(vertsA): #for seem reason what I think would be clockwise is the opposite of what this returns
		aPointIdx = vertsA.size()-1 - aPointIdx
		vertsA.invert()
	if Geometry.is_polygon_clockwise(vertsB):
		bPointIdx = vertsB.size()-1 - bPointIdx
		vertsB.invert()
	
	
	while i < vertsA.size():#for each vert in a
		
		ret.append(vertsA[i])
		if i == aPointIdx:#if we reached a's entry point into b
			for j in vertsB.size():
				ret.append(vertsB[(j+bPointIdx)%vertsB.size()])
				
		i += 1
	
	

	var aVerts = vertIndexArrToVertArr(vertsA,verts)#
	var bVerts = vertIndexArrToVertArr(vertsB,verts)
	var cVerts = vertIndexArrToVertArr(ret,verts)
	#polyUtil.saveVertArrAsScene(aVerts,"A")
#	polyUtil.saveVertArrAsScene(bVerts,"B")
#	polyUtil.saveVertArrAsScene(cVerts,"C")
	
	#polyUtil.saveVertArrAsScene(getLoopAsVerts(ret,verts),"C")
	
	#print("polyA:",getLoopAsVerts(vertsA,verts))
	#print("polyB:",getLoopAsVerts(vertsB,verts))
#	print("combined poly:",ret))
	
	return ret


func lineTupleTovVertIndices(arr):
	if arr.empty():
		return []
	
	var ret = [arr[0][0]]
	
	for i in range(1,arr.size()):
		ret.append(arr[i][0])
	
	return ret
	
	
func vertArrToLineIndices(arr : Array):
	var arrNoDupe = []
	var ret = []
	for i in arr:
		if !arrNoDupe.has(i):
			arrNoDupe.append(i)
	
	for i in arrNoDupe.size():
		ret.append([arrNoDupe[i],arrNoDupe[(i+1)%arrNoDupe.size()]])
	
	
	return ret

func getStairDict(dict):
	var allStairs  = []
	
	for i in dict.keys():
		if !allStairs.has(i):
			allStairs.append(i)
		
		for j in dict[i]:
			if !allStairs.has(j):
				allStairs.append(j)
	
	return allStairs
