extends Panel

export(Global.SlotType) var slotType = Global.SlotType.SLOT_DEFAULT;

var slotIndex;
var item = null;
var style;

func _init():
  mouse_filter = Control.MOUSE_FILTER_PASS;
  rect_min_size = Vector2(20, 20);
  style = StyleBoxFlat.new();
  refreshColors();
  style.set_border_width_all(1);
  style.border_color = Color("#2e2e2e");
  set('custom_styles/panel', style);
  print('Loaded panel!')

func setItem(newItem):
  add_child(newItem);
  item = newItem;
  item.itemSlot = self;
  refreshColors();

func pickItem():
  item.pickItem();
  remove_child(item);
  get_tree().get_root().add_child(item);
  item = null;
  refreshColors();

func putItem(newItem):
  print('Tried to load item into panel...')
  item = newItem;
  item.itemSlot = self;
  item.putItem();
  get_tree().get_root().remove_child(item);
  add_child(item);
  refreshColors();

func removeItem():
  remove_child(item);
  item = null;
  refreshColors();

func equipItem(newItem, rightClick =  true):
  item = newItem;
  item.itemSlot = self;
  item.putItem();
  if !rightClick:
    get_tree().get_root().remove_child(item);
  add_child(item);
  refreshColors();

func refreshColors():
  if item:
    style.bg_color = Color("#4d4d4d");
  else:
    style.bg_color = Color("#4d4d4d");
