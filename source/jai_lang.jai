Jai_Lexer :: struct
{
	buffer : *Buffer;
	offset, count, line, column : s64;
	is_in_asm_block : bool;
	is_in_herestring : bool;
	herestring_end_ident : Vec2l;
	tokens : [..]Jai_Token;
}

Jai_Token :: struct
{
	Kind :: enum
	{
		UNKNOWN;
		WHITESPACE;
		INVALID;
		COMMENT;
		STRING_LITERAL;
		NUMBER_LITERAL;
		IDENTIFIER;
		KEYWORD;
		KEYWORD_CONTROL;
		KEYWORD_STORAGE_TYPE;
		KEYWORD_TYPE;
		KEYWORD_FUNCTION;
		COMPILER_DIRECTIVE;
		POLYMORPHIC_ARGUMENT;
		NOTE;
		KEYWORD_ASM_TYPE;
		KEYWORD_ASM_INSTRUCTION;
		KEYWORD_ASM_SIZE;
		SYMBOL;
		EOI;
	}
	
	kind : Kind;
	range : Vec2l;
	l0, c0, l1, c1 : s64;
	union
	{
		control_keyword : Jai_Control_Keyword;
		storage_type_keyword : Jai_Storage_Type_Keyword;
		type_keyword : Jai_Type_Keyword;
		function_keyword : Jai_Function_Keyword;
		keyword : Jai_Keyword;
		compiler_directive : Jai_Compiler_Directive;
	};
}

JAI_CONTROL_KEYWORDS :: string.[ "if", "ifx", "then", "else", "case", "for", "while", "break", "continue", "return", "using", "defer" ];
JAI_STORAGE_TYPE_KEYWORDS :: string.[ "struct", "union", "enum", "enum_flags" ];
JAI_TYPE_KEYWORDS :: string.[ "void", "u8", "u16", "u32", "u64", "s8", "s16", "s32", "s64", "int", "float32", "float64", "f32", "f64", "float", "bool", "string", "__reg", "reg" ];
JAI_FUNCTION_KEYWORDS :: string.[ "cast", "xx", "type_of", "type_info", "size_of", "align_of", "initializer_of", "is_constant", "code_of" ];
JAI_OTHER_KEYWORDS :: string.[ "push_context", "context", "null", "true", "false", "it", "it_index", "no_check", "truncate", "no_dll", "stallable",
	"operator", "interface", "distinct", "isa", "inline", "typed" ];
JAI_COMPILER_DIRECTIVES :: string.[
	"import", "load", "foreign", "foreign_library", "foreign_system_library", "must", "no_abc", "insert", "insert_internal",
	"run", "char", "place", "through", "expand", "if", "scope_file", "scope_module", "scope_export", "assert", "bake_arguments", "bake_constants",
	"complete", "string", "no_reset", "dump", "code", "caller_location", "c_call", "c_callback", "module_parameters", "elsewhere", "placeholder", "intrinsic",
	"compiler", "symmetric", "modify", "cpp_return_type_is_non_pod", "cpp_method", "add_context", "dynamic_specialize", "specified", "filepath", "file", "line",
	"poke_name", "program_export", "procedure_of_call", "location", "type_info_none", "type_info_procedures_are_void_pointers", "type_info_no_size_complaint",
	"no_alias", "type", "deprecated", "align", "no_context", "runtime_support", "asm", "caller_code", "this", "no_padding", "ifx", "as", "bytes",
];

#insert -> string
{
	code : builder.Builder;
	builder.init (*code, mem.HEAP_ALLOC);
	builder.append_line (*code, "Jai_Control_Keyword :: enum\n{{");
	for JAI_CONTROL_KEYWORDS
		builder.append_line (*code, "\t%;", str.to_upper (str.clone (it, mem.HEAP_ALLOC)));
	builder.append_line (*code, "}\n");
	
	builder.append_line (*code, "Jai_Storage_Type_Keyword :: enum\n{{");
	for JAI_STORAGE_TYPE_KEYWORDS
		builder.append_line (*code, "\t%;", str.to_upper (str.clone (it, mem.HEAP_ALLOC)));
	builder.append_line (*code, "}\n");
	
	builder.append_line (*code, "Jai_Type_Keyword :: enum\n{{");
	for JAI_TYPE_KEYWORDS
		builder.append_line (*code, "\t%;", str.to_upper (str.clone (it, mem.HEAP_ALLOC)));
	builder.append_line (*code, "}\n");

	builder.append_line (*code, "Jai_Function_Keyword :: enum\n{{");
	for JAI_FUNCTION_KEYWORDS
		builder.append_line (*code, "\t%;", str.to_upper (str.clone (it, mem.HEAP_ALLOC)));
	builder.append_line (*code, "}\n");

	builder.append_line (*code, "Jai_Keyword :: enum\n{{");
	for JAI_OTHER_KEYWORDS
		builder.append_line (*code, "\t%;", str.to_upper (str.clone (it, mem.HEAP_ALLOC)));
	builder.append_line (*code, "}\n");

	builder.append_line (*code, "Jai_Compiler_Directive :: enum\n{{");
	for JAI_COMPILER_DIRECTIVES
		builder.append_line (*code, "\t%;", str.to_upper (str.clone (it, mem.HEAP_ALLOC)));
	builder.append_line (*code, "}\n");
	
	return builder.build (code, mem.HEAP_ALLOC);
}

