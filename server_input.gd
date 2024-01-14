class_name ServerInput extends OrderedInput


var id : int
var quat : Quaternion
var origin : Vector3
var velocity : Vector3
var angular_velocity : float
var shot_fired : bool

func _init(quat:Quaternion=Quaternion(1,0,0,0),origin:Vector3=Vector3(0,0,0),\
velocity:Vector3=Vector3(0,0,0),angular_velocity:float=0.0,shot_fired:bool=false,order:int=0,id:int=0,):
	self.id = id
	self.quat = quat
	self.origin = origin
	self.velocity = velocity
	self.angular_velocity = angular_velocity
	self.shot_fired = shot_fired
	self.order = order


func to_byte_array() -> PackedByteArray:
	return var_to_bytes([self.quat, self.origin, self.velocity, self.angular_velocity, self.shot_fired, self.order, self.id,])
