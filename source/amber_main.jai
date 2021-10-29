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
#load "amber_split.jai";
#load "amber_language.jai";
#load "amber_extension.jai";

CURSOR_ROUNDING :: 3.0;
CURSOR_MARGIN   :: 0;

viewport_size : Vec2i;
running : bool;
splits       : Slot_Array (Split);
buffers      : Slot_Array (Buffer);
text_layouts : Slot_Array (Text_Layout);
active_split_id : Split_ID;

handle_event :: inline (event : Event) -> Event_Result #must
{
	using result : Event_Result;
	if event.kind ==
	{
	case .WINDOW_CLOSE;
		running = false;
		
	case .WINDOW_RESIZE;
		for * split : splits
		{
			new_area := rectf (
				(split.area.x1 / cast (f32) viewport_size.x) * event.viewport_size.x,
				(split.area.y1 / cast (f32) viewport_size.y) * event.viewport_size.y,
				(split.area.x2 / cast (f32) viewport_size.x) * event.viewport_size.x,
				(split.area.y2 / cast (f32) viewport_size.y) * event.viewport_size.y
			);
			split_set_area (split.id, new_area);
		}
		viewport_size = event.viewport_size;
	
	case .MOUSE_PRESS;
		for splits
		{
			if contains (it.area, event.mouse_position)
			{
				active_split_id = it.id;
				
				break;
			}
		}
	}
	
	return result;
}

main :: ()
{
	FONT_NAME :: "fonts/jetbrainsmono/JetBrainsMono-Regular.ttf";
	
	platform_init_window_and_gl ();
	viewport_size = platform_get_viewport_size ();
	draw_init ();
	font_init ();
	init_slot_array (*buffers, 20, heap_allocator);
	init_slot_array (*text_layouts, 20, heap_allocator);
	init_slot_array (*splits, 10, heap_allocator);
	load_extension ("user.dll");
	init_extensions ();
	font_load_from_file (FONT_NAME);
	split_create_first ();
	
	running = true;
	frame_start := platform_get_time ();
	while running
	{
		previous_frame_start := frame_start;
		frame_start = platform_get_time ();
		delta_time := cast (f32) (frame_start - previous_frame_start);
		reset_temporary_storage ();
		event : Event;
		event_result : Event_Result;
		platform_reset_input_state ();
		while platform_get_next_event (*event)
		{
			event_result ||= handle_event (event);
			extensions_result, propagate := extensions_on_event (event);
			event_result ||= extensions_result;
			if !propagate then continue;
			if active_split_id != NULL_SPLIT
				event_result ||= split_handle_event (active_split_id, event);
		}

		if active_split_id != NULL_SPLIT
			split_update (active_split_id, *event_result, delta_time);
		extensions_on_update ();
		
		draw_begin ();
		for splits
			split_draw (it.id);
		draw_end ();
		platform_swap_window_buffers ();
		frame_end := platform_get_time ();
		platform_sleep_milliseconds (cast (s64) max (16 - (frame_end - frame_start) * 1000, 0));
	}

	terminate_and_free_extensions ();
}

