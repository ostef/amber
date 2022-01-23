// @Todo (stefan): Better error reporting and handling.

Config_Key_Value :: struct
{
	key : string;
	val : Config_Var;
}

Config_Var :: struct
{
	Kind :: enum
	{
		BOOL   :: 0;
		INT    :: 1;
		UINT   :: 2;
		FLOAT  :: 3;
		STRING :: 4;
		ARRAY  :: 5;
		MAP    :: 6;
	}

	kind : Kind;
	union
	{
		as_bool : bool;
		as_s64  : s64;
		as_u64  : u64;
		as_f32  : f32;
		as_string : string;
		as_array : []Config_Var;
		as_map   : []Config_Key_Value;
	};
}

config_variables : Hash_Map (string, Config_Var);

config_get :: (name : string, base : *Config_Var = null) -> *Config_Var #must
{
	if name.count == 0
		return base;

	if base
	{
		if base.kind != .ARRAY && base.kind != .MAP
			return null;
		subscript := name;
		if subscript[0] != #char "["
			return null;
		subscript = advance (subscript);
		for i : 0..subscript.count - 1
		{
			if subscript[i] == #char "]"
			{
				subscript.count = i;

				break;
			}
		}
		if subscript.count == 0
			return null;
		remaining := advance (name, cast (s64) (subscript.data - name.data) + subscript.count);
		if subscript[0] == #char "\""
		{
			if base.kind != .MAP || subscript.count < 2 || subscript[subscript.count - 1] != #char "\""
				return null;
			subscript = advance (subscript);
			subscript.count -= 1;
			for * base.as_map
			{
				if it.key == subscript
					return config_get (remaining, *it.val);
			}

			return null;
		}
		else
		{
			if base.kind != .ARRAY
				return null;
			index, ok := string_to_u64 (subscript);
			if !ok
				return null;
			for * base.as_array
				return config_get (remaining, it);

			return null;
		}
	}
	else
	{
		basename := name;
		for i : 0..basename.count - 1
		{
			if basename[i] == #char "["
			{
				basename.count = i;

				break;
			}
		}
		var := get_pointer (*config_variables, basename);
		if !var
			return null;

		return config_get (advance (name, basename.count), var);
	}
}

config_get_bool :: inline (name : string, fallback : bool = false) -> val : bool, ok : bool
{
	var := config_get (name);
	if !var || var.kind != .BOOL
		return fallback, false;

	return var.as_bool, true;
}
@Amber_API

config_get_int :: inline (name : string, fallback : s64 = 0) -> val : s64, ok : bool
{
	var := config_get (name);
	if !var || var.kind != .INT
		return fallback, false;

	return var.as_s64, true;
}
@Amber_API

config_get_uint :: inline (name : string, fallback : u64 = 0) -> val : u64, ok : bool
{
	var := config_get (name);
	if !var || var.kind != .UINT
		return fallback, false;

	return var.as_u64, true;
}
@Amber_API

config_get_float :: inline (name : string, fallback := 0.0) -> val : f32, ok : bool
{
	var := config_get (name);
	if !var || var.kind != .FLOAT
		return fallback, false;

	return var.as_f32, true;
}
@Amber_API

config_get_string :: inline (name : string, fallback := "") -> val : string, ok : bool
{
	var := config_get (name);
	if !var || var.kind != .STRING
		return fallback, false;

	return var.as_string, true;
}
@Amber_API

config_get_string_array :: inline (name : string, allocator : Allocator) -> val : []string, ok : bool
{
	var := config_get (name);
	if !var || var.kind != .ARRAY
		return .[], false;

	result : []string;
	result.data = alloc (size_of (string) * var.as_array.count, allocator);
	for var.as_array
	{
		if it.kind == .STRING
		{
			result.data[result.count] = it.as_string;
			result.count += 1;
		}
	}

	return result, true;
}
@Amber_API

