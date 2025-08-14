extends Node2D

@export var unit_type: String = "Worker"
@export var is_enemy := false
@export var texture_path := "res://assets/unit_worker.png"

var hp := 50
var speed := 120.0
var sight := 200.0
var attack := 0.0
var attack_range := 0.0
var attack_cooldown := 0.0
var gather_rate := 0.0
var carry := 0
var target: Vector2 = Vector2.ZERO
var has_target := false
var cooldown := 0.0
var carrying := 0
var home_hq: Node = null

func _ready():
	var tex_path = texture_path
	if unit_type == "Soldier":
		tex_path = "res://assets/unit_soldier.png"
	elif unit_type == "Enemy":
		tex_path = "res://assets/unit_enemy.png"
	$Sprite.texture = load(tex_path)
	add_to_group("units")

func setup_from_balance(b: Dictionary):
	if b.has("hp"): hp = b.hp
	if b.has("speed"): speed = float(b.speed)
	if b.has("sight"): sight = float(b.sight)
	if b.has("attack"): attack = float(b.attack)
	if b.has("attack_range"): attack_range = float(b.attack_range)
	if b.has("attack_cooldown"): attack_cooldown = float(b.attack_cooldown)
	if b.has("gather_rate"): gather_rate = float(b.gather_rate)
	if b.has("carry"): carry = int(b.carry)

func set_target(p: Vector2):
	target = p
	has_target = true

func _process(delta):
	if has_target:
		var dir = (target - global_position)
		var dist = dir.length()
		if dist > 4.0:
			global_position += dir.normalized() * speed * delta
		else:
			has_target = false
	# simple auto-attack if soldier/enemy
	cooldown = max(cooldown - delta, 0.0)
	if attack > 0.0 and cooldown <= 0.0:
		var nearest = _nearest_enemy()
		if nearest and global_position.distance_to(nearest.global_position) <= attack_range:
			nearest.take_damage(attack)
			cooldown = attack_cooldown

func _nearest_enemy():
	var best = null
	var best_d = 1e9
	for u in get_tree().get_nodes_in_group("units"):
		if u == self: continue
		if is_enemy != u.is_enemy:
			var d = global_position.distance_to(u.global_position)
			if d < best_d:
				best_d = d
				best = u
	return best

func take_damage(dmg: float):
	hp -= dmg
	if hp <= 0:
		queue_free()
