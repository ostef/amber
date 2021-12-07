Buffer_History :: struct
{
	edits : [..]Buffer_Edit;
	index : s64;
	edit_buffer : [..]u32;
}

Buffer :: struct
{
	id : Buffer_ID;
	split_id  : Split_ID;
	text_layout_id : Text_Layout_ID;
	language_id : Language_ID;
	
	filename : string;
	name     : string;
	
	data : *u32;
	gap       : s64;
	allocated : s64;
	using write_head  : Buffer_Cursor;
	other_cursors : [..]Buffer_Cursor;

	line_index, column_index : s64;
	lines : [..]s64;
	
	history      : Buffer_History;
	eol_sequence := EOL_Sequence.PLATFORM;
}

add_buffer :: inline () -> *Buffer #must
{
	buffer, index := insert_into_slot_array (*buffers);
	buffer.id = cast (Buffer_ID) (index + 1);
	buffer_init (buffer.id, 10000);
	
	return buffer;
}

remove_buffer :: inline (buffer_id : Buffer_ID)
{
	buffer_reset (buffer_id);
	remove_from_slot_array (*buffers, xx (buffer_id - 1));
}

get_buffer :: inline (id : Buffer_ID) -> *Buffer #must
{
	assert (buffer_exists (id), "Invalid buffer id (%).", id);
	
	return get_ptr (*buffers, cast (s64) id - 1);
}

get_buffer_count :: inline () -> s64 #must
{
	return buffers.count;
}
@Amber_API

get_active_buffer :: inline () -> Buffer_ID #must
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		return NULL_BUFFER;
	
	return split_get_active_buffer (split_id);
}
@Amber_API

buffer_exists :: inline (id : Buffer_ID) -> bool #must
{
	return id > 0 && id <= xx buffers.max_occupied && buffers.slots[cast (s64) id - 1].occupied;
}
@Amber_API

buffer_init :: (buffer_id : Buffer_ID, capacity : s64)
{
	using buffer := get_buffer (buffer_id);
	initialize_item (buffer);
	id = buffer_id;
	data = alloc (size_of (u32) * capacity, HEAP);
	gap       = capacity;
	allocated = capacity;
	init_array (*other_cursors, 20, HEAP);
	init_array (*lines, 5000, HEAP);
	push_into_array (*lines, 0);
	
	init_array (*history.edits, 1000, HEAP);
	init_array (*history.edit_buffer, capacity, HEAP);
}

buffer_reset :: (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	free (filename, HEAP);
	free (name, HEAP);
	free (data, HEAP);
	reset_array (*other_cursors);
	reset_array (*lines);
	reset_array (*history.edits);
	reset_array (*history.edit_buffer);
	initialize_item (buffer);
	id = buffer_id;
}

buffer_grow :: (buffer_id : Buffer_ID, additional_capacity : s64)
{
	using buffer := get_buffer (buffer_id);
	if additional_capacity <= 0 then return;
	count := buffer_get_count (buffer_id);
	back  := count - offset;
	new_capacity := allocated + additional_capacity;
	new_gap  := new_capacity - count;
	new_data := cast (*u32) alloc (size_of (u32) * new_capacity, HEAP);
	memcpy (new_data, data, offset * size_of (u32));
	memcpy (new_data + offset + new_gap, data + offset + gap, back * size_of (u32));
	
	free (data, HEAP);
	data      = new_data;
	allocated = new_capacity;
	gap       = new_gap;
}

buffer_load_file :: inline (buffer_id : Buffer_ID, filename : string) -> bool
{
	// @Note (stefan): We always use the full filename because the working directory
	// might change later.
	full_filename := platform_get_full_filename (filename, HEAP);
	str, ok := platform_read_entire_file (full_filename, TEMP);
	if !ok then return false;
	buffer_clear (buffer_id);
	utf8_str := utf8 (str);
	for utf8_str
		buffer_insert_at_cursor (buffer_id, it, WRITE_HEAD, .DONT_PUSH);
	buffer_set_filename (buffer_id, full_filename);
	buffer_set_name (buffer_id, filename_get_basename (full_filename));

	return true;
}
@Amber_API

buffer_write_to_file :: inline (buffer_id : Buffer_ID) -> bool
{
	buffer := get_buffer (buffer_id);
	if !buffer.filename then return false;
	
	utf8_str : string;
	for buffer
		utf8_str.count += utf8_codepoint_size (it);
	utf8_str.data = alloc (utf8_str.count, TEMP);
	byte_offset := 0;
	for buffer
		byte_offset += utf8_encode (advance (to_array (utf8_str), byte_offset), it);
	written, ok := platform_write_to_file (buffer.filename, utf8_str);

	return ok;
}
@Amber_API

buffer_clear :: inline (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	gap = allocated;
	offset       = 0;
	selection    = 0;
	line_index   = 0;
	column_index = 0;
	clear_array (*other_cursors);
	buffer_clear_history (buffer_id);
	clear_array (*lines);
	push_into_array (*lines, 0);
}
@Amber_API

buffer_clear_history :: inline (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	clear_array (*history.edits);
	history.index = 0;
	clear_array (*history.edit_buffer);
}
@Amber_API

buffer_clear_redo_history :: inline (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	history.edits.count = history.index;
}
@Amber_API

buffer_get_split :: inline (buffer_id : Buffer_ID) -> Split_ID #must
{
	using buffer := get_buffer (buffer_id);
	
	return split_id;
}
@Amber_API

