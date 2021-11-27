#scope_file

#import "Introspection";

custom_print_procs : [..]Print_Proc_Info;

find_print_procedure :: (info : *Type_Info) -> proc : Print_Proc #must
{
	for custom_print_procs
	{
		if cast (*Type_Info) it.type == info then return it.proc;
	}

	return null;
}

Print_Proc_Info :: struct
{
	type : Type;
	proc : Print_Proc;
}

#scope_export

Print_Proc :: #type (builder : *String_Builder, item : Any, format : string);

add_print_procedure :: ($T : Type, proc : Print_Proc) -> bool
{
	if !custom_print_procs.allocator.proc then custom_print_procs.allocator = HEAP;
	
	info := type_info (T);
	if info.type != .STRUCT then return false;

	print_proc_info : Print_Proc_Info = ---;
	print_proc_info.type = T;
	print_proc_info.proc = proc;
	print_proc := find_print_procedure (info);

	if !print_proc
	{
		push_to_array (*custom_print_procs, print_proc_info);

		return true;
	}

	return false;
}

cprint :: (str : *u8) #c_call
{
	length  : u32 = 0;
	written : u32 = 0;
	while str[length]
		length += 1;
	
	out := GetStdHandle (-11);	// STD_OUTPUT_HANDLE = -11
	WriteFile (out, str, length, *length, null);
}

cprintln :: (str : *u8) #c_call
{
	cprint (str);
	cprint ("\n");
}

print :: (fmt : string, args : ..Any)
{
	formatted := format_string (HEAP, fmt, ..args);	// @Note (stefan): I've had problems with the temporary storage overflowing when printing a lot
	defer free (formatted, HEAP);
	write_string (formatted);
}

println :: (fmt : string, args : ..Any)
{
	inline print (fmt, ..args);
	inline print ("\n");
}

print :: (val : Any)
{
	inline print ("%", val);
}

println :: (val : Any)
{
	inline println ("%", val);
}

fstring :: format_string;	// Had the idea to use this name because format_string is quite long
format_string :: (allocator : Allocator, fmt : string, args : ..Any) -> string #must
{
	//if args.count == 0 then return clone_string (fmt, allocator);

	builder := make_string_builder (fmt.count + 128, allocator);
	print_to_builder (*builder, fmt, ..args);

	return builder_to_string (builder);
}

fcstring :: format_string_to_cstring;
format_string_to_cstring :: (allocator : Allocator, fmt : string, args : ..Any) -> *u8 #must
{
	builder := make_string_builder (fmt.count + 128, allocator);
	print_to_builder (*builder, fmt, ..args);

	return builder_to_cstring (*builder);
}

print_char_to_builder :: (builder : *String_Builder, char : u8)
{
	inline push_into_array (builder, char);
}

print_escaped_char_to_builder :: (builder : *String_Builder, char : u8)
{
	if char ==
	{
	case #char "\r";
		print_string_to_builder (builder, "\\r");

	case #char "\n";
		print_string_to_builder (builder, "\\n");

	case #char "\t";
		print_string_to_builder (builder, "\\t");

	case #char "\"";
		print_string_to_builder (builder, "\\\"");

	case #char "\\";
		print_string_to_builder (builder, "\\\\");

	case;
		print_char_to_builder (builder, char);
	}
}

print_string_to_builder :: (builder : *String_Builder, str : string)
{
	if builder.count + str.count > builder.allocated then resize_string_builder (builder, builder.count + str.count + 128);
	memcpy (builder.data + builder.count, str.data, str.count);
	builder.count += str.count;
}

print_cstring_to_builder :: (builder : *String_Builder, cstr : *u8)
{
	str : string;
	str.data  = cstr;
	str.count = cstring_length (cstr);
	inline print_string_to_builder (builder, str);
}

