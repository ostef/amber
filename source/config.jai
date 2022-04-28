Color_Id :: u16;

Variable :: struct
{
	Value :: struct
	{
		Kind :: enum
		{
			INT;
			FLOAT;
			STRING;
			BOOL;
			RGBA;
		}

		kind : Kind;
		union
		{
			as_int    : int;
			as_float  : float;
			as_string : string;
			as_bool   : bool;
			as_rgba   : math.RGBA;
		};
	}

	name : string;
	value : Value;
}

set :: inline (value : *Variable.Value, val : $T)
{
	#if T == int
	{
		value.kind = .INT;
		value.as_int = val;
	}
	else #if T == float
	{
		value.kind = .FLOAT;
		value.as_float = val;
	}
	else #if T == bool
	{
		value.kind = .BOOL;
		value.as_bool = val;
	}
	else #if T == string
	{
		value.kind = .STRING;
		value.as_string = val;
	}
	else #if T == math.RGBA
	{
		value.kind = .RGBA;
		value.as_rgba = val;
	}
	else
		#assert false, "Invalid type, must be int, float, bool, string or RGBA.";
}

value_cast :: inline ($Target : Type, value : Variable.Value, $check_panic := true) -> Target #must, bool
{
	#if Target == int
	{
		if value.kind != .INT
		{
			#if check_panic
				panic ("Value is not an int.");
			return mem.default (Target), false;
		}
		return value.as_int, true;
	}
	else #if Target == float
	{
		if value.kind != .FLOAT
		{
			#if check_panic
				panic ("Value is not a float.");
			return mem.default (Target), false;
		}
		return value.as_float, true;
	}
	else #if Target == bool
	{
		if value.kind != .BOOL
		{
			#if check_panic
				panic ("Value is not a bool.");
			return mem.default (Target), false;
		}
		return value.as_bool, true;
	}
	else #if Target == string
	{
		if value.kind != .STRING
		{
			#if check_panic
				panic ("Value is not a string.");
			return mem.default (Target), false;
		}
		return value.as_string, true;
	}
	else #if Target == math.RGBA
	{
		if value.kind != .RGBA
		{
			#if check_panic
				panic ("Value is not a RGBA.");
			return mem.default (Target), false;
		}
		return value.as_rgba, true;
	}
	else
		#assert false, "Invalid type, must be int, float, bool, string or RGBA.";
}

Config :: struct
{
	variables : map.Hash_Map (string, Variable.Value);
}

set :: inline (config : *Config, name : string, value : Variable.Value)
{
	ptr := map.get_ptr (config.variables, name);
	if !ptr
		ptr = map.insert (*config.variables, str.clone (name, mem.HEAP_ALLOC), value);
	else
	{
		if ptr.kind == .STRING
			mem.free (ptr.as_string, mem.HEAP_ALLOC);
		<<ptr = value;
	}
	if ptr.kind == .STRING
		ptr.as_string = str.clone (ptr.as_string, mem.HEAP_ALLOC);
}

set :: inline (config : *Config, name : string, value : bool)
{
	val : Variable.Value;
	val.kind = .BOOL;
	val.as_bool = value;
	set (config, name, val);
}

set :: inline (config : *Config, name : string, value : int)
{
	val : Variable.Value;
	val.kind = .INT;
	val.as_int = value;
	set (config, name, val);
}

set :: inline (config : *Config, name : string, value : float)
{
	val : Variable.Value;
	val.kind = .FLOAT;
	val.as_float = value;
	set (config, name, val);
}

set :: inline (config : *Config, name : string, value : string)
{
	val : Variable.Value;
	val.kind = .STRING;
	val.as_string = value;
	set (config, name, val);
}

get :: inline (config : Config, name : string) -> Variable.Value, ok : bool
{
	ptr := map.get_ptr (config.variables, name);
	if !ptr
		return .{}, false;
	return <<ptr, true;
}

get_int :: inline (config : Config, name : string, fallback := 0) -> int, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind == .INT
		return fallback, false;
	return val.as_int, true;
}

