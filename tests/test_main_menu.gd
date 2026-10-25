extends SceneTree

func _init() -> void:
	print("--- BEGIN MAIN MENU VERIFICATION TEST ---")
	var menu_scene = load("res://scenes/main_menu.tscn")
	assert(menu_scene != null, "Main menu scene failed to load!")
	
	var menu_instance = menu_scene.instantiate()
	root.add_child(menu_instance)
	assert(menu_instance is MainMenu, "Main menu instance is not MainMenu script class!")
	
	var play_button = menu_instance.find_child("PlayButton", true, false)
	assert(play_button != null, "PlayButton must exist in MainMenu!")
	
	var how_to_play_button = menu_instance.find_child("HowToPlayButton", true, false)
	assert(how_to_play_button != null, "HowToPlayButton must exist in MainMenu!")
	
	var quit_button = menu_instance.find_child("QuitButton", true, false)
	assert(quit_button != null, "QuitButton must exist in MainMenu!")
	
	var modal = menu_instance.find_child("HowToPlayModal", true, false)
	assert(modal != null, "HowToPlayModal must exist in MainMenu!")
	assert(not modal.visible, "HowToPlayModal must initially be hidden!")
	
	# Test opening modal
	menu_instance._on_how_to_play_pressed()
	assert(modal.visible, "HowToPlayModal must be visible after _on_how_to_play_pressed!")
	
	# Test closing modal
	menu_instance._on_back_pressed()
	assert(not modal.visible, "HowToPlayModal must be hidden after _on_back_pressed!")
	
	print("✔ Main menu nodes, buttons, and modal interactions verified.")
	print("ALL MAIN MENU CHECKS PASSED SUCCESSFULLY!")
	quit(0)