config_get_string_map :: inline (name : string, allocator : Allocator) -> val : Hash_Map (string, string), ok : bool
{
	result : Hash_Map (string, string);
	result.allocator = allocator;

	var := config_get (name);
	if !var || var.kind != .MAP
		return result, false;

	init_map (*result, var.as_map.count, allocator);
	for var.as_map
	{
		if it.val.kind == .STRING
			insert_into_map (*result, it.key, it.val.as_string);
	}

	return result, true;
}
@Amber_API

parse_binding :: (binding : string) -> Mods, Key_Code, bool
{
	str := binding;
	mods : Mods;
	while str.count > 0
	{
		if starts_with (str, "CTRL+")
		{
			mods |= .CONTROL;
			str = advance (str, "CTRL+".count);
		}
		else if starts_with (str, "SHIFT+")
		{
			mods |= .SHIFT;
			str = advance (str, "SHIFT+".count);
		}
		else if starts_with (str, "ALT+")
		{
			mods |= .ALT;
			str = advance (str, "ALT+".count);
		}
		else
		{
			info_enum := type_info (Key_Code);
			for info_enum.names
			{
				if str == it
					return mods, cast (Key_Code) info_enum.values[it_index], true;
			}
			return .NONE, .UNKNOWN, false;
		}
	}

	return .NONE, .UNKNOWN, false;
}

Config_Parser :: struct
{
	filename : string;
	start, curr, end : *u8;
	line, column : s64;
	errors : [..]Config_Error;
	root : Config_Root;
	assignments : Bucket_Array (Config_Assignment, 20);
	lvalues     : Bucket_Array (Config_LValue, 20);
	rvalues     : Bucket_Array (Config_RValue, 20);
	array_literals : Bucket_Array (Config_Array_Literal, 20);
	map_literals   : Bucket_Array (Config_Map_Literal, 20);
}

Config_Error :: struct
{
	start : *u8;
	line, column : s64;
	str : string;
}

Config_Root :: struct
{
	assignments : [..]*Config_Assignment;
}

Config_Assignment :: struct
{
	lvalue : *Config_LValue;
	rvalue : *Config_RValue;
}

Config_RValue :: struct
{
	kind : Config_Var.Kind;
	union
	{
		bool_value : bool;
		int_value  : s64;
		uint_value : u64;
		float_value : f32;
		string_value : string;
		array_literal : *Config_Array_Literal;
		map_literal   : *Config_Map_Literal;
	};
}

Config_LValue :: struct
{
	identifier : string;
}

Config_Array_Literal :: struct
{
	elems : []*Config_RValue;
}

Config_Map_Literal :: struct
{
	Key_Value :: struct
	{
		key : string;
		val : *Config_RValue;
	}

	elems : []Key_Value;
}

config_parser_init :: inline (parser : *Config_Parser, filename : string, file_contents : string)
{
	parser.filename = filename;
	parser.start = file_contents.data;
	parser.curr = file_contents.data;
	parser.end = file_contents.data + file_contents.count;
	parser.line = 1;
	parser.column = 1;
	init_array (*parser.root.assignments, 50, HEAP);
	init_array (*parser.errors, 50, HEAP);
	init_bucket_array (*parser.assignments, 50, HEAP);
	init_bucket_array (*parser.lvalues, 200, HEAP);
	init_bucket_array (*parser.rvalues, 200, HEAP);
	init_bucket_array (*parser.array_literals, 50, HEAP);
	init_bucket_array (*parser.map_literals, 50, HEAP);
}

config_parser_destroy :: inline (parser : *Config_Parser)
{
	reset_array (*parser.root.assignments);
	reset_array (*parser.errors);
	reset_bucket_array (*parser.assignments);
	reset_bucket_array (*parser.lvalues);
	/*
	for * parser.rvalues
	{
		if it.kind == .STRING
			free (it.string_value.data, HEAP);
	}
	*/
	reset_bucket_array (*parser.rvalues);
	for * parser.array_literals
		free (it.elems, HEAP);
	reset_bucket_array (*parser.array_literals);
	for * parser.map_literals
	{
		for * elem : it.elems
			free (elem.key, HEAP);
		free (it.elems, HEAP);
	}
	reset_bucket_array (*parser.map_literals);
	parser.column = 1;
	parser.line = 1;
	parser.end = null;
	parser.curr = null;
	parser.start = null;
	parser.filename = "";
}

