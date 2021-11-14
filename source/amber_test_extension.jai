#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";

#program_export
init_extension :: (id : Extension_ID, using amber : *Amber_Hooks) -> bool
{
	println ("Hello Sailor, I am extension %!", id);
	
	return true;
}

#program_export
terminate_extension :: (using amber : *Amber_Hooks)
{
	println ("Goodbye Sailor!");
}
