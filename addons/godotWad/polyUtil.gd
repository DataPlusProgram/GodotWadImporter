class_name polyUtil
extends Control




static func rev(a,b,debug=false):
	#if debug:
	#	if b[0].y != 44:
	#		breakpoint
		

	
	var ai = Geometry2D.is_polygon_clockwise(a)
	var bi = Geometry2D.is_polygon_clockwise(b)
	
	
	if Geometry2D.is_polygon_clockwise(a): a.invert()
	if !Geometry2D.is_polygon_clockwise(b): b.invert()
	
	
	a = polyWithoutDuplicateVerts2(a)
	a = removeColinear(a)
	b = polyWithoutDuplicateVerts2(b)
	b = removeColinear(b)
	
	
	#if debug:
	#	print(a)
	
	var aX
	var bX = getFurthestPointIdxOnPoly(b,false)
	
	
	var aVert = findNewVertTrace(a,b[bX])["vert"]

	var result = addVertToPoly(a,aVert,null)
	
	a = result.poly
	aX = result.index
	
	
	var bVert = b[bX]
	var aSplit = splitAtPoint(a,result["index"],1,debug)
	var bSplit = splitAtPoint(b,bX,1,debug)
	
	var aResult
	var bResult 
	
	#if doesSegOverlapPoly(aSplit[0],bSplit[0],b):#if going upwards causes intersection we pick the two downards verts
	#	aResult = addVertToPoly(a,aSplit[1],aX)
	#	bResult = addVertToPoly(b,bSplit[1],bX)
	
	#else :
	#	aResult = addVertToPoly(a,aSplit[0],aX)
	#	bResult = addVertToPoly(b,bSplit[0],bX)
	
	#if debug:
	#	breakpoint
	

	if debug:
		var n = Node2D.new()
		n.name = "flee"
		
		n.add_child(makeCircleNode(aVert,0.05,Color.WHITE))
		n.add_child(makeCircleNode(aSplit[0],0.05,Color.RED))
		n.add_child(makeCircleNode(aSplit[1],0.05,Color.BLACK))
		
		#if !doesSegOverlapPoly(aSplit[0],bSplit[0],b):
		#	n.add_child(makeLineNode(aSplit[0],bSplit[0],"0,0"))
		#else:
		#	n.add_child(makeLineNode(aSplit[0],bSplit[0],"0,0",Color.red))
		
	#	if !doesSegOverlapPoly(aSplit[1],bSplit[1],b):
	#		n.add_child(makeLineNode(aSplit[1],bSplit[1],"1,1"))
	#	else:
	#		n.add_child(makeLineNode(aSplit[1],bSplit[1],"1,1",Color.red))
			
		
	#	if !doesSegOverlapPoly(aSplit[1],bSplit[0],b):
	#		n.add_child(makeLineNode(aSplit[1],bSplit[0],"1,2"))
	#	else:
	#		n.add_child(makeLineNode(aSplit[1],bSplit[0],"1,2",Color.red))
		
		#n.add_child(makeLineNode(aSplit[1],bSplit[1],"l2"))
		
		
		
		n.add_child(createPolyFromVerts(b,"b"))
		n.add_child(createPolyFromVerts(a,"a"))
		WADG.saveNodeAsScene(n)
	
	
	#if !doesSegOverlapPoly(aSplit[0],bSplit[0],b):#if going upwards causes intersection we pick the two downards verts
	aResult = addVertToPoly(a,aSplit[0],aX)
	bResult = addVertToPoly(b,bSplit[0],bX)
	
	#elif !doesSegOverlapPoly(aSplit[1],bSplit[1],b):
	#	aResult = addVertToPoly(a,aSplit[1],aX)
	#	bResult = addVertToPoly(b,bSplit[1],bX)
	
	#elif !doesSegOverlapPoly(aSplit[1],bSplit[0],b):
	#	aResult = addVertToPoly(a,aSplit[1],aX)
	#	bResult = addVertToPoly(b,bSplit[0],bX)
		
