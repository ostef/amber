Split :: struct
{
	id : Split_ID;
	area : Rectf;
	opened_buffer_ids : [..]Buffer_ID;
	active_buffer_index : s64;
	
	is_dragging_cursor    : bool;
	is_dragging_scrollbar : bool;
	scrollbar_drag_offset : f32;
	scrollbar_alpha : u8;
	scrollbar_show_time : f32;
	cursor_view_alpha : u8;
}

SCROLLBAR_WIDTH         :: 10.0;
MIN_SCROLLBAR_HEIGHT    :: 25.0;
MAX_SCROLLBAR_SHOW_TIME :: 3.0;
TAB_WIDTH  :: 150.0;
TAB_HEIGHT :: 30.0;

add_split :: inline () -> *Split #must
{
	split, index := insert_into_slot_array (*splits);
	split.id = cast (Split_ID) (index + 1);
	split_init (split.id);
	
	return split;
}

remove_split :: inline (split_id : Split_ID)
{
	split_reset (split_id);
	remove_from_slot_array (*splits, xx (split_id - 1));
}

get_split :: inline (id : Split_ID) -> *Split #must
{
	assert (split_exists (id), "Invalid split id (%).", id);
	
	return get_ptr (*splits, cast (s64) id - 1);
}

get_active_split :: inline () -> Split_ID #must
{
	return active_split_id;
}
@Amber_API

set_active_split :: inline (split_id : Split_ID)
{
	assert (split_exists (split_id), "Invalid split id (%).", split_id);
	active_split_id = split_id;
}
@Amber_API

split_exists :: inline (id : Split_ID) -> bool #must
{
	return id > 0 && id <= xx splits.max_occupied && splits.slots[cast (s64) id - 1].occupied;
}
@Amber_API

split_init :: inline (split_id : Split_ID)
{
	using split := get_split (split_id);
	init_array (*opened_buffer_ids, 20, heap_allocator);
}

split_reset :: inline (split_id : Split_ID)
{
	using split := get_split (split_id);
	reset_array (*opened_buffer_ids);
}

split_open_buffer :: (split_id : Split_ID) -> Buffer_ID
{
	using split := get_split (split_id);
	buffer := add_buffer ();
	buffer.split_id = split_id;
	push_into_array (*opened_buffer_ids, buffer.id);
	active_buffer_index = opened_buffer_ids.count - 1;
	layout := add_text_layout ();
	layout.font_id = 1;	// @Temporary
	layout.font_height = 16;	// @Temporary
	layout.split_id = split_id;
	buffer_set_text_layout (buffer.id, layout.id);
	language_process_buffer (buffer.id);
	text_layout_update_area (layout.id);
	text_layout_compute (layout.id);
	
	return buffer.id;
}
@Amber_API

split_close_buffer :: (split_id : Split_ID, buffer_index : s64)
{
	using split := get_split (split_id);
	buffer_id := split_get_buffer (split_id, buffer_index);
	remove_text_layout (buffer_get_text_layout (buffer_id));
	remove_buffer (buffer_id);
	sorted_remove_from_array (*opened_buffer_ids, buffer_index);
}
@Amber_API

split_get_area :: inline (split_id : Split_ID) -> Rectf #must
{
	using split := get_split (split_id);
	
	return area;
}
@Amber_API

split_set_area :: inline (split_id : Split_ID, new_area : Rectf)
{
	using split := get_split (split_id);
	area = new_area;
	for buffer_id : opened_buffer_ids
	{
		layout_id := buffer_get_text_layout (buffer_id);
		font := get_font (text_layout_get_font (layout_id));
		page := load_page (font, text_layout_get_font_height (layout_id));
		line_height := cast (f32) (page.ascent - page.descent);
		line_number_len := count_digits (buffer_get_line_count (buffer_id));
		text_layout_update_area (layout_id);
	}
}
@Amber_API

split_get_text_layout_area :: inline (split_id : Split_ID) -> Rectf #must
{
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);
	column_width := text_layout_get_column_width (active_layout_id);
	line_height  := text_layout_get_line_height (active_layout_id);
	area := split_get_area (split_id);
	line_number_len := count_digits (buffer_get_line_count (active_buffer_id));
	
	return rectf (
		area.x1 + cast (f32) (line_number_len + 2) * column_width,
		area.y1 + TAB_HEIGHT,
		area.x2,
		area.y2 - line_height
	);
}
@Amber_API

split_get_buffer_count :: inline (split_id : Split_ID) -> s64 #must
{
	using split := get_split (split_id);
	
	return opened_buffer_ids.count;
}
@Amber_API

