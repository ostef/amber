Command :: struct
{
	extension_id : Extension_ID;
	name : string;
	proc : Command_Proc;
	arg_count : s64;
	first_optional_argument : s64;
	combination : Key_Combination;
}

Command_Args :: struct
{
	name : string;
	args : []string;
}

#scope_file

commands : [..]Command;
command_prompt : string;
command_buffer : struct
{
	data : [..]u32;
	cursor : s64;
	history : [..][]u32;
};

#scope_export

command_register :: (
	extension_id : Extension_ID,
	using info : Command_Info
) -> bool
{
	if !commands.allocator.proc then commands.allocator = HEAP;
	if !name || !proc
		return false;
	for commands
	{
		if it.name == name
			return false;
	}
	pushed := push_into_array (*commands);
	// @Note (stefan): We don't make assumptions about where the memory for name and
	// combination comes from, so we allocate new memory for them.
	pushed.extension_id = extension_id;
	pushed.name = clone_string (name, HEAP);
	pushed.proc = proc;
	pushed.arg_count = arg_count;
	pushed.first_optional_argument = first_optional_argument;
	
	return true;
}
@Amber_API

command_unregister_for_extension :: (extension_id : Extension_ID)
{
	for * commands
	{
		if it.extension_id == extension_id
		{
			free (it.name, HEAP);
			remove it;
		}
	}
}
@Amber_API

parse_command_line :: (cmd_line : []u32) -> []Command_Args #must
{
	// @Todo (stefan): Handle errors like unclosed string literal.
	
	utf32 := cmd_line;
	result : [..]Command_Args;
	init_array (*result, 5, TEMP);
	while utf32.count
	{
		while utf32.count && is_space (utf32[0])
			utf32 = advance (utf32);
		// Parse name
		utf32_name := utf32;
		while utf32.count && !is_space (utf32[0])
			utf32 = advance (utf32);
		utf32_name.count = utf32.data - utf32_name.data;
		
		// Parse arguments
		args : [..]string;
		init_array (*args, 10, TEMP);
		current_arg : [..]u32;
		init_array (*current_arg, 20, TEMP);
		while utf32.count
		{
			clear_array (*current_arg);
			// Skip spaces
			while utf32.count && is_space (utf32[0]) && utf32[0] != #char "&"
				utf32 = advance (utf32);
			if !utf32.count then break;
			
			if utf32[0] == #char "&"
			{
				utf32 = advance (utf32);
				
				break;
			}
			else if utf32[0] == #char "\""
			{
				utf32 = advance (utf32);
				while utf32.count && utf32[0] != #char "\""
				{
					if utf32[0] == #char "\\"
						utf32 = advance (utf32);
					push_into_array (*current_arg, utf32[0]);
					utf32 = advance (utf32);
				}
				utf32 = advance (utf32);
				push_into_array (*args, utf32_to_utf8 (current_arg, TEMP));
			}
			else
			{
				while utf32.count && !is_space (utf32[0])
				{
					push_into_array (*current_arg, utf32[0]);
					utf32 = advance (utf32);
				}
				push_into_array (*args, utf32_to_utf8 (current_arg, TEMP));
			}
		}
		
		if utf32_name.count != 0
		{
			cmd := push_into_array (*result);
			cmd.name = utf32_to_utf8 (utf32_name, TEMP);
			cmd.args = args;
		}
	}
	
	return result;
}

command_execute_line :: inline ()
{
	push_into_array (*command_buffer.history, clone_array (command_buffer.data, HEAP));
	command_execute (command_buffer.data);
}
@Amber_API

command_execute :: (utf32 : []u32)
{
	execution_line := parse_command_line (utf32);
	command : *Command;
	for current : execution_line
	{
		cmd : *Command;
		for * commands
		{
			if it.name == current.name
			{
				cmd = it;
				
				break;
			}
		}
		if !cmd then break;
		if !cmd.proc (get_hooks (cmd.extension_id), current.args) then break;
	}
}
@Amber_API

command_buffer_set_prompt :: inline (prompt : string)
{
	free (command_prompt, HEAP);
	command_prompt = clone_string (prompt, HEAP);
}
@Amber_API

toggle_command_input :: inline ()
{
	is_inputting_command = !is_inputting_command;
	command_buffer_clear ();
}
@Amber_API

command_buffer_init :: inline ()
{
	init_array (*command_buffer.data, 100, HEAP);
	init_array (*command_buffer.history, 100, HEAP);
}

command_buffer_clear :: inline ()
{
	using command_buffer;
	clear_array (*data);
	cursor = 0;
}
@Amber_API

command_history_clear :: inline ()
{
	for command_buffer.history
		free (it, HEAP);
	clear_array (*command_buffer.history);
}
@Amber_API

command_history_match :: inline () -> []u32
{
	for < entry : command_buffer.history
	{
		if entry.count <= command_buffer.data.count then continue;
		for i : 0..command_buffer.data.count - 1
		{
			if entry[i] != command_buffer.data[i]
				continue entry;
		}

		return entry;
	}

	return .[];
}

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
@Amber_API

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

command_buffer_get_count :: inline () -> s64 #must
{
	return command_buffer.data.count;
}
@Amber_API

command_buffer_get_cursor :: inline () -> s64 #must
{
	return command_buffer.cursor;
}
@Amber_API

command_buffer_set_cursor :: inline (cursor : s64)
{
	command_buffer.cursor = clamp (cursor, 0, command_buffer.data.count);
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