get_float :: inline (config : Config, name : string, fallback := 0.0) -> float, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .FLOAT
		return fallback, false;
	return val.as_float, true;
}

get_string :: inline (config : Config, name : string, fallback := "") -> string, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .STRING
		return fallback, false;
	return val.as_string, true;
}

get_bool :: inline (config : Config, name : string, fallback := false) -> bool, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .BOOL
		return fallback, false;
	return val.as_bool, true;
}

get_rgba :: inline (config : Config, name : string, fallback := math.RGBA.{ 0, 0, 0, 0 }) -> math.RGBA, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .RGBA
		return fallback, false;
	return val.as_rgba, true;
}

Config_Parser :: struct
{
	Error :: struct
	{
		line, column : s64;
		error_string : string;
		line_string : string;
	}

	allocator : Allocator;
	filename : string;
	line, column : s64;
	start, curr, end : *u8;
	root_assignments : [..]*Config_Assignment;
	assignments : storage.Storage (Config_Assignment, 20);
	lvalues : storage.Storage (Config_LValue, 20);
	rvalues : storage.Storage (Config_RValue, 20);
	array_literals : storage.Storage (Config_Array_Literal, 20);
	map_literals : storage.Storage (Config_Map_Literal, 20);
}

Config_Assignment :: struct
{
	lvalue : *Config_LValue;
	rvalue : *Config_RValue;
}

Config_LValue :: struct
{
	identifier : string;
}

Config_RValue :: struct
{
	Kind :: enum
	{
		VALUE  :: 0;
		LVALUE :: 1;
		ARRAY  :: 2;
		MAP    :: 3;
	}

	kind : Kind;
	union
	{
		value : Variable.Value;
		lvalue   : *Config_LValue;
		array_literal : *Config_Array_Literal;
		map_literal   : *Config_Map_Literal;
	};
}

Config_Array_Literal :: struct
{
	elems : [..]*Config_RValue;
}

Config_Map_Literal :: struct
{
	Key_Value :: struct
	{
		key : string;
		value : *Config_RValue;
	}

	elems : [..]Key_Value;
}

init_from_file :: (parser : *Config_Parser, filename : string, allocator : Allocator) -> bool
{
	file_contents, ok := fs.read_entire_file (filename, allocator);
	if ok != .OK
		return false;
	parser.allocator = allocator;
	parser.filename = filename;
	parser.line = 1;
	parser.column = 1;
	parser.start = file_contents.data;
	parser.curr  = file_contents.data;
	parser.end   = file_contents.data + file_contents.count;
	array.init (*parser.root_assignments, 50, allocator);
	storage.init (*parser.assignments, allocator);
	storage.init (*parser.lvalues, allocator);
	storage.init (*parser.rvalues, allocator);
	storage.init (*parser.array_literals, allocator);
	storage.init (*parser.map_literals, allocator);
	return true;
}

recover :: inline (using parser : *Config_Parser)
{
	while curr < end && <<curr != #char ";"
		advance (parser);
	advance (parser);
}

error :: (using parser : *Config_Parser, fmt_str : string, args : ..Any)
{
	err : Error;
	err.line = line;
	err.column = column;
	err.error_string = str.format (allocator, fmt_str, ..args);
	line_start := curr - start;
	while line_start > 0 && start[line_start - 1] != #char "\n"
		line_start -= 1;
	line_end := curr - start;
	while start + line_end < end && line_end > 0 && start[line_end] != #char "\n"
		line_end += 1;
	err.line_string = str.make (start + line_start, line_end - line_start);

	fmt.println ("%:%:%, %", filename, err.line, err.column, err.error_string);
	line_number_len := fmt.print (" % | ", err.line);
	fmt.println (err.line_string);
	for i : 0..line_number_len + err.column - 2
		fmt.print (" ");
	fmt.println ("^");
}

