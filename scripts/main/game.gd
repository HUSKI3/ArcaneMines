extends Node

onready var layer0 = get_node("/root/Node2D/ground/layer0")
onready var layer1 = get_node("/root/Node2D/ground/layer1")
onready var inventory_ui = get_node("/root/Node2D/Player/c/UI/inv")
onready var console  = get_node("/root/Node2D/Player/c/m/p/l")
onready var plist  = get_node("/root/Node2D/Player/c/m2/p/plc/pl")
onready var players_source  = get_node("/root/Node2D/players_source")
onready var inv_labels  = get_node("/root/Node2D/Player/c/UI/labels")
onready var inventory_node  = get_node("/root/Node2D/Player/c/inventory")     

onready var dirt = layer0.tile_set.find_tile_by_name('dirt')
onready var grass = layer0.tile_set.find_tile_by_name('grass')
onready var flower = layer0.tile_set.find_tile_by_name('flower')
onready var down = layer0.tile_set.find_tile_by_name('down')
onready var tree = layer0.tile_set.find_tile_by_name('tree')

var player_resource = preload("res://objects/player.tscn")
var player_instance = player_resource.duplicate()

const itemImages = [
  preload("res://assets/gfx/items/sword.png"),
  preload("res://assets/gfx/block/wood.png")
];

onready var itemDictionary = {
  'wood_sword': {
    "itemName": "Wooden Sword",
    "itemValue": 0,
    "itemIcon": itemImages[0],
    "slotType": Global.SlotType.SLOT_DEFAULT
  },
  'wood': {
  "itemName": "Wood",
  "itemValue": 0,
  "itemIcon": itemImages[1], 
  "slotType": Global.SlotType.SLOT_DEFAULT
   }
};

export (int) var uuid

var old_pos
var players = []
var players_obj = {}
var inventory = {
  items:[]
}

# The URL we will connect to
export var websocket_url = "ws://nexo.fun:8080"
var _client = WebSocketClient.new()


onready var tile_types = {
  'dirt': dirt,
  'grass': grass,
  'flower': flower,
  'down': down,
  'tree': tree
}

onready var items = {
  'wood': tree
 }

# Called when the node enters the scene tree for the first time.
func _ready():
  print('/Loaded tile data')

  
  # Connect base signals to get notified of connection open, close, and errors.
  _client.connect("connection_closed", self, "_closed")
  _client.connect("connection_error", self, "_closed")
  _client.connect("connection_established", self, "_connected")
  # This signal is emitted when not using the Multiplayer API every time
  # a full packet is received.
  # Alternatively, you could check get_peer(1).get_available_packets() in a loop.
  _client.connect("data_received", self, "_on_data")
  
  # Initiate connection to the given URL.
  var err = _client.connect_to_url(websocket_url)
  if err != OK:
    print("Unable to connect")
    set_process(false)
  
  # Signals
  get_node("Player").connect("moved", self, "_send_movement")
  get_node("Player").connect("died", self, "_died")
  get_node("Player").connect("interact", self, "_interact")
  
    
func _upd_console(arg):
  # if console is more than 3 lines, flush
  if len(console.text.split('\n')) > 3:
    var new = console.text.split('\n')
    console.text = ''
    new.remove(0)
    for x in new:
      console.text += '\n' + str(x)
  else:
    console.text += '\n' + str(arg)
    
  
func _died():
  var pl = '{"call":"player.died", "uuid":%s}' % uuid
  _client.get_peer(1).put_packet(pl.to_utf8())

# Called when the HTTP request is completed.
func _load_map(body):
  var response = body
  #_upd_console('--> Got map data')
  # Load layer0
  #_upd_console('... Loading layer0')
  for coord in response.layer0.tiles:
    layer0.set_cell( coord.x, coord.y, tile_types[coord.type])
  #_upd_console('??? Loaded layer0')
  #_upd_console('... Loading layer1')
  for coord in response.layer1.tiles:
    layer1.set_cell( coord.x, coord.y, tile_types[coord.type], 1)
  #_upd_console('??? Loaded layer1')
  #_upd_console('??????')

###############################################
###############################################


func _closed(was_clean = false):
  # was_clean will tell you if the disconnection was correctly notified
  # by the remote peer before closing the socket.
  print("Closed, clean: ", was_clean)
  set_process(false)

func _connected(proto = ""):
  # Once we asre connected, ask the server for map data
  print("Connected with protocol: ", proto)
  var c = '{"call":"map.get_map", "uuid":%s}' % uuid
  _client.get_peer(1).put_packet(c.to_utf8())
  var pl = '{"call":"world.get_players", "uuid":%s}' % uuid
  _client.get_peer(1).put_packet(pl.to_utf8())
  

func _on_data():
  var raw = _client.get_peer(1).get_packet().get_string_from_utf8().replace("'",'"')
  #print(raw)
  var data =  parse_json(raw)
  #print("Got data from server: ", data.type)
  
  if data.type == 'map_data':
    _load_map(data.body)
    
  elif data.type == 'world.join':
    print('Server says, player joined at uuid ',data.player)
    if data.player == uuid:
      print('Thats us...')
    elif !(data.player in players) && data.player != uuid:
      players.append(data.player)
      # We also want to spawn them in here
      var player_instance = player_resource.instance()
      var p = player_instance.duplicate()
      players_obj[data.player] = p
      players_source.add_child(p)
      _proc_players()
  
  elif data.type == 'player.moved':
    var v = Vector2.ZERO
    v.x = data.x
    v.y = data.y
    if data.player != uuid:
      players_obj[data.player].position = v
    
  elif data.type == 'world.players':
    for x in data.players:
      if !(x in players) && x != uuid:
        players.append(x)
        # We also want to spawn them in here
        var player_instance = player_resource.instance()
        var p = player_instance.duplicate()
        players_obj[x] = p
        players_source.add_child(p)
      _proc_players()
      
  elif data.type == 'world.remove_tile':
    layer1.set_cellv(Vector2(data.x,data.y), -1)
    
  elif data.type == 'world.give':
    # We want to sync the inventory here
    var pop = '{"call":"player.inventory", "uuid":'+str(uuid)+'}'
    _client.get_peer(1).put_packet(pop.to_utf8())
  
  elif data.type == 'self.inventory':
    inventory_node.reset()
    for item in data.inv:
      print(item)
      inventory_node._on_AddItemButton_pressed(itemDictionary[str(item)])
    

func _proc_players(remove=false):	
  var o = players
  plist.text = ''
  for line in o:
    if remove:
      if line == remove:
        print('Removed this guy')
      else:
        plist.text += '\n'+str(line)
    else:
      plist.text += '\n'+str(line)

func _process(delta):
  # Call this in _process or _physics_process. Data transfer, and signals
  # emission will only happen when calling this function.
  _client.poll()

func _send_movement(pos):
  if old_pos != pos:
    var pop = '{"call":"player.moved","x":'+str(pos.x)+', "y":'+str(pos.y)+', "uuid":'+str(uuid)+'}'
    _client.get_peer(1).put_packet(pop.to_utf8())
  old_pos = pos
  
func _interact(v,cell):
  var pop = '{"call":"world.touch_tile","tile":'+str(v)+\
  ', "uuid":'+str(uuid)+\
  ', "cell":{ "y":'+str(cell.y)+\
  ',"x": '+str(cell.x)+'}}'
  _client.get_peer(1).put_packet(pop.to_utf8())
