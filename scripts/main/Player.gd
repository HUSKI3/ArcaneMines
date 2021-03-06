extends KinematicBody2D

var vel = Vector2.ZERO
var speed = 5
var health = 10.0
var h_resource = preload("res://objects/heart.tscn")
var h = h_resource.instance()
var bh_resource = preload("res://objects/broken_heart.tscn")
var bh = bh_resource.instance()
var on_stairs = false

export var FRICTION = 500
onready var layer1 = get_node("/root/Node2D/ground/layer1")
onready var console  = get_node("/root/Node2D/Player/c/m/p/l")
onready var hurt  = get_node("/root/Node2D/Player/pain")
onready var died_text  = get_node("/root/Node2D/Player/c/died_text")
onready var sprite  = get_node("/root/Node2D/Player/p")
onready var inventory_node  = get_node("/root/Node2D/Player/c/inventory")     

signal moved
signal died
signal interact
signal open_inv

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
  inventory_node.hide()
  pass # Replace with function body.

func _upd_console(arg):
  # if console is more than 3 lines, flush
  console.text = '\n' + str(arg)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  # Handle inputs
  var input_vector = Vector2.ZERO
  input_vector.x = (Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")) * Global.get_delta(delta)
  input_vector.y = (Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")) * Global.get_delta(delta)
  input_vector = input_vector.normalized()
  
  # inventory handling, idfk how to do oneliners here
  if Input.is_action_just_pressed('inv_open'):
    if !inventory_node.visible:
      inventory_node.show() 
    else:
      inventory_node.hide()
  
  # Proc movement here
  if health > 0:
    move_and_collide(input_vector, FRICTION*delta)
    emit_signal("moved", global_position)
  
  #print(get_child(0).get_children())
  
  #if str(health) != get_child(5).get _child(0).text:
  #  get_child(4).get_child(0).text = str(health)
  #  print(get_child(5).get_child(0),get_child(5).get_child(0).text)
    
    
  if input_vector.x > 0:
    sprite.animation = 'walky'
    sprite.flip_h = false
  elif input_vector.x < 0:
    sprite.flip_h = true
    sprite.animation = 'walky'
  elif input_vector.y > 0:
    sprite.animation = 'walkx-down'
  elif input_vector.y < 0:
    sprite.animation = 'walkx-up'
  else:
    sprite.animation = 'default'
    
  
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
    5:
      if Input.is_action_just_pressed('interact'):
        emit_signal("interact",tile_id,cell)
      
  # Handle health
  var v = Vector2.ZERO
  v.x = 1
  v.y = 1
  if health > 0:
    h.set_position(v)
  else:
    h.hide()
    bh.set_position(v)
    if has_node("broken_heart"):
      add_child(bh)
    _upd_console(">Died")
    died_text.show()
    emit_signal("died")
    
  
  # Proc the current effects here
  for e in cur_effects:
    if cur_effects[e]['valid'] == true:
      if cur_effects[e]['time'] < 1:
        cur_effects[e]['valid'] = false
      cur_effects[e]['time'] -= 1
      health -= cur_effects[e]['dmg']
      hurt.restart()
