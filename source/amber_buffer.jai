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

init_buffer :: (using buffer : *Buffer, capacity : s64)
{
	filename = "";
	name     = "";
	data = alloc (size_of (u32) * capacity, heap_allocator);
	gap       = capacity;
	allocated = capacity;
	offset       = 0;
	selection    = 0;
	line_index   = 0;
	column_index = 0;
	init_array (*other_cursors, 20, heap_allocator);
	init_array (*lines, 5000, heap_allocator);
	push_into_array (*lines, 0);
	
	init_array (*history.edits, 1000, heap_allocator);
	history.index = 0;
	init_array (*history.edit_buffer, capacity, heap_allocator);
	
	eol_sequence = .PLATFORM;
}

clear_buffer :: (using buffer : *Buffer)
{
	gap = allocated;
	offset       = 0;
	selection    = 0;
	line_index   = 0;
	column_index = 0;
	clear_array (*other_cursors);
	clear_history (buffer);
	clear_array (*lines);
	push_into_array (*lines, 0);
}

reset_buffer :: (using buffer : *Buffer)
{
	free (filename, heap_allocator);
	free (name, heap_allocator);
	free (data, heap_allocator);
	data = null;
	allocated = 0;
	offset = 0;
	selection = 0;
	line_index = 0;
	column_index = 0;
	reset_array (*other_cursors);
	reset_array (*lines);
	reset_array (*history.edits);
	history.index = 0;
	reset_array (*history.edit_buffer);
}

clear_history :: inline (using buffer : *Buffer)
{
	clear_array (*history.edits);
	history.index = 0;
	clear_array (*history.edit_buffer);
}

clear_redo_history :: inline (using buffer : *Buffer)
{
	history.edits.count = history.index;
}

grow_buffer :: (using buffer : *Buffer, additional_capacity : s64)
{
	if additional_capacity <= 0 then return;
	count := buffer_count (buffer);
	back  := count - offset;
	new_capacity := allocated + additional_capacity;
	new_gap  := new_capacity - count;
	new_data := cast (*u32) alloc (size_of (u32) * new_capacity, heap_allocator);
	memcpy (new_data, data, offset * size_of (u32));
	memcpy (new_data + offset + new_gap, data + offset + gap, back * size_of (u32));
	
	free (data, heap_allocator);
	data      = new_data;
	allocated = new_capacity;
	gap       = new_gap;
}

buffer_count :: inline (using buffer : *Buffer) -> s64 #must
{
	return allocated - gap;
}

codepoint_at :: inline (using buffer : *Buffer, index : s64) -> u32 #must
{
	assert (index >= 0 && index < buffer_count (buffer), "Buffer index % is out of range [0;%).", index, buffer_count (buffer));
	
	return data[cast (s64) (index >= offset) * gap + index];
}

