EOL_Sequence :: enum
{
	LF :: 0;
	CRLF :: 1;

	#if OS == .WINDOWS
		PLATFORM :: CRLF;
	else
		PLATFORM :: LF;
}

// @Todo (stefan): Page buffer
Buffer :: struct
{
	Id :: type_of (buffers).Slot_Info;

	History :: struct
	{
		edits : [..]Edit;
		undo_cursor : s64;
		edit_buffer : [..]u32;
	}

	Edit :: struct
	{
		Kind :: enum
		{
			INSERT    :: 0;
			DELETE    :: 1;
			BACKSPACE :: 2;
			MOVE_LINE_UP   :: 3;
			MOVE_LINE_DOWN :: 4;

			BATCH_BEGIN :: 100;
			BATCH_END   :: 101;
		}

		kind : Kind;
		line_index : s64;
		char_index : s64;
		selection  : s64;
		offset_in_edit_buffer : s64;
	}

	filename : string;
	data : *u32;
	cursor : s64;
	gap    : s64;
	allocated : s64;
	allocator : Allocator;
	line_index, column_index : s64;
	line_count : s64;
	#place line_count;
	line_lengths : [..]s64;
	history : History;
	eol_sequence := EOL_Sequence.PLATFORM;

}

init :: (using buffer : *Buffer, capacity : s64)
{
	mem.init (buffer);
	data = mem.alloc (size_of (u32) * capacity, mem.HEAP_ALLOC);
	assert (data != null, "Could not allocate memory for buffer (requested % characters).", capacity);
	gap = capacity;
	allocated = capacity;
	array.init (*line_lengths, 5000, mem.HEAP_ALLOC);
	array.push (*line_lengths, 0);
	array.init (*history.edits, 1000, mem.HEAP_ALLOC);
	array.init (*history.edit_buffer, capacity, mem.HEAP_ALLOC);
}

reset :: (using buffer : *Buffer)
{
	mem.free (filename, mem.HEAP_ALLOC);
	mem.free (data, mem.HEAP_ALLOC);
	array.reset (*line_lengths);
	array.reset (*history.edits);
	array.reset (*history.edit_buffer);
	mem.init (buffer);
}

load_file :: (buffer : *Buffer, filename : string) -> bool
{
	full_filename := fs.get_full_filename (filename, mem.HEAP_ALLOC);
	contents, ok := fs.read_entire_file (full_filename, mem.HEAP_ALLOC);
	if !ok
	{
		mem.free (full_filename, mem.HEAP_ALLOC);
		return false;
	}
	defer mem.free (contents, mem.HEAP_ALLOC);
	clear (buffer);
	for utf8.make_str (contents)
		insert (buffer, it);
	buffer.filename = full_filename;
	return true;
}