config_parser_error :: inline (using parser : *Config_Parser, error_str : string)
{
	println ("Error at line %, column %: %", line, column, error_str);
	error : Config_Error = ---;
	error.start = curr;
	error.line = line;
	error.column = column;
	error.str = error_str;
}

config_parser_recover :: inline (using parser : *Config_Parser)
{
	while config_parser_is_valid (parser) && !config_parser_match_string (parser, ";")
		config_parser_advance (parser);
}

config_parser_is_valid :: inline (using parser : *Config_Parser) -> bool
{
	return curr < end;
}

config_parser_get :: inline (using parser : *Config_Parser) -> u8
{
	if curr < end then return <<curr;

	return 0;
}

config_parser_skip_spaces :: inline (using parser : *Config_Parser)
{
	while config_parser_is_valid (parser)
	{
		skipped := false;
		while is_space (config_parser_get (parser))
		{
			config_parser_advance (parser);
			skipped = true;
		}
		if config_parser_match_string (parser, "#")
		{
			skipped = true;
			while config_parser_is_valid (parser) && !config_parser_match_string (parser, "\n")
				config_parser_advance (parser);
		}
		if !skipped then break;
	}
}

config_parser_is_string :: inline (using parser : *Config_Parser, str : string) -> bool
{
	if end - curr < str.count then return false;

	for i : 0..str.count - 1
	{
		if curr[i] != str[i] then return false;
	}

	return true;
}

config_parser_match_string :: inline (using parser : *Config_Parser, str : string) -> bool
{
	if config_parser_is_string (parser, str)
	{
		config_parser_advance (parser, str.count);

		return true;
	}

	return false;
}

config_parser_advance :: inline (using parser : *Config_Parser, count := 1)
{
	i := 0;
	while config_parser_is_valid (parser) && i < count
	{
		if config_parser_get (parser) == #char "\n"
		{
			line += 1;
			column = 0;
		}
		column += 1;
		curr += 1;
		i += 1;
	}
}

config_parse :: (using parser : *Config_Parser)
{
	profile ();

	while config_parser_is_valid (parser)
	{
		assignment := config_parse_assignment (parser);
		if assignment
			push_into_array (*root.assignments, assignment);
		config_parser_skip_spaces (parser);
	}
}

config_parse_assignment :: (using parser : *Config_Parser) -> *Config_Assignment
{
	profile ();

	lvalue := config_parse_lvalue (parser);
	if !lvalue
	{
		config_parser_error (parser, "Expected an l-value for assignment.");
		config_parser_recover (parser);

		return null;
	}
	config_parser_skip_spaces (parser);
	if !config_parser_match_string (parser, "=")
	{
		config_parser_error (parser, "Expected a '=' after l-value for assignment.");
		config_parser_recover (parser);

		return null;
	}
	rvalue := config_parse_rvalue (parser);
	if !rvalue
	{
		config_parser_error (parser, "Expected an r-value after '=' for assignment.");
		config_parser_recover (parser);

		return null;
	}
	config_parser_skip_spaces (parser);
	if !config_parser_match_string (parser, ";")
	{
		config_parser_error (parser, "Expected a ';' at the end of assigment.");
		config_parser_recover (parser);

		return null;
	}

	assignment := add_to_bucket_array (*assignments);
	assignment.lvalue = lvalue;
	assignment.rvalue = rvalue;

	return assignment;
}

config_parse_lvalue :: (using parser : *Config_Parser) -> *Config_LValue
{
	profile ();

	config_parser_skip_spaces (parser);
	identifier, ok := config_parse_identifier (parser);
	if !ok
		return null;

	lvalue := add_to_bucket_array (*lvalues);
	lvalue.identifier = identifier;

	return lvalue;
}

