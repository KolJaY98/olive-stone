extends SceneTree
# Balance check: a simple scripted player builds, staffs jobs, trades and defends for 90 days.
# Run: godot --headless --path . --script tools/balance_sim.gd

const ORDER := ["Well", "Shack", "Woodcutter", "Storehouse", "Farm", "Small House", "Small Quarry", "Kitchen", "Barracks",
	"Market", "Watchtower", "Small House", "Mosque", "Stone House", "Pen", "Olive Press", "Diwan",
	"Quarry", "Workshop", "Clinic", "Stone House", "Plaza", "Large House", "School", "Wall", "Wall", "Large House"]


func try_build(s, type: String) -> bool:
	var def: Dictionary = s.BUILDINGS[type]
	if int(def["lv"]) > s.level or s._missing_resource(def["cost"]) != "":
		return false
	var cls := str(def["cls"])
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				if s._place_problem(dx, dz, cls, type) == "":
					for k in def["cost"]:
						s.resources[k] = float(s.resources[k]) - float(def["cost"][k])
					var p = s._create_dynamic_plot(dx, dz, cls)
					s._spawn_building(type, p.idx, 0.0, false)
					s._assign_tasks()
					return true
	return false


func staff_jobs(s) -> void:
	var w: int = s._worker_count()
	var cons: Dictionary = s._compute_consumption()
	var want := {"Food": 0, "Water": 0, "Wood": 0, "Stone": 0, "Scrap": 0, "Oil": 0}
	if s._has_done("Olive Press") and w > 6:
		want["Oil"] = 1
		w -= 1
	var order := ["Food", "Water", "Wood", "Stone", "Food", "Wood", "Water", "Stone", "Scrap", "Food", "Wood", "Stone"]
	var left := w
	var i := 0
	while left > 0 and i < 60:
		var r: String = order[i % order.size()]
		i += 1
		var use := maxf(0.5, float(cons.get(r, 0.0)))
		var days := float(s.resources[r]) / use
		var cap := 40.0 if (r == "Food" or r == "Water") else 999.0
		if days > cap and r != "Wood" and r != "Stone":
			continue
		want[r] = int(want[r]) + 1
		left -= 1
	s.jobs = want
	s._clamp_jobs()
	s._assign_tasks()


func _init() -> void:
	var s = load("res://scenes/main.tscn").instantiate()
	root.add_child(s)
	await process_frame
	await process_frame
	s.start_screen.visible = false
	s._sync_menu_open()
	s.workers_opened = true
	var step := 0
	var last_day := 0
	var min_food_days := 999.0
	var lv_days := {}
	print("day pop lvl  food water wood stone scrap oil dinar | morale def  W/L  bld")
	while s.day < 90 and not s.game_over and step < 90 * 260:
		step += 1
		s._process(0.1)
		if s._modal_open():
			s._close_all_modals()
		if s.day != last_day:
			last_day = s.day
			var under := 0
			for b in s.buildings:
				if not b.done:
					under += 1
			if under == 0:
				for t in ORDER:
					if s._count_type(t) < ORDER.count(t) and try_build(s, t):
						break
			staff_jobs(s)
			if s.day == 2:
				for k in range(6):
					s.roads[Vector2i(int(floor((s.camp_pos.x + 40.0 + k * 26.0) / 26.0)), int(floor(s.camp_pos.z / 26.0)))] = 1
				s._rebuild_road_meshes()
				s.zones[Vector2i(0, -3)] = 1
				s.zones[Vector2i(1, -3)] = 1
				s._check_goals()
			if s.level >= 2 and s.day % 6 == 0:
				for b in s.buildings:
					if b.done and b.lvl < 3 and s.level >= s._upgrade_req_level(b) and s._missing_resource(s._upgrade_cost(b)) == "":
						s.inspected = b
						s._upgrade_pressed()
						s._close_inspect()
						break
			if s.day > 6 and not s.exploring and s.discovered_villages.size() < 3:
				s._on_explore_pressed()
			for vi in s.discovered_villages:
				var v: Dictionary = s.VILLAGES[vi]
				for j in range(v["buys"].size()):
					var res := str(v["buys"][j]["res"])
					if float(s.resources[res]) > 90.0:
						s._do_trade(vi, "sell", j)
						s._close_all_modals()
			var want_soldiers := clampi(s.day / 10, 0, s._barracks_capacity())
			while s._soldier_count() < want_soldiers and s._missing_resource(s.UNITS["guard"]["cost"]) == "":
				var n0: int = s._soldier_count()
				s._recruit("guard")
				if s._soldier_count() == n0:
					break
			if not lv_days.has(s.level):
				lv_days[s.level] = s.day
			var fdays := float(s.resources["Food"]) / maxf(0.5, float(s._compute_consumption()["Food"]))
			min_food_days = minf(min_food_days, fdays)
			if s.day % 5 == 0:
				var r: Dictionary = s.resources
				print("%3d %3d %2d  %4d %4d %4d %4d %4d %3d %4d | %3d %4d  %d/%d  %d" % [s.day, s.survivors.size(), s.level,
					int(r["Food"]), int(r["Water"]), int(r["Wood"]), int(r["Stone"]), int(r["Scrap"]), int(r["Oil"]), int(r["Dinar"]),
					int(s.morale), int(s._defense_total()), s.raids_won, s.raids_lost, s.buildings.size()])
	print("END day=", s.day, " game_over=", s.game_over, " pop=", s.survivors.size(), " level=", s.level, " goal=", s.goal_index, "/", s.GOALS.size(), " min_food_days=", snappedf(min_food_days, 0.1))
	var types := {}
	for b in s.buildings:
		types[b.type] = int(types.get(b.type, 0)) + 1
	print("buildings: ", types)
	print("level reached on day: ", lv_days, "  xp=", int(s.xp))
	print("unpaid: ", s.unpaid_notes)
	quit()
