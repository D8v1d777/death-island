extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	print("DIAGNOSTIC: Starting character rendering test...")
	
	# Load the actual game
	GameManagerGlobal.new_game()
	while GameManagerGlobal.is_loading:
		await get_tree().process_frame
	
	var player = GameManagerGlobal.get_player()
	var world = GameManagerGlobal.world
	
	print("DIAGNOSTIC: Player:", player)
	print("DIAGNOSTIC: World:", world)
	print("DIAGNOSTIC: Player illustration:", player.illustration)
	print("DIAGNOSTIC: Player illustration body:", player.illustration.body)
	
	if player.illustration.body:
		var body = player.illustration.body
		print("DIAGNOSTIC: Body visible:", body.visible)
		print("DIAGNOSTIC: Body visible in tree:", body.is_visible_in_tree())
		print("DIAGNOSTIC: Body global position:", body.global_position)
		print("DIAGNOSTIC: Body global transform:", body.global_transform)
		print("DIAGNOSTIC: Body rotation:", body.rotation)
		print("DIAGNOSTIC: Body hframes:", body.hframes)
		print("DIAGNOSTIC: Body vframes:", body.vframes)
		print("DIAGNOSTIC: Body frame:", body.frame)
		print("DIAGNOSTIC: Body texture:", body.texture)
		if body.texture:
			print("DIAGNOSTIC: Texture size:", body.texture.get_width(), "x", body.texture.get_height())
		print("DIAGNOSTIC: Body modulate:", body.modulate)
		print("DIAGNOSTIC: Body pixel_size:", body.pixel_size)
		print("DIAGNOSTIC: Body billboard:", body.billboard)
		print("DIAGNOSTIC: Body shaded:", body.shaded)
		
		# Check camera
		var camera = player.camera
		print("DIAGNOSTIC: Camera global position:", camera.global_position)
		print("DIAGNOSTIC: Camera global transform:", camera.global_transform)
		print("DIAGNOSTIC: Camera forward:", -camera.global_transform.basis.z)
		print("DIAGNOSTIC: Camera projection:", camera.projection)
		print("DIAGNOSTIC: Camera size:", camera.size)
		
		# Check sprite basis
		print("DIAGNOSTIC: Sprite global basis:", body.global_transform.basis)
		print("DIAGNOSTIC: Sprite forward (local -Z):", -body.global_transform.basis.z)
		print("DIAGNOSTIC: Sprite up (local +Y):", body.global_transform.basis.y)
		
		# Distance from camera to sprite
		var dist = camera.global_position.distance_to(body.global_position)
		print("DIAGNOSTIC: Camera to sprite distance:", dist)
		
		# Check if sprite is in camera frustum
		var to_sprite = (body.global_position - camera.global_position).normalized()
		var cam_forward = -camera.global_transform.basis.z
		var dot = to_sprite.dot(cam_forward)
		print("DIAGNOSTIC: Camera-to-sprite dot with camera forward:", dot)
		
		# Check if sprite faces camera
		var sprite_normal = -body.global_transform.basis.z  # Sprite faces -Z locally
		var dot2 = sprite_normal.dot(cam_forward)
		print("DIAGNOSTIC: Sprite normal dot camera forward:", dot2)
	
	# Check an enemy
	var enemy = world.get_node("boar_shore") as Enemy
	if enemy:
		print("\nDIAGNOSTIC: Enemy _body:", enemy._body)
		if enemy._body:
			print("DIAGNOSTIC: Enemy body visible:", enemy._body.visible)
			print("DIAGNOSTIC: Enemy body texture:", enemy._body.texture)
			if enemy._body.texture:
				print("DIAGNOSTIC: Enemy texture size:", enemy._body.texture.get_width(), "x", enemy._body.texture.get_height())
			print("DIAGNOSTIC: Enemy body hframes:", enemy._body.hframes)
			print("DIAGNOSTIC: Enemy body frame:", enemy._body.frame)
			print("DIAGNOSTIC: Enemy body rotation:", enemy._body.rotation)
			print("DIAGNOSTIC: Enemy body global pos:", enemy._body.global_position)
	
	# Capture screenshot from root viewport
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	if image:
		image.save_png("user://diagnostic_root.png")
		print("DIAGNOSTIC: Saved root viewport screenshot")
	else:
		print("DIAGNOSTIC: No root viewport image captured")
	
	get_tree().quit()
