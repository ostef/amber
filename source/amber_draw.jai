#scope_file

#import "stb_image";

#scope_export

create_texture_from_file :: inline (filename : string, keep_bound := false) -> Texture_Handle #must
{
	width, height, channels : s32;
	data := stbi_load (clone_to_cstring (filename, TEMP), *width, *height, *channels, 4);
	if !data then return 0;
	
	return create_texture (xx width, xx height, 4, data, keep_bound);
}
@Amber_API

create_texture :: inline (width : u32, height : u32, channels : s64, data : *void, keep_bound := false) -> Texture_Handle #must
{
	result : Texture_Handle;
	glGenTextures (1, *result);
	glBindTexture (GL_TEXTURE_2D, result);
	source_format : GLenum;
	if channels ==
	{
	case 1;
		source_format = GL_RED;
	case 2;
		source_format = GL_RG;
	case 3;
		source_format = GL_RGB;
	case 4;
		source_format = GL_RGBA;
	case;
		assert (false, "Invalid channel count, expected 1, 2, 3 or 4, got %.", channels);
	}
	if channels == 1 then glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, source_format, GL_UNSIGNED_BYTE, data);
	if channels == 1 then glPixelStorei (GL_UNPACK_ALIGNMENT, 4);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	if !keep_bound
		glBindTexture (GL_TEXTURE_2D, 0);

	return result;
}
@Amber_API

destroy_texture :: inline (texture : Texture_Handle)
{
	glDeleteTextures (1, *texture);
}
@Amber_API

create_framebuffer_and_texture :: inline (width : u32, height : u32, channels := 4) -> Framebuffer_Handle #must, Texture_Handle #must
{
	texture : Texture_Handle;
	glGenTextures (1, *texture);
	glBindTexture (GL_TEXTURE_2D, texture);
	defer glBindTexture (GL_TEXTURE_2D, 0);
	format : GLenum;
	if channels ==
	{
	case 1;
		format = GL_RED;
	case 2;
		format = GL_RG;
	case 3;
		format = GL_RGB;
	case 4;
		format = GL_RGBA;
	case;
		assert (false, "Invalid channel count, expected 1, 2, 3 or 4, got %.", channels);
	}
	if channels == 1 then glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	glTexImage2D (GL_TEXTURE_2D, 0, xx format, width, height, 0, format, GL_UNSIGNED_BYTE, null);
	if channels == 1 then glPixelStorei (GL_UNPACK_ALIGNMENT, 4);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

	framebuffer : Framebuffer_Handle;
	glGenFramebuffers (1, *framebuffer);
	glBindFramebuffer (GL_FRAMEBUFFER, framebuffer);
	defer glBindFramebuffer (GL_FRAMEBUFFER, 0);
	glFramebufferTexture2D (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);

	status := glCheckFramebufferStatus (GL_FRAMEBUFFER);
	if status != GL_FRAMEBUFFER_COMPLETE
	{
		glDeleteTextures (1, *texture);
		glDeleteFramebuffers (1, *framebuffer);
		
		return 0, 0;
	}
	
	return framebuffer, texture;
}
@Amber_API

destroy_framebuffer :: inline (framebuffer : Framebuffer_Handle)
{
	glDeleteFramebuffers (1, *framebuffer);
}
@Amber_API

destroy_framebuffer_and_texture :: inline (framebuffer : Framebuffer_Handle, texture : Texture_Handle)
{
	destroy_framebuffer (framebuffer);
	destroy_texture (texture);
}
@Amber_API

create_shader :: (vertex_src : string, fragment_src : string) -> Shader_Handle #must
{
	vso := glCreateShader (GL_VERTEX_SHADER);
	defer glDeleteShader (vso);
	glShaderSource (vso, 1, *clone_to_cstring (vertex_src, TEMP), null);
	glCompileShader (vso);

	fso := glCreateShader (GL_FRAGMENT_SHADER);
	defer glDeleteShader (fso);
	glShaderSource (fso, 1, *clone_to_cstring (fragment_src, TEMP), null);
	glCompileShader (fso);

	shader := glCreateProgram ();
	glAttachShader (shader, vso);
	glAttachShader (shader, fso);
	glLinkProgram (shader);
	success : s32;
	glGetProgramiv (shader, GL_LINK_STATUS, *success);

	if !success
	{
		info_log : [1024]u8;
		glGetProgramInfoLog (shader, info_log.count, null, info_log.data);
		println ("Could not link shader program:\n%", to_string (info_log));
		glDeleteProgram (shader);
		shader = 0;
	}

	return shader;
}
@Amber_API

