extends Panel

var slots = [];

func _init():
  slots.resize(512);
  slots.insert(Global.SlotType.SLOT_DEFAULT, get_node("/root/Node2D/Player/c/bottom_panel/grid/Panel"));
  slots.insert(Global.SlotType.SLOT_DEFAULT, get_node("/root/Node2D/Player/c/bottom_panel/grid/Panel2"));
  slots.insert(Global.SlotType.SLOT_DEFAULT, get_node("/root/Node2D/Player/c/bottom_panel/grid/Panel3"));
  slots.insert(Global.SlotType.SLOT_DEFAULT, get_node("/root/Node2D/Player/c/bottom_panel/grid/Panel4"));
  slots.insert(Global.SlotType.SLOT_DEFAULT, get_node("/root/Node2D/Player/c/bottom_panel/grid/Panel5"));
  print('Slots', slots)

func getSlotByType(type):
  return slots[type];

func getItemByType(type):
  return slots[type].item;
