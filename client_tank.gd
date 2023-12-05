extends "tank.gd"

const MAX_UPDATES_STORED : int = 10
const MIN_INTERPOLATION_DISTANCE = 0.1
const MIN_ANGLE_TO_INTERPOLATE = 0.01

var new_packet = {"quat": Quaternion(0,0,0,0),
					"origin": Vector3(0,0,0),
					"velocity": Vector3(0,0,0),
					"angular_velocity": 0,
					"shot_fired": bool(0),
					"server_ticks_msec": 0,
					"player_ticks_msec": 0,
					"player_slot": 0}
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

func add_recent_update(packet : Dictionary = new_packet) -> void:
	var player = get_node("/root/game/player")
	var old_transform = self.global_transform
	var old_velocity = recent_server_data[-1].velocity
	
	if packet.shot_fired:
		add_local_bullet(Transform3D(Basis(packet.quat), packet.origin), packet.velocity, player.get_local_tick_diff(packet))
	if packet.server_ticks_msec > recent_server_data[-1].server_ticks_msec:
		recent_server_data.append(packet)
		self.update_transform(packet)
		self._interpolate(old_transform, self.global_transform, old_velocity)
		if len(recent_server_data) > MAX_UPDATES_STORED:
			recent_server_data = recent_server_data.slice(-MAX_UPDATES_STORED)
		else:
			pass
	else:
		self.update_transform_from_prediction(self.recent_server_data[-1])
		self._interpolate(old_transform, self.global_transform, old_velocity)

func _interpolate(old_transform : Transform3D, new_transform : Transform3D, old_velocity) -> Transform3D:
	var pos_diff = (new_transform.origin - old_transform.origin).length()
	var rotation_diff = new_transform.basis.get_euler().y - old_transform.basis.get_euler().y
	if rotation_diff > PI:
		rotation_diff -= (2 * PI)
	elif rotation_diff < -PI:
		rotation_diff += (2 * PI)
	
	var interp_ratio = 0.0
	if abs(rotation_diff) > self.TURN_SPEED * self.PHYSICS_DELTA: 
		interp_ratio = (self.TURN_SPEED * self.PHYSICS_DELTA) / abs(rotation_diff)
	
	if pos_diff > (old_velocity.length() * self.PHYSICS_DELTA):
		interp_ratio = min(((old_velocity.length() * self.PHYSICS_DELTA) / pos_diff), interp_ratio)
	
	if interp_ratio > 0.0:
		return old_transform.interpolate_with(new_transform, interp_ratio)
	else:
		return new_transform

func update_transform(packet) -> void:
	self.global_transform = Transform3D(Basis(packet.quat), packet.origin)

func update_transform_from_prediction(packet) -> void:
	self.rotate_object_local(Vector3.UP, packet.angular_velocity * PHYSICS_DELTA)
	self.velocity = packet.velocity
	self.move_and_slide()

func add_local_bullet(start_transform, start_velocity, shot_tick):
	var shot = self.shoot(start_transform, start_velocity)
	for i in range((-shot_tick) - 1):
		shot.travel(PHYSICS_DELTA)