destroy_shader :: (shader : Shader_Handle)
{
	glDeleteProgram (shader);
}
@Amber_API

Draw_Context :: struct
{
	MAX_VERTICES :: 10_000;

	is_drawing : bool;
	
	vertices : [MAX_VERTICES]Vertex;
	vertex_count : s64;
	clear_color : RGBA;
	
	clip_rect : Recti;
	use_clip_rect : bool;
	
	viewport    : Recti;
	texture     : Texture_Handle;
	framebuffer : Framebuffer_Handle;
	shader      : Shader_Handle;
}

DEFAULT_SHADER_HANDLE : Shader_Handle : 0;

#scope_file

default_shader : Shader_Handle;
vao, vbo : GLuint;

#scope_export

draw_context : Draw_Context;

check_drawing :: inline ()
{
	//assert (draw_context.is_drawing, "Called a drawing function before calling draw_begin.");
}

draw_init :: ()
{
	// Create shader
	{
		default_shader = create_shader (VERTEX_SHADER, FRAGMENT_SHADER);
		assert (default_shader != 0, "Could not load default shader.");
	}

	// Create vertex buffer
	{
		glGenVertexArrays (1, *vao);
		glBindVertexArray (vao);

		glGenBuffers (1, *vbo);
		glBindBuffer (GL_ARRAY_BUFFER, vbo);
		glBufferData (GL_ARRAY_BUFFER, Draw_Context.MAX_VERTICES * size_of (Vertex), null, GL_DYNAMIC_DRAW);

		glEnableVertexAttribArray (0);
		glVertexAttribPointer (0, 3, GL_FLOAT, GL_FALSE, size_of (Vertex), cast (*void) offset_of (Vertex, "position"));
		
		glEnableVertexAttribArray (1);
		glVertexAttribPointer (1, 2, GL_FLOAT, GL_FALSE, size_of (Vertex), cast (*void) offset_of (Vertex, "tex_coords"));
		
		glEnableVertexAttribArray (2);
		glVertexAttribPointer (2, 4, GL_UNSIGNED_BYTE, GL_TRUE, size_of (Vertex), cast (*void) offset_of (Vertex, "color"));
		
		glBindVertexArray (0);
		glBindBuffer (GL_ARRAY_BUFFER, 0);
	}

	draw_context.clear_color = RGBA_BLACK;
}

draw_begin :: ()
{
	assert (!draw_context.is_drawing, "Called draw_begin twice.");
	assert (draw_context.vertex_count == 0, "Called draw_begin before calling draw_flush.");
	using draw_context.clear_color;
	glClearColor (r / 255.0, g / 255.0, b / 255.0, a / 255.0);
	glClear (GL_COLOR_BUFFER_BIT);
	draw_context.is_drawing = true;
}

