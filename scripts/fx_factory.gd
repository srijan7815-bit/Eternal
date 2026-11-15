extends RefCounted


static func make_frames(
	texture: Texture2D,
	frame_width: int,
	frame_height: int,
	animation_name: String,
	fps: float,
	loop_animation: bool
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop_animation)
	var columns := int(texture.get_width() / frame_width)
	for column in range(columns):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = texture
		atlas_frame.region = Rect2(column * frame_width, 0, frame_width, frame_height)
		frames.add_frame(animation_name, atlas_frame)
	return frames
