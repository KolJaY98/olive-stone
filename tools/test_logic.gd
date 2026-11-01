extends SceneTree
# Headless logic test for v3: placement rules, economy upkeep, trade, army, save/load.
# Run: godot --headless --path . --script tools/test_logic.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func run_days(s, n: int) -> void:
	for i in range(n):
		s._advance_day()


func place(s, type: String, near: Vector3, radius_cells: int = 6) -> Variant:
	var cls := str(s.BUILDINGS[type]["cls"])
	for r in range(0, radius_cells + 1):
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
	var s = load("res://scenes/main.tscn").instantiate()
	root.add_child(s)
	await process_frame
	await process_frame
	s.start_screen.visible = false
	s._sync_menu_open()
	print("== start")
	check(s.survivors.size() == 5, "5 survivors")
	check(not s.menu_open, "game running after start screen closed")
	for k in s.resources:
		s.resources[k] = 400.0
	s.level = 3

	print("== placement")
	var w = place(s, "Well", s.camp_pos)
	check(w != null, "well placed near camp")
	check(absf(w.pos.y - s._height_at_world(w.pos.x, w.pos.z)) < 40.0, "building sits on terrain height")
	var fd_inland: String = s._place_problem(0, 0, "L", "Fishing Dock")
	check(fd_inland != "", "fishing dock refused inland: " + fd_inland)
	var far: String = s._place_problem(13, 0, "S", "Shack")
	check(far.find("حدود") >= 0, "outside territory refused")
	# a road westward extends territory to the coast
	var x: float = s.camp_pos.x
	while s._coast_tiles(x, s.camp_pos.z) > 0.9:
		var key := Vector2i(int(floor(x / s.TRAIL_CELL)), int(floor(s.camp_pos.z / s.TRAIL_CELL)))
		s.roads[key] = s.ROAD_DIRT
		x -= s.TRAIL_CELL
	s._rebuild_road_meshes()
	var dock = null
	for gx in range(-12, -3):
		for gz in range(-3, 4):
			if dock == null and s._place_problem(gx, gz, "L", "Fishing Dock") == "":
				var p = s._create_dynamic_plot(gx, gz, "L")
				dock = s._spawn_building("Fishing Dock", p.idx, 1.0, true)
	check(dock != null, "fishing dock placeable on the shore after a road reaches it")
	check(s._speed_at(Vector3(s.camp_pos.x - 60.0, 0, s.camp_pos.z)) > 1.3, "walking is faster on a road")
	# zoning forbids a pen inside a residential zone
	var zc: Vector2i = s._world_to_grid(s.camp_pos.x, s.camp_pos.z + 260.0)
	for dx in range(-1, 3):
		s.zones[zc + Vector2i(dx, 0)] = 1
	var pen_prob: String = s._place_problem(zc.x, zc.y, "M", "Pen")
	check(pen_prob.find("ممنوع") >= 0, "pen refused in residential zone")
	var tent_prob: String = s._place_problem(zc.x, zc.y, "S", "Tent")
	check(tent_prob == "" or tent_prob.find("مشغول") >= 0, "tent allowed in residential zone: " + tent_prob)

	print("== land value & coverage")
	s._update_land_value()
	var lv_camp: float = s._get_land_value(0, 0)
	run_days(s, 3)
	check(absf(s._get_land_value(0, 0) - lv_camp) < 0.01, "land value does not accumulate day after day (%.1f)" % lv_camp)
	var mosque = place(s, "Mosque", s.camp_pos + Vector3(150, 0, 0))
	check(mosque != null, "mosque placed")
	s._update_land_value()
	check(s._get_land_value(0, 0) > lv_camp, "mosque raises nearby land value")
	s._apply_service_coverage()
	check(s.coverage_morale > 0.0, "mosque coverage gives morale (%.2f)" % s.coverage_morale)

	print("== economy upkeep")
	for k in s.resources:
		s.resources[k] = 0.0
	s.resources["Food"] = 100.0
	s.resources["Water"] = 100.0
	var farm = place(s, "Farm", s.camp_pos + Vector3(-200, 0, 150))
	check(farm != null, "farm placed")
	s._pay_daily_costs()
	check(farm.active, "farm active when water for irrigation exists")
	s.resources["Water"] = 0.0
	s._pay_daily_costs()
	check(not farm.active, "farm stops without irrigation water")
	var fsrc = null
	for src in s.sources:
		if src.building == farm:
			fsrc = src
	check(fsrc != null and fsrc.slots == 0, "stopped farm accepts no workers")
	s.cur_season = 3
	s.resources["Wood"] = 0.0
	var res: Dictionary = s._pay_daily_costs()
	check(res["cold"], "winter without firewood is cold")
	s.cur_season = 0

	print("== trade")
	for k in s.resources:
		s.resources[k] = 200.0
	s.discovered_villages.append(0)
	s._vstate(0)
	var d0: float = s.resources["Dinar"]
	s._do_trade(0, "sell", 0)
	check(s.resources["Dinar"] > d0, "selling to a village earns Dinar")
	check(s.trades_done == 1, "trade counted for goal")
	s._close_all_modals()
	for i in range(5):
		s._do_trade(0, "sell", 0)
		s._close_all_modals()
	var used: Dictionary = s._vstate(0)["used"]
	check(int(used.get("sell0", 0)) == s.TRADE_STOCK, "daily stock limits repeated sales")
	s.village_state[0]["rel"] = 60.0
	var mk = place(s, "Market", s.camp_pos + Vector3(0, 0, -200))
	check(mk != null, "market placed")
	s._sign_contract(0, "export", 0)
	s._close_all_modals()
	check(s.contracts.size() == 1, "export contract signed")
	var before: float = s.resources["Dinar"]
	run_days(s, 4)
	s._close_all_modals()
	check(s.resources["Dinar"] != before, "contract executed over days")

	print("== army")
	var bar = place(s, "Barracks", s.camp_pos + Vector3(220, 0, -150))
	check(bar != null, "barracks placed")
	for k in s.resources:
		s.resources[k] = 300.0
	s._recruit("guard")
	s._recruit("guard")
	s._recruit("archer")
	check(s._soldier_count() == 3, "3 soldiers recruited (%d)" % s._soldier_count())
	check(s._sum_jobs() <= s._worker_count(), "jobs never exceed civilian workers")
	var dfn: float = s._defense_total()
	check(dfn > 30.0, "defense counts army + militia (%.0f)" % dfn)
	s.raid_strength = 5.0
	var won0: int = s.raids_won
	s._resolve_raid()
	s._close_all_modals()
	check(s.raids_won == won0 + 1, "weak raid repelled")
	s.raid_strength = 9999.0
	var food0: float = s.resources["Food"]
	s._resolve_raid()
	s._close_all_modals()
	check(s.resources["Food"] < food0, "lost raid steals supplies")
	s._start_expedition()
	check(s.expedition_day > 0, "expedition started")
	s._resolve_expedition()
	s._close_all_modals()
	var away := 0
	for v in s.survivors:
		if v.away:
			away += 1
	check(away == 0, "soldiers return from expedition")

	print("== upgrades & demolish")
	for k in s.resources:
		s.resources[k] = 500.0
	s.level = 4
	s.inspected = w
	s._upgrade_pressed()
	check(w.lvl == 2, "well upgraded to level 2")
	var wsrc = null
	for src in s.sources:
		if src.building == w:
			wsrc = src
	check(wsrc.yield_amt > 4.0, "upgraded well yields more (%.1f)" % wsrc.yield_amt)
	var tent = place(s, "Tent", s.camp_pos + Vector3(-120, 0, -220))
	var tp = s.plots[tent.plot]
	var cells: Array = s._cells_for(tp.gx, tp.gz, tp.cls)
	s.inspected = tent
	s.demolish_armed = true
	s._demolish_pressed()
	var freed := true
	for c in cells:
		if s.occupied_cells.has(c):
			freed = false
	check(freed, "demolish frees the cells")

	print("== save / load roundtrip")
	var nb: int = s.buildings.size()
	var nroads: int = s.roads.size()
	var nzones: int = s.zones.size()
	var nsold: int = s._soldier_count()
	var lvls := 0
	for b in s.buildings:
		lvls += b.lvl
	s._write_save("user://test_save.json", true)
	s._load_game("user://test_save.json")
	s._close_all_modals()
	check(s.buildings.size() == nb, "buildings restored (%d/%d)" % [s.buildings.size(), nb])
	var lvls2 := 0
	for b in s.buildings:
		lvls2 += b.lvl
	check(lvls2 == lvls, "building levels restored")
	check(s.roads.size() == nroads, "roads restored")
	check(s.zones.size() == nzones, "zones restored")
	check(s._soldier_count() == nsold, "soldiers restored (%d/%d)" % [s._soldier_count(), nsold])
	check(s.contracts.size() == 1, "contracts restored")

	print("== long run (60 days, no crash)")
	for k in s.resources:
		s.resources[k] = 150.0
	for i in range(60 * 250):
		s._process(0.1)
		if s.menu_open:
			s._close_all_modals()
			s.menu_open = false
	print("  day=", s.day, " pop=", s.survivors.size(), " res=", s.resources)
	check(s.day >= 20 or s.game_over, "long simulation ran without script errors (day %d)" % s.day)
	print("== RESULT: ", "ALL PASSED" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails > 0 else 0)