get_cursor :: inline (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> *Buffer_Cursor #must
{
	assert (cursor_id >= WRITE_HEAD && cursor_id <= xx other_cursors.count, "Invalid cursor id (expected [0;%], got %).", other_cursors.count, cursor_id);
	if cursor_id == WRITE_HEAD
		return *write_head;
	
	return *other_cursors[cast (s64) cursor_id - 1];
}

is_at_bol :: inline (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> bool #must
{
	cursor := get_cursor (buffer, cursor_id);
	
	return cursor.offset == 0 || codepoint_at (buffer, cursor.offset - 1) == #char "\n";
}

is_at_eol :: inline (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> bool #must
{
	cursor := get_cursor (buffer, cursor_id);
	
	return cursor.offset == buffer_count (buffer) || codepoint_at (buffer, cursor.offset) == #char "\n";
}

move_cursor_forward :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_forward (buffer, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		
		return true;
	}
	
	if cursor.offset < buffer_count (buffer)
	{
		prev := codepoint_at (buffer, cursor.offset);
		if cursor_id == WRITE_HEAD
		{
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

move_cursor_backward :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_backward (buffer, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		
		return true;
	}
	
	if cursor.offset > 0
	{
		prev := codepoint_at (buffer, cursor.offset - 1);
		cursor.offset -= 1;
		if select then cursor.selection += 1;
		if cursor_id == WRITE_HEAD
		{
			data[offset + gap] = prev;
			column_index -= 1;
			if prev == #char "\n"
			{
				line_index  -= 1;
				column_index = lines[line_index] - 1;
			}
		}
	
		return true;
	}
	
	return false;
}

move_cursor_to_offset :: (using buffer : *Buffer, new_offset : s64, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_to_offset (buffer, new_offset, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	
	new_offset = clamp (new_offset, 0, buffer_count (buffer));
	while cursor.offset > new_offset
		moved |= move_cursor_backward (buffer, cursor_id, select);
	while cursor.offset < new_offset
		moved |= move_cursor_forward (buffer, cursor_id, select);
	
	return moved;
}

move_write_head_to_line_and_column :: (using buffer : *Buffer, new_line : s64, new_column : s64, select := false) -> bool
{
	moved := move_write_head_to_line (buffer, new_line, select);
	moved |= move_write_head_to_column (buffer, new_column, select);
	
	return moved;
}

move_cursor_to_bol :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	
	while !is_at_bol (buffer, cursor_id)
		moved |= move_cursor_backward (buffer, cursor_id, select);
	
	return moved;
}

move_cursor_to_eol :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_to_eol (buffer, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	
	while !is_at_eol (buffer, cursor_id)
		moved |= move_cursor_forward (buffer, cursor_id, select);
	
	return moved;
}

move_write_head_to_column :: (using buffer : *Buffer, column : s64, select := false) -> bool
{
	moved := false;
	if !select && selection != 0
	{
		selection = 0;
		moved = true;
	}
	
	while !is_at_eol (buffer, WRITE_HEAD) && column_index < column
		moved |= move_cursor_forward (buffer, WRITE_HEAD, select);
	while column_index > 0 && column_index > column
		moved |= move_cursor_backward (buffer, WRITE_HEAD, select);
	
	return moved;
}

move_cursor_to_previous_line :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_to_previous_line (buffer, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	start_offset := cursor.offset;
	moved := false;
	moved |= move_cursor_to_bol (buffer, cursor_id, select);
	if cursor.offset == 0 then return moved;
	start_column := start_offset - cursor.offset;
	moved |= move_cursor_backward (buffer, cursor_id, select);
	start_offset = cursor.offset;
	moved |= move_cursor_to_bol (buffer, cursor_id, select);
	while start_column > 0 && !is_at_eol (buffer, cursor_id)
	{
		moved |= move_cursor_forward (buffer, cursor_id, select);
		start_column -= 1;
	}
	
	return moved;
}

move_cursor_to_next_line :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_to_next_line (buffer, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	start_offset := cursor.offset;
	moved := false;
	moved |= move_cursor_to_bol (buffer, cursor_id, select);
	start_column := start_offset - cursor.offset;
	moved |= move_cursor_to_eol (buffer, cursor_id, select);
	moved |= move_cursor_forward (buffer, cursor_id, select);
	while start_column > 0 && !is_at_eol (buffer, cursor_id)
	{
		moved |= move_cursor_forward (buffer, cursor_id, select);
		start_column -= 1;
	}
	
	return true;
}

move_write_head_to_line :: (using buffer : *Buffer, line : s64, select := false) -> bool
{
	moved := false;
	if !select && selection != 0
	{
		selection = 0;
		moved = true;
	}
	
	while line_index > 0 && line_index > line
		moved |= move_cursor_to_previous_line (buffer, WRITE_HEAD, select);
	while line_index < lines.count - 1 && line_index < line
		moved |= move_cursor_to_next_line (buffer, WRITE_HEAD, select);
	
	return moved;
}

move_cursor_to_beginning :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_to_beginning (buffer, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = false;
	}
	
	while cursor.offset > 0
		moved |= move_cursor_backward (buffer, cursor_id, select);
	
	return moved;
}

move_cursor_to_end :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= move_cursor_to_end (buffer, xx i, select);
		
		return moved;
	}

	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = false;
	}
	
	while cursor.offset < buffer_count (buffer)
		moved |= move_cursor_forward (buffer, cursor_id, select);
	
	return moved;
}

skip_word_forward :: (using buffer : *Buffer, stop_at_word_separators : bool, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= skip_word_forward (buffer, stop_at_word_separators, xx i, select);
		
		return moved;
	}

	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	if cursor.offset == buffer_count (buffer)
		return moved;
	
	while is_space (codepoint_at (buffer, cursor.offset))
	{
		moved |= move_cursor_forward (buffer, cursor_id, select);
		if is_at_eol (buffer, cursor_id)
			return moved;
	}
	
	first := codepoint_at (buffer, cursor.offset);
	moved |= move_cursor_forward (buffer, cursor_id, select);
	codepoint := codepoint_at (buffer, cursor.offset);
	while !is_space (codepoint)
	{
		if is_alpha_num (first) != is_alpha_num (codepoint) then break;
		if codepoint == #char "_" && stop_at_word_separators then break;
		if is_at_eol (buffer, cursor_id) then break;
		moved |= move_cursor_forward (buffer, cursor_id, select);
		codepoint = codepoint_at (buffer, cursor.offset);
	}
	
	return moved;
}

