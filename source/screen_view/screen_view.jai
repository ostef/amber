#load "draw.jai";

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

get_rect :: inline (using view : Screen_View, index : s64) -> math.Rectf #must
{
	return math.move (
		glyph_rects[index],
		math.round (area.x1),
		math.round (area.y1)
	);
}

get_base_line :: inline (using view : Screen_View) -> s64 #must
{
	// @Todo (stefan): Handle scroll
	return 0;
}

get_visible_range :: (using view : Screen_View) -> Vec2l #must
{
	font_height := math.max (get_int (g_config, "buffer_font_height"), 5);
	// @Incomplete (stefan): We pick the page for the buffer font
	// with no effects and regular weight, but we might actually
	// use different weights and effects when rendering.
	// We probably should compute the max ascent and descent and use
	// that for all line heights in the buffer.
	page := font.load_page (g_buffer_font, xx font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : Vec2l;
	result.x = wrapped_lines[get_base_line (view)].first_char_index;
	result.y = glyph_rects.count - 1;
	for i : get_base_line (view)..wrapped_lines.count - 1
	{
		if i * line_height >= math.rect_height (area)	// @Incomplete: scrolling
		{
			result.y = wrapped_lines[i].first_char_index - 1;
			break;
		}
	}

	return result;
}

get_visible_line_range :: (using view : Screen_View) -> Vec2l #must
{
	font_height := math.max (get_int (g_config, "buffer_font_height"), 5);
	// @Incomplete (stefan): We pick the page for the buffer font
	// with no effects and regular weight, but we might actually
	// use different weights and effects when rendering.
	// We probably should compute the max ascent and descent and use
	// that for all line heights in the buffer.
	page := font.load_page (g_buffer_font, xx font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : Vec2l;
	result.x = get_base_line (view);
	result.y = wrapped_lines.count - 1;
	for i : get_base_line (view)..wrapped_lines.count - 1
	{
		if i * line_height >= math.rect_height (area)	// @Incomplete: scrolling
		{
			result.y = i;
			break;
		}
	}

	return result;
}

get_line_range :: inline (using view : Screen_View, line_index : s64) -> Vec2l #must
{
	line := wrapped_lines[line_index];
	range : Vec2l;
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
	extents = vec2f (0, 0);
	// @Todo (stefan):
	// fnt = get_font (get_string (g_config, "buffer_font"))
	show_whitespace := get_enum (g_config, "buffer_show_whitespace", fallback = Show_Whitespace.NEVER);
	tab_width := math.max (get_int (g_config, "tab_width", fallback = 4), 1);
	line : Line;
	pen : Vec2f;
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
		process_jai_buffer (get (text_info_id));
		layout_text (view);
		is_dirty = false;
	}
}
