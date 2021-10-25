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
	return language_register (language);
}

#program_export
terminate_extension :: (using amber : *Amber_Hooks)
{
	println ("Goodbye Sailor!");
}

foo_process_buffer :: (using amber : *Amber_Hooks, buffer_id : Buffer_ID)
{
	println ("Foo is processing the buffer %.", buffer_id);
}