write_to_file :: (buffer : *Buffer, filename : string) -> bool
{
	if !filename
		return false;
	data : []u8;
	for buffer
		data.count += utf8.encoding_length (it);
	if buffer.eol_sequence == .CRLF
		data.count += buffer.line_count - 1;
	data.data = mem.alloc (data.count, mem.HEAP_ALLOC);
	defer mem.free (data, mem.HEAP_ALLOC);
	byte_offset := 0;
	for buffer
	{
		if buffer.eol_sequence == .CRLF && it == #char "\n"
			byte_offset += utf8.encode (data, byte_offset, #char "\r");
		byte_offset += utf8.encode (data, byte_offset, it);
	}
	written, err := fs.write_to_file (filename, data);

	return err == .OK;
}

write_to_file :: inline (buffer : *Buffer) -> bool
{
	return write_to_file (buffer, buffer.filename);
}

clear :: (using buffer : *Buffer)
{
	gap = allocated;
	cursor = 0;
	line_index = 0;
	column_index = 0;
	clear_history (buffer);
	array.clear (*line_lengths);
	array.push (*line_lengths, 0);
}

clear_history :: (using buffer : *Buffer)
{
	array.clear (*history.edits);
	history.undo_cursor = 0;
	array.clear (*history.edit_buffer);
}

grow :: (using buffer : *Buffer, add_cap : s64)
{
	if add_cap <= 0
		return;
	count := get_count (buffer);
	back  := count - cursor;
	new_capacity := allocated + add_cap;
	new_gap      := new_capacity - count;
	new_data     := cast (*u32) mem.alloc (size_of (u32) * new_capacity, mem.HEAP_ALLOC);
	mem.copy (new_data, data, cursor * size_of (u32));
	mem.copy (new_data + cursor + new_gap, data + cursor + gap, back * size_of (u32));

	mem.free (data, mem.HEAP_ALLOC);
	data      = new_data;
	allocated = new_capacity;
	gap       = new_gap;
}

get_count :: inline (using buffer : Buffer) -> s64 #must
{
	return allocated - gap;
}

char_at :: inline (using buffer : Buffer, index : s64) -> u32 #must
{
	assert (index >= 0 && index < get_count (buffer), "Bounds check failure (got %, expected [0;%) ).", index, get_count (buffer));
	return data[cast (s64) (index >= cursor) * gap + index];
}

move_cursor_forward :: (using buffer : *Buffer) -> bool
{
	if cursor < get_count (buffer)
	{
		prev := char_at (buffer, cursor);
		data[cursor] = prev;
		cursor += 1;
		if prev == #char "\n"
		{
			line_index += 1;
			column_index = 0;
		}
		return true;
	}
	return false;
}

move_cursor_backward :: (using buffer : *Buffer) -> bool
{
	if cursor > 0
	{
		prev := char_at (buffer, cursor - 1);
		cursor -= 1;
		data[cursor + gap] = prev;
		if prev == #char "\n"
		{
			line_index -= 1;
			column_index = line_lengths[line_index] - 1;
		}
		return true;
	}
	return false;
}

#scope_file

split_current_line :: inline (using buffer : *Buffer)
{
	current := line_lengths[line_index];
	first_half := column_index;
	second_half := current - first_half;
	line_lengths[line_index] = first_half;
	array.ordered_insert_at (*line_lengths, line_index + 1, second_half);
}

#scope_export

insert :: (using buffer : *Buffer, codepoint : u32)
{
	if gap == 0
		grow (buffer, allocated + 8);
	data[cursor] = codepoint;
	cursor += 1;
	gap -= 1;
	line_lengths[line_index] += 1;
	column_index += 1;
	if codepoint == #char "\n"
	{
		split_current_line (buffer);
		line_index += 1;
		column_index = 0;
	}
}

#scope_file

merge_current_line_with_next_one :: inline (using buffer : *Buffer)
{
	if line_index == line_count - 1
		return;
	line_lengths[line_index] += line_lengths[line_index + 1];
	array.ordered_remove_at (*line_lengths, line_index + 1);
}

#scope_export

delete :: (using buffer : *Buffer) -> bool
{
	if cursor == get_count (buffer)
		return false;
	codepoint := char_at (buffer, cursor);
	gap += 1;
	line_lengths[line_index] -= 1;
	if codepoint == #char "\n"
		merge_current_line_with_next_one (buffer);
	return true;
}

delete :: (using buffer : *Buffer, selection : s64) -> bool
{
	if selection == 0
		return delete (buffer);
	while selection < 0
	{
		move_cursor_backward (buffer);
		delete (buffer);
		selection += 1;
	}
	while selection > 0
	{
		delete (buffer);
		selection -= 1;
	}
	return true;
}

backspace :: (using buffer : *Buffer) -> bool
{
	if cursor == 0
		return false;
	codepoint := char_at (buffer, cursor - 1);
	cursor -= 1;
	gap += 1;
	line_lengths[line_index] -= 1;
	column_index -= 1;
	if codepoint == #char "\n"
	{
		line_index -= 1;
		column_index = line_lengths[line_index] - 1;
		merge_current_line_with_next_one (buffer);
	}
	return true;
}

backspace :: (using buffer : *Buffer, selection : s64) -> bool
{
	if selection == 0
		return backspace (buffer);
	return delete (buffer, selection);
}

for_expansion :: (buffer : *Buffer, body : Code, flags : For_Flags) #expand
{
	BY_POINTER :: (flags & .POINTER) == .POINTER;
	REVERSE    :: (flags & .REVERSE) == .REVERSE;
	#assert !BY_POINTER "Cannot iterate by pointer.";

	#if REVERSE
	{
		start := get_count (buffer) - 1;
		end   := 0;
	}
	else
	{
		start := 0;
		end   := get_count (buffer) - 1;
	}

	for <=REVERSE `it_index : start..end
	{
		`it := char_at (buffer, it_index);
		#insert (remove=#assert false "Cannot remove while iterating.") body;
	}
}