skip_word_backward :: (using buffer : *Buffer, stop_at_word_separators : bool, cursor_id : Buffer_Cursor_ID, select := false) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		moved := false;
		for i : 0..other_cursors.count
			moved |= skip_word_backward (buffer, stop_at_word_separators, xx i, select);
		
		return moved;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	moved := false;
	if !select && cursor.selection != 0
	{
		cursor.selection = 0;
		moved = true;
	}
	if cursor.offset == 0
		return moved;
	
	while !is_at_bol (buffer, cursor_id) && is_space (codepoint_at (buffer, cursor.offset - 1))
		moved |= move_cursor_backward (buffer, cursor_id, select);
	first := codepoint_at (buffer, cursor.offset - 1);
	moved |= move_cursor_backward (buffer, cursor_id, select);
	while !is_space (codepoint_at (buffer, cursor.offset - 1))
	{
		if is_alpha_num (first) != is_alpha_num (codepoint_at (buffer, cursor.offset - 1))
			break;
		if codepoint_at (buffer, cursor.offset) == #char "_" && stop_at_word_separators
			break;
		moved |= move_cursor_backward (buffer, cursor_id, select);
		if is_at_bol (buffer, cursor_id) then break;
	}
	
	return moved;
}

clear_selection :: inline (using buffer : *Buffer)
{
	for :cursors * buffer
		it.selection = 0;
}

clear_cursors :: inline (using buffer : *Buffer)
{
	clear_array (*other_cursors);
}

