tool
extends Node
var vertsl= []
var parent = null
var navMeshs = []

var floorPlan
var mapDict
var luArr = []
var colArr = []

var allFloorMesh : ArrayMesh = ArrayMesh.new()
 

func _ready():
	set_meta("hidden",true)

func instance(mapDict,geomNode,specialNode):
	
	var sideDefs = mapDict["SIDEDEFS"]
	var sectors = mapDict["SECTORS"]
	var verts = mapDict["VERTEXES"]
	var lines = mapDict["LINEDEFS"]
	var sides = mapDict["SIDEDEFS"]
	vertsl = verts
	mapDict = mapDict
	allFloorMesh = ArrayMesh.new()
	floorPlan = Control.new()
	floorPlan.name = "FloorPlan"
	get_parent().mapNode.add_child(floorPlan)
	
	
	var secToLines = createSectorToLineArray(sectors,lines,sides)
	var guessPoly = null
	
	for sectorIndex in sectors.size():
		var currentSector = sectors[sectorIndex]
		var secLines = secToLines[sectorIndex]
		var tag = currentSector["tagNum"]
		
		
		if secLines == null:#somne maps have an error wehere the sector dosen't exist
			continue
		
		if secLines.size() < 3:
			print("found sector with less than 3 vertices. skiping")
			continue
		
		var loops = createSectorClosedLoop3(secLines)
		
		if loops.empty():
			continue
		#var loops = createSectorClosedLoop(sec)
		var secNode = Spatial.new()
		secNode.name = "sector " + String(sectorIndex)
		
		
		secNode.set_meta("floorHeight",currentSector["floorHeight"])
		secNode.set_meta("ceilingHeight",currentSector["ceilingHeight"])
		secNode.set_meta("oSides",[])
		secNode.set_meta("tag",String(tag))
		secNode.set_meta("sectorIdx",sectorIndex)
		secNode.add_to_group("sector_tag_" + String(tag))
		
		geomNode.add_child(secNode)
		#get_parent().get_node("Geometry").add_child(secNode)

		
		
		if typeof(loops[0]) == TYPE_STRING:#unclosed sectors don't really work but we do what we can
			guessPoly = guessConvexHull(loops[2])
			loops=loops[1]

		var workingSet = []#getLopAsVerts(loops[0],verts)
		var externals = []
		workingSet = null

		if guessPoly != null:
			renderLoop(currentSector,secNode,guessPoly,Vector3(0,-0.01,0),specialNode)
			guessPoly=null

		if loops == null:#a polygon had failed to be generated
			continue
		

		var secNodeL = Control.new()
		secNodeL.name = String(sectorIndex)
		

		floorPlan.add_child(secNodeL)

		secNodeL.set_owner(floorPlan)

		
		for i in loops.size():
			loops[i] = getLoopAsVerts(loops[i],verts)

		
		#breakpoint
		var tree = createTree(loops)
		for i in tree:#for each loop in sector
			if i[1] == null:
				
				var tex = $"../ResourceManager".fetchFlat(currentSector["floorTexture"])
				#addPolyToFloorPlan(i[0],secNodeL,tex)
				#createDbgPoly(i[0],String(sectorIndex),tex)
				workingSet = i[0]
				var children = getNodeChildren(i,tree,currentSector)
				children.sort_custom(self,"shapeXaxisCompare")
				

				for j in children:
					if j.size()<3:
						print("found a sub area with less than 3 vertices")
						continue

					workingSet = createCanal(workingSet,j,String(sectorIndex))
					
					
					
				workingSet = easeOverlapping(workingSet)
				
				removeUnnecessaryVerts(workingSet)
				addPolyToFloorPlan(workingSet,secNodeL,tex)
				renderLoop(currentSector,secNode,workingSet,Vector3.ZERO,specialNode)
	

	var runCol = 0.0
	
	for i in colArr:
		runCol+=i
		
	print("create_trimesh_collision called ",colArr.size()," times, on average taking ",runCol/colArr.size(),"ms")
	
	var runLU = 0.0
	
	for i in luArr:
		runLU+=i

	if get_parent().unwrapLightmap:
		print("lightmap_unwrap called ",luArr.size()," times, on average taking ",runLU/luArr.size(),"ms")
	floorPlan.visible = false
	navStuff(geomNode)

	
	
