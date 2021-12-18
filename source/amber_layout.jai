Text_Layout :: struct
{
	Line :: struct
	{
		unwrapped_line_index : s64;
		first_character      : s64;
	}

	id : Text_Layout_ID;
	split_id  : Split_ID;
	buffer_id : Buffer_ID;
	// @Todo (stefan): Handle multiple fonts for more interesting text rendering.
	font_id : Font_ID;
	font_height : u32;
	is_dirty : bool;

	area    : Rectf;
	extents : Vec2f;
	scroll        : Vec2f;
	visual_scroll : Vec2f;
	rects         : [..]Rectf;
	wrapped_lines : [..]Line;
	colors : [..]Color_Range;
}

TAB_WIDTH :: 4;

Color_Range :: struct
{
	range : Rangei;
	color : RGBA;
}

add_text_layout :: inline () -> *Text_Layout #must
{
	layout, index := insert_into_slot_array (*text_layouts);
	layout.id = cast (Text_Layout_ID) (index + 1);
	text_layout_init (layout.id, 10000);
	
	return layout;
}

remove_text_layout :: inline (layout_id : Text_Layout_ID)
{
	text_layout_reset (layout_id);
	remove_from_slot_array (*text_layouts, xx (layout_id - 1));
}

get_text_layout :: inline (id : Text_Layout_ID) -> *Text_Layout #must
{
	assert (text_layout_exists (id), "Invalid text layout id (%).", id);
	
	return get_ptr (*text_layouts, cast (s64) id - 1);
}

get_text_layout_count :: inline () -> s64 #must
{
	return text_layouts.count;
}
@Amber_API

get_active_text_layout :: inline () -> Text_Layout_ID #must
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return NULL_TEXT_LAYOUT;
	
	return buffer_get_text_layout (buffer_id);
}
@Amber_API

text_layout_exists :: inline (id : Text_Layout_ID) -> bool #must
{
	return id > 0 && id <= xx text_layouts.max_occupied && text_layouts.slots[cast (s64) id - 1].occupied;
}
@Amber_API

text_layout_init :: inline (layout_id : Text_Layout_ID, capacity : s64)
{
	using layout := get_text_layout (layout_id);
	init_array (*rects, capacity, HEAP);
	init_array (*wrapped_lines, capacity / 100, HEAP);
	init_array (*colors, capacity / 10, HEAP);
}

text_layout_reset :: inline (layout_id : Text_Layout_ID)
{
	using layout := get_text_layout (layout_id);
	reset_array (*rects);
	reset_array (*wrapped_lines);
	reset_array (*colors);
}

text_layout_clear :: inline (layout_id : Text_Layout_ID)
{
	using layout := get_text_layout (layout_id);
	clear_array (*rects);
	clear_array (*wrapped_lines);
	clear_array (*colors);
	is_dirty = true;
}
@Amber_API

text_layout_get_split :: inline (layout_id : Text_Layout_ID) -> Split_ID #must
{
	using layout := get_text_layout (layout_id);
	
	return split_id;
}
@Amber_API

text_layout_get_buffer :: inline (layout_id : Text_Layout_ID) -> Buffer_ID #must
{
	using layout := get_text_layout (layout_id);
	
	return buffer_id;
}
@Amber_API

text_layout_get_font :: inline (layout_id : Text_Layout_ID) -> Font_ID #must
{
	using layout := get_text_layout (layout_id);
	
	return font_id;
}
@Amber_API

text_layout_set_font :: inline (layout_id : Text_Layout_ID, font_id : Font_ID)
{
	layout := get_text_layout (layout_id);
	layout.is_dirty = true;
	layout.font_id = font_id;
}
@Amber_API

text_layout_get_font_height :: inline (layout_id : Text_Layout_ID) -> u32 #must
{
	using layout := get_text_layout (layout_id);
	
	return font_height;
}
@Amber_API

text_layout_set_font_height :: inline (layout_id : Text_Layout_ID, font_height : u32)
{
	layout := get_text_layout (layout_id);
	layout.is_dirty = true;
	layout.font_height = font_height;
}
@Amber_API

text_layout_get_column_width :: inline (layout_id : Text_Layout_ID) -> f32 #must
{
	font := get_font (text_layout_get_font (layout_id));
	page := load_page (font, text_layout_get_font_height (layout_id));
	
	return cast (f32) (page.space_advance);
}
@Amber_API