buffer_get_text_layout :: inline (buffer_id : Buffer_ID) -> Text_Layout_ID #must
{
	using buffer := get_buffer (buffer_id);
	
	return text_layout_id;
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

buffer_get_language :: inline (buffer_id : Buffer_ID) -> Language_ID #must
{
	using buffer := get_buffer (buffer_id);
	
	return language_id;
}
@Amber_API

buffer_set_language :: inline (buffer_id : Buffer_ID, language_id : Language_ID)
{
	assert (language_exists (language_id), "Invalid language id (%).", language_id);
	buffer := get_buffer (buffer_id);
	buffer.language_id = language_id;
	language_process_buffer (buffer_id);
}
@Amber_API

buffer_get_filename :: inline (buffer_id : Buffer_ID, allocator : Allocator) -> string #must
{
	using buffer := get_buffer (buffer_id);
	
	return clone_string (filename, allocator);
}
@Amber_API

buffer_set_filename :: inline (buffer_id : Buffer_ID, new_filename : string)
{
	using buffer := get_buffer (buffer_id);
	free (filename, HEAP);
	filename = clone_string (new_filename, HEAP);
	buffer_set_language (buffer_id, language_detect (filename));
}
@Amber_API

buffer_get_name :: inline (buffer_id : Buffer_ID, allocator : Allocator) -> string #must
{
	using buffer := get_buffer (buffer_id);
	
	return clone_string (name, allocator);
}
@Amber_API

buffer_set_name :: inline (buffer_id : Buffer_ID, name : string)
{
	buffer := get_buffer (buffer_id);
	free (buffer.name, HEAP);
	buffer.name = clone_string (name, HEAP);
}
@Amber_API

buffer_get_codepoint :: inline (buffer_id : Buffer_ID, index : s64) -> u32 #must
{
	using buffer := get_buffer (buffer_id);
	assert (index >= 0 && index < buffer_get_count (buffer_id), "Buffer index % is out of range [0;%).", index, buffer_get_count (buffer_id));
	
	return data[cast (s64) (index >= offset) * gap + index];
}
@Amber_API

buffer_get_count :: inline (buffer_id : Buffer_ID) -> s64 #must
{
	using buffer := get_buffer (buffer_id);
	
	return allocated - gap;
}
@Amber_API

buffer_cursor_exists :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool #must
{
	using buffer := get_buffer (buffer_id);

	return cursor_id >= WRITE_HEAD && cursor_id <= xx other_cursors.count;
}

buffer_get_cursor :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> Buffer_Cursor #must
{
	using buffer := get_buffer (buffer_id);
	assert (buffer_cursor_exists (buffer_id, cursor_id), "Invalid cursor id (%).", cursor_id);
	if cursor_id == WRITE_HEAD
		return write_head;
	
	return other_cursors[cast (s64) cursor_id - 1];
}
@Amber_API

buffer_get_cursor_ptr :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> *Buffer_Cursor #must
{
	using buffer := get_buffer (buffer_id);
	assert (buffer_cursor_exists (buffer_id, cursor_id), "Invalid cursor id (%).", cursor_id);
	if cursor_id == WRITE_HEAD
		return *write_head;
	
	return *other_cursors[cast (s64) cursor_id - 1];
}

buffer_get_cursor_line_index :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	if cursor_id == WRITE_HEAD
		return buffer.line_index;
	cursor := buffer_get_cursor (buffer_id, cursor_id);
	counter := 0;
	for line_length, line_index : buffer.lines
	{
		counter += line_length;
		if cursor.offset < counter then return line_index;
	}

	return buffer.lines.count - 1;
}
@Amber_API

buffer_get_cursor_column_index :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	if cursor_id == WRITE_HEAD
		return buffer.column_index;
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	start_offset := cursor.offset;
	buffer_move_cursor_to_bol (buffer_id, cursor_id, true);
	column_index := start_offset - cursor.offset;
	while cursor.offset != start_offset
		buffer_move_cursor_forward (buffer_id, cursor_id, true);
	
	return column_index;
}
@Amber_API

buffer_cursor_is_at_bol :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool #must
{
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	
	return cursor.offset == 0 || buffer_get_codepoint (buffer_id, cursor.offset - 1) == #char "\n";
}
@Amber_API

buffer_cursor_is_at_eol :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool #must
{
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	
	return cursor.offset == buffer_get_count (buffer_id) || buffer_get_codepoint (buffer_id, cursor.offset) == #char "\n";
}
@Amber_API

buffer_get_line_count :: inline (buffer_id : Buffer_ID) -> s64 #must
{
	using buffer := get_buffer (buffer_id);
	
	return lines.count;
}
@Amber_API

buffer_get_line_length :: inline (buffer_id : Buffer_ID, line_index : s64) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	assert (line_index >= 0 && line_index < buffer.lines.count,
		"Invalid line index (got %, max is %).", line_index, buffer.lines.count - 1);

	return buffer.lines[line_index];
}

buffer_get_eol_sequence :: inline (buffer_id : Buffer_ID) -> EOL_Sequence #must
{
	using buffer := get_buffer (buffer_id);
	
	return eol_sequence;
}
@Amber_API

buffer_set_eol_sequence :: inline (buffer_id : Buffer_ID, eol_sequence : EOL_Sequence)
{
	buffer := get_buffer (buffer_id);
	buffer.eol_sequence = eol_sequence;
}
@Amber_API

buffer_move_cursor_forward :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);
	
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_forward (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		
		return true;
	}
	
	if cursor.offset < buffer_get_count (buffer_id)
	{
		if cursor_id == WRITE_HEAD
		{
			prev := buffer_get_codepoint (buffer_id, cursor.offset);
			data[offset] = prev;
			column_index += 1;
			if prev == #char "\n"
			{
				line_index  += 1;
				column_index = 0;
			}
		}
		cursor.offset += 1;
		if select then cursor.selection -= 1;
		
		return true;
	}
	
	return false;
}
@Amber_API

buffer_move_cursor_backward :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);
	
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_backward (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		
		return true;
	}
	
	if cursor.offset > 0
	{
		if cursor_id == WRITE_HEAD
		{
			prev := buffer_get_codepoint (buffer_id, cursor.offset - 1);
			cursor.offset -= 1;
			if select then cursor.selection += 1;
			data[offset + gap] = prev;
			column_index -= 1;
			if prev == #char "\n"
			{
				line_index  -= 1;
				column_index = lines[line_index] - 1;
			}
		}
		else
		{
			cursor.offset -= 1;
			if select then cursor.selection += 1;
		}
		
		return true;
	}
	
	return false;
}
@Amber_API

