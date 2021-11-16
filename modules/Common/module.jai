#scope_module

#import "Math";		// Because printing and reading floats needs this

#if OS == .WINDOWS #import "Win32";
else #if OS == .LINUX #import "POSIX";

#scope_export

#if OS == .WINDOWS #load "win32.jai";
else #if OS == .LINUX #load "linux.jai";
#load "alloc.jai";
#load "array.jai";
#load "string.jai";
#load "string_to.jai";
#load "string_to_float.jai";
#load "string_builder.jai";
#load "print.jai";
#load "logging.jai";
#load "time.jai";

f32 :: float32;
f64 :: float64;

make_default_context :: () -> Context #c_call
{
	result : Context;
	result.allocator = heap_allocator;
	result.logger    = console_logger;

	return result;
}

get_command_line_arguments :: () -> []string #must
{
	c_args := __command_line_arguments;
	result := alloc_array (string, c_args.count, heap_allocator);
	for c_args
	{
		result[it_index].data  = it;
		result[it_index].count = cstring_length (it);
	}

	return result;
}

enum_count :: ($T : Type) -> int #must
{
	info := type_info (T);
	assert (info.type == .ENUM, "Called enum_count for a non enum type.");
	info_enum := cast (*Type_Info_Enum) info;
	count := info_enum.names.count;
	if info_enum.names[count - 1] == "COUNT" then count -= 1;	// Sometimes, we define a COUNT enum value. Don't count it.

	return count;
}

enum_value :: ($T : Type, name : string) -> T #must
{
	info := type_info (T);
	assert (info.type == .ENUM, "Called enum_value for a non enum type.");
	info_enum := cast (*Type_Info_Enum) info;
	for it, i : info_enum.names
	{
		if name == it then return cast (T) info_enum.values[i];
	}

	return cast (T) 0;
}

enum_next :: (value : $T) -> T #must
{
	info := type_info (T);
	assert (info.type ==.ENUM, "Called enum_next for a non enum type.");
	info_enum := cast (*Type_Info_Enum) info;
	value_index := find_first_occurence (info_enum.values, cast (s64) value);
	value_index = wrap (value_index + 1, info_enum.values.count);
	
	return cast (T) info_enum.values[value_index];
}

assert :: inline (assertion : bool, fmt := "", args : ..Any, location := #caller_location)
{
	if !assertion
	{
		// Prevent assert ()->...->assert ()->...->assert ()->...->assert () infinite loop (format_string might assert for example)
		if context.handling_assertion_failure then return;
		context.handling_assertion_failure = true;
		context.assertion_failed (location, format_string (temp_allocator, fmt, ..args));
		context.handling_assertion_failure = false;
	}
}

initialize_any :: (item : Any)
{
	if item.type.type == .STRUCT
	{
		info_struct := cast (*Type_Info_Struct) item.type;
		info_struct.initializer (item.value_pointer);
	}
	else
	{
		memset (item.value_pointer, 0, item.type.runtime_size);
	}
}

initialize_item :: (ptr : *$T)
{
	init :: initializer_of (T);

#if init
{
	inline init (ptr);
}
else
{
	memset (ptr, 0, size_of (T));
}
}

shallow_copy :: (dest : Any, src : Any)
{
	assert (dest.type == src.type, "Cannot shallow copy two elements of different types.");
	assert (dest.value_pointer != null, "Cannot shallow copy: dest is null.");
	assert (src.value_pointer != null, "Cannot shallow copy: src is null.");

	memcpy (dest.value_pointer, src.value_pointer, dest.type.runtime_size);
}

shallow_clone :: (src : Any, allocator : Allocator, allocator_data := null) -> Any #must
{
	assert (src.value_pointer != null, "Cannot shallow clone: src is null.");

	dest : Any;
	dest.type = src.type;
	dest.value_pointer = alloc (dest.type.runtime_size, allocator, allocator_data);
	memcpy (dest.value_pointer, src.value_pointer, dest.type.runtime_size);

	return dest;
}

offset_of :: inline ($T : Type, $member : string) -> s64 #must
{
	#insert #run format_string (heap_allocator, BODY, member);

	BODY :: #string END
		dummy : T = ---;
		
		return cast (*void) (*dummy.%) - cast (*void) *dummy;
	END
}

#if OS == .WINDOWS
{
#scope_file
	kernel32 :: #foreign_system_library "Kernel32";
	Sleep :: (milliseconds : u32) #foreign kernel32;
#scope_export
	sleep :: Sleep;
}
