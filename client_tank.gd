extends "tank.gd"

const MAX_UPDATES_STORED : int = 10
const MIN_INTERPOLATION_DISTANCE = 0.1
const MIN_ANGLE_TO_INTERPOLATE = 0.01

var recent_server_data : Array = [{"quat": Quaternion(0,0,0,0),
					"origin": Vector3(0,0,0),
					"velocity": Vector3(0,0,0),
					"angular_velocity": 0,
					"shot_fired": bool(0),
					"server_ticks_msec": 0,
					"player_ticks_msec": 0,
					"player_slot": 0}]

func _physics_process(delta):
	pass

func add_recent_update(packet : Dictionary) -> void:
	var player = get_node("/root/game/player")
	if packet.shot_fired:
		add_local_bullet(Transform3D(Basis(packet.quat), packet.origin), packet.velocity, player.get_local_tick_diff(packet))
	if packet.server_ticks_msec > recent_server_data[-1].server_ticks_msec:
		recent_server_data.append(packet)
		self.update_transform(packet)
		if len(recent_server_data) > MAX_UPDATES_STORED:
			recent_server_data = recent_server_data.slice(-MAX_UPDATES_STORED)
		else:
			pass
	else:
		self.update_transform_from_prediction(self.recent_server_data[-1])

func update_transform(packet) -> void:
	#Fix this code, especially in %player
	self.global_transform = Transform3D(Basis(packet.quat), packet.origin)

func update_transform_from_prediction(packet) -> void:
	self.rotate_object_local(Vector3.UP, packet.angular_velocity * PHYSICS_DELTA)
	self.velocity = packet.velocity
	self.move_and_slide()

func add_local_bullet(start_transform, start_velocity, shot_tick):
	var shot = self.shoot(start_transform, start_velocity)
	for i in range((-shot_tick) - 1):
		shot.travel(PHYSICS_DELTA)