buffer_move_cursor_to_offset :: (buffer_id : Buffer_ID, new_offset : s64, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_offset (buffer_id, new_offset, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	
	new_offset = clamp (new_offset, 0, buffer_get_count (buffer_id));
	while cursor.offset > new_offset
		moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
	while cursor.offset < new_offset
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
	
	return moved;
}
@Amber_API

buffer_move_write_head_to_line_and_column :: inline (buffer_id : Buffer_ID, new_line : s64, new_column : s64, select := false) -> bool
{
	moved := buffer_move_write_head_to_line (buffer_id, new_line, select);
	moved |= buffer_move_cursor_to_column (buffer_id, new_column, WRITE_HEAD, select);
	
	return moved;
}
@Amber_API

buffer_move_cursor_to_bol :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_bol (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	
	while !buffer_cursor_is_at_bol (buffer_id, cursor_id)
		moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
	
	return moved;
}
@Amber_API

buffer_move_cursor_to_eol :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_eol (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	
	while !buffer_cursor_is_at_eol (buffer_id, cursor_id)
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
	
	return moved;
}
@Amber_API

buffer_move_cursor_to_column :: inline (buffer_id : Buffer_ID, column : s64, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);
	moved := false;
	if !select && selection != 0
	{
		selection = 0;
		moved = true;
	}
	
	cursor_column_index := buffer_get_cursor_column_index (buffer_id, cursor_id);
	while !buffer_cursor_is_at_eol (buffer_id, cursor_id) && cursor_column_index < column
	{
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
		cursor_column_index += 1;
	}
	while cursor_column_index > 0 && cursor_column_index > column
	{
		moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
		cursor_column_index -= 1;
	}

	return moved;
}
@Amber_API

buffer_move_cursor_to_previous_line :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_previous_line (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	start_offset := cursor.offset;
	moved := false;
	moved |= buffer_move_cursor_to_bol (buffer_id, cursor_id, select);
	if cursor.offset == 0 then return moved;
	start_column := start_offset - cursor.offset;
	moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
	start_offset = cursor.offset;
	moved |= buffer_move_cursor_to_bol (buffer_id, cursor_id, select);
	while start_column > 0 && !buffer_cursor_is_at_eol (buffer_id, cursor_id)
	{
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
		start_column -= 1;
	}
	
	return moved;
}
@Amber_API

buffer_move_cursor_to_next_line :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);
	
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_next_line (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	start_offset := cursor.offset;
	moved := false;
	moved |= buffer_move_cursor_to_bol (buffer_id, cursor_id, select);
	start_column := start_offset - cursor.offset;
	moved |= buffer_move_cursor_to_eol (buffer_id, cursor_id, select);
	moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
	while start_column > 0 && !buffer_cursor_is_at_eol (buffer_id, cursor_id)
	{
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
		start_column -= 1;
	}
	
	return true;
}
@Amber_API

buffer_move_write_head_to_line :: inline (buffer_id : Buffer_ID, line : s64, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);
	moved := false;
	if !select && selection != 0
	{
		selection = 0;
		moved = true;
	}
	
	line = clamp (line, 0, lines.count - 1);
	while line_index > line
		moved |= buffer_move_cursor_to_previous_line (buffer_id, WRITE_HEAD, select);
	while line_index < line
		moved |= buffer_move_cursor_to_next_line (buffer_id, WRITE_HEAD, select);
	
	return moved;
}
@Amber_API

buffer_move_cursor_to_beginning :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_beginning (buffer_id, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = false;
	}
	
	while cursor.offset > 0
		moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
	
	return moved;
}
@Amber_API

buffer_move_cursor_to_end :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);
	
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_move_cursor_to_end (buffer_id, xx i, select);
		
		return moved;
	}

	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = false;
	}
	
	while cursor.offset < buffer_get_count (buffer_id)
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
	
	return moved;
}
@Amber_API

buffer_skip_word_forward :: (buffer_id : Buffer_ID, stop_at_word_separators : bool, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_skip_word_forward (buffer_id, stop_at_word_separators, xx i, select);
		
		return moved;
	}

	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	if cursor.offset == buffer_get_count (buffer_id)
		return moved;
	
	while is_space (buffer_get_codepoint (buffer_id, cursor.offset))
	{
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
		if buffer_cursor_is_at_eol (buffer_id, cursor_id)
			return moved;
	}
	
	first := buffer_get_codepoint (buffer_id, cursor.offset);
	moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
	if cursor.offset == buffer_get_count (buffer_id)
		return moved;
	codepoint := buffer_get_codepoint (buffer_id, cursor.offset);
	while !is_space (codepoint)
	{
		if is_alpha_num (first) != is_alpha_num (codepoint) then break;
		if codepoint == #char "_" && stop_at_word_separators then break;
		if buffer_cursor_is_at_eol (buffer_id, cursor_id) then break;
		moved |= buffer_move_cursor_forward (buffer_id, cursor_id, select);
		if cursor.offset == buffer_get_count (buffer_id) then break;
		codepoint = buffer_get_codepoint (buffer_id, cursor.offset);
	}
	
	return moved;
}
@Amber_API

buffer_skip_word_backward :: (buffer_id : Buffer_ID, stop_at_word_separators : bool, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= buffer_skip_word_backward (buffer_id, stop_at_word_separators, xx i, select);
		
		return moved;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	if cursor.offset == 0
		return moved;
	
	while !buffer_cursor_is_at_bol (buffer_id, cursor_id) && is_space (buffer_get_codepoint (buffer_id, cursor.offset - 1))
		moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
	if cursor.offset == 0
		return moved;
	first := buffer_get_codepoint (buffer_id, cursor.offset - 1);
	moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
	while cursor.offset > 0 && !is_space (buffer_get_codepoint (buffer_id, cursor.offset - 1))
	{
		if is_alpha_num (first) != is_alpha_num (buffer_get_codepoint (buffer_id, cursor.offset - 1))
			break;
		if buffer_get_codepoint (buffer_id, cursor.offset) == #char "_" && stop_at_word_separators
			break;
		moved |= buffer_move_cursor_backward (buffer_id, cursor_id, select);
		if buffer_cursor_is_at_bol (buffer_id, cursor_id) then break;
	}
	
	return moved;
}
@Amber_API

buffer_clear_selection :: inline (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	for :cursors * buffer
		it.selection = 0;
}
@Amber_API

buffer_clear_cursors :: inline (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	clear_array (*other_cursors);
}
@Amber_API

