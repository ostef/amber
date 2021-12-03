C_Lexer :: struct
{
	buffer_id : Buffer_ID;
	offset, count, line, column : s64;
	found_include_directive : bool;
	tokens : [..]C_Token;
}

C_Token :: struct
{
	Kind :: enum
	{
		UNKNOWN;
		WHITESPACE;
		INVALID;
		COMMENT;
		CHAR_LITERAL;
		STRING_LITERAL;
		NUMBER_LITERAL;
		IDENTIFIER;
		KEYWORD;
		KEYWORD_CONTROL;
		KEYWORD_STORAGE_TYPE;
		KEYWORD_TYPE;
		KEYWORD_FUNCTION;
		PREPROCESSOR_DIRECTIVE;
		SYMBOL;
		EOI;
	}
	
	kind : Kind;
	range : Rangei;
	l0, c0, l1, c1 : s64;
	union
	{
		control_keyword : C_Control_Keyword;
		storage_type_keyword : C_Storage_Type_Keyword;
		type_keyword : C_Type_Keyword;
		function_keyword : C_Function_Keyword;
		keyword : C_Keyword;
		preprocessor_directive : C_Preprocessor_Directive;
	};
}

C_CONTROL_KEYWORDS :: string.[ "if", "else", "switch", "case", "for", "do", "while", "break", "continue", "return" ];
C_STORAGE_TYPE_KEYWORDS :: string.[ "struct", "union", "enum" ];
C_TYPE_KEYWORDS :: string.[ "void", "unsigned", "signed", "char", "short", "int", "long", "float", "double" ];
C_FUNCTION_KEYWORDS :: string.[ "sizeof" ];
C_OTHER_KEYWORDS :: string.[ "extern", "static", "inline", "const", "volatile", "typedef" ];
C_PREPROCESSOR_DIRECTIVES :: string.[ "include", "if", "else", "elif", "endif", "ifdef", "ifndef",
	"define", "undef", "line", "error", "pragma" ];

#insert -> string
{
	pr :: print_to_builder;
	ln :: print_line_to_builder;
	nl :: print_newline_to_builder;
	
	builder : String_Builder;
	init_string_builder (*builder, 1000, TEMP);
	ln (*builder, "C_Control_Keyword :: enum\n{");
	for C_CONTROL_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, TEMP));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "C_Storage_Type_Keyword :: enum\n{");
	for C_STORAGE_TYPE_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, TEMP));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "C_Type_Keyword :: enum\n{");
	for C_TYPE_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, TEMP));
	ln (*builder, "}");
	nl (*builder);
	
	
	ln (*builder, "C_Function_Keyword :: enum\n{");
	for C_FUNCTION_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, TEMP));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "C_Keyword :: enum\n{");
	for C_OTHER_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, TEMP));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "C_Preprocessor_Directive :: enum\n{");
	for C_PREPROCESSOR_DIRECTIVES
		ln (*builder, "\t%;", clone_to_upper (it, TEMP));
	ln (*builder, "}");
	nl (*builder);
	
	return to_string (builder);
}

c_process_buffer :: (using hooks : *Amber_Hooks, buffer_id : Buffer_ID)
{
	layout_id := buffer_get_text_layout (buffer_id);
	lexer : C_Lexer;
	lexer.buffer_id = buffer_id;
	lexer.offset = 0;
	lexer.count  = buffer_get_count (buffer_id);
	lexer.line   = 1;
	lexer.column = 1;
	while true
	{
		token := read_next_token (hooks, *lexer);
		//push_into_array (*lexer.tokens, token);
		if token.kind == .EOI then break;
		color := RGBA_WHITE;
		if token.kind ==
		{
		case .INVALID; color = rgba (255, 0, 0);
		case .COMMENT; color = rgba (0x52, 0xb0, 0x41);
		case .CHAR_LITERAL; color = rgba (0xe0, 0x83, 0x69);
		case .STRING_LITERAL; color = rgba (0xe0, 0x83, 0x69);
		case .NUMBER_LITERAL; color = rgba (0xae, 0xdb, 0x9a);
		case .IDENTIFIER; color = rgba (255, 255, 255);
		case .KEYWORD; color = rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_CONTROL; color = rgba (0xe8, 0x79, 0xb2);
		case .KEYWORD_STORAGE_TYPE; color = rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_TYPE; color = rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_FUNCTION; color = rgba (0x4a, 0xa1, 0xff);
		case .PREPROCESSOR_DIRECTIVE;
			color = rgba (0x4a, 0xa1, 0xff);
			if token.preprocessor_directive == .INCLUDE
				lexer.found_include_directive = true;
			
		case .SYMBOL; color = rgba (0xe5, 0xe5, 0xe5);
		}
		text_layout_push_color (layout_id, token.range, color);
	}
	end := platform_get_time ();
}

set_token_start :: inline (using lexer : *C_Lexer, token : *C_Token)
{
	token.range.min = offset;
	token.l0 = line;
	token.c0 = column;
}

