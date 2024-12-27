@tool
extends Node


var primitiveType = Mesh.PRIMITIVE_TRIANGLES

var meshScale = Vector3.ONE

@onready var levelBuilder : Node =  $"../LevelBuilder"
@onready var resourceManager : Node = $"../ResourceManager"
@onready var materialManager : Node = $"../MaterialManager"
func _ready():
	set_meta("hidden",true)


enum TEXTUREDRAW{
	BOTTOMTOP,
	TOPBOTTOM,
	GRID,
}

var allStairSector : Array
var dynamicFloors : Array 
func seperateByTexture(arr : Array) -> Dictionary:
	var groups : Dictionary = {}
	var ret : Array = []
	for i in arr:
		var texture = i["textureName"] +","+str(i["alpha"])+","+str(i["scroll"])
		if !groups.has(texture): groups[texture] = []
		groups[texture].append(i)
	
	return groups
	

	

func merge(preInstancedMeshes : Dictionary,geomNode : Node,mapName : String,hasCollision : bool):
	
	allStairSector = getStairDict($"../LevelBuilder".mapDict["stairLookup"])
	dynamicFloors = $"../LevelBuilder".mapDict["dynamicFloors"]
	for sector : int in preInstancedMeshes.keys():#we have array of walls grouped by sector. for every sector:
		mergeSector(preInstancedMeshes[sector],sector,geomNode,mapName)#merge all of sector

func mergeSector(arr,sectorIdx:int,geomNode:Node,mapName:String) -> void:
	
	var textureGroup
	var ceilFloorFlag = false
	
	if typeof(arr) != TYPE_DICTIONARY:
		textureGroup = seperateByTexture(arr)#we create of dict of each unique texture along with their corresponding walls
	else:
		textureGroup = arr
		
	if textureGroup.keys().size() > get_parent().maxMaterialPerMesh:#if we have more than 4 textures in a group
		var dictA : Dictionary = {}
		var dictB : Dictionary= {}
		var textureNames = textureGroup.keys()
		
		
		for i in textureNames.size():#we split it in two to reduce the number
			if i%2 == 0: dictA[textureNames[i]] = textureGroup[textureNames[i]]
			if i%2 != 0: dictB[textureNames[i]] = textureGroup[textureNames[i]]
			
		
		mergeSector(dictA,sectorIdx,geomNode,mapName)
		mergeSector(dictB,sectorIdx,geomNode,mapName)
		return
		
	#we can only have one light level per sector
	var runningMesh : ArrayMesh= ArrayMesh.new()#this is the final mesh which will have sub surf for each material
	var runningSolid : ArrayMesh= ArrayMesh.new()
	var runningShootThrough: ArrayMesh= ArrayMesh.new()

	var sectors = levelBuilder.sectors
	var sectorNode : Node3D = null

	
	var meshInstance = MeshInstance3D.new()
	meshInstance.set_meta("sectorIdx",sectorIdx)
	


	sectorNode = textureGroupIntoMesh(textureGroup,runningMesh,sectors[sectorIdx],runningSolid,runningShootThrough,mapName)
	
	
	
	var keepWallsConvex = get_parent().KEEP_WALLS_CONVEX
	
	if (get_parent().mergeMesh == get_parent().MERGE.WALLS_AND_FLOOR or get_parent().mergeMesh == get_parent().MERGE.WALLS_AND_FLOOR_2)   and sectorNode !=  null and !allStairSector.has(sectorIdx):
		
			addFloorAndCeilingToMesh(runningMesh,runningMesh,sectorNode,sectorIdx,false,true,meshInstance)
			var floorRunning = runningSolid
			var ceilRunning = runningSolid
			var t = sectors[sectorIdx]
			
			if t["ceilingTexture"] == &"F_SKY1":
				floorRunning = runningShootThrough
			
			if get_parent().mergeMesh == get_parent().MERGE.WALLS_AND_FLOOR :
				addFloorAndCeilingToMesh(runningSolid,runningSolid,sectorNode,sectorIdx,true,false)
			
			if get_parent().mergeMesh == get_parent().MERGE.WALLS_AND_FLOOR_2 and !dynamicFloors.has(sectorIdx):
				var ret = getFloorAndCeilingMesh(sectorNode)
				if ret != null:

					var ceilingMesh = ret["ceilingNode"]
					var floorMesh = ret["floorNode"]
				
				
				
				
					
					if floorMesh.get_child_count() > 0:
						var floorCol = floorMesh.get_child(0)
						if floorCol != null:
							
							floorMesh.remove_child(floorCol)
							floorMesh.get_parent().add_child(floorCol)
							floorCol.position = floorMesh.position
							floorMesh.get_parent().remove_child(floorMesh)
							floorMesh.queue_free()
					
				
					
					if ceilingMesh.get_child_count() > 0:
						var ceilCol = ceilingMesh.get_child(0)
						
						if ceilCol != null:
							ceilingMesh.remove_child(ceilCol)
							ceilingMesh.get_parent().add_child(ceilCol)
							ceilCol.position = ceilingMesh.position
							ceilingMesh.get_parent().remove_child(ceilingMesh)
							ceilingMesh.queue_free()
							

	
	if !keepWallsConvex:
		var solidBody : StaticBody3D
		
		var shootTroughBody = null

		solidBody  = dumbFunc(runningSolid)

		if runningShootThrough.get_surface_count() > 0:
			shootTroughBody= dumbFunc(runningShootThrough)
		


		if shootTroughBody != null:
			shootTroughBody.name = "shootThroughCol"
			shootTroughBody.set_collision_layer_value(1,true)#stops players
			shootTroughBody.set_collision_layer_value(2,false)
			
		if solidBody != null:
			solidBody.name = "solidCol"
			solidBody.set_collision_layer_value(1,true)#stops actors
			solidBody.set_collision_layer_value(2,true)#stops bullets
			
			meshInstance.add_child(solidBody)

		
		if shootTroughBody != null:
			meshInstance.add_child(shootTroughBody)
		
	
	if get_parent().unwrapLightmap:
		runningMesh.lightmap_unwrap(Transform3D.IDENTITY,1.0)
	
	meshInstance.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	meshInstance.use_in_baked_light = true
	meshInstance.scale = meshScale
	meshInstance.mesh = runningMesh
	

	var lightLevel = WADG.getLightLevel(sectors[sectorIdx]["lightLevel"])
	
	
	#for i in meshInstance.mesh.get_surface_count():
	#	meshInstance.mesh.surface_get_material(i).set_shader_parameter("tint",Color(lightLevel,lightLevel,lightLevel))
	if get_parent().useInstanceShaderParam:
		#meshInstance.set("instance_shader_parameters/alpha",arr[0]["alpha"])
		meshInstance.set("instance_shader_parameters/sectorLight",Color(lightLevel,lightLevel,lightLevel))
	
	meshInstance.set_meta("merged",true)
	geomNode.add_child(meshInstance)
	

	
	

