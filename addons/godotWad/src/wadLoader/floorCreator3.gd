@tool
extends Node
var vertsl: PackedVector2Array= []
@onready var parent : WAD_Map = get_parent()
var navMeshs : Array = []

var floorMap
var mapDict : Dictionary
var luArr : Array= []
var mapName : String = ""
var allFloorMesh : ArrayMesh = ArrayMesh.new()
var scaleFactor : Vector3
@onready var resourceManager : Node = $"../ResourceManager"
@onready var materialManager : Node = $"../MaterialManager"
@onready var imageBuilder : Node = $"../ImageBuilder"


func _ready():
	scaleFactor = get_parent().scaleFactor
	set_meta("hidden",true)


var lines : Array[Dictionary] = []
var verts : PackedVector2Array = []
var sidedefs :  Array[Dictionary] = []
var polyArr : Array[PackedVector2Array] = []
var polyBB : Array[Rect2] = []
var polyIdxToInfo : Array[Dictionary] = []
var polyGrid :Dictionary = {}
var specialNode : Node
var modifiedCeils : Dictionary = {}
var secToLinesIdx : Dictionary

func instance(mapDict : Dictionary,geomNode : Node3D,specialNode : Node) -> void:
	
	var mapNode = parent.mapNode
	mapName = mapDict["name"]
	var startTime : int = Time.get_ticks_msec()
	self.specialNode = specialNode
	lines = []
	verts = []
	sidedefs = []
	polyArr = []
	polyBB = []
	polyIdxToInfo = []
	polyGrid = {}
	modifiedCeils = {}

	sidedefs = mapDict["sideDefsParsed"]
	var sectors : Array = mapDict["sectorsParsed"]
	#var sides = mapDict["SIDEDEFS"]
	verts = mapDict["vertexesParsed"]
	lines = mapDict["lineDefsParsed"]

	vertsl = verts
	self.mapDict = mapDict
	allFloorMesh = ArrayMesh.new()
	
	if parent.generateFloorMap:
		floorMap = Control.new()
		floorMap.name = "floorPlan"
		floorMap.set_script(load("res://floorPlan.gd"))
		
		var shapeCast : ShapeCast2D= ShapeCast2D.new()
		shapeCast.shape = CircleShape2D.new()
		shapeCast.shape.radius = 0.1
		shapeCast.target_position = Vector2.ZERO
		shapeCast.collide_with_bodies = false
		shapeCast.collide_with_areas = true
		shapeCast.name = "ShapeCast2D"
		floorMap.add_child(shapeCast)
		mapNode.add_child(floorMap)

	
	if parent.generateNav != get_parent().NAV.OFF:
		var nav = Node3D.new()
		#nav.cell_size = scaleFactor.x/0.031
		#nav.cell_height = scaleFactor.y/0.038
		nav.name = "Navigation"

		var navMesh = NavigationRegion3D.new()

		navMesh.name = "NavMesh"
		nav.add_child(navMesh)
		geomNode.get_parent().add_child(nav)

	var secToLines : Array = createSectorToLineArray(sectors,lines,sidedefs)["sectorLines"]
	var guessPoly = null


	var sectorToLoopsFloors : Array[Array] = []
	var sectorToLoopsFloorsInfo : Array[Dictionary] = []
	
	var sectorToLoopsCeilings: Array[Array]  = []
	var sectorToLoopsCeilingsInfo: Array[Dictionary]  = []
	var sectorToInteraction : Dictionary = mapDict["sectorToInteraction"]
	var typeData = $"../LevelBuilder".typeSheet.data
	
	for sectorIndex : int in sectors.size():
		var currentSector : Dictionary = sectors[sectorIndex]
		#var test = secToLines[sectorIndex]
		var secLines : Array[PackedInt32Array]
		secLines.resize( secToLines[sectorIndex].size())
		
		for i in secToLines[sectorIndex].size():
			secLines[i] = secToLines[sectorIndex][i]
			
		var a : Array[PackedInt32Array]= secLines
		var b : Array = secToLines[sectorIndex]
		
		
		
		if secLines == null:#somne maps have an error wehere the sector dosen't exist
			sectorToLoopsFloors.append([])
			sectorToLoopsCeilings.append([])
			sectorToLoopsFloorsInfo.append({})
			sectorToLoopsCeilingsInfo.append({})
			continue

		elif secLines.size() < 3:
			sectorToLoopsFloors.append([])
			sectorToLoopsCeilings.append([])
			sectorToLoopsFloorsInfo.append({})
			sectorToLoopsCeilingsInfo.append({})
			print("found sector with less than 3 vertices. skiping")
				
			continue

		sectorToLoopsFloors.append(createSectorClosedLoop4(secLines))
		sectorToLoopsCeilings.append(createSectorClosedLoop4(secLines))
		
		
		var infoFloor : Dictionary = {"height": currentSector["floorHeight"],"texture": currentSector["floorTexture"],"lightLevel":currentSector["lightLevel"],"type":currentSector["type"],"darkestNeighValue":currentSector["darkestNeighValue"]}
		sectorToLoopsFloorsInfo.append(infoFloor)
		
		var infoCeiling : Dictionary= {"height": currentSector["ceilingHeight"],"texture": currentSector["ceilingTexture"],"lightLevel":currentSector["lightLevel"],"type":currentSector["type"],"darkestNeighValue":currentSector["darkestNeighValue"]}
		
		if sectorToInteraction.has(sectorIndex):#todo: move this to it's own function
			for interaction in sectorToInteraction[sectorIndex]:
				var x = str(interaction['type'])
				if typeData.has(x):
					var typeInfo : Dictionary = typeData[x]
					if typeInfo["type"] == WADG.LTYPE.SCROLL:
						if typeInfo["direction"] == WADG.DIR.UP or typeInfo["direction"] == WADG.DIR.DOWN:
							if typeof (typeInfo["vector"]) == TYPE_STRING:
								if typeInfo["vector"] == "linedef":
									var line = lines[interaction["line"]]
									var diff = verts[line["endVert"]] - verts[line["startVert"]]
									
									if typeInfo["direction"] == WADG.DIR.UP:
										infoCeiling["vector"] = diff
									
									if typeInfo["direction"] == WADG.DIR.DOWN:
										infoFloor["vector"] = diff
									
									#var diff = verts[]
		
		
		if currentSector["ceilingTexture"] == &"F_SKY1":
			var heighestSkyNeigh : float= infoCeiling["height"]
			for i : int in currentSector["nieghbourSectors"]:
				var oSector : Dictionary = sectors[i]
				if oSector["ceilingTexture"] == &"F_SKY1":
					heighestSkyNeigh = max(heighestSkyNeigh,oSector["ceilingHeight"])
					
				if modifiedCeils.has(i):
					heighestSkyNeigh = max(heighestSkyNeigh,modifiedCeils[i])
					
			
			modifiedCeils[sectorIndex] = heighestSkyNeigh
			
			infoCeiling["highestSkyNeigh"] = heighestSkyNeigh
			
		sectorToLoopsCeilingsInfo.append(infoCeiling)
		
		
	
	var allStairSector : Array= getStairDict(mapDict["stairLookup"])
	var dynamicFloors : PackedInt32Array = mapDict["dynamicFloors"]
	var dynamicCeilings : Array = mapDict["dynamicCeilings"]
	
	
	
	if get_parent().meshSimplify:
		mergeTest(sectors,sectorToLoopsCeilings,sectorToLoopsCeilingsInfo,allStairSector,dynamicFloors,dynamicCeilings,false)
		mergeTest(sectors,sectorToLoopsFloors,sectorToLoopsFloorsInfo,allStairSector,dynamicFloors,dynamicCeilings,true)
		#
		

	for sectorIndex : int in sectors.size():
		
		var secNode := Node3D.new()
		var currentSector : Dictionary = sectors[sectorIndex]
		var tag : int= currentSector["tagNum"]
		
		
		secNode.name = "sector " + str(sectorIndex)
		secNode.set_meta("floorHeight",currentSector["floorHeight"])
		secNode.set_meta("ceilingHeight",currentSector["ceilingHeight"])
		secNode.set_meta("oSides",[])
		secNode.set_meta("tag",str(tag))
		secNode.set_meta("sectorIdx",sectorIndex)
		secNode.set_meta("light",currentSector["lightLevel"])
		secNode.set_meta("darkestNeighValue",currentSector["ceilingHeight"])
		secNode.add_to_group("sector_tag_" + str(tag))

		geomNode.add_child(secNode)
	
	
	#var t1 = Thread.new()
	#var t2 = Thread.new()
	
	
	
	var t = Time.get_ticks_msec()
	
	#allLoopToMesh(sectorToLoopsFloors,sectorToLoopsFloorsInfo,sectors,secToLines,geomNode,true)
	#allLoopToMesh(sectorToLoopsCeilings,sectorToLoopsCeilingsInfo,sectors,secToLines,geomNode,false)
	#t1.start(allLoopToMesh.bind(sectorToLoopsFloors,sectorToLoopsFloorsInfo,sectors,secToLines,geomNode,true),Thread.PRIORITY_HIGH)
	#t2.start(allLoopToMesh.bind(sectorToLoopsCeilings,sectorToLoopsCeilingsInfo,sectors,secToLines,geomNode,false))
	#t1.wait_to_finish()
	#t2.wait_to_finish()
	

	for sectorIdx : int in sectorToLoopsFloors.size():
		#t1.start(loopToMesh.bind(sectorToLoopsFloors[sectorIdx],sectorToLoopsFloorsInfo[sectorIdx],sectors,sectorIdx,secToLines,geomNode,true))
		#t1.wait_to_finish()
		loopToMesh(sectorToLoopsFloors[sectorIdx],sectorToLoopsFloorsInfo[sectorIdx],sectors,sectorIdx,secToLines,geomNode,true)
	#
	#
	for sectorIdx : int in sectorToLoopsCeilings.size():
		loopToMesh(sectorToLoopsCeilings[sectorIdx],sectorToLoopsCeilingsInfo[sectorIdx],sectors,sectorIdx,secToLines,geomNode,false)
		
		
	
	print(Time.get_ticks_msec()-t)
	var runLU : float  = 0.0

	for i in luArr:
		runLU+=i

	if parent.unwrapLightmap:
		print("lightmap_unwrap called ",luArr.size()," times, on average taking ",runLU/luArr.size(),"ms")
	
	if floorMap!= null:
		floorMap.visible = false
	
	
	mapNode.set_meta("sectorPolyArr",polyArr)
	mapNode.set_meta("polyIdxToInfo",polyIdxToInfo)
	mapNode.set_meta("polyBB",polyBB)
	mapNode.set_meta("polyGrid",polyGrid)
	
	SETTINGS.setTimeLog(get_tree(),"floorCreation",startTime)



