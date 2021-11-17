#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_hooks.jai";
#load "amber_profiler.jai";

Jai_Lexer :: struct
{
	buffer_id : Buffer_ID;
	offset, count, line, column : s64;
	is_in_asm_block : bool;
	is_in_herestring : bool;
	herestring_end_ident : Rangei;
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
	range : Rangei;
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

JAI_CONTROL_KEYWORDS :: string.[ "if", "ifx", "then", "else", "case", "for", "while", "break", "continue", "return", "using", "inline", "defer" ];
JAI_STORAGE_TYPE_KEYWORDS :: string.[ "struct", "union", "enum", "enum_flags" ];
JAI_TYPE_KEYWORDS :: string.[ "void", "u8", "u16", "u32", "u64", "s8", "s16", "s32", "s64", "int", "float32", "float64", "f32", "f64", "float", "bool", "string", "__reg", "reg" ];
JAI_FUNCTION_KEYWORDS :: string.[ "cast", "xx", "type_of", "type_info", "size_of", "align_of", "initializer_of", "is_constant" ];
JAI_OTHER_KEYWORDS :: string.[ "push_context", "context", "null", "true", "false", "it", "it_index", "no_check", "truncate", "no_dll", "stallable",
	"operator", "interface", "distinct", "isa" ];
JAI_COMPILER_DIRECTIVES :: string.[
	"import", "load", "foreign", "foreign_library", "foreign_system_library", "must", "no_abc", "insert", "insert_internal",
	"run", "char", "place", "through", "expand", "if", "scope_file", "scope_module", "scope_export", "assert", "bake", "bake_arguments", "bake_constants",
	"complete", "string", "no_reset", "dump", "code", "caller_location", "c_call", "c_callback", "module_parameters", "elsewhere", "placeholder", "intrinsic",
	"compiler", "symmetric", "modify", "cpp_return_type_is_non_pod", "cpp_method", "add_context", "dynamic_specialize", "specified", "filepath", "file", "line",
	"poke_name", "program_export", "procedure_of_call", "location", "type_info_none", "type_info_procedures_are_void_pointers", "type_info_no_size_complaint",
	"no_alias", "type", "deprecated", "align", "no_context", "runtime_support", "asm", "caller_code", "this", "no_padding", "ifx"
];
JAI_ASM_TYPE_KEYWORDS        :: string.[ "gpr", "str", "vec", "omr" ];
JAI_ASM_INSTRUCTION_KEYWORDS :: string.[
	"lock_xor",
	"lock_or",
	"lock_and",
	"lock_inc",
	"lock_add",
	"lock_cmpxchg16b",
	"lock_cmpxchg",
	"lock_xchg",
	"movzxbw",
	"popcnt",
	"bsf",
	"bswap",
	"xor",
	"or",
	"and",
	"cpuid",
	"mov",
	"lea",
	"rdtsc",
	"rdtscp",
	"rdseed",
	"rdrand",
	"setc",
	"shl",
	"prefetchnta",
	"prefetch0",
	"prefetch1",
	"prefetch2",
	"mfence",
	"pause",
	"int3"
];
JAI_GPR_KEYWORDS :: string.[ "a", "b", "c", "d", "sp" ];
JAI_ASM_SIZE_KEYWORDS :: string.[ "b", "w", "d", "q", "x", "y", "z" ];

#insert -> string
{
	pr :: print_to_builder;
	ln :: print_line_to_builder;
	nl :: print_newline_to_builder;
	
	builder : String_Builder;
	init_string_builder (*builder, 1000, temp_allocator);
	ln (*builder, "Jai_Control_Keyword :: enum\n{");
	for JAI_CONTROL_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, temp_allocator));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "Jai_Storage_Type_Keyword :: enum\n{");
	for JAI_STORAGE_TYPE_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, temp_allocator));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "Jai_Type_Keyword :: enum\n{");
	for JAI_TYPE_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, temp_allocator));
	ln (*builder, "}");
	nl (*builder);
	
	
	ln (*builder, "Jai_Function_Keyword :: enum\n{");
	for JAI_FUNCTION_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, temp_allocator));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "Jai_Keyword :: enum\n{");
	for JAI_OTHER_KEYWORDS
		ln (*builder, "\t%;", clone_to_upper (it, temp_allocator));
	ln (*builder, "}");
	nl (*builder);
	
	ln (*builder, "Jai_Compiler_Directive :: enum\n{");
	for JAI_COMPILER_DIRECTIVES
		ln (*builder, "\t%;", clone_to_upper (it, temp_allocator));
	ln (*builder, "}");
	nl (*builder);
	
	return to_string (builder);
}

#program_export
init_extension :: (using hooks : *Amber_Hooks, extension_id : Extension_ID) -> bool
{
	context.allocator = heap_allocator;
#if ENABLE_PROFILING
	init_profiler ();

	jai : Language;
	jai.extension_id = extension_id;
	jai.name = "Jai";
	jai.associated_file_extensions = string.[ "jai" ];
	jai.process_buffer = jai_process_buffer;
	language_register (jai);
	
	return true;
}