/*
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
	buffer_id := buffer_open (active_split_id, "some_file.txt", "Buffer");
	buffer := get_buffer (buffer_id);
	layout := get_text_layout (buffer.text_layout_id);
	page := load_page (get_font (layout.font_id), 16);
	line_height := cast (f32) (page.ascent - page.descent);

	running = true;
	is_dragging_cursor    := false;
	is_dragging_scrollbar := false;
	frame_start := platform_get_time ();
	while running
	{
		previous_frame_start := frame_start;
		frame_start = platform_get_time ();
		delta_time := cast (f32) (frame_start - previous_frame_start);
		reset_temporary_storage ();
		
		platform_reset_input_state ();
		event : Event;
		using event_result : Event_Result;
		while platform_get_next_event (*event)
		{
			tmp_result, propagate := extensions_on_event (event);
			event_result ||= tmp_result;
			if !propagate then continue;
			tmp_result = handle_event (event);
			event_result ||= tmp_result;
		}

		if buffer_modified
		{
			language_process_buffer (buffer.id);
			text_layout_set_dirty (layout.id);
		}
		
		mouse_position := platform_get_mouse_position ();
		if platform_get_mouse_button_state (.LEFT) == .PRESSED
		{
			if contains (scrollbar_rect, mouse_position)
			{
				scrollbar_drag_offset = scrollbar_rect.y1 - event.mouse_position.y;
				is_dragging_scrollbar = true;
			}
			else if contains (text_layout_get_area (layout.id), mouse_position)
			{
				if event.mods == Mods.ALT
				{
					offset := text_layout_get_closest_character (layout.id, event.mouse_position);
					buffer_add_cursor_at_offset (buffer.id, offset);
				}
				else
				{
					offset := text_layout_get_closest_character (layout.id, mouse_position);
					buffer_clear_cursors (buffer.id);
					buffer_move_cursor_to_offset (buffer.id, offset, WRITE_HEAD);
					is_dragging_cursor = true;
				}
				scroll_to_cursor = true;
			}
			show_scrollbar = true;
		}
		else if platform_get_mouse_button_state (.LEFT) == .DOWN
		{
			if is_dragging_cursor
			{
				offset := text_layout_get_closest_character (layout.id, mouse_position);
				buffer_clear_cursors (buffer.id);
				buffer_move_cursor_to_offset (buffer.id, offset, WRITE_HEAD, select = true);
				scroll_to_cursor = true;
			}
			else if is_dragging_scrollbar
			{
				scrollbar_rect = set_position (scrollbar_rect, vec2f (scrollbar_rect.x1, mouse_position.y + scrollbar_drag_offset));
				scrolling_area := rect_height (layout.area) - rect_height (scrollbar_rect);
				scroll_percent := scrollbar_rect.y1 / scrolling_area;
				layout.scroll.y = round (scroll_percent * max (layout.extents.y / line_height - 1, 0));
			}
		}
		else
		{
			is_dragging_cursor = false;
			is_dragging_scrollbar = false;
		}
		
		viewport := platform_get_viewport_size ();
		line_number_len := count_digits (buffer.lines.count);
		area := rectf (cast (f32) (line_number_len + 2) * page.space_advance, 0, xx viewport.width, xx viewport.height - cast (f32) (page.ascent - page.descent));
		if area != layout.area || text_layout_is_dirty (layout.id)
		{
			layout.area = area;
			text_layout_compute (layout.id);
		}
		
		cursor_rect := text_layout_get_rect (layout.id, buffer_get_cursor (buffer.id, WRITE_HEAD).offset);
		if scroll_to_cursor
		{
			area := text_layout_get_area (layout.id);
			if cursor_rect.y1 < area.y1
			{
				text_layout_scroll_y (layout.id, (cursor_rect.y1 - area.y1) / line_height);
				show_scrollbar = true;
			}
			if cursor_rect.y2 > area.y2
			{
				text_layout_scroll_y (layout.id, (cursor_rect.y2 - area.y2) / line_height);
				show_scrollbar = true;
			}
		}
		layout.scroll.x = clamp (layout.scroll.x, 0, max ((layout.extents.x - rect_width (layout.area)) / cast (f32) (page.space_advance) - 1, 0));
		layout.scroll.y = clamp (layout.scroll.y, 0, max (layout.extents.y / line_height - 1, 0));
		layout.visual_scroll = lerp (layout.visual_scroll, vec2f (round (layout.scroll.x), round (layout.scroll.y)), 0.5);
		scrollbar_show_time  = max (scrollbar_show_time - delta_time, 0);
		if show_scrollbar then scrollbar_show_time = MAX_SCROLLBAR_SHOW_TIME;

		extensions_on_update ();
		
		max_visible := layout.extents.y - line_height + rect_height (layout.area);
		visible_area := rect_height (layout.area) / max_visible;
		scroll_percent := layout.visual_scroll.y / max (layout.extents.y / line_height - 1, 0);
		scrollbar_height := max (visible_area * rect_height (layout.area), MIN_SCROLLBAR_HEIGHT);
		scrolling_area   := rect_height (layout.area) - scrollbar_height;
		scrollbar_rect  = xywhf (layout.area.x2 - SCROLLBAR_WIDTH, layout.area.y1 + scrolling_area * scroll_percent, SCROLLBAR_WIDTH, scrollbar_height);
		
		if contains (layout.area, mouse_position) && !contains (scrollbar_rect, mouse_position)
			platform_set_cursor (.IBEAM);
		else
			platform_set_cursor (.ARROW);
		
		draw_begin ();
		
		for splits
		{
			id := cast (Split_ID) (it_index + 1);
			draw_split (id);
		}
		
		draw_rect (xywhf (0, xx (viewport.height - page.ascent + page.descent), xx viewport.width, xx (page.ascent - page.descent)), RGBA_WHITE);
		draw_text (
			font_id,
			16,
			vec2f (0, xx (viewport.height - (page.ascent - page.descent))),
			fstring (temp_allocator, "Ln %, Col % ~ % line(s)", buffer.line_index + 1, buffer.column_index + 1, buffer.lines.count),
			RGBA_BLACK
		);
		
		draw_end ();
		platform_swap_window_buffers ();
		frame_end := platform_get_time ();
		//println ("Frame took % milliseconds.", (frame_end - frame_start) * 1000);
		platform_sleep_milliseconds (cast (s64) max (16 - (frame_end - frame_start) * 1000, 0));
	}

	cleanup_extensions ();
}
*/

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