func allLoopToMesh(sectorToLoop,loopInfo,sectors,secToLines,geomNode,isFloor):
	for sectorIdx : int in sectorToLoop.size():
		loopToMesh(sectorToLoop[sectorIdx],loopInfo[sectorIdx],sectors,sectorIdx,secToLines,geomNode,isFloor)
		
		


var count = 0
func loopToMesh(loops : Array,loopInfo : Dictionary,sectors : Array[Dictionary],sectorIdx : int,secToLines :Array[Array],geomNode : Node ,isFloor : bool) -> void:
	var currentSector : Dictionary = sectors[sectorIdx]
	var secNode : Node = geomNode.get_node("sector " + str(sectorIdx))
	var guessPoly

	if loops.is_empty():
		return
	

	if typeof(loops[0]) == TYPE_STRING:#unclosed sectors don't really work but we do what we can
		guessPoly = guessConvexHull(loops[2])
		loops=loops[1]

	var workingSet : PackedVector2Array= []#getLopAsVerts(loops[0],verts)
	workingSet = []

	if guessPoly != null:
		#renderLoop(currentSector,secNode,guessPoly,Vector3(0,-0.01,0)*scaleFactor,specialNode)
		renderLoopForLoop(currentSector,sectorIdx,secNode,guessPoly,Vector3(0,-0.01,0)*scaleFactor,true,false)
		guessPoly=null

		if loops == null:#a polygon had failed to be generated
			return

	
	var secNodeL : Control=Control.new()
	
	
	if parent.generateFloorMap:
		secNodeL.name = str(sectorIdx)
		floorMap.add_child(secNodeL)
		secNodeL.set_owner(floorMap)

	var loopVerts : Array[PackedVector2Array]
	
	loopVerts.resize(loops.size())
	for i : int in loops.size():
		
		loopVerts[i] = getLoopAsVerts(loops[i],verts)
		removeUnnecessaryVerts(loopVerts[i])
	

	
	var tree : Array= createTree(loopVerts)
	var allRootShapes = []
	count +=1
	
	for i : Array in tree:#for each loop in sector
		
		if i[1] == null:#has no parent so is a root

			#var tex : Texture2D = resourceManager.fetchFlat(currentSector["floorTexture"])
			
			workingSet = i[0]
			var children : Array[PackedVector2Array]= getNodeChildren(i,tree)
			children.sort_custom(Callable(self, "shapeXaxisCompare"))
			
			for j : Array in children:
				if j.size()<3:
					print("found a sub area with less than 3 vertices")
					continue

				for s : int in workingSet.size():
					workingSet[s]/= scaleFactor.x

				for s : int in j.size():
					j[s]  /= scaleFactor.x
				
				workingSet = createCanal(workingSet,j)
				
				
				for s in workingSet.size():
					workingSet[s] *= scaleFactor.x

				for s in j.size():
					j[s]  *= scaleFactor.x
					
				

			
			workingSet = easeOverlapping(workingSet)

			removeUnnecessaryVerts(workingSet)
			addPolyTofloorMap(workingSet,secNodeL,secNode,null)
			allRootShapes.append(workingSet)
			#renderLoop(currentSector,secNode,workingSet,Vector3.ZERO,specialNode)
			#renderLoopForLoop(loopInfo,sectorIdx,secNode,workingSet,Vector3.ZERO,isFloor,false,extras)
			
	
	var extras : Array[Array] = []
	extras.resize(allRootShapes.size())
	#var toErase = []
	#
	#if allRootShapes.size() > 1:
		#for i in allRootShapes.size()-1:
			#var res = areShapesIdentical(allRootShapes[0],allRootShapes[i+1])
			#if res != Vector2.INF:
				#extras[i].append(res)
				#allRootShapes[i+1] = [] as PackedVector2Array
	
	var k = 0
	
	#while k < allRootShapes.size():
	#	if allRootShapes[k].is_empty():
	#		allRootShapes.remove_at(k)
	#	else:
	#		k+=1
	
	for i in allRootShapes.size():
		if allRootShapes[i].is_empty():
			continue
		renderLoopForLoop(loopInfo,sectorIdx,secNode,allRootShapes[i],Vector3.ZERO,isFloor,false,extras[i])
		
	
	if secNodeL.get_child_count() == 0:
		secNodeL.queue_free()
	
	if !get_parent().generateFloorMap:
		secNodeL.queue_free()
		
	
	


