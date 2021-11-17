#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_unicode.jai";
#load "amber_platform.jai";
#load "amber_gl.jai";
#load "amber_draw.jai";
#load "amber_font.jai";
#load "amber_buffer.jai";
#load "amber_layout.jai";
#load "amber_split.jai";
#load "amber_language.jai";
#load "amber_command.jai";
#load "amber_extension.jai";
#load "amber_profiler.jai";

CURSOR_ROUNDING :: 3.0;
CURSOR_MARGIN   :: 0;

viewport_size : Vec2i;
running : bool;
splits       : Slot_Array (Split);
buffers      : Slot_Array (Buffer);
text_layouts : Slot_Array (Text_Layout);
active_split_id : Split_ID;
is_inputting_command : bool;
command_prompt : string;
command_buffer : struct
{
	data : [..]u32;
	cursor : s64;
};

handle_event :: inline (event : Event) -> Event_Result #must, propagate : bool
{
	using result : Event_Result;
	propagate := true;
	if event.kind ==
	{
	case .WINDOW_CLOSE;
		running = false;
		
	case .WINDOW_RESIZE;
		if event.viewport_size.x != 0 && event.viewport_size.y != 0
		{
			command_line_height := rect_height (command_buffer_get_rect ());
			for * split : splits
			{
				new_area := rectf (
					(split.area.x1 / cast (f32) viewport_size.x) * event.viewport_size.x,
					(split.area.y1 / (viewport_size.y - command_line_height)) * (event.viewport_size.y - command_line_height),
					(split.area.x2 / cast (f32) viewport_size.x) * event.viewport_size.x,
					(split.area.y2 / (viewport_size.y - command_line_height)) * (event.viewport_size.y - command_line_height)
				);
				split_set_area (split.id, new_area);
			}
			viewport_size = event.viewport_size;
		}
	
	case .TEXT_INPUT;
		if is_inputting_command
			command_buffer_insert (event.codepoint);

	case .KEY_PRESS; #through;
	case .KEY_REPEAT;
		if event.key_code == .ESCAPE && event.mods == .NONE
		{
			toggle_command_input ();
			propagate = false;
		}
		
		if is_inputting_command
		{
			if event.key_code ==
			{
			case .BACKSPACE;
				command_buffer_backspace ();
				
			case .DELETE;
				command_buffer_delete ();
			
			case .RETURN;
				command_execute (command_buffer.data);
				toggle_command_input ();
				propagate = false;
			
			case .LEFT;
				command_buffer_move_cursor_backward ();
			
			case .RIGHT;
				command_buffer_move_cursor_forward ();
			}
		}
		else if event.mods == .CONTROL
		{
			if event.key_code ==
			{
			case .K;
				active_split_id = split_create_below (active_split_id);
			
			case .I;
				active_split_id = split_create_above (active_split_id);
			
			case .J;
				active_split_id = split_create_left (active_split_id);
			
			case .L;
				active_split_id = split_create_right (active_split_id);
			
			case .Q;
				merged_with := split_merge (active_split_id);
				if merged_with != NULL_SPLIT
					active_split_id = merged_with;
			
			case .O;
				split := get_split (active_split_id);
				split.active_buffer_index = wrap (split.active_buffer_index + 1, split.opened_buffer_ids.count);
			
			case .U;
				split := get_split (active_split_id);
				split.active_buffer_index = wrap (split.active_buffer_index - 1, split.opened_buffer_ids.count);
			
			case .N;
				split_open_buffer (active_split_id);
			}
		}

	case .MOUSE_PRESS;
		if contains (command_buffer_get_rect (), event.mouse_position)
		{
			if !is_inputting_command
				toggle_command_input ();
			else
				command_buffer_set_cursor (command_buffer_get_closest_character (event.mouse_position));
		}
		else
		{
			for splits
			{
				if contains (it.area, event.mouse_position)
				{
					active_split_id = it.id;
					if is_inputting_command then toggle_command_input ();
					
					break;
				}
			}
		}
	}
	
	return result, propagate;
}

