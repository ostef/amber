#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";
#load "amber_c.jai";
#load "amber_default_commands.jai";

#program_export
init_extension :: (using hooks : *Amber_Hooks, extension_id : Extension_ID) -> bool
{
	on_update = default_on_update;
	register_all_commands (hooks, extension_id);
	clang : Language;
	clang.extension_id = extension_id;
	clang.name = "C";
	clang.default_associated_file_extensions = string.[ "c", "h" ];
	clang.process_buffer = c_process_buffer;
	language_register (clang);
	
	return true;
}

#program_export
terminate_extension :: (using hooks : *Amber_Hooks)
{
}

default_on_update :: (using hooks : *Amber_Hooks)
{
	reset_temporary_storage ();
}