func createNav(geomNode,mesh):
	var navigation  = geomNode.get_node("../Navigation")
	var navMeshInstance = NavigationRegion3D.new()
	var meshD = mesh.duplicate()

	navMeshInstance.add_child(meshD)
	navigation.add_child(navMeshInstance)

	geomNode.get_parent().add_child(navigation)


func getNodeChildren(treeNode : Array,treeArr : Array[Array]) -> Array[PackedVector2Array]:
	var arr : Array[PackedVector2Array]= []
	var index = treeArr.find(treeNode)
	for i in treeArr:
		if i[1] == index:
			arr.append(i[0])
	return arr

func getMaxX(shape : Array) -> Vector2:
	var shapeMaxX : Vector2 = Vector2(-INF,0)
	
	for vert : Vector2 in shape:
		if vert.x > shapeMaxX.x:
			shapeMaxX = vert

	if shapeMaxX.x != -INF:
		return shapeMaxX
	else:
		#this shouldn't happen
		return Vector2.INF


func createCanal(shape1: PackedVector2Array,shape2 : PackedVector2Array) -> PackedVector2Array:

	var shape2MaxX : Vector2 = Vector2(-INF,0)
	var shape2MaxIndex : int = -1
	var shapae1closestIndex : int= -1
	var shape1closestVert
	var shape1nextIndex
	var fiddleVector : Vector2 = Vector2(0,0)
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

	var s1Sfter : PackedVector2Array
	var s1Before : PackedVector2Array = shape1.slice(0,shapae1closestIndex+1)
	
	if shapae1closestIndex != shape1.size()-1:
		s1Sfter = shape1.slice(shapae1closestIndex+1,shape1.size()+1)
	else:
		s1Sfter = []


	var half1  : PackedVector2Array= []
	var half2 : PackedVector2Array= []

	if shape2MaxIndex != 0:
		half1 = shape2.slice(0,shape2MaxIndex)#everything up untill the split point
	else:
		half1 = []#giving slice a negative number will just loop it back over to the end of the array
	half2 = shape2.slice(shape2MaxIndex,shape2.size())#everyting after the split point(including the split point itself)


	var increasingY = 1
	if (shape1[shapae1closestIndex].y -shape1[shape1nextIndex].y) > 0:
		increasingY =-1

	var lastVert : Vector2
	
	if half1.is_empty():
		lastVert = half2[half2.size()-1]
	else:
		lastVert = half1[half1.size()-1]
	
	var newS2EndPoint : Vector2= scaleLine([ lastVert,shape2MaxX],1)
	#var newS2EndPoint : Vector2= scaleLine([ (half2 + half1).back(),shape2MaxX],1)18/08/24

	var newS1EndPoint : Vector2 = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.000001) #- Vector2(0,0.01)
	if increasingY == 1:
		newS1EndPoint  = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.000001) #+ Vector2(0,0.01)
	if isVertex:#if we are a vertice we need to look one point foward than we usually do

		var nextPointAfterEnd : int= (shape1nextIndex+1)%shape1.size()

		var line : Array = [shape1closestVert,shape1[nextPointAfterEnd]]
		newS1EndPoint = scaleLine(line,0.000001)



#	var s2combine : PackedVector2Array = half2 + half1 + [newS2EndPoint])18/08/24
	half2.append_array(half1)
	half2.append(newS2EndPoint)
	var s2combine : PackedVector2Array = half2
	var s2lastLine : PackedVector2Array = [s2combine[s2combine.size()-1],shape2MaxX]
	var combinedPoly : PackedVector2Array

	combinedPoly = s1Before + PackedVector2Array([shape1closestVert]) + s2combine + PackedVector2Array([newS1EndPoint])  + s1Sfter
	
	
	removeDuplicateVerts(combinedPoly)
	removeUnnecessaryVerts(combinedPoly)
	
	
#	createDbgPoly(combinedPoly,dbgName)


	return combinedPoly






	
	

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






	var shapeHalf1 = polyA.slice(0,leaveIdxA+1)
	var shapeHalf2 = polyA.slice(enterIdxA,polyA.size()+1)



	var newPolyB = []

	for i in polyB.size():
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

		var closest = Geometry2D.get_closest_point_to_segment(point,segA,segB)
		var dist = point.distance_squared_to(closest)

		if dist < minDist:
			minDist = dist
			closestPoint = closest
			closestSeg = [i,(i+1)%poly.size()]


		if is_equal_approx(0,dist):
			break


	poly.insert(closestSeg[1],closestPoint)




func getLoopAsVerts(loop:Array,verts:Array) -> PackedVector2Array:
	var vertArray : PackedVector2Array = []
	for i : Array in loop:
		var vert = verts[i[1]]
		vertArray.append(vert)
	return vertArray

func vertIndexArrToVertArr(loop : Array,verts: Array) -> Array:
	var vertArray : Array= []
	for vertIdx in loop:
		vertArray.append(verts[vertIdx])
		
	return vertArray


