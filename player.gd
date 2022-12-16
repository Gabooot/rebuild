extends "Standard3D.gd"

# Maximum speed of tank.
@export var MAX_SPEED = 4
# The downward acceleration when in the air, in meters per second squared.
@export var GRAVITY = 9.8
# Tank turn rate
@export var TURN_SPEED = 1
# Tank initial jump velocity
@export var JUMP_SPEED = 8

var new_acceleration = 100
var new_speed = 0
var new_vertical_velocity = 0
var angular_velocity = 0

func _process(_delta):
	if Input.is_action_just_pressed("shoot"):
		shoot()

func _physics_process(delta):
	rotate_object_local(Vector3.UP, angular_velocity*delta)
	
	if not is_on_floor():
		self.axis_lock_linear_y = false
		velocity.y -= GRAVITY * delta
	
	if is_on_floor():
		self.axis_lock_linear_y = true
		if Input.is_action_pressed("turn_right"):
			angular_velocity = -TURN_SPEED
		elif Input.is_action_pressed("turn_left"):
			angular_velocity = TURN_SPEED
		else:
			angular_velocity = 0
		
		if Input.is_action_pressed("move_forward"):
			new_speed += new_acceleration * delta
		elif Input.is_action_pressed("move_backward"):
			new_speed -= new_acceleration * delta
		else:
			new_speed = 0
		
		if new_speed > MAX_SPEED:
			new_speed = MAX_SPEED
		elif new_speed < -MAX_SPEED:
			new_speed = -MAX_SPEED
		
		velocity = transform.basis.z * -new_speed
		
		if Input.is_action_pressed("jump"):
			self.axis_lock_linear_y = false
			velocity.y = JUMP_SPEED
	
	move_and_slide()

func shoot():
	var bullet = preload("res://bullet.tscn")
	var shot = bullet.instantiate()
	shot.position = position - (transform.basis.z * 1.2)
	shot.velocity = velocity + (-transform.basis.z * shot.SPEED)
	get_parent().add_child(shot)
