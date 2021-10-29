#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_math.jai";
#load "amber_hooks.jai";

#program_export
init_extension :: (id : Extension_ID, using amber : *Amber_Hooks) -> bool
{
	println ("Hello Sailor, I am extension %!", id);
	language : Language;
	language.extension_id = id;
	language.name = "foo";
	language.process_buffer = foo_process_buffer;
	on_event  = handle_event;
	on_update = update;
	
	return language_register (language);
}

#program_export
terminate_extension :: (using amber : *Amber_Hooks)
{
	println ("Goodbye Sailor!");
}

handle_event :: (using amber : *Amber_Hooks, event : Event) -> Event_Result, propagate : bool
{
	result : Event_Result;
	if event.kind == .KEY_PRESS
	{
		if event.key_code == .H && event.mods == .CONTROL
		{
			for i : 0.."Hello Sailor!".count - 1
				buffer_insert_at_cursor (split_get_active_buffer (get_active_split ()), "Hello Sailor!"[i], ALL_CURSORS);
			result.buffer_modified  = true;
			result.scroll_to_cursor = true;
			
			return result, false;
		}
	}
	
	return result, true;
}

update :: (using amber : *Amber_Hooks)
{
}

foo_process_buffer :: (using amber : *Amber_Hooks, buffer_id : Buffer_ID)
{
	println ("Foo is processing the buffer %.", buffer_id);
}