buffer_merge_duplicate_cursors :: (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	cursor_id := WRITE_HEAD;
	while cursor_id <= xx other_cursors.count
	{
		cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
		if cursor_id != WRITE_HEAD && (cursor.offset == offset ||
		   selection > 0 && cursor.offset >= offset && cursor.offset < offset + selection ||
		   selection < 0 && cursor.offset >= offset + selection && cursor.offset < offset)
		{
			selection += cursor.selection - cast (s64) (offset < cursor.offset);
			sorted_remove_from_array (*other_cursors, xx (cursor_id - 1));
			cursor_id = WRITE_HEAD;
			
			continue;
		}
	
		merged := false;
		for * other_cursors
		{
			if it_index + 1 == xx cursor_id then continue;
			
			if it.selection > 0 && cursor.offset >= it.offset && cursor.offset < it.offset + it.selection ||
			   it.selection < 0 && cursor.offset >= it.offset + it.selection && cursor.offset < it.offset ||
			   cursor.offset == it.offset
			{
				if cursor.offset != it.offset
					buffer_move_cursor_to_offset (buffer_id, it.offset, cursor_id, select = true);
				sorted_remove_from_array (*other_cursors, it_index);
				merged = true;
				
				break;
			}
		}
		if merged
			cursor_id = WRITE_HEAD;
		else
			cursor_id += 1;
	}
}
@Amber_API

buffer_sort_cursors_by_offset :: (buffer_id : Buffer_ID)
{
	using buffer := get_buffer (buffer_id);
	quick_sort (other_cursors, (left, right) => (left.offset - right.offset));
}
@Amber_API

buffer_add_cursor_at_offset :: (buffer_id : Buffer_ID, target_offset : s64) -> bool
{
	using buffer := get_buffer (buffer_id);

	for :cursors buffer
	{
		if it.selection > 0 && target_offset >= it.offset && target_offset < it.offset + it.selection ||
		   it.selection < 0 && target_offset >= it.offset + it.selection && target_offset < it.offset ||
		   target_offset == it.offset
			return false;
	}

	closest : Buffer_Cursor;
	for other_cursors
	{
		if abs (it.offset - target_offset) < abs (closest.offset - target_offset)
			closest = it;
	}
	push_into_array (*other_cursors, closest);
	buffer_move_cursor_to_offset (buffer_id, target_offset, xx other_cursors.count);
	
	return true;
}
@Amber_API

buffer_add_cursor_on_previous_line :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		added := false;
		max_cursor_index := other_cursors.count;
		for i : 0..max_cursor_index
			added |= buffer_add_cursor_on_previous_line (buffer_id, xx i);
		
		return added;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	prev_offset    := cursor.offset;
	prev_selection := cursor.selection;
	buffer_move_cursor_to_previous_line (buffer_id, cursor_id);
	target_offset := cursor.offset;
	buffer_move_cursor_to_offset (buffer_id, prev_offset, cursor_id);
	cursor.selection = prev_selection;
	for :cursors buffer
	{
		if it.selection > 0 && target_offset >= it.offset && target_offset < it.offset + it.selection ||
		   it.selection < 0 && target_offset >= it.offset + it.selection && target_offset < it.offset ||
		   target_offset == it.offset
			return false;
	}

	push_into_array (*other_cursors, <<cursor);
	buffer_move_cursor_to_offset (buffer_id, target_offset, xx other_cursors.count);
	
	return true;
}
@Amber_API

