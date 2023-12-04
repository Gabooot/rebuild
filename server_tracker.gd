extends "tank.gd"

@onready var player = get_parent()

func predict_transform(data) -> void:
	self.global_transform = Transform3D(Basis(data.quat), data.origin)
	# Lazy way to determine if player is on floor after position reset/update
	self.velocity = Vector3.ZERO
	move_and_slide()
		
	self.velocity = data.velocity
	self.speed = sqrt((data.velocity.x**2) + (data.velocity.z**2)) *\
	(float(data.velocity.angle_to(self.transform.basis.z) < (0.5)) * -1)
	#print("Server angular: ", data.angular_velocity, " Current angular: ", self.angular_velocity)
	self.angular_velocity = data.angular_velocity
	
	var i = player.get_local_tick_diff(data)
	while i < -1:
		i += 1
		self.rotate_from_input(player.input_stream[i])
		self.move_from_input(player.input_stream[i]) 

func add_local_bullet(start_transform, start_velocity, shot_tick):
	var timer = get_node_or_null("/root/game/HUD/scope/shot_counter")
	if timer:
		timer.start_shot_timer()
	var shot = self.shoot(start_transform, start_velocity)
	shot.can_collide_with_tanks = false
	for i in range((-shot_tick) - 1):
		shot.travel(PHYSICS_DELTA, false)
	shot.can_collide_with_tanks = true
