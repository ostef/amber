#import "Compiler";	// For code nodes
#import "Common";	// For alloc, free

Code_Builder :: struct
{
	count : s64;
	data  : *u8;
	allocated : s64;

	indentation_level : s64;
	line, column : s64;

	allocator : Allocator;
}

init_code_builder :: inline (builder : *Code_Builder, capacity : s64, allocator : Allocator)
{
	builder.count = 0;
	builder.data = alloc (capacity, allocator);
	builder.allocated = capacity;
	builder.indentation_level = 0;
	builder.line = 1;
	builder.column = 1;
	builder.allocator = allocator;
}

to_string :: inline (using builder : Code_Builder) -> string #must
{
	str : string = ---;
	str.data = data;
	str.count = count;

	return str;
}

indent :: inline (using builder : *Code_Builder)
{
	for 0..indentation_level - 1
		print_char_to_builder (builder, #char "\t");
}

grow_builder :: inline (using builder : *Code_Builder, additional_capacity : s64)
{
	if additional_capacity <= 0
		return;
	new_capacity := allocated + additional_capacity;
	new_data := alloc (new_capacity, allocator);
	memcpy (new_data, data, count);
	free (data, allocator);
	data = new_data;
	allocated = new_capacity;
}

print_char_to_builder :: inline (using builder : *Code_Builder, char : u8)
{
	if count >= allocated
		grow_builder (builder, allocated + 128);
	data[count] = char;
	count += 1;
	if char == #char "\n"
	{
		line += 1;
		column = 0;
	}
	column += 1;
}

print_escaped_char_to_builder :: inline (builder : *Code_Builder, char : u8)
{
	if char ==
	{
	case #char "\r";
		print_to_builder (builder, "\\r");
	case #char "\n";
		print_to_builder (builder, "\\n");
	case #char "\t";
		print_to_builder (builder, "\\t");
	case #char "\"";
		print_to_builder (builder, "\\\"");
	case #char "\\";
		print_to_builder (builder, "\\\\");
	case;
		print_char_to_builder (builder, char);
	}
}

print_escaped_string_to_builder :: (using builder : *Code_Builder, str : string)
{
	if count + str.count >= allocated
		grow_builder (builder, allocated + 128);
	print_char_to_builder (builder, #char "\"");
	for i : 0..str.count - 1
		print_escaped_char_to_builder (builder, str[i]);
	print_char_to_builder (builder, #char "\"");
}

print_to_builder :: inline (using builder : *Code_Builder, str : string)
{
	if count + str.count >= allocated
		grow_builder (builder, allocated + 128);
	for i : 0..str.count - 1
		print_char_to_builder (builder, str[i]);
}

print_to_builder :: inline (using builder : *Code_Builder, str : string, strs : ..string)
{
	print_to_builder (builder, str);
	for strs
		print_to_builder (builder, it);
}

print_line_to_builder :: inline (using builder : *Code_Builder, str : string)
{
	print_to_builder (builder, str);
	print_newline_to_builder (builder);
}

print_line_to_builder :: inline (using builder : *Code_Builder, str : string, strs : ..string)
{
	print_to_builder (builder, str);
	for strs
		print_to_builder (builder, it);
	print_newline_to_builder (builder);
}

print_newline_to_builder :: inline (using builder : *Code_Builder)
{
	print_char_to_builder (builder, #char "\n");
}

print_s64_to_builder :: inline (using builder : *Code_Builder, value : s64, base := 10)
{
	unsigned_value : u64 = xx value;
	if value < 0
	{
		unsigned_value = xx -value;
		print_char_to_builder (builder, #char "-");
	}
	print_u64_to_builder (builder, unsigned_value, base);
}

print_u64_to_builder :: inline (builder : *Code_Builder, value : u64, base := 10)
{
	assert (base > 1 && base <= 16, "Invalid base (got %, expected base in [2, 16]).", base);

	if base ==
	{
	case 2;  print_to_builder (builder, "0b");
	case 16; print_to_builder (builder, "0x");
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
		character_buffer[digit_count - 1 - i] = "0123456789abcdef"[digit];
		value /= xx base;
	}

	for i : 0..digit_count - 1
		print_char_to_builder (builder, character_buffer[i]);
}

code_print_identifier :: inline (builder : *Code_Builder, using ident : *Code_Ident)
{
	if flags & .DEFINES_POLYMORPH_VARIABLE
		print_to_builder (builder, "$");
	if flags & .HAS_SCOPE_MODIFIER
		print_to_builder (builder, "`");
	print_to_builder (builder, name);
}

code_print_literal :: (builder : *Code_Builder, using lit : *Code_Literal)
{
	if #complete value_type ==
	{
	case .UNINITIALIZED;
	case .NUMBER;
		base := 10;
		if numeric_flags & .BINARY
			base = 2;
		else if numeric_flags & .HEX
			base = 16;
		if numeric_flags & .FLOAT64
			//print_f64_to_builder (builder, _float64);
			print_to_builder (builder, "0.0");
		else if numeric_flags & .FLOAT
			//print_f32_to_builder (builder, _float32);
			print_to_builder (builder, "0.0");
		else if numeric_flags & .MINUS_SIGN
			print_s64_to_builder (builder, _s64, base);
		else
			print_u64_to_builder (builder, _u64, base);

	case .STRING;
		print_escaped_string_to_builder (builder, _string);

	case .TRUE;
		print_to_builder (builder, "true");

	case .FALSE;
		print_to_builder (builder, "false");

	case .ARRAY;
		info := array_literal_info;
		if info.element_type
			code_print_type_instantiation (builder, info.element_type);
		print_to_builder (builder, ".[");
		for info.array_members
		{
			if it_index != 0
				print_to_builder (builder, ", ");
			code_print_expression (builder, it);
		}
		print_to_builder (builder, "]");

	case .STRUCT;
		info := struct_literal_info;
		if info.type_expression
			code_print_expression (builder, info.type_expression);
		print_to_builder (builder, ".{");
		for info.arguments
		{
			if it_index != 0
				print_to_builder (builder, ", ");
			code_print_expression (builder, it);
		}
		print_to_builder (builder, "}");

	case .POINTER;
		info := pointer_literal_info;
		if #complete info.pointer_literal_type ==
		{
		case .CONSTANT_VALUE;
			if info.offset_from_symbol == 0
				print_to_builder (builder, "null");
			else
				print_s64_to_builder (builder, info.offset_from_symbol);	// @Todo (stefan): Print in hex.

		case .DATA_POINTER;
			code_print_literal (builder, info.string_or_array_literal);
		
		case .GLOBAL_SYMBOL;
			code_print_declaration (builder, info.global_symbol);
		}

	case .DATA_FIELD_PLUS_OFFSET;	// @Note (stefan): What is that ???
	}
}

code_print_procedure_header :: (builder : *Code_Builder, using header : *Code_Procedure_Header)
{
	print_to_builder (builder, "(");
	for decl : arguments
	{
		if it_index > 0
			print_to_builder (builder, ", ");
		code_print_declaration (builder, decl);
	}
	print_to_builder (builder, ")");
	for decl : returns
	{
		if it_index == 0
			print_to_builder (builder, " -> ");
		else
			print_to_builder (builder, ", ");
		code_print_declaration (builder, decl);
	}

	if procedure_flags & .DEPRECATED
	{
		print_to_builder (builder, "#deprecated ");
		if deprecation_string
			print_escaped_string_to_builder (builder, deprecation_string);
	}
	if procedure_flags & .SYNTACTICALLY_MARKED_AS_NO_CONTEXT
		print_to_builder (builder, "#no_context ");
	if procedure_flags & .DEBUG_DUMP
		print_to_builder (builder, "#dump ");
}

code_print_procedure_body :: (builder : *Code_Builder, using header : *Code_Procedure_Header)
{
	if modify_directives.count != 0
	{
		for modify : modify_directives
		{
			print_to_builder (builder, "#modify ");
			code_print_block (builder, modify.block);
		}
	}

	body := body_or_null;
	if body.block
	{
		print_to_builder (builder, " ");
		code_print_block (builder, body.block);
		print_newline_to_builder (builder);
	}
	else
	{
		print_line_to_builder (builder, ";");
	}
}

code_print_note :: inline (builder : *Code_Builder, using note : *Code_Note)
{
	string_literal := false;
	for i : 0..text.count - 1
	{
		char := text[i];
		if char ==
		{
		case #char "\r"; #through;
		case #char "\n"; #through;
		case #char "\t"; #through;
		case #char "\""; #through;
		case #char "\\";
			string_literal = true;
			
			break;
		}
	}

	print_to_builder (builder, "@");
	if string_literal
		print_escaped_string_to_builder (builder, text);
	else
		print_to_builder (builder, text);
}

code_print_struct :: (builder : *Code_Builder, using code : *Code_Struct)
{
	if struct_flags & .UNION
		print_to_builder (builder, "union");
	else
		print_to_builder (builder, "struct");
	
	if constants_block
	{
		print_to_builder (builder, "(");
		code_print_argument_decls (builder, constants_block.members);
		print_to_builder (builder, ")");
	}
	print_to_builder (builder, " ");
	
	for notes
	{
		code_print_note (builder, it);
		print_to_builder (builder, " ");
	}
	
	if block
		code_print_block (builder, block);
}

code_print_enum :: (builder : *Code_Builder, using code : *Code_Enum)
{
	if is_flags
		print_to_builder (builder, "enum_flags ");
	else
		print_to_builder (builder, "enum ");
	if marked_as_complete
		print_to_builder (builder, "#complete ");
	if marked_as_specified
		print_to_builder (builder, "#specified ");
	if internal_type_inst
	{
		code_print_type_instantiation (builder, internal_type_inst);
		print_to_builder (builder, " ");
	}
	if block
		code_print_block (builder, block);
}

code_print_scope_entry :: (builder : *Code_Builder, using entry : *Code_Scope_Entry)
{
	if entry.kind ==
	{
	case .DECLARATION;
		code_print_declaration (builder, cast (*Code_Declaration) entry);
	case .COMPOUND_DECLARATION;
		code_print_compound_declaration (builder, cast (*Code_Compound_Declaration) entry);
	}
}

code_print_sequence :: (builder : *Code_Builder, using sequence : *Code_Sequence)
{
	for expressions
	{
		code_print_expression (builder, it);
		code_print_semicolon (builder, it);
	}
}

code_print_declaration :: (builder : *Code_Builder, using decl : *Code_Declaration)
{
	if flags & .IS_ITERATOR
		return;
	if flags & .IS_IMPORTED
		return;

	if flags & .PROGRAM_EXPORT
	{
		print_to_builder (builder, "#program_export ");
		if program_export_name
		{
			print_to_builder (builder, "\"");
			print_to_builder (builder, <<program_export_name);
			print_to_builder (builder, "\" ");
		}
	}
	if flags & .NO_RESET
		print_to_builder (builder, "#no_reset ");
	if flags & .IS_MARKED_AS_USING
		print_to_builder (builder, "using ");
	
	if name
	{
		if flags & .AUTO_VALUE_BAKE_IS_REQUIRED
			print_to_builder (builder, "$");
		else if flags & .AUTO_VALUE_BAKE
			print_to_builder (builder, "$$");
		print_to_builder (builder, decl.name);
		print_to_builder (builder, " :");
		if type_inst
			print_to_builder (builder, " ");
	}
	if type_inst
	{
		code_print_type_instantiation (builder, type_inst);
		if expression
			print_to_builder (builder, " ");
	}
	
	if expression
	{
		if flags & .IS_CONSTANT
			print_to_builder (builder, ": ");
		else
			print_to_builder (builder, "= ");

		code_print_expression (builder, expression);
	}

	if flags & .MUST_BE_RECEIVED
		print_to_builder (builder, " #must");

	for notes
	{
		print_to_builder (builder, " ");
		code_print_note (builder, it);
	}
}

code_print_compound_declaration :: (builder : *Code_Builder, using compound : *Code_Compound_Declaration)
{
	if alignment_expression
	{
		print_to_builder (builder, "#align (");
		code_print_expression (builder, alignment_expression);
		print_to_builder (builder, ")");
	}
	if declaration_properties.flags & .IS_MARKED_AS_USING
		print_to_builder (builder, "using ");
	code_print_comma_separated_arguments (builder, comma_separated_assignment);
	code_print_declaration (builder, declaration_properties);
	for notes
	{
		print_to_builder (builder, " ");
		code_print_note (builder, it);
	}
}

code_print_arguments :: (builder : *Code_Builder, args : []Code_Argument)
{
	for args
	{
		if it_index != 0
			print_to_builder (builder, ", ");
		if it.name
		{
			code_print_identifier (builder, it.name);
			print_to_builder (builder, " = ");
		}
		code_print_expression (builder, it.expression);
	}
}

code_print_argument_decls :: (builder : *Code_Builder, args : []*Code_Scope_Entry)
{
	for args
	{
		if it_index != 0
			print_to_builder (builder, ", ");
		code_print_declaration (builder, cast (*Code_Declaration) it);
	}
}

code_print_comma_separated_arguments :: (builder : *Code_Builder, using args : *Code_Comma_Separated_Arguments)
{
	for expressions
	{
		if it_index != 0
			print_to_builder (builder, ", ");
		code_print_expression (builder, it);
	}
}

code_print_type_instantiation :: (builder : *Code_Builder, using inst : *Code_Type_Instantiation)
{
	if inst_flags & .TYPE_DIRECTIVE
	{
		print_to_builder (builder, "#type");
		if inst_flags & .TYPE_DIRECTIVE_DISTINCT
			print_to_builder (builder, ", distinct");
		else if inst_flags & .TYPE_DIRECTIVE_ISA
			print_to_builder (builder, ", isa");
		print_to_builder (builder, " ");
		if type_directive_target
			code_print_type_instantiation (builder, type_directive_target);
	}

	if pointer_to
	{
		print_to_builder (builder, "*");
		code_print_type_instantiation (builder, pointer_to);
	}
	else if array_element_type
	{
		if inst_flags & .VARARGS
			print_to_builder (builder, "..");
		else if inst_flags & .RESIZABLE
			print_to_builder (builder, "[..]");
		else if array_dimension
		{
			print_to_builder (builder, "[");
			code_print_expression (builder, array_dimension);
			print_to_builder (builder, "]");
		}
		else
			print_to_builder (builder, "[]");
		code_print_type_instantiation (builder, array_element_type);
	}
	else if type_valued_expression
	{
		code_print_expression (builder, type_valued_expression);
	}
}

code_print_block :: (builder : *Code_Builder, using block : *Code_Block)
{
	if block_flags & .BLOCK_NO_ARRAY_BOUNDS_CHECK
		print_to_builder (builder, "#no_abc ");
	print_braces := cast (bool) (node_flags & .IS_PARENTHESIZED) || statements.count > 1 || members.count > 1;
	if print_braces
	{
		print_to_builder (builder, "\n{\n");
		builder.indentation_level += 1;
	}
	else
		print_to_builder (builder, " ");
	if block_type != .IMPERATIVE
	{
		for members
		{
			if print_braces
				indent (builder);
			code_print_scope_entry (builder, it);
			root_expr : *Code_Node;
			if it.kind == .DECLARATION
				root_expr = (cast (*Code_Declaration) it).expression;
			else if it.kind == .COMPOUND_DECLARATION
				root_expr = (cast (*Code_Compound_Declaration) it).declaration_properties.expression;
			code_print_semicolon (builder, root_expr);
		}
	}
	
	for statements
	{
		if it.node_flags & .CREATED_BY_DESUGARING
			continue;
		if block_type == .DATA_DECLARATIONS
		{
			if it.kind == .DECLARATION
				continue;
			if it.kind == .DIRECTIVE_STATIC_IF
				continue;
		}
		if it.node_flags & .STATEMENT_IS_DEFERRED
			print_to_builder (builder, "defer ");
		if print_braces
			indent (builder);
		code_print_expression (builder, it);
		code_print_semicolon (builder, it);
	}

	if print_braces
	{
		builder.indentation_level -= 1;
		indent (builder);
		print_to_builder (builder, "}\n");
	}
	else
		print_to_builder (builder, " ");
}

code_print_operator :: inline (builder : *Code_Builder, op : Operator_Type.loose)
{
	using Operator_Type;
	if op ==
	{
	case xx PLUS_EQUALS;
		print_to_builder (builder, "+=");
	case xx MINUS_EQUALS;
		print_to_builder (builder, "-=");
	case xx TIMES_EQUALS;
		print_to_builder (builder, "*=");
	case xx DIV_EQUALS;
		print_to_builder (builder, "/=");
	case xx MOD_EQUALS;
		print_to_builder (builder, "%=");
	case xx IS_EQUAL;
		print_to_builder (builder, "==");
	case xx IS_NOT_EQUAL;
		print_to_builder (builder, "!=");
	case xx LOGICAL_AND;
		print_to_builder (builder, "&&");
	case xx LOGICAL_OR;
		print_to_builder (builder, "||");
	case xx LESS_EQUALS;
		print_to_builder (builder, "<=");
	case xx GREATER_EQUALS;
		print_to_builder (builder, ">=");
	case xx SHIFT_LEFT;
		print_to_builder (builder, "<<");
	case xx SHIFT_RIGHT;
		print_to_builder (builder, ">>");
	case xx ROTATE_LEFT;
		print_to_builder (builder, "<<<");
	case xx ROTATE_RIGHT;
		print_to_builder (builder, ">>>");
	case xx SHIFT_LEFT_EQUALS;
		print_to_builder (builder, "<<=");
	case xx SHIFT_RIGHT_EQUALS;
		print_to_builder (builder, ">>=");
	case xx ROTATE_LEFT_EQUALS;
		print_to_builder (builder, "<<<=");
	case xx ROTATE_RIGHT_EQUALS;
		print_to_builder (builder, ">>>=");
	case xx BITWISE_AND_EQUALS;
		print_to_builder (builder, "&=");
	case xx BITWISE_OR_EQUALS;
		print_to_builder (builder, "|=");
	case xx BITWISE_XOR_EQUALS;
		print_to_builder (builder, "^=");
	case xx LOGICAL_AND_EQUALS;
		print_to_builder (builder, "&&=");
	case xx LOGICAL_OR_EQUALS;
		print_to_builder (builder, "||=");
	case xx POINTER_DEREFERENCE;
		print_to_builder (builder, "<<");
	case;
		print_char_to_builder (builder, cast, no_check (u8) op);
	}
}

code_print_unary_operator :: (builder : *Code_Builder, using op : *Code_Unary_Operator)
{
	code_print_operator (builder, operator_type);
	code_print_expression (builder, subexpression);
}

code_print_binary_operator :: (builder : *Code_Builder, using op : *Code_Binary_Operator)
{
	code_print_expression (builder, left);
	if operator_type != xx Operator_Type.ARRAY_SUBSCRIPT
	{
		if operator_type != #char "."
			print_to_builder (builder, " ");
		code_print_operator (builder, operator_type);
		if operator_type != #char "."
			print_to_builder (builder, " ");
	}
	else
		print_to_builder (builder, "[");
	code_print_expression (builder, right);
	if operator_type == xx Operator_Type.ARRAY_SUBSCRIPT
		print_to_builder (builder, "]");
}

code_print_if :: (builder : *Code_Builder, using code : *Code_If)
{
	if is_ifx
		print_to_builder (builder, "ifx ");
	else
		print_to_builder (builder, "if ");
	if marked_as_complete
		print_to_builder (builder, "#complete ");
	code_print_expression (builder, condition);
	if is_switch_statement
		print_to_builder (builder, " ==");
	if then_block
	{
		if is_ifx
			print_to_builder (builder, " then ");
		else
			print_to_builder (builder, " ");
		code_print_block (builder, then_block);
	}
	if else_block
	{
		print_to_builder (builder, " else ");
		code_print_block (builder, else_block);
	}
}

code_print_while :: (builder : *Code_Builder, using code : *Code_While)
{
	print_to_builder (builder, "while ");
	code_print_expression (builder, condition);
	print_to_builder (builder, " ");
	code_print_block (builder, block);
}

code_print_for :: (builder : *Code_Builder, using code : *Code_For)
{
	print_to_builder (builder, "for ");
	if want_pointer_expression
	{
		print_to_builder (builder, "*=");
		code_print_expression (builder, want_pointer_expression);
		print_to_builder (builder, " ");
	}
	else if takes_pointer
		print_to_builder (builder, "* ");


	if want_reverse_expression
	{
		print_to_builder (builder, "*=");
		code_print_expression (builder, want_reverse_expression);
		print_to_builder (builder, " ");
	}
	else if downward	// @Note (stefan): Why 'downward' and not 'reverse' ?
		print_to_builder (builder, "* ");
	
	// Print it and it_index identifier
	if ident_decl
	{
		print_to_builder (builder, ident_decl.name);
		print_to_builder (builder, " ");
	}
	if index_decl
	{
		print_to_builder (builder, ", ");
		print_to_builder (builder, index_decl.name);
		print_to_builder (builder, " ");
	}
	if ident_decl || index_decl
		print_to_builder (builder, ": ");
	
	code_print_expression (builder, iteration_expression);
	if iteration_expression_right
	{
		print_to_builder (builder, "..");
		code_print_expression (builder, iteration_expression_right);
	}
	print_to_builder (builder, " ");
	code_print_block (builder, block);
}

code_print_case :: (builder : *Code_Builder, using code : *Code_Case)
{
	print_to_builder (builder, "case");
	if condition
	{
		print_to_builder (builder, " ");
		code_print_expression (builder, condition);
	}
	print_to_builder (builder, ";");
	indent (builder);
	code_print_block (builder, then_block);
	if marked_as_fallthrough
		print_line_to_builder (builder, "#through;");
}

code_print_loop_control :: (builder : *Code_Builder, using control : *Code_Loop_Control)
{
	if #complete control_type ==
	{
	case .BREAK;
		print_to_builder (builder, "break");
	case .CONTINUE;
		print_to_builder (builder, "continue");
	case .REMOVE;
		print_to_builder (builder, "remove");
	}
	if target_ident
		code_print_identifier (builder, target_ident);
}

code_print_cast :: (builder : *Code_Builder, using expr : *Code_Cast)
{
	if cast_flags & .IS_AUTO
	{
		print_to_builder (builder, "xx ");
	}
	else if (cast_flags & .IS_IMPLICIT) == 0
	{
		print_to_builder (builder, "cast");
		if cast_flags & .NO_BOUNDS_CHECK
			print_to_builder (builder, ", no_check");
		if cast_flags & .TRUNCATE
			print_to_builder (builder, ", trunc");
		print_to_builder (builder, " (");
		code_print_type_instantiation (builder, target_type);
		print_to_builder (builder, ") ");
	}
	code_print_expression (builder, expression);
}

code_print_return :: (builder : *Code_Builder, using ret : *Code_Return)
{
	if is_backticked
		print_to_builder (builder, "`");
	if arguments_unsorted.count == 0
	{
		print_to_builder (builder, "return");
	}
	else
	{
		print_to_builder (builder, "return ");
		code_print_arguments (builder, arguments_unsorted);
	}
}

code_print_procedure_call :: (builder : *Code_Builder, using call : *Code_Procedure_Call)
{
	code_print_expression (builder, procedure_expression);
	print_to_builder (builder, " (");
	code_print_arguments (builder, arguments_unsorted);
	print_to_builder (builder, ")");
}

code_print_compiler_query :: (builder : *Code_Builder, using expr : *Code_Size_Or_Type_Info)
{
	if #complete query_kind ==
	{
	case .SIZE_OF;
		print_to_builder (builder, "size_of (");
		code_print_type_instantiation (builder, type_to_query);
		print_to_builder (builder, ")");
	case .TYPE_OF;
		print_to_builder (builder, "type_of (");
		code_print_expression (builder, type_of_expression);
		print_to_builder (builder, ")");
	case .TYPE_INFO;
		print_to_builder (builder, "type_info (");
		code_print_type_instantiation (builder, type_to_query);
		print_to_builder (builder, ")");
	case .INITIALIZER_OF;
		print_to_builder (builder, "initializer_of (");
		code_print_type_instantiation (builder, type_to_query);
		print_to_builder (builder, ")");
	case .IS_CONSTANT;
		print_to_builder (builder, "is_constant (");
		code_print_expression (builder, type_of_expression);
		print_to_builder (builder, ")");
	}
}

code_print_directive_import :: (builder : *Code_Builder, using directive : *Code_Directive_Import)
{
	print_to_builder (builder, "#import");
	if flags & .UNSHARED
		print_to_builder (builder, ", unshared");
	print_to_builder (builder, " ");
	print_escaped_string_to_builder (builder, name);
	if module_parameters_call
	{
		print_to_builder (builder, "(");
		code_print_arguments (builder, module_parameters_call.arguments_unsorted);
		print_to_builder (builder, ")");
	}
	if program_parameters_call
	{
		print_to_builder (builder, "(");
		code_print_arguments (builder, program_parameters_call.arguments_unsorted);
		print_to_builder (builder, ")");
	}
	print_line_to_builder (builder, ";");
}

code_print_directive_through :: (builder : *Code_Builder, using directive : *Code_Directive_Through)
{
	print_to_builder (builder, "#through");
}

code_print_directive_run :: (builder : *Code_Builder, using directive : *Code_Directive_Run)
{
	block := procedure.body_or_null.block;
	if flags & .ASSERTION
		print_to_builder (builder, "#assert");
	else
		print_to_builder (builder, "#run");
	if flags & .STALLABLE
		print_to_builder (builder, ", stallable");
	print_to_builder (builder, " ");
	// @Note (stefan): Shouldn't we print the whole block ?
	code_print_expression (builder, block.statements[0]);
}

code_print_directive_code :: (builder : *Code_Builder, using directive : *Code_Directive_Code)
{
	if code_flags & .NULL || !expression
		print_to_builder (builder, "#code, null");
	else
	{
		print_to_builder (builder, "#code ");
		code_print_expression (builder, expression);
	}
}

code_print_directive_bake :: (builder : *Code_Builder, using directive : *Code_Directive_Bake)
{
	if #complete bake_type ==
	{
	case .CONSTANTS_BAKE;
		print_to_builder (builder, "#bake_constants ");
	case .PARAMETER_VALUE_BAKE;
		print_to_builder (builder, "#bake_arguments ");
	case .DYNAMIC_SPECIALIZE;
		print_to_builder (builder, "#dynamic_specialize ");
	}
	code_print_procedure_call (builder, procedure_call);
}

code_print_directive_modify :: (builder : *Code_Builder, using directive : *Code_Directive_Modify)
{
	print_to_builder (builder, "#modify ");
	code_print_block (builder, block);
}
code_print_directive_foreign_library :: (builder : *Code_Builder, using directive : *Code_Directive_Foreign_Library)
{
	print_line_to_builder (builder, "#foreign_library \"%\";", name);
}

code_print_push_context :: (builder : *Code_Builder, using push : *Code_Push_Context)
{
	print_to_builder (builder, "push_context ");
	code_print_expression (builder, to_push);
	print_to_builder (builder, " ");
	code_print_block (builder, block);
}

code_print_directive_scope :: (builder : *Code_Builder, using directive : *Code_Directive_Scope)
{
	if #complete scope_type ==
	{
	case .EXPORT;
		print_to_builder (builder, "#scope_export");
	case .FILE;
		print_to_builder (builder, "#scope_file");
	case .INTERNAL;
		print_to_builder (builder, "#scope_module");
	}
}

code_print_directive_static_if :: (builder : *Code_Builder, using directive : *Code_Directive_Static_If)
{
	if is_ifx
		print_to_builder (builder, "#ifx ");
	else
		print_to_builder (builder, "#if ");
	code_print_expression (builder, condition);
	if then_block
		code_print_block (builder, then_block);
	if else_block
	{
		print_to_builder (builder, " else ");
		code_print_block (builder, else_block);
	}
}

code_print_directive_location :: (builder : *Code_Builder, using directive : *Code_Directive_Location)
{
	if is_caller_location
		print_to_builder (builder, "#caller_location");
	else
	{
		print_to_builder (builder, "#location (");
		if expression
			code_print_expression (builder, expression);
		print_to_builder (builder, ")");
	}
}

code_print_defer :: (builder : *Code_Builder, using code : *Code_Defer)
{
	if is_backticked
		print_to_builder (builder, "`");
	print_to_builder (builder, "defer ");
	code_print_block (builder, block);
}

code_print_using :: (builder : *Code_Builder, using code : *Code_Using)
{
	print_to_builder (builder, "using ");
	code_print_expression (builder, expression);
}

code_print_placeholder :: (builder : *Code_Builder, using placeholder : *Code_Placeholder)
{
	// @Note (stefan): Code_Placeholder has an ident member, but it's commented out.
	print_to_builder (builder, "#placeholder");
}

code_print_directive_insert :: (builder : *Code_Builder, using directive : *Code_Directive_Insert)
{
	if is_internal
		print_to_builder (builder, "#insert_internal ");
	else
		print_to_builder (builder, "#insert ");
	code_print_expression (builder, expression);
}

code_print_expression :: (builder : *Code_Builder, using expr : *Code_Node)
{
	assert (expr != null, "Expression was null.");
	// Don't print parenthesis around blocks. We print braces instead, when
	// calling code_print_block.
	if (node_flags & .IS_PARENTHESIZED) && kind != .BLOCK
		print_to_builder (builder, "(");
	defer
	{
		if (node_flags & .IS_PARENTHESIZED) && kind != .BLOCK
			print_to_builder (builder, ")");
	}

	if #complete kind ==
	{
	case .UNINITIALIZED;
	case .BLOCK;
		code_print_block (builder, cast (*Code_Block) expr);
	case .LITERAL;
		code_print_literal (builder, cast (*Code_Literal) expr);
	case .IDENT;
		code_print_identifier (builder, cast (*Code_Ident) expr);
	case .UNARY_OPERATOR;
		code_print_unary_operator (builder, cast (*Code_Unary_Operator) expr);
	case .BINARY_OPERATOR;
		code_print_binary_operator (builder, cast (*Code_Binary_Operator) expr);
	case .PROCEDURE_BODY;
		code_print_procedure_body (builder, (cast (*Code_Procedure_Body) expr).header);
	case .PROCEDURE_CALL;
		code_print_procedure_call (builder, cast (*Code_Procedure_Call) expr);
	case .CONTEXT;
	case .WHILE;
		code_print_while (builder, cast (*Code_While) expr);
	case .IF;
		code_print_if (builder, cast (*Code_If) expr);
	case .LOOP_CONTROL;
		code_print_loop_control (builder, cast (*Code_Loop_Control) expr);
	case .CASE;
		code_print_case (builder, cast (*Code_Case) expr);
	case .REMOVE;
		// @Note (stefan): This is probably unused or deprecated, because Code_Loop_Control already handles remove.
	case .RETURN;
		code_print_return (builder, cast (*Code_Return) expr);
	case .FOR;
		code_print_for (builder, cast (*Code_For) expr);
	case .TYPE_DEFINITION;
	case .TYPE_INSTANTIATION;
		code_print_type_instantiation (builder, cast (*Code_Type_Instantiation) expr);
	case .ENUM;
		code_print_enum (builder, cast (*Code_Enum) expr);
	case .PROCEDURE_HEADER;
		code_print_procedure_header (builder, cast (*Code_Procedure_Header) expr);
	case .STRUCT;
		code_print_struct (builder, cast (*Code_Struct) expr);
	case .COMMA_SEPARATED_ARGUMENTS;
		code_print_comma_separated_arguments (builder, cast (*Code_Comma_Separated_Arguments) expr);
	case .EXTRACT;
	case .SEQUENCE;
		code_print_sequence (builder, cast (*Code_Sequence) expr);
	case .MAKE_VARARGS;
	case .DECLARATION;
		code_print_declaration (builder, cast (*Code_Declaration) expr);
	case .CAST;
		code_print_cast (builder, cast (*Code_Cast) expr);
	case .DIRECTIVE_IMPORT;
		code_print_directive_import (builder, cast (*Code_Directive_Import) expr);
	case .DIRECTIVE_THIS;
		print_to_builder (builder, "#this");
	case .DIRECTIVE_THROUGH;
		code_print_directive_through (builder, cast (*Code_Directive_Through) expr);
	case .DIRECTIVE_LOAD;
		// @Note (stefan): This does not seem to be printable. There is no Code_Directive_Load...
	case .DIRECTIVE_RUN;
		code_print_directive_run (builder, cast (*Code_Directive_Run) expr);
	case .DIRECTIVE_CODE;
		code_print_directive_code (builder, cast (*Code_Directive_Code) expr);
	case .DIRECTIVE_POKE_NAME;
	case .ASM;
	case .DIRECTIVE_BAKE;
		code_print_directive_bake (builder, cast (*Code_Directive_Bake) expr);
	case .DIRECTIVE_MODIFY;
		code_print_directive_modify (builder, cast (*Code_Directive_Modify) expr);
	case .DIRECTIVE_FOREIGN_LIBRARY;
		code_print_directive_foreign_library (builder, cast (*Code_Directive_Foreign_Library) expr);
	case .SIZE_OR_TYPE_INFO;
		code_print_compiler_query (builder, cast (*Code_Size_Or_Type_Info) expr);
	case .PUSH_CONTEXT;
		code_print_push_context (builder, cast (*Code_Push_Context) expr);
	case .NOTE;
		code_print_note (builder, cast (*Code_Note) expr);
	case .DIRECTIVE_PLACE;
	case .DIRECTIVE_SCOPE;
		code_print_directive_scope (builder, cast (*Code_Directive_Scope) expr);
	case .DIRECTIVE_STATIC_IF;
		code_print_directive_static_if (builder, cast (*Code_Directive_Static_If) expr);
	case .DIRECTIVE_LOCATION;
		code_print_directive_location (builder, cast (*Code_Directive_Location) expr);
	case .DIRECTIVE_ALIGN;
	case .DIRECTIVE_ADD_CONTEXT;
	case .COMPOUND_DECLARATION;
		code_print_compound_declaration (builder, cast (*Code_Compound_Declaration) expr);
	case .DEFER;
		code_print_defer (builder, cast (*Code_Defer) expr);
	case .USING;
		code_print_using (builder, cast (*Code_Using) expr);
	case .PLACEHOLDER;
		code_print_placeholder (builder, cast (*Code_Placeholder) expr);
	case .DIRECTIVE_INSERT;
		code_print_directive_insert (builder, cast (*Code_Directive_Insert) expr);
	}
}

code_print_semicolon :: inline (builder : *Code_Builder, using expr : *Code_Node)
{
	if !expr
	{
		print_line_to_builder (builder, ";");
	}
	else if kind ==
	{
	case .PROCEDURE_HEADER;     #through;
	case .PROCEDURE_BODY;       #through;
	case .IF;                   #through;
	case .CASE;                 #through;
	case .DIRECTIVE_STATIC_IF;  #through;
	case .WHILE;                #through;
	case .FOR;                  #through;
	case .BLOCK; 
		print_newline_to_builder (builder);
	case;
		print_line_to_builder (builder, ";");
	}
}