set_token_end :: inline (using lexer : *C_Lexer, token : *C_Token)
{
	token.range.max = offset - 1;
	token.l1 = line;
	token.c1 = column;
}

read_next_token :: (using hooks : *Amber_Hooks, using lexer : *C_Lexer) -> C_Token
{
	token : C_Token;
	set_token_start (lexer, *token);

	if offset >= count
	{
		token.kind = .EOI;
		set_token_end (lexer, *token);
	}
	else if is_space (peek_codepoint (hooks, lexer))
	{
		token.kind = .WHITESPACE;
		skip_spaces (hooks, lexer);
		set_token_end (lexer, *token);
	}
	else if advance_if_matches_string (hooks, lexer, "//")
	{
		token.kind = .COMMENT;
		while offset < count && peek_codepoint (hooks, lexer) != #char "\n"
			advance (hooks, lexer);
		advance (hooks, lexer);
		set_token_end (lexer, *token);
	}
	else if advance_if_matches_string (hooks, lexer, "/*")
	{
		closed := false;
		while offset < count
		{
			if advance_if_matches_string (hooks, lexer, "*/")
			{
				closed = true;
				
				break;
			}
			advance (hooks, lexer);
		}
		if !closed
			token.kind = .INVALID;
		else
			token.kind = .COMMENT;
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (hooks, lexer) == #char "'"
	{
		advance (hooks, lexer);
		while offset < count && peek_codepoint (hooks, lexer) != #char "'"
		{
			if peek_codepoint (hooks, lexer) == #char "\\"
				advance (hooks, lexer);
			advance (hooks, lexer);
		}
		if peek_codepoint (hooks, lexer) != #char "'"
			token.kind = .INVALID;
		else
			token.kind = .CHAR_LITERAL;
		advance (hooks, lexer);
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (hooks, lexer) == #char "\""
	{
		advance (hooks, lexer);
		while offset < count && peek_codepoint (hooks, lexer) != #char "\""
		{
			if peek_codepoint (hooks, lexer) == #char "\\"
				advance (hooks, lexer);
			advance (hooks, lexer);
		}
		if peek_codepoint (hooks, lexer) != #char "\""
			token.kind = .INVALID;
		else
			token.kind = .STRING_LITERAL;
		advance (hooks, lexer);
		set_token_end (lexer, *token);
	}
	else if found_include_directive && peek_codepoint (hooks, lexer) == #char "<"
	{
		advance (hooks, lexer);
		while offset < count && peek_codepoint (hooks, lexer) != #char ">"
			advance (hooks, lexer);
		if peek_codepoint (hooks, lexer) != #char ">"
			token.kind = .INVALID;
		else
			token.kind = .STRING_LITERAL;
		advance (hooks, lexer);
		set_token_end (lexer, *token);
	}
	else if is_digit (peek_codepoint (hooks, lexer))
	{
		is_int_hex   := advance_if_matches_string (hooks, lexer, "0x") || advance_if_matches_string (hooks, lexer, "0X");
		is_int_oct   := false;
		if !is_int_hex
			is_int_oct = advance_if_matches_string (hooks, lexer, "0");

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
			if matches_string (hooks, lexer, "..")
			{
				break;
			}
			else if peek_codepoint (hooks, lexer) == #char "."
			{
				if found_exponent || found_decimal || is_int_hex || is_int_oct then valid = false;
				found_decimal    = true;
				last_was_decimal = true;
			}
			else if peek_codepoint (hooks, lexer) == #char "e" && !is_int_hex
			{
				if digit_count == 0 || found_exponent || is_int_oct then valid = false;
				found_exponent    = true;
				last_was_exponent = true;
			}
			else if is_alpha_num (peek_codepoint (hooks, lexer))
			{
				if (is_int_hex)
				{
					if !is_hex_digit (peek_codepoint (hooks, lexer))
						valid = false;
				}
				else if is_int_oct
				{
					if !is_digit (peek_codepoint (hooks, lexer), 8)
						valid = false;
				}
				else if !is_digit (peek_codepoint (hooks, lexer))
				{
					valid = false;
				}

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

			advance (hooks, lexer);
		}

		if is_int_oct && digit_count == 0
		{
			is_int_oct = false;
			digit_count = 1;
		}
		
		if digit_count == 0 ||
			found_decimal && decimal_digit_count == 0 ||
			found_exponent && exponent_digit_count == 0
		{
			valid = false;
		}

		token.kind = ifx valid then C_Token.Kind.NUMBER_LITERAL else C_Token.Kind.INVALID;
		set_token_end (lexer, *token);
	}
	else if is_alpha (peek_codepoint (hooks, lexer)) || peek_codepoint (hooks, lexer) == #char "_"
	{
		if advance_if_matches_identifier_in_array (hooks, lexer, C_CONTROL_KEYWORDS)
			token.kind = .KEYWORD_CONTROL;
		else if advance_if_matches_identifier_in_array (hooks, lexer, C_STORAGE_TYPE_KEYWORDS)
			token.kind = .KEYWORD_STORAGE_TYPE;
		else if advance_if_matches_identifier_in_array (hooks, lexer, C_TYPE_KEYWORDS)
			token.kind = .KEYWORD_TYPE;
		else if advance_if_matches_identifier_in_array (hooks, lexer, C_FUNCTION_KEYWORDS)
			token.kind = .KEYWORD_FUNCTION;
		else if advance_if_matches_identifier_in_array (hooks, lexer, C_OTHER_KEYWORDS)
			token.kind = .KEYWORD;
		else
		{
			token.kind = .IDENTIFIER;
			skip_identifier (hooks, lexer);
		}
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (hooks, lexer) == #char "#"
	{
		advance (hooks, lexer);
		skip_spaces (hooks, lexer);
		ok, directive := advance_if_matches_identifier_in_array (hooks, lexer, C_PREPROCESSOR_DIRECTIVES);
		if ok
		{
			token.kind = .PREPROCESSOR_DIRECTIVE;
			token.preprocessor_directive = xx directive;
		}
		else
		{
			token.kind = .INVALID;
			skip_identifier (hooks, lexer);
		}
		set_token_end (lexer, *token);
	}
	else
	{
		token.kind = .SYMBOL;
		advance (hooks, lexer);
		set_token_end (lexer, *token);
	}
	
	return token;
}

peek_codepoint :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, peek_offset := 0) -> u32 #must
{
	if offset + peek_offset >= count then return 0;
	
	return buffer_get_codepoint (buffer_id, offset + peek_offset);
}

skip_spaces :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer) -> s64
{
	i := 0;
	while offset < count && is_space (peek_codepoint (hooks, lexer))
	{
		advance (hooks, lexer);
		i += 1;
	}
	
	return i;
}

skip_identifier :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer) -> s64
{
	if !is_alpha (peek_codepoint (hooks, lexer)) && peek_codepoint (hooks, lexer) != #char "_"
		return 0;
	i := 0;
	while offset < count && is_alpha_num (peek_codepoint (hooks, lexer))
	{
		advance (hooks, lexer);
		i += 1;
	}

	return i;
}