var colShapeCache : Dictionary = {}

func renderLoopForLoop(currentSector : Dictionary,sectorIndex : int,sectorNode : Node,verts : PackedVector2Array,offset : Vector3= Vector3(0,0,0),isFloor : bool = true,holesPresent = true,extras = []) -> void:
	
	
	var height : float = currentSector["height"]
	var textureName : StringName = currentSector["texture"]
	var fakeTexture : Texture2D
	var fakeTextureName = textureName
	var texture : Texture2D
	var fakeTarget = "fakeFloors"
	
	if !isFloor:
		fakeTarget = "fakeCeilings"
	
	var alpha : float = 1.0
	
	
	if mapDict.has(fakeTarget):
		if mapDict[fakeTarget].has(sectorIndex):
			for entry in mapDict[fakeTarget][sectorIndex]:
				textureName = entry[1]
				if entry.size() == 3:
					alpha = entry[2]
	
	if fakeTextureName != textureName:
		if textureName != "F_SKY1":
			fakeTexture = resourceManager.fetchFlat(fakeTextureName,!parent.dontUseShader)
			
			
			if fakeTexture == null:
				fakeTexture = resourceManager.fetchPatchedTexture(fakeTextureName,!parent.dontUseShader)
	else:
		fakeTexture = texture
	
	if currentSector.has("highestSkyNeigh"):
		height = currentSector["highestSkyNeigh"]
	if textureName != "F_SKY1":
		texture = resourceManager.fetchFlat(textureName,!parent.dontUseShader)
		
		if texture == null:
			texture = resourceManager.fetchPatchedTexture(textureName,!parent.dontUseShader)
	
	
	if parent.skyCeil == parent.SKYVIS.DISABLED:#the floor can be a ceiling too
		if textureName == &"F_SKY1":
			return

	
	var vertArray: PackedVector2Array = []
	
	#if holesPresent:
	vertArray = triangulate(verts)#if the sector is complete this should return a non-empty array
	#else:
		#vertArray = triangualteDelaunay(verts)#if the sector is complete this should return a non-empty array
	
	if vertArray.is_empty():
		vertArray = Geometry2D.convex_hull(verts)
		vertArray = triangulate(vertArray)

	if vertArray.is_empty():
		return

	


	var dim : Vector3 = Vector3(-INF,0,-INF)
	var mini : Vector3 = Vector3(INF,0,INF)
	var finalArr : PackedVector3Array = []
	var origin : Vector3 = offset
	
	finalArr.resize(vertArray.size())
	
	for i : int in vertArray.size()/3:
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

		finalArr[i*3] = t1
		finalArr[i*3+1] = t2
		finalArr[(i*3+2)] = t3
		
		#finalArr.append(t1)
		#finalArr.append(t2)
		#finalArr.append(t3)
	
	var light : float= currentSector["lightLevel"]
	var dir : int = 1
	
	if !isFloor:
		dir = -1
	
 	#$"../LevelBuilder".typeSheet.data[currentSecgo]
	
	
	var vector = Vector2.ZERO
	
	if currentSector.has("vector"):
		vector = currentSector["vector"]
	

	var ret : Dictionary= createMesh(finalArr,height,dir,dim,mini,textureName,texture,currentSector,true,vector)
	
	
	
	var mesh : GeometryInstance3D = ret["mesh"]
	var center : Vector3 = ret["center"]
	
	var tintParam = WADG.getLightLevel(light)
	if parent.useInstanceShaderParam:
		mesh.set("instance_shader_parameters/sectorLight",Color(tintParam,tintParam,tintParam))
	
	if isFloor:
		mesh.name = "floor " + textureName
		mesh.set_meta("floor",true)
	else:
		mesh.name = "ceil " + textureName
		mesh.set_meta("ceil",true)

	mesh.position = (center + Vector3(0,height,0))

	if mapDict.has(fakeTarget):
		if mapDict[fakeTarget].has(sectorIndex):
			for entry in mapDict[fakeTarget][sectorIndex]:
				if !isFloor:
					dir = -dir
				var fakeFloor = createMesh(finalArr,height,dir,dim,mini,fakeTextureName,fakeTexture,currentSector,true,vector,alpha)["mesh"]
				
				fakeFloor.position = mesh.position
				fakeFloor.position.y = entry[0]
				sectorNode.add_child(fakeFloor)
	
	if isFloor:
		funcHandleFakeFloor(mesh,sectorNode,currentSector)
	
	#if !colShapeCache.has(dim):
		#mesh.create_trimesh_collision()
		#colShapeCache[dim] = mesh.get_child(0)
	#else:
		#mesh.add_child(colShapeCache[diwdm].duplicate())
	
	if verts.size() <= 4:
		createColSimple(verts,mesh,center)
	elif isConvex(verts):
		createColSimple(verts,mesh,center)
	else:
		mesh.create_trimesh_collision()
	

		
	var staticShape
	if mesh.get_child_count() >0:
		staticShape = mesh.get_child(0)
		staticShape.set_collision_layer_value(1,1)
		staticShape.set_collision_layer_value(2,1)
		

		if textureName == &"F_SKY1":
			staticShape.set_collision_layer_value(2,0)
			staticShape.set_collision_mask_value(2,0)


	
	#floorMesh.set_meta("sector",currentSector["index"])#this requred for teleports to work
	
	
	#for i in mesh.get_surface_override_material_count():
	#	mesh.mesh.surface_get_material(i).set_shader_parameter("tint",Color(tintParam,tintParam,tintParam))
	
	mesh.add_to_group(sectorNode.name)
	
	if extras.size() > 0:
		var mmi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = extras.size()+1
		mmi.set("instance_shader_parameters/sectorLight",Color(tintParam,tintParam,tintParam))
		
		mm.mesh = mesh.mesh
		
		var t = Transform3D()
		t.origin = mesh.position
		var colN = staticShape.duplicate()
		colN.transform = t
		mmi.add_child(colN)
		var count = 1
		mm.set_instance_transform(0,t)
		for i in extras:
			var tn := Transform3D()
			tn.origin.x = mesh.position.x + -(i.x)
			tn.origin.z = mesh.position.z -(i.y)
			tn.origin.y = mesh.position.y
			mm.set_instance_transform(count,tn)
			count += 1
			if staticShape != null:
				colN = staticShape.duplicate()
				colN.transform = tn
				mmi.add_child(colN)
				
		
		mmi.multimesh = mm
		mesh = mmi
		#sectorNode.add_child(mmi)
	
	#if extras.size() > 0:
		#for i in extras:
			#var exta = mesh.duplicate()
			#exta.position.x = mesh.position.x + -(i.x)
			#exta.position.z =  mesh.position.z - (i.y)
			#sectorNode.add_child(exta)
	
	sectorNode.add_child(mesh)

	
	var type : int= currentSector["type"]


	if type != 0 and isFloor:
		
		if !parent.sectorSpecials.has(type):
			return
		
		var typeEntry = parent.sectorSpecials[type]
		var lightLevel = currentSector["lightLevel"]
		var script = load("res://addons/godotWad/src/sectorType.gd")
		

		var node = Node.new()
		var dmgInfo = WADG.getDamageInfoFromSectorType2(typeEntry)
			
		specialNode.add_child(node)
			
		if dmgInfo.has("specific"):
			if dmgInfo["specific"].has("secret"):
				sectorNode.get_node("../../").totalSecrets += 1
				dmgInfo["path"] = specialNode.get_parent().get_path_to(node).get_concatenated_names()

			
		if !dmgInfo.is_empty():
			mesh.set_meta("damage",dmgInfo)

		if !typeEntry.has("light type"):
			return
		
		if typeEntry["light type"] == 0 or typeEntry["light type"] > 3:
			return
		if !typeEntry.has("name"):
			return
			
		node.name = "sectorType-" + sectorNode.name
		node.set_script(script)
		
		
		node.useInstanceShaderParam = parent.useInstanceShaderParam
		

		var path : String = "../../Geometry/" + sectorNode.name + "/" + mesh.name
		node.sectorIndex = sectorIndex
		node.darkestNeighbour = currentSector["darkestNeighValue"]
		node.initialValue = currentSector["lightLevel"]
		
		node.meshPath = path
		node.lightType = typeEntry["light type"]
		node.interval = typeEntry["light tick"]
		mesh.set_meta("special",node)
			
		