text_layout_get_line_height :: inline (layout_id : Text_Layout_ID) -> f32 #must
{
	font := get_font (text_layout_get_font (layout_id));
	page := load_page (font, text_layout_get_font_height (layout_id));
	
	return cast (f32) (page.ascent - page.descent);
}
@Amber_API

text_layout_is_dirty :: inline (layout_id : Text_Layout_ID) -> bool #must
{
	using layout := get_text_layout (layout_id);
	
	return is_dirty;
}
@Amber_API

text_layout_set_dirty :: inline (layout_id : Text_Layout_ID)
{
	using layout := get_text_layout (layout_id);
	is_dirty = true;
}
@Amber_API

text_layout_get_area :: inline (layout_id : Text_Layout_ID) -> Rectf #must
{
	using layout := get_text_layout (layout_id);
	
	return area;
}
@Amber_API

text_layout_set_area :: inline (layout_id : Text_Layout_ID, area : Rectf)
{
	layout := get_text_layout (layout_id);
	layout.area = area;
	layout.is_dirty = true;
}
@Amber_API

text_layout_update_area :: inline (layout_id : Text_Layout_ID)
{
	text_layout_set_area (layout_id, split_get_text_layout_area (text_layout_get_split (layout_id)));
}
@Amber_API

text_layout_get_extents :: inline (layout_id : Text_Layout_ID) -> Vec2f #must
{
	using layout := get_text_layout (layout_id);
	
	return extents;
}
@Amber_API

text_layout_get_scroll :: inline (layout_id : Text_Layout_ID) -> Vec2f #must
{
	using layout := get_text_layout (layout_id);
	
	return scroll;
}
@Amber_API

text_layout_set_scroll :: inline (layout_id : Text_Layout_ID, scroll : Vec2f)
{
	layout := get_text_layout (layout_id);
	layout.scroll = scroll;
}
@Amber_API

text_layout_set_scroll_x :: inline (layout_id : Text_Layout_ID, scroll_x : f32)
{
	layout := get_text_layout (layout_id);
	layout.scroll.x = scroll_x;
}
@Amber_API

text_layout_set_scroll_y :: inline (layout_id : Text_Layout_ID, scroll_y : f32)
{
	layout := get_text_layout (layout_id);
	layout.scroll.y = scroll_y;
}
@Amber_API

text_layout_scroll_x :: inline (layout_id : Text_Layout_ID, add_scroll : f32)
{
	using layout := get_text_layout (layout_id);
	
	scroll.x += add_scroll;
}
@Amber_API

text_layout_scroll_y :: inline (layout_id : Text_Layout_ID, add_scroll : f32)
{
	using layout := get_text_layout (layout_id);
	
	scroll.y += add_scroll;
}
@Amber_API

text_layout_get_max_scroll :: inline (layout_id : Text_Layout_ID) -> Vec2f #must
{
	font := get_font (text_layout_get_font (layout_id));
	page := load_page (font, text_layout_get_font_height (layout_id));
	line_height := cast (f32) (page.ascent - page.descent);
	extents := text_layout_get_extents (layout_id);
	area    := text_layout_get_area (layout_id);
	
	return vec2f (
		max (ceil ((extents.x - rect_width (area)) / cast (f32) page.space_advance), 0),
		max (ceil ((extents.y - rect_height (area)) / line_height), 0)
	);
}
@Amber_API

text_layout_get_visual_scroll :: inline (layout_id : Text_Layout_ID) -> Vec2f #must
{
	using layout := get_text_layout (layout_id);
	
	return visual_scroll;
}
@Amber_API

text_layout_set_visual_scroll :: inline (layout_id : Text_Layout_ID, scroll : Vec2f)
{
	layout := get_text_layout (layout_id);
	layout.visual_scroll = scroll;
}
@Amber_API

text_layout_get_rect :: inline (layout_id : Text_Layout_ID, index : s64) -> Rectf #must
{
	using layout := get_text_layout (layout_id);
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	
	return move (rects[index], round (area.x1) - visual_scroll.x * page.space_advance, round (area.y1) - visual_scroll.y * line_height);
}
@Amber_API

text_layout_get_relative_rect :: inline (layout_id : Text_Layout_ID, index : s64) -> Rectf #must
{
	using layout := get_text_layout (layout_id);
	
	return rects[index];
}
@Amber_API

