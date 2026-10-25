extends Area3D
class_name RiskGate

@export var risk_lane_index: int = 1 # 1 = Right, -1 = Left
var has_triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if has_triggered:
		return
	if body.is_in_group("player"):
		has_triggered = true
		if body.has_method("notify_risk_sector"):
			body.notify_risk_sector(risk_lane_index)