#	else:
#		aResult = addVertToPoly(a,aSplit[0],aX)
#		bResult = addVertToPoly(b,bSplit[1],bX)
	
	a = aResult.poly
	b = bResult.poly
	
	
	
	#saveVertArrAsScene(a,"a")
	aX = aResult["trackedIndex"]#a.find(aVert)
	bX = bResult["trackedIndex"]#b.find(bVert)
	
	
	var deletedVertA 
	var deletedVertB = b[bX]
	
	
	#saveVertArrAsScene(a,"a")
	#saveVertArrAsScene(b,"b")
	
	
	var a1 = aResult["index"]
	var b1= bResult["index"]
	var b2 = bX
	var a2 = aX
	

	
	#var fillerPoly1 = Polygon2D.new()
	var fillerPoly1 = [b[b1],a[a2],a[a1]]
	var fillerPoly2 = [a[a2],b[b2],b[b1]]
	
	if !Geometry2D.is_polygon_clockwise(fillerPoly1): fillerPoly1.invert()
	if !Geometry2D.is_polygon_clockwise(fillerPoly2): fillerPoly2.invert()
	#fillerPoly1.polygon = [b[b1],a[a2],a[a1]]
	#if debug:
	#	print(a1,",",b1,",",b2,",",a1)
	var canalPolyVerts = canalTwoPolys(a,b,a1,b1,b2,a2)

	var canalPoly = Polygon2D.new()
	
	canalPoly.name = "done"
	
	
	
	return [canalPolyVerts ,fillerPoly1 , fillerPoly2]
	

	
static func getFurthestPointIdxOnPoly(poly,debug=false,axis = Vector2.RIGHT):
	
	var furthestPointIdx = 0
	var furthestDist = -INF
	
	for v in poly.size():
		
		if poly[v].dot(axis) > furthestDist:
			furthestPointIdx = v
			furthestDist = poly[v].dot(axis)
			
	
	
	return furthestPointIdx
	

	
static func findNewVertTrace(poly,point,dir = Vector2.RIGHT):
	
	var closest = point
	var closestDist = INF
	
	var segA = point
	var segB = point + (dir*2000)
	var preIndex = -1
	
	for i in poly.size():
		var a = poly[i]
		var b = poly[(i+1)%poly.size()]
		
		
		var contact = Geometry2D.segment_intersects_segment(a,b,segA,segB)
		
		if contact == null:
			contact = Geometry2D.segment_intersects_segment(segA,segB,a,b)
			
		
		if contact != null:
			#lines.append([a,b,Color.gold])
			if point.distance_squared_to(contact) < closestDist:
				closest = contact
				closestDist = point.distance_squared_to(contact)
				preIndex = i

				
				
	return {"vert":closest,"preIndex":preIndex}


func getPointOnPolyClosestToPoint(poly,point):
	var closestPoint = Vector2.ZERO
	var closestDist = INF
	
	for segIdx in poly.size():
		var a = poly[segIdx]
		var b = poly[abs((segIdx+1)%poly.size())]
		
		var p = Geometry2D.get_closest_point_to_segment(point,a,b)
		var dist = p.distance_squared_to(point)
		
		if dist < closestDist:
			closestDist = dist
			closestPoint = p
			
		
	return closestPoint



static func splitAtPoint(poly,idx,dir = 1,dbg=false):
	
	var vert = poly[idx]
	var pIdx = indexCircular(poly,idx-1)
	var nIdx = indexCircular(poly,idx+1)
	
	var vertP = poly[pIdx]
	var vertN = poly[nIdx]
	var pullBack = 0.2
	var newV
	
	var dP =vertP - vert
	var dN =vertN - vert
	

	var xDffP = vertP.y
	var xDffN = vertN.y
	

	
	var dpScaled = (vert) + dP.normalized() * pullBack
	var dNScaled = (vert) + dN.normalized() * pullBack
	
	

	if dP.y > dN.y:
	#if abs(dP.y) < abs(dN.y):
	#if abs(dpScaled.y) < abs(dNScaled.y):
		return [dpScaled,dNScaled]
		

		
	return [dNScaled,dpScaled]


static func createPolyFromVerts(verts,ployName,col = Color(1,1,1,0.2)):
	var poly =  Polygon2D.new()
	poly.name = ployName
	poly.polygon = verts
	poly.color = col
	return poly

static func saveVertArrAsScene(arr,sceneName = "poly",path = "res://dbg/"):
	var poly =  Polygon2D.new()
	poly.name = sceneName
	poly.polygon = arr.duplicate(true)
	WADG.saveNodeAsScene(poly,path)



