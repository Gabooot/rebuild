extends CharacterBody3D
class_name MovingBlock

var next_velocity : Vector3 = Vector3(0,0,0)
var timer : int = -1
var id = -20


func _ready() -> void:
	self.velocity = Vector3(0,0,-2.0)
	get_node("/root/game").after_simulation.connect(_simulate)
	#self.global_transform.origin = Vector3(17,10,16)


func _simulate() -> void:
	self.timer -= 1
	
	if timer == 0:
		self.velocity = next_velocity
	
	var collision = move_and_collide(self.velocity * 0.016667)
	if collision:
		var obstacle = collision.get_collider()
		if obstacle is CharacterBody3D:
			var remainder = collision.get_remainder()
			obstacle.move_and_collide(remainder)
			obstacle.force_update_transform()
			self.move_and_collide(remainder)
	if (timer < -900) and multiplayer.is_server():
		self.next_velocity = -velocity
		self.timer = 20
	self.force_update_transform()


func simulate() -> void:
	pass