main :: ()
{
	FONT_NAME :: "fonts/jetbrainsmono/JetBrainsMono-Regular.ttf";
	context.allocator = heap_allocator;
	
#if ENABLE_PROFILING
	init_profiler ();
	platform_init_window_and_gl ();
	viewport_size = platform_get_viewport_size ();
	draw_init ();
	font_init ();
	init_array (*command_buffer.data, 100, heap_allocator);
	init_slot_array (*buffers, 20, heap_allocator);
	init_slot_array (*text_layouts, 20, heap_allocator);
	init_slot_array (*splits, 10, heap_allocator);
	command_buffer_set_prompt (">");
	load_extension ("amber_test_extension.dll");
	load_extension ("amber_jai.dll");
	init_extensions ();
	font_load_from_file (FONT_NAME);
	split_create_first ();
	buffer_load_file (get_active_buffer (), "some_file.txt");
	buffer_move_cursor_to_beginning (get_active_buffer (), WRITE_HEAD);
	
	for buffer : buffers
	{
		language_process_buffer (buffer.id);
		text_layout_update_area (buffer_get_text_layout (buffer.id));
		text_layout_compute (buffer_get_text_layout (buffer.id));
	}
	
	running = true;
	frame_start := platform_get_time ();
	while running
	{
		profile ("main_loop");
		
		previous_frame_start := frame_start;
		frame_start = platform_get_time ();
		delta_time := cast (f32) (frame_start - previous_frame_start);
		reset_temporary_storage ();
		event : Event;
		event_result : Event_Result;
		platform_reset_input_state ();
		while platform_get_next_event (*event)
		{
			intermediate_result, propagate := extensions_on_event (event);
			event_result ||= intermediate_result;
			if !propagate then continue;
			intermediate_result, propagate = handle_event (event);
			event_result ||= intermediate_result;
			if !propagate then continue;
			if !is_inputting_command && active_split_id != NULL_SPLIT
				event_result ||= split_handle_event (active_split_id, event);
		}

		if active_split_id != NULL_SPLIT
			split_update (active_split_id, *event_result, delta_time);
		memset (*event_result, 0, size_of (Event_Result));
		for splits
		{
			if it.id == active_split_id
				continue;
			split_update (it.id, *event_result, delta_time);
		}
		if contains (command_buffer_get_rect (), platform_get_mouse_position ())
			platform_set_cursor (.ARROW);
		extensions_on_update ();
		
		draw_begin ();
		for splits
			split_draw (it.id);
		if active_split_id != NULL_SPLIT && get_split_count () > 1
			draw_rect_outline (truncate_all_sides (split_get_area (active_split_id), 1.5), rgba (50, 100, 200, 128), 3, 5.0);
		if is_inputting_command
			draw_command_buffer (1, 16, command_buffer_get_rect ().min, RGBA_WHITE);
		draw_end ();
		
		platform_swap_window_buffers ();
		frame_end := platform_get_time ();
		platform_sleep_milliseconds (cast (s64) max (16 - (frame_end - frame_start) * 1000, 0));
	}

	terminate_and_free_extensions ();
#if ENABLE_PROFILING
{
	builder : String_Builder;
	init_string_builder (*builder, 5000, temp_allocator);
	write_profiling_data_to_builder (*builder);
	platform_write_to_file ("profiling.txt", to_string (builder));
}
}

