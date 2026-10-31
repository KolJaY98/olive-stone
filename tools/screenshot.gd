extends SceneTree
# Renders the game and saves screenshots (needs a real display/GPU, not --headless).
# Usage (from project root):  godot --path . --resolution 1280x720 --script tools/screenshot.gd
# Output: user:// folder (see OS.get_user_data_dir() printed below).

func snap(name: String) -> void:
	for i in range(6):
		await process_frame
	var path := OS.get_user_data_dir() + "/" + name + ".png"
	root.get_texture().get_image().save_png(path)
	print("saved ", path)

func _init() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	for i in range(20):
		await process_frame
	for i in range(60):
		scene._process(0.1)
	await snap("shot_start")
	scene._toggle_sheet("build")
	await snap("shot_build")
	scene._toggle_sheet("build")
	scene._start_placing("Tent")
	await snap("shot_place")
	scene._cancel_placement()
	scene.resources["Wood"] = 500.0
	scene.resources["Stone"] = 500.0
	scene.resources["Scrap"] = 100.0
	scene._add_xp(800.0)
	for e in [["Well", 0], ["Tent", 1], ["Storehouse", 4], ["Farm", 7], ["Olive Grove", 8], ["Stone House", 5], ["Workshop", 6], ["Quarry", 9]]:
		scene._start_placing(e[0])
		scene._set_ghost_plot(e[1])
		scene._confirm_build()
	for i in range(2500):
		scene._process(0.1)
	await snap("shot_city")
	scene._toggle_sheet("workers")
	await snap("shot_workers")
	quit()
