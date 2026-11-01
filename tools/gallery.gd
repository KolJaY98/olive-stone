extends SceneTree
# Renders every building type in a grid for visual QA: godot --path . --resolution 1600x720 --script tools/gallery.gd
func _init() -> void:
	var out := ProjectSettings.globalize_path("res://build/shots/")
	DirAccess.make_dir_recursive_absolute(out)
	var s = load("res://scenes/main.tscn").instantiate()
	root.add_child(s)
	for i in range(10):
		await process_frame
	s.start_screen.visible = false
	s._sync_menu_open()
	s.ui_root.visible = false
	var types: Array = s.BUILDINGS.keys()
	var cols := 6
	for i in range(types.size()):
		var t: String = types[i]
		var cls := str(s.BUILDINGS[t]["cls"])
		var gx := (i % cols) * 3 - 8
		var gz := (i / cols) * 3 - 5
		var p = s._create_dynamic_plot(gx, gz, cls)
		var b = s._spawn_building(t, p.idx, 1.0, true, 0.0, 1)
		var l := Label3D.new()
		l.text = t
		l.font_size = 48
		l.pixel_size = 0.8
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = b.pos + Vector3(0, 120, 0)
		s.add_child(l)
	var c: Vector3 = s.camp_pos
	for shot in [[Vector3(-350, 0, -260), 520.0, "g1"], [Vector3(150, 0, -260), 520.0, "g2"], [Vector3(-350, 0, 120), 520.0, "g3"], [Vector3(150, 0, 120), 520.0, "g4"], [Vector3(0, 0, 0), 300.0, "g5_camp"]]:
		s.camera_target = c + shot[0]
		s.camera.size = shot[1]
		s._update_camera()
		for k in range(8):
			await process_frame
		root.get_texture().get_image().save_png(out + str(shot[2]) + ".png")
	quit()
