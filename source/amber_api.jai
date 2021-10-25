buffer_get_codepoint :: (buffer_id : Buffer_ID, index : s64) -> u32 #must
{
	buffer := get_buffer (buffer_id);
	
	return codepoint_at (buffer, index);
}
@Amber_API

buffer_get_line_count :: (buffer_id : Buffer_ID) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	
	return buffer.lines.count;
}
@Amber_API

buffer_get_line_length :: (buffer_id : Buffer_ID, line_index : s64) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	
	return buffer.lines[line_index];
}
@Amber_API

buffer_get_length :: (buffer_id : Buffer_ID) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	
	return buffer.allocated - buffer.gap;
}
@Amber_API

buffer_get_cursor_count :: (buffer_id : Buffer_ID) -> s64 #must
{
	buffer := get_buffer (buffer_id);
	
	return buffer.other_cursors.count + 1;
}
@Amber_API

buffer_get_cursor :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> Buffer_Cursor #must
{
	buffer := get_buffer (buffer_id);
	
	return <<get_cursor (buffer, cursor_id);
}
@Amber_API

buffer_add_cursor_at_offset :: (buffer_id : Buffer_ID, offset : s64) -> bool
{
	buffer := get_buffer (buffer_id);

	return add_cursor_at_offset (buffer, offset);
}
@Amber_API

buffer_add_cursor_on_previous_line :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
{
	buffer := get_buffer (buffer_id);

	return add_cursor_on_previous_line (buffer, cursor_id);
}
@Amber_API

buffer_add_cursor_on_next_line :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
{
	buffer := get_buffer (buffer_id);
	
	return add_cursor_on_next_line (buffer, cursor_id);
}
@Amber_API

buffer_remove_cursor :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID)
{
	assert (cursor_id != 0, "Cannot remove write head cursor.");
	buffer := get_buffer (buffer_id);
	assert (cursor_id > 0 && cursor_id < xx buffer.other_cursors.count,
		"Invalid cursor id, expected (0;%), got %.", buffer.other_cursors.count, cursor_id);
	remove_cursor (buffer, cursor_id);
}
@Amber_API

buffer_insert :: (buffer_id : Buffer_ID, codepoint : u32, cursor_id : Buffer_Cursor_ID)
{
	buffer := get_buffer (buffer_id);
	insert_at_cursor (buffer, codepoint, cursor_id);
}
@Amber_API

buffer_delete :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
{
	buffer := get_buffer (buffer_id);
	
	return delete_selection (buffer, cursor_id);
}
@Amber_API

buffer_backspace :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
{
	buffer := get_buffer (buffer_id);
	
	return backspace_selection (buffer, cursor_id);
}
@Amber_API