func textureGroupIntoMesh(textureGroup:Dictionary,runningMesh:ArrayMesh,sector : Dictionary,runningSolid:ArrayMesh,runningShootThrough : ArrayMesh,mapName : String) -> Node3D:
	var sectorNode
	
	var keepWallsConvex = get_parent().KEEP_WALLS_CONVEX
	
	for textureName : String in textureGroup.keys():
		
		var localMesh: SurfaceTool= SurfaceTool.new()
		var localSolid : SurfaceTool= SurfaceTool.new()
		var localShootThrough : SurfaceTool= SurfaceTool.new()
		
		var params = textureName.split(",")
		var alpha = float(params[1])
		
		localMesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		if !keepWallsConvex:
			localSolid.begin(Mesh.PRIMITIVE_TRIANGLES)
			localShootThrough.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var meshCenter = Vector3.ZERO
		var mat : Material
		
		for mesh : Dictionary in textureGroup[textureName]:
			meshCenter += getMeshCenter(mesh["start"],mesh["ceilZ"])
			
		meshCenter /=  textureGroup[textureName].size()
		
		var text : Texture

		if textureName!=null:
			if textureName.substr(0,6) != "F_SKY1":
				text = textureGroup[textureName][0]["texture"]
				var lightAdjusted = WADG.getLightLevel(sector["lightLevel"])
				var sectorColor : Color = Color(lightAdjusted,lightAdjusted,lightAdjusted)
				var realTextureName : String = textureName.split(",")[0]#after the comma is alpha to stop same textures of different alpha being lost in merge
				mat = materialManager.fetchGeometryMaterial(realTextureName,text,sectorColor,Vector2.ZERO,alpha,true)
				
			else:
				mat = materialManager.fetchSkyMat($"../ImageBuilder".getSkyboxTextureForMap(mapName),true)


		
		localMesh.set_material(mat)
		
		
		for meshInfo : Dictionary in textureGroup[textureName]:#we keep appending to localSurf
			
			var start : Vector2= meshInfo["start"]
			var end : Vector2= meshInfo["end"]
			var floorZ : float= meshInfo["floorZ"]
			var ceilZ : float= meshInfo["ceilZ"]
			var fCeil : float= meshInfo["fCeil"]
			var uvType : TEXTUREDRAW = meshInfo["uvType"]
			var textureOffset : Vector2= meshInfo["textureOffset"]
			var sideIndex : int = meshInfo["sideIndex"]
			
			makeSideMesh(start,end,floorZ,ceilZ,fCeil,text,uvType,textureOffset,sideIndex,textureName,localMesh,meshCenter,mat)
			#createMesh(localMesh,meshInfo,meshCenter,mat,text)
			
			if meshInfo["hasCol"] == false:
				continue
			
			if !keepWallsConvex:
				if meshInfo["colMask"] == 1:
					makeSideMesh(start,end,floorZ,ceilZ,fCeil,text,uvType,textureOffset,sideIndex,textureName,localSolid,meshCenter,mat)
					#createMesh(localSolid,meshInfo,meshCenter,mat,text)
					
				elif meshInfo["colMask"] == 0:
					makeSideMesh(start,end,floorZ,ceilZ,fCeil,text,uvType,textureOffset,sideIndex,textureName,localShootThrough,meshCenter,mat)
					#createMesh(localShootThrough,meshInfo,meshCenter,mat,text)
			
				
			sectorNode = meshInfo["sectorNode"]
		
		
		if !keepWallsConvex:
			localSolid.commit(runningSolid)
			localShootThrough.commit(runningShootThrough)
		
		
		runningMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,localMesh.commit_to_arrays())
		runningMesh.surface_set_material(runningMesh.get_surface_count()-1,mat)
		#runningMesh.append_from(localMesh)
		#addToMeshWall(localMesh,runningMesh)
		
		
		runningMesh.surface_set_name(runningMesh.get_surface_count()-1,textureName)
		
	return sectorNode


	
