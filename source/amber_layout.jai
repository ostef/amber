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
	font_id : Font_ID;
	font_height : u32;

	area    : Rectf;
	extents : Vec2f;
	scroll        : Vec2f;
	visual_scroll : Vec2f;
	rects         : [..]Rectf;
	wrapped_lines : [..]Line;
}

Color_Range :: struct
{
	range : Rangei;
	color : RGBA;
}

init_text_layout :: (layout : *Text_Layout, capacity : s64)
{
	init_array (*layout.rects, capacity, heap_allocator);
	init_array (*layout.wrapped_lines, capacity / 100, heap_allocator);
}

base_line :: (using layout : *Text_Layout) -> s64 #must
{
	return clamp (cast (s64) visual_scroll.y, 0, wrapped_lines.count - 1);
}

layout_text :: (using layout : *Text_Layout)
{
	wrap_line :: () #expand
	{
		push_into_array (*`wrapped_lines, `line);
		`line.first_character = `i;
		`pen.x = page.space_advance * 4.0 * (indentation_level + 1);
		`pen.y += `page.ascent - `page.descent;
	}

	clear_array (*wrapped_lines);
	clear_array (*rects);
	
	buffer := get_buffer (buffer_id);
	font   := get_font (font_id);
	page   := load_page (font, font_height);
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
			advance := snap_up (pen.x + glyph.advance, page.space_advance * 4.0) - pen.x;
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
}

draw_line_numbers :: (using layout : *Text_Layout, color : RGBA, highlight_color : RGBA)
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

	position := vec2f (area.x1 - width + page.space_advance, area.y1 - visual_scroll.y * line_height);
	current_line_index := -1;
	line_range := get_visible_line_range (layout);
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

draw_selection :: (using layout : *Text_Layout, color : RGBA)
{
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
	visible_lines := get_visible_line_range (layout);
	for :cursors cur : buffer
	{
		if cur.selection == 0 then continue;
		
		for li : visible_lines
		{
			line_range := get_line_range (layout, li);
			selection_rect : Rectf;
			was_selected := false;
			for i : line_range
			{
				rect := get_rect (layout, i);
				is_selected := cur.selection > 0 && i >= cur.offset && i < cur.offset + cur.selection - 1 ||
							   cur.selection < 0 && i >= cur.offset + cur.selection && i < cur.offset;
				defer was_selected = is_selected;
				
				if !was_selected && is_selected
				{
					selection_rect.x1 = rect.x1;
					selection_rect.y1 = rect.y1;
					selection_rect.y2 = rect.y2;
				}
				
				if was_selected && !is_selected || i == line_range.max && is_selected
				{
					selection_rect.x2 = rect.x2;
					
					break;
				}
			}
			
			draw_rect (selection_rect, color, CURSOR_ROUNDING);
		}
	}
}

draw_line_highlight :: (using layout : *Text_Layout, color : RGBA)
{
	prev_clip := draw_set_clipping (true);
	defer draw_set_clipping (prev_clip);
	prev_clip_rect := draw_set_clip_rect (recti (area));
	defer draw_set_clip_rect (prev_clip_rect);
	prev_texture := draw_set_texture (0);
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (0);
	defer draw_set_shader (prev_shader);

	buffer := get_buffer (buffer_id);
	rect := get_rect (layout, buffer.offset);
	rect.x1 = area.x1;
	rect.x2 = area.x2;
	draw_rect (rect, color);
}

draw_text_layout :: inline (using layout : *Text_Layout, color : RGBA)
{
	colors : [1]Color_Range;
	colors[0].range = rangei (0, rects.count - 1);
	colors[0].color = color;
	draw_text_layout (layout, colors);
}

draw_text_layout :: (using layout : *Text_Layout, color_ranges : []Color_Range)
{
	assert (color_ranges.count > 0, "Color range array is empty.");

	prev_clip := draw_set_clipping (true);
	defer draw_set_clipping (prev_clip);
	prev_clip_rect := draw_set_clip_rect (recti (area));
	defer draw_set_clip_rect (prev_clip_rect);
	prev_texture := draw_get_texture ();
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);

	buffer := get_buffer (buffer_id);
	font   := get_font (font_id);
	page   := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	visible_range := get_visible_range (layout);
	color_index := 0;
	for i : visible_range
	{
		while color_index < color_ranges.count - 1
		{
			if contains (color_ranges[color_index].range, i)
				break;
			color_index += 1;
		}
		color := color_ranges[color_index].color;
		draw_cursor := false;
		is_whitespace := false;
		for :cursors cur : buffer
		{
			if cur.offset == i
				draw_cursor = true;
		}

		rect := get_rect (layout, i);
		if draw_cursor
		{
			draw_set_texture (0);
			draw_rect (rect, color, CURSOR_ROUNDING);
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
		draw_rect (glyph_rect, (ifx draw_cursor then invert (color) else color), uv_rect = glyph.uv_rect);
	}
}

get_rect :: inline (using layout : *Text_Layout, index : s64) -> Rectf #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	
	return move (rects[index], area.x1 - visual_scroll.x * page.space_advance, area.y1 - visual_scroll.y * line_height);
}

get_visible_range :: (using layout : *Text_Layout) -> Rangei #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : Rangei;
	result.min = wrapped_lines[base_line (layout)].first_character;
	result.max = rects.count - 1;
	for i : base_line (layout)..wrapped_lines.count - 1
	{
		if i * line_height - visual_scroll.y * line_height >= rect_height (area)
		{
			result.max = wrapped_lines[i].first_character - 1;
		
			break;
		}
	}
	
	return result;
}

get_visible_line_range :: (using layout : *Text_Layout) -> Rangei #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	result : Rangei;
	result.min = base_line (layout);
	result.max = wrapped_lines.count - 1;
	for i : base_line (layout)..wrapped_lines.count - 1
	{
		if i * line_height - visual_scroll.y * line_height >= rect_height (area)
		{
			result.max = i;
		
			break;
		}
	}
	
	return result;
}

get_line_range :: inline (using layout : *Text_Layout, line_index : s64) -> Rangei #must
{
	result : Rangei;
	result.min = wrapped_lines[line_index].first_character;
	result.max = ifx line_index + 1 < wrapped_lines.count then wrapped_lines[line_index + 1].first_character - 1 else rects.count - 1;
	
	return result;
}

get_closest_character :: (using layout : *Text_Layout, position : Vec2f) -> s64 #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);
	line_height := cast (f32) (page.ascent - page.descent);
	relative := position - rect_position (area);
	line_index := cast (s64) round (visual_scroll.y) + cast (s64) (relative.y / line_height);
	line_index = clamp (line_index, 0, wrapped_lines.count - 1);
	range : Rangei;
	range.min = wrapped_lines[line_index].first_character;
	range.max = ifx line_index == wrapped_lines.count - 1 then rects.count - 1 else wrapped_lines[line_index + 1].first_character - 1;
	if position.x <= get_rect (layout, range.min).x1
		return range.min;
	else if position.x >= get_rect (layout, range.max).x2
		return range.max;
	for i : range
	{
		rect := get_rect (layout, i);
		if contains (rect, position)
			return i;
	}
	
	return range.max;
}
