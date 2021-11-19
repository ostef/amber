Amber_Program_Data :: struct
{
	workspace : Workspace;
	command_headers : [..]*Compiler.Code_Procedure_Header;
	generated_command_procs : bool;
}

#scope_file

programs_data : [..]Amber_Program_Data;

#scope_export

amber_add_workspace :: (workspace : Workspace)
{
	if !programs_data.data
		init_array (*programs_data, 10, temp_allocator);
	data := push_into_array (*programs_data, initialize = true);
	data.workspace = workspace;
	init_array (*data.command_headers, 50, temp_allocator);
}

amber_handle_compiler_message :: (message : *Compiler.Message)
{
	using data : *Amber_Program_Data;
	for * programs_data
	{
		if it.workspace == message.workspace
		{
			data = it;
		
			break;
		}
	}
	if !data then return;
	
	if message.kind ==
	{
	case .TYPECHECKED;
		typechecked := cast (*Compiler.Message_Typechecked) message;
		for header : typechecked.procedure_headers
		{
			for note : header.expression.notes
			{
				if note.text == "Amber_Command"
				{
					push_into_array (*command_headers, header.expression);
					
					break;
				}
			}
		}

	case .PHASE;
		phase := cast (*Compiler.Message_Phase) message;
		if phase.phase == .TYPECHECKED_ALL_WE_CAN
		{
			if !generated_command_procs
			{
				for command_headers
					Compiler.add_build_string (generate_command_wrapper (it), message.workspace);
				Compiler.add_build_string (generate_register_all_commands_proc (data), message.workspace);
				clear_array (*command_headers);
				generated_command_procs = true;
			}
		}
	}
}

#scope_file

get_first_optional_argument :: (header : *Compiler.Code_Procedure_Header) -> s64 #must
{
	for arg, i : header.arguments
	{
		if i == 0 then continue;
		if arg.expression
			return i - 1;
	}
	
	return -1;
}

generate_command_wrapper :: (header : *Compiler.Code_Procedure_Header) -> string #must
{
	function_name := header.name;
	name      := advance (function_name, "command_".count);
	info      := cast (*Type_Info_Procedure) header.type;
	arg_count := header.arguments.count - 1;
	first_optional_argument := get_first_optional_argument (header);
	
	builder : String_Builder;
	init_string_builder (*builder, 1000, temp_allocator);
	pr :: print_to_builder;
	ln :: print_line_to_builder;
	nl :: print_newline_to_builder;
	
	ln (*builder, "%_wrapper :: (using hooks : *Amber_Hooks, args : []string) -> bool\n{", function_name);
	if first_optional_argument != -1
	{
		ln (*builder, "\tif args.count < %\n\t{", first_optional_argument);
		ln (*builder, "\t\tprintln (\"Command '%' expects at least % argument(s) but got %.\", args.count);\n", name, first_optional_argument);
		ln (*builder, "\t\treturn false;");
		ln (*builder, "\t}");
		
		nl (*builder);
		
		ln (*builder, "\tif args.count > %\n\t{", arg_count);
		ln (*builder, "\t\tprintln (\"Command '%' expects at most % argument(s) but got %.\", args.count);\n", name, arg_count);
		ln (*builder, "\t\treturn false;");
		ln (*builder, "\t}");
	}
	else
	{
		ln (*builder, "\tif args.count != %\n\t{", arg_count);
		ln (*builder, "\t\tprintln (\"Command '%' expects % argument(s) but got %.\", args.count);\n", name, arg_count);
		ln (*builder, "\t\treturn false;");
		ln (*builder, "\t}");
	}
	
	nl (*builder);
	
	for arg : info.argument_types
	{
		if it_index == 0
			continue;
		i := it_index - 1;
		is_optional := first_optional_argument != -1 && i >= first_optional_argument;
		typename := "string";
		
		if arg.type ==
		{
		case .INTEGER;	typename = "s64";
		case .BOOL;		typename = "bool";
		case .FLOAT;	typename = "f32";
		case .STRING;	typename = "string";
		case;
			Compiler.compiler_report (Compiler.get_filename (header), header.l0, header.c0,
				fstring (temp_allocator, "Command procedure has arguments with type that we don't handle. Argument type is %. Handled argument types are: INTEGER, BOOL, FLOAT and STRING.", arg.type));
		}

		if is_optional
		{
			ln (*builder, "\targ% : %;", i, typename);
			ln (*builder, "\targ%_ok := true;", i);
			ln (*builder, "\tif args.count > % then arg%, arg%_ok = string_to_% (args[%]);", i, i, i, typename, i);
		}
		else
		{
			ln (*builder, "\targ%, arg%_ok := string_to_% (args[%]);", i, i, typename, i);
		}
		ln (*builder, "\tif !arg%_ok\n\t{", i);
		ln (*builder, "\t\tprintln (\"Command '%' expects a % for argument %.\");\n", name, typename, i);
		ln (*builder, "\t\treturn false;");
		ln (*builder, "\t}");
		nl (*builder);
	}
	pr (*builder, "\treturn % (hooks, ", function_name);
	for i : 0..arg_count - 1
	{
		if i != 0 then pr (*builder, ", ");
		pr (*builder, "arg%", i);
	}
	ln (*builder, ");");
	ln (*builder, "}");

	return to_string (builder);
}

generate_register_all_commands_proc :: (using data : *Amber_Program_Data) -> string #must
{
	builder : String_Builder;
	init_string_builder (*builder, 1000, temp_allocator);
	pr :: print_to_builder;
	ln :: print_line_to_builder;
	nl :: print_newline_to_builder;
	
	ln (*builder, "register_all_commands :: (using hooks : *Amber_Hooks, extension_id : Extension_ID)\n{");
	for header, i : command_headers
	{
		function_name := header.name;
		name := advance (header.name, "command_".count);
		info := cast (*Type_Info_Procedure) header.type;
		arg_count := info.argument_types.count - 1;
		first_optional_argument := get_first_optional_argument (header);
		ln (*builder, "\tcommand_register (extension_id, Command_Info.{ \"%\", %_wrapper, %, % });", name, function_name, arg_count, first_optional_argument);
	}
	ln (*builder, "}");

	return to_string (builder);
}