matches_string :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, str : string) -> bool #must
{
	if offset + str.count > count then return false;
	for i : 0..str.count - 1
	{
		if peek_codepoint (hooks, lexer, i) != str[i]
			return false;
	}
	
	return true;
}

advance_if_matches_string :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, str : string) -> bool
{
	if matches_string (hooks, lexer, str)
	{
		advance (hooks, lexer, str.count);
		
		return true;
	}
	
	return false;
}

matches_range :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, range : Rangei) -> bool #must
{
	if offset + length (range) > count then return false;
	for i : 0..length (range) - 1
	{
		if peek_codepoint (hooks, lexer, i) != buffer_get_codepoint (buffer_id, range.min + i)
			return false;
	}
	
	return true;
}

advance_if_matches_range :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, range : Rangei) -> bool
{
	if matches_range (hooks, lexer, range)
	{
		advance (hooks, lexer, length (range));
		
		return true;
	}
	
	return false;
}

matches_identifier :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, ident : string) -> bool #must
{
	if offset + ident.count > count then return false;
	for i : 0..ident.count - 1
	{
		if peek_codepoint (hooks, lexer, i) != ident[i]
			return false;
	}
	
	return offset + ident.count == count - 1 || !is_alpha_num (peek_codepoint (hooks, lexer, ident.count));
}

advance_if_matches_identifier :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, ident : string) -> bool
{
	if matches_identifier (hooks, lexer, ident)
	{
		advance (hooks, lexer, ident.count);
		
		return true;
	}
	
	return false;
}

matches_identifier_in_array :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, array : []string) -> bool #must, index : s64
{
	for array
	{
		if matches_identifier (hooks, lexer, it)
			return true, it_index;
	}
	
	return false, -1;
}

advance_if_matches_identifier_in_array :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer, array : []string) -> bool #must, index : s64
{
	for array
	{
		if advance_if_matches_identifier (hooks, lexer, it)
			return true, it_index;
	}
	
	return false, -1;
}

advance_until_space :: inline (using hooks : *Amber_Hooks, using lexer : *C_Lexer) -> s64
{
	i := 0;
	while offset < count && !is_space (peek_codepoint (hooks, lexer))
	{
		advance (hooks, lexer);
		i += 1;
	}
	
	return i;
}

advance :: (using hooks : *Amber_Hooks, lexer : *C_Lexer, count := 1) -> bool
{
	if lexer.offset >= lexer.count
		return false;
	i := 0;
	while i < count && lexer.offset < lexer.count
	{
		if peek_codepoint (hooks, lexer) == #char "\n"
		{
			lexer.line += 1;
			lexer.column = 0;
			lexer.found_include_directive = false;
		}
		lexer.offset += 1;
		lexer.column += 1;
		i += 1;
	}
	
	return true;
}
