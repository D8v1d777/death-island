extends SceneTree
## Measure uncropped original vector cells on an expanded diagnostic canvas.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var bounds: Dictionary = {}
	for character in ["Dave", "Marie"]:
		for frame in 8:
			var key := "%s-%d" % [character, frame]
			var image := Image.new()
			var source := FileAccess.get_file_as_string(args[0].path_join(key + ".svg"))
			if image.load_svg_from_string(source) != OK:
				printerr("FAIL: cannot inspect " + key)
				quit(1)
				return
			var used := image.get_used_rect()
			if not used.has_area() or used.position.x <= 0 or used.end.x >= 512 or used.end.y >= 704:
				printerr("FAIL: diagnostic canvas too small: " + key)
				quit(1)
				return
			bounds[key] = [used.position.x - 128, used.position.y - 128, used.size.x, used.size.y]
	print("CELL_BOUNDS: " + JSON.stringify(bounds))
	quit()
