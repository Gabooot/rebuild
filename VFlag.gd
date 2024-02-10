extends Flag
class_name VFlag

func _init():
	MAX_SPEED += 2.5
	reload_time_tick += 200

func _drop_flag(tank : TankInterface) -> void:
	#print("Dropping flag on: ", multiplayer.is_server())
	tank.flag_name = "default"
	tank.emit_signal("flag_dropped")

func grab_flag(tank : TankInterface, flag_pole : FlagPole) -> void:
	pass