func navStuff(geomNode):
	
	var staticMesh = MeshInstance.new()
	var navigation = Navigation.new()
	
	
	
	navigation.add_child(staticMesh)
	
	
	var shape = allFloorMesh.create_trimesh_shape()
	var colShapeNode = CollisionShape.new()
	var col = StaticBody.new()
	
	colShapeNode.shape = shape
	
	col.name = "floorPlan3D"
	col.add_child(colShapeNode)
	geomNode.get_parent().add_child(col)
	staticMesh.mesh = allFloorMesh
	
	col.collision_layer = 32768
	col.collision_mask = 0
	



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


func createCanal(shape1,shape2,dbgName = null):

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
	
	var newS1EndPoint = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.00001) #- Vector2(0,0.01)
	if increasingY == 1:
		 newS1EndPoint = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.00001) #+ Vector2(0,0.01)
	if isVertex:#if we are a vertice we need to look one point foward than we usually do
		
		var nextPointAfterEnd = (shape1nextIndex+1)%shape1.size()
		
		var line = [shape1closestVert,shape1[nextPointAfterEnd]]
		newS1EndPoint = scaleLine(line,0.00001)
	
	

	var s2combine = half2 + half1 + [newS2EndPoint]

	var s2lastLine = [s2combine[s2combine.size()-1],shape2MaxX]
	#var transitionLine = [s2newOrder.back(), shape1closestVert]
	var combinedPoly
	
	combinedPoly = s1Before + [shape1closestVert] + s2combine + [newS1EndPoint]  + s1Sfter 
	
	
	removeDuplicateVerts(combinedPoly)
	removeUnnecessaryVerts(combinedPoly)
#	createDbgPoly(combinedPoly,dbgName)
	

	return combinedPoly



func getLoopAsVerts(loop,verts):
	var vertArray = []
	for i in loop:
		var vert = verts[i[1]]
		vertArray.append(vert)
	return vertArray


