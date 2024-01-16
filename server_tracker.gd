extends "tank.gd"

@onready var player = get_parent()

func _start_buffer() -> void:
	self.buffer = InputBuffer.new(ServerInput.new(Quaternion(1,0,0,0), Vector3(10, 5, 10)), buffer_length)

func predict_transform(data:OrderedInput=self.buffer.take()) -> void:
	#print("incoming packet: ", data.quat, " ", data.origin, " Old transform: ", self.global_transform)
	self.global_transform = Transform3D(Basis(data.quat), data.origin)
	#print("new_transform: ", self.global_transform)
	# Lazy way to determine if player is on floor after position reset/update
	self.velocity = Vector3.ZERO
	move_and_slide()
		
	self.velocity = data.velocity
	if self.is_on_floor():
		var ground_velocity = Vector2(self.velocity.x, self.velocity.z)
		var absolute_speed = ground_velocity.length()
		var direction = ground_velocity.angle_to(Vector2(self.global_transform.basis.z.x, self.global_transform.basis.z.z)) # (0.5 * PI)
		#print("Direction: ", direction)
		if abs(direction) < 0.001:
			self.speed = absolute_speed * -1
		else:
			self.speed = absolute_speed
	#sqrt((data.velocity.x**2) + (data.velocity.z**2)) *\
	#(float(data.velocity.angle_to(self.transform.basis.z) < (0.5 * PI)) * -1)
	#print("Server angular: ", data.angular_velocity, " Current angular: ", self.angular_velocity)
	self.angular_velocity = data.angular_velocity
	
	var i = player.get_local_tick_diff(data)
	#print("packet order: ", data.order)
	while i < 0:
		var current_input = player.input_stream[i]
		self.rotate_from_input(current_input)
		self.move_from_input(current_input)
		i += 1


func add_local_bullet(start_transform, start_velocity, shot_tick):
	var timer = get_node_or_null("/root/game/HUD/scope/shot_counter")
	if timer:
		timer.start_shot_timer()
	var shot = self.shoot(start_transform, start_velocity)
	shot.can_collide_with_tanks = false
	for i in range((-shot_tick) - 1):
		shot.travel(PHYSICS_DELTA, false)
	shot.can_collide_with_tanks = true

func teleport(target : Vector3) -> void:
	pass
