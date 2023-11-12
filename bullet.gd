extends CharacterBody3D

const SPEED = 5.0
var radar_icon = null
func _ready():
	var lifetime = Timer.new()
	self.add_child(lifetime)
	lifetime.timeout.connect(_exit)
	lifetime.start(15)
	
	radar_icon = preload("res://radar_bullet.tscn").instantiate()
	radar_icon.bullet = self
	var RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	radar_icon.position = Vector2(self.global_position.x * RADAR_SCALE, self.global_position.z * RADAR_SCALE)
	# I'm dumb and I can't figure out how to initialize bullet rotation correctly; so I hide it until it updates...
	# radar_icon.global_rotation = -1.570796
	radar_icon.visible = false
	get_node("/root/game/radar/rotater/mover").add_child(radar_icon)


func _physics_process(delta):
	travel(delta)
	
func travel(delta): 
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider() is tank:
			get_node("/root/game").emit_signal("tank_hit", "problem", collision.get_collider().name)
			self._exit()
		velocity = velocity.bounce(collision.get_normal())

func _exit():
	radar_icon.queue_free()
	self.queue_free()
