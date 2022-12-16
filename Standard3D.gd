extends CharacterBody3D

func teleport(target : Vector3) -> void:
	self.global_position = target