print_escaped_string_to_builder :: (builder : *String_Builder, str : string)
{
	if builder.count + str.count > builder.allocated then resize_string_builder (builder, builder.count + str.count + 128);

	print_char_to_builder (builder, #char "\"");
	for i : 0..str.count - 1
		print_escaped_char_to_builder (builder, str[i]);
	print_char_to_builder (builder, #char "\"");
}

Int_Format :: struct
{
	base := 10;
}

parse_int_formatting_string :: (format : string) -> Int_Format #must, format_was_valid : bool
{
	str := format;
	int_format : Int_Format;
	if str.count == 0 then return int_format, false;

	format_was_valid := true;
	if str == "0b" then int_format.base = 2;
	if str == "0o" then int_format.base = 8;
	if str == "0x" then int_format.base = 16;

	return int_format, format_was_valid;
}

print_s64_to_builder :: (builder : *String_Builder, value : s64, base := 10, print_base_prefix := false, min_digits := 1)
{
	if value < 0
	{
		value = -value;
		print_char_to_builder (builder, #char "-");
	}

	inline print_u64_to_builder (builder, cast (u64) value, base, print_base_prefix, min_digits);
}

print_u64_to_builder :: (builder : *String_Builder, value : u64, base := 10, print_base_prefix := false, min_digits := 1)
{
	assert (base > 1 && base <= 16, "Invalid base (got %, expected base in [2, 16]).", base);

	if print_base_prefix
	{
		if base ==
		{
		case 2;  print_string_to_builder (builder, "0b");
		case 8;  print_string_to_builder (builder, "0o");
		case 10;
		case 16; print_string_to_builder (builder, "0x");
		case;
			print_char_to_builder (builder, #char "b");
			print_u64_to_builder (builder, xx base);
			print_char_to_builder (builder, #char "_");
		}
	}

	dummy_value := value;
	digit_count := 0;
	if dummy_value == 0 then digit_count = 1;
	while dummy_value
	{
		digit_count += 1;
		dummy_value /= (xx base);
	}

	// The minimum base we can have is 2, and for a 64 bit number we can at most print 64 digits
	character_buffer : [64]u8 = ---;
	for i : 0..digit_count - 1
	{
		digit := value % (xx base);
		character_buffer[digit_count - 1 - i] = digit_to_char (xx digit, base);
		value /= xx base;
	}

	for i : 0..digit_count - 1  print_char_to_builder (builder, character_buffer[i]);
}

#scope_file

#import "stb_sprintf";

#scope_export

Float_Format :: struct
{
	digits_after_decimal := -1;
}

parse_float_formatting_string :: (format : string) -> Float_Format #must, format_was_valid : bool
{
	str := format;
	float_format : Float_Format;
	if str.count == 0 then return float_format, false;

	format_was_valid := true;
	if str[0] == #char "."
	{
		str = advance (str);
		digits, str, ok := string_to_u64 (str);
		float_format.digits_after_decimal = xx digits;
		if !ok then format_was_valid = false;
	}

	return float_format, format_was_valid;
}

print_f32_to_builder :: (builder : *String_Builder, value : f32, digits_after_decimal : int)
{
	inline print_f64_to_builder (builder, xx value, digits_after_decimal);
}

print_f64_to_builder :: (builder : *String_Builder, value : f64, digits_after_decimal : int)
{
	buffer : [100]u8;
	fmt : *u8;
	if digits_after_decimal != -1 then fmt = format_string_to_cstring (TEMP, "%%.%f", digits_after_decimal);
	else fmt = "%f";
	stbsp_snprintf (buffer.data, buffer.count, fmt, value);
	print_cstring_to_builder (builder, buffer.data);
}

print_bool_to_builder :: (builder : *String_Builder, value : bool)
{
	if value then print_string_to_builder (builder, "true");
	else          print_string_to_builder (builder, "false");
}

print_pointer_to_builder :: (builder : *String_Builder, value : *void)
{
	if value then print_u64_to_builder (builder, cast (u64) value, base = 16);
	else          print_string_to_builder (builder, "null");
}

print_type_to_builder :: (builder : *String_Builder, info : *Type_Info, $compilable := true)
{
	if info.type ==
	{
	case .STRUCT;
		info_struct := cast (*Type_Info_Struct) info;

		if info_struct.name
		{
			print_string_to_builder (builder, info_struct.name);
		}
		else
		{
			if info_struct.struct_flags & .UNION
			{
				// @Todo (stefan): Print union { member : type; member : type; ... } when $compilable = true
				assert (!compilable, "Printing an anonymous union type with $compilable = true. This is not yet handled.");
				print_string_to_builder (builder, "(anonymous union)");
			}
			else
			{
				// @Todo (stefan): Print struct { member : type; member : type; ... } when $compilable = true
				assert (!compilable, "Printing an anonymous struct type with $compilable = true. This is not yet handled.");
				print_string_to_builder (builder, "(anonymous struct)");
			}
		}

		if info_struct.polymorph_source_struct
		{
			print_string_to_builder (builder, " (");
			for * param : info_struct.specified_parameters
			{
				if it_index != 0 then print_string_to_builder (builder, ", ");
				print_string_to_builder (builder, param.name);

				if param.offset_into_constant_storage >= 0
				{
					print_string_to_builder (builder, " = ");
					param_value : Any;
					param_value.type = param.type;
					param_value.value_pointer = info_struct.constant_storage_buffer + param.offset_into_constant_storage;
					print_item_to_builder (builder, param_value, "");
				}
			}
			print_string_to_builder (builder, ")");
		}

	case .POINTER;
		info_pointer := cast (*Type_Info_Pointer) info;
		print_string_to_builder (builder, "*");
		if info_pointer.relative_pointer_size ==
		{
		case 1; print_string_to_builder (builder, "~s8");
		case 2; print_string_to_builder (builder, "~s16");
		case 4; print_string_to_builder (builder, "~s32");
		case 8; print_string_to_builder (builder, "~s64");
		}
		print_type_to_builder (builder, info_pointer.pointer_to, compilable);

	case .ARRAY;
		info_array := cast (*Type_Info_Array) info;
		if info_array.array_type ==
		{
		case .FIXED;     print_to_builder (builder, "[%]", info_array.array_count);
		case .VIEW;      print_to_builder (builder, "[]");
		case .RESIZABLE; print_to_builder (builder, "[..]");
		}
		
		print_type_to_builder (builder, info_array.element_type, compilable);

	case .TYPE;
		print_string_to_builder (builder, "Type");

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		if info_enum.name
		{
			print_string_to_builder (builder, info_enum.name);
		}
		else
		{
			assert (!compilable, "Printing an anonymous enum type with $compilable = true. This is not allowed.");
			print_string_to_builder (builder, "(anonymous enum)");
		}

	case .STRING;
		info_string := cast (*Type_Info_String) info;
		print_string_to_builder (builder, "string");
		if info_string.relative_pointer_size ==
		{
		case 1; print_string_to_builder (builder, "~s8");
		case 2; print_string_to_builder (builder, "~s16");
		case 4; print_string_to_builder (builder, "~s32");
		case 8; print_string_to_builder (builder, "~s64");
		}

	case .PROCEDURE;
		info_procedure := cast (*Type_Info_Procedure) info;
		#if !compilable print_string_to_builder (builder, "procedure ");
		print_string_to_builder (builder, "(");
		for info_procedure.argument_types
		{
			if it_index != 0 then print_string_to_builder (builder, ", ");
			print_type_to_builder (builder, it, compilable);
		}
		print_string_to_builder (builder, ")");

		if info_procedure.return_types
		{
			print_string_to_builder (builder, " -> ");
			if info_procedure.return_types.count > 1 then print_string_to_builder (builder, "(");
			for info_procedure.return_types
			{
				if it_index != 0 then print_string_to_builder (builder, ", ");
				print_type_to_builder (builder, it, compilable);
			}
			if info_procedure.return_types.count > 1 then print_string_to_builder (builder, ")");
		}

		proc_flags := info_procedure.procedure_flags;
		if proc_flags & .IS_ELSEWHERE    then print_string_to_builder (builder, " #elsewhere");
		if proc_flags & .IS_COMPILE_TIME then print_string_to_builder (builder, " #compiler");
		if proc_flags & .IS_C_CALL       then print_string_to_builder (builder, " #c_call");
		if proc_flags & .IS_INTRINSIC    then print_string_to_builder (builder, " #intrinsic");

	case .CODE;
		print_string_to_builder (builder, "Code");

	case .INTEGER;
		info_integer := cast (*Type_Info_Integer) info;
		if info_integer.runtime_size ==
		{
		case 1; print_string_to_builder (builder, ifx info_integer.signed then "s8"  else "u8");
		case 2; print_string_to_builder (builder, ifx info_integer.signed then "s16" else "u16");
		case 4; print_string_to_builder (builder, ifx info_integer.signed then "s32" else "u32");
		case 8; print_string_to_builder (builder, ifx info_integer.signed then "s64" else "u64");
		}

	case .FLOAT;
		if info.runtime_size == 
		{
		case 4; print_string_to_builder (builder, "f32");
		case 8; print_string_to_builder (builder, "f64");
		}

	case .BOOL;
		print_string_to_builder (builder, "bool");

	case .VOID;
		print_string_to_builder (builder, "void");

	case .VARIANT;
		info_variant := cast (*Type_Info_Variant) info;
		print_string_to_builder (builder, info_variant.name);

	case;
		assert (!compilable, "Printing an unhandled type (%) with $compilable = true. This is not allowed.", info.type);
		print_string_to_builder (builder, "(unhandled type)");
	}
}

print_item_to_builder :: (builder : *String_Builder, item : Any, format := "")
{
	info := item.type;

	if info.type ==
	{
	case .STRING;
		print_string_to_builder (builder, any_to_string (item));

	case .BOOL;
		print_bool_to_builder (builder, <<cast (*bool) item.value_pointer);

	case .INTEGER;
		info_integer := cast (*Type_Info_Integer) info;
		int_format := parse_int_formatting_string (format);
		if info_integer.signed then print_s64_to_builder (builder, any_sized_int_to_s64 (info_integer.runtime_size, item.value_pointer),  int_format.base);
		else                        print_u64_to_builder (builder, any_sized_uint_to_u64 (info_integer.runtime_size, item.value_pointer), int_format.base);

	case .FLOAT;
		info_float := cast (*Type_Info_Float) info;
		float_format := parse_float_formatting_string (format);
		if info_float.runtime_size ==
		{
		case 4; print_f64_to_builder (builder, xx <<cast (*f32) item.value_pointer, float_format.digits_after_decimal);
		case 8; print_f64_to_builder (builder, xx <<cast (*f64) item.value_pointer, float_format.digits_after_decimal);
		}

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		info_integer := cast (*Type_Info_Integer) info_enum.internal_type;
		enum_value := 0;
		if info_integer.signed then enum_value = any_sized_int_to_s64 (info_integer.runtime_size, item.value_pointer);
		else                        enum_value = xx any_sized_uint_to_u64 (info_integer.runtime_size, item.value_pointer);

		if info_enum.enum_type_flags & .FLAGS
		{
			flags_value := cast (u64) enum_value;
			flags_printed : u64;
			first := true;
			for info_enum.values
			{
				value := cast (u64) it;
				flag := flags_value & value;
				if flag != value then flag = 0;
				if flag == 0 then continue;
				if !(flag & ~flags_printed) then continue;
				flags_printed |= flag;

				if !first then print_string_to_builder (builder, " | ");
				print_string_to_builder (builder, info_enum.names[it_index]);
				first = false;
			}

			out_of_range := flags_value & ~flags_printed;
			if out_of_range != 0
			{
				if !first then print_string_to_builder (builder, " | ");
				print_u64_to_builder (builder, out_of_range, base = 16, print_base_prefix = true);
			}
		}
		else
		{
			index := -1;
			for info_enum.values
			{
				if it == enum_value
				{
					index = it_index;

					break;
				}
			}

			if index == -1
			{
				print_string_to_builder (builder, info_enum.name);
				print_string_to_builder (builder, ", OoR (");
				print_s64_to_builder (builder, xx enum_value);
				print_string_to_builder (builder, ")");
			}
			else
			{
				print_string_to_builder (builder, info_enum.names[index]);
			}
		}

	case .POINTER;
		info_pointer := cast (*Type_Info_Pointer) info;

		// @Todo (stefan): Print the pointed type ?
		if info_pointer.relative_pointer_size
		{
			absolute_pointer, offset := relative_to_absolute_pointer (info_pointer.relative_pointer_size, item.value_pointer);
			if absolute_pointer
			{
				print_string_to_builder (builder, "~");
				print_s64_to_builder (builder, offset);
				print_string_to_builder (builder, " (");
				print_u64_to_builder (builder, cast (u64) absolute_pointer, base = 16);
				print_string_to_builder (builder, ")");
			}
			else
			{
				print_string_to_builder (builder, "~null");
			}
		}
		else
		{
			ptr := <<cast (**void) item.value_pointer;
			print_pointer_to_builder (builder, ptr);
		}

	case .VOID;
		print_string_to_builder (builder, "void");

	case .CODE;
		print_string_to_builder (builder, "Code");

	case .PROCEDURE;
		val := <<cast (**void) item.value_pointer;
		print_string_to_builder (builder, "procedure ");
		print_pointer_to_builder (builder, val);

	case .OVERLOAD_SET;
		print_string_to_builder (builder, "(procedure overloads)");

	case .TYPE;
		type_value := <<cast (**Type_Info) item.value_pointer;
		if type_value then print_type_to_builder (builder, type_value);
		else               print_string_to_builder (builder, "Type (null)");

	case .ARRAY;
		info_array := cast (*Type_Info_Array) info;
		print_type_to_builder (builder, info_array.element_type);
		print_string_to_builder (builder, ".[");

		count : s64;
		data  : *void;
		if info_array.array_type == .FIXED
		{
			count = info_array.array_count;
			data  = item.value_pointer;
		}
		else
		{
			if info_array.relative_pointer_size
			{
				size := info_array.relative_pointer_size;
				count = any_sized_int_to_s64 (size, item.value_pointer);
				data  = relative_to_absolute_pointer (size, item.value_pointer + size);
			}
			else
			{
				count = <<cast (*s64) item.value_pointer;
				data  = <<cast (**void) (item.value_pointer + 8);
			}
		}

		for i : 0..count - 1
		{
			curr : Any = ---;
			curr.type          = info_array.element_type;
			curr.value_pointer = data + info_array.element_type.runtime_size * i;
			print_string_to_builder (builder, " ");
			print_item_to_builder (builder, curr, "");
			if i < count - 1 then print_string_to_builder (builder, ",");
			print_string_to_builder (builder, " ");
		}
		print_string_to_builder (builder, "]");

	case;
		proc := find_print_procedure (info);
		if proc
		{
			proc (builder, item, format);
		}
		else
		{
			print_string_to_builder (builder, "(unhandled type)");
		}
	}
}

print_to_builder :: (builder : *String_Builder, fmt : string, args : ..Any)
{
	arg_index := 0;
	cursor := 0;
	printed := 0;
	while cursor < fmt.count
	{
		char := fmt[cursor];
		if arg_index == args.count || char != #char "%"
		{
			cursor += 1;

			continue;
		}

		str_to_print : string;
		str_to_print.data  = fmt.data + printed;
		str_to_print.count = cursor - printed;
		print_string_to_builder (builder, str_to_print); 
		cursor += 1;
		format_string := "";

		if cursor < fmt.count
		{
			next := fmt[cursor];
			// @Incomplete (stefan): When there is no arguments left, this prints '%%' instead of '%'. Fix this.
			if next == #char "%"
			{
				print_char_to_builder (builder, #char "%");
				cursor += 1;
				printed = cursor;

				continue;
			}

			// Read formatting string
			if next == #char "*"
			{
				fmt_cursor := cursor + 1;
				while fmt_cursor < fmt.count
				{
					current := fmt[fmt_cursor];
					if fmt_cursor == cursor + 1 && current == #char "*"
					{
						cursor += 1;

						break;
					}

					if current == #char "*"
					{
						format_string.data  = fmt.data + cursor + 1;
						format_string.count = fmt_cursor - cursor - 1;
						cursor = fmt_cursor + 1;

						break;
					}

					fmt_cursor += 1;
				}
			}
		}

		print_item_to_builder (builder, args[arg_index], format_string);
		arg_index += 1;
		printed = cursor;
	}

	str_to_print : string;
	str_to_print.data  = fmt.data + printed;
	str_to_print.count = cursor - printed;
	print_string_to_builder (builder, str_to_print);
}

print_newline_to_builder :: (builder : *String_Builder)
{
	inline print_char_to_builder (builder, #char "\n");
}

print_line_to_builder :: (builder : *String_Builder, str : string)
{
	inline print_string_to_builder (builder, str);
	inline print_char_to_builder (builder, #char "\n");
}

print_line_to_builder :: (builder : *String_Builder, fmt : string, args : ..Any)
{
	inline print_to_builder (builder, fmt, ..args);
	inline print_char_to_builder (builder, #char "\n");
}

print_indentation_to_builder :: inline (builder : *String_Builder, level : int, str := "\t")
{
	for 0..level - 1
		print_string_to_builder (builder, str);
}
