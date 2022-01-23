command_quit :: (using hooks : *Amber_Hooks) -> bool
{
	amber_terminate ();
	
	return true;
}
@Amber_Command

command_exit :: (using hooks : *Amber_Hooks) -> bool
{
	amber_terminate ();
	
	return true;
}
@Amber_Command

command_lsplit :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_left (split_id));
	
	return true;
}
@Amber_Command

command_rsplit :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_right (split_id));

	return true;
}
@Amber_Command

command_asplit :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_above (split_id));

	return true;
}
@Amber_Command

command_bsplit :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_below (split_id));

	return true;
}
@Amber_Command

command_merge :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		return false;
	split_merge (split_id);

	return true;
}
@Amber_Command

command_open :: (using hooks : *Amber_Hooks, filename : string) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		split_create_first ();
	buffer_id = get_active_buffer ();
	ok := buffer_load_file (buffer_id, filename);
	buffer_move_cursor_to_beginning (buffer_id, WRITE_HEAD, false);
	
	return ok;
}
@Amber_Command

command_save :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	
	return buffer_write_to_file (buffer_id);
}
@Amber_Command

command_new :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		split_open_buffer (split_id);
	
	return true;
}
@Amber_Command

command_close :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		amber_terminate ();
	else
		split_close_buffer (split_id, split_get_active_buffer_index (split_id));
	
	return true;
}
@Amber_Command

command_prev :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id != NULL_SPLIT
	{
		buffer_index := split_get_active_buffer_index (split_id);
		buffer_count := split_get_buffer_count (split_id);
		split_set_active_buffer (split_id, wrap (buffer_index - 1, buffer_count));
	}
	
	return true;
}
@Amber_Command

command_next :: (using hooks : *Amber_Hooks) -> bool
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		return false;
	buffer_index := split_get_active_buffer_index (split_id);
	buffer_count := split_get_buffer_count (split_id);
	split_set_active_buffer (split_id, wrap (buffer_index + 1, buffer_count));
	
	return true;
}
@Amber_Command

command_line :: (using hooks : *Amber_Hooks, line : s64) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	buffer_clear_cursors (buffer_id);
	buffer_move_cursor_to_line (buffer_id, line - 1, WRITE_HEAD, false);
	buffer_move_cursor_to_bol (buffer_id, WRITE_HEAD, false);
	
	return true;
}
@Amber_Command

command_undo :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	
	return buffer_undo_last_edit (buffer_id);
}
@Amber_Command

command_redo :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	
	return buffer_redo_last_edit (buffer_id);
}
@Amber_Command

command_clear_cursors_and_selection :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_clear_cursors (buffer_id);
	buffer_clear_selection (buffer_id);

	return true;
}
@Amber_Command

command_paste :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	clipboard_text := platform_get_clipboard_text (TEMP);
	if clipboard_text.count
		buffer_insert_utf8_text_at_cursor (buffer_id, clipboard_text, ALL_CURSORS, .PUSH_EDIT);

	return true;
}
@Amber_Command

command_newline :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_insert_at_cursor (buffer_id, #char "\n", ALL_CURSORS, .PUSH_EDIT);

	return true;
}
@Amber_Command

command_newline_above :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_move_cursor_to_bol (buffer_id, ALL_CURSORS, false);
	buffer_insert_at_cursor (buffer_id, #char "\n", ALL_CURSORS, .PUSH_EDIT);
	buffer_move_cursor_backward (buffer_id, ALL_CURSORS, false);

	return true;
}
@Amber_Command