draw_flush :: ()
{
	ortho_proj :: inline (left : f32, right : f32, bottom : f32, top : f32, znear : f32, zfar : f32) -> [4][4]f32
	{
		result : [4][4]f32;
		result[0][0] = 2.0 / (right - left);
		result[3][0] = (right + left) / (left - right);
		result[1][1] = 2.0 / (top - bottom);
		result[3][1] = (top + bottom) / (bottom - top);
		result[2][2] = 2.0 / (znear - zfar);
		result[3][2] = (znear + zfar) / (znear - zfar);
		result[3][3] = 1.0;
		result[2][2] = result[2][2] * 0.5 + result[2][3] * 0.5;
		result[3][2] = result[3][2] * 0.4 + result[3][3] * 0.5;
		
		return result;
	}

	if draw_context.vertex_count == 0 then return;
	//assert (draw_context.is_drawing, "Called draw_flush before calling draw_begin.");

	shader := draw_context.shader;
	if !shader then shader = default_shader;
	glBindVertexArray (vao);
	defer glBindVertexArray (0);
	glBindBuffer (GL_ARRAY_BUFFER, vbo);
	defer glBindBuffer (GL_ARRAY_BUFFER, 0);
	glUseProgram (shader);
	defer glUseProgram (0);
	glBindTexture (GL_TEXTURE_2D, draw_context.texture);
	defer glBindTexture (GL_TEXTURE_2D, 0);
	glBindFramebuffer (GL_FRAMEBUFFER, draw_context.framebuffer);
	defer glBindFramebuffer (GL_FRAMEBUFFER, 0);
	
	viewport := draw_context.viewport;
	if draw_context.framebuffer == 0
	{
		size := platform_get_viewport_size ();
		viewport = recti (0, 0, size.x, size.y);
	}
	view_projection := ortho_proj (xx viewport.x1, xx viewport.x2, xx viewport.y2, xx viewport.y1, 0, 1);
	glViewport (viewport.x1, viewport.y1, xx rect_width (viewport), xx rect_height (viewport));
	glUniformMatrix4fv (glGetUniformLocation (shader, "u_View_Projection_Matrix"), 1, GL_FALSE, *view_projection[0][0]);
	glUniform1i (glGetUniformLocation (shader, "u_Use_Texture"), xx (draw_context.texture != 0));
	
	if draw_context.use_clip_rect
	{
		clip_rect := draw_context.clip_rect;
		glEnable (GL_SCISSOR_TEST);
		new_y1 := rect_height (viewport) - clip_rect.y2;
		new_y2 := rect_height (viewport) - clip_rect.y1;
		clip_rect.y1 = new_y1;
		clip_rect.y2 = new_y2;
		glScissor (xx clip_rect.x1, xx clip_rect.y1, xx rect_width (clip_rect), xx rect_height (clip_rect));
	}
	defer glDisable (GL_SCISSOR_TEST);
	glDisable (GL_DEPTH_TEST);
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glPolygonMode (GL_FRONT_AND_BACK, GL_LINE);

	glBufferSubData (GL_ARRAY_BUFFER, 0, size_of (Vertex) * draw_context.vertex_count, draw_context.vertices.data);
	glDrawArrays (GL_TRIANGLES, 0, xx draw_context.vertex_count);

	draw_context.vertex_count = 0;
}

draw_end :: ()
{
	assert (draw_context.is_drawing, "Called draw_end before calling draw_begin.");
	draw_flush ();
	draw_context.is_drawing = false;
}

draw_get_clear_color :: inline () -> RGBA #must
{
	return draw_context.clear_color;
}
@Amber_API

draw_set_clear_color :: inline (color : RGBA) -> RGBA
{
	previous := draw_context.clear_color;
	if previous != color then draw_flush ();
	draw_context.clear_color = color;
	
	return previous;
}
@Amber_API

draw_get_clip_rect :: inline () -> Recti #must
{
	return draw_context.clip_rect;
}
@Amber_API

