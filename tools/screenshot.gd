extends SceneTree
# Renders the game and saves screenshots (needs a real display/GPU, not --headless).
# Usage (from project root):  godot --path . --resolution 1600x720 --script tools/screenshot.gd
# Output: build/shots/*.png

var out := ""


func snap(name: String) -> void:
	for i in range(8):
		await process_frame
	root.get_texture().get_image().save_png(out + name + ".png")
	print("saved ", name)


func place(s, type: String, near: Vector3) -> Variant:
	var cls := str(s.BUILDINGS[type]["cls"])
	for r in range(0, 8):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var a: Vector2i = s._anchor_from_world(near.x, near.z, cls) + Vector2i(dx, dz)
				if s._place_problem(a.x, a.y, cls, type) == "":
					var p = s._create_dynamic_plot(a.x, a.y, cls)
					return s._spawn_building(type, p.idx, 1.0, true)
	return null


func _init() -> void:
	out = ProjectSettings.globalize_path("res://build/shots/")
	DirAccess.make_dir_recursive_absolute(out)
	var s = load("res://scenes/main.tscn").instantiate()
	root.add_child(s)
	for i in range(20):
		await process_frame
	await snap("01_start_screen")
	s.start_screen.visible = false
	s._sync_menu_open()
	for i in range(40):
		s._process(0.1)
	await snap("02_first_day")
	for k in s.resources:
		s.resources[k] = 600.0
	s.level = 4
	s.day = 34
	var c: Vector3 = s.camp_pos
	# roads: a cross through the camp and one toward the coast
	for k in range(-14, 15):
		s.roads[Vector2i(int(floor((c.x + k * 26.0) / 26.0)), int(floor((c.z + 120.0) / 26.0)))] = 2 if absi(k) < 6 else 1
		s.roads[Vector2i(int(floor((c.x + 120.0) / 26.0)), int(floor((c.z + k * 26.0) / 26.0)))] = 1
	s._rebuild_road_meshes()
	for gx in range(-3, 0):
		for gz in range(-4, -1):
			s.zones[Vector2i(gx, gz)] = 1
	for gx2 in range(3, 6):
		for gz2 in range(1, 4):
			s.zones[Vector2i(gx2, gz2)] = 3
	var list := [["Mosque", Vector3(-60, 0, -140)], ["Stone House", Vector3(-200, 0, -230)], ["Small House", Vector3(-120, 0, -260)],
		["Large House", Vector3(-260, 0, -120)], ["Market", Vector3(200, 0, -60)], ["Well", Vector3(60, 0, 60)],
		["Farm", Vector3(-250, 0, 220)], ["Barracks", Vector3(330, 0, -230)], ["Watchtower", Vector3(380, 0, 40)],
		["Workshop", Vector3(330, 0, 200)], ["Quarry", Vector3(400, 0, 320)], ["Woodcutter", Vector3(240, 0, 330)],
		["Plaza", Vector3(30, 0, -250)], ["Clinic", Vector3(-30, 0, 260)], ["Diwan", Vector3(160, 0, 230)],
		["Wall", Vector3(470, 0, -100)], ["Olive Press", Vector3(-380, 0, 30)], ["Pen", Vector3(-140, 0, 360)]]
	for e in list:
		var b = place(s, e[0], c + e[1])
		if b != null and (e[0] == "Mosque" or e[0] == "Market"):
			b.lvl = 3
			s._apply_level_visual(b)
	s._update_land_value()
	s.discovered_villages.append_array([0, 2, 5])
	for i in [0, 2, 5]:
		s._vstate(i)
	s.village_state[0]["rel"] = 62.0
	s._show_territory(false)
	for i in range(300):
		s._process(0.1)
	s._close_all_modals()
	await snap("03_city")
	s.camera.size = 420.0
	await snap("04_city_close")
	s.camera.size = 700.0
	s._toggle_sheet("build")
	await snap("05_build_home")
	s._set_build_tab("def")
	await snap("06_build_def")
	s._toggle_sheet("build")
	for zc in [Vector2i(-1, 2), Vector2i(0, 2), Vector2i(-1, 3), Vector2i(0, 3)]:
		s.zones[zc] = 2
	s._toggle_sheet("plan")
	s._set_plan_mode("zone_1")
	await snap("07_plan_zones")
	s._set_plan_mode("zone_1")
	s._toggle_lv_overlay()
	await snap("08_land_value")
	s._toggle_lv_overlay()
	s._toggle_sheet("plan")
	s._start_placing("Stone House")
	s._update_ghost_placement(c + Vector3(380, 0, 260))
	await snap("09_place_refused")
	s._update_ghost_placement(c + Vector3(-90, 0, -330))
	await snap("10_place_ok")
	s._cancel_placement()
	s._advance_day()
	s._close_all_modals()
	s._toggle_sheet("economy")
	await snap("11_economy")
	s._toggle_sheet("economy")
	s._recruit("guard")
	s._recruit("guard")
	s._recruit("archer")
	s._toggle_sheet("army")
	await snap("12_army")
	s._toggle_sheet("army")
	s._toggle_sheet("villages")
	await snap("13_villages")
	s._toggle_sheet("villages")
	s._open_trade(0)
	await snap("14_trade")
	s._close_all_modals()
	s.council_unlocked = true
	s._show_council_panel()
	await snap("15_diwan")
	s._close_all_modals()
	s.raid_strength = 60.0
	s._start_raid()
	s.menu_open = false
	for i in range(40):
		s._process(0.1)
	await snap("16_raid")
	for i in range(200):
		s._process(0.1)
		if s._modal_open():
			break
	await snap("17_battle_report")
	s._close_all_modals()
	s._toggle_sheet("workers")
	await snap("18_workers")
	s._toggle_sheet("workers")
	root.content_scale_factor = 1.3
	await snap("19_large_text")
	quit()
