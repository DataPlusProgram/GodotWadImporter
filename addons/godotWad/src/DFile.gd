extends Node
var timings = {}


var data
var pos = 0
	
func loadFile(path):
	#var file = File.new()
	#if file.open(path,File.READ) != 0:
	#	return false
	
	var file = FileAccess.open(path,FileAccess.READ)
	
	if file == null:
		return false
	
	data = file.get_buffer(file.get_length())
	
	file.close()
	return true
	
	
func seek(offset):#
	pos = offset

func get_position():
	return pos
	
func get_8() -> int:
	var ret : int = data[pos]
	pos+=1
	return ret

func bulkByteArr(size):
	var ret = data.subarray(pos,pos+size)
	pos += size
	return ret

func get_16():
	#var ret = data.subarray(pos,pos+1)
	var ret = data.slice(pos,pos+2)
	pos+=2
	
	#var spb = StreamPeerBuffer.new()
	#spb.data_array = ret
	#var single_float = spb.get_16()
	
	#return single_float
	var rety = (ret[1] << 8) + ret[0]
	return (ret[1] << 8) + ret[0]

func get_16u():
	var ret = data.subarray(pos,pos+1)
	ret =  (ret[1] << 8) + ret[0]
	if (ret & 0x8000):
		ret -= 0x8000
		ret = (-32767 + ret) -1
		
	pos+=2
	return ret

func get_32u():
	#var ret = data.subarray(pos,pos+3)
	var ret = data.slice(pos,pos+4)
	pos+=4
	return (ret[3] << 24) + (ret[2] << 16) + (ret[1] << 8 ) + ret[0]
	



func get_32():
	#var ret = data.subarray(pos,pos+3)
	
	var ret = data.slice(pos,pos+4)
	var spb = StreamPeerBuffer.new()
	spb.data_array = ret
	var single_float = spb.get_32()
	pos+=4
	return single_float
	
func get_32_bigEndian():
	var ret : PackedByteArray = data.slice(pos,pos+4)
	#ret.reverse()
	var spb = StreamPeerBuffer.new()
	
	spb.big_endian = true
	
	spb.data_array = ret
	var single_float = spb.get_32()
	pos+=4

	return single_float

func get_16s():
	var ret = data.slice(pos,pos+2)
	ret =  (ret[1] << 8) + ret[0]
	if (ret & 0x8000):
		ret -= 0x8000
		ret = (-32767 + ret) -1
		
	pos+=2
	return ret

func get_Vector32():
	var x = get_float32()
	var y = get_float32()
	var z = get_float32()
	return Vector3(x,y,z)

func get_float32():
	var ret = data.subarray(pos,pos+3)
	var spb = StreamPeerBuffer.new()
	spb.data_array = ret
	var single_float = spb.get_float()
	pos+=4
	return single_float
	

func get_buffer(size) -> PackedByteArray:
	var ret = data.slice(pos,pos+(size))#not sure why using -1 here
	pos+=size
	return ret
	
func get_String(length):
#	var ret = data.subarray(pos,pos+(length-1)).get_string_from_ascii()
	var ret = data.slice(pos,pos+(length)).get_string_from_ascii()
	
	pos+=length
	return ret.to_upper()
	
	#func get_line():
	#	return data.get_line()
func get_length():
	return data.size()
		
func eof_reached():
	return pos >= data.size()


func scanForString(string,searchSize):
	#var sub = data.subarray(pos,pos+(searchSize-1))
	var sub = data.slice(pos,pos+(searchSize-1))
	for index in sub.size():
		if sub[index] == 0:
			sub[index] = 32
	
	var t = sub.get_string_from_ascii()
	
	return t.find(string,0) != -1
	
	