#program_export
terminate_extension :: (using hooks : *Amber_Hooks)
{
#if ENABLE_PROFILING
{
	builder : String_Builder;
	init_string_builder (*builder, 5000, temp_allocator);
	write_profiling_data_to_builder (*builder);
	platform_write_to_file ("jai_profiling.txt", to_string (builder));
}
}

jai_process_buffer :: (using hooks : *Amber_Hooks, buffer_id : Buffer_ID)
{
	profile ();
	
	layout_id := buffer_get_text_layout (buffer_id);
	lexer : Jai_Lexer;
	lexer.buffer_id = buffer_id;
	lexer.offset = 0;
	lexer.count  = buffer_get_count (buffer_id);
	lexer.line   = 1;
	lexer.column = 1;
	next_token_is_herestring_end_ident := false;
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
		case .STRING_LITERAL;
			color = rgba (0xe0, 0x83, 0x69);
			lexer.is_in_herestring = false;
		
		case .NUMBER_LITERAL; color = rgba (0xae, 0xdb, 0x9a);
		case .IDENTIFIER;
			color = rgba (255, 255, 255);
			if next_token_is_herestring_end_ident
			{
				lexer.herestring_end_ident = token.range;
				lexer.is_in_herestring = true;
				next_token_is_herestring_end_ident = false;
			}
		
		case .KEYWORD; color = rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_CONTROL; color = rgba (0xe8, 0x79, 0xb2);
		case .KEYWORD_STORAGE_TYPE; color = rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_TYPE; color = rgba (0x4a, 0xa1, 0xff);
		case .KEYWORD_FUNCTION; color = rgba (0x4a, 0xa1, 0xff);
		case .COMPILER_DIRECTIVE;
			color = rgba (0x4a, 0xa1, 0xff);
			if token.compiler_directive == .STRING
				next_token_is_herestring_end_ident = true;
			
		case .POLYMORPHIC_ARGUMENT; color = rgba (0x4a, 0xa1, 0xff);
		case .NOTE; color = rgba (0x4a, 0xa1, 0xff);
		case .SYMBOL; color = rgba (0xe5, 0xe5, 0xe5);
		}
		text_layout_push_color (layout_id, token.range, color);
	}
	end := platform_get_time ();
}

set_token_start :: inline (using lexer : *Jai_Lexer, token : *Jai_Token)
{
	token.range.min = offset;
	token.l0 = line;
	token.c0 = column;
}

set_token_end :: inline (using lexer : *Jai_Lexer, token : *Jai_Token)
{
	token.range.max = offset - 1;
	token.l1 = line;
	token.c1 = column;
}

