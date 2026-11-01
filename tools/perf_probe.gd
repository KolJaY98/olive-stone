extends SceneTree
# Render-load probe: a 20-building town with 25 villagers. godot --path . --resolution 1600x720 --script tools/perf_probe.gd
func _init():
	var s = load("res://scenes/main.tscn").instantiate()
	root.add_child(s)
	for i in range(6):
		await process_frame
	s.start_screen.visible = false
	s._sync_menu_open()
	for k in s.resources:
		s.resources[k] = 900.0
	s.level = 5
	var n := 0
	for t in ["Stone House", "Small House", "Large House", "Farm", "Market", "Mosque", "Woodcutter", "Quarry", "Barracks", "Storehouse", "Kitchen", "Clinic", "Olive Grove", "Workshop", "Plaza", "Tent", "Small House", "Stone House", "Well", "Diwan"]:
		var done := false
		for r in range(1, 7):
			for dx in range(-r, r + 1):
				for dz in range(-r, r + 1):
					if done or maxi(absi(dx), absi(dz)) != r:
						continue
					var cls := str(s.BUILDINGS[t]["cls"])
					if s._place_problem(dx, dz, cls, t) == "":
						var p = s._create_dynamic_plot(dx, dz, cls)
						var b = s._spawn_building(t, p.idx, 1.0, true)
						b.lvl = 3
						s._apply_level_visual(b)
						done = true
						n += 1
			if done:
				break
	for i in range(20):
		s._add_villager(s._new_name(), "Farming")
	s._assign_tasks()
	for i in range(60):
		s._process(0.1)
		await process_frame
	var t0 := Time.get_ticks_msec()
	for i in range(120):
		await process_frame
	var fps := 120000.0 / float(Time.get_ticks_msec() - t0)
	print("buildings=", n, " villagers=", s.survivors.size(), " objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " mac_fps=", snappedf(fps, 0.1), " nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var counts := {}
	for vi in s.find_children("*", "VisualInstance3D", true, false):
		var top: Node = vi
		while top.get_parent() != s and top.get_parent() != null:
			top = top.get_parent()
		var key: String = str(top.name) + ":" + vi.get_class()
		if top.get_parent() == s and top.name.begins_with("@"):
			key = "@" + top.get_class() + ":" + vi.get_class()
		counts[key] = int(counts.get(key, 0)) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	for k in keys.slice(0, 14):
		print("  ", k, " = ", counts[k])
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/shots/perf_town.png"))
	quit()