func createMesh(arr : PackedVector3Array,height:float,dir:int,dim:Vector3,mini:Vector3,textureName:StringName,texture:Texture2D,sector:Dictionary,toAllMesh:bool = false,scroll : Vector2 = Vector2.ZERO,alpha : float = 1.0) -> Dictionary:
	var surf : SurfaceTool= SurfaceTool.new()
	#var surfAbs :SurfaceTool= SurfaceTool.new()
	var tmpMesh :ArrayMesh= ArrayMesh.new()
	var scaleFactor : Vector3= parent.scaleFactor
	var textureKey : String= textureName
	var center : Vector3
	var sum : Vector3 = Vector3.ZERO
	var scale = 1
	for vert : Vector3 in arr:
		sum += vert

	center = sum/arr.size()
	sector["center"] = center
	var mat : Material


	var lightAdjust : float = WADG.getLightLevel(sector["lightLevel"])
	var sectorColor := Color(lightAdjust,lightAdjust,lightAdjust)
	
	
	if textureName !=&"F_SKY1":
		mat = materialManager.fetchGeometryMaterial(textureName,texture,sectorColor,scroll,alpha,false)
	else:
		
		mat = materialManager.fetchSkyMat(imageBuilder.getSkyboxTextureForMap(mapName),true)
	
	
	
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_material(mat)


	if dir == -1:
		arr.reverse()
	var count : int = 0
	
	var normal : Vector3 = Vector3(0,dir,0)
	var tW : float = 0
	var tH : float = 0
	
	if texture != null:
		tW  = texture.get_width() * scaleFactor.x
		tH  = texture.get_height() * scaleFactor.z
	
	for v : Vector3 in arr:
		surf.set_normal(normal)
		if texture != null:
			if tW != 0 and tH!=0:

				var uvX : float = (v.x)/(tW)
				var uvY : float = (v.z)/(tH)
	
				surf.set_uv(Vector2(uvX,uvY))
				surf.set_uv2(Vector2(uvX,uvY))
		
		surf.add_vertex((v-center)*scale)
		#surfAbs.add_vertex((v+Vector3(0,height,0)))

	tmpMesh = surf.commit()
	#tmpMesh.surface_set_name(tmpMesh.get_surface_count()-1,textureName)
	

	if parent.unwrapLightmap:
		var a = Time.get_ticks_msec()
		tmpMesh.lightmap_unwrap(Transform3D.IDENTITY,1)
		luArr.append(Time.get_ticks_msec()-a)

	var meshNode : MeshInstance3D= MeshInstance3D.new()
	meshNode.mesh = tmpMesh


	meshNode.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	meshNode.use_in_baked_light = true

	
	return {"mesh":meshNode,"center":center}


func triangulate(arr : PackedVector2Array) -> PackedVector2Array:
	var triangualted : PackedInt32Array = Geometry2D.triangulate_polygon(arr)
	
	#var triangualted = Geometry2D.triangulate_delaunay(arr)
	#triangualted.invert()
	
	var  vertArrTri : PackedVector2Array = []
	for i : int in triangualted:
		vertArrTri.append(arr[i])

	return vertArrTri


func triangualteDelaunay(arr):
	var triangualted = Geometry2D.triangulate_delaunay(arr)

	var  vertArrTri : Array = []
	
	for i : int in triangualted.size()/3:
		var a = arr[triangualted[i*3]]
		var b = arr[triangualted[(i*3)+1]]
		var c = arr[triangualted[(i*3)+2]]
		
		if !Geometry2D.is_polygon_clockwise([a,b,c]):
			vertArrTri.append(a)
			vertArrTri.append(b)
			vertArrTri.append(c)

	return vertArrTri



func createSectorClosedLoop4(sectorLines : Array[PackedInt32Array]) -> Array[Array]:
	var lines : Array= sectorLines.duplicate(true)
	var allLoops : Array[Array] = []
	
	while(lines.size()>0):# as long as we have a vertex

		var runningLoop : Array[PackedInt32Array] = [lines[0]]#the start of loop is set
		var foundNext : bool = true
		#print("-a--")
		lines.erase(lines[0])
		#print("----")

		while foundNext:
			foundNext = addNextToLoopOld(runningLoop[runningLoop.size()-1],lines,runningLoop)

		if runningLoop.size() > 2:
			allLoops.append(runningLoop)


	return allLoops


func addNextToLoopOld(cur : PackedInt32Array,lines : Array[PackedInt32Array] ,runningLoop : Array) -> bool:
	
	for l : PackedInt32Array in lines:
		var b : int = cur[1]
			
		if b == l[0]:
			runningLoop.append(l)
			#print("---b---")
			lines.erase(l)
			#print("----")
			return true
		
	return false





