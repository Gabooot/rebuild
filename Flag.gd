extends RefCounted
class_name Flag

var MAX_SPEED : float = 5
var GRAVITY : float = 9.8
var TURN_SPEED : float = .8
var JUMP_SPEED : float = 9.5

const GUN_VELOCITY_MULTIPLIER : float = 1.4
# TODO Watch this space, controllable physics speed is probably useful
const PHYSICS_DELTA = 0.01666666

var reload_time_tick : int = 120
var acceleration : float = 100.0
var tank : TankInterface

func _init(parent_tank : TankInterface):
	self.tank = parent_tank
	tank.flag = self

func simulate() -> void:
	
	if self.tank.is_shooting:
		self.shoot()
	else:
		pass
	
	var old_velocity = tank.velocity
	tank.velocity = Vector3(0,0,0)
	tank.move_and_slide()
	tank.velocity = old_velocity
	
	self.rotate_from_input()
	self.move_from_input() 
	self._update_shot_timers()
	
	self.tank.is_shooting = false
	self.tank.is_jumping = false


func rotate_from_input() -> void:
	if tank.is_on_floor():
		tank.angular_velocity = tank.steering_input * TURN_SPEED
		tank.rotate_object_local(Vector3.UP, tank.angular_velocity * PHYSICS_DELTA)
	else:
		tank.rotate_object_local(Vector3.UP, tank.angular_velocity * PHYSICS_DELTA)

func move_from_input() -> void:
	if (not tank.is_on_floor()) or tank.is_jumping:
		tank.axis_lock_linear_y = false
	else:
		tank.axis_lock_linear_y = true
	
	tank.engine_speed = get_speed_from_input()
	tank.velocity = get_velocity_from_speed(tank.engine_speed, tank.is_jumping)
		#print("server old: ", tank.global_position)
	tank.move_and_slide()

func get_speed_from_input() -> float:
	if not tank.is_on_floor():
		return tank.engine_speed
	var new_speed = 0.0
	if tank.speed_input * MAX_SPEED > tank.engine_speed:
		new_speed = min((tank.engine_speed + (acceleration * PHYSICS_DELTA)), tank.speed_input * MAX_SPEED)
	elif tank.speed_input * MAX_SPEED < tank.engine_speed:
		new_speed = max((tank.engine_speed - (acceleration * PHYSICS_DELTA)), tank.speed_input * MAX_SPEED)
	else:
		new_speed = tank.engine_speed
	
	return new_speed

func get_velocity_from_speed(speed : float=tank.engine_speed, jumped : bool=false) -> Vector3:
	if tank.is_on_floor():
		if jumped:
			var external_velocity = ((tank.transform.basis.z * -speed) + Vector3(0, JUMP_SPEED, 0))
			return external_velocity
		else:
			var external_velocity = tank.transform.basis.z * -speed
			return external_velocity
	else:
		var external_velocity = (tank.velocity - Vector3(0, GRAVITY * PHYSICS_DELTA, 0))
		return external_velocity

# Shoot a bullet
func shoot(force:bool=false,start_transform:Transform3D=tank.global_transform, start_velocity:Vector3=tank.velocity) -> Variant:
	if (tank.shot_timers[0] < 1) or force:
		tank.shot_timers.pop_front()
		tank.shot_timers.append(self.reload_time_tick)
		var bullet = preload("res://bullet.tscn")
		var shot = bullet.instantiate()
		shot.position = start_transform.origin - (start_transform.basis.z * 1.2)
		shot.velocity = Vector3(start_velocity.x, 0.0, start_velocity.z) + (-start_transform.basis.z * shot.SPEED)
		tank.game_controller.add_child(shot)
		return shot
	else:
		#print("Shot Timers: ", tank.shot_timers)
		return null


func _update_shot_timers() -> void:
	#print("Tank shot timers: ", tank.shot_timers)
	for i in range(len(tank.shot_timers)):
		if tank.shot_timers[i] > 0:
			tank.shot_timers[i] = tank.shot_timers[i] - 1