text_layout_get_visible_range :: (layout_id : Text_Layout_ID) -> Rangei #must
{
	using layout := get_text_layout (layout_id);
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : Rangei;
	result.min = wrapped_lines[text_layout_get_base_line (layout_id)].first_character;
	result.max = rects.count - 1;
	for i : text_layout_get_base_line (layout_id)..wrapped_lines.count - 1
	{
		if i * line_height - visual_scroll.y * line_height >= rect_height (area)
		{
			result.max = wrapped_lines[i].first_character - 1;
		
			break;
		}
	}
	
	return result;
}
@Amber_API

text_layout_get_visible_line_range :: (layout_id : Text_Layout_ID) -> Rangei #must
{
	using layout := get_text_layout (layout_id);
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : Rangei;
	result.min = text_layout_get_base_line (layout_id);
	result.max = wrapped_lines.count - 1;
	for i : text_layout_get_base_line (layout_id)..wrapped_lines.count - 1
	{
		if i * line_height - visual_scroll.y * line_height >= rect_height (area)
		{
			result.max = i;
		
			break;
		}
	}
	
	return result;
}
@Amber_API

text_layout_get_line_range :: inline (layout_id : Text_Layout_ID, line_index : s64) -> Rangei #must
{
	using layout := get_text_layout (layout_id);
	result : Rangei;
	result.min = wrapped_lines[line_index].first_character;
	result.max = ifx line_index + 1 < wrapped_lines.count then wrapped_lines[line_index + 1].first_character - 1 else rects.count - 1;
	
	return result;
}
@Amber_API

text_layout_get_closest_character :: (layout_id : Text_Layout_ID, position : Vec2f) -> s64 #must
{
	using layout := get_text_layout (layout_id);
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	relative := position - rect_position (area);
	line_index := cast (s64) round (visual_scroll.y) + cast (s64) (relative.y / line_height);
	line_index = clamp (line_index, 0, wrapped_lines.count - 1);
	range : Rangei;
	range.min = wrapped_lines[line_index].first_character;
	range.max = ifx line_index == wrapped_lines.count - 1 then rects.count - 1 else wrapped_lines[line_index + 1].first_character - 1;
	if position.x <= text_layout_get_rect (layout_id, range.min).x1
		return range.min;
	else if position.x >= text_layout_get_rect (layout_id, range.max).x2
		return range.max;
	for i : range
	{
		rect := text_layout_get_rect (layout_id, i);
		if contains (rect, position)
			return i;
	}
	
	return range.max;
}
@Amber_API

text_layout_get_base_line :: inline (layout_id : Text_Layout_ID) -> s64 #must
{
	using layout := get_text_layout (layout_id);
	
	return clamp (cast (s64) visual_scroll.y, 0, wrapped_lines.count - 1);
}
@Amber_API

text_layout_clear_colors :: inline (layout_id : Text_Layout_ID)
{
	using layout := get_text_layout (layout_id);
	clear_array (*colors);
}
@Amber_API

text_layout_push_color :: inline (layout_id : Text_Layout_ID, range : Rangei, color : RGBA)
{
	using layout := get_text_layout (layout_id);
	ptr := push_into_array (*colors);
	ptr.range = range;
	ptr.color = color;
}
@Amber_API