config_parse_rvalue :: (using parser : *Config_Parser) -> *Config_RValue
{
	profile ();

	config_parser_skip_spaces (parser);

	bool_value, bool_ok := config_parse_bool (parser);
	if bool_ok
	{
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .BOOL;
		rvalue.bool_value = bool_value;

		return rvalue;
	}

	uint_value, uint_ok := config_parse_uint (parser);
	if uint_ok
	{
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .UINT;
		rvalue.uint_value = uint_value;

		return rvalue;
	}

	int_value, int_ok := config_parse_int (parser);
	if int_ok
	{
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .INT;
		rvalue.int_value = int_value;

		return rvalue;
	}

	string_value, string_ok := config_parse_string (parser);
	if string_ok
	{
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .STRING;
		rvalue.string_value = string_value;

		return rvalue;
	}
	
	float_value, float_ok := config_parse_float (parser);
	if float_ok
	{
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .FLOAT;
		rvalue.float_value = float_value;

		return rvalue;
	}
	
	if config_parser_is_string (parser, "[")
	{
		array_literal := config_parse_array_literal (parser);
		if !array_literal
			return null;
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .ARRAY;
		rvalue.array_literal = array_literal;

		return rvalue;
	}

	if config_parser_is_string (parser, "{")
	{
		map_literal := config_parse_map_literal (parser);
		if !map_literal
			return null;
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .MAP;
		rvalue.map_literal = map_literal;

		return rvalue;
	}
	
	return null;
}

config_parse_int :: inline (using parser : *Config_Parser) -> s64, ok : bool
{
	str : string = ---;
	str.data = curr;
	str.count = end - curr;
	value, ok, remainder := string_to_s64 (str);
	if !ok then return 0, false;
	config_parser_advance (parser, remainder.data - curr);

	return value, ok;
}

config_parse_uint :: inline (using parser : *Config_Parser) -> u64, ok : bool
{
	str : string = ---;
	str.data = curr;
	str.count = end - curr;
	value, ok, remainder := string_to_u64 (str);
	if !ok then return 0, false;
	config_parser_advance (parser, remainder.data - curr);

	return value, ok;
}

config_parse_bool :: inline (using parser : *Config_Parser) -> bool, ok : bool
{
	if config_parser_match_string (parser, "true")
		return true, true;
	if config_parser_match_string (parser, "false")
		return false, true;
	
	return false, false;
}

