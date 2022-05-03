tool
extends Node


var primitiveType = Mesh.PRIMITIVE_TRIANGLES

func _ready():
	set_meta("hidden",true)


enum TEXTUREDRAW{
	BOTTOMTOP,
	TOPBOTTOM,
	GRID,
}


	
func seperateByTexture(arr):
	var groups = {}
	var ret = []
	for i in arr:
		var texture = i["textureName"]
		if !groups.has(texture): groups[texture] = []
		groups[texture].append(i)
	
	return groups
	

	

func merge(arr,geomNode):
	for sector in arr.keys():#we have array of walls grouped by sector. for every sector:
		mergeSector(arr[sector],sector,geomNode)#merge all of sector
	

func mergeSector(arr,sectorIdx,geomNode):
	var textureGroup
	var textureGroupSolid
	var textureGroupShootThrough
	if typeof(arr) != TYPE_DICTIONARY:
		textureGroup = seperateByTexture(arr)#we create of dict of each unique texture along with their corresponding walls
		
	else:
		textureGroup = arr
		
	if textureGroup.keys().size() > get_parent().maxMaterialPerMesh:#if we have more than 4 textures in a group
		var dictA = {}
		var dictB = {}
		var textureNames = textureGroup.keys()
		
		
		for i in textureNames.size():#we split it in two to reduce the number
			if i%2 == 0: dictA[textureNames[i]] = textureGroup[textureNames[i]]
			if i%2 != 0: dictB[textureNames[i]] = textureGroup[textureNames[i]]
			
		
		mergeSector(dictA,sectorIdx,geomNode)
		mergeSector(dictB,sectorIdx,geomNode)
		return
		
	#we can only have one light level per sector
	var surf = SurfaceTool.new()
	var runningMesh = ArrayMesh.new()#this is the final mesh which will have sub surf for each material
	var runningSolid  = ArrayMesh.new()
	var runningShootThrough = ArrayMesh.new()
	var sectors = $"../LevelBuilder".sectors
	var sectorNode = null
	surf.begin(primitiveType)
	
	var meshInstance = MeshInstance.new()
	meshInstance.name = "merged sector " + String(sectorIdx)
	meshInstance.set_meta("sectorIdx",sectorIdx)
	var t = sectors[sectorIdx]
	sectorNode = textureGroupIntoMesh(textureGroup,runningMesh,sectors,sectorIdx,runningSolid,runningShootThrough)
	
	#var meshInstancePath = get_parent().get_path() + "/merged sector " + String(sectorIdx)
	
	if get_parent().mergeMesh == get_parent().MERGE.WALLS_AND_FLOOR:
		addFloorAndCeilingToMesh(runningMesh,sectorNode,sectorIdx,false,true,meshInstance)
		addFloorAndCeilingToMesh(runningSolid,sectorNode,sectorIdx,true,false)

	#var solidMeshInstance = MeshInstance.new()
#	solidMeshInstance.mesh = runningSolid
	
	var solidBody = dumbFunc(runningSolid)
	if solidBody == null:
		return
	solidBody.name = "solidCol"
	
	var shootTroughBody = null

	

	if runningShootThrough.get_surface_count() > 0:
		shootTroughBody= dumbFunc(runningShootThrough)
	
	
	if shootTroughBody != null:
		shootTroughBody.name = "shootThroughCol"
		shootTroughBody.collision_layer = 0
	
	
	
	
	meshInstance.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	meshInstance.use_in_baked_light = true
	meshInstance.mesh = runningMesh
	
	meshInstance.set_meta("merged",true)
	
	geomNode.add_child(meshInstance)
	meshInstance.add_child(solidBody)
	if shootTroughBody != null:
		meshInstance.add_child(shootTroughBody)
	
	#meshInstance.create_trimesh_collision()
	

