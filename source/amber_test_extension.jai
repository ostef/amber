#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";

#program_export
init_extension :: (id : Extension_ID, using hooks : *Amber_Hooks) -> bool
{
	println ("Hello Sailor, I am extension %!", id);
	register_all_commands (hooks, id);
	on_event = handle_event;
	
	return true;
}

#program_export
terminate_extension :: (using hooks : *Amber_Hooks)
{
	println ("Goodbye Sailor!");
}

handle_event :: (using hooks : *Amber_Hooks, event : Event) -> Event_Result, bool
{
	result : Event_Result;
	if event.kind == .KEY_PRESS && event.key_code == .H && event.mods == .CONTROL
	{
		for i : 0.."Hello Sailor!".count - 1
			buffer_insert_at_cursor (get_active_buffer (), "Hello Sailor!"[i], ALL_CURSORS);
		result.buffer_modified = true;
		result.scroll_to_cursor = true;

		return result, false;
	}

	return result, true;
}

command_test :: (using hooks : *Amber_Hooks, str : string, i : int, b : bool, optional := 10)
{
	println (str);
	println (i);
	println (b);
	println (optional);
}
@Amber_Command
