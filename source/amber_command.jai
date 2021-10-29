#scope_file

commands : [..]Command;

#scope_export

command_register :: inline (command : Command) -> bool
{
	if !commands.allocator then commands.allocator = heap_allocator;
	if !command.name || !command.proc
		return false;
	for commands
	{
		if it.name == command.name
			return false;
	}
	pushed := push_into_array (*commands, command);
	// @Note (stefan): We don't make assumptions about where the memory for name and
	// combination comes from, so we allocate new memory for them.
	pushed.name = clone_string (command.name, heap_allocator);
	pushed.combination = clone_array (command.combination, heap_allocator);
	
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
