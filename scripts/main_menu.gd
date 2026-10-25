extends Control
class_name MainMenu

# ============================================================
# OVERDRIVE — Futuristic Main Menu & Start Screen
# ============================================================

@onready var main_menu_vbox: VBoxContainer = $CenterContainer/MenuCard/Margin/VBox
@onready var play_button: Button = $CenterContainer/MenuCard/Margin/VBox/PlayButton
@onready var how_to_play_button: Button = $CenterContainer/MenuCard/Margin/VBox/HowToPlayButton
@onready var quit_button: Button = $CenterContainer/MenuCard/Margin/VBox/QuitButton

@onready var how_to_play_modal: PanelContainer = $HowToPlayModal
@onready var back_button: Button = $HowToPlayModal/Margin/VBox/BackButton
@onready var fade_rect: ColorRect = $FadeOverlay

var is_transitioning: bool = false

func _ready() -> void:
	_ensure_nodes()
	if how_to_play_modal:
		how_to_play_modal.visible = false
	if fade_rect:
		fade_rect.modulate.a = 1.0
		var tween = create_tween()
		if tween:
			tween.tween_property(fade_rect, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
		if play_button.is_inside_tree():
			play_button.grab_focus()
	if how_to_play_button and not how_to_play_button.pressed.is_connected(_on_how_to_play_pressed):
		how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

func _ensure_nodes() -> void:
	if not how_to_play_modal:
		how_to_play_modal = get_node_or_null("HowToPlayModal")
	if not main_menu_vbox:
		main_menu_vbox = get_node_or_null("CenterContainer/MenuCard/Margin/VBox")
	if not play_button:
		play_button = get_node_or_null("CenterContainer/MenuCard/Margin/VBox/PlayButton")
	if not how_to_play_button:
		how_to_play_button = get_node_or_null("CenterContainer/MenuCard/Margin/VBox/HowToPlayButton")
	if not quit_button:
		quit_button = get_node_or_null("CenterContainer/MenuCard/Margin/VBox/QuitButton")
	if not back_button:
		back_button = get_node_or_null("HowToPlayModal/Margin/VBox/BackButton")
	if not fade_rect:
		fade_rect = get_node_or_null("FadeOverlay")

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if how_to_play_modal and how_to_play_modal.visible:
				_on_back_pressed()
			else:
				_on_play_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if how_to_play_modal and how_to_play_modal.visible:
				_on_back_pressed()
				get_viewport().set_input_as_handled()

func _on_play_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(_start_game)
	else:
		_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_how_to_play_pressed() -> void:
	_ensure_nodes()
	if how_to_play_modal:
		how_to_play_modal.visible = true
	if main_menu_vbox:
		main_menu_vbox.get_parent().get_parent().visible = false
	if back_button and back_button.is_inside_tree():
		back_button.grab_focus()

func _on_back_pressed() -> void:
	_ensure_nodes()
	if how_to_play_modal:
		how_to_play_modal.visible = false
	if main_menu_vbox:
		main_menu_vbox.get_parent().get_parent().visible = true
	if play_button and play_button.is_inside_tree():
		play_button.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
