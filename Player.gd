extends KinematicBody2D

var vel = Vector2.ZERO
var speed = 5
var health = 10.0
var h_resource = preload("assets/heart.tscn")
var h = h_resource.instance()
var bh_resource = preload("assets/broken_heart.tscn")
var bh = bh_resource.instance()
var on_stairs = false

export var FRICTION = 500
onready var layer1 = get_node("/root/Node2D/ground/layer1")
onready var console  = get_node("/root/Node2D/Player/c/m/p/l")
onready var hurt  = get_node("/root/Node2D/Player/pain")
onready var died_text  = get_node("/root/Node2D/Player/c/died_text")

signal moved

# Effects
var cur_effects = {
	'poison':{
		'valid':false, # if an effect is valid
		'time':2,      # Ticks for the effect
		'dmg':0.1      # Damage for the given effect
	},
}


# Called when the node enters the scene tree for the first time.
func _ready():
	print('/Character loaded')
	var v = Vector2.ZERO
	v.x = 1
	v.y = 1
	h.set_position(v)
	add_child(h)
	died_text.hide()
	pass # Replace with function body.

func _upd_console(arg):
	# if console is more than 3 lines, flush
	console.text = '\n' + str(arg)

func _physics_process(delta):
	# Handle inputs
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	# If a dialogue here
	if Input.is_action_just_pressed('ui_accept') && on_stairs:
		_upd_console('cum')
	
	# Proc movement here
	move_and_collide(input_vector, FRICTION*delta)
	emit_signal("moved", global_position)
	
	# Check collision
	var cell = layer1.world_to_map(global_position)
	var tile_id = layer1.get_cellv(cell)
	#print(name,global_position,tile_id)
	match tile_id:
		1:
			# Grass...
			_upd_console(">Grass\n>Congratz! You finally touched some grass!")
		2:
			# Touched a poisonous flower
			_upd_console(">Flower\n>Smells nice... Oh shit, that's poison")
			cur_effects['poison']['valid'] = true
			cur_effects['poison']['time'] = 2
		3:
			# Dungeon here!
			_upd_console(">A dark staircase\n>Enter?")
			on_stairs = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Handle health
	var v = Vector2.ZERO
	v.x = 1
	v.y = 1
	if health > 5:
		h.set_position(v)
	else:
		h.hide()
		bh.set_position(v)
		if has_node("broken_heart"):
			add_child(bh)
		_upd_console(">Died")
		died_text.show()
	
	# Proc the current effects here
	for e in cur_effects:
		if cur_effects[e]['valid'] == true:
			if cur_effects[e]['time'] < 1:
				cur_effects[e]['valid'] = false
			cur_effects[e]['time'] -= 1
			health -= cur_effects[e]['dmg']
			hurt.restart()
