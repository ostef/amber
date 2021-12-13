// Generate Markdown files from the .amber_doc files and the
// source code data gathered from the metaprogram.

#import "Lexer";

Doc_File :: struct
{
	Entry :: struct
	{
		Kind :: enum
		{
			UNKNOWN :: 0;
			PROC    :: 1;
			STRUCT  :: 2;
			ENUM    :: 3;
		}

		Name_Desc :: struct
		{
			name : string;
			desc : string;
		}

		kind : Kind;
		using name_desc : Name_Desc;
		params  : [..]Name_Desc;
		members : [..]Name_Desc;
		returns : [..]Name_Desc;
	}

	name : string;
	entries : [..]Entry;
}

parse_doc_file :: (filename : string, using doc : *Doc_File) -> bool
{
	lexer : Lexer;
	file_contents, ok := read_entire_file (filename, HEAP);
	if !ok then return false;
	lexer_init (*lexer, filename, file_contents);

	// Parse name
	lexer_skip_spaces (*lexer);
	if !lexer_advance_if_matches_string (*lexer, "@name:")
		return lexer_error (*lexer, "Expected '@name:'.");
	lexer_skip_spaces (*lexer);
	name.data = lexer.curr;
	name.count = 0;
	while lexer_is_valid (*lexer) && <<lexer.curr != #char "\n"
		lexer_advance (*lexer);
	name.count = lexer.curr - name.data;
	name = trim_spaces_at_ends (name);
	if name.count == 0
		return lexer_error (*lexer, "Could not parse name.");
	init_array (*entries, 100, HEAP);
	while lexer_is_valid (*lexer)
	{
		entry := push_into_array (*entries);
		lexer_skip_spaces (*lexer);
		if !lexer_is_valid (*lexer)
			break;
		if !lexer_advance_if_matches_string (*lexer, "---")
			return lexer_error (*lexer, "Expected '---'.");
		lexer_advance_to_next_line (*lexer);
		lexer_skip_spaces (*lexer);
		if lexer_advance_if_matches_string (*lexer, "@proc:")
			entry.kind = .PROC;
		else if lexer_advance_if_matches_string (*lexer, "@struct:")
			entry.kind = .STRUCT;
		else if lexer_advance_if_matches_string (*lexer, "@enum:")
			entry.kind = .ENUM;
		else
			return lexer_error (*lexer, "Expected '@proc', '@struct' or '@enum', got '%'.", lexer_get_next_line (lexer));
		lexer_skip_spaces (*lexer);
		// Parse name
		entry.name.data = lexer.curr;
		while lexer_is_valid (*lexer) && is_alpha_num (<<lexer.curr)
			lexer_advance (*lexer);
		entry.name.count = lexer.curr - entry.name.data;
		if entry.name.count == 0
			return lexer_error (*lexer, "Could not parse % name.", entry.kind);
		lexer_skip_spaces (*lexer);
		// Parse description
		if lexer_advance_if_matches_string (*lexer, "@desc:")
		{
			entry.desc.data = lexer.curr;
			lexer_advance_to_next_line (*lexer);
			while lexer_is_valid (*lexer) && <<lexer.curr != #char "@" && !lexer_matches_string (*lexer, "---")
				lexer_advance_to_next_line (*lexer);
			entry.desc.count = lexer.curr - entry.desc.data;
			entry.desc = trim_spaces_at_ends (entry.desc);
			if entry.desc.count == 0
				return lexer_error (*lexer, "Could not parse % description.", entry.name);
		}

		// Parse parameters
		init_array (*entry.params, 8, HEAP);
		while lexer_is_valid (*lexer)
		{
			if !lexer_advance_if_matches_string (*lexer, "@param")
				break;
		
			lexer_skip_spaces (*lexer);
			param := push_into_array (*entry.params);
			// Parse parameter name
			param.name.data = lexer.curr;
			while lexer_is_valid (*lexer) && <<lexer.curr != #char ":"
				lexer_advance (*lexer);
			param.name.count = lexer.curr - param.name.data;
			if param.name.count == 0
				return lexer_error (*lexer, "Could not parse param name.");
			lexer_advance (*lexer);
			// Parse parameter description
			param.desc.data = lexer.curr;
			lexer_advance_to_next_line (*lexer);
			while lexer_is_valid (*lexer) && <<lexer.curr != #char "@" && !lexer_matches_string (*lexer, "---")
				lexer_advance_to_next_line (*lexer);
			param.desc.count = lexer.curr - param.desc.data;
			param.desc = trim_spaces_at_ends (param.desc);
			if param.desc.count == 0
				return lexer_error (*lexer, "Could not parse param % description.", param.name);
		}

		// Parse members
		init_array (*entry.members, 8, HEAP);
		while lexer_is_valid (*lexer)
		{
			if !lexer_advance_if_matches_string (*lexer, "@member")
				break;
		
			lexer_skip_spaces (*lexer);
			member := push_into_array (*entry.members);
			// Parse member name
			member.name.data = lexer.curr;
			while lexer_is_valid (*lexer) && <<lexer.curr != #char ":"
				lexer_advance (*lexer);
			member.name.count = lexer.curr - member.name.data;
			if member.name.count == 0
				return lexer_error (*lexer, "Could not parse member name.");
			lexer_advance (*lexer);
			// Parse member description
			member.desc.data = lexer.curr;
			lexer_advance_to_next_line (*lexer);
			while lexer_is_valid (*lexer) && <<lexer.curr != #char "@" && !lexer_matches_string (*lexer, "---")
				lexer_advance_to_next_line (*lexer);
			member.desc.count = lexer.curr - member.desc.data;
			member.desc = trim_spaces_at_ends (member.desc);
			if member.desc.count == 0
				return lexer_error (*lexer, "Could not parse member % description.", member.name);
		}

		// Parse returns
		init_array (*entry.returns, 8, HEAP);
		while lexer_is_valid (*lexer)
		{
			if !lexer_advance_if_matches_string (*lexer, "@return")
				break;
		
			lexer_skip_spaces (*lexer);
			ret := push_into_array (*entry.returns);
			// Parse return name
			ret.name.data = lexer.curr;
			while lexer_is_valid (*lexer) && <<lexer.curr != #char ":"
				lexer_advance (*lexer);
			ret.name.count = lexer.curr - ret.name.data;
			lexer_advance (*lexer);
			// Parse return description
			ret.desc.data = lexer.curr;
			lexer_advance_to_next_line (*lexer);
			while lexer_is_valid (*lexer) && <<lexer.curr != #char "@" && !lexer_matches_string (*lexer, "---")
				lexer_advance_to_next_line (*lexer);
			ret.desc.count = lexer.curr - ret.desc.data;
			ret.desc = trim_spaces_at_ends (ret.desc);
			if ret.desc.count == 0
				return lexer_error (*lexer, "Could not parse return % description.", ret.name);
		}
	}

	return true;
}

