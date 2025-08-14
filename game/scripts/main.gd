extends Node2D

@onready var units_root: Node2D = $Units
@onready var props_root: Node2D = $Props
@onready var ui_layer: CanvasLayer = $UI

var balance = {}
var roe = {}
var scenario = {}
var selected: Array = []
var selection_start := Vector2.ZERO
var selecting := false
var resources := 0
var civilians_risk := 0
var objectives_captured := 0
var objective_nodes: Array = []

const UNIT_SCENE := preload("res://scenes/Unit.tscn")
const HQ_SCENE := preload("res://scenes/HQ.tscn")
const RESOURCE_SCENE := preload("res://scenes/Resource.tscn")
const ENEMY_SPAWNER_SCENE := preload("res://scenes/EnemySpawner.tscn")

func _ready():
	load_data()
	setup_world()
	get_viewport().gui_release_focus()
	print("Frontlines RTS running. Tap-drag to select, tap to move; UI buttons at top-left.")

func load_data():
	var f = FileAccess.open("res://../design/units.json", FileAccess.READ)
	balance = JSON.parse_string(f.get_as_text())
	f = FileAccess.open("res://../design/roe.json", FileAccess.READ)
	roe = JSON.parse_string(f.get_as_text())
	f = FileAccess.open("res://../design/scenario_northern_corridor.json", FileAccess.READ)
	scenario = JSON.parse_string(f.get_as_text())

func setup_world():
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.12,0.15,0.18,1)
	bg.size = Vector2(scenario.map_size[0], scenario.map_size[1])
	add_child(bg)
	bg.move_to_front()
	
	# Objectives
	for pos in scenario.objectives:
		var o = ColorRect.new()
		o.size = Vector2(40,40)
		o.position = Vector2(pos[0]-20, pos[1]-20)
		o.color = Color(0.6,0.65,0.9,0.5)
		props_root.add_child(o)
		objective_nodes.append(o)
	
	# HQ
	var hq = HQ_SCENE.instantiate()
	hq.position = Vector2(scenario.hq_position[0], scenario.hq_position[1])
	add_child(hq)
	hq.balance = balance
	hq.on_spawn_unit.connect(_on_spawn_unit)
	hq.on_deposit_resource.connect(_on_deposit)
	
	# Resources
	for pos in scenario.resources:
		var r = RESOURCE_SCENE.instantiate()
		r.position = Vector2(pos[0], pos[1])
		add_child(r)
	
	# Player start units
	for utype in scenario.start_units.keys():
		for pos in scenario.start_units[utype]:
			var u = UNIT_SCENE.instantiate()
			u.unit_type = utype
			u.position = Vector2(pos[0], pos[1])
			u.is_enemy = false
			u.setup_from_balance(balance[utype])
			units_root.add_child(u)
	
	# Enemy spawners
	for sp in scenario.enemy_spawners:
		var s = ENEMY_SPAWNER_SCENE.instantiate()
		s.position = Vector2(sp.pos[0], sp.pos[1])
		s.interval = sp.interval
		s.balance = balance
		add_child(s)
		s.spawn_enemy.connect(_on_spawn_enemy)
	
	update_ui()

func _process(delta):
	# Victory check: capture by proximity
	var captured = 0
	for o in objective_nodes:
		for u in units_root.get_children():
			if u is Node2D and not u.is_enemy and u.global_position.distance_to(o.global_position + o.size*0.5) < 100:
				captured += 1
				break
	objectives_captured = captured
	update_ui()

func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.pressed
		var pos = event.position if event is InputEventScreenTouch else event.position
		if event is InputEventScreenTouch and pressed or (event is InputEventMouseButton and pressed and event.button_index == MOUSE_BUTTON_LEFT):
			selecting = true
			selection_start = pos
		elif selecting and ((event is InputEventScreenTouch and not pressed) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not pressed)):
			selecting = false
			perform_selection(Rect2(selection_start, pos - selection_start))
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and pressed:
			command_move_all(pos)
	elif event is InputEventScreenDrag:
		pass

func perform_selection(rect: Rect2):
	selected.clear()
	rect = rect.abs()
	for u in units_root.get_children():
		if u is Node2D and not u.is_enemy:
			if rect.has_point(u.global_position):
				selected.append(u)
	update_ui()

func command_move_all(pos: Vector2):
	for u in selected:
		if "set_target" in u:
			u.set_target(pos)

func _draw():
	if selecting:
		var rect = Rect2(selection_start, get_viewport().get_mouse_position() - selection_start).abs()
		draw_rect(rect, Color(0.3,0.7,1,0.2), true)
		draw_rect(rect, Color(0.3,0.7,1,1), false, 2)

func _on_spawn_unit(utype: String, pos: Vector2):
	if utype in balance:
		var u = UNIT_SCENE.instantiate()
		u.unit_type = utype
		u.position = pos
		u.is_enemy = false
		u.setup_from_balance(balance[utype])
		units_root.add_child(u)

func _on_spawn_enemy(enemy_node):
	units_root.add_child(enemy_node)

func _on_deposit(amount: int):
	resources += amount
	update_ui()

func spend(cost: int) -> bool:
	if resources >= cost:
		resources -= cost
		update_ui()
		return true
        return false

func update_ui():
	var txt = "Res: %d   Selected: %d   Obj: %d/3" % [resources, selected.size(), objectives_captured]
	if not ui_layer.has_node("Label"):
		var l = Label.new()
		l.name = "Label"
		l.theme_type_variation = "Header"
		l.position = Vector2(10, 10)
		ui_layer.add_child(l)
	ui_layer.get_node("Label").text = txt
