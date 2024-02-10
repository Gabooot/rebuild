extends CharacterBody3D
class_name MovingBlock

var next_velocity : Vector3 = Vector3(0,0,0)
var timer : int = -1
var id = -20


func _ready() -> void:
	self.velocity = Vector3(0,0,-2.0)


func simulate() -> void:
	self.timer -= 1
	
	if timer == 0:
		self.velocity = next_velocity
	
	self.move_and_collide(self.velocity * 0.016667)
	
	if (timer < -900) and multiplayer.is_server():
		self.next_velocity = -velocity
		self.timer = 20