text_layout_compute :: (layout_id : Text_Layout_ID)
{
	wrap_line :: () #expand
	{
		push_into_array (*`wrapped_lines, `line);
		`line.first_character = `i;
		`pen.x = page.space_advance * cast (f32) TAB_WIDTH * (indentation_level + 1);
		`pen.y += `page.ascent - `page.descent;
	}

	using layout := get_text_layout (layout_id);
	buffer := get_buffer (buffer_id);
	font   := get_font (font_id);
	clear_array (*wrapped_lines);
	clear_array (*rects);
	
	page := load_page (font, font_height);
	line : Line;
	pen  : Vec2f;
	extents = vec2f (0, 0);
	line_height := cast (f32) (page.ascent - page.descent);
	start_of_line := true;
	indentation_level := 0;
	for codepoint, i : buffer
	{
		rect : Rectf;
		if codepoint ==
		{
		case #char "\n";
			if pen.x + page.space_advance > rect_width (area)
				wrap_line ();
			rect = xywhf (pen.x, pen.y, xx page.space_advance, line_height);
			pen.x = 0;
			pen.y += line_height;
			push_into_array (*wrapped_lines, line);
			line.first_character = i + 1;
			line.unwrapped_line_index += 1;
			start_of_line = true;
			indentation_level = 0;
		
		case #char "\t";
			if start_of_line
				indentation_level += 1;
			glyph := load_glyph (page, 0x2192);
			advance := snap_up (pen.x + glyph.advance, page.space_advance * cast (f32) TAB_WIDTH) - pen.x;
			if pen.x + advance > rect_width (area)
				wrap_line ();
			rect = xywhf (pen.x, pen.y, advance, line_height);
			pen.x += advance;
		
		case #char " ";
			codepoint = 0xb7;
			#through;
		
		case;
			start_of_line = false;
			glyph := load_glyph (page, codepoint);
			if pen.x + glyph.advance > rect_width (area)
				wrap_line ();
			rect = xywhf (pen.x, pen.y, xx glyph.advance, line_height);
			pen.x += glyph.advance;
		}
		extents.x = max (extents.x, pen.x);
		extents.y = max (extents.y, pen.y);
		push_into_array (*rects, rect);
	}
	push_into_array (*rects, xywhf (pen.x, pen.y, xx page.space_advance, line_height));
	push_into_array (*wrapped_lines, line);
	pen.x += xx page.space_advance;
	pen.y += line_height;
	extents.x = max (extents.x, pen.x);
	extents.y = max (extents.y, pen.y);
	is_dirty = false;
}
@Amber_API

