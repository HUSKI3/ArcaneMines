extends Node

func get_delta(delta: float) -> float:
  return 1 / ((1 / delta) / 60)


enum SlotType {
  SLOT_DEFAULT = 0
}
