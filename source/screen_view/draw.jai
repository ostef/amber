draw :: (using view : Screen_View)
{
	imdraw.scope_clip_rect (math.recti (area));
	imdraw.draw_rect_outline (area, math.RGBA_WHITE, 2);
	prev_texture := imdraw.get_texture ();
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (*font.g_glyph_shader);
	defer imdraw.set_shader (prev_shader);

	buffer    := get (buffer_id);
	text_info := get (text_info_id);
	info_index := 0;
	info := text_info.infos[info_index];
	font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	page : *font.Page;
	if flagged (info.effects, .ITALIC)
	{
		fnt := font.find_font (g_buffer_font, info.weight, .ITALIC, fallback = g_buffer_font);
		page = font.load_page (fnt, font_height);
	}
	else
	{
		fnt := font.find_font (g_buffer_font, info.weight, .NONE, fallback = g_buffer_font);
		page = font.load_page (fnt, font_height);
	}
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	visible := get_visible_range (view);
	for i : visible.x..visible.y
	{
		if text_info.infos[info_index].range.x > i || i > text_info.infos[info_index].range.y
		{
			while info_index < text_info.infos.count - 1
			{
				info = text_info.infos[info_index];
				if info.range.x <= i && i <= info.range.y
					break;
				info_index += 1;
			}
			fnt : *font.Font;
			if flagged (info.effects, .ITALIC)
				fnt = font.find_font (g_buffer_font, info.weight, .ITALIC, fallback = g_buffer_font);
			else
				fnt = font.find_font (g_buffer_font, info.weight, .NONE, fallback = g_buffer_font);
			page = font.load_page (fnt, font_height);
		}
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
		color := info.color;
		if draw_cursor
		{
			imdraw.set_texture (null);
			imdraw.draw_rect (rect, color);
			color = math.invert (color);
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
