#load "draw.jai";

// Metadata about the text in a buffer, for rendering.
// This is the thing that a syntax colorizer would modify.
// It might make it so that all 'if's are in bold, and
// of color-id 'keyword' for example.
Text_Info :: struct
{
	Id :: #type, isa storage.Slot_Info;

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
		range : linalg.Vec2l;		// 16-bytes
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

get_info_for_character :: (using info : Text_Info, index : s64) -> info.Info_Range #must, info_index : s64
{
	for infos
	{
		if it.range.x <= index && index <= it.range.y
			return it, it_index;
	}
	return .{}, -1;
}

get_next_info :: (using info : Text_Info, info_index : s64, char_index : s64) -> info.Info_Range #must, new_info_index : s64
{
	if info_index < 0 || info_index >= infos.count
		return .{}, -1;
	i := info_index;
	for i : info_index..infos.count - 1
	{
		it := infos[i];
		if it.range.x <= char_index && char_index <= it.range.y
			return it, i;
	}
	return .{}, -1;
}

update :: (using info : *Text_Info)
{
	buffer := get (buffer_id);
	if buffer.is_dirty
		process_jai_buffer (info);
}

Show_Whitespace :: enum
{
	NEVER :: 0;
	ONLY_SELECTED :: 1;
	ALWAYS :: 2;
}

Screen_View :: struct
{
	Id :: #type, isa storage.Slot_Info;

	Line :: struct
	{
		unwrapped_line_index : s64;
		first_char_index     : s64;
	}

	id : Id;
	#as using base : View;
	base.type = Screen_View;
	text_info_id : Text_Info.Id;
	area    : math.Rectf;
	extents : linalg.Vec2f;
	scroll  : linalg.Vec2f;
	visual_scroll : linalg.Vec2f;
	glyph_rects   : [..]math.Rectf;
	wrapped_lines : [..]Line;
	cursor_rects : [..]math.Rectf;
	is_mouse_selecting : bool;

	base.procs.on_cursor_added   = on_cursor_added_to_screen_view;
	base.procs.on_cursor_removed = on_cursor_removed_from_screen_view;
}

to_screen_view :: inline (view : *View) -> *Screen_View #must
{
	assert (view.type == Screen_View, "View is not a Screen_View.");
	return cast (*Screen_View) (cast (*void) view - offset_of (Screen_View, "base"));
}

on_cursor_added_to_screen_view :: (base_view : *View, index : s64)
{
	using view := to_screen_view (base_view);
	char_index := cursors[index].char_index;
	if char_index < glyph_rects.count
		array.ordered_insert_at (*cursor_rects, index, glyph_rects[char_index]);
	else
		array.ordered_insert_at (*cursor_rects, index, math.rectf (0, 0, 0, 0));
}

on_cursor_removed_from_screen_view :: (base_view : *View, index : s64, cursor : View.Cursor)
{
	using view := to_screen_view (base_view);
	array.ordered_remove_at (*cursor_rects, index);
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
	view.text_info_id = text_info_id;
	view.area = area;
	array.init (*view.glyph_rects, get_count (get (buffer_id)) + 1000, mem.HEAP_ALLOC);
	array.init (*view.wrapped_lines, get (buffer_id).line_count + 100, mem.HEAP_ALLOC);
	array.init (*view.cursor_rects, 10, mem.HEAP_ALLOC);
	init (*view.base, Screen_View, buffer_id, read_only);
}

reset :: (using view : *Screen_View)
{
	reset (*view.base);
	array.reset (*glyph_rects);
	array.reset (*wrapped_lines);
	array.reset (*cursor_rects);
}

handle_window_message :: (using view : *Screen_View, msg : window.Message)
{
	if msg.kind ==
	{
	case .MOUSE_BUTTON_PRESSED;
		mouse_pos := linalg.vec2f (xx msg.mouse_x, xx msg.mouse_y);
		if msg.mouse_button == .LEFT && math.contains (area, mouse_pos)
			g_active_screen_view = view;

		if msg.mouse_button == .LEFT && math.contains (get_text_area (view), mouse_pos)
		{
			clear_cursors (view);
			clear_selection (view);
			move_cursor (view, get_closest_character (view, mouse_pos), false);
			is_mouse_selecting = true;
		}

	case .MOUSE_BUTTON_RELEASED;
		is_mouse_selecting = false;

	case .MOUSE_MOVED;
		mouse_pos := linalg.vec2f (xx msg.mouse_x, xx msg.mouse_y);
		if g_active_screen_view == view
		&& is_mouse_selecting && input.is_mouse_button_down (.LEFT) && !input.is_mouse_button_pressed (.LEFT)
		{
			clear_cursors (view);
			move_cursor (view, get_closest_character (view, mouse_pos), true);
		}

	case .MOUSE_WHEEL;
		mouse_pos := linalg.vec2f (xx msg.mouse_x, xx msg.mouse_y);
		if math.contains (area, mouse_pos)
			scroll -= linalg.vec2f (msg.mouse_wheel_x, msg.mouse_wheel_y);
		scroll = linalg.clamp (scroll, linalg.vec2f (0, 0), get_max_scroll (view));

	case .WINDOW_MAXIMIZED; #through;
	case .WINDOW_RESIZED;
		// @Todo (stefan): Handle resizing to (0, 0)
		current_available := linalg.vec2i (g_viewport_size.x, g_viewport_size.y - WINDOW_CAPTION_HEIGHT);
		new_available := linalg.vec2i (msg.viewport_width, msg.viewport_height - WINDOW_CAPTION_HEIGHT);
		x_ratio := area.x / cast (f32) current_available.x;
		y_ratio := (area.y - WINDOW_CAPTION_HEIGHT) / cast (f32) current_available.y;
		width_ratio := area.w / cast (f32) current_available.x;
		height_ratio := area.h / cast (f32) current_available.y;
		area.x = x_ratio * cast (f32) new_available.x;
		area.y = WINDOW_CAPTION_HEIGHT + y_ratio * cast (f32) new_available.y;
		area.w = width_ratio * cast (f32) new_available.x;
		area.h = height_ratio * cast (f32) new_available.y;
		is_dirty = true;
	}
	if g_active_screen_view == view
		handle_window_message (*view.base, msg);
}

get_text_area :: inline (using view : Screen_View) -> math.Rectf #must
{
	use_buffer_font := get_bool (g_config, "use_buffer_font_for_buffer_info", fallback = true);
	put_bar_on_top := get_bool (g_config, "put_buffer_info_bar_on_top");
	font_height := cast (u32) math.max (get_int (g_config, "buffer_info_font_height", fallback = 16), MIN_FONT_HEIGHT);
	page : *font.Page;
	if use_buffer_font
		page = font.load_page (g_buffer_font, font_height);
	else
		page = font.load_page (g_main_font, font_height);
	if put_bar_on_top
		return math.truncate_top (view.area, cast (f32) (page.ascent - page.descent));
	return math.truncate_bottom (view.area, cast (f32) (page.ascent - page.descent));
}

get_rect :: inline (using view : Screen_View, index : s64, page : *font.Page = null) -> math.Rectf #must
{
	if !page
	{
		font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
		page = font.load_page (g_buffer_font, font_height);
	}
	text_area := get_text_area (view);
	return math.move (
		glyph_rects[index],
		math.round (text_area.x) - visual_scroll.x * page.space_advance,
		math.round (text_area.y) - visual_scroll.y * (page.ascent - page.descent)
	);
}

get_cursor_rect :: inline (using view : Screen_View, index : s64, page : *font.Page = null) -> math.Rectf #must
{
	if !page
	{
		font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
		page = font.load_page (g_buffer_font, font_height);
	}
	text_area := get_text_area (view);
	return math.move (
		cursor_rects[index],
		math.round (text_area.x) - visual_scroll.x * page.space_advance,
		math.round (text_area.y) - visual_scroll.y * (page.ascent - page.descent)
	);
}

get_max_scroll :: (using view : Screen_View, page : *font.Page = null) -> linalg.Vec2f #must
{
	if !page
	{
		font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
		page = font.load_page (g_buffer_font, font_height);
	}
	return linalg.vec2f (
		math.max (math.ceil ((extents.x - get_text_area (view).w) / cast (f32) page.space_advance), 0),
		math.max (math.ceil ((extents.y - get_text_area (view).h) / cast (f32) (page.ascent - page.descent)), 0)
	);
}

get_closest_character :: (using view : Screen_View, position : linalg.Vec2f) -> s64 #must
{
	font_height := math.max (get_int (g_config, "buffer_font_height"), 5);
	page := font.load_page (g_buffer_font, xx font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	line_index := cast (s64) (math.round (visual_scroll.y) + (position.y - get_text_area (view).y) / line_height);
	line_index = math.clamp (line_index, 0, wrapped_lines.count - 1);
	range := get_line_range (view, line_index);
	if position.x <= get_rect (view, range.x).x
		return range.x;
	else if position.x >= math.left (get_rect (view, range.y))
		return range.y;
	for i : range.x..range.y
	{
		if math.contains (get_rect (view, i), position)
			return i;
	}

	return range.y;
}

get_base_line :: inline (using view : Screen_View) -> s64 #must
{
	return math.clamp (cast (s64) visual_scroll.y, 0, wrapped_lines.count - 1);
}

get_visible_range :: (using view : Screen_View) -> linalg.Vec2l #must
{
	font_height := math.max (get_int (g_config, "buffer_font_height"), 5);
	// @Incomplete (stefan): We pick the page for the buffer font
	// with no effects and regular weight, but we might actually
	// use different weights and effects when rendering.
	// We probably should compute the max ascent and descent and use
	// that for all line heights in the buffer.
	page := font.load_page (g_buffer_font, xx font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : linalg.Vec2l;
	result.x = wrapped_lines[get_base_line (view)].first_char_index;
	result.y = glyph_rects.count - 1;
	for i : get_base_line (view)..wrapped_lines.count - 1
	{
		if i * line_height - visual_scroll.y * line_height >= get_text_area (view).h
		{
			result.y = wrapped_lines[i].first_char_index - 1;
			break;
		}
	}

	return result;
}

get_visible_line_range :: (using view : Screen_View) -> linalg.Vec2l #must
{
	font_height := math.max (get_int (g_config, "buffer_font_height"), 5);
	// @Incomplete (stefan): We pick the page for the buffer font
	// with no effects and regular weight, but we might actually
	// use different weights and effects when rendering.
	// We probably should compute the max ascent and descent and use
	// that for all line heights in the buffer.
	page := font.load_page (g_buffer_font, xx font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : linalg.Vec2l;
	result.x = get_base_line (view);
	result.y = wrapped_lines.count - 1;
	for i : get_base_line (view)..wrapped_lines.count - 1
	{
		if i * line_height - visual_scroll.y * line_height >= get_text_area (view).h
		{
			result.y = i;
			break;
		}
	}

	return result;
}

get_line_range :: inline (using view : Screen_View, line_index : s64) -> linalg.Vec2l #must
{
	line := wrapped_lines[line_index];
	range : linalg.Vec2l;
	range.x = line.first_char_index;
	range.y = glyph_rects.count - 1;
	if line_index < wrapped_lines.count - 1
		range.y = wrapped_lines[line_index + 1].first_char_index - 1;

	return range;
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

	buffer    := get (buffer_id);
	text_info := get (text_info_id);
	font_height := cast (u32) math.max (get_int (g_config, "buffer_font_height", fallback = 16), MIN_FONT_HEIGHT);
	page : *font.Page;
	info_index := 0;
	// Reset data
	array.clear (*wrapped_lines);
	array.clear (*glyph_rects);
	extents = linalg.vec2f (0, 0);
	// @Todo (stefan):
	// fnt = get_font (get_string (g_config, "buffer_font"))
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	tab_width := math.max (get_int (g_config, "tab_width", fallback = 4), 1);
	line : Line;
	pen : linalg.Vec2f;
	start_of_line := true;	// Used to count the indentation level
	indentation_level := 0;
	for codepoint, i : buffer
	{
		info, new_info_index := get_next_info (text_info, info_index, i);
		if !page || info_index != new_info_index
		{
			fnt := font.find_font (g_buffer_font, info.weight, xx info.effects, fallback = g_buffer_font);
			page = font.load_page (fnt, font_height);
			info_index = new_info_index;
		}
		rect : math.Rectf;
		if codepoint ==
		{
		case #char "\n";
			if pen.x + page.space_advance > get_text_area (view).w
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
			if pen.x + advance > get_text_area (view).w
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
			if pen.x + glyph.advance > get_text_area (view).w
				wrap_line ();
			rect = math.xywhf (pen.x, pen.y, xx glyph.advance, xx (page.ascent - page.descent));
			pen.x += glyph.advance;
		}
		extents = linalg.max (extents, pen);
		array.push (*glyph_rects, rect);
	}
	page = font.load_page (g_buffer_font, font_height);
	array.push (*glyph_rects,
		math.xywhf (
			pen.x, pen.y,
			xx page.space_advance, xx (page.ascent - page.descent)
		)
	);
	array.push (*wrapped_lines, line);
	pen.x += xx page.space_advance;
	pen.y += xx (page.ascent - page.descent);
	extents = linalg.max (extents, pen);
}

update :: (using view : *Screen_View)
{
	buffer := get (buffer_id);
	scroll_smoothing := math.clamp (get_float (g_config, "scroll_smoothing"), 0, 0.9);
	visual_scroll = linalg.lerp (visual_scroll, linalg.round (scroll), 1 - scroll_smoothing);
	if is_dirty || buffer.is_dirty
		layout_text (view);
	cursor_smoothing := math.clamp (get_float (g_config, "cursor_smoothing"), 0, 0.9);
	for * cursor_rects
	{
		glyph_rect := glyph_rects[cursors[it_index].char_index];
		it.x = math.lerp (it.x, glyph_rect.x, 1 - cursor_smoothing);
		it.w = math.lerp (it.w, glyph_rect.w, 1 - cursor_smoothing);
		it.y = math.lerp (it.y, glyph_rect.y, 1 - cursor_smoothing);
		it.h = math.lerp (it.h, glyph_rect.h, 1 - cursor_smoothing);
	}
}
