extends RefCounted
class_name Flag

var MAX_SPEED : float = 5
var GRAVITY : float = 9.8
var TURN_SPEED : float = .8
var JUMP_SPEED : float = 9.5

const GUN_VELOCITY_MULTIPLIER : float = 1.4
# TODO Watch this space, controllable physics speed is probably useful
const PHYSICS_DELTA = 0.01666666

var reload_time_msec = 3000
var acceleration : float = 100.0
var tank : TankInterface

func _init(parent_tank : TankInterface):
	self.tank = parent_tank
	tank.flag = self

func run_input_from_client(input : OrderedInput, server_shots_only=false) -> void:
	assert(input is PlayerInput, " Error: trying to run server output on server tank")
	
	if input.shot_fired and (not server_shots_only):
		self.shoot()
		input.shot_fired = false
		tank.shot_fired = true
	
	self.rotate_from_input(input)
	self.move_from_input(input) 

func set_client_state(input : OrderedInput, extrapolation_factor:int=5) -> PlayerInput:
	assert(input is ServerInput, " Error: trying to run client output on client tank")
	tank.global_transform = Transform3D(Basis(input.quat), input.origin)
	tank.velocity = input.velocity
	
	if input.shot_fired:
		print("shooting locally")
		var shot : Bullet = self.shoot(true)
		for i in range(extrapolation_factor):
			shot.travel(PHYSICS_DELTA, false)
		input.shot_fired = false
	
	return _get_client_input_from_server_input(input)

func get_state() -> OrderedInput:
	var current_transform = tank.global_transform
	var quat = Quaternion(current_transform.basis.orthonormalized())
	var origin = current_transform.origin
	#print("output origin: ", origin)
	return ServerInput.new(quat, origin, tank.velocity, tank.angular_velocity, tank.shot_fired)

func rotate_from_input(input : PlayerInput) -> void:
	if tank.is_on_floor():
		tank.angular_velocity = input.rotation * TURN_SPEED
		tank.rotate_object_local(Vector3.UP, tank.angular_velocity * PHYSICS_DELTA)
	else:
		tank.rotate_object_local(Vector3.UP, tank.angular_velocity * PHYSICS_DELTA)

func move_from_input(input : PlayerInput) -> void:
	if (not tank.is_on_floor()) or input.jumped:
		tank.axis_lock_linear_y = false
	else:
		tank.axis_lock_linear_y = true
	
	tank.speed = get_speed_from_input(input)
	tank.velocity = get_velocity_from_speed(tank.speed, input.jumped)
		#print("server old: ", tank.global_position)
	tank.move_and_slide()

func get_speed_from_input(input : PlayerInput) -> float:
	if not tank.is_on_floor():
		return tank.speed
	var new_speed = 0.0
	if input.speed * MAX_SPEED > tank.speed:
		new_speed = min((tank.speed + (acceleration * PHYSICS_DELTA)), input.speed * MAX_SPEED)
	elif input.speed * MAX_SPEED < tank.speed:
		new_speed = max((tank.speed - (acceleration * PHYSICS_DELTA)), input.speed * MAX_SPEED)
	else:
		new_speed = tank.speed
	
	return new_speed

func get_velocity_from_speed(speed : float=tank.speed, jumped : bool=false) -> Vector3:
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
	if ((Time.get_ticks_msec() - tank.shot_timers[0]) > reload_time_msec) or force:
		tank.get_node("/root/game/HUD/scope/shot_counter").start_shot_timer(reload_time_msec)
		tank.shot_timers.pop_front()
		tank.shot_timers.append(Time.get_ticks_msec())
		var bullet = preload("res://bullet.tscn")
		var shot = bullet.instantiate()
		shot.position = start_transform.origin - (start_transform.basis.z * 1.5)
		shot.velocity = start_velocity + (-start_transform.basis.z * shot.SPEED)
		tank.game_controller.add_child(shot)
		return shot
	else:
		return null

func _get_client_input_from_server_input(input : ServerInput) -> PlayerInput:
	assert(input is ServerInput, "Error; wrong input data type")
	
	var input_speed : float
	var input_rotation : float
	
	if tank.is_on_floor():
		var ground_velocity = Vector2(tank.velocity.x, tank.velocity.z)
		var absolute_speed = ground_velocity.length()
		var direction = ground_velocity.angle_to(Vector2(tank.global_transform.basis.z.x, tank.global_transform.basis.z.z)) 
		
		if abs(direction) < 0.001:
			absolute_speed = absolute_speed * -1
		else:
			absolute_speed = absolute_speed
		
		input_speed = (absolute_speed / MAX_SPEED)
		tank.speed = absolute_speed
	else:
		input_speed = (tank.speed / MAX_SPEED)
	
	input_rotation = input.angular_velocity / TURN_SPEED
	return PlayerInput.new(input_rotation, input_speed, false, input.shot_fired)
