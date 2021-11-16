#import "Common";	// For assert, but Common imports us too!

relative_to_absolute_pointer :: (size : s64, relative_ptr : *void) -> pointer : *void, offset : int
{
	offset := 0;
	if size ==
	{
	case 1;
		ival := <<cast (*s8) relative_ptr;
		if ival then offset = ival ^ 0x80;
		else return null, 0;
		
	case 2;
		ival := <<cast (*s16) relative_ptr;
		if ival then offset = ival ^ 0x8000;
		else return null, 0;

	case 4;
		ival := <<cast (*s32) relative_ptr;
		if ival then offset = ival ^ 0x8000_0000;
		else return null, 0;

	case 8;
		ival := <<cast (*s64) relative_ptr;
		if ival then offset = ival ^ 0x8000_0000_0000_0000;
		else return null, 0;

	case;
		assert (false, "Invalid relative pointer size.");
	}

	ptr := cast (*u8) relative_ptr + offset;

	return ptr, offset;
}

any_sized_int_to_s64 :: (size : s64, ptr : *void) -> s64
{
	if size ==
	{
	case 1; return xx <<cast (*s8)  ptr;
	case 2; return xx <<cast (*s16) ptr;
	case 4; return xx <<cast (*s32) ptr;
	case 8; return xx <<cast (*s64) ptr;
	}

	assert (false, "Invalid integer size.");
}

any_sized_uint_to_u64 :: (size : s64, ptr : *void) -> u64
{
	if size ==
	{
	case 1; return xx <<cast (*u8)  ptr;
	case 2; return xx <<cast (*u16) ptr;
	case 4; return xx <<cast (*u32) ptr;
	case 8; return xx <<cast (*u64) ptr;
	}

	assert (false, "Invalid unsigned integer size.");
}

string_to_enum :: ($T : Type, str : string) -> T, bool
{
	info := type_info (T);
	assert (info.type == .ENUM);
	
	for info.names
	{
		if name == it then return xx info.values[it_index], true;
	}
	
	return xx 0, false;
}

enum_to_string :: (val : $T) -> string
{
	info := type_info (T);
	
	return inline enum_to_string (info);
}

enum_to_string :: (info : *Type_Info_Enum) -> string
{
	assert (info.type == .ENUM);
	
	for info.values
	{
		if it == xx val then return info.names[it_index];
	}
	
	return "";
}

any_to_s64 :: (item : Any) -> s64
{
	assert (item.type.type == .INTEGER);
	info_integer := cast (*Type_Info_Integer) item.type;

	if info_integer.signed
		return any_sized_int_to_s64 (info_integer.runtime_size, item.value_pointer);
	else
		return xx any_sized_uint_to_u64 (info_integer.runtime_size, item.value_pointer);
}

any_to_string :: (item : Any) -> string
{
	assert (item.type.type == .STRING);
	
	info_string := cast (*Type_Info_String) item.type;
	str : string = ---;
	if !info_string.relative_pointer_size
	{
		str = <<cast (*string) item.value_pointer;
	}
	else
	{
		ptr_size := info_string.relative_pointer_size;
		str.count = any_sized_int_to_s64 (ptr_size, item.value_pointer);
		str.data  = relative_to_absolute_pointer (ptr_size, cast (*u8) item.value_pointer + ptr_size);
	}

	return str;
}

get_array_count_and_data :: (item : Any) -> s64, *void
{
	info_array := cast (*Type_Info_Array) item.type;
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

	return count, data;
}

get_struct_member :: (item : Any, name : string) -> Any
{
	assert (item.type.type == .STRUCT);

	info_struct := cast (*Type_Info_Struct) item.type;
	result : Any;
	for member : info_struct.members
	{
		if member.name == name
		{
			result.type = member.type;
			result.value_pointer = item.value_pointer + member.offset_in_bytes;

			break;
		}
	}

	return result;
}

get_struct_member_info :: (info : *Type_Info_Struct, name : string) -> *Type_Info_Struct_Member
{
	assert (info.type == .STRUCT);

	for * member : info.members
	{
		if member.name == name then return member;
	}

	return null;
}

set_string :: inline (item : Any, str : string)
{
	assert (item.type.type == .STRING);
	info_str := cast (*Type_Info_String) item.type;
	// @Incomplete (stefan): Handle relative pointers.
	assert (info_str.relative_pointer == 0);
	<<cast (*s64) item.value_pointer = str.count;
	<<cast (**u8) item.value_pointer + 8 = str.data;
}

set_int :: inline (item : Any, val : s64)
{
	assert (item.type.type == .INTEGER);
	info_int := cast (*Type_Info_Integer) item.type;
	assert (info_int.signed);
	if item.type.runtime_size ==
	{
	case 1; <<cast (*s8)  item.value_pointer = cast, no_check (s8)  val;
	case 2; <<cast (*s16) item.value_pointer = cast, no_check (s16) val;
	case 4; <<cast (*s32) item.value_pointer = cast, no_check (s32) val;
	case 8; <<cast (*s64) item.value_pointer = cast, no_check (s64) val;
	}
}

set_uint :: inline (item : Any, val : u64)
{
	assert (item.type.type == .INTEGER);
	info_int := cast (*Type_Info_Integer) item.type;
	assert (!info_int.signed);
	if item.type.runtime_size ==
	{
	case 1; <<cast (*u8)  item.value_pointer = cast, no_check (u8)  val;
	case 2; <<cast (*u16) item.value_pointer = cast, no_check (u16) val;
	case 4; <<cast (*u32) item.value_pointer = cast, no_check (u32) val;
	case 8; <<cast (*u64) item.value_pointer = cast, no_check (u64) val;
	}
}

set_float :: inline (item : Any, val : f64)
{
	assert (item.type.type == .FLOAT);
	if item.type.runtime_size ==
	{
	case 4; <<cast (*f32) item.value_pointer = xx val;
	case 8; <<cast (*f64) item.value_pointer = xx val;
	}
}

set_bool :: inline (item : Any, val : bool)
{
	assert (item.type.type == .BOOL);
	<<cast (*bool) item.value_pointer = val;
}