command_backspace :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_backspace_selection (buffer_id, ALL_CURSORS, .PUSH_EDIT);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_backspace_word :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_skip_word_backward (buffer_id, config_get_bool ("treat_underscores_as_alpha_numeric_boundary", true), ALL_CURSORS, true);
	result := buffer_backspace_selection (buffer_id, ALL_CURSORS, .PUSH_EDIT);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_delete :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_delete_selection (buffer_id, ALL_CURSORS, .PUSH_EDIT);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_delete_word :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_skip_word_forward (buffer_id, config_get_bool ("treat_underscores_as_alpha_numeric_boundary", true), ALL_CURSORS, true);
	result := buffer_delete_selection (buffer_id, ALL_CURSORS, .PUSH_EDIT);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_left :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_backward (buffer_id, ALL_CURSORS, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_left :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_backward (buffer_id, ALL_CURSORS, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_prev_word :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_skip_word_backward (buffer_id, config_get_bool ("treat_underscores_as_alpha_numeric_boundary", true), ALL_CURSORS, flagged (platform_get_mod_state (), .SHIFT));
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_prev_word :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_skip_word_backward (buffer_id, config_get_bool ("treat_underscores_as_alpha_numeric_boundary", true), ALL_CURSORS, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_right :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_forward (buffer_id, ALL_CURSORS, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_right :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_forward (buffer_id, ALL_CURSORS, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_next_word :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_skip_word_forward (buffer_id, config_get_bool ("treat_underscores_as_alpha_numeric_boundary", true), ALL_CURSORS, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_next_word :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_skip_word_forward (buffer_id, config_get_bool ("treat_underscores_as_alpha_numeric_boundary", true), ALL_CURSORS, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_to_previous_line (buffer_id, ALL_CURSORS, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_to_previous_line (buffer_id, ALL_CURSORS, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_to_next_line (buffer_id, ALL_CURSORS, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_cursor_to_next_line (buffer_id, ALL_CURSORS, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_page_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	layout_id := buffer_get_text_layout (buffer_id);
	page_height := cast (s64) (rect_height (text_layout_get_area (layout_id)) / text_layout_get_line_height (layout_id));

	result := false;
	for 1..page_height
	{
		if buffer_move_cursor_to_previous_line (buffer_id, ALL_CURSORS, false)
			result = true;
		else
			break;
	}
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_page_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	layout_id := buffer_get_text_layout (buffer_id);
	page_height := cast (s64) (rect_height (text_layout_get_area (layout_id)) / text_layout_get_line_height (layout_id));

	result := false;
	for 1..page_height
	{
		if buffer_move_cursor_to_previous_line (buffer_id, ALL_CURSORS, true)
			result = true;
		else
			break;
	}
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_page_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	layout_id := buffer_get_text_layout (buffer_id);
	page_height := cast (s64) (rect_height (text_layout_get_area (layout_id)) / text_layout_get_line_height (layout_id));

	result := false;
	for 1..page_height
	{
		if buffer_move_cursor_to_next_line (buffer_id, ALL_CURSORS, false)
			result = true;
		else
			break;
	}
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_page_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;
	layout_id := buffer_get_text_layout (buffer_id);
	page_height := cast (s64) (rect_height (text_layout_get_area (layout_id)) / text_layout_get_line_height (layout_id));

	result := false;
	for 1..page_height
	{
		if buffer_move_cursor_to_next_line (buffer_id, ALL_CURSORS, true)
			result = true;
		else
			break;
	}
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_move_line_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_line_up (buffer_id, ALL_CURSORS, .PUSH_EDIT);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_move_line_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	result := buffer_move_line_down (buffer_id, ALL_CURSORS, .PUSH_EDIT);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_add_cursor_above :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	return buffer_add_cursor_on_previous_line (buffer_id, ALL_CURSORS);
}
@Amber_Command

command_add_cursor_below :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	return buffer_add_cursor_on_next_line (buffer_id, ALL_CURSORS);
}
@Amber_Command

command_scroll_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	layout_id := buffer_get_text_layout (buffer_id);
	text_layout_scroll_y (layout_id, -1);

	return true;
}
@Amber_Command

command_scroll_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	layout_id := buffer_get_text_layout (buffer_id);
	text_layout_scroll_y (layout_id, 1);

	return true;
}
@Amber_Command

command_scroll_page_up :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	layout_id := buffer_get_text_layout (buffer_id);
	page_height := cast (s64) (rect_height (text_layout_get_area (layout_id)) / text_layout_get_line_height (layout_id));
	text_layout_scroll_y (layout_id, cast (f32) -page_height);

	return true;
}
@Amber_Command

command_scroll_page_down :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	layout_id := buffer_get_text_layout (buffer_id);
	page_height := cast (s64) (rect_height (text_layout_get_area (layout_id)) / text_layout_get_line_height (layout_id));
	text_layout_scroll_y (layout_id, cast (f32) page_height);

	return true;
}
@Amber_Command

command_beginning :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_clear_cursors (buffer_id);
	result := buffer_move_cursor_to_beginning (buffer_id, WRITE_HEAD, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_to_beginning :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_clear_cursors (buffer_id);
	result := buffer_move_cursor_to_beginning (buffer_id, WRITE_HEAD, true);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_end :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_clear_cursors (buffer_id);
	result := buffer_move_cursor_to_end (buffer_id, WRITE_HEAD, false);
	buffer_merge_duplicate_cursors (buffer_id);

	return result;
}
@Amber_Command

command_select_to_end :: (using hooks : *Amber_Hooks) -> bool
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		return false;

	buffer_clear_cursors (buffer_id);
	result := buffer_move_cursor_to_end (buffer_id, WRITE_HEAD, true);

	return result;
}
@Amber_Command
