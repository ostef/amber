draw_selection :: (using view : Screen_View, color : math.RGBA)
{
	imdraw.scope_clip_rect (math.recti (area));
	prev_texture := imdraw.set_texture (null);
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (null);
	defer imdraw.set_shader (prev_shader);

	cursor_rounding := math.clamp (get_float (g_config, "cursor_rounding", fallback = 0), 0, 10);
	visible_lines := get_visible_line_range (view);
	for cur : cursors
	{
		if cur.selection == 0
			continue;
		for li : visible_lines.x..visible_lines.y
		{
			line_range := get_line_range (view, li);
			selection_rect : math.Rectf;
			was_selected := false;
			for i : line_range.x..line_range.y
			{
				rect := get_rect (view, i);
				is_selected := cursor_selects (cur, i);
				defer was_selected = is_selected;

				// If we are the start of the selection, set the
				// left, top and bottom coords of the selection rect
				if !was_selected && is_selected
				{
					selection_rect.x1 = rect.x1;
					selection_rect.y1 = rect.y1;
					selection_rect.y2 = rect.y2;
				}
				if is_selected
					selection_rect.x2 = rect.x2;
				if was_selected && !is_selected
					break;
			}
			imdraw.draw_rect (selection_rect, color, corner_radius = cursor_rounding);
		}
	}
}

#scope_file

draw_character_range :: (
	using view : Screen_View,
	first_char : s64,
	last_char  : s64,
	page : *font.Page,
	effects : imdraw.Text_Effects,
	color : math.RGBA,
	show_whitespace : Show_Whitespace,
	$draw_cursors := true
)
{
	draw_effects :: () #expand
	{
		if flagged (`effects, .UNDERLINE)
		{
			imdraw.set_texture (null);
			imdraw.draw_line (
				`line_start + vec2f (0, 0.5),
				`line_end   + vec2f (0, 0.5),
				`color,
				1
			);
		}
		if flagged (`effects, .STRIKETHROUGH)
		{
			imdraw.set_texture (null);
			imdraw.draw_line (
				`line_start - vec2f (0, `page.ascent * (2.0 / 5.0) + 0.5),
				`line_end   - vec2f (0, `page.ascent * (2.0 / 5.0) + 0.5),
				`color,
				1
			);
		}
	}

	cursor_rounding := math.clamp (get_float (g_config, "cursor_rounding", fallback = 0), 0, 10);
	buffer := get (buffer_id);
	new_line := true;
	line_start : Vec2f;
	line_end   : Vec2f;
	for i : first_char..last_char
	{
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
		rect := get_rect (view, i);
		if new_line || line_end.y != rect.y1 + page.ascent
		{
			draw_effects ();
			line_start = vec2f (rect.x1, rect.y1 + page.ascent);
		}
		line_end = vec2f (rect.x2, rect.y1 + page.ascent);
		new_line = false;
		char_color := color;
		if draw_cursor
		{
			imdraw.set_texture (null);
			if g_active_screen_view.id == view.id
			{
				imdraw.draw_rect (rect, char_color, corner_radius = cursor_rounding);
				char_color = math.rgba (0.1, 0.1, 0.1);
			}
			else
				imdraw.draw_rect_outline (
					math.truncate_all_sides (rect, 0.5),
					char_color,
					corner_radius = cursor_rounding,
					thickness = 1
				);
		}
		if i >= get_count (buffer)
			break;
		codepoint := char_at (buffer, i);
		if codepoint ==
		{
		case #char "\n";
			new_line = true;
			continue;
		case #char "\t";
			if show_whitespace == .ALWAYS
			|| show_whitespace == .ONLY_SELECTED && is_selected
			{
				codepoint = #char "→";
				char_color.a /= 3;
			}
			else
				continue;
		case #char " ";
			if show_whitespace == .ALWAYS
			|| show_whitespace == .ONLY_SELECTED && is_selected
			{
				codepoint = #char "·";
				char_color.a /= 3;
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
		imdraw.draw_rect (glyph_rect, char_color, glyph.uv_rect);
	}
	draw_effects ();
}

#scope_export

draw_character_range :: (using view : Screen_View, first : s64, last : s64, $draw_cursors := true)
{
	imdraw.scope_clip_rect (math.recti (area));
	prev_texture := imdraw.get_texture ();
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (*font.g_glyph_shader);
	defer imdraw.set_shader (prev_shader);

	text_info := get (text_info_id);
	font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	page : *font.Page;
	i := first;
	info, info_index := get_info_for_character (text_info, i);
	while i <= last && info_index >= 0 && info_index < text_info.infos.count
	{
		info = text_info.infos[info_index];
		if !page || info.weight != page.font.weight || info.effects != xx page.font.effects
		{
			fnt := font.find_font (g_buffer_font, info.weight, xx info.effects, fallback = g_buffer_font);
			page = font.load_page (fnt, font_height);
		}
		draw_character_range (
			view,
			i,
			math.min (info.range.y, last),
			page,
			info.effects,
			info.color,
			show_whitespace,
			draw_cursors
		);
		i = info.range.y + 1;
		info_index += 1;
	}
	if !page
		page = font.load_page (g_buffer_font, font_height);
	if i <= last
		draw_character_range (
			view,
			i,
			last,
			page,
			.NONE,
			math.RGBA_WHITE,
			show_whitespace,
			draw_cursors
		);
}

draw :: (using view : Screen_View)
{
	imdraw.draw_rect_outline (area, math.rgba (255, 255, 255, 100), 2);
	draw_selection (view, math.rgba (50, 100, 200));
	range := get_visible_range (view);
	draw_character_range (view, range.x, range.y);
}
