draw_selection :: (using view : Screen_View, color : math.RGBA)
{
	imdraw.scope_clip_rect (math.recti (get_text_area (view)));
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
					selection_rect.x = rect.x;
					selection_rect.y = rect.y;
					selection_rect.h = rect.h;
				}
				if is_selected
					math.set_right (*selection_rect, rect.x + rect.w);
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
	show_whitespace : Show_Whitespace
)
{
	draw_effects :: () #expand
	{
		if flagged (`effects, .UNDERLINE)
		{
			imdraw.set_texture (null);
			imdraw.draw_line (
				`line_start + linalg.vec2f (0, 0.5),
				`line_end   + linalg.vec2f (0, 0.5),
				`color,
				1
			);
		}
		if flagged (`effects, .STRIKETHROUGH)
		{
			imdraw.set_texture (null);
			imdraw.draw_line (
				`line_start - linalg.vec2f (0, `page.ascent * (2.0 / 5.0) + 0.5),
				`line_end   - linalg.vec2f (0, `page.ascent * (2.0 / 5.0) + 0.5),
				`color,
				1
			);
		}
	}

	buffer := get (buffer_id);
	new_line := true;
	line_start : linalg.Vec2f;
	line_end   : linalg.Vec2f;
	for i : first_char..last_char
	{
		is_selected := false;
		for cursors
		{
			// If this character is on the cursor, don't draw it unless the cursor
			// is an outline (we are not the active screen view). The character is
			// drawn on top of the cursor, in draw_cursors in that case.
			if it.char_index == i && g_active_screen_view.id == id
				continue i;
			if cursor_overlaps (it, i)
				is_selected = true;
		}
		rect := get_rect (view, i);
		if new_line || line_end.y != rect.y + page.ascent
		{
			draw_effects ();
			line_start = linalg.vec2f (rect.x, rect.y + page.ascent);
		}
		line_end = linalg.vec2f (rect.x + rect.w, rect.y + page.ascent);
		new_line = false;
		char_color := color;
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
			rect.x + glyph.bitmap_bearing_x,
			rect.y - glyph.bitmap_bearing_y + page.ascent,
			cast (f32) glyph.bitmap_width,
			cast (f32) glyph.bitmap_height
		);
		imdraw.set_texture (glyph.atlas_texture);
		imdraw.draw_rect (glyph_rect, char_color, glyph.uv_rect);
	}
	draw_effects ();
}

#scope_export

draw_character_range :: (using view : Screen_View, first : s64, last : s64)
{
	imdraw.scope_clip_rect (math.recti (get_text_area (view)));
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
			show_whitespace
		);
		i = info.range.y + 1;
		info_index += 1;
	}
}

draw_cursors :: (using view : Screen_View)
{
	imdraw.scope_clip_rect (math.recti (get_text_area (view)));
	prev_texture := imdraw.set_texture (null);
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (*font.g_glyph_shader);
	defer imdraw.set_shader (prev_shader);

	if cursor_rects.count != cursors.count
		fmt.println ("We have % cursors, but % cursor rects.", cursors.count, cursor_rects.count);
	buffer := get (buffer_id);
	text_info := get (text_info_id);
	font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	page := font.load_page (g_buffer_font, font_height);
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	cursor_rounding := math.clamp (get_float (g_config, "cursor_rounding", fallback = 0), 0, 10);
	for i : 0..cursor_rects.count - 1
	{
		info, info_index := get_info_for_character (text_info, cursors[i].char_index);
		color := ifx info_index == -1 then math.RGBA_WHITE else info.color;
		rect := get_cursor_rect (view, i);
		if g_active_screen_view.id == view.id
			imdraw.draw_rect (rect, color, corner_radius = cursor_rounding);
		else
			imdraw.draw_rect_outline (
				math.truncate_all_sides (rect, 0.5),
				color,
				corner_radius = cursor_rounding,
				thickness = 1
			);
		if g_active_screen_view.id != id || cursors[i].char_index == get_count (buffer)
			continue;
		color = get_rgba (g_config, "editor_colors['view.background']", VIEW_BACKGROUND);
		codepoint := char_at (buffer, cursors[i].char_index);
		if codepoint ==
		{
		case #char "\n";
			continue;
		case #char "\t";
			if show_whitespace != .NEVER
			{
				codepoint = #char "→";
				color.a /= 3;
			}
			else
				continue;
		case #char " ";
			if show_whitespace != .NEVER
			{
				codepoint = #char "·";
				color.a /= 3;
			}
		}
		glyph := font.render_glyph (page, codepoint);
		glyph_rect := math.xywhf (
			rect.x + glyph.bitmap_bearing_x,
			rect.y - glyph.bitmap_bearing_y + page.ascent,
			cast (f32) glyph.bitmap_width,
			cast (f32) glyph.bitmap_height
		);
		imdraw.set_texture (glyph.atlas_texture);
		imdraw.draw_rect (glyph_rect, color, glyph.uv_rect);
		imdraw.set_texture (null);
	}
}

draw :: (using view : Screen_View)
{
	imdraw.draw_rect (
		view.area,
		get_rgba (g_config, "editor_colors['view.background']", VIEW_BACKGROUND)
	);
	if g_active_screen_view.id == view.id
		draw_selection (view, get_rgba (g_config, "editor_colors['view.selection']", VIEW_BACKGROUND));
	else
		draw_selection (view, get_rgba (g_config, "editor_colors['view.inactive_selection']", VIEW_BACKGROUND));
	range := get_visible_range (view);
	draw_character_range (view, range.x, range.y);
	draw_cursors (view);
	// Draw buffer info
	buffer := get (buffer_id);
	use_buffer_font := get_bool (g_config, "use_buffer_font_for_buffer_info", fallback = true);
	put_bar_on_top := get_bool (g_config, "put_buffer_info_bar_on_top");
	font_height := cast (u32) math.max (get_int (g_config, "buffer_info_font_height", fallback = 16), MIN_FONT_HEIGHT);
	info_font := ifx use_buffer_font then g_buffer_font else g_main_font;
	page := font.load_page (info_font, font_height);
	info_bar_area : math.Rectf;
	if put_bar_on_top
		info_bar_area = math.truncate_bottom (view.area, area.h - cast (f32) (page.ascent - page.descent));
	else
		info_bar_area = math.truncate_top (view.area, area.h - cast (f32) (page.ascent - page.descent));
	imdraw.draw_rect (
		info_bar_area,
		get_rgba (g_config, "editor_colors['view.info.background']", VIEW_INFO_BACKGROUND)
	);
	info_text_col := get_rgba (g_config, "editor_colors['view.info.text']", VIEW_INFO_TEXT);
	imdraw.draw_text (
		info_font,
		font_height,
		info_bar_area.position,
		path.get_basename (buffer.filename),
		info_text_col
	);
	li, ci := get_cursor_line_and_column (view, 0);
	imdraw.draw_text (
		info_font,
		font_height,
		math.top_right (info_bar_area),
		fmt.format (mem.TEMP_ALLOC, "Ln %, Col % ~ %", li + 1, ci + 1, buffer.eol_sequence),
		info_text_col,
		anchor = .TOP_RIGHT
	);
}
