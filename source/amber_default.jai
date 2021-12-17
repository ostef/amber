#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";
#load "amber_c.jai";

#program_export
init_extension :: (using hooks : *Amber_Hooks, extension_id : Extension_ID) -> bool
{
	register_all_commands (hooks, extension_id);
	clang : Language;
	clang.extension_id = extension_id;
	clang.name = "C";
	clang.associated_file_extensions = string.[ "c", "h" ];
	clang.process_buffer = c_process_buffer;
	language_register (clang);
	
	return true;
}

#program_export
terminate_extension :: (using hooks : *Amber_Hooks)
{
}

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