func renderLoop(currentSector,sectorNode,verts,offset = Vector3(0,0,0),specialNode=null):
	
	
	var vertArray= triangulate(verts)#if the sector is complete this should return a non-empty array
	
	if vertArray == []:
		vertArray = Geometry.convex_hull_2d(verts)
		vertArray = triangulate(vertArray)
	
	if vertArray == []:
		return
	
	var floorHeight = currentSector["floorHeight"]
	var ceilHeight = currentSector["ceilingHeight"]
	
	var floorTexture
	if currentSector["floorTexture"] != "F_SKY1":
		
		#if currentSector["index"] == 109:
		#	breakpoint
		
		floorTexture = $"../ResourceManager".fetchFlat(currentSector["floorTexture"],!get_parent().dontUseShader)
		

		
			
	var ceilTexture
	if currentSector["ceilingTexture"] != "F_SKY1":
		ceilTexture =  $"../ResourceManager".fetchFlat(currentSector["ceilingTexture"],!get_parent().dontUseShader)
	
	
	
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
	
	if true:#floorTexture!= null:
		var ret = createFloorMesh(finalArr,floorHeight,1,dim,mini,currentSector["floorTexture"],floorTexture,currentSector,true)
		var floorMesh = ret["mesh"]
		var center = ret["center"]
	
		floorMesh.translation = (center + Vector3(0,floorHeight,0))
		
		
		funcHandleFakeFloor(floorMesh,sectorNode,currentSector)
		
		var a = OS.get_system_time_msecs()
		floorMesh.create_trimesh_collision()
		colArr.append(OS.get_system_time_msecs()-a)

		
		
		
		if floorMesh.has_node("_col"):
			floorMesh.get_node("_col").set_meta("floor","true")
			floorMesh.get_child(0).set_collision_layer_bit(1,1)
		
		if currentSector["floorTexture"] == "F_SKY1":
			floorMesh.get_child(0).collision_layer = 0
	
			
		floorMesh.name = "floor " + currentSector["floorTexture"]
		floorMesh.set_meta("floor","true")
		floorMesh.set_meta("sector",currentSector["index"])
		floorMesh.add_to_group(sectorNode.name)
		sectorNode.add_child(floorMesh)
		
		
		var type = currentSector["type"]
		
		if type != 0:
			var lightLevel = currentSector["lightLevel"]
			var script = load("res://addons/godotWad/src/sectorType.gd")
			var node = Node.new()
			
			
			node.name = "sectorType-" + sectorNode.name
			node.set_script(script)
			
			
			var lePath = "../../Geometry/" + sectorNode.name + "/" + floorMesh.name
			
			node.darkValue = currentSector["darkestNeighValue"]
			node.brightValue = currentSector["lightLevel"]
			node.meshPath = lePath
			node.type = type
			
		
			
			specialNode.add_child(node)

			floorMesh.set_meta("special",node)
	
	
	if true:

		if get_parent().skyCeil == get_parent().SKYVIS.DISABLED:
			if currentSector["ceilingTexture"] == "F_SKY1":
				return
				
		var ret = createFloorMesh(finalArr,ceilHeight,-1,dim,mini,currentSector["ceilingTexture"],ceilTexture,currentSector)
		
		var ceilMesh = ret["mesh"]
		var center = ret["center"]
		var a = OS.get_system_time_msecs()
		ceilMesh.create_trimesh_collision()
		colArr.append(OS.get_system_time_msecs()-a)
		
		
		if currentSector["ceilingTexture"] == "F_SKY1":
			ceilMesh.get_child(0).collision_layer = 0
		
		#ceilMesh.create_convex_collision()
		#ceilMesh.create_multiple_convex_collisions()
		if ceilMesh.has_node("_col"):
			ceilMesh.get_node("_col").set_meta("ceil","true")
		ceilMesh.set_meta("ceil","true")
		ceilMesh.name = "ceiling " + currentSector["floorTexture"]
		
		if currentSector["ceilingTexture"] == "F_SKY1":
			ceilHeight = currentSector["highestNeighCeilInc"]-1
		
		ceilMesh.translation = (center + Vector3(0,ceilHeight,0))
		
		sectorNode.add_child(ceilMesh)
		
	
	
	
	
func createFloorMesh(arr,height,dir,dim,mini,textureName,texture = null,sector=null,toAllMesh = false):
	var surf = SurfaceTool.new()
	var surfAbs = SurfaceTool.new()
	var tmpMesh = Mesh.new()
	
	#var mat = null
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
		mat = $"../ResourceManager".fetchSkyMat()

	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surfAbs.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_material(mat)

	if dir == -1:
		arr.invert()
	var count = 0
	
	
	
	#a = OS.get_system_time_msecs()
	for v in arr:
		surf.add_normal(Vector3(0,dir,0))
		if texture != null:
			if texture.get_width() != 0 and texture.get_height()!=0:

				var uvX = (v.x)/texture.get_width()
				var uvY = (v.z)/texture.get_height()
			
				surf.add_uv(Vector2(uvX,uvY))
		surf.add_vertex((v-center))
		var scale = get_parent().scale
		scale = 1
		surfAbs.add_vertex(((v+Vector3(0,height,0))*scale))
	
	
	#print("time creating verts and uvs:",OS.get_system_time_msecs()-a)
	
	#a = OS.get_system_time_msecs()

	surf.commit(tmpMesh)
	tmpMesh.surface_set_name(tmpMesh.get_surface_count()-1,textureName)
	
	if toAllMesh:
		surfAbs.commit(allFloorMesh)
	
	if get_parent().unwrapLightmap:
		var a = OS.get_system_time_msecs()
		tmpMesh.lightmap_unwrap(Transform.IDENTITY,1)
		luArr.append(OS.get_system_time_msecs()-a)
	#print("lightmap_unwrap:",OS.get_system_time_msecs()-a)
	
	#a = OS.get_system_time_msecs()
	var meshNode = MeshInstance.new()
	meshNode.mesh = tmpMesh
	#print("mesh instantiation and assignment:",OS.get_system_time_msecs()-a)
	
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