generate_markdown :: (builder : *String_Builder, using doc : Doc_File)
{
	pr :: print_to_builder;
	ln :: print_line_to_builder;
	nl :: print_newline_to_builder;

	ln (builder, "# %", name);
	nl (builder);

	for entries
	{
		if it_index != 0
		{
			nl (builder);
			ln (builder, "---");
			nl (builder);
		}
		generate_markdown (builder, it);
	}
}

generate_markdown :: (builder : *String_Builder, using entry : Doc_File.Entry)
{
	pr :: print_to_builder;
	ln :: print_line_to_builder;
	nl :: print_newline_to_builder;

	ln (builder, "<h2 id=\"%\">", name);
	if #complete kind ==
	{
	case .UNKNOWN;
		return;

	case .PROC;
		ln (builder, "Procedure:");

	case .STRUCT;
		ln (builder, "Struct:");

	case .ENUM;
		ln (builder, "Enum:");
	}
	ln (builder, "</h2>");
	nl (builder);

	ln (builder, "```jai");
	// @Todo (stefan): Print declaration + filename + line.
	if kind == .PROC
	{
		header : *Compiler.Code_Procedure_Header;
		for amber_api_procedures
		{
			if it.name == name
			{
				header = it;

				break;
			}
		}

		if header
		{
			print_procedure_header_to_builder (builder, header);
			nl (builder);
		}
		else
		{
			ln (builder, "// Could not find API procedure declaration.");
		}
	}
	else
		ln (builder, "// Declaration goes here");
	
	ln (builder, "```");
	nl (builder);

	ln (builder, "## Description:");
	ln (builder, desc);

	if params.count > 0
	{
		nl (builder);
		ln (builder, "## Params:");
	}
	for params
	{
		pr (builder, "**");
		pr (builder, it.name);
		pr (builder, "** ");
		ln (builder, "%  ", it.desc);
	}

	if members.count > 0
	{
		nl (builder);
		ln (builder, "## Members:");
	}
	for members
	{
		pr (builder, "**");
		pr (builder, it.name);
		pr (builder, "** ");
		ln (builder, "%  ", it.desc);
	}

	if returns.count > 0
	{
		nl (builder);
		ln (builder, "## Returns:");
	}
	for returns
	{
		if it.name
		{
			pr (builder, "**");
			ln (builder, it.name);
			pr (builder, "** ");
		}
		
		ln (builder, "%  ", it.desc);
	}
}

print_procedure_header_to_builder :: (builder : *String_Builder, header : *Compiler.Code_Procedure_Header)
{
	print_to_builder (builder, header.name);
	print_to_builder (builder, " :: (");
	for arg : header.arguments
	{
		if it_index != 0
			print_to_builder (builder, ", ");
		print_to_builder (builder, arg.name);
		print_to_builder (builder, " : ");
		print_type_to_builder (builder, arg.type);
	}
	print_to_builder (builder, ")");
	for ret : header.returns
	{
		if it_index == 0
			print_to_builder (builder, " -> ");
		else
			print_to_builder (builder, ", ");
		if ret.name
		{
			print_to_builder (builder, ret.name);
			print_to_builder (builder, " : ");
		}
		print_type_to_builder (builder, ret.type);
	}
}