fill_variables :: inline (config : *Config, using parser : Config_Parser)
{
	fill_value :: (config : *Config, name : string, rvalue : *Config_RValue)
	{
		if #complete rvalue.kind ==
		{
		case .VALUE;
			set (config, name, rvalue.value);
		case .LVALUE;
			val, ok := get (config, rvalue.lvalue.identifier);
			if ok
				set (config, name, val);
		case .ARRAY;
			set (config, str.join (mem.TEMP_ALLOC, name, ".count"), rvalue.array_literal.elems.count);
			for elem, i : rvalue.array_literal.elems
				fill_value (config, str.format (mem.TEMP_ALLOC, "%[%]", name, i), elem);
		case .MAP;
			set (config, str.join (mem.TEMP_ALLOC, name, ".count"), rvalue.map_literal.elems.count);
			for elem, i : rvalue.map_literal.elems
				fill_value (config, str.format (mem.TEMP_ALLOC, "%[{:'}]", name, elem.key), elem.value);
		}
	}

	mem.temporary_block ();
	for root_assignments
		fill_value (config, it.lvalue.identifier, it.rvalue);
}

parse :: (using parser : *Config_Parser)
{
	while curr < end
	{
		assignment := parse_assignment (parser);
		if assignment
			array.push (*root_assignments, assignment);
		skip_spaces (parser);
	}
}

#scope_file

advance :: inline (using parser : *Config_Parser, count := 1)
{
	while curr < end && count > 0
	{
		if <<curr == #char "\n"
		{
			line += 1;
			column = 0;
		}
		column += 1;
		curr += 1;
		count -= 1;
	}
}

skip_spaces :: inline (using parser : *Config_Parser) -> skipped : s64
{
	i := 0;
	while curr < end && str.is_space (<<curr)
	{
		advance (parser);
		i += 1;
	}
	return i;
}

equals :: inline (using parser : *Config_Parser, str : string) -> bool #must
{
	if end - curr < str.count
		return false;
	for i : 0..str.count - 1
		if curr[i] != str[i]
			return false;
	return true;
}

match :: inline (using parser : *Config_Parser, str : string) -> bool #must
{
	if !equals (parser, str)
		return false;
	advance (parser, str.count);
	return true;
}

parse_assignment :: (parser : *Config_Parser) -> *Config_Assignment #must
{
	skip_spaces (parser);
	lvalue := parse_lvalue (parser);
	if !lvalue
	{
		error (parser, "Expected an l-value for assignment.");
		recover (parser);
		return null;
	}
	skip_spaces (parser);
	if !match (parser, "=")
	{
		error (parser, "Expected '=' for assignment after l-value.");
		recover (parser);
		return null;
	}
	rvalue := parse_rvalue (parser);
	if !rvalue
	{
		error (parser, "Expected an r-value for assignment.");
		recover (parser);
		return null;
	}
	skip_spaces (parser);
	if !match (parser, ";")
	{
		error (parser, "Expected ';' at the end of assignment.");
		recover (parser);
		return null;
	}
	assignment := storage.find_free_slot (*parser.assignments);
	assignment.lvalue = lvalue;
	assignment.rvalue = rvalue;
	return assignment;
}

parse_lvalue :: (parser : *Config_Parser) -> *Config_LValue #must
{
	skip_spaces (parser);
	identifier, ok := parse_identifier (parser);
	if !ok
		return null;
	lvalue := storage.find_free_slot (*parser.lvalues);
	lvalue.identifier = identifier;
	return lvalue;
}

