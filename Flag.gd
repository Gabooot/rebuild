extends Node
class_name Flag

var MAX_SPEED : float = 5
var GRAVITY : float = 9.8
var TURN_SPEED : float = .8
var JUMP_SPEED : float = 9.5

var PHYSICS_DELTA = 0.01666666
var reload_time_tick : int = 120
var acceleration : float = 100.0


func simulate(tank : TankInterface) -> void:

	_update_shot_timers(tank)
	var old_velocity = tank.velocity
	tank.velocity = Vector3(0,0,0)
	tank.move_and_slide()
	tank.velocity = old_velocity
	rotate_from_input(tank)
	
	var velocity_adjustment = Vector3(0,0,0)
	if tank.is_on_floor():
		var collision = tank.move_and_collide(Vector3(0,-0.1,0.0),true)
		if collision:
			if collision.get_collider() is CharacterBody3D:
				velocity_adjustment = collision.get_collider().velocity
	if tank.is_shooting:
		shoot(tank, tank.global_transform, tank.velocity + velocity_adjustment)
	else:
		pass
	
	move_from_input(tank, velocity_adjustment) 
	tank.is_shooting = false
	tank.is_jumping = false
	if tank.is_dropping_flag:
		_drop_flag(tank)
	tank.is_dropping_flag = false


func rotate_from_input(tank : TankInterface) -> void:
	if tank.is_on_floor():
		tank.angular_velocity = tank.steering_input * TURN_SPEED
		tank.rotate_object_local(Vector3.UP, tank.angular_velocity * PHYSICS_DELTA)
	else:
		tank.rotate_object_local(Vector3.UP, tank.angular_velocity * PHYSICS_DELTA)

func move_from_input(tank : TankInterface, velocity_adjustment : Vector3) -> void:
	if (not tank.is_on_floor()) or tank.is_jumping:
		tank.axis_lock_linear_y = false
	else:
		tank.axis_lock_linear_y = true
	
	tank.engine_speed = _get_speed_from_input(tank)
	tank.velocity = _get_velocity_from_speed(tank, tank.engine_speed, tank.is_jumping)
	tank.velocity += velocity_adjustment
	tank.move_and_slide()
	if not tank.is_jumping:
		tank.velocity -= velocity_adjustment

func _get_speed_from_input(tank : TankInterface) -> float:
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

func _get_velocity_from_speed(tank : TankInterface, speed : float, jumped : bool=false) -> Vector3:
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
func shoot(tank:TankInterface,start_transform:Transform3D, start_velocity:Vector3) -> Variant:
	if (tank.shot_timers[0] < 1):
		tank.shot_timers.pop_front()
		tank.shot_timers.append(reload_time_tick)
		var bullet = preload("res://bullet.tscn")
		var shot = bullet.instantiate()
		shot.position = start_transform.origin - (start_transform.basis.z * 1.2)
		shot.velocity = Vector3(start_velocity.x, 0.0, start_velocity.z) + (-start_transform.basis.z * shot.SPEED)
		tank.game_controller.add_child(shot)
		return shot
	else:
		#print("Shot Timers: ", tank.shot_timers)
		return null


func _update_shot_timers(tank : TankInterface) -> void:
	#print("Tank shot timers: ", tank.shot_timers)
	for i in range(len(tank.shot_timers)):
		if tank.shot_timers[i] > 0:
			tank.shot_timers[i] = tank.shot_timers[i] - 1

func grab_flag(tank : TankInterface, new_flag : FlagPole) -> void:
	var id = tank.id
	new_flag.attach_to_tank(id)

func _drop_flag(tank : TankInterface) -> void:
	pass
