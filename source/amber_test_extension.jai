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
	on_input = handle_input_event;

	return language_register (language);
}

#program_export
terminate_extension :: (using amber : *Amber_Hooks)
{
	println ("Goodbye Sailor!");
}

handle_input_event :: (using amber : *Amber_Hooks, event : Input_Event) -> bool
{
	if event.kind == .KEY_PRESS
	{
		if event.key_code == .H && event.mods == .CONTROL
		{
			for i : 0.."Hello Sailor!".count - 1
			{
				buffer_insert_at_cursor (cast (Buffer_ID) 1, "Hello Sailor!"[i], ALL_CURSORS);
			}
			
			return true;
		}
	}
	
	return false;
}

foo_process_buffer :: (using amber : *Amber_Hooks, buffer_id : Buffer_ID)
{
	println ("Foo is processing the buffer %.", buffer_id);
}
