extends SceneTree
## Use Godot's real decoder, without extra image dependencies or modifying pixels.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1:
		printerr("FAIL: expected gallery directory")
		quit(1)
		return
	var folder := arguments[0]
	var manifest: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(folder.path_join("gallery.json"))
	)
	if not manifest is Dictionary or not manifest.get("captures") is Array:
		printerr("FAIL: invalid gallery manifest")
		quit(1)
		return
	var digests: Dictionary = {}
	for entry in manifest.captures:
		var image := Image.new()
		if (
			image.load(folder.path_join(str(entry.file))) != OK
			or image.get_size() != Vector2i(1280, 720)
		):
			printerr("FAIL: invalid gallery image: " + str(entry.file))
			quit(1)
			return
		var colors: Dictionary = {}
		for y in range(0, 720, 24):
			for x in range(0, 1280, 32):
				colors[image.get_pixel(x, y).to_rgba32()] = true
		var hash_context := HashingContext.new()
		hash_context.start(HashingContext.HASH_SHA256)
		hash_context.update(image.get_data())
		var digest := hash_context.finish().hex_encode()
		if colors.size() < 16 or digests.has(digest):
			printerr("FAIL: blank or duplicate decoded image: " + str(entry.file))
			quit(1)
			return
		digests[digest] = true
	if digests.size() != 6:
		printerr("FAIL: unexpected decoded gallery count")
		quit(1)
		return
	print("IMAGE DECODE: six valid, nonblank, distinct 1280x720 captures")
	quit(0)
