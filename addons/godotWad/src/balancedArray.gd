
extends Resource
class_name BalancedArray
var maxSectionSize = 100
var array : Array[Array] = [[]]
var vectorArray : Array[PackedVector3Array] = []

var total = 0
var curPos = 0


func add(item):
	var smallestSize = INF
	var smallestSectionIndex = INF
	for sectionIdx in array.size():
		if array[sectionIdx].size() < smallestSize:
			smallestSize = array[sectionIdx].size()
			smallestSectionIndex = sectionIdx
	
	if smallestSize < maxSectionSize:
		array[smallestSectionIndex].append(item)
	
	else:
		array = splitArray()
		add(item)
		
	
	var total = 0
	for sectionIdx in array.size():
		total+= array[sectionIdx].size()
		
	return total


func splitArray() -> Array[Array]:
	var newAmnt = array.size() + 1
	var fillSize = int(maxSectionSize / newAmnt)
	
	# Flatten the array into a single list of elements
	var all_elements = []
	for arr in array:
		all_elements.append_array(arr)
	
	# Sorting is optional depending on your needs
	all_elements.sort()
	
	# Initialize the return array
	var ret : Array[Array]
	for i in range(newAmnt):
		ret.append([])

	# Distribute elements across the new arrays
	for i in range(newAmnt):
		var start_idx = i * fillSize
		var end_idx = start_idx + fillSize
		if start_idx < all_elements.size():
			ret[i] = all_elements.slice(start_idx, min(end_idx, all_elements.size()))
	
	# Handle any remaining elements
	var remaining_elements = all_elements.slice(newAmnt * fillSize)
	
	for i in range(remaining_elements.size()):
		ret[i % newAmnt].append(remaining_elements[i])
	
	return ret

func erase(item) -> void:# This will only work correclty if each element of the array is unique
	for section in array:
		if section.has(item):
			section.erase(item)
			return
			
func eraseFromItemFromSection(section : Array, item) -> void:
	if section.has(item):
		section.erase(item)
		return

func getNext() -> Array:
	curPos =(curPos + 1)%array.size()
	
	#print(curPos)
	
	var pos = 0
	var curArr = array[curPos]
	
	
	while pos < curArr.size():
		if !is_instance_valid(curArr[pos]):
			curArr.remove_at(pos)
			pos = max(pos -1,0)
			continue
		pos+=1
	
	return curArr
