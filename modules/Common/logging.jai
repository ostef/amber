#if OS == .WINDOWS
{
	console_logger :: (message : string, data : *void, info : Log_Info)
	{
		flags_to_color :: (flags : Log_Flags) -> u16
		{
			if flags & .CONTENT then return 10;	// Green
			if flags & .WARNING then return 14;	// Yellow
			if flags & .ERROR   then return 12;	// Red

			return 7;
		}
		
		// @Robustness (stefan): Win32 only!!!
		out := GetStdHandle (-11);	// STD_OUTPUT_HANDLE = -11
		SetConsoleTextAttribute (out, flags_to_color (info.common_flags));
		write_string (message);
		SetConsoleTextAttribute (out, 7);	// Gray (default)
	}
}
else #if OS == .LINUX
{
	console_logger :: (message : string, data : *void, info : Log_Info)
	{
		write (STDOUT_FILENO, message.data, xx message.count);
	}
}

log_message :: (fmt : string, args : ..Any, info : Log_Info)
{
	if !context.logger then return;

	if context.stack_trace
	{
		message_fmt := format_string (context.allocator, context.allocator_data, "%: %\n", context.stack_trace.next.info.name, fmt);
		defer free (message_fmt, context.allocator, context.allocator_data);
	
		formatted := format_string (context.allocator, context.allocator_data, message_fmt, ..args);
		defer free (formatted, context.allocator, context.allocator_data);

		context.logger (formatted, context.logger_data, info);
	}
	else
	{
		message_fmt := format_string (context.allocator, context.allocator_data, "%\n", context.stack_trace.next.info.name, fmt);
		defer free (message_fmt, context.allocator, context.allocator_data);
	
		formatted := format_string (context.allocator, context.allocator_data, message_fmt, ..args);
		defer free (formatted, context.allocator, context.allocator_data);

		context.logger (formatted, context.logger_data, info);
	}
}

log_trace :: (fmt : string, args : ..Any, location := #caller_location)
{
	info : Log_Info;
	info.location = location;

	inline log_message (fmt, ..args, info);
}

log_content :: (fmt : string, args : ..Any, location := #caller_location)
{
	info : Log_Info;
	info.location = location;
	info.common_flags = Log_Flags.CONTENT;

	inline log_message (fmt, ..args, info);
}

log_warning :: (fmt : string, args : ..Any, location := #caller_location)
{
	info : Log_Info;
	info.location = location;
	info.common_flags = Log_Flags.WARNING;

	inline log_message (fmt, ..args, info);
}

// @Note (stefan): Always returns false, this is useful when erroring
// out of a procedure that returns true on success and false on failure.
log_error :: (fmt : string, args : ..Any, location := #caller_location) -> bool
{
	info : Log_Info;
	info.location = location;
	info.common_flags = Log_Flags.ERROR;

	inline log_message (fmt, ..args, info);

	return false;
}
