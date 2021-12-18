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
#load "amber_config.jai";

CURSOR_ROUNDING :: 3.0;

viewport_size : Vec2i;
running : bool;
splits       : Slot_Array (Split);
buffers      : Slot_Array (Buffer);
text_layouts : Slot_Array (Text_Layout);
active_split_id : Split_ID;
is_inputting_command : bool;
executable_path : string;
executable_dir  : string;

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
		if event.key_code == .F3 && event.mods == .NONE
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
				command_execute_line ();
				toggle_command_input ();
				propagate = false;
			
			case .LEFT;
				command_buffer_move_cursor_backward ();
			
			case .RIGHT;
				command_buffer_move_cursor_forward ();
			
			case .UP;
				command_buffer_set_cursor (command_buffer_get_count ());
				command_buffer_set_cursor (command_buffer_get_count ());
				match := command_history_match ();
				match.data  += command_buffer_get_count ();
				match.count -= command_buffer_get_count ();
				for match
					command_buffer_insert (it);

			case .DOWN;

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

amber_terminate :: ()
{
	running = false;
}
@Amber_API

amber_get_executable_path :: (allocator : Allocator) -> string #must
{
	return clone_string (executable_path, allocator);
}
@Amber_API

main :: ()
{
	FONT_NAME :: "fonts/jetbrainsmono/JetBrainsMono-Regular.ttf";
	context.allocator = HEAP;

#if ENABLE_PROFILING
	init_profiler ();

	executable_path = platform_get_module_filename (HEAP);
	executable_dir  = filename_remove_basename (executable_path);

	config : Amber_Config;
	parser : Config_Parser;
	{
		file_contents, ok := platform_read_entire_file ("config.amber", TEMP);
		config_parser_init (*parser, "config.amber", file_contents);
		config_parse (*parser);
		//config_print (*parser.root);
		/*
		config_fill_variables (*config, *parser.root);
		#insert -> string
		{
			builder : String_Builder;
			builder.allocator = TEMP;
			for type_info (Amber_Config).members
				print_line_to_builder (*builder, "println (\"% is %%\", config.%);", it.name, it.name);
			
			return to_string (builder);
		}
		*/
	}

	platform_init_window_and_gl ();
	viewport_size = platform_get_viewport_size ();
	draw_init ();
	font_init ();
	command_buffer_init ();
	init_slot_array (*buffers, 20, HEAP);
	init_slot_array (*text_layouts, 20, HEAP);
	init_slot_array (*splits, 10, HEAP);
	command_buffer_set_prompt (">");
	if !load_extension ("amber_default.dll") then println ("Could not load extension 'amber_default'.");
	load_extension ("amber_test_extension.dll");
	load_extension ("amber_jai.dll");
	init_extensions ();
	font_load_from_file (FONT_NAME);
	split_create_first ();
	buffer_load_file (get_active_buffer (), "get_next_line.c");
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
		
		// Handle file changes
		file_changes := platform_pull_file_changes ();
		for change : file_changes
		{
			for buffer : buffers
			{
				buffer_id := cast (Buffer_ID) (it_index + 1);
				if change.dirname == filename_remove_basename (buffer.filename) &&
				   change.basename == filename_get_basename (buffer.filename)
				{
					if buffer_reload (buffer_id)
					{
						language_process_buffer (buffer_id);
						text_layout_set_dirty (buffer_get_text_layout (buffer_id));
					}
					else
						println ("Failed to reload buffer after file change.");
				}
			}
		}

		// Handle window events
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

		// Update
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
	init_string_builder (*builder, 5000, TEMP);
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
