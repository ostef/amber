/*
 * Ideas about the config system:
 *
 * The config system uses the type information features of Jai.
 * We have an Amber_Config struct, which contains all the config
 * variables of the main program, and extensions can set the
 * Amber_Hooks.extension_config variable in extension_init to add
 * configuration variables. We use the type information of the struct
 * to fill all the data from the config file we parsed prior
 * (Amber_Hooks.extension_config is an Any).
 * 
 * Config loading for the main program and the extensions is done
 * separately, because the extension list is in the main config
 * file. After we've loaded the main program's configuration, we load
 * extensions and fill all the variables inside each extensions' config
 * pointer using the Type_Info (see config_fill_variables procedure).
 */

// @Todo (stefan): Better error reporting and handling.

Amber_Config :: struct
{
	extensions : [..]string;
	default_font_name : string;
	default_font_height : u32;
	command_prompt : string;
	some_array : [3]int = .[ 1, 2, 3 ];
	another_array : []int;
	treat_underscores_as_alpha_numeric_boundary : bool;
}

Config_Parser :: struct
{
	filename : string;
	start, curr, end : *u8;
	line, column : s64;
	errors : [..]Config_Error;
	root : Config_Root;
	assignments : Bucket_Array (Config_Assignment, 20);
	rvalues     : Bucket_Array (Config_RValue, 20);
	lvalues     : Bucket_Array (Config_LValue, 20);
	compounds   : Bucket_Array (Config_Compound, 20);
	compound_elems : Bucket_Array (Config_Compound_Elem, 20);
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
	Kind :: enum
	{
		LVALUE   :: 0;
		INT      :: 1;
		BOOL     :: 2;
		STRING   :: 3;
		FLOAT    :: 4;
		COMPOUND :: 5;
	}

	kind : Kind;
	union
	{
		lvalue : *Config_LValue;
		int_value : int;
		bool_value : bool;
		string_value : string;
		float_value : float;
		compound : *Config_Compound;
	};
}

Config_LValue :: struct
{
	identifier : string;
	subscript_index : int;
	member_lvalue : *Config_LValue;
}

Config_Compound :: struct
{
	elems : []*Config_Compound_Elem;
}

Config_Compound_Elem :: struct
{
	Specifier :: struct
	{
		Kind :: enum
		{
			NONE       :: 0;
			IDENTIFIER :: 1;
			INDEX      :: 2;
		}
		
		kind : Kind;
		union
		{
			identifier : string;
			index : int;
		};
	}

	specifier : Specifier;
	rvalue : *Config_RValue;
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
	init_bucket_array (*parser.rvalues, 200, HEAP);
	init_bucket_array (*parser.lvalues, 200, HEAP);
	init_bucket_array (*parser.compounds, 50, HEAP);
	init_bucket_array (*parser.compound_elems, 200, HEAP);
}

config_parser_error :: (using parser : *Config_Parser, error_str : string)
{
	println ("Error at line %, column %: %", line, column, error_str);
	error : Config_Error = ---;
	error.start = curr;
	error.line = line;
	error.column = column;
	error.str = error_str;
}

config_parser_recover :: (using parser : *Config_Parser)
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

	if is_alpha (config_parser_get (parser)) || config_parser_get (parser) == #char "_"
	{
		lvalue := config_parse_lvalue (parser);
		if !lvalue then return null;
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .LVALUE;
		rvalue.lvalue = lvalue;

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
	
	if config_parser_is_string (parser, "{")
	{
		compound := config_parse_compound (parser);
		if !compound then return null;
		rvalue := add_to_bucket_array (*rvalues);
		rvalue.kind = .COMPOUND;
		rvalue.compound = compound;

		return rvalue;
	}
	
	return null;
}

config_parse_lvalue :: (using parser : *Config_Parser) -> *Config_LValue
{
	profile ();

	config_parser_skip_spaces (parser);
	identifier, ok := config_parse_identifier (parser);
	if !ok then return null;
	subscript_index := 0;
	if config_parser_match_string (parser, "[")
	{
		subscript_index = config_parse_int (parser);
		if subscript_index < 0 then return null;
		if !config_parser_match_string (parser, "]") then return null;
	}
	member_lvalue : *Config_LValue;
	if config_parser_match_string (parser, ".")
	{
		member_lvalue = config_parse_lvalue (parser);
		if !member_lvalue then return null;
	}

	lvalue := add_to_bucket_array (*lvalues);
	lvalue.identifier = identifier;
	lvalue.subscript_index = subscript_index;
	lvalue.member_lvalue = member_lvalue;

	return lvalue;
}

config_parse_int :: inline (using parser : *Config_Parser) -> int, ok : bool
{
	str : string = ---;
	str.data = curr;
	str.count = end - curr;
	value, ok, remainder := string_to_s64 (str);
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

config_parse_compound :: (using parser : *Config_Parser) -> *Config_Compound
{
	profile ();

	config_parser_skip_spaces (parser);
	if !config_parser_match_string (parser, "{") then return null;
	elems : [..]*Config_Compound_Elem;
	elems.allocator = TEMP;
	found_comma := true;
	config_parser_skip_spaces (parser);
	while !config_parser_match_string (parser, "}")
	{
		if !found_comma then return null;
		elem := config_parse_compound_elem (parser);
		if !elem then return null;
		push_into_array (*elems, elem);
		config_parser_skip_spaces (parser);
		found_comma = config_parser_match_string (parser, ",");
		config_parser_skip_spaces (parser);
	}

	compound := add_to_bucket_array (*compounds);
	compound.elems = clone_array (elems, HEAP);

	return compound;
}

config_parse_compound_elem :: (using parser : *Config_Parser) -> *Config_Compound_Elem
{
	profile ();

	specifier : Config_Compound_Elem.Specifier;
	config_parser_skip_spaces (parser);
	if config_parser_match_string (parser, ".")
	{
		ok := false;
		int_value, int_ok := config_parse_int (parser);
		if int_ok
		{
			specifier.kind = .INDEX;
			specifier.index = int_value;
			if specifier.index < 0 then return null;
			ok = true;
		}
		else if is_alpha (config_parser_get (parser)) || config_parser_get (parser) == #char "_"
		{
			specifier.kind = .IDENTIFIER;
			specifier.identifier = config_parse_identifier (parser);
			ok = true;
		}
		if !ok then return null;
		config_parser_skip_spaces (parser);
		if !config_parser_match_string (parser, "=") return null;
	}
	rvalue := config_parse_rvalue (parser);
	if !rvalue then return null;

	compound_elem := add_to_bucket_array (*compound_elems);
	compound_elem.specifier = specifier;
	compound_elem.rvalue = rvalue;

	return compound_elem;
}

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
	if resizable then allocator = rtti_get_resizable_array_allocator (ptr, info);
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
