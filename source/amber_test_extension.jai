#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";

#program_export
init_extension :: (id : Extension_ID, using hooks : *Amber_Hooks) -> bool
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

command_test :: (using hooks : *Amber_Hooks, str : string, i : int, b : bool, optional := 10)
{
}
@Amber_Command
