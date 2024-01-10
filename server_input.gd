extends RefCounted
class_name ServerInput 

var id : int
var quat : Quaternion
var origin : Vector3
var velocity : Vector3
var shot_fired : bool

func _init(slot:int=0,quat:Quaternion=Quaternion(0,0,0,0),origin:Vector3=Vector3(0,0,0),\
velocity:Vector3=Vector3(0,0,0),shot_fired:bool=false,id:int=0):
	self.slot = slot
	self.quat = quat
	self.origin = origin
	self.velocity = velocity
	self.shot_fired = shot_fired
	self.id = id

func to_byte_array() -> PackedByteArray:
	return var_to_bytes([self.slot, self.quat, self.origin, self.velocity, self.shot_fired])