buffer_add_cursor_on_next_line :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
{
	using buffer := get_buffer (buffer_id);

	if cursor_id == ALL_CURSORS
	{
		added := false;
		max_cursor_index := other_cursors.count;
		for i : 0..max_cursor_index
			added |= buffer_add_cursor_on_next_line (buffer_id, xx i);
		
		return added;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	prev_offset    := cursor.offset;
	prev_selection := cursor.selection;
	buffer_move_cursor_to_next_line (buffer_id, cursor_id);
	target_offset := cursor.offset;
	buffer_move_cursor_to_offset (buffer_id, prev_offset, cursor_id);
	cursor.selection = prev_selection;
	for :cursors buffer
	{
		if it.selection > 0 && target_offset >= it.offset && target_offset < it.offset + it.selection ||
		   it.selection < 0 && target_offset >= it.offset + it.selection && target_offset < it.offset ||
		   target_offset == it.offset
			return false;
	}
	
	push_into_array (*other_cursors, <<cursor);
	buffer_move_cursor_to_offset (buffer_id, target_offset, xx other_cursors.count);
	
	return true;
}
@Amber_API

buffer_remove_cursor :: inline (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID)
{
	using buffer := get_buffer (buffer_id);
	assert (cursor_id > 0 && cursor_id < xx other_cursors.count,
		"Invalid cursor id, expected (0;%), got %.", other_cursors.count, cursor_id);
	sorted_remove_from_array (*other_cursors, xx (cursor_id - 1));
}
@Amber_API

#scope_file

split_current_line :: inline (using buffer : *Buffer)
{
	current := lines[line_index];
	first_half := column_index;
	second_half := current - first_half;
	lines[line_index] = first_half;
	sorted_insert_into_array (*lines, line_index + 1, second_half);
}

merge_current_line_with_next_one :: inline (using buffer : *Buffer)
{
	if line_index == lines.count - 1 then return;
	lines[line_index] += lines[line_index + 1];
	sorted_remove_from_array (*lines, line_index + 1);
}

#scope_export

buffer_history_push_edit :: inline (buffer_id : Buffer_ID, kind : Buffer_Edit_Kind, cursor_id := ALL_CURSORS) -> *Buffer_Edit
{
	using buffer := get_buffer (buffer_id);
	buffer_clear_redo_history (buffer_id);
	edit := push_into_array (*history.edits);
	edit.kind = kind;
	edit.cursor_id = cursor_id;
	if cursor_id != ALL_CURSORS
	{
		edit.line_index = buffer_get_cursor_line_index (buffer_id, cursor_id);
		edit.cursor = buffer_get_cursor (buffer_id, cursor_id);
	}
	edit.offset_in_edit_buffer = history.edit_buffer.count;
	history.index = history.edits.count;

	return edit;
}
@Amber_API

buffer_history_push_char :: inline (buffer_id : Buffer_ID, codepoint : u32)
{
	using buffer := get_buffer (buffer_id);
	push_into_array (*history.edit_buffer, codepoint);
}
@Amber_API

buffer_history_push_text :: inline (buffer_id : Buffer_ID, text : []u32)
{
	using buffer := get_buffer (buffer_id);
	for text
		push_into_array (*history.edit_buffer, it);
}
@Amber_API

buffer_begin_batch_edit :: inline (buffer_id : Buffer_ID)
{
	buffer_history_push_edit (buffer_id, .BATCH_BEGIN);
}
@Amber_API

buffer_end_batch_edit :: inline (buffer_id : Buffer_ID)
{
	buffer_history_push_edit (buffer_id, .BATCH_END);
}
@Amber_API

buffer_insert_at_cursor :: (buffer_id : Buffer_ID, codepoint : u32, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT)
{
	using buffer := get_buffer (buffer_id);
	if codepoint == #char "\r" then return;
	if cursor_id == ALL_CURSORS
	{
		if history_buffering == .PUSH_EDIT
			buffer_begin_batch_edit (buffer_id);
		for i : 0..other_cursors.count
			buffer_insert_at_cursor (buffer_id, codepoint, xx i, history_buffering);
		if history_buffering == .PUSH_EDIT
			buffer_end_batch_edit (buffer_id);
		
		return;
	}
	
	if history_buffering ==
	{
	case .PUSH_EDIT;
		buffer_history_push_edit (buffer_id, .INSERT, cursor_id);
		#through;

	case .PUSH_TEXT;
		push_into_array (*history.edit_buffer, codepoint);
	}

	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	prev_offset    := offset;
	prev_selection := selection;
	if cursor_id != WRITE_HEAD
		buffer_move_cursor_to_offset (buffer_id, cursor.offset, WRITE_HEAD);

	if selection != 0 then buffer_delete_selection (buffer_id, WRITE_HEAD);
	if gap == 0 then buffer_grow (buffer_id, allocated + 8);
	data[offset] = codepoint;
	offset += 1;
	gap -= 1;
	
	lines[line_index] += 1;
	column_index += 1;
	if codepoint == #char "\n"
	{
		split_current_line (buffer);
		line_index += 1;
		column_index = 0;
	}

	if cursor_id != WRITE_HEAD
	{
		<<cursor = write_head;
		buffer_move_cursor_to_offset (buffer_id, prev_offset, WRITE_HEAD);
		selection = prev_selection;
	}
	
	for i : 0..other_cursors.count
	{
		if i == xx cursor_id then continue;
		it := buffer_get_cursor_ptr (buffer_id, xx i);
		if it.offset >= cursor.offset - 1 then buffer_move_cursor_forward (buffer_id, xx i);
	}
}
@Amber_API

buffer_insert_text_at_cursor :: (buffer_id : Buffer_ID, text : []u32, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT)
{
	using buffer := get_buffer (buffer_id);
	if cursor_id == ALL_CURSORS
	{
		if history_buffering == .PUSH_EDIT
			buffer_begin_batch_edit (buffer_id);
		for i : 0..other_cursors.count
			buffer_insert_text_at_cursor (buffer_id, text, xx i, history_buffering);
		if history_buffering == .PUSH_EDIT
			buffer_end_batch_edit (buffer_id);
		
		return;
	}

	if history_buffering == .PUSH_EDIT
	{
		buffer_history_push_edit (buffer_id, .INSERT, cursor_id);
		history_buffering = .PUSH_TEXT;
	}

	for text
		buffer_insert_at_cursor (buffer_id, it, cursor_id, history_buffering);
}
@Amber_API

buffer_insert_utf8_text_at_cursor :: (buffer_id : Buffer_ID, text : string, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT)
{
	using buffer := get_buffer (buffer_id);
	if cursor_id == ALL_CURSORS
	{
		if history_buffering == .PUSH_EDIT
			buffer_begin_batch_edit (buffer_id);
		for i : 0..other_cursors.count
			buffer_insert_utf8_text_at_cursor (buffer_id, text, xx i, history_buffering);
		if history_buffering == .PUSH_EDIT
			buffer_end_batch_edit (buffer_id);
		
		return;
	}

	if history_buffering == .PUSH_EDIT
	{
		buffer_history_push_edit (buffer_id, .INSERT, cursor_id);
		history_buffering = .PUSH_TEXT;
	}

	for utf8 (text)
		buffer_insert_at_cursor (buffer_id, it, cursor_id, history_buffering);
}
@Amber_API

buffer_delete_selection :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT) -> bool
{
	delete_helper :: inline (using buffer : *Buffer)
	{
		codepoint := buffer_get_codepoint (id, offset);
		gap += 1;
		lines[line_index] -= 1;
		if codepoint == #char "\n"
			merge_current_line_with_next_one (buffer);
	}
	
	using buffer := get_buffer (buffer_id);
	
	if cursor_id == ALL_CURSORS
	{
		modified := false;
		if history_buffering == .PUSH_EDIT
			buffer_begin_batch_edit (buffer_id);
		for i : 0..other_cursors.count
			modified |= buffer_delete_selection (buffer_id, xx i, history_buffering);
		if history_buffering == .PUSH_EDIT
			buffer_end_batch_edit (buffer_id);
		
		return modified;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	if cursor.offset == buffer_get_count (buffer_id) && cursor.selection == 0
		return false;
	
	if history_buffering == .PUSH_EDIT
	{
		edit := buffer_history_push_edit (buffer_id, .DELETE, cursor_id);
		if cursor.selection < 0 then edit.cursor.offset += cursor.selection;
		// Also push text
		history_buffering = .PUSH_TEXT;
	}

	prev_offset    := offset;
	prev_selection := selection;
	if cursor_id != WRITE_HEAD
	{
		buffer_move_cursor_to_offset (buffer_id, cursor.offset, WRITE_HEAD);
		selection = cursor.selection;
	}

	if history_buffering == .PUSH_TEXT
	{
		if selection == 0
			push_into_array (*history.edit_buffer, buffer_get_codepoint (buffer_id, offset));
		else
			for :selected_text codepoint, i : buffer
				push_into_array (*history.edit_buffer, codepoint);
	}

	count := 0;
	if selection == 0
	{
		delete_helper (buffer);
		count += 1;
	}

	while selection < 0
	{
		buffer_move_cursor_backward (buffer_id, WRITE_HEAD, select = true);
		delete_helper (buffer);
		count += 1;
	}
	
	while selection > 0
	{
		selection -= 1;
		delete_helper (buffer);
		count += 1;
	}
	
	if cursor_id != WRITE_HEAD
	{
		<<cursor = write_head;
		prev_offset = clamp (prev_offset, 0, buffer_get_count (buffer_id));
		buffer_move_cursor_to_offset (buffer_id, prev_offset, WRITE_HEAD);
		selection = prev_selection;
	}

	for i : 0..other_cursors.count
	{
		if i == xx cursor_id then continue;
		it := buffer_get_cursor_ptr (buffer_id, xx i);
		if it.offset >= cursor.offset - 1
		{
			prev_selection := it.selection;
			it.selection = 0;
			for 0..count - 1
				buffer_move_cursor_backward (buffer_id, xx i);
			it.selection = prev_selection;
		}
	}

	return true;
}
@Amber_API

buffer_backspace_selection :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT) -> bool
{
	using buffer := get_buffer (buffer_id);
	
	if cursor_id == ALL_CURSORS
	{
		modified := false;
		if history_buffering == .PUSH_EDIT
			buffer_begin_batch_edit (buffer_id);
		for i : 0..other_cursors.count
			modified |= buffer_backspace_selection (buffer_id, xx i, history_buffering);
		if history_buffering == .PUSH_EDIT
			buffer_end_batch_edit (buffer_id);
	
		return modified;
	}
	
	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	if cursor.selection != 0 then return buffer_delete_selection (buffer_id, cursor_id);
	if cursor.offset == 0 then return false;
	
	if history_buffering ==
	{
	case .PUSH_EDIT;
		buffer_history_push_edit (buffer_id, .BACKSPACE, cursor_id);
		#through;

	case .PUSH_TEXT;
		push_into_array (*history.edit_buffer, buffer_get_codepoint (buffer_id, cursor.offset - 1));
	}

	prev_offset    := offset;
	prev_selection := selection;
	if cursor_id != WRITE_HEAD
		buffer_move_cursor_to_offset (buffer_id, cursor.offset, WRITE_HEAD);

	codepoint := buffer_get_codepoint (buffer_id, offset - 1);
	offset -= 1;
	gap += 1;
	
	lines[line_index] -= 1;
	column_index -= 1;
	if codepoint == #char "\n"
	{
		line_index -= 1;
		column_index = lines[line_index] - 1;
		merge_current_line_with_next_one (buffer);
	}
	
	if cursor_id != WRITE_HEAD
	{
		<<cursor = write_head;
		buffer_move_cursor_to_offset (buffer_id, prev_offset, WRITE_HEAD);
		selection = prev_selection;
	}
	
	for i : 0..other_cursors.count
	{
		if i == xx cursor_id then continue;
		it := buffer_get_cursor_ptr (buffer_id, xx i);
		if it.offset >= cursor.offset - 1
			buffer_move_cursor_backward (buffer_id, xx i);
	}
	
	return true;
}
@Amber_API