func createMesh(localSurf : SurfaceTool,meshInfo : Dictionary,origin : Vector3,mat : Material,texture : Texture) -> void:
	var start : Vector2= meshInfo["start"]
	var end : Vector2= meshInfo["end"]
	var floorZ : float= meshInfo["floorZ"]
	var ceilZ : float= meshInfo["ceilZ"]
	var fCeil : float= meshInfo["fCeil"]
	var uvType : TEXTUREDRAW = meshInfo["uvType"]
	var textureOffset : Vector2= meshInfo["textureOffset"]
	var sideIndex : int = meshInfo["sideIndex"]

	var textureName : String= meshInfo["textureName"]

	
	
	makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,textureName,localSurf,origin,mat)
	

var meshCache : Dictionary = {}

func makeSideMesh(start:Vector2,end:Vector2,floorZ:float,ceilZ:float,fCeil:float,texture:Texture,uvType:TEXTUREDRAW,textureOffset:Vector2,sideIndex:int,textureName:String,localSurf:SurfaceTool,origin:Vector3,mat:Material) -> void:

	var scaleFactor : Vector3= get_parent().scaleFactor
	var height : float = ceilZ-floorZ 
	var startUVy : float= 0
	var startUVx : float= 0
	var endUVy : float= 0
	var endUVx : float= 0
	
	var textureDim : Vector2 = Vector2.ZERO
	
	if texture != null:
		textureDim = texture.get_size()*Vector2(scaleFactor.x,scaleFactor.y)
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
	
	 
		startUVy += textureOffset.y / textureDim.y
		endUVy += textureOffset.y / textureDim.y
	
		startUVx += textureOffset.x / textureDim.x
		endUVx += textureOffset.x / textureDim.x
	
	var TL = Vector3(start.x,ceilZ,start.y)# - origin
	var BL = Vector3(start.x,floorZ,start.y)# -origin
	var TR = Vector3(end.x,ceilZ,end.y)# - origin
	var BR = Vector3(end.x,floorZ,end.y)# - origin
	
	var line1 : Vector3 = TL - TR
	var line2 : Vector3 = TL - BL
	var normal : Vector3 = -line1.cross(line2).normalized()

	#var meshKey = [TL-TL,TR-TL,BR-TL,BL-TL,textureOffset,textureDim]
	
	#if !meshCache.has(meshKey):
	#	meshCache[meshKey] = true
	#else:
	#	breakpoint
	
	localSurf.set_normal(normal)
	localSurf.set_uv(Vector2(startUVx,startUVy))
	localSurf.set_uv2(Vector2(startUVx,startUVy))
	localSurf.add_vertex(TL)
	
	localSurf.set_normal(normal)
	localSurf.set_uv((Vector2(endUVx,startUVy)))
	localSurf.set_uv2((Vector2(endUVx,startUVy)))
	localSurf.add_vertex(TR)
	
	localSurf.set_normal(normal)
	localSurf.set_uv(Vector2(endUVx,endUVy))
	localSurf.set_uv2(Vector2(endUVx,endUVy))
	localSurf.add_vertex(BR)
	
	
	localSurf.set_normal(normal)
	localSurf.set_uv(Vector2(startUVx,startUVy))
	localSurf.set_uv2(Vector2(startUVx,startUVy))
	localSurf.add_vertex(TL)
	
	localSurf.set_normal(normal)
	localSurf.set_uv(Vector2(endUVx,endUVy))
	localSurf.set_uv2(Vector2(endUVx,endUVy))
	localSurf.add_vertex(BR)
	
	localSurf.set_normal(normal)
	localSurf.set_uv(Vector2(startUVx,endUVy))
	localSurf.set_uv2(Vector2(startUVx,endUVy))
	localSurf.add_vertex(BL)
	

