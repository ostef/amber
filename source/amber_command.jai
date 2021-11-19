Command :: struct
{
	extension_id : Extension_ID;
	name : string;
	proc : Command_Proc;
	arg_count : s64;
	first_optional_argument : s64;
	combination : Key_Combination;
}

Command_Args :: struct
{
	name : string;
	args : []string;
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

parse_command_line :: (cmd_line : []u32) -> []Command_Args #must
{
	// @Todo (stefan): Handle errors like unclosed string literal.
	
	utf32 := cmd_line;
	result : [..]Command_Args;
	init_array (*result, 5, temp_allocator);
	while utf32.count
	{
		while utf32.count && is_space (utf32[0])
			utf32 = advance (utf32);
		// Parse name
		utf32_name := utf32;
		while utf32.count && !is_space (utf32[0])
			utf32 = advance (utf32);
		utf32_name.count = utf32.data - utf32_name.data;
		
		// Parse arguments
		args : [..]string;
		init_array (*args, 10, temp_allocator);
		current_arg : [..]u32;
		init_array (*current_arg, 20, temp_allocator);
		while utf32.count
		{
			clear_array (*current_arg);
			// Skip spaces
			while utf32.count && is_space (utf32[0]) && utf32[0] != #char "&"
				utf32 = advance (utf32);
			if !utf32.count then break;
			
			if utf32[0] == #char "&"
			{
				utf32 = advance (utf32);
				
				break;
			}
			else if utf32[0] == #char "\""
			{
				utf32 = advance (utf32);
				while utf32.count && utf32[0] != #char "\""
				{
					if utf32[0] == #char "\\"
						utf32 = advance (utf32);
					push_into_array (*current_arg, utf32[0]);
					utf32 = advance (utf32);
				}
				utf32 = advance (utf32);
				push_into_array (*args, utf32_to_utf8 (current_arg, temp_allocator));
			}
			else
			{
				while utf32.count && !is_space (utf32[0])
				{
					push_into_array (*current_arg, utf32[0]);
					utf32 = advance (utf32);
				}
				push_into_array (*args, utf32_to_utf8 (current_arg, temp_allocator));
			}
		}
		
		if utf32_name.count != 0
		{
			cmd := push_into_array (*result);
			cmd.name = utf32_to_utf8 (utf32_name, temp_allocator);
			cmd.args = args;
		}
	}
	
	return result;
}

command_execute :: (utf32 : []u32)
{
	execution_line := parse_command_line (utf32);
	command : *Command;
	for current : execution_line
	{
		cmd : *Command;
		for * commands
		{
			if it.name == current.name
			{
				cmd = it;
				
				break;
			}
		}
		if !cmd then break;
		if !cmd.proc (get_hooks (cmd.extension_id), current.args) then break;
	}
}
@Amber_API
