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

add_split :: inline () -> *Split #must
{
	split, index := insert_into_slot_array (*splits);
	split.id = cast (Split_ID) (index + 1);
	init_array (*split.opened_buffer_ids, 10, heap_allocator);
	
	return split;
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

split_exists :: inline (id : Split_ID) -> bool #must
{
	return id > 0 && id <= xx splits.max_occupied && splits.slots[cast (s64) id - 1].occupied;
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
		layout := get_text_layout (buffer_get_text_layout (buffer_id));
		font := get_font (layout.font_id);
		page := load_page (font, layout.font_height);
		line_number_len := count_digits (buffer_get_line_count (buffer_id));
		layout.area = rectf (
			area.x1 + cast (f32) (line_number_len + 2) * page.space_advance,
			area.y1,
			area.x2,
			area.y2 - cast (f32) (page.ascent - page.descent)
		);
		layout.is_dirty = true;
	}
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

split_create_first :: inline () -> Split_ID
{
	assert (splits.count == 0, "Trying to create the first split, but % splits already exist.", splits.count);
	
	viewport := platform_get_viewport_size ();
	split := add_split ();
	split.area = rectf (0, 0, xx viewport.width, xx viewport.height);
	buffer_open (split.id, "", "");
	
	return split.id;
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
			for buffer_id : it.opened_buffer_ids
				push_into_array (*split.opened_buffer_ids, buffer_id);
			reset_array (*it.opened_buffer_ids);
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
			for buffer_id : it.opened_buffer_ids
				push_into_array (*split.opened_buffer_ids, buffer_id);
			reset_array (*it.opened_buffer_ids);
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
			for buffer_id : it.opened_buffer_ids
				push_into_array (*split.opened_buffer_ids, buffer_id);
			reset_array (*it.opened_buffer_ids);
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
			for buffer_id : it.opened_buffer_ids
				push_into_array (*split.opened_buffer_ids, buffer_id);
			reset_array (*it.opened_buffer_ids);
			remove it;
			
			break;
		}
	}
}
@Amber_API

split_get_scrollbar_rect :: (split_id : Split_ID) -> Rectf #must
{
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);
	line_height    := text_layout_get_line_height (active_layout_id);
	layout_extents := text_layout_get_extents (active_layout_id);
	layout_area    := text_layout_get_area (active_layout_id);
	max_visible  := layout_extents.y - line_height + rect_height (layout_area);
	visible_area := rect_height (layout_area) / max_visible;
	scroll_percent   := text_layout_get_visual_scroll (active_layout_id).y / max (layout_extents.y / line_height - 1, 0);
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
	
	if event_result.buffer_modified
	{
		language_process_buffer (active_buffer_id);
		text_layout_set_dirty (active_layout_id);
	}
	if text_layout_is_dirty (active_layout_id)
		text_layout_compute (active_layout_id);
	
	line_height := text_layout_get_line_height (active_layout_id);
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
			scroll_percent := scrollbar_rect.y1 / (rect_height (text_layout_get_area (active_layout_id)) - rect_height (scrollbar_rect));
			text_layout_set_scroll_y (active_layout_id, round (scroll_percent * max (text_layout_get_extents (active_layout_id).y / line_height - 1, 0)));
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
			text_layout_scroll_y (active_layout_id, (cursor_rect.y1 - layout_area.y1) / line_height);
			show_scrollbar = true;
		}
		if cursor_rect.y2 > layout_area.y2
		{
			text_layout_scroll_y (active_layout_id, (cursor_rect.y2 - layout_area.y2) / line_height);
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
	else
		platform_set_cursor (.ARROW);
}

split_draw :: inline (split_id : Split_ID)
{
	using split := get_split (split_id);
	active_buffer_id := split_get_active_buffer (split_id);
	active_layout_id := buffer_get_text_layout (active_buffer_id);
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
	
	max_visible  := layout_extents.y - line_height + rect_height (layout_area);
	cursor_view_position := (text_layout_get_relative_rect (active_layout_id, buffer_get_cursor (active_buffer_id, WRITE_HEAD).offset).y1 / max_visible) * rect_height (layout_area);
	
	draw_rect (scrollbar_rect, rgba (RGBA_WHITE, split.scrollbar_alpha), rect_width (scrollbar_rect) * 0.5);
	draw_rect (xywhf (layout_area.x2 - SCROLLBAR_WIDTH, layout_area.y1 + cursor_view_position, SCROLLBAR_WIDTH, 2), rgba (RGBA_WHITE, split.cursor_view_alpha));
}