func createSectorToLineArray(sectors:Array,lines : Array,sides : Array) -> Dictionary:
	var linNum : int= 0
	var sectorLines : Array[Array] = []
	var sectorLineIdx : Dictionary = {}

	sectorLines.resize(sectors.size())


	for line : Dictionary in lines:

		var frontSideIndex : int = line["frontSideDef"]
		var backSideIndex : int= line["backSideDef"]


		if backSideIndex != -1:


			var frontSide : Dictionary = sides[frontSideIndex]
			var fsectorId : int = frontSide["frontSector"]

			var backSide : Dictionary= sides[backSideIndex]
			var bsectorId : int= backSide["frontSector"]

			if bsectorId == fsectorId:
				continue


		var frontSide : Dictionary = sides[frontSideIndex]
		var sectorId : int = frontSide["sector"]

		if typeof(sectorLines[sectorId]) != TYPE_ARRAY: 
			sectorLines[sectorId] = []
		
		var p : PackedInt32Array = [line["startVert"],line["endVert"]]
		sectorLines[sectorId].append(p)
		var key : String = str(line["startVert"]) + "," +  str(line["endVert"])
		sectorLineIdx[key] = line["index"]

		if backSideIndex != -1 :
			var backSide : Dictionary  = sides[backSideIndex]
			var backSectorId : int = backSide["sector"]

			if backSectorId == sectorId:
				continue
			if typeof(sectorLines[backSectorId]) != TYPE_ARRAY: 
				var pia : PackedInt32Array = []
				sectorLines[backSectorId] = pia

			var pia : PackedInt32Array = [line["endVert"],line["startVert"]]
			sectorLines[backSectorId].append(pia)
			key = str(line["endVert"]) + "," +  str(line["startVert"])
			sectorLineIdx[key] = line["index"]


		linNum += 1
	return {"sectorLines":sectorLines,"sectorLinesIdx":sectorLineIdx}

func createTree(loops : Array[PackedVector2Array]) -> Array[Array]:
	var arr = loops.duplicate(true)
	
	var tree  : Array[Array]= []
	for i : PackedVector2Array in arr:
		tree.append([i,null])

	for i in tree.size()-1:
		for j in range(i+1,arr.size()):
			var p1 : Array = tree[i][0]
			var p2 : Array= tree[j][0]
			var isP1withinP2 : bool= (Geometry2D.clip_polygons(p1,p2)) == [] 
			var isP2withinP1 : bool= (Geometry2D.clip_polygons(p2,p1)) == []

			if isP1withinP2:
				tree[i][1] = j

			if isP2withinP1:
				tree[j][1] = i

	return tree


func getClosetXpoint(point : Vector2 ,poly : PackedVector2Array):
	var maxX = getMaxX(poly)
	var closestDist = INF
	var ret = null
	
	for i in poly.size():
		var line1 : Array = [poly[i],poly[(i+1)%poly.size()]]
		var line2 : Array= [point,Vector2(maxX.x+10*scaleFactor.y,point.y)]
		var closestPoint = Geometry2D.segment_intersects_segment(line1[0],line1[1],line2[0],line2[1])
		if closestPoint != null:
			if point.distance_squared_to(closestPoint) < closestDist:
				closestDist =  point.distance_squared_to(closestPoint)

				ret = [closestPoint,i,(i+1)%poly.size()]

	if ret != null:
		return [Vector2(round(ret[0].x),round(ret[0].y)),ret[1],ret[2]]
	return ret

func scaleLine(line : Array,factor : float) -> Vector2:
	var slope : Vector2 = line[1] - line[0]
	return line[0] + (slope*factor)


func shapeXaxisCompare(a:Array,b:Array) -> bool:
	if getMaxX(a) > getMaxX(b):
		return true
		
	return false

func guessConvexHull(arr):
	var tmp = []

	for i in arr:

		if tmp.find(vertsl[i[0]]) == -1:
			tmp.append(vertsl[i[0]])
		if tmp.find(vertsl[i[1]])  == -1:
			tmp.append(vertsl[i[1]])
	var hull = Geometry2D.convex_hull(tmp)


	return hull

func removeDuplicateVerts(arr : PackedVector2Array) -> void:
	var end : int= arr.size()
	var i : int = 0
	
	while(i<end):
		var arrSize : int = arr.size()
		if arrSize<4:
			return
			
		if (arr[i]-(arr[(i+1)%arrSize])).length_squared() > 1.5:
			i+=1
			continue
			
		#print((arr[i]-(arr[(i+1)%arrSize])).length_squared())
		var a : Vector2 = stepifyVector(arr[i],0.1)
		var b : Vector2 = stepifyVector(arr[(i+1)%arrSize],0.1)

		if a == b:
			arr.remove_at((i+1)%arrSize)
			i-=1
			end = arr.size()
		i+=1

func removeUnnecessaryVerts(arr : PackedVector2Array) -> void:

	var end : int = arr.size()
	var i : int= 0
	
	while(i<end):
		var arrSize : int = arr.size()
		if arrSize<4:
			return
		var a : Vector2 = stepifyVector(arr[i],0.1)
		var b : Vector2= stepifyVector(arr[(i+1)%arrSize],0.1)
		var c : Vector2= stepifyVector(arr[(i+2)%arrSize],0.1)
		var slopeA :  float
		var slopeB:  float
		var aDeltaX : float = (b.x-a.x)
		var bDeltaY : float= (c.x-b.x)

		if aDeltaX == 0:
			slopeA = INF
		else:
			slopeA = (b.y-a.y)/(b.x-a.x)

		if bDeltaY == 0:
			slopeB = INF
		else:
			slopeB = (c.y-b.y)/(c.x-b.x)

		if slopeA == slopeB:

			arr.remove_at((i+1)%arr.size())
			i-=1
			end = arr.size()

		i+=1

func stepifyVector(v:Vector2,step:float) -> Vector2:
	v = Vector2(snapped(v.x,step),snapped(v.y,step))
	return v

func stepifyVector3(v,step):
	v = Vector3(snapped(v.x,step),snapped(v.y,step),snapped(v.z,step))
	return v


func savefloorMap():

	parent.add_child(floorMap)
	var pack = PackedScene.new()
	pack.pack(floorMap)
	ResourceSaver.save(pack,"res://dbg/"+"floorMap"+".tscn")




func addPolyTofloorMap(arr : PackedVector2Array ,sectorNodeL : Node,sectorNode : Node,texture=null) -> void:
	polyArr.append(arr)
	var bb : Rect2 = WADG.getBoundingBox(arr)
	polyBB.append(bb)
	var overlappingCells : PackedVector2Array = WADG.findOverlappingCells(bb,polyBB.size())
	
	for cell : Vector2 in overlappingCells:
		if !polyGrid.has(cell):
			polyGrid[cell] = []
	
		polyGrid[cell].append(polyBB.size()-1)
	
	polyIdxToInfo.append({"floorHeight":sectorNode.get_meta("floorHeight"),"ceilingHeight":sectorNode.get_meta("ceilingHeight"),"sectorIdx":sectorNode.get_meta("sectorIdx"),"tag":sectorNode.get_meta("tag"),"light":sectorNode.get_meta("light")})
	
	return



