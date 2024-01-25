extends TeleportableCharacterBody
class_name Bullet

const SPEED = 9.0
var radar_icon = null
var can_collide_with_tanks = true
@onready var game_controller = get_node("/root/game")

func _ready():
	game_controller.simulate.connect(simulate)
	var lifetime = Timer.new()
	self.add_child(lifetime)
	lifetime.timeout.connect(_exit)
	lifetime.start(15)
	
	radar_icon = preload("res://radar_bullet.tscn").instantiate()
	radar_icon.bullet = self
	var RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	radar_icon.position = Vector2(self.global_position.x * RADAR_SCALE, self.global_position.z * RADAR_SCALE)
	# I'm dumb and I can't figure out how to initialize bullet rotation correctly; so I hide it until it updates...
	radar_icon.global_rotation = self.global_rotation.y
	#print("Radar rotation: ", radar_icon.global_rotation, " Bullet rotation: ", self.global_rotation.y)
	#radar_icon.visible = false
	get_node("/root/game/radar/rotater/mover").add_child(radar_icon)
	var tele_gadget = TeleportDevice.new()
	self.add_child(tele_gadget)
	%shot.play()


func _physics_process(delta):
	self.travel(delta)
	
func travel(delta, collide_with_tanks=true): 
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		%rico.play()
	self.look_at(self.global_position + self.velocity)

func _exit():
	radar_icon.queue_free()
	self.queue_free()


func _on_area_3d_body_entered(body):
	if (body is Tank) and self.can_collide_with_tanks:
		print("tank hit: ", body.name)
		get_node("/root/game").emit_signal("tank_hit", "problem", body.name)
		self._exit()

func simulate() -> void:
	#print("Simulating bullet: ", self.global_position)
	#self.travel(0.01666667)
	pass
	
	