read_next_token :: (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer) -> Jai_Token
{
	profile ();

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
		while offset < count && !matches_range (hooks, lexer, herestring_end_ident)
			advance (hooks, lexer);
		if offset == count
			token.kind = .INVALID;
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
		level := 1;
		while offset < count && level > 0
		{
			if advance_if_matches_string (hooks, lexer, "/*")
			{
				level += 1;
				
				continue;
			}
			else if advance_if_matches_string (hooks, lexer, "*/")
			{
				level -= 1;
				
				continue;
			}
			advance (hooks, lexer);
		}
		if level != 0
			token.kind = .INVALID;
		else
			token.kind = .COMMENT;
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
	else if is_digit (peek_codepoint (hooks, lexer))
	{
		is_float_hex := advance_if_matches_string (hooks, lexer, "0h") || advance_if_matches_string (hooks, lexer, "0H");
		is_int_hex   := false;
		if !is_float_hex
			is_int_hex = advance_if_matches_string (hooks, lexer, "0x") || advance_if_matches_string (hooks, lexer, "0X");
		is_int_bin   := false;
		if !is_float_hex && !is_int_hex
			is_int_bin = advance_if_matches_string (hooks, lexer, "0b") || advance_if_matches_string (hooks, lexer, "0B");

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
				if found_exponent || found_decimal || is_float_hex || is_int_hex || is_int_bin then valid = false;
				found_decimal    = true;
				last_was_decimal = true;
			}
			else if peek_codepoint (hooks, lexer) == #char "e" && !is_float_hex && !is_int_hex
			{
				if digit_count == 0 || found_exponent || is_int_bin then valid = false;
				found_exponent    = true;
				last_was_exponent = true;
			}
			else if is_alpha_num (peek_codepoint (hooks, lexer))
			{
				if (is_float_hex || is_int_hex)
				{
					if !is_hex_digit (peek_codepoint (hooks, lexer)) && peek_codepoint (hooks, lexer) != #char "_"
						valid = false;
				}
				else if is_int_bin
				{
					if !is_bin_digit (peek_codepoint (hooks, lexer)) && peek_codepoint (hooks, lexer) != #char "_"
						valid = false;
				}
				else if !is_digit (peek_codepoint (hooks, lexer)) && peek_codepoint (hooks, lexer) != #char "_"
				{
					valid = false;
				}
				
				if peek_codepoint (hooks, lexer) == #char "_" && last_was_exponent then valid = false;

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

		if digit_count == 0 ||
			found_decimal && decimal_digit_count == 0 ||
			found_exponent && exponent_digit_count == 0
		{
			valid = false;
		}

		token.kind = ifx valid then Jai_Token.Kind.NUMBER_LITERAL else Jai_Token.Kind.INVALID;
		set_token_end (lexer, *token);
	}
	else if is_alpha (peek_codepoint (hooks, lexer)) || peek_codepoint (hooks, lexer) == #char "_"
	{
		if advance_if_matches_identifier_in_array (hooks, lexer, JAI_CONTROL_KEYWORDS)
			token.kind = .KEYWORD_CONTROL;
		else if advance_if_matches_identifier_in_array (hooks, lexer, JAI_STORAGE_TYPE_KEYWORDS)
			token.kind = .KEYWORD_STORAGE_TYPE;
		else if advance_if_matches_identifier_in_array (hooks, lexer, JAI_TYPE_KEYWORDS)
			token.kind = .KEYWORD_TYPE;
		else if advance_if_matches_identifier_in_array (hooks, lexer, JAI_FUNCTION_KEYWORDS)
			token.kind = .KEYWORD_FUNCTION;
		else if advance_if_matches_identifier_in_array (hooks, lexer, JAI_OTHER_KEYWORDS)
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
		ok, directive := advance_if_matches_identifier_in_array (hooks, lexer, JAI_COMPILER_DIRECTIVES);
		if ok
		{
			token.kind = .COMPILER_DIRECTIVE;
			token.compiler_directive = xx directive;
		}
		else
		{
			token.kind = .INVALID;
			skip_identifier (hooks, lexer);
		}
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (hooks, lexer) == #char "@"
	{
		advance (hooks, lexer);
		if is_space (peek_codepoint (hooks, lexer))
			token.kind = .INVALID;
		else
		{
			token.kind = .NOTE;
			advance_until_space (hooks, lexer);
		}
		set_token_end (lexer, *token);
	}
	else if peek_codepoint (hooks, lexer) == #char "$"
	{
		advance (hooks, lexer);
		if peek_codepoint (hooks, lexer) == #char "$"
			advance (hooks, lexer);
		if skip_identifier (hooks, lexer)
			token.kind = .POLYMORPHIC_ARGUMENT;
		else
			token.kind = .INVALID;
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

peek_codepoint :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, peek_offset := 0) -> u32 #must
{
	assert (offset + peek_offset < count);
	
	return buffer_get_codepoint (buffer_id, offset + peek_offset);
}

skip_spaces :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer) -> s64
{
	i := 0;
	while offset < count && is_space (peek_codepoint (hooks, lexer))
	{
		advance (hooks, lexer);
		i += 1;
	}
	
	return i;
}

skip_identifier :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer) -> s64
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

matches_string :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, str : string) -> bool #must
{
	if offset + str.count > count then return false;
	for i : 0..str.count - 1
	{
		if peek_codepoint (hooks, lexer, i) != str[i]
			return false;
	}
	
	return true;
}

advance_if_matches_string :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, str : string) -> bool
{
	if matches_string (hooks, lexer, str)
	{
		advance (hooks, lexer, str.count);
		
		return true;
	}
	
	return false;
}

matches_range :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, range : Rangei) -> bool #must
{
	if offset + length (range) > count then return false;
	for i : 0..length (range) - 1
	{
		if peek_codepoint (hooks, lexer, i) != buffer_get_codepoint (buffer_id, range.min + i)
			return false;
	}
	
	return true;
}

advance_if_matches_range :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, range : Rangei) -> bool
{
	if matches_range (hooks, lexer, range)
	{
		advance (hooks, lexer, length (range));
		
		return true;
	}
	
	return false;
}

matches_identifier :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, ident : string) -> bool #must
{
	if offset + ident.count > count then return false;
	for i : 0..ident.count - 1
	{
		if peek_codepoint (hooks, lexer, i) != ident[i]
			return false;
	}
	
	return offset + ident.count == count - 1 || !is_alpha_num (peek_codepoint (hooks, lexer, ident.count));
}

advance_if_matches_identifier :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, ident : string) -> bool
{
	if matches_identifier (hooks, lexer, ident)
	{
		advance (hooks, lexer, ident.count);
		
		return true;
	}
	
	return false;
}

matches_identifier_in_array :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, array : []string) -> bool #must, index : s64
{
	for array
	{
		if matches_identifier (hooks, lexer, it)
			return true, it_index;
	}
	
	return false, -1;
}

advance_if_matches_identifier_in_array :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer, array : []string) -> bool #must, index : s64
{
	for array
	{
		if advance_if_matches_identifier (hooks, lexer, it)
			return true, it_index;
	}
	
	return false, -1;
}

advance_until_space :: inline (using hooks : *Amber_Hooks, using lexer : *Jai_Lexer) -> s64
{
	i := 0;
	while offset < count && !is_space (peek_codepoint (hooks, lexer))
	{
		advance (hooks, lexer);
		i += 1;
	}
	
	return i;
}

advance :: (using hooks : *Amber_Hooks, lexer : *Jai_Lexer, count := 1) -> bool
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
		}
		lexer.offset += 1;
		lexer.column += 1;
		i += 1;
	}
	
	return true;
}
