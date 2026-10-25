extends Area3D
class_name Obstacle

enum ObstacleType {
	SLIDE_BARRIER,
	JUMP_HURDLE,
	LANE_PILLAR
}

@export var obstacle_type: ObstacleType = ObstacleType.SLIDE_BARRIER
@export var damage_amount: float = 30.0
@export var speed_penalty: float = 12.0
@export var is_high_risk: bool = false

var has_hit_player: bool = false
var has_rewarded_slide: bool = false
var slide_detector: Area3D = null

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_setup_components()

func _setup_components() -> void:
	# If this is a slide barrier, add an underside detector area to reward clean slides!
	if obstacle_type == ObstacleType.SLIDE_BARRIER:
		slide_detector = Area3D.new()
		slide_detector.name = "SlideRewardZone"
		slide_detector.collision_layer = 0
		slide_detector.collision_mask = 2
		
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(3.0, 0.9, 1.5)
		col.shape = box
		col.position = Vector3(0, 0.45, 0) # On the ground beneath the barrier
		slide_detector.add_child(col)
		add_child(slide_detector)
		
		slide_detector.body_entered.connect(_on_slide_zone_entered)

func _on_body_entered(body: Node3D) -> void:
	if has_hit_player:
		return
	if body.is_in_group("player"):
		has_hit_player = true
		var warning_text = ""
		match obstacle_type:
			ObstacleType.SLIDE_BARRIER:
				warning_text = "BARRIER COLLISION! PRESS [S] TO SLIDE"
			ObstacleType.JUMP_HURDLE:
				warning_text = "HAZARD IMPACT! PRESS [SPACE] TO JUMP"
			ObstacleType.LANE_PILLAR:
				warning_text = "WALL CRASH! SWITCH LANES [A/D]"
		
		if body.has_method("take_hit"):
			body.take_hit(damage_amount, speed_penalty, warning_text)
			
		# Impact visual feedback: shake or flash
		_visual_impact_flash()

func _on_slide_zone_entered(body: Node3D) -> void:
	if has_hit_player or has_rewarded_slide:
		return
	if body.is_in_group("player"):
		if body.has_method("is_sliding_active") and body.is_sliding_active():
			has_rewarded_slide = true
			if body.has_method("register_perfect_slide"):
				body.register_perfect_slide()

func _visual_impact_flash() -> void:
	var mesh: MeshInstance3D = null
	for child in get_children():
		if child is MeshInstance3D:
			mesh = child
			break
	if not mesh:
		return
	var orig_mat = mesh.get_surface_override_material(0)
	if not orig_mat:
		orig_mat = mesh.material_override
	var flash_mat = StandardMaterial3D.new()
	flash_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1.0, 0.2, 0.2)
	mesh.material_override = flash_mat
	
	var tween = create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func(): if is_instance_valid(mesh): mesh.material_override = orig_mat)
