#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_math.jai";
#load "amber_language.jai";

Jai_Lexer :: struct
{
	buffer_id : Buffer_ID;
	offset, count, line, column : s64;
	is_in_asm_block : bool;
	is_in_herestring : bool;
	herestring_end_word : Rangei;
	tokens : [..]Jai_Token;
}

Jai_Token :: struct
{
	Kind :: enum
	{
		UNKNOWN;
		INVALID;
		COMMENT;
		STRING_LITERAL;
		NUMBER_LITERAL;
		IDENTIFIER;
		KEYWORD;
		CONTROL_KEYWORD;
		STORAGE_TYPE_KEYWORD;
		TYPE_KEYWORD;
		FUNCTION_KEYWORD;
		COMPILER_DIRECTIVE;
		ASM_TYPE_KEYWORD;
		ASM_INSTRUCTION_KEYWORD;
		ASM_SIZE_KEYWORD;
		SYMBOL;
		EOI;
	}
	
	kind : Kind;
	l0, c0, l1, c1 : s64;
}

JAI_CONTROL_KEYWORDS :: string.[ "if", "ifx", "then", "else", "case", "for", "while", "break", "continue", "return", "using", "inline", "defer" ];
JAI_STORAGE_TYPE_KEYWORDS :: string.[ "struct", "union", "enum", "enum_flags" ];
JAI_TYPE_KEYWORDS :: string.[ "void", "u8", "u16", "u32", "u64", "s8", "s16", "s32", "s64", "int", "float32", "float64", "f32", "f64", "float", "bool", "string", "__reg" ];
JAI_FUNCTION_KEYWORDS :: string.[ "cast", "xx", "type_of", "type_info", "size_of", "align_of", "initializer_of", "is_constant" ];
JAI_OTHER_KEYWORDS :: string.[ "push_context", "context", "null", "true", "false", "it", "it_index", "no_check", "truncate", "no_dll", "stallable",
	"operator", "interface", "distinct", "isa" ];
JAI_COMPILER_DIRECTIVES :: string.[
	"import", "load", "foreign", "foreign_library", "foreign_system_library", "must", "no_abc", "insert", "insert_internal",
	"run", "char", "place", "through", "expand", "if", "scope_file", "scope_module", "scope_export", "assert", "bake", "bake_arguments", "bake_constants",
	"complete", "string", "no_reset", "dump", "code", "caller_location", "c_call", "c_callback", "module_parameters", "elsewhere", "placeholder", "intrinsic",
	"compiler", "symmetric", "modify", "cpp_return_type_is_non_pod", "cpp_method", "add_context", "dynamic_specialize", "specified", "filepath", "file", "line",
	"poke_name", "program_export", "procedure_of_call", "location", "type_info_none", "type_info_procedures_are_void_pointers", "type_info_no_size_complaint",
	"no_alias", "type", "deprecated", "align", "no_context", "runtime_support", "asm", "caller_code", "this", "no_padding"
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
	"int3",
	
];
JAI_ASM_SIZE_KEYWORDS :: string.[ "b", "w", "d", "q", "x", "y", "z" ];

#program_export
init_extension :: (id : Extension_ID, using amber : *Amber_Hooks) -> bool
{
	jai : Language;
	jai.extension_id = id;
	jai.name = "Jai";
	jai.associated_extensions = string.[ "jai" ];
	jai.process_buffer = jai_process_buffer;
	language_register (jai);
	
	return true;
}

#program_export
terminate_extension :: (using amber : *Amber_Hooks)
{
}

jai_process_buffer :: (using amber : *Amber_Hooks, buffer_id : Buffer_ID) -> bool
{
	if !buffer_is_dirty (buffer_id) then return false;
	lexer := get_pointer (*lexers, buffer_id);
	lexer.offset = 0;
	lexer.count  = buffer_get_length (buffer_id);
	lexer.line   = 1;
	lexer.column = 1;
	while true
	{
		token := read_next_token (lexer);
		push_into_array (*lexer.tokens, token);
		if token.kind == .EOI then break;
	}
	
	return true;
}

read_next_token :: (using amber : *Amber_Hooks, using lexer : *Jai_Lexer) -> Token
{
	token : Jai_Token;
	token.l0 = line;
	token.c0 = column;
	token.l1 = line;
	token.c1 = column;
	
	return token;
}

advance :: (using amber : *Amber_Hooks, using lexer : *Jai_Lexer, count := 1) -> bool
{
	if offset >= count
		return false;
	i := 0;
	while i < count && offset < count)
	{
		if buffer_get_codepoint (buffer_id, offset) == #char "\n"
		{
			line += 1;
			column = 0;
		}
		offset += 1;
		column += 1;
		i += 1;
	}
	
	return true;
}
