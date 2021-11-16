Command :: struct
{
	extension_id : Extension_ID;
	name : string;
	proc : Command_Proc;
	arg_count : s64;
	first_optional_argument : s64;
	combination : Key_Combination;
}

#scope_file

commands : [..]Command;

#scope_export

command_register :: (
	extension_id : Extension_ID,
	using info : Command_Info
) -> bool
{
	if !commands.allocator then commands.allocator = heap_allocator;
	if !name || !proc
		return false;
	for commands
	{
		if it.name == name
			return false;
	}
	pushed := push_into_array (*commands);
	// @Note (stefan): We don't make assumptions about where the memory for name and
	// combination comes from, so we allocate new memory for them.
	pushed.extension_id = extension_id;
	pushed.name = clone_string (name, heap_allocator);
	pushed.proc = proc;
	pushed.arg_count = arg_count;
	pushed.first_optional_argument = first_optional_argument;
	
	return true;
}
@Amber_API

command_unregister_for_extension :: (extension_id : Extension_ID)
{
	for * commands
	{
		if it.extension_id == extension_id
		{
			free (it.name, heap_allocator);
			remove it;
		}
	}
}
@Amber_API