split_get_buffer :: inline (split_id : Split_ID, index : s64) -> Buffer_ID #must
{
	using split := get_split (split_id);
	assert (index >= 0 && index < opened_buffer_ids.count, "Invalid buffer index (expected [0;%), got %).", opened_buffer_ids.count, index);
	
	return opened_buffer_ids[index];
}
@Amber_API

split_get_active_buffer_index :: inline (split_id : Split_ID) -> s64 #must
{
	using split := get_split (split_id);
	
	return active_buffer_index;
}
@Amber_API

split_get_active_buffer :: inline (split_id : Split_ID) -> Buffer_ID #must
{
	using split := get_split (split_id);
	
	return opened_buffer_ids[active_buffer_index];
}
@Amber_API

split_get_active_text_layout :: inline (split_id : Split_ID) -> Text_Layout_ID #must
{
	return buffer_get_text_layout (split_get_active_buffer (split_id));
}
@Amber_API

split_create_first :: inline () -> Split_ID
{
	assert (splits.count == 0, "Trying to create the first split, but % splits already exist.", splits.count);
	
	viewport := platform_get_viewport_size ();
	split := add_split ();
	split.area = rectf (0, 0, xx viewport.width, xx viewport.height);
	split_open_buffer (split.id);
	set_active_split (split.id);
	
	return split.id;
}
@Amber_API

split_get_scrollbar_rect :: (split_id : Split_ID) -> Rectf #must
{
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);
	line_height    := text_layout_get_line_height (active_layout_id);
	layout_extents := text_layout_get_extents (active_layout_id);
	layout_area    := text_layout_get_area (active_layout_id);
	max_scroll     := text_layout_get_max_scroll (active_layout_id);
	max_visible    := layout_extents.y;
	visible_area := rect_height (layout_area) / max_visible;
	scroll_percent   := text_layout_get_visual_scroll (active_layout_id).y / max_scroll.y;
	scrollbar_height := max (visible_area * rect_height (layout_area), MIN_SCROLLBAR_HEIGHT);
	scrolling_area   := rect_height (layout_area) - scrollbar_height;
	scrollbar_rect   := xywhf (layout_area.x2 - SCROLLBAR_WIDTH, layout_area.y1 + scrolling_area * scroll_percent, SCROLLBAR_WIDTH, scrollbar_height);

	return scrollbar_rect;
}
@Amber_API

