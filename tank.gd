extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8
var angular_velocity : float = 0

func _physics_process(delta):
	var server = get_node("/root/game/UDPserver")
	#server.packet_number += 1.0
	if not is_on_floor():
		self.axis_lock_linear_y = false
		self.velocity.y -= GRAVITY * delta
	rotate_object_local(Vector3.UP, angular_velocity*delta)
	move_and_slide()
	


func shoot():
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = position - (transform.basis.z * 1.2)
	shot.velocity = velocity + (-transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)