func getMeshCenter(start,ceilZ) -> Vector3:
	var origin : Vector3 = Vector3(start.x,ceilZ,start.y)
	return origin
	
func getFloorAndCeilingMesh(sectorNode : Node3D):
	var floorNode : Node3D
	var ceilingNode: Node3D
	
	for i : Node in sectorNode.get_children():

		if i.has_meta("ceil"): 
			ceilingNode = i
		if i.has_meta("floor"):
			floorNode = i
	
	if floorNode == null: return null
	if ceilingNode == null : return null
	
	
	if floorNode.has_meta("special") or floorNode.has_meta("damage"):
		return null
		
	if ceilingNode.has_meta("special") or floorNode.has_meta("damage"):
		return null
	
	
	var ceilingMat = ceilingNode.mesh.surface_get_material(0)
	var floorMat = floorNode.mesh.surface_get_material(0)
	
	return {
		"ceilingNode":ceilingNode,"ceilingMesh":ceilingNode.mesh,"ceilingTransform":ceilingNode.transform,"ceilingMat":ceilingMat,
		"floorNode":floorNode,"floorMesh":floorNode.mesh,"floorTransform":floorNode.transform,"floorMat":floorMat
		}
	
	
func addFloorAndCeilingToMesh(srcMeshForFloor : ArrayMesh, srcMeshForCeil : ArrayMesh,sectorNode : Node3D,sectorIdx : int,delete : bool= false,childrenDupe : bool= false,meshInstance:MeshInstance3D=null) -> void:
	
	var ret = getFloorAndCeilingMesh(sectorNode)
	if ret == null:
		return
	
	
	var ceilingMesh = ret["ceilingMesh"]
	var floorMesh = ret["floorMesh"]
	
	
	addFloorOrCeilToMesh(ret["ceilingMat"],srcMeshForCeil,ceilingMesh,ret["ceilingTransform"].origin,delete,ret["ceilingNode"])
	
	if !dynamicFloors.has(sectorIdx):
		addFloorOrCeilToMesh(ret["floorMat"],srcMeshForFloor,floorMesh,ret["floorTransform"].origin,delete,ret["floorNode"])
	
	
	if childrenDupe:
		if ret["floorNode"].has_meta("special"):
			var specialNode = ret["floorNode"].get_meta("special")
			
			specialNode.meshPath = "../../Geometry/" + meshInstance.name

	

func addFloorOrCeilToMesh(mat : Material,inputMesh : ArrayMesh,meshToAdd : ArrayMesh,origin : Vector3,delete : bool,oldNode : Node3D) -> void:
	var surf : SurfaceTool = SurfaceTool.new()
	
	surf.set_material(mat)
	addToMeshFlat(surf,inputMesh,meshToAdd,origin)
	
	if delete:
		oldNode.get_parent().remove_child(oldNode)
		oldNode.queue_free()
		
	var surfname = meshToAdd.surface_get_name(0)
	inputMesh.surface_set_name(inputMesh.get_surface_count()-1,surfname)
	

func dumbFunc(mesh : ArrayMesh):
	var meshInstance : MeshInstance3D= MeshInstance3D.new()
	meshInstance.scale = meshScale
	meshInstance.mesh = mesh

	meshInstance.create_trimesh_collision()
	
	if meshInstance.get_child_count() != 0:
		var a = meshInstance.get_child(0)
		
		if a == null:
			meshInstance.queue_free()
			return
		
		
		var t  =a.duplicate()
		meshInstance.queue_free()
		return t
		
	meshInstance.queue_free()
	return null
	
func addToMeshFlat(surf : SurfaceTool,dest:ArrayMesh,source:ArrayMesh,position:Vector3):

	var data : Dictionary = WADG.getVertsFromMeshArrayMesh(source,position)
	
	var verts = data["verts"]
	var normals = data["normals"]
	var uv = data["uv"]
	var mat = data["material"]
	
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_material(mat)
	for i in verts.size():
		surf.set_normal(normals[i])
		surf.set_uv(uv[i])
		surf.set_uv2(uv[i])
		surf.add_vertex(verts[i])
		
		
	
	surf.commit(dest)

func getStairDict(dict) -> Array:
	var allStairs  = []
	
	for i in dict.keys():
		if !allStairs.has(i):
			allStairs.append(i)
		
		for j in dict[i]:
			if !allStairs.has(j):
				allStairs.append(j)
	
	return allStairs
