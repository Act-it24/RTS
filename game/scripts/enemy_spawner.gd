extends Node2D
signal spawn_enemy(enemy)

@export var interval := 6.0
var timer := 0.0
var balance

const UNIT_SCENE := preload("res://scenes/Unit.tscn")

func _process(delta):
	timer += delta
	if timer >= interval:
		timer = 0.0
		var e = UNIT_SCENE.instantiate()
		e.unit_type = "Enemy"
		e.is_enemy = true
		e.setup_from_balance(balance["Enemy"])
		e.position = global_position + Vector2(randi()%40-20, randi()%40-20)
		emit_signal("spawn_enemy", e)
		e.set_target(Vector2(320,360))