func textureGroupIntoMesh(textureGroup,runningMesh,sectors,sectorIdx,runningSolid,runningShootThrough):
	var sectorNode
	for textureName in textureGroup.keys():
		
		var localSurf = SurfaceTool.new()
		var localSolid = SurfaceTool.new()
		var localShootThrough = SurfaceTool.new()
		
		localSurf.begin(Mesh.PRIMITIVE_TRIANGLES)
		localSolid.begin(Mesh.PRIMITIVE_TRIANGLES)
		localShootThrough.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var meshCenter = Vector3.ZERO
		var mat
		for mesh in textureGroup[textureName]:
			 meshCenter += getMeshCenter(mesh)
			
		meshCenter /=  textureGroup[textureName].size()
		
		var text

		if textureName!=null:
			if textureName != "F_SKY1":
				text = textureGroup[textureName][0]["texture"]
				mat = $"../ResourceManager".fetchMaterial(textureName,text,sectors[sectorIdx]["lightLevel"],0,1,0,true)
			else:
				mat = $"../ResourceManager".createSkyMat(true)

		
		localSurf.set_material(mat)
		for meshInfo in textureGroup[textureName]:#we keep appending to localSurf
			createMesh(localSurf,meshInfo,meshCenter,mat,text)
			
			if meshInfo["colMask"] == 1:
				createMesh(localSolid,meshInfo,meshCenter,mat,text)
				
			if meshInfo["colMask"] == 0:
				createMesh(localShootThrough,meshInfo,meshCenter,mat,text)
				
			sectorNode = meshInfo["sectorNode"]
		
		localSolid.commit(runningSolid)
		localShootThrough.commit(runningShootThrough)
		localSurf.commit(runningMesh)#then append localSurf to
		
		runningMesh.surface_set_name(runningMesh.get_surface_count()-1,textureName)
		
	return sectorNode


	
func createMesh(localSurf,meshInfo,origin,mat,texture):
	var start = meshInfo["start"]
	var end = meshInfo["end"]
	var floorZ = meshInfo["floorZ"]
	var ceilZ = meshInfo["ceilZ"]
	var fCeil = meshInfo["fCeil"]
	var uvType = meshInfo["uvType"]
	var textureOffset = meshInfo["textureOffset"]
	var sideIndex = meshInfo["sideIndex"]

	var textureName = meshInfo["textureName"]

	var sector = meshInfo["sector"]

	makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector,textureName,localSurf,origin,mat)
	



func makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector,textureName,localSurf,origin,mat):

	
	var height = ceilZ-floorZ 
	var startUVy = 0
	var startUVx = 0
	var endUVy= 0
	var endUVx = 0
	
	
	if texture != null:
		var textureDim = texture.get_size()
		endUVx = ((start-end).length()/textureDim.x)
		if uvType == TEXTUREDRAW.TOPBOTTOM:
			endUVy = height
			startUVy/=textureDim.y
			endUVy/=textureDim.y
		
		elif uvType == TEXTUREDRAW.BOTTOMTOP:
			startUVy = floorZ-ceilZ
			endUVy = 0
			startUVy/=textureDim.y
			endUVy/=textureDim.y
			
		elif uvType == TEXTUREDRAW.GRID:
			startUVy = (fCeil - ceilZ)/textureDim.y
			endUVy = startUVy+(ceilZ-floorZ)/textureDim.y
	
	 
		startUVy += textureOffset.y / texture.get_height() 
		endUVy += textureOffset.y / texture.get_height() 
	
		startUVx += textureOffset.x / texture.get_width() 
		endUVx += textureOffset.x / texture.get_width() 
	
	var TL = Vector3(start.x,ceilZ,start.y)# - origin
	var BL = Vector3(start.x,floorZ,start.y)# -origin
	var TR = Vector3(end.x,ceilZ,end.y)# - origin
	var BR = Vector3(end.x,floorZ,end.y)# - origin
	
	var line1 = TL - TR
	var line2 = TL - BL
	var normal = -line1.cross(line2).normalized()

	#var subSurf = SurfaceTool.new()
	#subSurf.set_material(mat)

	localSurf.add_normal(normal)
	localSurf.add_uv(Vector2(startUVx,startUVy))
	localSurf.add_vertex(TL)
	
	localSurf.add_normal(normal)
	localSurf.add_uv((Vector2(endUVx,startUVy)))
	localSurf.add_vertex(TR)
	
	localSurf.add_normal(normal)
	localSurf.add_uv(Vector2(endUVx,endUVy))
	localSurf.add_vertex(BR)
	
	
	localSurf.add_normal(normal)
	localSurf.add_uv(Vector2(startUVx,startUVy))
	localSurf.add_vertex(TL)
	
	localSurf.add_normal(normal)
	localSurf.add_uv(Vector2(endUVx,endUVy))
	localSurf.add_vertex(BR)
	
	localSurf.add_normal(normal)
	localSurf.add_uv(Vector2(startUVx,endUVy))
	localSurf.add_vertex(BL)
	
	
	#subSurf.commit(runningMesh)
	
	
