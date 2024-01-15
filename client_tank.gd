extends "tank.gd"

const MAX_UPDATES_STORED : int = 10
const MIN_INTERPOLATION_DISTANCE = 0.1
const MIN_ANGLE_TO_INTERPOLATE = 0.01

var extrapolation_factor : int = 3 
var previous_input : OrderedInput = ServerInput.new()

func _ready():
	self._start_buffer()
	self._add_radar_icon()

func _physics_process(delta):
	pass

func _start_buffer() -> void:
	self.buffer = InputBuffer.new(ServerInput.new(), 1)

func _add_radar_icon() -> void:
	print("Adding radar icon")
	var radar_icon = preload("res://radar_tank.tscn")
	radar_icon = radar_icon.instantiate()
	radar_icon.player = self
	get_node("/root/game/radar/rotater/mover").add_child(radar_icon)

func update_from_input(packet : OrderedInput=self.buffer.take()) -> Variant:
	#print("packet: ", bytes_to_var(packet.to_byte_array()))
	var old_transform = self.global_transform
	var old_velocity = previous_input.velocity
	self.previous_input = packet
	
	if packet.shot_fired:
		print("shooting locally")
		self.shoot()
		packet.shot_fired = false
		#_add_local_bullet(Transform3D(Basis(packet.quat), packet.origin), packet.velocity, extrapolation_factor)
	
	self._update_transform(packet)
	self._interpolate(old_transform, self.global_transform, old_velocity)
	return null

func add_ordered_input(new_input : OrderedInput) -> void:
	assert(new_input is ServerInput, "Error: non-server input in InputBuffer")
	super(new_input)

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

func _update_transform(packet) -> void:
	self.global_transform = Transform3D(Basis(packet.quat), packet.origin)

func update_transform_from_prediction(packet) -> void:
	self.rotate_object_local(Vector3.UP, packet.angular_velocity * PHYSICS_DELTA)
	self.velocity = packet.velocity
	self.move_and_slide()

func _add_local_bullet(start_transform, start_velocity, shot_tick_diff : int):
	var shot = self.shoot(start_transform, start_velocity)
	if shot:
		for i in range((-shot_tick_diff) - 1):
			shot.travel(PHYSICS_DELTA)
