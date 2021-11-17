#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";

#program_export
init_extension :: (using hooks : *Amber_Hooks, extension_id : Extension_ID) -> bool
{
	register_all_commands (hooks, extension_id);
	
	return true;
}

#program_export
terminate_extension :: (using hooks : *Amber_Hooks)
{
}

command_lsplit :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_left (split_id));
}
@Amber_Command

command_rsplit :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_right (split_id));
}
@Amber_Command

command_asplit :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_above (split_id));
}
@Amber_Command

command_bsplit :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		set_active_split (split_create_below (split_id));
}
@Amber_Command

command_merge :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id != NULL_SPLIT
		split_merge (split_id);
}
@Amber_Command

command_open :: (using hooks : *Amber_Hooks, filename : string)
{
	buffer_id := get_active_buffer ();
	if buffer_id == NULL_BUFFER
		split_create_first ();
	buffer_id = get_active_buffer ();
	buffer_load_file (buffer_id, filename);
	buffer_move_cursor_to_beginning (buffer_id, WRITE_HEAD, false);
}
@Amber_Command

command_save :: (using hooks : *Amber_Hooks)
{
	buffer_id := get_active_buffer ();
	if buffer_id != NULL_BUFFER
		buffer_write_to_file (buffer_id);
}
@Amber_Command

command_new :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		split_create_first ();
	else
		split_open_buffer (split_id);
}
@Amber_Command

command_close :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id == NULL_SPLIT
		amber_terminate ();
	else
		split_close_buffer (split_id, split_get_active_buffer_index (split_id));
}
@Amber_Command

command_prev :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id != NULL_SPLIT
	{
		buffer_index := split_get_active_buffer_index (split_id);
		buffer_count := split_get_buffer_count (split_id);
		split_set_active_buffer (split_id, wrap (buffer_index - 1, buffer_count));
	}
}
@Amber_Command

command_next :: (using hooks : *Amber_Hooks)
{
	split_id := get_active_split ();
	if split_id != NULL_SPLIT
	{
		buffer_index := split_get_active_buffer_index (split_id);
		buffer_count := split_get_buffer_count (split_id);
		split_set_active_buffer (split_id, wrap (buffer_index + 1, buffer_count));
	}
}
@Amber_Command

command_line :: (using hooks : *Amber_Hooks, line : s64)
{
	buffer_id := get_active_buffer ();
	if buffer_id != NULL_BUFFER
	{
		buffer_clear_cursors (buffer_id);
		buffer_move_write_head_to_line (buffer_id, line - 1, false);
		buffer_move_cursor_to_bol (buffer_id, WRITE_HEAD, false);
	}
}
@Amber_Command
