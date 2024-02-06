extends TeleportableCharacterBody
class_name Bullet

const SPEED = 9.0
var radar_icon = null
var can_collide_with_tanks = true
var detector : HackyArea3D
var start_immunity_countdown : int = 8
@onready var game_controller = get_node("/root/game")

func _ready():
	game_controller.simulate.connect(simulate)
	game_controller.after_simulation.connect(_after_simulation)
	self._attach_detector()
	var lifetime = Timer.new()
	self.add_child(lifetime)
	lifetime.timeout.connect(_exit)
	lifetime.start(15)
	radar_icon = preload("res://radar_bullet.tscn").instantiate()
	radar_icon.bullet = self
	var RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	radar_icon.position = Vector2(self.global_position.x * RADAR_SCALE, self.global_position.z * RADAR_SCALE)
	radar_icon.global_rotation = self.global_rotation.y
	get_node("/root/game/radar/rotater/mover").add_child(radar_icon)
	var state_manager = StateManager.new(self, ["velocity", "global_transform"], game_controller.active_tick)
	self.add_child(state_manager)
	var tele_gadget = TeleportDevice.new()
	self.add_child(tele_gadget)
	%shot.play()
	self.force_update_transform()


func travel(delta, collide_with_tanks=true): 
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		%rico.play()
	self.look_at(self.global_position + self.velocity)

func _exit():
	radar_icon.queue_free()
	self.queue_free()


func simulate() -> void:
	#print("Simulating bullet: ", self.global_position)
	self.travel(0.01666667)
	self.force_update_transform()


func _after_simulation() -> void:
	if not self.can_collide_with_tanks:
		return
	
	for body in detector.get_overlapping_bodies():
		if (body is TankInterface):
			if multiplayer.is_server():
				body.global_position += Vector3(randf_range(-10,10), 80, randf_range(-10,10))
				self.position += Vector3(-9999,-9999,-9999)
			else:
				if (body.name == "input_tracker"):
					continue 
				self.position += Vector3(-9999,-9999,-9999)


func _attach_detector() -> void:
	var shape = SphereShape3D.new()
	shape.radius = 0.05
	self.detector = HackyArea3D.new(2,shape)
	self.add_child(self.detector)