buffer_move_line_up :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT) -> bool
{
	buffer := get_buffer (buffer_id);
	if cursor_id == ALL_CURSORS
	{
		last_line_moved := -1;
		modified := false;
		// @Note (stefan): We need to move the line for each cursor in
		// line_index ascending order.
		for :sorted_cursors cursor, cursor_id : buffer
		{
			line_index := buffer_get_cursor_line_index (buffer_id, cursor_id);
			// Don't move a line that is before the last line we moved, because
			// it means the cursor is on the same line as the previous one.
			if line_index < last_line_moved
				continue;
			// Don't move the same line twice.
			if line_index != last_line_moved
				modified |= buffer_move_line_up (buffer_id, cursor_id, history_buffering);
			last_line_moved = line_index;
		}

		return modified;
	}

	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	line_index := buffer_get_cursor_line_index (buffer_id, cursor_id);
	if line_index == 0 then return false;
	if history_buffering == .PUSH_EDIT
		buffer_history_push_edit (buffer_id, .MOVE_LINE_UP, cursor_id);

	// @Note (stefan): I don't like the way we handle multiple cursors on the same line...
	Same_Line :: struct
	{
		cursor_id : Buffer_Cursor_ID;
		relative_offset : s64;
	}

	other_cursors_on_the_same_line : [..]Same_Line;
	other_cursors_on_the_same_line.allocator = TEMP;
	for :cursors other, other_id : buffer
	{
		if other_id == cursor_id then continue;
		if buffer_get_cursor_line_index (buffer_id, other_id) == line_index
		{
			same_line := push_into_array (*other_cursors_on_the_same_line);
			same_line.cursor_id = other_id;
			same_line.relative_offset = other.offset - cursor.offset;
		}
	}

	line_buffer : [..]u32;
	line_buffer.allocator = TEMP;
	start_column_index := buffer_get_cursor_column_index (buffer_id, cursor_id);
	is_last_line := line_index == buffer_get_line_count (buffer_id) - 1;
	buffer_move_cursor_to_bol (buffer_id, cursor_id);

	if buffer_get_line_length (buffer_id, line_index) != 0
	{
		eol := false;
		while !eol
		{
			eol = buffer_cursor_is_at_eol (buffer_id, cursor_id);
			if is_last_line && eol then break;
			codepoint := buffer_get_codepoint (buffer_id, cursor.offset);
			push_into_array (*line_buffer, codepoint);
			if history_buffering == .PUSH_TEXT
				buffer_history_push_char (buffer_id, codepoint);
			buffer_delete_selection (buffer_id, cursor_id, .DONT_PUSH);
		}
	}

	if is_last_line
	{
		push_into_array (*line_buffer, #char "\n");
		if history_buffering == .PUSH_TEXT
			buffer_history_push_char (buffer_id, #char "\n");
		buffer_backspace_selection (buffer_id, cursor_id, .DONT_PUSH);
		buffer_move_cursor_to_bol (buffer_id, cursor_id);
	}
	else
	{
		buffer_move_cursor_to_previous_line (buffer_id, cursor_id);
	}

	buffer_insert_text_at_cursor (buffer_id, line_buffer, cursor_id, .DONT_PUSH);
	buffer_move_cursor_to_previous_line (buffer_id, cursor_id);
	buffer_move_cursor_to_column (buffer_id, start_column_index, cursor_id);

	// Move cursors that were on the same line so they keep the same relative offset
	// as the cursor we just moved.
	for other_cursors_on_the_same_line
		buffer_move_cursor_to_offset (buffer_id, cursor.offset + it.relative_offset, it.cursor_id);

	return true;
}

buffer_move_line_down :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, history_buffering := History_Buffering.PUSH_EDIT) -> bool
{
	buffer := get_buffer (buffer_id);
	if cursor_id == ALL_CURSORS
	{
		last_line_moved := buffer.lines.count;
		modified := false;
		// @Note (stefan): We need to move the line for each cursor in
		// line_index descending order.
		for < :sorted_cursors cursor, cursor_id : buffer
		{
			line_index := buffer_get_cursor_line_index (buffer_id, cursor_id);
			// Don't move a line that is after the last line we moved, because
			// it means the cursor is on the same line as the previous one.
			if line_index > last_line_moved
				continue;
			// Don't move the same line twice.
			if line_index != last_line_moved
				modified |= buffer_move_line_down (buffer_id, cursor_id, history_buffering);
			last_line_moved = line_index;
		}

		return modified;
	}

	cursor := buffer_get_cursor_ptr (buffer_id, cursor_id);
	line_index := buffer_get_cursor_line_index (buffer_id, cursor_id);
	if line_index == buffer.lines.count - 1 then return false;
	if history_buffering == .PUSH_EDIT
		buffer_history_push_edit (buffer_id, .MOVE_LINE_DOWN, cursor_id);

	// @Note (stefan): I don't like the way we handle multiple cursors on the same line...
	Same_Line :: struct
	{
		cursor_id : Buffer_Cursor_ID;
		relative_offset : s64;
	}

	other_cursors_on_the_same_line : [..]Same_Line;
	other_cursors_on_the_same_line.allocator = TEMP;
	for :cursors other, other_id : buffer
	{
		if other_id == cursor_id then continue;
		if buffer_get_cursor_line_index (buffer_id, other_id) == line_index
		{
			same_line := push_into_array (*other_cursors_on_the_same_line);
			same_line.cursor_id = other_id;
			same_line.relative_offset = other.offset - cursor.offset;
		}
	}

	line_buffer : [..]u32;
	line_buffer.allocator = TEMP;
	start_column_index := buffer_get_cursor_column_index (buffer_id, cursor_id);
	move_to_last_line := line_index == buffer_get_line_count (buffer_id) - 2;
	buffer_move_cursor_to_bol (buffer_id, cursor_id);

	eol := false;
	while !eol
	{
		eol = buffer_cursor_is_at_eol (buffer_id, cursor_id);
		codepoint := buffer_get_codepoint (buffer_id, cursor.offset);
		push_into_array (*line_buffer, codepoint);
		if history_buffering == .PUSH_TEXT
			buffer_history_push_char (buffer_id, codepoint);
		buffer_delete_selection (buffer_id, cursor_id, .DONT_PUSH);
	}

	if move_to_last_line
	{
		buffer_move_cursor_to_eol (buffer_id, cursor_id);
		buffer_insert_at_cursor (buffer_id, #char "\n", cursor_id, .DONT_PUSH);
		pop_off_array (*line_buffer);
		if history_buffering == .PUSH_TEXT
			pop_off_array (*buffer.history.edit_buffer);
	}
	else
	{
		buffer_move_cursor_to_next_line (buffer_id, cursor_id);
	}

	buffer_insert_text_at_cursor (buffer_id, line_buffer, cursor_id, .DONT_PUSH);
	if !move_to_last_line
		buffer_move_cursor_to_previous_line (buffer_id, cursor_id);
	buffer_move_cursor_to_column (buffer_id, start_column_index, cursor_id);

	// Move cursors that were on the same line so they keep the same relative offset
	// as the cursor we just moved.
	for other_cursors_on_the_same_line
		buffer_move_cursor_to_offset (buffer_id, cursor.offset + it.relative_offset, it.cursor_id);

	return true;
}

buffer_undo_last_edit :: (buffer_id : Buffer_ID) -> bool
{
	using buffer := get_buffer (buffer_id);
	if history.index == 0 then return false;
	edit := history.edits[history.index - 1];
	count : s64 = ---;
	if history.index == history.edits.count
		count = history.edit_buffer.count - edit.offset_in_edit_buffer;
	else
		count = history.edits[history.index].offset_in_edit_buffer - edit.offset_in_edit_buffer;
	history.index -= 1;

	if edit.kind ==
	{
	case .INSERT;
		buffer_clear_cursors (buffer_id);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset, WRITE_HEAD);
		for 1..count
			buffer_delete_selection (buffer_id, WRITE_HEAD, history_buffering = .DONT_PUSH);
		
	case .DELETE;
		text : []u32 = ---;
		text.data = history.edit_buffer.data + edit.offset_in_edit_buffer;
		text.count = count;
		buffer_clear_cursors (buffer_id);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset, WRITE_HEAD);
		buffer_insert_text_at_cursor (buffer_id, text, WRITE_HEAD, .DONT_PUSH);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset, WRITE_HEAD);

	case .BACKSPACE;
		text : []u32 = ---;
		text.data = history.edit_buffer.data + edit.offset_in_edit_buffer;
		text.count = count;
		buffer_clear_cursors (buffer_id);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset - text.count, WRITE_HEAD);
		buffer_insert_text_at_cursor (buffer_id, text, WRITE_HEAD, .DONT_PUSH);

	case .MOVE_LINE_UP;
		buffer_clear_cursors (buffer_id);
		buffer_move_write_head_to_line (buffer_id, edit.line_index - 1);
		buffer_move_line_down (buffer_id, WRITE_HEAD, .DONT_PUSH);
	
	case .MOVE_LINE_DOWN;
		buffer_clear_cursors (buffer_id);
		buffer_move_write_head_to_line (buffer_id, edit.line_index + 1);
		buffer_move_line_up (buffer_id, WRITE_HEAD, .DONT_PUSH);

	case .BATCH_END;
		assert (history.index > 0, "Found a BATCH_END edit, but no matching BATCH_BEGIN edit was found.");
		next := history.edits[history.index - 1];
		while next.kind != .BATCH_BEGIN
		{
			assert (history.index > 0, "Found a BATCH_END edit, but no matching BATCH_BEGIN edit was found.");
			buffer_undo_last_edit (buffer_id);
			next = history.edits[history.index - 1];
		}
		history.index -= 1;	// Skip the matching BATCH_BEGIN edit
	}

	return true;
}
@Amber_API

