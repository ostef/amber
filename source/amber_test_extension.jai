#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";

#program_export
init_extension :: (using hooks : *Amber_Hooks, extension_id : Extension_ID) -> bool
{
	println ("Hello Sailor, I am extension %!", id);
	register_all_commands (hooks, id);
	
	return true;
}

#program_export
terminate_extension :: (using hooks : *Amber_Hooks)
{
	println ("Goodbye Sailor!");
}