process_jai_buffer :: (text_info : *Text_Info)
{
	lexer : Jai_Lexer;
	lexer.buffer = get (text_info.buffer_id);
	lexer.line = 1;
	lexer.column = 1;
	lexer.count = get_count (lexer.buffer);
	next_token_is_herestring_end_ident := false;
	array.clear (*text_info.infos);
	while true
	{
		token := read_next_token (*lexer);
		info : Text_Info.Info;
		info.weight = .REGULAR;
		info.color = math.RGBA_WHITE;
		if token.kind ==
		{
		case .INVALID;
			info.color = math.rgba (255, 0, 0);
			info.weight = .BOLD;
		case .COMMENT;
			info.color = math.rgba (0x52, 0xb0, 0x41);
			info.effects |= .ITALIC;
		case .STRING_LITERAL;
			info.color = math.rgba (0xe0, 0x83, 0x69);
			lexer.is_in_herestring = false;
		case .NUMBER_LITERAL; info.color = math.rgba (0xae, 0xdb, 0x9a);
		case .IDENTIFIER;
			info.color = math.rgba (255, 255, 255);
			if next_token_is_herestring_end_ident
			{
				lexer.herestring_end_ident = token.range;
				lexer.is_in_herestring = true;
				next_token_is_herestring_end_ident = false;
			}
		case .KEYWORD_CONTROL;
			info.color = math.rgba (0xe8, 0x79, 0xb2);
			info.weight = .BOLD;
		case .KEYWORD;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_STORAGE_TYPE;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_TYPE;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_FUNCTION;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
		case .COMPILER_DIRECTIVE;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
			if token.compiler_directive == .STRING
				next_token_is_herestring_end_ident = true;
		case .POLYMORPHIC_ARGUMENT;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
		case .NOTE;
			info.color = math.rgba (0x4a, 0xa1, 0xff);
			info.effects |= .UNDERLINE;
		case .SYMBOL;
			info.color = math.rgba (0xe5, 0xe5, 0xe5);
		}
		ptr := array.push (*text_info.infos);
		ptr.range = token.range;
		ptr.info = info;
		if token.kind == .EOI
			break;
	}
}

set_token_start :: inline (using lexer : *Jai_Lexer, token : *Jai_Token)
{
	token.range.x = offset;
	token.l0 = line;
	token.c0 = column;
}

set_token_end :: inline (using lexer : *Jai_Lexer, token : *Jai_Token)
{
	token.range.y = offset - 1;
	token.l1 = line;
	token.c1 = column;
}