merge_duplicate_cursors :: inline (using buffer : *Buffer)
{
	cursor_id := WRITE_HEAD;
	while cursor_id <= xx other_cursors.count
	{
		cursor := get_cursor (buffer, cursor_id);
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
					move_cursor_to_offset (buffer, it.offset, cursor_id, select = true);
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

add_cursor_at_offset :: (using buffer : *Buffer, target_offset : s64) -> bool
{
	for :cursors buffer
	{
		if it.selection > 0 && target_offset >= it.offset && target_offset < it.offset + it.selection ||
		   it.selection < 0 && target_offset >= it.offset + it.selection && target_offset < it.offset ||
		   target_offset == it.offset
			return false;
	}
	cursor : Buffer_Cursor;
	index := other_cursors.count;
	for other_cursors
	{
		if it.offset > target_offset
		{
			index = it_index;
			cursor = it;
			
			break;
		}
	}
	sorted_insert_into_array (*other_cursors, index, cursor);
	move_cursor_to_offset (buffer, target_offset, xx (index + 1));
	
	return true;
}

add_cursor_on_previous_line :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		added := false;
		max_cursor_index := other_cursors.count;
		for i : 0..max_cursor_index
			added |= add_cursor_on_previous_line (buffer, xx i);
		
		return added;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	prev_offset    := cursor.offset;
	prev_selection := cursor.selection;
	move_cursor_to_previous_line (buffer, cursor_id);
	target_offset := cursor.offset;
	move_cursor_to_offset (buffer, prev_offset, cursor_id);
	cursor.selection = prev_selection;
	for :cursors buffer
	{
		if it.selection > 0 && target_offset >= it.offset && target_offset < it.offset + it.selection ||
		   it.selection < 0 && target_offset >= it.offset + it.selection && target_offset < it.offset ||
		   target_offset == it.offset
			return false;
	}

	index := other_cursors.count;
	for other_cursors
	{
		if it.offset > target_offset
		{
			index = it_index;
			
			break;
		}
	}
	sorted_insert_into_array (*other_cursors, index, <<cursor);
	move_cursor_to_offset (buffer, target_offset, xx (index + 1));
	
	return true;
}

add_cursor_on_next_line :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> bool
{
	if cursor_id == ALL_CURSORS
	{
		added := false;
		max_cursor_index := other_cursors.count;
		for i : 0..max_cursor_index
			added |= add_cursor_on_next_line (buffer, xx i);
		
		return added;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	prev_offset    := cursor.offset;
	prev_selection := cursor.selection;
	move_cursor_to_next_line (buffer, cursor_id);
	target_offset := cursor.offset;
	move_cursor_to_offset (buffer, prev_offset, cursor_id);
	cursor.selection = prev_selection;
	for :cursors buffer
	{
		if it.selection > 0 && target_offset >= it.offset && target_offset < it.offset + it.selection ||
		   it.selection < 0 && target_offset >= it.offset + it.selection && target_offset < it.offset ||
		   target_offset == it.offset
			return false;
	}
	
	index := other_cursors.count;
	for other_cursors
	{
		if it.offset > target_offset
		{
			index = it_index;
			
			break;
		}
	}
	sorted_insert_into_array (*other_cursors, index, <<cursor);
	move_cursor_to_offset (buffer, target_offset, xx (index + 1));
	
	return true;
}

remove_cursor :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID)
{
	assert (cursor_id > 0 && cursor_id < xx other_cursors.count,
		"Invalid cursor id, expected (0;%), got %.", other_cursors.count, cursor_id);
	sorted_remove_from_array (*other_cursors, xx (cursor_id - 1));
}

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

insert_at_cursor :: (using buffer : *Buffer, codepoint : u32, cursor_id : Buffer_Cursor_ID)
{
	if codepoint == #char "\r" then return;
	if cursor_id == ALL_CURSORS
	{
		for i : 0..other_cursors.count
			insert_at_cursor (buffer, codepoint, xx i);
		
		return;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	prev_offset    := offset;
	prev_selection := selection;
	if cursor_id != WRITE_HEAD
		move_cursor_to_offset (buffer, cursor.offset, WRITE_HEAD);

	if selection != 0 then delete_selection (buffer, WRITE_HEAD);
	if gap == 0 then grow_buffer (buffer, allocated + 8);
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
		move_cursor_to_offset (buffer, prev_offset, WRITE_HEAD);
		selection = prev_selection;
	}
	
	for i : 0..other_cursors.count
	{
		if i == xx cursor_id then continue;
		it := get_cursor (buffer, xx i);
		if it.offset >= cursor.offset - 1 then move_cursor_forward (buffer, xx i);
	}
}

delete_selection :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> bool
{
	delete_helper :: (using buffer : *Buffer)
	{
		codepoint := codepoint_at (buffer, offset);
		gap += 1;
		lines[line_index] -= 1;
		if codepoint == #char "\n"
			merge_current_line_with_next_one (buffer);
	}
	
	if cursor_id == ALL_CURSORS
	{
		modified := false;
		for i : 0..other_cursors.count
			modified |= delete_selection (buffer, xx i);
		
		return modified;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	if cursor.offset == buffer_count (buffer) && cursor.selection == 0
		return false;
	prev_offset    := offset;
	prev_selection := selection;
	if cursor_id != WRITE_HEAD
		move_cursor_to_offset (buffer, cursor.offset, WRITE_HEAD);
	
	count := 0;
	if selection == 0
	{
		delete_helper (buffer);
		count += 1;
	}
	
	while selection < 0
	{
		move_cursor_backward (buffer, WRITE_HEAD, select = true);
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
		move_cursor_to_offset (buffer, prev_offset, WRITE_HEAD);
		selection = prev_selection;
	}

	for i : 0..other_cursors.count
	{
		if i == xx cursor_id then continue;
		it := get_cursor (buffer, xx i);
		if it.offset >= cursor.offset - 1
		{
			for 0..count - 1
				move_cursor_backward (buffer, xx i);
		}
	}

	return true;
}

backspace_selection :: (using buffer : *Buffer, cursor_id : Buffer_Cursor_ID) -> bool #must
{
	if cursor_id == ALL_CURSORS
	{
		modified := false;
		for i : 0..other_cursors.count
			modified |= backspace_selection (buffer, xx i);
	
		return modified;
	}
	
	cursor := get_cursor (buffer, cursor_id);
	if cursor.selection != 0 then return delete_selection (buffer, cursor_id);
	if cursor.offset == 0 then return false;
	prev_offset    := offset;
	prev_selection := selection;
	if cursor_id != WRITE_HEAD
		move_cursor_to_offset (buffer, cursor.offset, WRITE_HEAD);

	codepoint := codepoint_at (buffer, offset - 1);
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
		move_cursor_to_offset (buffer, prev_offset, WRITE_HEAD);
		selection = prev_selection;
	}
	
	for i : 0..other_cursors.count
	{
		if i == xx cursor_id then continue;
		it := get_cursor (buffer, xx i);
		if it.offset >= cursor.offset - 1 then move_cursor_backward (buffer, xx i);
	}
	
	return true;
}

operator [] :: inline (using buffer : Buffer, index : s64) -> u32 #must
{
	assert (index >= 0 && index < buffer_count (*buffer), "Buffer index is out of range [0;%).", buffer_count (*buffer));
	
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
		it = get_cursor (buffer, it_index);
else
		it = <<get_cursor (buffer, it_index);
		#insert (remove=sorted_remove_from_array (*buffer.other_cursors, i - 1)) body;
	}
}

for_expansion :: (buffer : *Buffer, body : Code, flags : For_Flags) #expand
{
	BY_POINTER :: (flags & .POINTER) == .POINTER;
	REVERSE    :: (flags & .REVERSE) == .REVERSE;
	
#if REVERSE
{
	start := buffer_count (buffer) - 1;
	end   := 0;
}
else
{
	start := 0;
	end   := buffer_count (buffer) - 1;
}

#if BY_POINTER
	`it : *u32;
else
	`it : u32;

	for <=REVERSE `it_index : start..end
	{
		index := it_index;
		if it_index >= buffer.offset then index += buffer.gap;
#if BY_POINTER
		it = *buffer.data[index];
else
		it = buffer.data[index];
		#insert (remove=#assert false "Cannot remove while iterating.") body;
	}
}