buffer_redo_last_edit :: (buffer_id : Buffer_ID) -> bool
{
	using buffer := get_buffer (buffer_id);
	if history.index == history.edits.count then return false;
	edit := history.edits[history.index];
	count : s64 = ---;
	if history.index == history.edits.count - 1
		count = history.edit_buffer.count - edit.offset_in_edit_buffer;
	else
		count = history.edits[history.index + 1].offset_in_edit_buffer - edit.offset_in_edit_buffer;
	history.index += 1;

	if edit.kind ==
	{
	case .INSERT;
		text : []u32 = ---;
		text.data = history.edit_buffer.data + edit.offset_in_edit_buffer;
		text.count = count;
		buffer_clear_cursors (buffer_id);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset, WRITE_HEAD);
		buffer_insert_text_at_cursor (buffer_id, text, WRITE_HEAD, .DONT_PUSH);

	case .DELETE;
		buffer_clear_cursors (buffer_id);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset, WRITE_HEAD);
		for 1..count
			buffer_delete_selection (buffer_id, WRITE_HEAD, .DONT_PUSH);

	case .BACKSPACE;
		buffer_clear_cursors (buffer_id);
		buffer_move_cursor_to_offset (buffer_id, edit.cursor.offset, WRITE_HEAD);
		for 1..count
			buffer_backspace_selection (buffer_id, WRITE_HEAD, .DONT_PUSH);

	case .MOVE_LINE_UP;
		buffer_clear_cursors (buffer_id);
		buffer_move_write_head_to_line (buffer_id, edit.line_index);
		buffer_move_line_up (buffer_id, WRITE_HEAD, .DONT_PUSH);
	
	case .MOVE_LINE_DOWN;
		buffer_clear_cursors (buffer_id);
		buffer_move_write_head_to_line (buffer_id, edit.line_index);
		buffer_move_line_down (buffer_id, WRITE_HEAD, .DONT_PUSH);

	case .BATCH_BEGIN;
		assert (history.index < history.edits.count, "Found a BATCH_BEGIN edit, but no matching BATCH_END edit was found.");
		next := history.edits[history.index];
		while next.kind != .BATCH_END
		{
			assert (history.index < history.edits.count, "Found a BATCH_BEGIN edit, but no matching BATCH_END edit was found.");
			buffer_redo_last_edit (buffer_id);
			next = history.edits[history.index];
		}
		history.index += 1;	// Skip the matching BATCH_END edit
	}

	return true;
}
@Amber_API

