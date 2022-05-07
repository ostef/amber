// Metadata about the text in a buffer, for rendering.
// This is the thing that a syntax colorizer would modify.
// It might make it so that all 'if's are in bold, and
// of color-id 'keyword' for example.
Text_Info :: struct
{
	Id :: type_of (g_text_infos).Slot_Info;

	Info :: struct
	{
		weight   : font.Weight;		// 1-byte
		effects  : imdraw.Text_Effects;	// 1-byte
		color    : math.RGBA;	// @Temporary @Memory
		//color_id : Color_Id;		// 2-bytes
	}	// 4-bytes

	// We don't want to have an Info for each character,
	// because that wouldn't be very efficient, so we have
	// an info for a range of characters.
	Info_Range :: struct
	{
		range : Vec2l;		// 16-bytes
		using info : Info;	// 4-bytes
	}	// 20-bytes, 24-bytes with padding

	// If we have a buffer with 5000 lines, let's say
	// on average it has 80 character long lines,
	// with 15 tokens per lines, and we don't merge
	// similar tokens together, we have 15 * 5000
	// Info_Ranges, so 15 * 5000 * 24 bytes = 1,72 MB

	id : Id;
	buffer_id : Buffer.Id;
	infos : [..]Info_Range;
}

Show_Whitespace :: enum
{
	NEVER :: 0;
	ONLY_SELECTED :: 1;
	ALWAYS :: 2;
}

Screen_View :: struct
{
	Id :: type_of (g_screen_views).Slot_Info;

	Line :: struct
	{
		unwrapped_line_index : s64;
		first_char_index     : s64;
	}

	id : Id;
	#as using base : View;
	text_info_id : Text_Info.Id;
	area    : math.Rectf;
	extents : Vec2f;
	scroll  : Vec2f;
	glyph_rects   : [..]math.Rectf;
	wrapped_lines : [..]Line;
}

init :: (
	view : *Screen_View,
	buffer_id : Buffer.Id,
	text_info_id : Text_Info.Id,
	read_only : bool,
	area : math.Rectf
)
{
	assert (storage.is_valid (g_text_infos, text_info_id), "Invalid text info id.");
	//assert (get (text_info_id).buffer_id == buffer_id, "Text info does not reference the same buffer.");	Cannot find operator == for some reason
	init (*view.base, Screen_View, buffer_id, read_only);
	view.text_info_id = text_info_id;
	view.area = area;
	array.init (*view.glyph_rects, get_count (get (buffer_id)) + 1000, mem.HEAP_ALLOC);
	array.init (*view.wrapped_lines, get (buffer_id).line_count + 100, mem.HEAP_ALLOC);
}

reset :: (using view : *Screen_View)
{
	reset (*view.base);
	array.reset (*glyph_rects);
	array.reset (*wrapped_lines);
}

handle_window_message :: (using view : *Screen_View, msg : window.Message)
{
	if msg.kind ==
	{
	case .WINDOW_MAXIMIZED; #through;
	case .WINDOW_RESIZED;
		// @Todo (stefan): Handle resizing to (0, 0)
		current_available := vec2i (g_viewport_size.x, g_viewport_size.y - WINDOW_CAPTION_HEIGHT);
		new_available := vec2i (msg.viewport_width, msg.viewport_height - WINDOW_CAPTION_HEIGHT);
		x_ratio := area.x1 / cast (f32) current_available.x;
		y_ratio := (area.y1 - WINDOW_CAPTION_HEIGHT) / cast (f32) current_available.y;
		width_ratio := math.rect_width (area) / cast (f32) current_available.x;
		height_ratio := math.rect_height (area) / cast (f32) current_available.y;
		area.x1 = math.round (x_ratio * cast (f32) new_available.x);
		area.y1 = WINDOW_CAPTION_HEIGHT + math.round (y_ratio * cast (f32) new_available.y);
		area.x2 = area.x1 + width_ratio * cast (f32) new_available.x;
		area.y2 = area.y1 + height_ratio * cast (f32) new_available.y;
		is_dirty = true;
	}
	handle_window_message (*view.base, msg);
}

