extends Control
class_name HUD

@onready var speed_label: Label = $TopLeft/Card/Margin/VBox/SpeedHBox/SpeedLabel
@onready var speed_bar: ProgressBar = $TopLeft/Card/Margin/VBox/SpeedBar
@onready var energy_bar: ProgressBar = $TopLeft/Card/Margin/VBox/EnergyBar
@onready var energy_label: Label = $TopLeft/Card/Margin/VBox/EnergyHBox/EnergyLabel
@onready var shields_container: HBoxContainer = $TopLeft/Card/Margin/VBox/ShieldsHBox/PipsContainer
var dash_bar: ProgressBar = null   # created at runtime — see _ready
var dash_label: Label = null        # created at runtime — see _ready

@onready var score_label: Label = $TopRight/Card/Margin/VBox/ScoreLabel
@onready var distance_label: Label = $TopRight/Card/Margin/VBox/DistanceLabel
@onready var multiplier_label: Label = $TopRight/Card/Margin/VBox/MultiplierLabel

@onready var feedback_label: Label = $CenterContainer/FeedbackLabel
@onready var game_over_panel: PanelContainer = $GameOverModal
@onready var final_score_label: Label = $GameOverModal/VBox/FinalScoreLabel
@onready var final_dist_label: Label = $GameOverModal/VBox/FinalDistLabel
@onready var final_reason_label: Label = $GameOverModal/VBox/ReasonLabel
@onready var retry_button: Button = $GameOverModal/VBox/RetryButton

@onready var pause_modal: PanelContainer = $PauseModal
@onready var resume_button: Button = $PauseModal/VBox/ResumeButton
@onready var pause_retry_button: Button = $PauseModal/VBox/PauseRetryButton

var feedback_tween: Tween = null

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if pause_modal:
		pause_modal.visible = false
	if feedback_label:
		feedback_label.modulate.a = 0.0
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if pause_retry_button:
		pause_retry_button.pressed.connect(_on_retry_pressed)
	_build_dash_indicator()

func _build_dash_indicator() -> void:
	## Append a compact dash-cooldown row to the existing TopLeft HUD card.
	var vbox: VBoxContainer = get_node_or_null("TopLeft/Card/Margin/VBox")
	if not vbox:
		return
	
	# Row label
	var lbl := Label.new()
	lbl.name = "DashLabel"
	lbl.text = "DASH // READY"
	lbl.add_theme_color_override("font_color", Color(0.15, 0.95, 1.0))
	lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl)
	dash_label = lbl
	
	# Cooldown bar
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.07, 0.09, 0.12, 0.95)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.12, 0.88, 0.98, 1.0)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	
	var bar := ProgressBar.new()
	bar.name = "DashBar"
	bar.custom_minimum_size = Vector2(230, 6)
	bar.max_value = 1.0
	bar.value = 1.0  # starts full = ready
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(bar)
	dash_bar = bar

func update_speed(current: float, max_s: float) -> void:
	if speed_label:
		speed_label.text = "VELOCITY // %.1f M/S" % current
	if speed_bar:
		speed_bar.max_value = max_s
		speed_bar.value = current

func update_energy(current: float, max_e: float) -> void:
	if energy_label:
		energy_label.text = "BOOST CORE // %d%%" % int(current)
	if energy_bar:
		energy_bar.max_value = max_e
		energy_bar.value = current

func update_dash_cooldown(ratio: float) -> void:
	## ratio: 0.0 = ready (full bar), 1.0 = just dashed (empty bar)
	if dash_bar:
		dash_bar.value = 1.0 - ratio  # bar drains to 0 then refills
	if dash_label:
		if ratio <= 0.0:
			dash_label.text = "DASH // READY"
			dash_label.modulate = Color(0.15, 0.95, 1.0)
		else:
			var pct := int((1.0 - ratio) * 100.0)
			dash_label.text = "DASH // %d%%" % pct
			dash_label.modulate = Color(0.45, 0.55, 0.65)

func update_shields(current: int, max_s: int) -> void:
	if not shields_container:
		return
	for child in shields_container.get_children():
		child.queue_free()
		
	for i in range(max_s):
		var pip = Panel.new()
		pip.custom_minimum_size = Vector2(28, 12)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 2
		style.corner_radius_top_right = 2
		style.corner_radius_bottom_left = 2
		style.corner_radius_bottom_right = 2
		if i < current:
			style.bg_color = Color(0.12, 0.88, 0.98) # Electric cyan active shield
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.4, 0.95, 1.0)
		else:
			style.bg_color = Color(0.12, 0.14, 0.18, 0.6) # Depleted dark slot
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.2, 0.22, 0.28, 0.4)
		pip.add_theme_stylebox_override("panel", style)
		shields_container.add_child(pip)

func update_multiplier(mult: float) -> void:
	if not multiplier_label:
		return
	var rank_text = "FLOW 1.0x"
	var col = Color(0.18, 0.82, 0.98)
	if mult >= 3.5:
		rank_text = "MAX FLOWSTATE"
		col = Color(1.0, 0.25, 0.3)
	elif mult >= 2.5:
		rank_text = "FLOW x%.1f [TIER S]" % mult
		col = Color(1.0, 0.75, 0.15)
	elif mult >= 1.8:
		rank_text = "FLOW x%.1f [TIER A]" % mult
		col = Color(0.2, 1.0, 0.6)
	elif mult >= 1.2:
		rank_text = "FLOW x%.1f [TIER B]" % mult
		col = Color(0.25, 0.88, 1.0)
	else:
		rank_text = "FLOW x%.1f" % mult
		
	multiplier_label.text = rank_text
	multiplier_label.modulate = col

func update_score(score: int, dist: float) -> void:
	if score_label:
		score_label.text = "SCORE // %07d" % score
	if distance_label:
		distance_label.text = "DIST // %.0f M" % dist

func show_feedback(text: String, col: Color) -> void:
	if not feedback_label:
		return
	if feedback_tween:
		feedback_tween.kill()
		
	feedback_label.text = text
	feedback_label.modulate = col
	feedback_label.scale = Vector2(1.15, 1.15)
	
	feedback_tween = create_tween().set_parallel(true)
	feedback_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(feedback_label, "modulate:a", 1.0, 0.08)
	feedback_tween.chain().tween_property(feedback_label, "modulate:a", 0.0, 0.5).set_delay(0.6)

func show_game_over(reason: String, score: int, dist: float) -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if final_reason_label:
		final_reason_label.text = reason
	if final_score_label:
		final_score_label.text = "FINAL SCORE: %d" % score
	if final_dist_label:
		final_dist_label.text = "DISTANCE: %.0f METERS" % dist

func set_paused(paused: bool) -> void:
	if pause_modal:
		pause_modal.visible = paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	if pause_modal:
		pause_modal.visible = false

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
