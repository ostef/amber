draw_character_range :: (using view : Screen_View, first : s64, last : s64, $draw_cursors := true)
{
	imdraw.scope_clip_rect (math.recti (area));
	imdraw.draw_rect_outline (area, math.rgba (255, 255, 255, 100), 2);
	prev_texture := imdraw.get_texture ();
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (*font.g_glyph_shader);
	defer imdraw.set_shader (prev_shader);

	buffer    := get (buffer_id);
	text_info := get (text_info_id);
	visible := get_visible_range (view);
	first = math.clamp (first, visible.x, visible.y);
	last  = math.clamp (last,  visible.x, visible.y);
	font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	page : *font.Page;
	info_index := 0;
	for i : first..last
	{
		info, new_info_index := get_next_info (text_info, info_index, i);
		if !page || info_index != new_info_index
		{
			fnt := font.find_font (g_buffer_font, info.weight, xx info.effects, fallback = g_buffer_font);
			page = font.load_page (fnt, font_height);
			info_index = new_info_index;
		}
		draw_cursor := false;
		is_selected := false;
		for cursors
		{
			#if draw_cursors
			{
				if it.char_index == i
					draw_cursor = true;
			}
			if cursor_overlaps (it, i)
				is_selected = true;
		}
		rect := math.move (
			glyph_rects[i],
			math.round (area.x1),
			math.round (area.y1)
		);
		color := info.color;
		if draw_cursor
		{
			imdraw.set_texture (null);
			imdraw.draw_rect (rect, color);
			// @Incomplete (stefan): We want this to be the same color as
			// the background, to have a transparency effect.
			color = math.rgba (0.1, 0.1, 0.1, 1);
		}
		if i >= get_count (buffer)
			break;
		codepoint := char_at (buffer, i);
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

draw :: (using view : Screen_View)
{
	range := get_visible_range (view);
	draw_character_range (view, range.x, range.y);
}
