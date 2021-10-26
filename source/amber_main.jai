#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_math.jai";
#load "amber_unicode.jai";
#load "amber_platform.jai";
#load "amber_gl.jai";
#load "amber_draw.jai";
#load "amber_font.jai";
#load "amber_buffer.jai";
#load "amber_layout.jai";
#load "amber_language.jai";
#load "amber_extension.jai";

CURSOR_ROUNDING :: 3.0;
CURSOR_MARGIN   :: 0;
SCROLLBAR_WIDTH :: 10.0;
MIN_SCROLLBAR_HEIGHT    :: 25.0;
MAX_SCROLLBAR_SHOW_TIME :: 3.0;

running : bool;

#scope_file

buffers      : Slot_Array (Buffer);
text_layouts : Slot_Array (Text_Layout);
splits       : Slot_Array (Split);
active_split_id : Split_ID;

#scope_export

Split :: struct
{
	id : Split_ID;
	area : Rectf;
	buffer_ids : [..]Buffer_ID;
	active_buffer_index : s64;
}

get_active_split :: () -> Split_ID #must
{
	return active_split_id;
}
@Amber_API

buffer_exists :: inline (id : Buffer_ID) -> bool #must
{
	return id > 0 && id <= xx buffers.max_occupied && buffers.slots[cast (s64) id - 1].occupied;
}
@Amber_API

text_layout_exists :: inline (id : Text_Layout_ID) -> bool #must
{
	return id > 0 && id <= xx text_layouts.max_occupied && text_layouts.slots[cast (s64) id - 1].occupied;
}
@Amber_API

split_exists :: inline (id : Split_ID) -> bool #must
{
	return id > 0 && id <= xx splits.max_occupied && splits.slots[cast (s64) id - 1].occupied;
}
@Amber_API

split_get_area :: inline (split_id : Split_ID) -> Rectf #must
{
	split := get_split (split_id);
	
	return split.area;
}
@Amber_API

split_get_buffer_count :: inline (split_id : Split_ID) -> s64 #must
{
	split := get_split (split_id);
	
	return split.buffer_ids.count;
}
@Amber_API

split_get_buffer :: inline (split_id : Split_ID, index : s64) -> Buffer_ID #must
{
	split := get_split (split_id);
	assert (index >= 0 && index < split.buffer_ids.count, "Invalid buffer index (expected [0;%), got %).", split.buffer_ids.count, index);
	
	return split.buffer_ids[index];
}
@Amber_API

split_get_active_buffer :: inline (split_id : Split_ID) -> Buffer_ID #must
{
	split := get_split (split_id);
	
	return split.buffer_ids[split.active_buffer_index];
}
@Amber_API

split_create_left :: inline (split_id : Split_ID) -> Split_ID
{
	split := get_split (split_id);
	split.area = set_width (split.area, rect_width (split.area) * 0.5);
	new_split := add_split ();
	new_split.area = split.area;
	split.area = move (split.area, rect_width (split.area), 0);
	
	return new_split.id;
}
@Amber_API

split_create_right :: inline (split_id : Split_ID) -> Split_ID
{
	split := get_split (split_id);
	split.area = set_width (split.area, rect_width (split.area) * 0.5);
	new_split := add_split ();
	new_split.area = move (split.area, rect_width (split.area), 0);
	
	return new_split.id;
}
@Amber_API

split_create_above :: inline (split_id : Split_ID) -> Split_ID
{
	split := get_split (split_id);
	split.area = set_height (split.area, rect_height (split.area) * 0.5);
	new_split := add_split ();
	new_split.area = split.area;
	split.area = move (split.area, 0, rect_height (split.area));
	
	return new_split.id;
}
@Amber_API

split_create_below :: inline (split_id : Split_ID) -> Split_ID
{
	split := get_split (split_id);
	split.area = set_height (split.area, rect_height (split.area) * 0.5);
	new_split := add_split ();
	new_split.area = move (split.area, 0, rect_height (split.area));
	
	return new_split.id;
}
@Amber_API

