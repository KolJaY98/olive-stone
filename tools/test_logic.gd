extends SceneTree
func _init() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var counts := {}
	for s in scene.sources:
		counts[s.res] = int(counts.get(s.res, 0)) + 1
	print("pop=", scene.survivors.size(), " cap=", scene._housing_capacity(), " sources=", counts, " jobs=", scene.jobs, " level=", scene.level)
	var near := 1e9
	for s in scene.sources:
		near = minf(near, scene._flat_dist(s.pos, scene.camp_pos))
	print("nearest resource point from camp: ", int(near), " units")
	var tasks := {}
	for v in scene.survivors:
		tasks[v.task + ":" + v.job] = int(tasks.get(v.task + ":" + v.job, 0)) + 1
	print("tasks=", tasks)
	# terrace flatness under every plot
	var worst := 0.0
	for p in scene.plots:
		for ox in [-0.5, 0.5]:
			for oz in [-0.5, 0.5]:
				var h: float = scene._height_at_world(p.pos.x + ox * p.size.x, p.pos.z + oz * p.size.y)
				worst = maxf(worst, absf(h - scene.plateau_h))
	print("max height deviation under plots: ", snappedf(worst, 0.01))
	# economy: 6 days with default jobs, nothing built
	var start: Dictionary = scene.resources.duplicate()
	for i in range(720):
		scene._process(0.1)
	print("after 6 days: day=", scene.day, " res=", scene.resources, " xp=", snappedf(scene.xp, 0.1), " level=", scene.level, " pop=", scene.survivors.size())
	print("last_income=", scene.last_income)
	# no passive growth
	for r in ["Food", "Water", "Wood", "Stone", "Scrap"]:
		scene.jobs[r] = 0
	scene._assign_tasks()
	for i in range(240):
		scene._process(0.1)
	var w0: float = scene.resources["Wood"]
	for i in range(240):
		scene._process(0.1)
	print("no jobs -> wood unchanged: ", w0 == scene.resources["Wood"])
	scene.jobs = {"Food": 1, "Water": 1, "Wood": 1, "Stone": 1, "Scrap": 0}
	scene._assign_tasks()
	# locked building and plot rules
	scene._card_pressed("Farm")
	print("farm at level ", scene.level, ": placing=", scene.selected_building, " toast=", scene.toast_label.text)
	# build well + tent on level-1 plots
	scene.resources["Wood"] = 200.0
	scene.resources["Stone"] = 200.0
	scene.resources["Scrap"] = 50.0
	scene._card_pressed("Well")
	print("well ghost plot=", scene.ghost_plot)
	scene._confirm_build()
	scene._card_pressed("Tent")
	print("tent ghost plot=", scene.ghost_plot)
	scene._confirm_build()
	scene._card_pressed("Tent")
	print("third small building with no free plot: selected='", scene.selected_building, "' toast=", scene.toast_label.text)
	for i in range(600):
		scene._process(0.1)
	var done := 0
	for b in scene.buildings:
		if b.done: done += 1
	print("built ", done, "/", scene.buildings.size(), " cap=", scene._housing_capacity(), " level=", scene.level, " xp=", snappedf(scene.xp, 0.1), " goal=", scene.goal_index)
	# level up unlocks
	scene._add_xp(500.0)
	var open_plots := 0
	for p in scene.plots:
		if p.lv <= scene.level: open_plots += 1
	print("after xp boost: level=", scene.level, " open plots=", open_plots)
	scene.resources["Wood"] = 300.0
	scene.resources["Stone"] = 300.0
	scene._card_pressed("Farm")
	print("farm ghost plot=", scene.ghost_plot, " cls=", scene.plots[scene.ghost_plot].cls)
	scene._confirm_build()
	scene._card_pressed("Storehouse")
	scene._confirm_build()
	for i in range(900):
		scene._process(0.1)
	var users := 0
	for s in scene.sources:
		if s.building != null:
			users += scene._source_users(s, null)
	print("buildings=", scene.buildings.size(), " workers at building points=", users, " pop=", scene.survivors.size())
	# inspect & demolish farm
	var farm = null
	for b in scene.buildings:
		if b.type == "Farm": farm = b
	scene._inspect_building(farm)
	scene._demolish_pressed()
	scene._demolish_pressed()
	print("after demolish: buildings=", scene.buildings.size(), " plot free=", scene.plots[farm.plot].building == null)
	# tap on an empty plot and on a building
	var p0 = scene.plots[2]
	scene._on_tap(scene.camera.unproject_position(p0.pos))
	print("tap empty plot toast: ", scene.toast_label.text)
	# save / load
	scene._save_game()
	var nb: int = scene.buildings.size()
	var lv: int = scene.level
	scene._load_game("user://olive_stone_save.json")
	print("load: buildings ", nb, "->", scene.buildings.size(), " level ", lv, "->", scene.level, " plots linked=", scene.plots[0].building != null)
	for i in range(60):
		scene._process(0.1)
	# game over
	scene.resources["Food"] = 0.0
	scene.resources["Water"] = 0.0
	for r in ["Food", "Water", "Wood", "Stone", "Scrap"]:
		scene.jobs[r] = 0
	scene._assign_tasks()
	var guard := 0
	while not scene.game_over and guard < 4000:
		scene._process(0.5)
		guard += 1
	print("game over=", scene.game_over, " day=", scene.day, " text=", scene.over_label.text)
	quit()