layout_text :: (using view : *Screen_View)
{
	wrap_line :: () #expand
	{
		array.push (*`wrapped_lines, `line);
		`line.first_char_index = `i;
		`pen.x = page.space_advance * cast (f32) `tab_width * (`indentation_level + 1);
		`pen.y += xx (`page.ascent - `page.descent);
	}

	buffer := get (buffer_id);
	info   := get (text_info_id);
	// Reset data
	array.clear (*wrapped_lines);
	array.clear (*glyph_rects);
	extents = vec2f (0, 0);
	// @Todo (stefan):
	// fnt = get_font (get_string (g_config, "buffer_font"))
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	page := font.load_page (g_buffer_font, font_height);
	tab_width := math.max (get_int (g_config, "tab_width", fallback = 4), 1);
	line : Line;
	pen : Vec2f;
	start_of_line := true;	// Used to count the indentation level
	indentation_level := 0;
	for codepoint, i : buffer
	{
		rect : math.Rectf;
		if codepoint ==
		{
		case #char "\n";
			if pen.x + page.space_advance > math.rect_width (area)
				wrap_line ();
			rect = math.xywhf (pen.x, pen.y, xx page.space_advance, xx (page.ascent - page.descent));
			pen.x = 0;
			pen.y += xx (page.ascent - page.descent);
			array.push (*wrapped_lines, line);
			line.first_char_index = i + 1;
			line.unwrapped_line_index += 1;
			indentation_level = 0;
			start_of_line = true;

		case #char "\t";
			if start_of_line then indentation_level += 1;
			glyph_advance := page.space_advance;
			if show_whitespace
			{
				glyph := font.load_glyph (page, #char "→");
				glyph_advance = glyph.advance;
			}
			advance := math.snap_up (pen.x + glyph_advance, page.space_advance * cast (f32) tab_width) - pen.x;
			if pen.x + advance > math.rect_width (area)
				wrap_line ();
			rect = math.xywhf (pen.x, pen.y, advance, xx (page.ascent - page.descent));
			pen.x += advance;

		case #char " ";
			if show_whitespace
				codepoint = #char "·";
			#through;

		case;
			start_of_line = false;
			glyph := font.load_glyph (page, codepoint);
			if pen.x + glyph.advance > math.rect_width (area)
				wrap_line ();
			rect = math.xywhf (pen.x, pen.y, xx glyph.advance, xx (page.ascent - page.descent));
			pen.x += glyph.advance;
		}
		extents = linalg.max (extents, pen);
		array.push (*glyph_rects, rect);
	}
	array.push (*glyph_rects,
		math.xywhf (
			pen.x, pen.y,
			xx page.space_advance, xx (page.ascent - page.descent)
		)
	);
	pen.x += xx page.space_advance;
	pen.y += xx (page.ascent - page.descent);
	extents = linalg.max (extents, pen);
}

update :: (using view : *Screen_View)
{
	if is_dirty
	{
		layout_text (view);
		is_dirty = false;
	}
}

draw :: (using view : Screen_View)
{
	imdraw.scope_clip_rect (math.recti (area));
	imdraw.draw_rect_outline (area, math.RGBA_WHITE, 2);
	prev_texture := imdraw.get_texture ();
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (*font.g_glyph_shader);
	defer imdraw.set_shader (prev_shader);

	buffer := get (buffer_id);
	info   := get (text_info_id);
	font_height := math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	page := font.load_page (g_buffer_font, cast (u32) font_height);
	for codepoint, i : buffer
	{
		draw_cursor := false;
		is_selected := false;
		for cursors
		{
			if it.char_index == i
				draw_cursor = true;
			if cursor_overlaps (it, i)
				is_selected = true;
		}
		rect := math.move (
			glyph_rects[i],
			math.round (area.x1),
			math.round (area.y1)
		);
		color := math.RGBA_WHITE;
		if draw_cursor
		{
			imdraw.set_texture (null);
			imdraw.draw_rect (rect, color);
			color = math.invert (color);
		}
		
		if codepoint ==
		{
		case #char "\n";
			continue;
		case #char "\t";
			if show_whitespace == .ALWAYS
			|| show_whitespace == .ONLY_SELECTED && is_selected
			{
				codepoint = #char "→";
				color.a /= 3;
			}
			else
				continue;
		case #char " ";
			if show_whitespace == .ALWAYS
			|| show_whitespace == .ONLY_SELECTED && is_selected
			{
				codepoint = #char "·";
				color.a /= 3;
			}
		}
		glyph := font.render_glyph (page, codepoint);
		glyph_rect := math.xywhf (
			rect.x1 + glyph.bitmap_bearing_x,
			rect.y1 - glyph.bitmap_bearing_y + page.ascent,
			cast (f32) glyph.bitmap_width,
			cast (f32) glyph.bitmap_height
		);
		imdraw.set_texture (glyph.atlas_texture);
		imdraw.draw_rect (glyph_rect, color, glyph.uv_rect);
	}
}