operator [] :: inline (using buffer : Buffer, index : s64) -> u32 #must
{
	assert (index >= 0 && index < buffer_get_count (buffer.id), "Buffer index is out of range [0;%).", buffer_get_count (buffer.id));
	
	return data[cast (s64) (index >= offset) * gap + index];
}

cursors :: (buffer : *Buffer, body : Code, flags : For_Flags) #expand
{
	BY_POINTER :: (flags & .POINTER) == .POINTER;
	REVERSE    :: (flags & .REVERSE) == .REVERSE;

#if REVERSE
{
	start := buffer.other_cursors.count;
	end   := 0;
}
else
{
	start := 0;
	end   := buffer.other_cursors.count;
}

#if BY_POINTER
	`it : *Buffer_Cursor;
else
	`it : Buffer_Cursor;

	for <=REVERSE i : start..end
	{
		`it_index := cast (Buffer_Cursor_ID) i;
#if BY_POINTER
		it = buffer_get_cursor_ptr (buffer.id, it_index);
else
		it = buffer_get_cursor (buffer.id, it_index);
		#insert (remove=sorted_remove_from_array (*buffer.other_cursors, i - 1)) body;
	}
}

sorted_cursors :: (buffer : *Buffer, body : Code, flags : For_Flags) #expand
{
	REVERSE :: (flags & .REVERSE) == .REVERSE;

#if REVERSE
{
	start := buffer.other_cursors.count;
	end   := 1;
}
else
{
	start := 1;
	end   := buffer.other_cursors.count;
}

	`it : Buffer_Cursor;
	`it_index : Buffer_Cursor_ID;

	buffer_sort_cursors_by_offset (buffer.id);
	iterated_on_write_head := false;
	for <=REVERSE i : start..end
	{
		cursor_id := cast (Buffer_Cursor_ID) i;
		cursor := buffer_get_cursor (buffer.id, cursor_id);
#if REVERSE
{
		if !iterated_on_write_head && buffer.offset > cursor.offset
		{
			iterated_on_write_head = true;
			it_index = WRITE_HEAD;
			it = buffer.write_head;
			#insert body;
		}
}
else
{
		if !iterated_on_write_head && buffer.offset < cursor.offset
		{
			iterated_on_write_head = true;
			it_index = WRITE_HEAD;
			it = buffer.write_head;
			#insert body;
		}
}
		it_index = cursor_id;
		it = cursor;
		#insert body;
	}
	if !iterated_on_write_head
	{
		it_index = WRITE_HEAD;
		it = buffer.write_head;
		#insert (continue={}, break={}) body;
	}
}

selected_text :: (buffer : *Buffer, body : Code, flags : For_Flags) #expand
{
	BY_POINTER :: (flags & .POINTER) == .POINTER;
	REVERSE    :: (flags & .REVERSE) == .REVERSE;
	#assert !BY_POINTER;

#if REVERSE
{
	start := buffer.offset - 1;
	end   := buffer.offset;
	if buffer.selection > 0 then start += buffer.selection;
	if buffer.selection < 0 then end += buffer.selection; 
}
else
{
	start := buffer.offset;
	end   := buffer.offset - 1;
	if buffer.selection < 0 then start += buffer.selection; 
	if buffer.selection > 0 then end += buffer.selection;
}

	for <=REVERSE `it_index : start..end
	{
		index := it_index;
		if it_index >= buffer.offset then index += buffer.gap;
		`it := buffer.data[index];
		#insert (remove=#assert false "Cannot remove while iterating.") body;
	}
}

for_expansion :: (buffer : *Buffer, body : Code, flags : For_Flags) #expand
{
	BY_POINTER :: (flags & .POINTER) == .POINTER;
	REVERSE    :: (flags & .REVERSE) == .REVERSE;
	#assert !BY_POINTER;
	
#if REVERSE
{
	start := buffer_get_count (buffer.id) - 1;
	end   := 0;
}
else
{
	start := 0;
	end   := buffer_get_count (buffer.id) - 1;
}

	for <=REVERSE `it_index : start..end
	{
		index := it_index;
		if it_index >= buffer.offset then index += buffer.gap;
		`it := buffer.data[index];
		#insert (remove=#assert false "Cannot remove while iterating.") body;
	}
}
