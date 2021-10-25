Command :: struct
{
	Proc :: #type (*Amber_Hooks, []string);
	
	extension_id : Extension_ID;
	name : string;
	proc : Proc;
	arg_count : s64;
	first_optional_argument : s64;
}

#scope_file

commands : [..]Command;

#scope_export

command_register :: (command : Command) -> bool
{
	if !commands.allocator then commands.allocator = heap_allocator;
	if !command.name || !command.proc
		return false;
	for commands
	{
		if it.name == command.name
			return false;
	}
	push_into_array (*commands, command);
	
	return true;
}
@Amber_API