split_merge_left :: inline (split_id : Split_ID)
{
	split := get_split (split_id);
	for * splits
	{
		if it.area.x2 == split.area.x1 && it.area.y1 == split.area.y1 && it.area.y2 == split.area.y2
		{
			split.area.x1 = it.area.x1;
			reset_array (*it.buffer_ids);
			remove it;
			
			break;
		}
	}
}
@Amber_API

split_merge_right :: inline (split_id : Split_ID)
{
	split := get_split (split_id);
	for * splits
	{
		if it.area.x1 == split.area.x2 && it.area.y1 == split.area.y1 && it.area.y2 == split.area.y2
		{
			split.area.x2 = it.area.x2;
			reset_array (*it.buffer_ids);
			remove it;
			
			break;
		}
	}
}
@Amber_API

split_merge_above :: inline (split_id : Split_ID)
{
	split := get_split (split_id);
	for * splits
	{
		if it.area.y2 == split.area.y1 && it.area.x1 == split.area.x1 && it.area.x2 == split.area.x2
		{
			split.area.y1 = it.area.y1;
			reset_array (*it.buffer_ids);
			remove it;
			
			break;
		}
	}
}
@Amber_API

split_merge_below :: inline (split_id : Split_ID)
{
	split := get_split (split_id);
	for * splits
	{
		if it.area.y1 == split.area.y2 && it.area.x1 == split.area.x1 && it.area.x2 == split.area.x2
		{
			split.area.y2 = it.area.y2;
			reset_array (*it.buffer_ids);
			remove it;
			
			break;
		}
	}
}
@Amber_API

buffer_open :: inline (split_id : Split_ID, filename : string) -> Buffer_ID
{
	split : *Split;
	if splits.count == 0
		split = add_split ();
	else
		split = get_split (split_id);
	buffer := add_buffer ();
	buffer.split_id = split.id;
	str, ok := platform_read_entire_file (filename, temp_allocator);
	utf8_str := utf8 (str);
	if ok
	{
		buffer.filename = clone_string (filename, heap_allocator);
		for utf8_str
			buffer_insert_at_cursor (buffer.id, it, WRITE_HEAD);
		buffer_move_cursor_to_beginning (buffer.id, WRITE_HEAD);
	}

	text_layout := add_text_layout ();
	text_layout.split_id = split.id;
	text_layout.font_id = 1;
	text_layout.font_height = 16;
	text_layout.area = split.area;
	buffer_set_text_layout (buffer.id, text_layout.id);
	push_into_array (*split.buffer_ids, buffer.id);
	
	return buffer.id;
}
@Amber_API

buffer_close :: inline (buffer_id : Buffer_ID)
{
	buffer := get_buffer (buffer_id);
	split  := get_split (buffer.split_id);
	for split.buffer_ids
	{
		if it == buffer_id
		{
			remove it;
			buffer_reset (buffer_id);
			remove_from_slot_array (*buffers, xx buffer_id - 1);
			
			return;
		}
	}
	panic ("Buffer with id % does not exist in split with id %.", buffer_id, split.id);
}
@Amber_API

buffer_set_text_layout :: inline (buffer_id : Buffer_ID, text_layout_id : Text_Layout_ID)
{
	layout := get_text_layout (text_layout_id);
	layout.buffer_id = buffer_id;
	buffer := get_buffer (buffer_id);
	buffer.text_layout_id = text_layout_id;
}
@Amber_API

add_buffer :: inline () -> *Buffer #must
{
	buffer, index := insert_into_slot_array (*buffers);
	buffer.id = cast (Buffer_ID) (index + 1);
	buffer_init (buffer.id, 10000);
	
	return buffer;
}

add_text_layout :: inline () -> *Text_Layout #must
{
	layout, index := insert_into_slot_array (*text_layouts);
	layout.id = cast (Text_Layout_ID) (index + 1);
	text_layout_init (layout.id, 10000);
	
	return layout;
}