func easeOverlapping(arr : PackedVector2Array) -> PackedVector2Array:
	var size = arr.size()

	for i : Vector2 in arr:
		if arr.count(i) >1:
			var a  = arr.find(i)
			var b = arr.rfind(i)

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


			arr[aLine[1]] = scaleLine([aLineV[0],aLineV[1]],0.9999)
			arr[bLine[1]] = scaleLine([bLineV[0],bLineV[1]],0.9999)


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
	var nieghSides : PackedInt32Array = mapInfo["sectorToSides"][sectorIdx]


	for i in nieghSides:
		var line = mapInfo["sideDefsParsed"][i]
		if line["upperName"] != "-" and line["upperName"] != "AASTINKY":
			return
		if line["lowerName"] != "-" and line["lowerName"] != "AASTINKY":
			return
		if line["middleName"]!= "-" and line["middleName"] != "AASTINKY":
			return



	var mesh2 : MeshInstance3D = mesh.duplicate()


	var neighIdx = secInfo["nieghbourSectors"][0]
	var neighInfo = mapInfo["sectorsParsed"][neighIdx]
	var neighTexture= neighInfo["floorTexture"]
	var matKey= neighTexture +"," + str(neighInfo["lightLevel"])+ "," + str(Vector2(0,0))

	var neighFloorTextureRes = $"../ResourceManager".fetchFlat(neighInfo["floorTexture"],!parent.dontUseShader)
	var neighFloorMat = $"../ResourceManager".fetchMaterial(neighTexture,neighFloorTextureRes,neighInfo["lightLevel"],Vector2(0,0),0,false)

	mesh2.set_surface_override_material(0,neighFloorMat)
	
	


	mesh2.position.y = secInfo["nextHighestFloor"]
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


func mergeTest(sectors : Array[Dictionary],sectorLoops : Array[Array],sectorLoopsInfo : Array[Dictionary],stairLookup : Array,dynamicFloors : Array ,dynamicCeilings: Array,isFloor : bool):
	return
	
	var mergeCount : int= 0
	var mapDict : Dictionary= parent.maps[parent.mapName]
	var sectorToInteraction : Dictionary = mapDict["sectorToInteraction"]
	var lightSectors : PackedInt32Array = $"../LumpParser".lightSectors
	var sectorsDupe : Array[Dictionary]= sectors.duplicate(true)

	var sectorIndex : int = -1
	
	var typeData = $"../LevelBuilder".typeSheet.data
	
	var lookArr : PackedInt32Array= []
	for i in sectors.size():
		lookArr.append(i)
	
	#while sectorIndex < sectorsDupe.size()-1:
	var itt = 0
	while itt < lookArr.size():
		
		sectorIndex = lookArr[itt]
		
	#	print(sectorIndex)
		itt+=1
		#sectorIndex+=1
		
		
		if sectorLoops[sectorIndex].is_empty():
			continue
		
		if sectorToInteraction.has(sectorIndex):
			continue
		
		
		if stairLookup.has(sectorIndex):
			continue
		
		if dynamicFloors.has(sectorIndex) and isFloor:
			continue
		
		if dynamicCeilings.has(sectorIndex) and !isFloor:
			continue
		
		if lightSectors.has(sectorIndex):
			continue
		
		var currentSector : Dictionary= sectorsDupe[sectorIndex]
		var neighIdx : PackedInt32Array= currentSector["nieghbourSectors"]
		
		if sectorIndex >= sectorLoopsInfo.size():
			continue
		
		var info : Dictionary= sectorLoopsInfo[sectorIndex]
		
		if info["type"] != 0:
			continue

		
		for neighSecIdx : int in neighIdx:
			
			if sectorToInteraction.has(neighSecIdx):#if its an interaction sectior we will probably skip
				continue
				#actaully cant do this because we need the ceils and floors
				
				#var lineType = null
				#
				#if sectorToInteraction[neighSecIdx].size() == 1: 
					#lineType = sectorToInteraction[neighSecIdx][0]["type"]
				#
				#if lineType != null and !isFloor:
					#var typeInfo : Dictionary = typeData[str(lineType)]#unless we are ceiling and interaction is floor
					
					#if typeInfo["type"] != WADG.LTYPE.LIFT and typeInfo["type"] != WADG.LTYPE.FLOOR: actaully cant do this because we need the ceils and floors
					#	continue
					
					
				#else:
					#continue
			
			
			if stairLookup.has(neighSecIdx):
				continue
			
			if dynamicFloors.has(neighSecIdx) and isFloor:
				continue
			
			if dynamicCeilings.has(sectorIndex) and !isFloor:
				continue
			
			var secBloops : Array = sectorLoops[neighSecIdx]
			var secAloops : Array = sectorLoops[sectorIndex]
			
			if secAloops.is_empty():
				continue
			
			if secBloops.is_empty():
				continue
			
			var neighSector : Dictionary= sectorsDupe[neighSecIdx]
			
			if lightSectors.has(neighSecIdx):
				continue

			
			if neighSecIdx >= sectorLoopsInfo.size():
				continue
			
			
			var neighInfo : Dictionary= sectorLoopsInfo[neighSecIdx]
			
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
			
			
			
			var continueFlag : bool = false
			
			if secBloops.size() == 1 and secAloops.size() > 1:#of the other sector is a signle shape and this sector is more than one (we need to find if the single shape is the same as the hole in this sector)
				var bFlat : Array = lineTupleTovVertIndices(secBloops[0])#here we get the index of each piont of the possible hole sector and sort them asc.
				bFlat.sort()
				
				for i : int in secAloops.size():#we are comparing each shape in the sector to the hole of the other sector
					var iFlat : Array= lineTupleTovVertIndices(secAloops[i])
					iFlat.sort()
					
					if bFlat == iFlat:#we have found a match to the hole
						sectorLoops[sectorIndex].remove_at(i)
						sectorLoops[neighSecIdx] = []
						continueFlag = true
						break
						
				
				if continueFlag:
					sectorLoops[neighSecIdx] = []
					
					
					for i in neighSector["nieghbourSectors"]:
						if i != sectorIndex and !currentSector["nieghbourSectors"].has(i):
							currentSector["nieghbourSectors"].append(i)
				

					currentSector["nieghbourSectors"].remove_at(currentSector["nieghbourSectors"].find(neighSecIdx))#this may be cause of break
					#currentSector["nieghbourSectors"].erase(neighSecIdx)
					
					mergeCount +=1 
					itt -= 1
					continue
			
			if secAloops.size() > 1 or secBloops.size() > 1:
				continue
			
			
		
			
			var aLoop : Array = secAloops[0]
			var bLoop : Array = secBloops[0]
			
			
			var commonLineArr : Array[Array] = []
			
			
			for aVert : Array in aLoop:
				for bVert : Array in bLoop:
					if aVert[0] == bVert[1] and aVert[1] == bVert[0]:
						commonLineArr.append(aVert)

			
			
			
			if commonLineArr.size() == 0:#the sectors aren't connected
				continue


			commonLine = commonLineArr[0]
			
			
			if commonLineArr.size() == 1:#if there is only one line connecting them
				var aI : PackedInt32Array = lineTupleTovVertIndices(aLoop)
				var bI  : PackedInt32Array= lineTupleTovVertIndices(bLoop)
				
				
				var m : PackedInt32Array = join(aI,bI,aI.find(commonLine[0]),bI.find(commonLine[0]))
				
				var mL : Array = vertArrToLineIndices(m)
				
				sectorLoops[neighSecIdx] = []
				sectorLoops[sectorIndex] = [mL]
				
				
						
			elif commonLineArr.size() == bLoop.size()-1:
				
				for i in commonLineArr:
					print("---c---")
					
					aLoop.erase(i)
					print("------")
				sectorLoops[neighSecIdx] = []
				sectorLoops[sectorIndex] = [aLoop]
				
	
			else:
				continue

			#print("merge %s,%s" % [sectorIndex,neighSecIdx])
			
			for i : int in neighSector["nieghbourSectors"]:#adopt other sectors neighbours
				if i != sectorIndex and !currentSector["nieghbourSectors"].has(i):
					currentSector["nieghbourSectors"].append(i)
			
			
			currentSector["nieghbourSectors"].remove_at(currentSector["nieghbourSectors"].find(neighSecIdx))
			#currentSector["nieghbourSectors"].erase(neighSecIdx)
			
			mergeCount +=1
			itt -= 1
			
			for i in currentSector["nieghbourSectors"]:
				if i != sectorIndex:
					if lookArr.count(i) <2:
						if itt >lookArr.find(i):#if we've already proccesed and affected sector we will need to do it again at the end since it's changed
							lookArr.append(i)
			
			
	print("merge count:",mergeCount)
			