config_parse_string :: inline (using parser : *Config_Parser) -> string, ok : bool
{
	profile ();

	if !config_parser_match_string (parser, "\"")
		return "", false;
	builder : String_Builder;
	builder.allocator = TEMP;
	while config_parser_is_valid (parser) && !config_parser_is_string (parser, "\"")
	{
		escape := false;
		if config_parser_get (parser) == #char "\\"
		{
			config_parser_advance (parser);
			escape = true;
		}
		if config_parser_get (parser) == #char "\n"
			return "", false;
		if escape
		{
			if config_parser_get (parser) ==
			{
			case #char "n";
				print_char_to_builder (*builder, #char "\n");
			case #char "t";
				print_char_to_builder (*builder, #char "\t");
			}
		}
		else
		{
			print_char_to_builder (*builder, config_parser_get (parser));
		}
		config_parser_advance(parser);
	}
	if !config_parser_match_string (parser, "\"") then return "", false;

	return clone_string (to_string (builder), HEAP), true;
}

config_parse_float :: inline (using parser : *Config_Parser) -> float, ok : bool
{
	return 0.0, false;
}

config_parse_identifier :: inline (using parser : *Config_Parser) -> string, ok : bool
{
	if !is_alpha (config_parser_get (parser)) && config_parser_get (parser) != #char "_"
		return "", false;
	identifier : string = ---;
	identifier.data = curr;
	config_parser_advance (parser);
	while is_alpha_num (config_parser_get (parser))
		config_parser_advance (parser);
	identifier.count = curr - identifier.data;
	
	return identifier, true;
}

config_parse_array_literal :: (using parser : *Config_Parser) -> *Config_Array_Literal
{
	profile ();

	config_parser_skip_spaces (parser);
	if !config_parser_match_string (parser, "[") then return null;
	elems : [..]*Config_RValue;
	elems.allocator = TEMP;
	found_comma := true;
	config_parser_skip_spaces (parser);
	while !config_parser_match_string (parser, "]")
	{
		if !found_comma then return null;
		elem := config_parse_rvalue (parser);
		if !elem then return null;
		push_into_array (*elems, elem);
		config_parser_skip_spaces (parser);
		found_comma = config_parser_match_string (parser, ",");
		config_parser_skip_spaces (parser);
	}

	array_literal := add_to_bucket_array (*array_literals);
	array_literal.elems = clone_array (elems, HEAP);

	return array_literal;
}

config_parse_map_literal :: (using parser : *Config_Parser) -> *Config_Map_Literal
{
	profile ();

	config_parser_skip_spaces (parser);
	if !config_parser_match_string (parser, "{") then return null;
	elems : [..]Config_Map_Literal.Key_Value;
	elems.allocator = TEMP;
	found_comma := true;
	config_parser_skip_spaces (parser);
	while !config_parser_match_string (parser, "}")
	{
		if !found_comma then return null;
		ok : bool;
		elem : Config_Map_Literal.Key_Value = ---;
		elem.key, ok = config_parse_string (parser);
		if !ok then return null;
		config_parser_skip_spaces (parser);
		if !config_parser_match_string (parser, ":")
			return null;
		config_parser_skip_spaces (parser);
		elem.val = config_parse_rvalue (parser);
		if !elem.val then return null;
		push_into_array (*elems, elem);
		config_parser_skip_spaces (parser);
		found_comma = config_parser_match_string (parser, ",");
		config_parser_skip_spaces (parser);
	}

	map_literal := add_to_bucket_array (*map_literals);
	map_literal.elems = clone_array (elems, HEAP);

	return map_literal;
}

config_assign :: (var : *Config_Var, rvalue : *Config_RValue)
{
	var.kind = rvalue.kind;
	if #complete rvalue.kind ==
	{
	case .BOOL;
		var.as_bool = rvalue.bool_value;
	case .INT;
		var.as_s64 = rvalue.int_value;
	case .UINT;
		var.as_u64 = rvalue.uint_value;
	case .FLOAT;
		var.as_f32 = rvalue.float_value;
	case .STRING;
		var.as_string = clone_string (rvalue.string_value, HEAP);
	case .ARRAY;
		var.as_array.count = rvalue.array_literal.elems.count;
		var.as_array.data = alloc (size_of (Config_Var) * var.as_array.count, HEAP);
		for rvalue.array_literal.elems
			config_assign (*var.as_array[it_index], it);
	case .MAP;
		var.as_map.count = rvalue.map_literal.elems.count;
		var.as_map.data = alloc (size_of (Config_Key_Value) * var.as_map.count, HEAP);
		for rvalue.map_literal.elems
		{
			var.as_map[it_index].key = clone_string (it.key, HEAP);
			config_assign (*var.as_map[it_index].val, it.val);
		}
	}
}

config_fill_variables :: inline (using root : *Config_Root)
{
	// @Leak (stefan): Make sure we free all the variables.
	if !config_variables.allocator.proc
		init_map (*config_variables, 100, HEAP);
	clear_map (*config_variables);
	for assignments
	{
		var, was_present := insert_into_map (*config_variables, clone_string (it.lvalue.identifier, HEAP));
		// @Leak (stefan): If was_present is true, we overwrite the variable without freeing it.
		config_assign (var, it.rvalue);
	}
}

/*
config_print_lvalue :: (using lvalue : *Config_LValue)
{
	print (identifier);
	if subscript_index >= 0
		print ("[%]", subscript_index);
	if member_lvalue
	{
		print (".");
		config_print_lvalue (member_lvalue);
	}
}

config_print_rvalue :: (using rvalue : *Config_RValue, indentation_level : int)
{
	if kind ==
	{
	case .LVALUE;
		config_print_lvalue (lvalue);
	case .INT;
		print ("%", int_value);
	case .BOOL;
		print ("%", bool_value);
	case .STRING;
		builder : String_Builder;
		builder.allocator = TEMP;
		print_escaped_string_to_builder (*builder, string_value);
		print (to_string (builder));
	case .COMPOUND;
		config_print_compound (compound, indentation_level);
	}
}

config_print_assignment :: (using assignment : *Config_Assignment)
{
	config_print_lvalue (lvalue);
	print (" = ");
	config_print_rvalue (rvalue, 0);
	println (";");
}

config_print_compound :: (using compound : *Config_Compound, indentation_level : int)
{
	print ("\n");
	for 0..indentation_level - 1
		print ("\t");
	print ("{");
	for elems
	{
		config_print_compound_elem (it, indentation_level + 1);
		print (",");
	}
	print ("\n");
	for 0..indentation_level - 1
		print ("\t");
	print ("}");
}

config_print_compound_elem :: (using elem : *Config_Compound_Elem, indentation_level : int)
{
	print ("\n");
	for 0..indentation_level - 1
		print ("\t");
	if specifier.kind ==
	{
	case .IDENTIFIER;
		print (".% = ", specifier.identifier);
	case .INDEX;
		print (".% = ", specifier.index);
	}
	config_print_rvalue (rvalue, indentation_level);
}

config_print :: (using root : *Config_Root)
{
	for assignments
		config_print_assignment (it);
}

config_fill_variables :: (config : Any, root : *Config_Root) -> bool
{
	profile ();
	
	info := cast (*Type_Info_Struct) config.type;
	ptr := config.value_pointer;
	if info.type == .POINTER
	{
		info = cast (*Type_Info_Struct) (cast (*Type_Info_Pointer) info).pointer_to;
		ptr = <<cast (**void) ptr;
	}
	assert (info.type == .STRUCT, "Config has invalid non-struct type.");
	for root.assignments
	{
		lvalue := config_find_lvalue_ptr (ptr, info, it.lvalue);
		if lvalue.value_pointer
		{
			if !config_assign (ptr, info, lvalue.value_pointer, lvalue.type, it.rvalue)
			{
				print ("Could not assign to l-value ");
				config_print_lvalue (it.lvalue);
				print (".\n");
			}
		}
	}

	return true;
}

config_find_lvalue_ptr :: (ptr : *void, info : *Type_Info_Struct, lvalue : *Config_LValue) -> Any
{
	for info.members
	{
		if it.name == lvalue.identifier
		{
			member_ptr := ptr + it.offset_in_bytes;
			if lvalue.subscript_index > 0
			{
				// Typecheck array
				if it.type.type != .ARRAY
				{
					println ("Accessing l-value with non-zero subscript index for non-array type ('%').", lvalue.identifier);

					return NULL_ANY;
				}
				if lvalue.subscript_index > rtti_get_array_count (member_ptr, cast (*Type_Info_Array) it.type)
				{
					println ("Index % out of bounds when accessing l-value array ('%').", lvalue.identifier);

					return NULL_ANY;
				}
				member_ptr = rtti_get_array_data (member_ptr, cast (*Type_Info_Array) it.type) + (cast (*Type_Info_Array) info).element_type.runtime_size * lvalue.subscript_index;
			}

			if lvalue.member_lvalue
			{
				if it.type.type != .STRUCT
				{
					println ("Accessing member of l-value for non-struct type ('%').", lvalue.identifier);

					return NULL_ANY;
				}
				
				return config_find_lvalue_ptr (member_ptr, cast (*Type_Info_Struct) it.type, lvalue.member_lvalue);
			}
			result : Any = ---;
			result.type = it.type;
			result.value_pointer = member_ptr;
			println ("Found l-value pointer for %.", lvalue.identifier);

			return result;
		}
	}

	return NULL_ANY;
}

config_assign :: (config_ptr : *void, config_info : *Type_Info_Struct, ptr : *void, info : *Type_Info, rvalue : *Config_RValue) -> bool
{
	profile ();

	if #complete rvalue.kind ==
	{
	case .INT;
		if info.type != .INTEGER then return false;
		info_int := cast (*Type_Info_Integer) info;
		if !info_int.signed && rvalue.int_value < 0 then return false;
		rtti_set_int (ptr, info_int, rvalue.int_value);

	case .BOOL;
		if info.type != .BOOL then return false;
		rtti_set_bool (ptr, info, rvalue.bool_value);

	case .STRING;
		if info.type != .STRING then return false;
		info_str := cast (*Type_Info_String) info;
		if info_str.relative_pointer_size then return false;	// @Note (stefan): We don't handle relative strings
		rtti_set_string (ptr, info_str, rvalue.string_value);
	
	case .FLOAT;
		if info.type != .FLOAT then return false;
		rtti_set_float (ptr, cast (*Type_Info_Float) info, rvalue.float_value);

	case .COMPOUND;
		if info.type ==
		{
		case .STRUCT;
			return config_assign_compound_struct (config_ptr, config_info, ptr, cast (*Type_Info_Struct) info, rvalue.compound);
		case .ARRAY;
			return config_assign_compound_array (config_ptr, config_info, ptr, cast (*Type_Info_Array) info, rvalue.compound);
		case;
			return false;
		}

	case .LVALUE;
		panic ("Assign to lvalue is not yet implemented (identifier was %).", rvalue.lvalue.identifier);
		rhs := config_find_lvalue_ptr (config_ptr, config_info, rvalue.lvalue);
		if !rhs.value_pointer then return false;
		if !rtti_is_assignable (info, rhs.type) then return false;
		rtti_assign (ptr, info, rhs.value_pointer, rhs.type);
	}
	
	return true;
}

config_assign_compound_struct :: (config_ptr : *void, config_info : *Type_Info_Struct, ptr : *void, info : *Type_Info_Struct, compound : *Config_Compound) -> bool
{
	member_index := 0;
	for elem : compound.elems
	{
		member : *Type_Info_Struct_Member;
		if #complete elem.specifier.kind ==
		{
		case .NONE;
			if member_index >= info.members.count then return false;
			member = *info.members[member_index];

		case .IDENTIFIER;
			for * info.members
			{
				if it.name == elem.specifier.identifier
				{
					member = it;
					member_index = it_index;

					break;
				}
			}

		case .INDEX;
			return false;
		}
		if !member then return false;
		member_ptr  := ptr + member.offset_in_bytes;
		member_info := member.type;
		member_index += 1;
		config_assign (config_ptr, config_info, member_ptr, member_info, elem.rvalue);
	}

	return true;
}

config_assign_compound_array :: (config_ptr : *void, config_info : *Type_Info_Struct, ptr : *void, info : *Type_Info_Array, compound : *Config_Compound) -> bool
{
	resizable := info.array_type == .RESIZABLE;
	count     := rtti_get_array_count (ptr, info);
	data_ptr  := rtti_get_array_data (ptr, info);
	allocated := 0;
	if resizable
		allocated = rtti_get_resizable_array_capacity (ptr, info);
	else
		allocated = count;
	allocator : Allocator;
	if resizable
	{
		allocator = rtti_get_resizable_array_allocator (ptr, info);
		if allocator.proc == null
		{
			rtti_set_resizable_array_allocator (ptr, info, HEAP);
			allocator = HEAP;
		}
	}
	elem_info := info.element_type;
	index := 0;
	for elem : compound.elems
	{
		elem_ptr : *void;
		if #complete elem.specifier.kind ==
		{
		case .NONE;
			if index >= allocated && resizable
				data_ptr, allocated = rtti_resize_array (ptr, info, allocated + 8);
			if index >= allocated then return false;
			elem_ptr = data_ptr + elem_info.runtime_size * index;
		case .INDEX;
			if resizable then return false;
			index = elem.specifier.index;
			if index >= count then return false;
			elem_ptr = data_ptr + elem_info.runtime_size * index;
		case .IDENTIFIER;
			return false;
		}
		index += 1;
		if resizable then rtti_set_array_count (ptr, info, index);
		config_assign (config_ptr, config_info, elem_ptr, elem_info, elem.rvalue);
	}

	return true;
}
*/
