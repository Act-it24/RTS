extends Node2D
signal on_spawn_unit(utype: String, pos: Vector2)
signal on_deposit_resource(amount: int)

var balance: Dictionary

func spawn_worker():
	emit_signal("on_spawn_unit", "Worker", global_position + Vector2(100,0))

func spawn_soldier():
	var cost = int(balance["Soldier"]["build_cost"])
	# In MVP, cost isn't deducted; use game.spend() if wired
	emit_signal("on_spawn_unit", "Soldier", global_position + Vector2(120,20))

func deposit(amount: int):
	emit_signal("on_deposit_resource", amount)
