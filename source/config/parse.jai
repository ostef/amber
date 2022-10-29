Config_Parser :: struct
{
	Error :: struct
	{
		filename : string;
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

	kind : Kind;	@Fmt_Tag
	using val : union
	{
		value : Variable.Value;
		lvalue   : *Config_LValue;
		array_literal : *Config_Array_Literal;
		map_literal   : *Config_Map_Literal;
	};	@Fmt_Tagged_Union
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

preprocess_config_file :: (file_contents : string, allocator : Allocator) -> string #must
#no_abc
{
	preprocess :: (result : *builder.Builder, file_contents : string)
	#no_abc
	{
		i := 0;
		while i < file_contents.count
		{
			if str.starts_with (str.advance (file_contents, i), "@include")
			{
				i += "@include".count;
				while i < file_contents.count && str.is_space (file_contents[i])
					i += 1;
				if i == file_contents.count || file_contents[i] != #char "\""
				{
					log.error ("Config: expected a string literal after @include directive.");
					recover (file_contents, i);
					continue;
				}
				i += 1;
				filename : string;
				filename.data = file_contents.data + i;
				while i < file_contents.count && file_contents[i] != #char "\"" && file_contents[i] != #char "\n"
					i += 1;
				filename.count = file_contents.data + i - filename.data;
				if i == file_contents.count || file_contents[i] != #char "\""
				{
					log.error ("Config: unclosed string literal for @include directive.");
					recover (file_contents, i);
					continue;
				}
				i += 1;
				contents, err := fs.read_entire_file (filename, mem.HEAP_ALLOC);
				if err != .OK
				{
					log.error ("Config: could not open file {:'} for @include directive.", filename);
					continue;
				}
				defer mem.free (contents, mem.HEAP_ALLOC);
				preprocess (result, contents);
			}
			else
			{
				builder.append_byte (result, file_contents[i]);
				i += 1;
			}
		}
	}

	recover :: inline (file_contents : string, i : s64) -> s64
	{
		while i < file_contents.count && file_contents[i] != #char "\n"
			i += 1;
		if i < file_contents.count
			i += 1;
		return i;
	}

	result : builder.Builder;
	builder.init (*result, mem.HEAP_ALLOC);
	defer builder.reset (*result);
	preprocess (*result, file_contents);

	return builder.build (result, allocator);
}

init_from_file :: (parser : *Config_Parser, filename : string, allocator : Allocator) -> bool
{
	file_contents, ok := fs.read_entire_file (filename, allocator);
	if ok != .OK
		return false;
	preprocessed_contents := preprocess_config_file (file_contents, allocator);
	mem.free (file_contents, allocator);
	parser.allocator = allocator;
	parser.filename = filename;
	parser.line = 1;
	parser.column = 1;
	parser.start = preprocessed_contents.data;
	parser.curr  = preprocessed_contents.data;
	parser.end   = preprocessed_contents.data + preprocessed_contents.count;
	array.init (*parser.root_assignments, 50, allocator);
	storage.init (*parser.assignments, allocator);
	storage.init (*parser.lvalues, allocator);
	storage.init (*parser.rvalues, allocator);
	storage.init (*parser.array_literals, allocator);
	storage.init (*parser.map_literals, allocator);
	return true;
}

recover :: inline (using parser : *Config_Parser, until := ";")
{
	while curr < end && str.find_first (until, <<curr) < 0
		advance (parser);
	advance (parser);
}

error :: (using parser : *Config_Parser, fmt_str : string, args : ..Any)
{
	err : Error;
	err.filename = filename;
	err.line = line;
	err.column = column;
	err.error_string = fmt.format (allocator, fmt_str, ..args);
	line_start := curr - start;
	while line_start > 0 && start[line_start - 1] != #char "\n"
		line_start -= 1;
	line_end := curr - start;
	while start + line_end < end && line_end > 0 && start[line_end] != #char "\n"
		line_end += 1;
	err.line_string = str.make (start + line_start, line_end - line_start);
	print_error (err);
}

print_error :: (using err : Config_Parser.Error)
{
	fmt.println ("%:%:%, %", filename, line, column, error_string);
	line_number_len := fmt.print (" % | ", line);
	for i : 0..line_string.count - 1
	{
		if line_string[i] == #char "\t"
			fmt.print ("    ");
		else
			fmt.print ("{:c}", line_string[i]);
	}
	fmt.print ("\n");
	for i : 0..line_number_len - 1
		fmt.print (" ");
	for i : 0..column - 2
	{
		if line_string[i] == #char "\t"
			fmt.print ("    ");
		else
			fmt.print (" ");
	}
	fmt.println ("^");
}

fill_variables :: inline (config : *Config, using parser : Config_Parser)
{
	find_map_key_index :: inline (config : Config, name : string, map_key : string) -> s64, bool
	{
		for val, key : config.variables
		{
			if equals (val, map_key)
			&& key.count > name.count + 2
			&& str.starts_with (key, name)
			&& key[name.count] == #char "["
			&& str.is_digit (key[name.count + 1])
			{
				index, read, err := strconv.parse_s64 (str.advance (key, name.count + 1));
				assert (err == .OK, "Could not parse key index for % in %.", name, key);
				remaining := str.advance (key, name.count + 1 + read + 1);
				if remaining != ".key"
					continue;
				return index, true;
			}
		}
		return -1, false;
	}

	fill_value :: (config : *Config, name : string, rvalue : *Config_RValue) -> overwritten : bool
	{
		if #complete rvalue.kind ==
		{
		case .VALUE;
			return set (config, name, rvalue.value);

		case .LVALUE;
			val, ok := get (config, rvalue.lvalue.identifier);
			if ok
				return set (config, name, val);
			return false;

		case .ARRAY;
			count_varname := str.join (mem.TEMP_ALLOC, name, ".count");
			count := get_int (config, count_varname);
			overwritten := set (config, count_varname, count + rvalue.array_literal.elems.count);
			for elem, i : rvalue.array_literal.elems
				fill_value (config, fmt.format (mem.TEMP_ALLOC, "%[%]", name, count + i), elem);

			return overwritten;

		case .MAP;
			count_varname := str.join (mem.TEMP_ALLOC, name, ".count");
			count := get_int (config, count_varname);
			added := 0;
			for elem, i : rvalue.map_literal.elems
			{
				varname := fmt.format (mem.TEMP_ALLOC, "%['%']", name, elem.key);

				index : s64;
				if !fill_value (config, varname, elem.value)
				{
					index = count + added;
					added += 1;
				}
				else
				{
					exists : bool;
					index, exists = find_map_key_index (config, name, elem.key);
					assert (exists, "Filled pre-existing map name[key] variable, but could not find the name[index] form.");
				}

				// @Note (stefan): I can see these being useful for iteration, for example:
				// for i : 0..get_int (config, "map.count") - 1
				// {
				//     key   := get_string (config, "map[%].key");
				//     value := get (config, "map[%].value");
				// }
				set (config, fmt.format (mem.TEMP_ALLOC, "%[%].key", name, index), elem.key);
				fill_value (config, fmt.format (mem.TEMP_ALLOC, "%[%].value", name, index), elem.value);
			}

			// We consider the map was overwritten if the name.count variable already exists
			return set (config, count_varname, count + added);
		}
		return false;
	}

	mem.temporary_storage_block ();
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
	// @Todo (stefan): Parse more complicated expressions, like map and array subscript for l-values.
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
	{
		val, ok := parse_float (parser);
		if ok
			return add_value_rvalue (val);
	}
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
		val, invalid := parse_array_literal (parser);
		if val
		{
			rvalue := storage.find_free_slot (*parser.rvalues);
			rvalue.kind = .ARRAY;
			rvalue.array_literal = val;
			return rvalue;
		}
		else if invalid
			return null;
	}
	{
		val, invalid := parse_map_literal (parser);
		if val
		{
			rvalue := storage.find_free_slot (*parser.rvalues);
			rvalue.kind = .MAP;
			rvalue.map_literal = val;
			return rvalue;
		}
		else if invalid
			return null;
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
	skip_spaces (parser);
	// Differentiate between floats and integers
	// If there is a . or an e/E, it's a float
	has_dot_or_exp := false;
	i := 0;
	while curr + i < end
	{
		defer i += 1;
		if curr[i] == #char "." || curr[i] == #char "e" || curr[i] == #char "E"
		{
			has_dot_or_exp = true;
			break;
		}
		if !str.is_digit (curr[i])
			break;
	}
	if !has_dot_or_exp
		return 0, false;
	s := str.make (curr, end - curr);
	val, read := strconv.parse_f64 (s);
	if read == 0
		return 0, false;
	advance (parser, read);
	return cast (float) val, true;
}

parse_string :: inline (using parser : *Config_Parser) -> val : string, ok : bool, unclosed : bool
{
	mem.temporary_storage_block ();
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

parse_array_literal :: inline (using parser : *Config_Parser) -> *Config_Array_Literal #must, invalid : bool
{
	skip_spaces (parser);
	if !match (parser, "[")
		return null, false;
	elems : [..]*Config_RValue;
	elems.allocator = allocator;
	found_comma := true;
	skip_spaces (parser);
	while !match (parser, "]")
	{
		if !found_comma
		{
			error (parser, "Expected ',' or ']' in array literal.");
			recover (parser, "];");
			return null, true;
		}
		elem := parse_rvalue (parser);
		if !elem
		{
			error (parser, "Expected an r-value for an array element.");
			recover (parser, "];");
			return null, true;
		}
		array.push (*elems, elem);
		skip_spaces (parser);
		found_comma = match (parser, ",");
		skip_spaces (parser);
	}
	literal := storage.find_free_slot (*parser.array_literals);
	literal.elems = elems;
	return literal, false;
}

parse_map_literal :: inline (using parser : *Config_Parser) -> *Config_Map_Literal #must, invalid : bool
{
	skip_spaces (parser);
	if !match (parser, "{")
		return null, false;
	elems : [..]Config_Map_Literal.Key_Value;
	elems.allocator = allocator;
	found_comma := true;
	skip_spaces (parser);
	while !match (parser, "}")
	{
		if !found_comma
		{
			error (parser, "Expected ',' or  '}' in map literal.");
			recover (parser, "};");
			return null, true;
		}
		ok : bool;
		elem : Config_Map_Literal.Key_Value;
		elem.key, ok = parse_string (parser);
		if !ok
		{
			error (parser, "Expected a string literal on the left hand side of a key-value pair.");
			recover (parser, "};");
			return null, true;
		}
		skip_spaces (parser);
		if !match (parser, ":")
		{
			error (parser, "Expected a colon (':') after the key for a key-value pair.");
			recover (parser, "};");
			return null, true;
		}
		skip_spaces (parser);
		elem.value = parse_rvalue (parser);
		if !elem.value
		{
			error (parser, "Expected an r-value on the right hande side of a key-value pair.");
			recover (parser, "};");
			return null, true;
		}
		array.push (*elems, elem);
		skip_spaces (parser);
		found_comma = match (parser, ",");
		skip_spaces (parser);
	}
	literal := storage.find_free_slot (*parser.map_literals);
	literal.elems = elems;
	return literal, false;
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