read_next_token :: (using lexer : *Jai_Lexer) -> Jai_Token
{
	token : Jai_Token;
	set_token_start (lexer, *token);

	if offset >= count
	{
		token.kind = .EOI;
		set_token_end (lexer, *token);
	}
	else if is_in_herestring
	{
		token.kind = .STRING_LITERAL;
		while offset < count && !matches_range (lexer, herestring_end_ident)
			advance (lexer);
		if offset == count
			token.kind = .INVALID;
		set_token_end (lexer, *token);
	}
	else if str.is_space (xx peek_codepoint (lexer))
	{
		token.kind = .WHITESPACE;
		skip_spaces (lexer);
		set_token_end (lexer, *token);
	}
	else if advance_if_matches_string (lexer, "//")
	{
		token.kind = .COMMENT;
		while offset < count && peek_codepoint (lexer) != #char "\n"
			advance (lexer);
		advance (lexer);
		set_token_end (lexer, *token);
	}
	else if advance_if_matches_string (lexer, "/*")
	{
		level := 1;
		while offset < count && level > 0
		{
			if advance_if_matches_string (lexer, "/*")
			{
				level += 1;
				
				continue;
			}
			else if advance_if_matches_string (lexer, "*/")
			{
				level -= 1;
				
				continue;
			}
			advance (lexer);
		}
		if level != 0
			token.kind = .INVALID;
		else
			token.kind = .COMMENT;
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (lexer) == #char "\""
	{
		advance (lexer);
		while offset < count && peek_codepoint (lexer) != #char "\""
		{
			if peek_codepoint (lexer) == #char "\\"
				advance (lexer);
			advance (lexer);
		}
		if lexer.offset == count
			token.kind = .INVALID;
		else
			token.kind = .STRING_LITERAL;
		advance (lexer);
		set_token_end (lexer, *token);
	}
	else if str.is_digit (xx peek_codepoint (lexer))
	{
		is_float_hex := advance_if_matches_string (lexer, "0h") || advance_if_matches_string (lexer, "0H");
		is_int_hex   := false;
		if !is_float_hex
			is_int_hex = advance_if_matches_string (lexer, "0x") || advance_if_matches_string (lexer, "0X");
		is_int_bin   := false;
		if !is_float_hex && !is_int_hex
			is_int_bin = advance_if_matches_string (lexer, "0b") || advance_if_matches_string (lexer, "0B");

		valid := true;
		found_decimal     := false;
		found_exponent    := false;
		last_was_decimal  := false;
		last_was_exponent := false;
		digit_count          := 0;
		whole_digit_count    := 0;
		decimal_digit_count  := 0;
		exponent_digit_count := 0;
		while lexer.offset < lexer.count
		{
			if matches_string (lexer, "..")
				break;
			else if peek_codepoint (lexer) == #char "."
			{
				if found_exponent || found_decimal || is_float_hex || is_int_hex || is_int_bin then valid = false;
				found_decimal    = true;
				last_was_decimal = true;
			}
			else if peek_codepoint (lexer) == #char "e" && !is_float_hex && !is_int_hex
			{
				if digit_count == 0 || found_exponent || is_int_bin then valid = false;
				found_exponent    = true;
				last_was_exponent = true;
			}
			else if str.is_alpha_num (xx peek_codepoint (lexer))
			{
				if (is_float_hex || is_int_hex)
				{
					if !str.is_hex_digit (xx peek_codepoint (lexer)) && peek_codepoint (lexer) != #char "_"
						valid = false;
				}
				else if is_int_bin
				{
					if !str.is_bin_digit (xx peek_codepoint (lexer)) && peek_codepoint (lexer) != #char "_"
						valid = false;
				}
				else if !str.is_digit (xx peek_codepoint (lexer)) && peek_codepoint (lexer) != #char "_"
				{
					valid = false;
				}
				
				if peek_codepoint (lexer) == #char "_" && last_was_exponent then valid = false;

				digit_count += 1;
				if found_exponent then exponent_digit_count += 1;
				else if found_decimal then decimal_digit_count += 1;
				else whole_digit_count += 1;
				last_was_decimal  = false;
				last_was_exponent = false;
			}
			else
			{
				break;
			}

			advance (lexer);
		}

		if digit_count == 0 ||
			found_decimal && decimal_digit_count == 0 ||
			found_exponent && exponent_digit_count == 0
		{
			valid = false;
		}

		token.kind = ifx valid then Jai_Token.Kind.NUMBER_LITERAL else Jai_Token.Kind.INVALID;
		set_token_end (lexer, *token);
	}
	else if str.is_alpha (xx peek_codepoint (lexer)) || peek_codepoint (lexer) == #char "_"
	{
		if advance_if_matches_identifier_in_array (lexer, JAI_CONTROL_KEYWORDS)
			token.kind = .KEYWORD_CONTROL;
		else if advance_if_matches_identifier_in_array (lexer, JAI_STORAGE_TYPE_KEYWORDS)
			token.kind = .KEYWORD_STORAGE_TYPE;
		else if advance_if_matches_identifier_in_array (lexer, JAI_TYPE_KEYWORDS)
			token.kind = .KEYWORD_TYPE;
		else if advance_if_matches_identifier_in_array (lexer, JAI_FUNCTION_KEYWORDS)
			token.kind = .KEYWORD_FUNCTION;
		else if advance_if_matches_identifier_in_array (lexer, JAI_OTHER_KEYWORDS)
			token.kind = .KEYWORD;
		else
		{
			token.kind = .IDENTIFIER;
			skip_identifier (lexer);
		}
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (lexer) == #char "#"
	{
		advance (lexer);
		skip_spaces (lexer);
		ok, directive := advance_if_matches_identifier_in_array (lexer, JAI_COMPILER_DIRECTIVES);
		if ok
		{
			token.kind = .COMPILER_DIRECTIVE;
			token.compiler_directive = xx directive;
		}
		else
		{
			token.kind = .INVALID;
			skip_identifier (lexer);
		}
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (lexer) == #char "@"
	{
		advance (lexer);
		// @Todo (stefan): string literal notes
		if offset >= count || str.is_space (xx peek_codepoint (lexer))
			token.kind = .INVALID;
		else
		{
			token.kind = .NOTE;
			advance_until_space (lexer);
		}
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (lexer) == #char "$"
	{
		advance (lexer);
		if peek_codepoint (lexer) == #char "$"
			advance (lexer);
		if skip_identifier (lexer)
			token.kind = .POLYMORPHIC_ARGUMENT;
		else
			token.kind = .INVALID;
		set_token_end (lexer, *token);
	}
	else
	{
		token.kind = .SYMBOL;
		advance (lexer);
		set_token_end (lexer, *token);
	}
	
	return token;
}

peek_codepoint :: inline (using lexer : *Jai_Lexer, peek_offset := 0) -> u32 #must
{
	assert (offset + peek_offset < count, "Bounds check failure (got % + %, max is %).", offset, peek_offset, count - 1);
	
	return char_at (buffer, offset + peek_offset);
}

skip_spaces :: inline (using lexer : *Jai_Lexer) -> s64
{
	i := 0;
	while offset < count && str.is_space (xx peek_codepoint (lexer))
	{
		advance (lexer);
		i += 1;
	}
	
	return i;
}

skip_identifier :: inline (using lexer : *Jai_Lexer) -> s64
{
	if offset >= count
		return 0;
	if !str.is_alpha (xx peek_codepoint (lexer)) && peek_codepoint (lexer) != #char "_"
		return 0;
	i := 0;
	while offset < count && str.is_alpha_num (xx peek_codepoint (lexer))
	{
		advance (lexer);
		i += 1;
	}

	return i;
}

matches_string :: inline (using lexer : *Jai_Lexer, str : string) -> bool #must
{
	if offset + str.count > count then return false;
	for i : 0..str.count - 1
	{
		if peek_codepoint (lexer, i) != str[i]
			return false;
	}
	
	return true;
}

advance_if_matches_string :: inline (using lexer : *Jai_Lexer, str : string) -> bool
{
	if matches_string (lexer, str)
	{
		advance (lexer, str.count);
		
		return true;
	}
	
	return false;
}

matches_range :: inline (using lexer : *Jai_Lexer, range : Vec2l) -> bool #must
{
	if offset + range.y - range.x > count then return false;
	for i : 0..range.y - range.x - 1
	{
		if peek_codepoint (lexer, i) != char_at (buffer, range.x + i)
			return false;
	}
	
	return true;
}

advance_if_matches_range :: inline (using lexer : *Jai_Lexer, range : Vec2l) -> bool
{
	if matches_range (lexer, range)
	{
		advance (lexer, range.y - range.x);
		
		return true;
	}
	
	return false;
}

matches_identifier :: inline (using lexer : *Jai_Lexer, ident : string) -> bool #must
{
	if offset + ident.count > count
		return false;
	for i : 0..ident.count - 1
	{
		if peek_codepoint (lexer, i) != ident[i]
			return false;
	}
	
	return offset + ident.count == count || !str.is_alpha_num (xx peek_codepoint (lexer, ident.count));
}

advance_if_matches_identifier :: inline (using lexer : *Jai_Lexer, ident : string) -> bool
{
	if matches_identifier (lexer, ident)
	{
		advance (lexer, ident.count);
		
		return true;
	}
	
	return false;
}

matches_identifier_in_array :: inline (using lexer : *Jai_Lexer, array : []string) -> bool #must, index : s64
{
	for array
	{
		if matches_identifier (lexer, it)
			return true, it_index;
	}
	
	return false, -1;
}

advance_if_matches_identifier_in_array :: inline (using lexer : *Jai_Lexer, array : []string) -> bool #must, index : s64
{
	for array
	{
		if advance_if_matches_identifier (lexer, it)
			return true, it_index;
	}
	
	return false, -1;
}

advance_until_space :: inline (using lexer : *Jai_Lexer) -> s64
{
	i := 0;
	while offset < count && !str.is_space (xx peek_codepoint (lexer))
	{
		advance (lexer);
		i += 1;
	}
	
	return i;
}

advance :: (lexer : *Jai_Lexer, count := 1) -> bool
{
	if lexer.offset >= lexer.count
		return false;
	i := 0;
	while i < count && lexer.offset < lexer.count
	{
		if peek_codepoint (lexer) == #char "\n"
		{
			lexer.line += 1;
			lexer.column = 0;
		}
		lexer.offset += 1;
		lexer.column += 1;
		i += 1;
	}
	
	return true;
}