func join(vertsA : Array,vertsB : Array,aPointIdx : int,bPointIdx : int) -> PackedInt32Array:#aPoint is vert whre A enters B, bPoint is where b is entered into
	
	var ret : Array = []
	var i : int = 0
	
	if Geometry2D.is_polygon_clockwise(vertsA): #for seem reason what I think would be clockwise is the opposite of what this returns
		aPointIdx = vertsA.size()-1 - aPointIdx
		vertsA.reverse()
	if Geometry2D.is_polygon_clockwise(vertsB):
		bPointIdx = vertsB.size()-1 - bPointIdx
		vertsB.reverse()
	
	
	while i < vertsA.size():#for each vert in a
		
		ret.append(vertsA[i])
		if i == aPointIdx:#if we reached a's entry point into b
			for j in vertsB.size():
				ret.append(vertsB[(j+bPointIdx)%vertsB.size()])
				
		i += 1
	
	

	var aVerts : Array= vertIndexArrToVertArr(vertsA,verts)#
	var bVerts  : Array= vertIndexArrToVertArr(vertsB,verts)
	var cVerts  : Array= vertIndexArrToVertArr(ret,verts)

	
	return ret


func lineTupleTovVertIndices(arr : Array) -> PackedInt32Array:
	if arr.is_empty():
		return []
	
	var ret : PackedInt32Array = [arr[0][0]]
	
	for i : int in range(1,arr.size()):
		ret.append(arr[i][0])
	
	return ret
	
	
func vertArrToLineIndices(arr : PackedInt32Array) -> Array[PackedInt32Array]:
	var arrNoDupe : PackedInt32Array = []
	var ret : Array[PackedInt32Array] = []
	for i : int in arr:
		
		
		if arrNoDupe.find(i) == -1:
			arrNoDupe.append(i)
	
	for i : int in arrNoDupe.size():
		ret.append([arrNoDupe[i],arrNoDupe[(i+1)%arrNoDupe.size()]] as PackedInt32Array)
	
	
	return ret

func getStairDict(dict) -> Array:
	var allStairs  = []
	
	for i in dict.keys():
		if !allStairs.has(i):
			allStairs.append(i)
		
		for j in dict[i]:
			if !allStairs.has(j):
				allStairs.append(j)
	
	return allStairs

var vertsCache = {}

func createColSimple(verts : PackedVector2Array,meshNode : Node,center : Vector3):
	var colInstance = CollisionShape3D.new()
	var colShape = ConvexPolygonShape3D.new()
	var body = StaticBody3D.new()
	var points = PackedVector3Array()
	#colShape.points = []

	for i in verts:
		points.append(Vector3(i.x,0,i.y)-center)

	
	colShape.points = points
	
	colInstance.shape = colShape
	body.add_child(colInstance)
	meshNode.add_child(body)
	
func createColSimple2(verts : Array,meshNode : Node,center : Vector3):
	var colInstance : CollisionShape3D
	
	var body = StaticBody3D.new()
	

	if !vertsCache.has(verts):
		var points = PackedVector3Array()
		var colShape = ConvexPolygonShape3D.new()
		colInstance = CollisionShape3D.new()
		colShape.points = []
		for i in verts:
			points.append(Vector3(i.x,0,i.y)-center)

		
		colShape.points = points
		colInstance.shape = colShape
		vertsCache[verts] = colInstance.duplicate()
		
		body.add_child(colInstance)
		meshNode.add_child(body)
			   
	else:
		colInstance = vertsCache[verts].duplicate()
		body.add_child(colInstance)
		meshNode.add_child(body)

func createColRect(pionts:Array):
	var c = BoxShape3D.new()
	#c.size =

func isConvex(points: PackedVector2Array) -> bool:
	var size = points.size()
	var sign = 0
	
	for i in range(size):
		var p1 = points[i]
		var p2 = points[(i + 1) % size]
		var p3 = points[(i + 2) % size]
		
		var cross = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
		
		if sign == 0:
			sign = cross
		elif cross * sign < 0:
			return false
	
	return true

func areShapesIdentical(a: Array, b: Array):
	#return Vector2.INF
	# Ensure both arrays have the same number of vertices
	
	if a.size() != b.size():
		return Vector2.INF

	# Sort both arrays based on their positions (lexicographical order)
	a.sort()
	b.sort()

	# Calculate the translation vector between the first point in both sorted arrays
	var translation = a[0] - b[0]

	# Check if each vertex in sorted_a matches the corresponding vertex in sorted_b after translation
	for i in range(a.size()):
		if a[i] != b[i] + translation:
			return Vector2.INF

	return translation