parse_rvalue :: (parser : *Config_Parser) -> *Config_RValue #must
{
	add_value_rvalue :: (value : $T) -> *Config_RValue #expand
	{
		rvalue := storage.find_free_slot (*`parser.rvalues);
		rvalue.kind = .VALUE;
		set (*rvalue.value, value);
		return rvalue;
	}

	skip_spaces (parser);
	{
		val, ok := parse_bool (parser);
		if ok
			return add_value_rvalue (val);
	}
	/* @Todo {
		val, ok := parse_float (parser);
		if ok
			return add_value_rvalue (val);
	}*/
	{
		val, ok := parse_int (parser);
		if ok
			return add_value_rvalue (val);
	}
	{
		val, ok, unclosed := parse_string (parser);
		if ok
			return add_value_rvalue (val);
		else if unclosed
		{
			error (parser, "Unclosed string literal.");
			recover (parser);
			return null;
		}
	}
	{
		val, ok, invalid := parse_rgba (parser);
		if ok
			return add_value_rvalue (val);
		else if invalid
		{
			error (parser, "Invalid RGBA literal.");
			recover (parser);
			return null;
		}
	}
	{
		val := parse_lvalue (parser);
		if val
		{
			rvalue := storage.find_free_slot (*parser.rvalues);
			rvalue.kind = .LVALUE;
			rvalue.lvalue = val;
			return rvalue;
		}
	}
	{
		val := parse_array_literal (parser);
		if val
		{
			rvalue := storage.find_free_slot (*parser.rvalues);
			rvalue.kind = .ARRAY;
			rvalue.array_literal = val;
			return rvalue;
		}
	}
	{
		val := parse_map_literal (parser);
		if val
		{
			rvalue := storage.find_free_slot (*parser.rvalues);
			rvalue.kind = .MAP;
			rvalue.map_literal = val;
			return rvalue;
		}
	}
	return null;
}

parse_bool :: inline (using parser : *Config_Parser) -> val : bool, ok : bool
{
	skip_spaces (parser);
	s := str.make (curr, end - curr);
	val, read := strconv.parse_bool (s);
	if read == 0 || (curr + read < end && str.is_alnum (curr[read]))
		return false, false;
	advance (parser, read);
	return val, true;
}

parse_int :: inline (using parser : *Config_Parser) -> val : int, ok : bool
{
	skip_spaces (parser);
	s := str.make (curr, end - curr);
	val, read := strconv.parse_s64 (s);
	if read == 0
		return 0, false;
	advance (parser, read);
	return val, true;
}

parse_float :: inline (using parser : *Config_Parser) -> val : float, ok : bool
{
	// @Todo (stefan): differentiate between floats and integers
	skip_spaces (parser);
	s := str.make (curr, end - curr);
	val, read := strconv.parse_f64 (s);
	if read == 0
		return 0, false;
	advance (parser, read);
	return cast (float) val, true;
}

parse_string :: inline (using parser : *Config_Parser) -> val : string, ok : bool, unclosed : bool
{
	mem.temporary_block ();
	skip_spaces (parser);
	result : builder.Builder;
	builder.init (*result, mem.TEMP_ALLOC);
	if curr >= end
		return "", false, false;
	if <<curr != #char "\""
		return "", false, false;
	advance (parser);
	while true
	{
		if curr >= end || <<curr == #char "\n"
			return "", false, true;
		if <<curr == #char "\""
			break;
		if match (parser, "\\n")
			builder.append (*result, "\n");
		else if match (parser, "\\r")
			builder.append (*result, "\r");
		else if match (parser, "\\t")
			builder.append (*result, "\t");
		else if match (parser, "\\\\")
			builder.append (*result, "\\");
		else if match (parser, "\\\"")
			builder.append (*result, "\"");
		else
		{
			builder.append_byte (*result, <<curr);
			advance (parser);
		}
	}
	advance (parser);
	return builder.build (result, allocator), true, false;
}

parse_rgba :: inline (using parser : *Config_Parser) -> val : math.RGBA, ok : bool, invalid : bool
{
	skip_spaces (parser);
	if !match (parser, "#")
		return .{}, false, false;
	if end - curr < 6
		return .{}, false, true;
	rs := str.make (curr, 2);
	r, rok := strconv.parse_u8 (rs, strconv.HEXADECIMAL_BASE);
	if rok != 2
		return .{}, false, true;
	advance (parser, rok);
	gs := str.make (curr, 2);
	g, gok := strconv.parse_u8 (gs, strconv.HEXADECIMAL_BASE);
	if gok != 2
		return .{}, false, true;
	advance (parser, gok);
	bs := str.make (curr, 2);
	b, bok := strconv.parse_u8 (bs, strconv.HEXADECIMAL_BASE);
	if bok != 2
		return .{}, false, true;
	advance (parser, bok);
	as := str.make (curr, end - curr);
	a, aok := strconv.parse_u8 (as, strconv.HEXADECIMAL_BASE);
	if aok != 0 && aok != 2
		return .{}, false, true;
	advance (parser, aok);
	return math.rgba (r, g, b, ifx aok then a else 255), true, false;
}

parse_identifier :: inline (using parser : *Config_Parser) -> val : string, ok : bool
{
	skip_spaces (parser);
	if curr >= end
		return "", false;
	if <<curr != #char "_" && !str.is_alpha (<<curr)
		return "", false;
	s : string;
	s.data = curr;
	while curr + s.count < end
	{
		if !str.is_alnum (curr[s.count])
			break;
		s.count += 1;
	}
	if s == "true" || s == "false"
		return "", false;
	advance (parser, s.count);
	return s, true;
}

parse_array_literal :: inline (using parser : *Config_Parser) -> *Config_Array_Literal #must
{
	skip_spaces (parser);
	if !match (parser, "[")
		return null;
	elems : [..]*Config_RValue;
	elems.allocator = allocator;
	found_comma := true;
	skip_spaces (parser);
	while !match (parser, "]")
	{
		if !found_comma
			return null;
		elem := parse_rvalue (parser);
		if !elem
			return null;
		array.push (*elems, elem);
		skip_spaces (parser);
		found_comma = match (parser, ",");
		skip_spaces (parser);
	}
	literal := storage.find_free_slot (*parser.array_literals);
	literal.elems = elems;
	return literal;
}

parse_map_literal :: inline (using parser : *Config_Parser) -> *Config_Map_Literal #must
{
	skip_spaces (parser);
	if !match (parser, "{")
		return null;
	elems : [..]Config_Map_Literal.Key_Value;
	elems.allocator = allocator;
	found_comma := true;
	skip_spaces (parser);
	while !match (parser, "}")
	{
		if !found_comma
			return null;
		ok : bool;
		elem : Config_Map_Literal.Key_Value;
		elem.key, ok = parse_string (parser);
		if !ok
			return null;
		skip_spaces (parser);
		if !match (parser, ":")
			return null;
		skip_spaces (parser);
		elem.value = parse_rvalue (parser);
		if !elem.value
			return null;
		array.push (*elems, elem);
		skip_spaces (parser);
		found_comma = match (parser, ",");
		skip_spaces (parser);
	}
	literal := storage.find_free_slot (*parser.map_literals);
	literal.elems = elems;
	return literal;
}

/*
print :: (using lvalue : *Config_LValue)
{
	fmt.print (identifier);
}

print :: (using rvalue : *Config_RValue)
{
	if #complete kind == 
	{
	case .VALUE;
		print (value);
	case .LVALUE;
		print (lvalue);
	case .ARRAY;
		print (array_literal);
	case .MAP;
		print (map_literal);
	}
}

print :: (using value : Variable.Value)
{
	if #complete kind ==
	{
	case .INT;
		fmt.print (as_int);
	case .FLOAT;
		fmt.print (as_float);
	case .BOOL;
		fmt.print (as_bool);
	case .STRING;
		fmt.print ("{:'}", as_string);
	}
}

print :: (using array_literal : *Config_Array_Literal)
{
	fmt.println ("[");
	for elems
	{
		if it_index != 0
			fmt.println (",");
		print (it);
	}
	fmt.print ("]");
}

print :: (using map_literal : *Config_Map_Literal)
{
	//fmt.println ("% elems", elems.count);
	fmt.println ("{");
	for elems
	{
		if it_index != 0
			fmt.println (",");
		fmt.print ("{:'} : ", it.key);
		if it.value.kind == .MAP && it.value.map_literal == map_literal
			panic ("WOOOOOOW!!!! That's an infinite loop right there!");
		print (it.value);
	}
	fmt.print ("}");
}

print :: (using assignment : *Config_Assignment)
{
	print (lvalue);
	fmt.print (" = ");
	print (rvalue);
	fmt.println (";");
}

print :: (using parser : *Config_Parser)
{
	for root_assignments
	{
		print (it);
	}
}
*/
