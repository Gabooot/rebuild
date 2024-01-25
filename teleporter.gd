extends Area3D
class_name Teleporter

@onready var base = get_node("/root/game")
var target : Teleporter 
var active_3d_nodes : Array = [] 
# Called when the node enters the scene tree for the first time.
func _ready():
	target = get_node("/root/game/teleporter2")
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited) 
	#base.establish_state.connect(_find_tanks)

func _on_body_entered(body : Node3D) -> void:
	#print("body entered teleporter")
	if body is TeleportableCharacterBody:
		body.emit_signal("teleporter_entered", self)

func _on_body_exited(body : Node3D):
	#print("body exited teleporter")
	if body is TeleportableCharacterBody:
		body.emit_signal("teleporter_exited", self)

func teleport_transform(old_transform: Transform3D, old_velocity : Vector3) -> Array:
	#var old_position = old_transform.origin
	#var new_position = target.global_transform * (self.global_transform.inverse() * (old_position))
	var new_transform = target.global_transform * (self.global_transform.inverse() * old_transform)
	#var old_quat = old_transform.basis.get_rotation_quaternion()
	var rotate_by = target.basis.get_rotation_quaternion()
	var inverse_rotation = self.basis.get_rotation_quaternion().inverse()
	#var new_quat = rotate_by * (inverse_rotation * old_quat)
	var new_velocity = rotate_by * (inverse_rotation * old_velocity)
	return [new_transform, new_velocity]
	

func _get_teleported_position(relative_position : Vector3) -> Vector3:
	var rotation_quat = Quaternion(self.global_transform.basis).normalized()
	relative_position = rotation_quat * relative_position
	return self.global_position + relative_position

'''func _find_tanks() -> void:
	var collision = self.move_and_collide(Vector3(0,1,0), true)
	if collision and (collision.get_collider() is TeleportableCharacterBody):
		collision.get_collider().emit_signal("teleporter_entered")'''