func createSectorClosedLoop(sectorLines):#gets all closed loops in sector
	var soup = sectorLines.duplicate(true)
	var loops = []
	var curloop = []
	var badVerts = []
	var first = [INF,INF]
	for line in sectorLines: #we start with the line that hasw the smallest vert index
		if line[0] < first[0]:
			first = line
			

	commitToLoop(first,curloop,soup)
	var i = -1
	var fetch = true
	while(true):
	
		if curloop.back()[1] == curloop.front()[0]:# and loop.size() > 1:#we closed a loop
			loops.append(curloop)
			curloop = []
			i = -1
			fetch = commitToLoop(soup[i],curloop,soup)
					
		
		elif curloop.back()[1] == soup[i][0] :#connection found
			fetch = commitToLoop(soup[i],curloop,soup)
			i=-1
			

		elif i+1==soup.size():#we have reached the end without closing the loop
			badVerts = badVerts + curloop
			curloop = []
			fetch = commitToLoop(soup[0],curloop,soup)

			i = -1
			#commitToLoop(soup[0],curloop,soup)
		
		if fetch == false:#we ran out of lines to process
			if curloop.back()[1] == curloop.front()[0]:
				loops.append(curloop)
				curloop = []
			
			if !curloop.empty():
				badVerts = badVerts + curloop
			
			if badVerts.size()>0:
				return(["fail",loops,badVerts])
				
			if badVerts.size()==0:
				if loops.empty():
					breakpoint
				return(loops)
		
		i+=1
		
func createSectorClosedLoop2(sec):
	var soup = sec.duplicate(true)
	var loops = []
	var curloop = []
	var badVerts = []
	var first = [INF,INF]
	var fetch = true
	for line in sec:
		if line[0] < first[0]:#get the smallest vertex indice
			first = line
			

	commitToLoop(first,curloop,soup)
	var i = 0
	while(true):
		var check = soup[i]
		if curloop.back()[1] == check[0]:
			fetch = commitToLoop(soup[i],curloop,soup)
			i=0
		
		if curloop.front()[0] == soup.back()[1] and curloop.size() > 2:
			loops.append(curloop)
			curloop = []
			i = 0
			fetch = commitToLoop(soup[i],curloop,soup)
		
		if i+1 == soup.size():
			badVerts = badVerts + curloop
			curloop = []
			fetch = commitToLoop(soup[0],curloop,soup)
			i=0
		
		if fetch == false:#soup.size() == 0
			if badVerts.size()>0:
				return(["fail",loops,badVerts])
				
			else:
				if loops.empty():
					breakpoint
				return(loops)
			
		
		i+=1
	

func createSectorClosedLoop3(sectorLines):
	var lines = sectorLines.duplicate(true)
	var allLoops = []
	while(lines.size()>0):# as long as we have a vertex
		var runningLoop = [lines[0]]#the start of loop is set
		var foundNext = true
		lines.erase(lines[0])
		
		while foundNext:
			foundNext = addNextToLoop(runningLoop[runningLoop.size()-1],lines,runningLoop)
		
		if runningLoop.size() > 2:
			allLoops.append(runningLoop)
		
	#print("----")
	
	#for l in allLoops:
	#	print(l)
	
	return allLoops
		
		