static func canalTwoPolys(polyA,polyB,leaveA,enterB,leaveB,enterA,bIsHole=true):


	

	var shapeHalf1: PackedVector2Array = []
	var shapeHalf2: PackedVector2Array = []
	
	var newPolyA  = []
	
	var inc = -1
	if enterA > leaveA: inc = 1
	for i in polyA.size():
		var idx = indexCircular(polyA,enterA+inc*i)
		newPolyA.append(polyA[idx])
	


	var newPolyB = []
	#print("---")
	inc = -1
	
	
	if enterB > leaveB and (enterB+1)%polyB.size() != 0: inc = 1

	for i in polyB.size():
		var idx = indexCircular(polyB,enterB+inc*i)
		
		newPolyB.append(polyB[idx])


	
	return newPolyA + newPolyB


static func indexCircular(arr,index):
	return (index + arr.size() + arr.size()) % arr.size()
		
		
static func addVertToPoly(poly,point,trackedPoint = null):

	var minDist = INF
	var closestPoint = Vector2.ZERO
	var closestSeg = [0,1]
	
	if poly.has(point):
		return {"poly":poly,"index":poly.find(point),"vert":point,"trackedIndex":poly.find(point)}
	
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

	if trackedPoint != null:
		if trackedPoint >= closestSeg[1]:
			trackedPoint = trackedPoint+1
	
	poly.insert(closestSeg[1],closestPoint)
	return {"poly":poly,"index":closestSeg[1],"vert":point,"trackedIndex":trackedPoint}


static func polyWithoutDuplicateVerts(poly):
	var polyNoDupe = []
	for i in poly:
		if !polyNoDupe.has(i):
			polyNoDupe.append(i)
			
	return polyNoDupe

static func polyWithoutDuplicateVerts2(poly):
	var polyNoDupe = []
	for i in poly.size():
		var t = poly[i]
		var t2 = poly[(i+1)%poly.size()]
		if !t.is_equal_approx(t2):
			polyNoDupe.append(poly[i])
			
	return polyNoDupe


static func polyWithoutApproxDuplicateVerts(poly):
	var polyNoDupe = []
	for i in poly:
		var has = false
		
		for j in polyNoDupe:
			if i.is_equal_approx(j):
				has = true
				break
		
		if has == false:
			polyNoDupe.append(i)
			
			
	return polyNoDupe

static func removeColinear(poly):
	
	var retArr = []
	
	for i in poly.size():
		
		var vert = poly[i]
		var pVert = poly[indexCircular(poly,i-1)]
		var nVert = poly[indexCircular(poly,i+1)]
		
		var pDelta = (vert-pVert).normalized()
		var nDelta = (nVert-vert).normalized()
		
		
		if pDelta == nDelta:
			continue
		
		retArr.append(poly[i])
		
	return retArr

static func doesSegOverlapPoly(segA,segB,poly):
	

	for i in poly.size():
		var polySegA = poly[i]
		var polySegB = poly[(i+1)%poly.size()]
		
		#polySegA = polySegA+(polySegB-polySegA)*0.1
		#polySegB = polySegA+(polySegB-polySegA)*0.9
		
		var contact = Geometry2D.segment_intersects_segment(segA,segB,polySegA,polySegB)
		if contact != null:
			return true
			
		if contact == null:
			contact = Geometry2D.segment_intersects_segment(polySegA,polySegB,segA,segB)
			if contact != null:
				return true
		
	return false


static func makeLineNode(a,b,lineName,col = Color.BLUE):
	
	var line = Line2D.new()
	line.name = lineName
	line.width= 0.02
	line.default_color = col
	line.points = PackedVector2Array([a,b])
	
	return line


static func saveLine(a,b,lineName):
	WADG.saveNodeAsScene(makeLineNode(a,b,lineName))


static func makeCircleNode(pos,radius = 1,color = Color.BLACK):
	var verts = []
	var i = 0
	while i < 360:
		verts.append(Vector2(radius*sin(deg_to_rad(i)),radius*cos(deg_to_rad(i)))+pos) 
		i += 20
	
	var poly = Polygon2D.new()
	poly.color = color
	poly.polygon = verts
	return poly