draw_text :: (font_id : Font_ID, height : u32, position : Vec2f, text : string, color : RGBA)
{
	profile ();
	
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

command_buffer_set_prompt :: inline (prompt : string)
{
	free (command_prompt, heap_allocator);
	command_prompt = clone_string (prompt, heap_allocator);
}
@Amber_API

toggle_command_input :: inline ()
{
	is_inputting_command = !is_inputting_command;
	command_buffer_clear ();
}
@Amber_API

command_buffer_clear :: inline ()
{
	using command_buffer;
	clear_array (*data);
	cursor = 0;
}
@Amber_API

command_buffer_insert :: inline (codepoint : u32)
{
	using command_buffer;
	if codepoint == #char "\n" || codepoint == #char "\r" || codepoint == #char "\t"
		return;
	sorted_insert_into_array (*data, cursor, codepoint);
	cursor += 1;
}
@Amber_API

command_buffer_delete :: inline ()
{
	using command_buffer;
	if cursor != data.count
		sorted_remove_from_array (*data, cursor);
}
@Amber_API

command_buffer_backspace :: inline ()
{
	using command_buffer;
	if cursor != 0
	{
		cursor -= 1;
		sorted_remove_from_array (*data, cursor);
	}
}
@Amber_API

command_buffer_move_cursor_backward :: inline ()
{
	using command_buffer;
	if cursor > 0
		cursor -= 1;
}

command_buffer_move_cursor_forward :: inline ()
{
	using command_buffer;
	if cursor < data.count
		cursor += 1;
}
@Amber_API

command_buffer_skip_word_forward :: inline (stop_at_word_separators : bool)
{
	using command_buffer;
	while cursor < data.count && is_space (data[cursor])
		command_buffer_move_cursor_forward ();
	first := data[cursor];
	command_buffer_move_cursor_forward ();
	while cursor < data.count && !is_space (data[cursor])
	{
		if is_alpha_num (first) != is_alpha_num (data[cursor]) then break;
		if data[cursor] == #char "_" && stop_at_word_separators then break;
		command_buffer_move_cursor_forward ();
	}
}
@Amber_API

command_buffer_skip_word_backward :: inline (stop_at_word_separators : bool)
{
	using command_buffer;
	while cursor > 0 && is_space (data[cursor - 1])
		command_buffer_move_cursor_backward ();
	first := data[cursor - 1];
	command_buffer_move_cursor_backward ();
	while cursor > 0 && !is_space (data[cursor - 1])
	{
		if is_alpha_num (first) != is_alpha_num (data[cursor - 1]) then break;
		if data[cursor] == #char "_" && stop_at_word_separators then break;
		command_buffer_move_cursor_backward ();
	}
}
@Amber_API

command_buffer_get_cursor :: inline () -> s64 #must
{
	return command_buffer.cursor;
}
@Amber_API

command_buffer_set_cursor :: inline (cursor : s64)
{
	command_buffer.cursor = cursor;
}
@Amber_API

command_buffer_get_rect :: inline () -> Rectf #must
{
	return rectf (
		0,
		viewport_size.y - font_get_line_height (1, 16),
		cast (f32) viewport_size.x,
		cast (f32) viewport_size.y
	);
}
@Amber_API

command_buffer_get_closest_character :: inline (position : Vec2f) -> s64 #must
{
	using command_buffer;
	start := command_buffer_get_rect ().min;
	font := get_font (1);
	page := load_page (font, 16);
	pen : Vec2f;
	for codepoint, i : utf8 (command_prompt)
	{
		glyph := load_glyph (page, codepoint);
		rect := xywhf (
			pen.x,
			pen.y,
			xx glyph.advance,
			xx (page.ascent - page.descent)
		);
		rect = move (rect, round (start.x), round (start.y));
		if contains (rect, position)
			return 0;
		pen.x += glyph.advance;
	}
	for codepoint, i : data
	{
		glyph := load_glyph (page, codepoint);
		rect := xywhf (
			pen.x,
			pen.y,
			xx glyph.advance,
			xx (page.ascent - page.descent)
		);
		rect = move (rect, round (start.x), round (start.y));
		if contains (rect, position)
			return i;
		pen.x += glyph.advance;
	}
	return data.count;
}
@Amber_API

draw_command_buffer :: (font_id : Font_ID, height : u32, position : Vec2f, color : RGBA)
{
	profile ();
	
	using command_buffer;
	prev_texture := draw_get_texture ();
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);
	
	font := get_font (font_id);
	page := load_page (font, height);
	pen : Vec2f;
	for codepoint, i : utf8 (command_prompt)
	{
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
	for codepoint, i : data
	{
		glyph := load_glyph (page, codepoint);
		glyph_rect := xywhf (
			pen.x + glyph.bitmap_bearing_x,
			pen.y - glyph.bitmap_bearing_y + page.ascent,
			xx glyph.bitmap_width,
			xx glyph.bitmap_height
		);
		glyph_rect = move (glyph_rect, round (position.x), round (position.y));
		if i == cursor
		{
			draw_set_texture (0);
			draw_rect (
				xywhf (
					round (position.x) + pen.x,
					round (position.y) + pen.y,
					xx glyph.advance,
					xx (page.ascent - page.descent)
				),
				color,
				CURSOR_ROUNDING
			);
		}
		draw_set_texture (glyph.atlas_texture);
		draw_rect (glyph_rect, (ifx i == cursor then RGBA_BLACK else color), uv_rect = glyph.uv_rect);
		pen.x += glyph.advance;
	}
	if cursor == data.count
	{
		draw_set_texture (0);
		draw_rect (
			xywhf (
				round (position.x) + pen.x,
				round (position.y) + pen.y,
				cast (f32) page.space_advance,
				cast (f32) (page.ascent - page.descent)
			),
			color,
			CURSOR_ROUNDING
		);
	}
}

