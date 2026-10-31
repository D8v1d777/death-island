extends Node
## Short, bounded desktop-renderer sample. Never represents target-phone performance.

const SAMPLE_FRAMES := 60


func _ready() -> void:
	SaveManagerGlobal.save_directory = "user://performance-probe-saves/"
	call_deferred("_run")


func _run() -> void:
	var start := Time.get_ticks_msec()
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	var ready_ms := Time.get_ticks_msec() - start
	Engine.max_fps = 0
	for index in 10:
		await RenderingServer.frame_post_draw
	var times: Array[float] = []
	var previous := Time.get_ticks_usec()
	var draws := 0
	var textures := 0
	var memory_start := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	for index in SAMPLE_FRAMES:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		times.append((now - previous) / 1000.0)
		previous = now
		draws = maxi(
			draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		)
		textures = maxi(textures, int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))
	times.sort()
	var folder := OS.get_environment("DEATH_ISLAND_CAPTURE_DIR")
	var file := FileAccess.open(folder.path_join("performance.json"), FileAccess.WRITE)
	if not file:
		printerr("FAIL: cannot save performance sample")
		get_tree().quit(1)
		return
	file.store_string(
		JSON.stringify(
			{
				"engine": Engine.get_version_info().string,
				"adapter": RenderingServer.get_video_adapter_name(),
				"method":
				"Desktop OpenGL, stationary Wreckshore; 10 warmup + 60 uncapped wall-clock frames",
				"world_ready_ms_not_cold_launch": ready_ms,
				"sample_frames": times.size(),
				"wall_frame_ms_p50": times[ceili(SAMPLE_FRAMES * 0.5) - 1],
				"wall_frame_ms_p95": times[ceili(SAMPLE_FRAMES * 0.95) - 1],
				"wall_frame_ms_p99": times.back(),
				"draw_calls_max": draws,
				"texture_memory_bytes_max": textures,
				"static_memory_bytes_start": memory_start,
				"static_memory_bytes_end": int(Performance.get_monitor(Performance.MEMORY_STATIC))
			},
			"\t"
		)
	)
	file.close()
	GameManagerGlobal.request_quit_to_main_menu()
	for index in 2:
		await get_tree().process_frame
	SaveManagerGlobal.delete_save(SaveManagerGlobal.AUTOSAVE_SLOT)
	print("PERFORMANCE: 60 real-renderer frames recorded")
	get_tree().quit(0)