split_handle_event :: (split_id : Split_ID, event : Event) -> Event_Result #must
{
	using result : Event_Result;
	using split := get_split (split_id);
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);
	if event.kind ==
	{
	case .TEXT_INPUT;
		buffer_insert_at_cursor (active_buffer_id, event.codepoint, ALL_CURSORS);
		buffer_modified = true;
		scroll_to_cursor = true;
		
	case .KEY_PRESS; #through;
	case .KEY_REPEAT;
		if event.key_code ==
		{
		case .ESCAPE;
			buffer_clear_cursors (active_buffer_id);
			buffer_clear_selection (active_buffer_id);
		
		case .RETURN;
			buffer_insert_at_cursor (active_buffer_id, #char "\n", ALL_CURSORS);
			buffer_modified = true;
			scroll_to_cursor = true;
		
		case .BACKSPACE;
			if event.mods == .CONTROL
				buffer_skip_word_backward (active_buffer_id, true, ALL_CURSORS, select = true);
			buffer_modified = buffer_backspace_selection (active_buffer_id, ALL_CURSORS);
			buffer_merge_duplicate_cursors (active_buffer_id);
			scroll_to_cursor = true;
		
		case .DELETE;
			if event.mods == .CONTROL
				buffer_skip_word_forward (active_buffer_id, true, ALL_CURSORS, select = true);
			buffer_modified = buffer_delete_selection (active_buffer_id, ALL_CURSORS);
			buffer_merge_duplicate_cursors (active_buffer_id);
			scroll_to_cursor = true;
		
		case .LEFT; #through;
		case .RIGHT;
			right := event.key_code == .RIGHT;
			skip_word := ifx right then buffer_skip_word_forward else buffer_skip_word_backward;
			move_cursor := ifx right then buffer_move_cursor_forward else buffer_move_cursor_backward;
			if flagged (event.mods, .CONTROL) && !flagged (event.mods, .ALT)
				skip_word (active_buffer_id, true, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
			else
				move_cursor (active_buffer_id, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
			buffer_merge_duplicate_cursors (active_buffer_id);
			scroll_to_cursor = true;
		
		case .UP; #through;
		case .DOWN;
			down := event.key_code == .DOWN;
			if event.mods == Mods.SHIFT | .ALT
			{
				add_cursor := ifx down then buffer_add_cursor_on_next_line else buffer_add_cursor_on_previous_line;
				add_cursor (active_buffer_id, ALL_CURSORS);
				scroll_to_cursor = true;
			}
			else if event.mods == Mods.CONTROL
			{
				text_layout_scroll_y (active_layout_id, cast (int) down * 2.0 - 1);
				show_scrollbar = true;
			}
			else
			{
				move_cursor := ifx down then buffer_move_cursor_to_next_line else buffer_move_cursor_to_previous_line;
				move_cursor (active_buffer_id, ALL_CURSORS, select = flagged (event.mods, .SHIFT));
				buffer_merge_duplicate_cursors (active_buffer_id);
				scroll_to_cursor = true;
			}
			
		case .PAGE_UP; #through;
		case .PAGE_DOWN;
			down := event.key_code == .PAGE_DOWN;
			if remove_flag (event.mods, .SHIFT) == .CONTROL
			{
				text_layout_scroll_y (active_layout_id, 30 * (cast (int) down * 2.0 - 1));
				show_scrollbar = true;
			}
			else
			{
				move_cursor := ifx down then buffer_move_cursor_to_next_line else buffer_move_cursor_to_previous_line;
				for 1..30
				{
					if !move_cursor (active_buffer_id, ALL_CURSORS, select = flagged (event.mods, .SHIFT))
						break;
				}
				buffer_merge_duplicate_cursors (active_buffer_id);
				scroll_to_cursor = true;
			}
		}
		
	case .MOUSE_WHEEL;
		if contains (text_layout_get_area (active_layout_id), event.mouse_position)
		{
			text_layout_set_scroll (active_layout_id, text_layout_get_scroll (active_layout_id) - event.mouse_wheel);
			show_scrollbar = true;
		}
	
	case .MOUSE_PRESS;
		if event.mouse_button == .LEFT
		{
			scrollbar_rect := split_get_scrollbar_rect (split_id);
			if contains (scrollbar_rect, event.mouse_position)
			{
				is_dragging_scrollbar = true;
				scrollbar_drag_offset = scrollbar_rect.y1 - event.mouse_position.y;
			}
			else if contains (text_layout_get_area (active_layout_id), event.mouse_position)
			{
				offset := text_layout_get_closest_character (active_layout_id, event.mouse_position);
				if event.mods == .ALT
				{
					buffer_add_cursor_at_offset (active_buffer_id, offset);
				}
				else
				{
					buffer_clear_cursors (active_buffer_id);
					buffer_move_cursor_to_offset (active_buffer_id, offset, WRITE_HEAD);
					is_dragging_cursor = true;
				}
				scroll_to_cursor = true;
			}
			show_scrollbar = true;
		}
	}

	return result;
}

split_update :: (split_id : Split_ID, using event_result : *Event_Result, delta_time : f32)
{
	using split := get_split (split_id);
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);
	font := get_font (text_layout_get_font (active_layout_id));
	page := load_page (font, text_layout_get_font_height (active_layout_id));
	line_height := cast (f32) (page.ascent - page.descent);
	
	if event_result.buffer_modified
	{
		language_process_buffer (active_buffer_id);
		line_number_len := count_digits (buffer_get_line_count (active_buffer_id));
		text_layout_update_area (active_layout_id);
		text_layout_set_dirty (active_layout_id);
	}
	if text_layout_is_dirty (active_layout_id)
		text_layout_compute (active_layout_id);
	
	layout_area := text_layout_get_area (active_layout_id);
	mouse_position := platform_get_mouse_position ();
	// Select text with mouse and drag scrollbar
	if platform_get_mouse_button_state (.LEFT) == .DOWN
	{
		if is_dragging_cursor
		{
			offset := text_layout_get_closest_character (active_layout_id, mouse_position);
			buffer_clear_cursors (active_buffer_id);
			buffer_move_cursor_to_offset (active_buffer_id, offset, WRITE_HEAD, select = true);
			scroll_to_cursor = true;
		}
		else if is_dragging_scrollbar
		{
			scrollbar_rect := split_get_scrollbar_rect (split_id);
			scrollbar_rect = set_position (scrollbar_rect, vec2f (scrollbar_rect.x1, mouse_position.y + scrollbar_drag_offset));
			scroll_percent := (scrollbar_rect.y1 - layout_area.y1) / (rect_height (layout_area) - rect_height (scrollbar_rect));
			text_layout_set_scroll_y (active_layout_id, round (scroll_percent * text_layout_get_max_scroll (active_layout_id).y));
		}
	}
	else if platform_get_mouse_button_state (.LEFT) != .PRESSED
	{
		is_dragging_cursor    = false;
		is_dragging_scrollbar = false;
	}

	// Scroll to cursor, limit scrolling and update visual scroll
	if scroll_to_cursor
	{
		cursor_rect := text_layout_get_rect (active_layout_id, buffer_get_cursor (active_buffer_id, WRITE_HEAD).offset);
		if cursor_rect.y1 < layout_area.y1
		{
			text_layout_scroll_y (active_layout_id, ceil ((cursor_rect.y1 - layout_area.y1) / line_height));
			show_scrollbar = true;
		}
		if cursor_rect.y2 > layout_area.y2
		{
			text_layout_scroll_y (active_layout_id, ceil ((cursor_rect.y2 - layout_area.y2) / line_height));
			show_scrollbar = true;
		}
	}
	text_layout_set_scroll (active_layout_id, clamp (text_layout_get_scroll (active_layout_id), vec2f (0, 0), text_layout_get_max_scroll (active_layout_id)));
	text_layout_set_visual_scroll (active_layout_id, lerp (text_layout_get_visual_scroll (active_layout_id), round (text_layout_get_scroll (active_layout_id)), 0.5));
	scrollbar_show_time = max (scrollbar_show_time - delta_time, 0);
	if show_scrollbar then scrollbar_show_time = MAX_SCROLLBAR_SHOW_TIME;
	
	// Set cursor graphics
	if contains (layout_area, mouse_position) && !contains (split_get_scrollbar_rect (split_id), mouse_position)
		platform_set_cursor (.IBEAM);
	else if contains (split.area, mouse_position)
		platform_set_cursor (.ARROW);
}

split_draw :: (split_id : Split_ID)
{
	using split := get_split (split_id);
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);

	for buffer_id : opened_buffer_ids
		draw_rect (xywhf (area.x1 + it_index * TAB_WIDTH, area.y1, TAB_WIDTH, TAB_HEIGHT), rgba (50, 50, 50, 255), 10.0, Rectangle_Corners.TOP_LEFT | .TOP_RIGHT);

	draw_line_numbers (active_layout_id, rgba (150, 150, 150), RGBA_WHITE);
	draw_line_highlight (active_layout_id, rgba (255, 255, 255, 10));
	draw_selection (active_layout_id, rgba (50, 100, 200));
	draw_text_layout (active_layout_id);

	scrollbar_rect := split_get_scrollbar_rect (split_id);
	line_height    := text_layout_get_line_height (active_layout_id);
	layout_extents := text_layout_get_extents (active_layout_id);
	layout_area    := text_layout_get_area (active_layout_id);
	mouse_position := platform_get_mouse_position ();
	if is_dragging_scrollbar
		split.scrollbar_alpha = lerp (split.scrollbar_alpha, 200, 0.3);
	else if contains (scrollbar_rect, mouse_position)
		split.scrollbar_alpha = lerp (split.scrollbar_alpha, 150, 0.3);
	else if scrollbar_show_time > 0 || contains (rectf (layout_area.x2 - SCROLLBAR_WIDTH, layout_area.y1, layout_area.x2, layout_area.y2), mouse_position)
		split.scrollbar_alpha = lerp (split.scrollbar_alpha, 50, 0.3);
	else
		split.scrollbar_alpha = lerp (split.scrollbar_alpha, 0, 0.3);
	
	if split.scrollbar_show_time > 0 || is_dragging_scrollbar || contains (rectf (layout_area.x2 - SCROLLBAR_WIDTH, layout_area.y1, layout_area.x2, layout_area.y2), mouse_position)
		split.cursor_view_alpha = lerp (split.cursor_view_alpha, 255, 0.3);
	else
		split.cursor_view_alpha = lerp (split.cursor_view_alpha, 0, 0.3);
	
	max_visible  := layout_extents.y;
	cursor_view_position := (text_layout_get_relative_rect (active_layout_id, buffer_get_cursor (active_buffer_id, WRITE_HEAD).offset).y1 / max_visible) * rect_height (layout_area);
	
	draw_rect (scrollbar_rect, rgba (RGBA_WHITE, split.scrollbar_alpha), rect_width (scrollbar_rect) * 0.5);
	draw_rect (xywhf (layout_area.x2 - SCROLLBAR_WIDTH, layout_area.y1 + cursor_view_position, SCROLLBAR_WIDTH, 2), rgba (RGBA_WHITE, split.cursor_view_alpha));

	draw_rect (rectf (split.area.x1, split.area.y2 - line_height, split.area.x2, split.area.y2), RGBA_WHITE);
	draw_text (
		text_layout_get_font (active_layout_id),
		text_layout_get_font_height (active_layout_id),
		vec2f (split.area.x1, split.area.y2 - line_height),
		fstring (
			temp_allocator,
			"Ln %, Col % ~ % line(s)",
			buffer_get_line_index (active_buffer_id) + 1,
			buffer_get_column_index (active_buffer_id) + 1,
			buffer_get_line_count (active_buffer_id)
		),
		RGBA_BLACK
	);

	if split_id == get_active_split ()
		draw_rect_outline (truncate_all_sides (area, 1.5), rgba (50, 100, 200, 128), 3, 5.0);
}