func getMeshCenter(meshDict):
	var start = meshDict["start"]
	var origin = Vector3(start.x,meshDict["ceilZ"],start.y)
	return origin
	
func getFloorAndCeilingMesh(sectorNode):
	var floorNode
	var ceilingNode
	
	for i in sectorNode.get_children():
		if i.has_meta("ceil"): 
			ceilingNode = i
		if i.has_meta("floor"):
			floorNode = i
	
	if floorNode == null: return null
	if ceilingNode == null : return null
	
	
	
	var ceilingMat = ceilingNode.mesh.surface_get_material(0)
	var floorMat = floorNode.mesh.surface_get_material(0)
	
	return {
		"ceilingNode":ceilingNode,"ceilingMesh":ceilingNode.mesh,"ceilingTransform":ceilingNode.transform,"ceilingMat":ceilingMat,
		"floorNode":floorNode,"floorMesh":floorNode.mesh,"floorTransform":floorNode.transform,"floorMat":floorMat
		}
	
	
func addFloorAndCeilingToMesh(mesh,sectorNode,sectorIdx,delete = false,childrenDupe = false,meshInstance=null):
	
	var mapDict = $"../LevelBuilder".mapDict
	
	
	
	var ret = getFloorAndCeilingMesh(sectorNode)
	if ret == null:
		return
	
	
	var ceilingMesh = ret["ceilingMesh"]
	var floorMesh = ret["floorMesh"]
	var surf = SurfaceTool.new()
	
	surf.set_material(ret["ceilingMat"])
	surf.append_from(ceilingMesh,0,ret["ceilingTransform"])
	
	if delete:
		ret["ceilingNode"].get_parent().remove_child(ret["ceilingNode"])
		ret["ceilingNode"].queue_free()
	
	surf.commit(mesh)
	surf = SurfaceTool.new()
	
	for baseSector in mapDict["stairLookup"].keys():
		if mapDict["stairLookup"][baseSector].has(sectorIdx):
			return
			
			
	surf.set_material(ret["floorMat"])
	var surfname = floorMesh.surface_get_name(0)
	surf.append_from(floorMesh,0,ret["floorTransform"])
	
	surf.commit(mesh)
	mesh.surface_set_name(mesh.get_surface_count()-1,surfname)
	
	if childrenDupe:
		if ret["floorNode"].has_meta("special"):
			var specialNode = ret["floorNode"].get_meta("special")
			
			specialNode.meshPath = "../../Geometry/" + meshInstance.name

	
	if delete:
		ret["floorNode"].get_parent().remove_child(ret["floorNode"])
		ret["floorNode"].queue_free()
		


func dumbFunc(mesh):
	var meshInstance = MeshInstance.new()
	meshInstance.mesh = mesh
	meshInstance.create_trimesh_collision()
	
	if meshInstance.get_child_count() != 0:
		var a = meshInstance.get_child(0)
		if a == null:
			return
		var t =a.duplicate()
		return t
		
	return null
	
