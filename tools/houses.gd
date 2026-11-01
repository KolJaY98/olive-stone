extends SceneTree
# Close-ups for visual QA: housing ladder, dusk window glow, planning bar.
func _init() -> void:
	var out := ProjectSettings.globalize_path("res://build/shots/")
	var s = load("res://scenes/main.tscn").instantiate()
	root.add_child(s)
	for i in range(8):
		await process_frame
	s.start_screen.visible = false
	s._sync_menu_open()
	var c: Vector3 = s.camp_pos
	var spots := [["Shack", Vector2i(-6, -5)], ["Small House", Vector2i(-4, -5)], ["Stone House", Vector2i(-2, -6)], ["Large House", Vector2i(1, -7)]]
	for e in spots:
		var cls := str(s.BUILDINGS[e[0]]["cls"])
		var p = s._create_dynamic_plot(e[1].x, e[1].y, cls)
		s._spawn_building(e[0], p.idx, 1.0, true, 0.0, 1)
	s.ui_root.visible = false
	s.camera_target = c + Vector3(-160, 0, -360)
	s.camera.size = 300.0
	s._update_camera()
	for k in range(10):
		await process_frame
	root.get_texture().get_image().save_png(out + "h1_houses.png")
	s.day_timer = s.DAY_LENGTH * 0.97
	s.paused = false
	s.menu_open = false
	s._process(0.0)
	for k in range(10):
		await process_frame
	root.get_texture().get_image().save_png(out + "h2_dusk.png")
	s.day_timer = s.DAY_LENGTH * 0.4
	s.ui_root.visible = true
	s.camera.size = 700.0
	s.camera_target = c
	s._update_camera()
	s._toggle_sheet("plan")
	s._set_plan_mode("road_dirt")
	for k in range(10):
		await process_frame
	root.get_texture().get_image().save_png(out + "h3_plan_bar.png")
	s._plan_done()
	s._start_rain(10.0)
	for k in range(30):
		s._process(0.05)
		await process_frame
	root.get_texture().get_image().save_png(out + "h4_rain.png")
	quit()