// @Note (stefan): We can't include expansions in the API...
draw_scope_clip_rect :: (rect : Recti) #expand
{
	previous := draw_push_clip_rect (rect);
	`defer draw_set_clip_rect (previous);
}

draw_set_clip_rect :: inline (rect : Recti) -> previous_clip_rect : Recti
{
	draw_flush ();
	draw_context.use_clip_rect = true;
	previous := draw_context.clip_rect;
	draw_context.clip_rect = rect;
	{
		using draw_context.clip_rect;
		if x1 > x2 then x1 = x2;
		if y1 > y2 then y1 = y2;
	}
	
	return previous;
}
@Amber_API

draw_push_clip_rect :: inline (rect : Recti) -> previous_clip_rect : Recti
{
	if draw_context.use_clip_rect
		return draw_set_clip_rect (clip (rect, draw_context.clip_rect));
	
	return draw_set_clip_rect (rect);
}
@Amber_API

draw_set_clipping :: inline (clip : bool) -> previous_value : bool
{
	previous := draw_context.use_clip_rect;
	if previous != clip then draw_flush ();
	draw_context.use_clip_rect = clip;
	
	return previous;
}
@Amber_API

draw_get_viewport :: inline () -> Recti #must
{
	return draw_context.viewport;
}
@Amber_API

draw_set_viewport :: inline (viewport : Recti) -> Recti
{
	previous := draw_context.viewport;
	if previous != viewport then draw_flush ();
	draw_context.viewport = viewport;
	
	return previous;
}
@Amber_API

draw_get_texture :: inline () -> Texture_Handle #must
{
	return draw_context.texture;
}
@Amber_API

draw_set_texture :: inline (texture : Texture_Handle) -> previous_texture : Texture_Handle
{
	previous := draw_context.texture;
	if previous != texture then draw_flush ();
	draw_context.texture = texture;
	
	return previous;
}
@Amber_API

draw_get_framebuffer :: inline () -> Framebuffer_Handle #must
{
	return draw_context.framebuffer;
}
@Amber_API

draw_set_framebuffer :: inline (framebuffer : Framebuffer_Handle) -> Framebuffer_Handle
{
	previous := draw_context.framebuffer;
	if previous != framebuffer then draw_flush ();
	draw_context.framebuffer = framebuffer;
	
	return previous;
}
@Amber_API

draw_get_shader :: inline () -> Shader_Handle #must
{
	return draw_context.shader;
}
@Amber_API

draw_set_shader :: inline (shader : Shader_Handle) -> Shader_Handle
{
	previous := draw_context.shader;
	if shader == 0 then shader = default_shader;
	if previous != shader then draw_flush ();
	draw_context.shader = shader;
	
	return previous;
}
@Amber_API

draw_reserve_vertices :: inline (count : s64) -> *Vertex #must
{
	check_drawing ();
	
	if draw_context.vertex_count + count > Draw_Context.MAX_VERTICES then draw_flush ();
	result := *draw_context.vertices[draw_context.vertex_count];
	draw_context.vertex_count += count;
	
	return result;
}
@Amber_API

draw_triangle :: (
	p0 : Vec2f,
	p1 : Vec2f,
	p2 : Vec2f,
	color : RGBA,
	uv0 := Vec2f.{ 0, 0 },
	uv1 := Vec2f.{ 0.5, 1 },
	uv2 := Vec2f.{ 1, 0 }
)
{
	check_drawing ();

	if (p0 == p1 || p1 == p2 || p2 == p0)
		return;

	v0 := draw_reserve_vertices (3);
	v0.position   = p0;
	v0.tex_coords = uv0;
	v0.color      = color;
	
	v1 := v0 + 1;
	v1.position   = p1;
	v1.tex_coords = uv1;
	v1.color      = color;
	
	v2 := v1 + 1;
	v2.position   = p2;
	v2.tex_coords = uv2;
	v2.color      = color;
}
@Amber_API

/*
draw_triangle_outline :: (
	p0 : Vec2f,
	p1 : Vec2f,
	p2 : Vec2f,
	color : RGBA,
	thickness : f32
)
{
	check_drawing ();

}
@Amber_API
*/

draw_quad :: inline (
	p0 : Vec2f,
	p1 : Vec2f,
	p2 : Vec2f,
	p3 : Vec2f,
	color : RGBA,
	uv0 := Vec2f.{ 0, 0 },
	uv1 := Vec2f.{ 0, 1 },
	uv2 := Vec2f.{ 1, 1 },
	uv3 := Vec2f.{ 1, 0 }
)
{
	check_drawing ();
	
	draw_triangle (
		p1,
		p0,
		p3,
		color,
		uv0 = uv1,
		uv1 = uv0,
		uv2 = uv3
	);
	draw_triangle (
		p1,
		p3,
		p2,
		color,
		uv0 = uv1,
		uv1 = uv3,
		uv2 = uv2
	);
}
@Amber_API

draw_rect :: (
	rect : Rectf,
	color : RGBA,
	corner_radius := 0.0,
	round_corners := Rectangle_Corners.ALL,
	uv_rect := Rectf.{ 0, 0, 1, 1 }
)
{
	check_drawing ();

	if rect.x1 >= rect.x2 || rect.y1 >= rect.y2
		return;
	if corner_radius <= 0 || round_corners == .NONE
	{
		draw_triangle (
			vec2f (rect.x1, rect.y2),
			vec2f (rect.x1, rect.y1),
			vec2f (rect.x2, rect.y1),
			color,
			uv0 = vec2f (uv_rect.x1, uv_rect.y2),
			uv1 = vec2f (uv_rect.x1, uv_rect.y1),
			uv2 = vec2f (uv_rect.x2, uv_rect.y1)
		);
		draw_triangle (
			vec2f (rect.x1, rect.y2),
			vec2f (rect.x2, rect.y1),
			vec2f (rect.x2, rect.y2),
			color,
			uv0 = vec2f (uv_rect.x1, uv_rect.y2),
			uv1 = vec2f (uv_rect.x2, uv_rect.y1),
			uv2 = vec2f (uv_rect.x2, uv_rect.y2)
		);
	}
	else
	{
		inner_rect    := truncate_all_sides (rect, corner_radius);
		uv_radius     := (corner_radius / rect_width (rect)) * rect_width (uv_rect);
		inner_uv_rect := truncate_all_sides (uv_rect, uv_radius);
		// Inner rect
		draw_triangle (
			vec2f (inner_rect.x1, inner_rect.y2),
			vec2f (inner_rect.x1, inner_rect.y1),
			vec2f (inner_rect.x2, inner_rect.y1),
			color,
			uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
			uv1 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
			uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1)
		);
		draw_triangle (
			vec2f (inner_rect.x1, inner_rect.y2),
			vec2f (inner_rect.x2, inner_rect.y1),
			vec2f (inner_rect.x2, inner_rect.y2),
			color,
			uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
			uv1 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
			uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y2)
		);
		// Draw corners
		if flagged (round_corners, .TOP_LEFT)
			draw_semi_circle (
				rect_top_left (inner_rect),
				corner_radius,
				PI / 2,
				PI / 2,
				color,
				uv_center = rect_top_left (inner_uv_rect),
				uv_radius = uv_radius
			);
		else
			draw_rect (
				rectf (rect.x1, rect.y1, inner_rect.x1, inner_rect.y1),
				color,
				uv_rect = rectf (uv_rect.x1, uv_rect.y1, inner_uv_rect.x1, inner_uv_rect.y1)
			);
		if flagged (round_corners, .TOP_RIGHT)
			draw_semi_circle (
				rect_top_right (inner_rect),
				corner_radius,
				0,
				PI / 2,
				color,
				uv_center = rect_top_right (inner_uv_rect),
				uv_radius = uv_radius
			);
		else
			draw_rect (
				rectf (inner_rect.x2, rect.y1, rect.x2, inner_rect.y1),
				color,
				uv_rect = rectf (inner_uv_rect.x2, uv_rect.y1, uv_rect.x2, inner_uv_rect.y1)
			);
		if flagged (round_corners, .BOTTOM_LEFT)
			draw_semi_circle (
				rect_bottom_left (inner_rect),
				corner_radius,
				PI,
				PI / 2,
				color,
				uv_center = rect_bottom_left (inner_uv_rect),
				uv_radius = uv_radius
			);
		else
			draw_rect (
				rectf (rect.x1, inner_rect.y2, inner_rect.x1, rect.y2),
				color,
				uv_rect = rectf (uv_rect.x1, inner_uv_rect.y2, inner_uv_rect.x1, uv_rect.y2)
			);
		if flagged (round_corners, .BOTTOM_RIGHT)
			draw_semi_circle (
				rect_bottom_right (inner_rect),
				corner_radius,
				3 * PI / 2,
				PI / 2,
				color,
				uv_center = rect_bottom_right (inner_uv_rect),
				uv_radius = uv_radius
			);
		else
			draw_rect (
				rectf (inner_rect.x2, inner_rect.y2, rect.x2, rect.y2),
				color,
				uv_rect = rectf (inner_uv_rect.x2, inner_uv_rect.y2, uv_rect.x2, uv_rect.y2)
			);
		// Top
		draw_triangle (
			vec2f (inner_rect.x1, rect.y1),
			vec2f (inner_rect.x2, rect.y1),
			vec2f (inner_rect.x1, inner_rect.y1),
			color,
			uv0 = vec2f (inner_uv_rect.x1, uv_rect.y1),
			uv1 = vec2f (inner_uv_rect.x2, uv_rect.y1),
			uv2 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
		);
		draw_triangle (
			vec2f (inner_rect.x1, inner_rect.y1),
			vec2f (inner_rect.x2, rect.y1),
			vec2f (inner_rect.x2, inner_rect.y1),
			color,
			uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
			uv1 = vec2f (inner_uv_rect.x2, uv_rect.y1),
			uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
		);
		// Right
		draw_triangle (
			vec2f (inner_rect.x2, inner_rect.y1),
			vec2f (rect.x2, inner_rect.y1),
			vec2f (rect.x2, inner_rect.y2),
			color,
			uv0 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
			uv1 = vec2f (uv_rect.x2, inner_uv_rect.y1),
			uv2 = vec2f (uv_rect.x2, inner_uv_rect.y2),
		);
		draw_triangle (
			vec2f (inner_rect.x2, inner_rect.y1),
			vec2f (rect.x2, inner_rect.y2),
			vec2f (inner_rect.x2, inner_rect.y2),
			color,
			uv0 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
			uv1 = vec2f (uv_rect.x2, inner_uv_rect.y2),
			uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y2),
		);
		// Bottom
		draw_triangle (
			vec2f (inner_rect.x1, inner_rect.y2),
			vec2f (inner_rect.x2, inner_rect.y2),
			vec2f (inner_rect.x2, rect.y2),
			color,
			uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
			uv1 = vec2f (inner_uv_rect.x2, inner_uv_rect.y2),
			uv2 = vec2f (inner_uv_rect.x2, uv_rect.y2),
		);
		draw_triangle (
			vec2f (inner_rect.x1, inner_rect.y2),
			vec2f (inner_rect.x2, rect.y2),
			vec2f (inner_rect.x1, rect.y2),
			color,
			uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
			uv1 = vec2f (inner_uv_rect.x2, uv_rect.y2),
			uv2 = vec2f (inner_uv_rect.x1, uv_rect.y2),
		);
		// Left
		draw_triangle (
			vec2f (rect.x1, inner_rect.y1),
			vec2f (inner_rect.x1, inner_rect.y1),
			vec2f (inner_rect.x1, inner_rect.y2),
			color,
			uv0 = vec2f (uv_rect.x1, inner_uv_rect.y1),
			uv1 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
			uv2 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
		);
		draw_triangle (
			vec2f (rect.x1, inner_rect.y1),
			vec2f (inner_rect.x1, inner_rect.y2),
			vec2f (rect.x1, inner_rect.y2),
			color,
			uv0 = vec2f (uv_rect.x1, inner_uv_rect.y1),
			uv1 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
			uv2 = vec2f (uv_rect.x1, inner_uv_rect.y2),
		);
	}
}
@Amber_API

draw_rect_outline :: (
	rect : Rectf,
	color : RGBA,
	thickness : f32,
	corner_radius := 0.0,
	round_corners := Rectangle_Corners.ALL,
	uv_rect := Rectf.{ 0, 0, 1, 1 }
)
{
	inner_rect := truncate_all_sides (rect, thickness * 0.5);
	outer_rect := expand_all_sides (rect, thickness * 0.5);
	uv_thickness  := thickness / rect_width (rect) * rect_width (uv_rect);
	uv_radius     := (corner_radius / rect_width (rect)) * rect_width (uv_rect);
	inner_uv_rect := truncate_all_sides (uv_rect, uv_thickness * 0.5);
	outer_uv_rect := expand_all_sides (uv_rect, uv_thickness * 0.5);
	inset := corner_radius - thickness;
	uv_inset := uv_radius - uv_thickness;

	// Draw corners
	if flagged (round_corners, .TOP_LEFT)
		draw_semi_circle_outline (
			rect_top_left (inner_rect) + vec2f (inset, inset),
			corner_radius,
			PI / 2,
			PI / 2,
			color,
			thickness,
			uv_center = rect_top_left (inner_uv_rect),
			uv_radius = uv_radius
		);
	
	if flagged (round_corners, .TOP_RIGHT)
		draw_semi_circle_outline (
			rect_top_right (inner_rect) + vec2f (-inset, inset),
			corner_radius,
			0,
			PI / 2,
			color,
			thickness,
			uv_center = rect_top_right (inner_uv_rect),
			uv_radius = uv_radius
		);
	if flagged (round_corners, .BOTTOM_LEFT)
		draw_semi_circle_outline (
			rect_bottom_left (inner_rect) + vec2f (inset, -inset),
			corner_radius,
			PI,
			PI / 2,
			color,
			thickness,
			uv_center = rect_bottom_left (inner_uv_rect),
			uv_radius = uv_radius
		);
	if flagged (round_corners, .BOTTOM_RIGHT)
		draw_semi_circle_outline (
			rect_bottom_right (inner_rect) + vec2f (-inset, -inset),
			corner_radius,
			3 * PI / 2,
			PI / 2,
			color,
			thickness,
			uv_center = rect_bottom_right (inner_uv_rect),
			uv_radius = uv_radius
		);
	
	// Top
	draw_quad (
		vec2f (inner_rect.x1 + inset, inner_rect.y1),
		vec2f (inner_rect.x1 + inset, outer_rect.y1),
		vec2f (inner_rect.x2 - inset, outer_rect.y1),
		vec2f (inner_rect.x2 - inset, inner_rect.y1),
		color,
		vec2f (inner_uv_rect.x1 + uv_inset, inner_uv_rect.y1),
		vec2f (inner_uv_rect.x1 + uv_inset, outer_uv_rect.y1),
		vec2f (inner_uv_rect.x2 - uv_inset, outer_uv_rect.y1),
		vec2f (inner_uv_rect.x2 - uv_inset, inner_uv_rect.y1),
	);
	// Right
	draw_quad (
		vec2f (inner_rect.x2, inner_rect.y1 + inset),
		vec2f (outer_rect.x2, inner_rect.y1 + inset),
		vec2f (outer_rect.x2, inner_rect.y2 - inset),
		vec2f (inner_rect.x2, inner_rect.y2 - inset),
		color,
		vec2f (inner_uv_rect.x2, inner_uv_rect.y1 + uv_inset),
		vec2f (outer_uv_rect.x2, inner_uv_rect.y1 + uv_inset),
		vec2f (outer_uv_rect.x2, inner_uv_rect.y2 - uv_inset),
		vec2f (inner_uv_rect.x2, inner_uv_rect.y2 - uv_inset),
	);
	// Bottom
	draw_quad (
		vec2f (inner_rect.x1 + inset, outer_rect.y2),
		vec2f (inner_rect.x1 + inset, inner_rect.y2),
		vec2f (inner_rect.x2 - inset, inner_rect.y2),
		vec2f (inner_rect.x2 - inset, outer_rect.y2),
		color,
		vec2f (inner_uv_rect.x1 + uv_inset, outer_uv_rect.y2),
		vec2f (inner_uv_rect.x1 + uv_inset, inner_uv_rect.y2),
		vec2f (inner_uv_rect.x2 - uv_inset, inner_uv_rect.y2),
		vec2f (inner_uv_rect.x2 - uv_inset, outer_uv_rect.y2),
	);
	// Left
	draw_quad (
		vec2f (outer_rect.x1, inner_rect.y1 + inset),
		vec2f (inner_rect.x1, inner_rect.y1 + inset),
		vec2f (inner_rect.x1, inner_rect.y2 - inset),
		vec2f (outer_rect.x1, inner_rect.y2 - inset),
		color,
		vec2f (outer_uv_rect.x1, inner_uv_rect.y1 + uv_inset),
		vec2f (inner_uv_rect.x1, inner_uv_rect.y1 + uv_inset),
		vec2f (inner_uv_rect.x1, inner_uv_rect.y2 - uv_inset),
		vec2f (outer_uv_rect.x1, inner_uv_rect.y2 - uv_inset),
	);
}
@Amber_API

draw_semi_circle :: (center : Vec2f, radius : f32, start_angle : f32, angle : f32, color : RGBA, resolution := 0, uv_center := Vec2f.{ 0.5, 0.5 }, uv_radius := 0.5)
{
	check_drawing ();

	if radius <= 0
		return;

	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	theta := -angle / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (cos (-start_angle), sin (-start_angle));
	
	for 0..resolution - 1
	{
		p1 := p;
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;
		p2 := p;
		
		draw_triangle (
			center,
			center + p1 * radius,
			center + p2 * radius,
			color,
			uv0 = uv_center,
			uv1 = uv_center + p1 * uv_radius,
			uv2 = uv_center + p2 * uv_radius
		);
	}
}
@Amber_API

draw_circle :: (center : Vec2f, radius : f32, color : RGBA, resolution := 0, uv_center := Vec2f.{ 0.5, 0.5 }, uv_radius := 0.5)
{
	check_drawing ();

	inline draw_semi_circle (center, radius, 0, 2 * PI, color, resolution, uv_center, uv_radius);
}
@Amber_API

draw_semi_circle_outline :: (
	center : Vec2f,
	radius : f32,
	start_angle : f32,
	angle : f32,
	color : RGBA,
	thickness : f32,
	resolution := 0,
	uv_center := Vec2f.{ 0.5, 0.5 },
	uv_radius := 0.5
)
{
	check_drawing ();

	if radius <= 0
		return;
	
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	uv_thickness := thickness / radius * uv_radius;
	inner_radius := radius - thickness;
	inner_uv_radius := uv_radius - uv_thickness;
	theta := -angle / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (cos (-start_angle), sin (-start_angle));
	
	for 0..resolution - 1
	{
		p1 := p;
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;
		p2 := p;
		
		draw_triangle (
			center + p1 * inner_radius,
			center + p1 * radius,
			center + p2 * radius,
			color,
			uv0 = uv_center + p1 * inner_uv_radius,
			uv1 = uv_center + p1 * uv_radius,
			uv2 = uv_center + p2 * uv_radius
		);
		draw_triangle (
			center + p1 * inner_radius,
			center + p2 * radius,
			center + p2 * inner_radius,
			color,
			uv0 = uv_center + p1 * inner_uv_radius,
			uv1 = uv_center + p2 * uv_radius,
			uv2 = uv_center + p2 * inner_uv_radius
		);
	}
}
@Amber_API

draw_circle_outline :: (center : Vec2f, radius : f32, color : RGBA, thickness : f32, resolution := 0, uv_center := Vec2f.{ 0.5, 0.5 }, uv_radius := 0.5)
{
	check_drawing ();

	inline draw_semi_circle_outline (center, radius, 0, 2 * PI, color, thickness, resolution, uv_center, uv_radius);
}
@Amber_API

draw_line :: (start : Vec2f, end : Vec2f, color : RGBA, thickness : f32)
{
	check_drawing ();

	line_dir := normalized (end - start);
	theta    := atan2 (line_dir.x, -line_dir.y);
	cost     := cos (theta);
	sint     := sin (theta);
	offset   := vec2f (cost, sint) * thickness * 0.5;
	draw_triangle (start - offset, start + offset, end + offset, color);
	draw_triangle (start - offset, end + offset, end - offset, color);
}
@Amber_API

VERTEX_SHADER :: #string END
#version 330 core

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec2 a_Tex_Coords;
layout (location = 2) in vec4 a_Color;

out vec2 Tex_Coords;
out vec4 Color;

uniform mat4 u_View_Projection_Matrix;

void main ()
{
	gl_Position = u_View_Projection_Matrix * vec4 (a_Position, 0, 1);
	Tex_Coords = a_Tex_Coords;
	Color      = a_Color;
}
END

FRAGMENT_SHADER :: #string END
#version 330 core

in vec2 Tex_Coords;
in vec4 Color;

out vec4 Frag_Color;

uniform sampler2D u_Texture;
uniform bool u_Use_Texture;

void main ()
{
	vec4 sampled = vec4 (1, 1, 1, 1);
	if (u_Use_Texture)
		sampled = texture (u_Texture, Tex_Coords);
	Frag_Color = sampled * Color;
}
END