func addNextToLoop(cur,lines,runningLoop):
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
	sectorLines.resize(sectors.size())
	for line in lines:
		
		
		
		var frontSideIndex = line["frontSideDef"]
		var backSideIndex = line["backSideDef"]
		
		
		if frontSideIndex != -1 and backSideIndex != -1:
			
			var frontSide = sides[frontSideIndex]
			var fsectorId = frontSide["frontSector"]
			
			var backSide = sides[frontSideIndex]
			var bsectorId = backSide["frontSector"]
			

		
			
			
			
		
		if frontSideIndex != -1 : 
			var frontSide = sides[frontSideIndex]
			var sectorId = frontSide["sector"]
		
			if typeof(sectorLines[sectorId]) != TYPE_ARRAY: sectorLines[sectorId] = []
			sectorLines[sectorId].append([line["startVert"],line["endVert"]])
	
		if backSideIndex != -1 : 
			var backSide = sides[backSideIndex]
			var sectorId = backSide["sector"]
			if typeof(sectorLines[sectorId]) != TYPE_ARRAY: sectorLines[sectorId] = []
			sectorLines[sectorId].append([line["endVert"],line["startVert"]])
			
		linNum += 1
	return sectorLines

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

func getClosetXpoint(point,poly):
	var maxX = getMaxX(poly)
	var closestDist = INF
	var ret = null
	for i in poly.size():
		var line1 = [poly[i],poly[(i+1)%poly.size()]] 
		var line2 = [point,Vector2(maxX.x+10,point.y)]
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

func createDbgPoly(arr,dbgName,texture=null):
	var debugImage = Polygon2D.new()
	debugImage.polygon = arr
	debugImage.scale *= 0.1
	debugImage.texture = texture
	if dbgName!= null:
		debugImage.name = "Sector %s " % dbgName


	debugImage.set_owner(self)
	var pack = PackedScene.new()
	pack.pack(debugImage)
	ResourceSaver.save("res://dbg/"+dbgName+".tscn",pack)


func saveFloorPlan():
	
	get_parent().add_child(floorPlan)
	var pack = PackedScene.new()
	pack.pack(floorPlan)
	ResourceSaver.save("res://dbg/"+"floorPlan"+".tscn",pack)

func addPolyToFloorPlan(arr,sectorNode,texture=null):
	

	var centerArr = arr.duplicate()
	var center = Vector2.ZERO
	
	for v in arr:
		center += v
		
	center /= arr.size()
	
	for i in centerArr.size():
		centerArr[i] -= center
		
		
	
	var poly = Polygon2D.new()
	poly.name = "Polygon2D"
	poly.polygon = centerArr
	poly.texture = texture

	
	poly.position = center
	var area = Area2D.new()
	area.name = "Area2D"
	
	var colPoly = CollisionPolygon2D.new()
	
	#var polyShape = makePolyShape(centerArr)
	#area.add_child(polyShape)
	
	
	colPoly.name = "CollisionPolygon2D"
	colPoly.polygon = centerArr
	area.add_child(colPoly)
	poly.add_child(area)
	colPoly.scale = Vector2.ONE * 1.0001
	#sectorNode.add_child(colPoly)
	sectorNode.add_child(poly)
	#colPoly.set_owner(floorPlan)
	area.set_owner(floorPlan)
	colPoly.set_owner(floorPlan)
	poly.set_owner(floorPlan)
	#polyShape.set_owner(floorPlan)
	

func makePolyShape(pointsAsVerts):
	var vector2pool = PoolVector2Array(pointsAsVerts)
	#var polyShape = ConvexPolygonShape2D.new()
	#polyShape.points = vector2pool
	
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



		

func createPoly2D(arr,polyName,texture=null):
	var poly = Polygon2D.new()
	poly.polygon = arr
	poly.name = polyName
	poly.texture = texture
	return poly

func savePoly(node):
	var packedScene = PackedScene.new()
	packedScene.pack(node)
	ResourceSaver.save("res://dbg/"+node.name+".tscn",packedScene)
	
func vertArrToPolyShape(pointsAsVerts):
	var vector2pool = PoolVector2Array(pointsAsVerts)
	var polyShape = ConcavePolygonShape2D.new()
	
	polyShape.segments = vector2pool
	return polyShape
	
	
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