add_split :: inline () -> *Split #must
{
	split, index := insert_into_slot_array (*splits);
	split.id = cast (Split_ID) (index + 1);
	init_array (*split.buffer_ids, 10, heap_allocator);
	
	return split;
}

get_buffer :: inline (id : Buffer_ID) -> *Buffer #must
{
	assert (buffer_exists (id), "Invalid buffer id (%).", id);
	
	return get_ptr (*buffers, cast (s64) id - 1);
}

get_text_layout :: inline (id : Text_Layout_ID) -> *Text_Layout #must
{
	assert (text_layout_exists (id), "Invalid text layout id (%).", id);
	
	return get_ptr (*text_layouts, cast (s64) id - 1);
}

get_split :: inline (id : Split_ID) -> *Split #must
{
	assert (split_exists (id), "Invalid split id (%).", id);
	
	return get_ptr (*splits, cast (s64) id - 1);
}

draw_split :: inline (split_id : Split_ID)
{
	active_buffer := get_buffer (split_get_active_buffer (split_id));
	draw_line_numbers (active_buffer.text_layout_id, rgba (150, 150, 150), RGBA_WHITE);
	draw_line_highlight (active_buffer.text_layout_id, rgba (255, 255, 255, 10));
	draw_selection (active_buffer.text_layout_id, rgba (50, 100, 200));
	draw_text_layout (active_buffer.text_layout_id, RGBA_WHITE);
}