draw_line_numbers :: (layout_id : Text_Layout_ID, color : RGBA, highlight_color : RGBA)
{
	draw_justified_number :: (page : *Font_Page, position : Vec2f, n : s64, width : s64, color : RGBA)
	{
		pen := vec2f (position.x + width * page.space_advance, position.y);
		if n == 0
		{
			glyph := load_glyph (page, #char "0");
			pen.x -= xx glyph.advance;
			glyph_rect := xywhf (
				pen.x + glyph.bitmap_bearing_x,
				pen.y - glyph.bitmap_bearing_y + page.ascent,
				xx glyph.bitmap_width,
				xx glyph.bitmap_height
			);
			draw_set_texture (glyph.atlas_texture);
			draw_rect (glyph_rect, color, uv_rect = glyph.uv_rect);
		}
		
		while n > 0
		{
			glyph := load_glyph (page, cast (u32) (#char "0" + (n % 10)));
			pen.x -= xx glyph.advance;
			glyph_rect := xywhf (
				pen.x + glyph.bitmap_bearing_x,
				pen.y - glyph.bitmap_bearing_y + page.ascent,
				xx glyph.bitmap_width,
				xx glyph.bitmap_height
			);
			draw_set_texture (glyph.atlas_texture);
			draw_rect (glyph_rect, color, uv_rect = glyph.uv_rect);
			n /= 10;
		}
	}

	using layout := get_text_layout (layout_id);
	buffer := get_buffer (buffer_id);
	font   := get_font (font_id);
	page   := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	line_number_len := 0;
	{
		tmp := buffer.lines.count;
		while tmp > 0
		{
			line_number_len += 1;
			tmp /= 10;
		}
	}
	width := cast (f32) (line_number_len + 2) * page.space_advance;

	prev_clip := draw_set_clipping (true);
	defer draw_set_clipping (prev_clip);
	prev_clip_rect := draw_set_clip_rect (xywhi (
		xx (area.x1 - width),
		xx area.y1,
		xx width,
		xx rect_height (area))
	);
	defer draw_set_clip_rect (prev_clip_rect);
	prev_texture := draw_get_texture ();
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);

	position := vec2f (round (area.x1) - width + page.space_advance, round (area.y1) - visual_scroll.y * line_height);
	current_line_index := -1;
	line_range := text_layout_get_visible_line_range (layout_id);
	for line_index : line_range
	{
		line := wrapped_lines[line_index];
		if line.unwrapped_line_index != current_line_index
		{
			current_line_index = line.unwrapped_line_index;
			draw_justified_number (
				page,
				vec2f (position.x, position.y + line_index * line_height),
				current_line_index + 1,
				line_number_len,
				(ifx buffer.line_index == current_line_index then highlight_color else color)
			);
		}
	}
}

draw_selection :: (layout_id : Text_Layout_ID, color : RGBA)
{
	using layout := get_text_layout (layout_id);
	prev_clip := draw_set_clipping (true);
	defer draw_set_clipping (prev_clip);
	prev_clip_rect := draw_set_clip_rect (recti (area));
	defer draw_set_clip_rect (prev_clip_rect);
	prev_texture := draw_set_texture (0);
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (0);
	defer draw_set_shader (prev_shader);

	buffer := get_buffer (buffer_id);
	font   := get_font (font_id);
	page   := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	visible_lines := text_layout_get_visible_line_range (layout_id);
	for :cursors cur : buffer
	{
		if cur.selection == 0 then continue;
		
		for li : visible_lines
		{
			line_range := text_layout_get_line_range (layout_id, li);
			selection_rect : Rectf;
			was_selected := false;
			for i : line_range
			{
				rect := text_layout_get_rect (layout_id, i);
				is_selected := cur.selection > 0 && i >= cur.offset && i < cur.offset + cur.selection ||
							   cur.selection < 0 && i >= cur.offset + cur.selection && i < cur.offset;
				defer was_selected = is_selected;
				
				if !was_selected && is_selected
				{
					selection_rect.x1 = rect.x1;
					selection_rect.y1 = rect.y1;
					selection_rect.y2 = rect.y2;
				}
				
				if i == line_range.max && is_selected
				{
					selection_rect.x2 = rect.x2;
				}
				else if was_selected && !is_selected
				{
					selection_rect.x2 = rect.x1;
					
					break;
				}
			}
			
			draw_rect (selection_rect, color, CURSOR_ROUNDING);
		}
	}
}

draw_line_highlight :: (layout_id : Text_Layout_ID, color : RGBA)
{
	using layout := get_text_layout (layout_id);
	prev_clip := draw_set_clipping (true);
	defer draw_set_clipping (prev_clip);
	prev_clip_rect := draw_set_clip_rect (recti (area));
	defer draw_set_clip_rect (prev_clip_rect);
	prev_texture := draw_set_texture (0);
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (0);
	defer draw_set_shader (prev_shader);

	buffer := get_buffer (buffer_id);
	rect   := text_layout_get_rect (layout_id, buffer.offset);
	rect.x1 = area.x1;
	rect.x2 = area.x2;
	draw_rect (rect, color);
}

draw_text_layout :: (layout_id : Text_Layout_ID)
{
	using layout := get_text_layout (layout_id);
	prev_clip := draw_set_clipping (true);
	defer draw_set_clipping (prev_clip);
	prev_clip_rect := draw_set_clip_rect (recti (area));
	defer draw_set_clip_rect (prev_clip_rect);
	prev_texture := draw_get_texture ();
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);

	assert (colors.count != 0, "Colors array is empty.");
	active := !is_inputting_command && get_active_split () == text_layout_get_split (layout_id);
	buffer := get_buffer (buffer_id);
	font   := get_font (font_id);
	page   := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	visible_range := text_layout_get_visible_range (layout_id);
	color_index := 0;
	for i : visible_range
	{
		while color_index < colors.count - 1
		{
			if contains (colors[color_index].range, i)
				break;
			color_index += 1;
		}
		color := colors[color_index].color;
		draw_cursor := false;
		is_whitespace := false;
		for :cursors cur : buffer
		{
			if cur.offset == i
				draw_cursor = true;
		}

		rect := text_layout_get_rect (layout_id, i);
		if draw_cursor
		{
			draw_set_texture (0);
			if active
				draw_rect (rect, color, CURSOR_ROUNDING);
			else
				draw_rect_outline (truncate_all_sides (rect, 0.5), color, 1, CURSOR_ROUNDING);
		}
		if i == rects.count - 1 then break;

		codepoint := buffer_get_codepoint (buffer_id, i);
		if codepoint ==
		{
		case #char "\n";
			continue;
		
		case #char "\t";
			codepoint = 0x2192;
			is_whitespace = true;
			
		case #char " ";
			codepoint = 0xb7;
			is_whitespace = true;
		}
		glyph := load_glyph (page, codepoint);
		glyph_rect := xywhf (
			rect.x1 + glyph.bitmap_bearing_x,
			rect.y1 - glyph.bitmap_bearing_y + page.ascent,
			xx glyph.bitmap_width,
			xx glyph.bitmap_height
		);
		if is_whitespace then color.a /= 3;
		draw_set_texture (glyph.atlas_texture);
		draw_rect (glyph_rect, (ifx active && draw_cursor then RGBA_BLACK else color), uv_rect = glyph.uv_rect);
	}
}