main :: ()
{
	FONT_NAME :: "fonts/jetbrainsmono/JetBrainsMono-Regular.ttf";
	
	platform_init_window_and_gl ();
	draw_init ();
	font_init ();
	init_slot_array (*buffers, 10, heap_allocator);
	init_slot_array (*text_layouts, 10, heap_allocator);
	init_slot_array (*splits, 10, heap_allocator);
	load_extension ("user.dll");
	init_extensions ();
	
	font_loaded, font_id := font_load_from_file (FONT_NAME);
	if !font_loaded
	{
		platform_open_error_box ("Could not load font '%'.", FONT_NAME);
		return;
	}
	viewport := platform_get_viewport_size ();
	split := add_split ();
	active_split_id = split.id;
	buffer_id := buffer_open (active_split_id, "some_file.txt");
	buffer := get_buffer (buffer_id);
	layout := get_text_layout (buffer.text_layout_id);
	
	extensions_on_startup ();

	running = true;
	page := load_page (get_font (font_id), 16);
	line_height := cast (f32) (page.ascent - page.descent);
	is_dragging_cursor    := false;
	is_dragging_scrollbar := false;
	scrollbar_drag_offset := 0.0;
	scrollbar_rect : Rectf;
	scrollbar_alpha : u8;
	scrollbar_show_time : f32;
	cursor_view_alpha : u8;
	frame_start := platform_get_time ();
	while running
	{
		previous_frame_start := frame_start;
		frame_start = platform_get_time ();
		delta_time := cast (f32) (frame_start - previous_frame_start);
		reset_temporary_storage ();
		
		platform_reset_input_state ();
		modified := false;
		show_scrollbar := false;
		scroll_to_cursor := false;
		event : Input_Event;
		while platform_get_next_event (*event)
		{
			if extensions_on_input (event) then continue;

			if event.kind ==
			{
			case .TEXT_INPUT;
				buffer_insert_at_cursor (buffer.id, event.codepoint, ALL_CURSORS);
				modified = true;
				scroll_to_cursor = true;
				
			case .KEY_PRESS; #through;
			case .KEY_REPEAT;
				if event.key_code ==
				{
				case .ESCAPE;
					buffer_clear_cursors (buffer.id);
					buffer_clear_selection (buffer.id);
				
				case .RETURN;
					buffer_insert_at_cursor (buffer.id, #char "\n", ALL_CURSORS);
					modified = true;
					scroll_to_cursor = true;
				
				case .BACKSPACE;
					if event.mods == .CONTROL
						buffer_skip_word_backward (buffer.id, true, ALL_CURSORS, select = true);
					modified = buffer_backspace_selection (buffer.id, ALL_CURSORS);
					buffer_merge_duplicate_cursors (buffer.id);
					scroll_to_cursor = true;
				
				case .DELETE;
					if event.mods == .CONTROL
						buffer_skip_word_forward (buffer.id, true, ALL_CURSORS, select = true);
					modified = buffer_delete_selection (buffer.id, ALL_CURSORS);
					buffer_merge_duplicate_cursors (buffer.id);
					scroll_to_cursor = true;
				
				case .LEFT;
					if flagged (event.mods, .CONTROL) && !flagged (event.mods, .ALT)
						buffer_skip_word_backward (buffer.id, true, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
					else
						buffer_move_cursor_backward (buffer.id, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
					buffer_merge_duplicate_cursors (buffer.id);
					scroll_to_cursor = true;
				
				case .RIGHT;
					if remove_flag (event.mods, .SHIFT) == .CONTROL
						buffer_skip_word_forward (buffer.id, true, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
					else
						buffer_move_cursor_forward (buffer.id, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
					buffer_merge_duplicate_cursors (buffer.id);
					scroll_to_cursor = true;
				
				case .UP;
					if event.mods == Mods.SHIFT | .ALT
					{
						buffer_add_cursor_on_previous_line (buffer.id, ALL_CURSORS);
						scroll_to_cursor = true;
					}
					else if event.mods == Mods.CONTROL
					{
						layout.scroll.y -= 1;
						show_scrollbar = true;
					}
					else
					{
						buffer_move_cursor_to_previous_line (buffer.id, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
						buffer_merge_duplicate_cursors (buffer.id);
						scroll_to_cursor = true;
					}
					
				case .DOWN;
					if event.mods == Mods.SHIFT | .ALT
					{
						buffer_add_cursor_on_next_line (buffer.id, ALL_CURSORS);
						scroll_to_cursor = true;
					}
					else if event.mods == Mods.CONTROL
					{
						layout.scroll.y += 1;
						show_scrollbar = true;
					}
					else
					{
						buffer_move_cursor_to_next_line (buffer.id, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
						buffer_merge_duplicate_cursors (buffer.id);
						scroll_to_cursor = true;
					}

				case .PAGE_UP;
					if remove_flag (event.mods, .SHIFT) == .CONTROL
					{
						layout.scroll.y -= 30;
						show_scrollbar = true;
					}
					else
					{
						for 1..30
						{
							if !buffer_move_cursor_to_previous_line (buffer.id, ALL_CURSORS, select = flagged (event.mods, .SHIFT))
								break;
						}
						buffer_merge_duplicate_cursors (buffer.id);
						scroll_to_cursor = true;
					}
				
				case .PAGE_DOWN;
					if remove_flag (event.mods, .SHIFT) == .CONTROL
					{
						layout.scroll.y += 30;
						show_scrollbar = true;
					}
					else
					{
						for 1..30
						{
							if !buffer_move_cursor_to_next_line (buffer.id, ALL_CURSORS, select = flagged (event.mods, .SHIFT))
								break;
						}
						buffer_merge_duplicate_cursors (buffer.id);
						scroll_to_cursor = true;
					}
				}

			case .MOUSE_PRESS; #through;
			case .MOUSE_REPEAT;
				if event.mouse_button == .LEFT && contains (scrollbar_rect, event.mouse_position)
				{
					scrollbar_drag_offset = scrollbar_rect.y1 - event.mouse_position.y;
					is_dragging_scrollbar = true;
				}
				else if event.mouse_button == .LEFT && contains (layout.area, event.mouse_position)
				{
					if event.mods == Mods.ALT
					{
						offset := text_layout_get_closest_character (layout.id, event.mouse_position);
						buffer_add_cursor_at_offset (buffer.id, offset);
					}
					else
					{
						offset := text_layout_get_closest_character (layout.id, platform_get_mouse_position ());
						buffer_clear_cursors (buffer.id);
						buffer_move_cursor_to_offset (buffer.id, offset, WRITE_HEAD);
						is_dragging_cursor = true;
					}
					scroll_to_cursor = true;
				}
				show_scrollbar = true;
			
			case .MOUSE_WHEEL;
				if contains (layout.area, event.mouse_position)
				{
					layout.scroll -= event.mouse_wheel;
					show_scrollbar = true;
				}
			}
		}
		
		if platform_get_mouse_button_state (.LEFT) == .DOWN
		{
			if is_dragging_cursor
			{
				offset := text_layout_get_closest_character (layout.id, platform_get_mouse_position ());
				buffer_clear_cursors (buffer.id);
				buffer_move_cursor_to_offset (buffer.id, offset, WRITE_HEAD, select = true);
				scroll_to_cursor = true;
			}
			else if is_dragging_scrollbar
			{
				mouse_position := platform_get_mouse_position ();
				scrollbar_rect = set_position (scrollbar_rect, vec2f (scrollbar_rect.x1, mouse_position.y + scrollbar_drag_offset));
				scrolling_area := rect_height (layout.area) - rect_height (scrollbar_rect);
				scroll_percent := scrollbar_rect.y1 / scrolling_area;
				layout.scroll.y = round (scroll_percent * max (layout.extents.y / line_height - 1, 0));
			}
		}
		else if platform_get_mouse_button_state (.LEFT) != .PRESSED
		{
			is_dragging_cursor = false;
			is_dragging_scrollbar = false;
		}
		
		wave := cos (cast (f32) platform_get_time () * 0.2) * 0.5 + 0.5;
		line_number_len := 0;
		{
			tmp := buffer.lines.count;
			while tmp > 0
			{
				line_number_len += 1;
				tmp /= 10;
			}
		}
		viewport := platform_get_viewport_size ();
		area := rectf (cast (f32) (line_number_len + 2) * page.space_advance, 0, xx viewport.width, xx viewport.height - cast (f32) (page.ascent - page.descent));
		if modified then language_process_buffer (buffer.id);
		if area != layout.area || modified
		{
			layout.area = area;
			start := platform_get_time ();
			text_layout_compute (layout.id);
			end := platform_get_time ();
			println ("Laying out took % ms.", (end - start) * 1000);
		}
		cursor_rect := text_layout_get_rect (layout.id, buffer.offset);
		layout.scroll.x = clamp (layout.scroll.x, 0, max ((layout.extents.x - rect_width (layout.area)) / cast (f32) (page.space_advance) - 1, 0));
		if scroll_to_cursor
		{
			if cursor_rect.y1 - CURSOR_MARGIN * line_height < layout.area.y1
			{
				layout.scroll.y += (cursor_rect.y1 - CURSOR_MARGIN * line_height - layout.area.y1) / line_height;
				show_scrollbar = true;
			}
			if cursor_rect.y2 + CURSOR_MARGIN * line_height > layout.area.y2
			{
				layout.scroll.y += (cursor_rect.y2 + CURSOR_MARGIN * line_height - layout.area.y2) / line_height;
				show_scrollbar = true;
			}
		}
		layout.scroll.y      = clamp (layout.scroll.y, 0, max (layout.extents.y / line_height - 1, 0));
		layout.visual_scroll = lerp (layout.visual_scroll, vec2f (round (layout.scroll.x), round (layout.scroll.y)), 0.5);
		scrollbar_show_time  = max (scrollbar_show_time - delta_time, 0);
		if show_scrollbar then scrollbar_show_time = MAX_SCROLLBAR_SHOW_TIME;

		extensions_on_update ();
		
		draw_begin ();
		
		for splits
		{
			id := cast (Split_ID) (it_index + 1);
			draw_split (id);
		}
		
		max_visible := layout.extents.y - line_height + rect_height (layout.area);
		visible_area := rect_height (layout.area) / max_visible;
		scroll_percent := layout.visual_scroll.y / max (layout.extents.y / line_height - 1, 0);
		scrollbar_height := max (visible_area * rect_height (layout.area), MIN_SCROLLBAR_HEIGHT);
		scrolling_area   := rect_height (layout.area) - scrollbar_height;
		scrollbar_rect  = xywhf (layout.area.x2 - SCROLLBAR_WIDTH, layout.area.y1 + scrolling_area * scroll_percent, SCROLLBAR_WIDTH, scrollbar_height);
		if is_dragging_scrollbar
			scrollbar_alpha = lerp (scrollbar_alpha, 200, 0.3);
		else if contains (scrollbar_rect, platform_get_mouse_position ())
			scrollbar_alpha = lerp (scrollbar_alpha, 150, 0.3);
		else if scrollbar_show_time > 0 || contains (rectf (layout.area.x2 - SCROLLBAR_WIDTH, layout.area.y1, layout.area.x2, layout.area.y2), platform_get_mouse_position ())
			scrollbar_alpha = lerp (scrollbar_alpha, 50, 0.3);
		else
			scrollbar_alpha = lerp (scrollbar_alpha, 0, 0.3);
		
		if scrollbar_show_time > 0 || is_dragging_scrollbar || contains (rectf (layout.area.x2 - SCROLLBAR_WIDTH, layout.area.y1, layout.area.x2, layout.area.y2), platform_get_mouse_position ())
			cursor_view_alpha = lerp (cursor_view_alpha, 255, 0.3);
		else
			cursor_view_alpha = lerp (cursor_view_alpha, 0, 0.3);
		draw_rect (scrollbar_rect, rgba (RGBA_WHITE, scrollbar_alpha), rect_width (scrollbar_rect) * 0.5);
		cursor_position := (layout.rects[buffer.offset].y1 / max_visible) * rect_height (layout.area);
		draw_rect (xywhf (layout.area.x2 - SCROLLBAR_WIDTH, layout.area.y1 + cursor_position, SCROLLBAR_WIDTH, 2), rgba (RGBA_WHITE, cursor_view_alpha));
		
		draw_rect (xywhf (0, xx (viewport.height - page.ascent + page.descent), xx viewport.width, xx (page.ascent - page.descent)), RGBA_WHITE);
		draw_text (
			font_id,
			16,
			vec2f (0, xx (viewport.height - (page.ascent - page.descent))),
			fstring (temp_allocator, "Ln %, Col % ~ % line(s)", buffer.line_index + 1, buffer.column_index + 1, buffer.lines.count),
			RGBA_BLACK
		);
		
		/*
		for splits
		{
			draw_rect (truncate_all_sides (it.area, 1), RGBA_WHITE);
		}
		*/

		draw_end ();
		platform_swap_window_buffers ();
		frame_end := platform_get_time ();
		//println ("Frame took % milliseconds.", (frame_end - frame_start) * 1000);
		platform_sleep_milliseconds (cast (s64) max (16 - (frame_end - frame_start) * 1000, 0));
	}

	extensions_on_shutdown ();
	cleanup_extensions ();
}

draw_text :: (font_id : Font_ID, height : u32, position : Vec2f, text : string, color : RGBA)
{
	prev_texture := draw_get_texture ();
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);
	
	font := get_font (font_id);
	page := load_page (font, height);
	pen : Vec2f;
	for i : 0..text.count - 1
	{
		codepoint : u32 = text[i];
		if codepoint ==
		{
		case #char "\n";
			pen.x = 0;
			pen.y += page.ascent - page.descent;
		
		case #char "\t";
			pen.x = snap_up (pen.x + page.space_advance, page.space_advance * 4.0);
		
		case;
			glyph := load_glyph (page, codepoint);
			glyph_rect := xywhf (
				pen.x + glyph.bitmap_bearing_x,
				pen.y - glyph.bitmap_bearing_y + page.ascent,
				xx glyph.bitmap_width,
				xx glyph.bitmap_height
			);
			glyph_rect = move (glyph_rect, round (position.x), round (position.y));
			draw_set_texture (glyph.atlas_texture);
			draw_rect (glyph_rect, color, uv_rect = glyph.uv_rect);
			pen.x += glyph.advance;
		}
	}
}
@Amber_API
