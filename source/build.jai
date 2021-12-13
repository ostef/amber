#import "Common";
#import "Process";
#import "File";
Compiler :: #import "Compiler";
Windows_Resources :: #import "Windows_Resources";

#load "amber_meta.jai";
#load "amber_doc.jai";

IS_IN_METAPROGRAM :: true;
DATA_DIR          :: "data/";
DEFAULT_BUILD_DIR :: "bin/";
DEFAULT_INT_DIR   :: "int/";
APP_OUTPUT_NAME  :: "amber";
EXTENSIONS       :: string.[ "amber_default", "amber_jai" ];
ICON_FILENAME    :: "misc/icon.ico";

partial_build := false;
use_llvm := false;
profile := false;
release := false;
target  := OS;
run_on_success := false;
link_info := false;
time_info := false;
doc := false;
build_dir := DEFAULT_BUILD_DIR;
int_dir   := DEFAULT_INT_DIR;

generate_amber_hooks := true;
amber_api_procedures  : [..]*Compiler.Code_Procedure_Header;
run_after_typechecking : [..]*Compiler.Code_Procedure_Header;

report_error :: (fmt : string, args : ..Any, location := #caller_location)
{
	str := fstring (TEMP, fmt, ..args);
	Compiler.compiler_report (str, location);
}

set_default_build_options :: (options : *Compiler.Build_Options, output_type : type_of (Compiler.Build_Options.output_type), output_name : string)
{
	options.output_path       = build_dir;
	options.intermediate_path = int_dir;
	if release then Compiler.set_optimization_level (options, 2, 0);
	if release
		options.dead_code_elimination = .ALL;
	else
		options.dead_code_elimination = .MODULES_ONLY;
	options.stack_trace = !release || profile;
	options.backend = .X64;
	if use_llvm then options.backend = .LLVM;
	options.os_target = target;
	options.text_output_flags = 0;
	if time_info then options.text_output_flags |= .OUTPUT_TIMING_INFO;
	if link_info then options.text_output_flags |= .OUTPUT_LINK_LINE;
	if partial_build
		options.output_type = .NO_OUTPUT;
	else
		options.output_type = output_type;
	options.output_executable_name = output_name;
}

compile_workspace :: (workspace : Workspace, files : ..string) -> bool
{
	build_success := false;
	Compiler.compiler_begin_intercept (workspace);
	for files
		Compiler.add_build_file (it, workspace);
	Compiler.add_build_string (fstring (TEMP, "ENABLE_PROFILING :: %;", profile), workspace);
	Compiler.add_build_string (fstring (TEMP, "RELEASE :: %;", release), workspace);
	Compiler.add_build_string (fstring (TEMP, "DEBUG   :: %;", !release), workspace);
	Compiler.add_build_string ("IS_IN_METAPROGRAM :: false;", workspace);
	
	while true
	{
		message := Compiler.compiler_wait_for_message ();
		if message.workspace != workspace then continue;
		amber_handle_compiler_message (message);
		if message.kind ==
		{
		case .COMPLETE;
			complete := cast (*Compiler.Message_Complete) message;
			build_success = complete.error_code == .NONE;
	
			break;
	
		case .TYPECHECKED;
			typechecked := cast (*Compiler.Message_Typechecked) message;
			for header : typechecked.procedure_headers
			{
				for note : header.expression.notes
				{
					if note.text ==
					{
					case "Amber_API";
						push_into_array (*amber_api_procedures, header.expression);
					
					case "Run_After_Typechecking";
						push_into_array (*run_after_typechecking, header.expression);
					}
				}
			}
		
		case .PHASE;
			phase := cast (*Compiler.Message_Phase) message;
			if phase.phase == .TYPECHECKED_ALL_WE_CAN
			{
				pr :: print_to_builder;
				ln :: print_line_to_builder;
				nl :: print_newline_to_builder;
				
				// Run procedures marked with @Run_After_Typechecking
				for run_after_typechecking
					Compiler.add_build_string (fstring (TEMP, "#run % ();", it.name), workspace);
				clear_array (*run_after_typechecking);

				// Generate Amber_Hooks struct
				if generate_amber_hooks
				{
					quick_sort (amber_api_procedures, (a, b) => compare_strings (a.name, b.name));

					builder := make_string_builder (5000, TEMP);
					ln (*builder, "// This file was automatically generated.");
					nl (*builder);
					ln (*builder, "Amber_Hooks :: struct #type_info_none\n{");
					ln (*builder, "\tusing callbacks : Extension_Callbacks;");
					ln (*builder, "\tHEAP : Allocator;");
					nl (*builder);
					
					for header : amber_api_procedures
						ln (*builder, "\t% : %;", header.name, <<cast (*Type) *header.type);
					ln (*builder, "}");

					write_to_file ("source/amber_hooks.jai", to_string (builder));

					nl (*builder);
					ln (*builder, "load_api :: (hooks : *Amber_Hooks)\n{");
					ln (*builder, "hooks.HEAP = HEAP;");
					for header : amber_api_procedures
						ln (*builder, "\thooks.% = %;", header.name, header.name);
					ln (*builder, "}");
					
					Compiler.add_build_string (to_string (builder), workspace);
					//clear_array (*amber_api_procedures);
					generate_amber_hooks = false;
				}
			}
		}
	}
	Compiler.compiler_end_intercept (workspace);

	return build_success;
}

build :: ()
{
	// Handle command line arguments
	user_args, system_args := Compiler.compiler_get_command_line_arguments ();
	for system_args
	{
		if it ==
		{
		case "-llvm";    use_llvm = true;
		case "-release"; release = true;
		}
	}
	
	program_args := make_array (string, 10, TEMP);
	is_build_dir, is_int_dir, is_program_arg := false;
	for user_args
	{
		if is_build_dir
		{
			if it[it.count - 1] != #char "/"
				build_dir = join (TEMP, it, "/");
			else
				build_dir = it;
			println ("Changed build directory to '%'.", build_dir);
			is_build_dir = false;
		}
		else if is_int_dir
		{
			if it[it.count - 1] != #char "/"
				int_dir = join (TEMP, it, "/");
			else
				int_dir = it;
			println ("Changed intermediate directory to '%'.", int_dir);
			is_int_dir = false;
		}
		else if is_program_arg
		{
			push_into_array (*program_args, " ", it);
		}
		else if it ==
		{
		case "partial"; partial_build = true;
		case "llvm";    use_llvm = true;
		case "release"; release = true;
		case "profile"; profile = true;
		case "windows"; target = .WINDOWS;
		case "linux";   target = .LINUX;
		case "macos";   target = .MACOS;
		case "run";     run_on_success = true;
		case "link_info"; link_info = true;
		case "time_info"; time_info = true;
		case "build_dir"; is_build_dir = true;
		case "int_dir";   is_int_dir   = true;
		case "doc";   doc = true;
		case "---"; is_program_arg = true;
		case; println ("Unkown argument '%'.", it);
		}
	}

	// Set build and intermediate directories
	if target ==
	{
	case .WINDOWS;
		build_dir = join (TEMP, build_dir, "win");
		int_dir   = join (TEMP, int_dir, "win");
	
	case .LINUX;
		build_dir = join (TEMP, build_dir, "linux");
		int_dir   = join (TEMP, int_dir, "linux");
	
	case .MACOS;
		build_dir = join (TEMP, build_dir, "macos");
		int_dir   = join (TEMP, int_dir, "macos");
	
	case;
		report_error ("Unsupported target OS %.", target);
	}
	
	if release
	{
		build_dir = join (TEMP, build_dir, "_release");
		int_dir   = join (TEMP, int_dir, "_release");
	}
	else
	{
		build_dir = join (TEMP, build_dir, "_debug");
		int_dir   = join (TEMP, int_dir, "_debug");
	}

	if profile
	{
		build_dir = join (TEMP, build_dir, "_profile");
		int_dir   = join (TEMP, int_dir, "_profile");
	}

	build_dir = join (TEMP, build_dir, "/");
	int_dir   = join (TEMP, int_dir, "/");
	println ("Build        directory: '%'.", build_dir);
	println ("Intermediate directory: '%'.", int_dir);
	print ("\n");
	sorted_insert_to_array (*program_args, 0, APP_OUTPUT_NAME);
	extension_workspaces : [EXTENSIONS.count]Workspace;

	// #filepath is 'something/source/', we want 'something/'
	set_working_directory (strip_filename_from_path (#filepath));

	init_array (*amber_api_procedures, 100, TEMP);
	init_array (*run_after_typechecking, 100, TEMP);
	app := Compiler.compiler_create_workspace (APP_OUTPUT_NAME);
	{
		options := Compiler.get_build_options (app);
		set_default_build_options (*options, .EXECUTABLE, APP_OUTPUT_NAME);
		Compiler.set_build_options (options, app);
	}
	
	for name, i : EXTENSIONS
	{
		extension_workspaces[i] = Compiler.compiler_create_workspace (name);
		{
			amber_add_workspace (extension_workspaces[i]);
			options := Compiler.get_build_options (extension_workspaces[i]);
			set_default_build_options (*options, .DYNAMIC_LIBRARY, name);
			Compiler.set_build_options (options, extension_workspaces[i]);
		}
	}

	delete_directory (build_dir);
	delete_directory (int_dir);
	create_directory_tree (build_dir);
	create_directory_tree (int_dir);
	
	app_build_success  := compile_workspace (app,  "source/amber_main.jai");
	if doc && app_build_success then generate_documentation ();
	generate_amber_hooks = false;
	extensions_build_success : [EXTENSIONS.count]bool;
	all_extensions_build_success := true;
	for workspace, i : extension_workspaces
	{
		extensions_build_success[i] = compile_workspace (workspace, join (TEMP, "source/", EXTENSIONS[i], ".jai"));
		all_extensions_build_success &= extensions_build_success[i];
	}
	
	print ("\n");
	if app_build_success then println ("Workspace '%':\tBuild successful.", APP_OUTPUT_NAME);
	else println ("Workspace '%':\tBuild failed.", APP_OUTPUT_NAME);
	for name, i : EXTENSIONS
	{
		if extensions_build_success[i] then println ("Workspace '%':\tBuild successful.", name);
		else println ("Workspace '%':\tBuild failed.", name);
	}
	print ("\n");

	if app_build_success && !partial_build
	{
		exe_filename := join (TEMP, build_dir, APP_OUTPUT_NAME, ".exe");
		print ("Setting icon to '%' for executable '%' - ", ICON_FILENAME, exe_filename);
		ok := Windows_Resources.set_icon_by_filename (exe_filename, ICON_FILENAME);
		if ok then println ("OK");
		else println ("FAILED");
	}
	
	if all_extensions_build_success && app_build_success && !partial_build
	{
		copy_files (DATA_DIR, build_dir);

		if run_on_success
		{
			working_directory := get_working_directory (TEMP);
			set_working_directory (build_dir);
			defer set_working_directory (working_directory);
			cmd := join (TEMP, ..program_args);
			println ("Running %\n", cmd);
			os_run_command (cmd);
		}
	}
	
	// Set metaprogram output to none
	Compiler.set_build_options_dc (.{ do_output = false, write_added_strings = false });
}

generate_documentation :: ()
{
	visitor :: (info : *File_Visit_Info, data : *void)
	{
		if !info.is_directory
		{
			extension := get_filename_extension (info.name);
			if extension == "amber_doc"
			{
				doc_file : Doc_File;
				ok := parse_doc_file (info.full_name, *doc_file);
				if ok
				{
					builder : String_Builder;
					init_string_builder (*builder, 10000, HEAP);
					generate_markdown (*builder, doc_file);
					name := strip_extension_from_path (info.name);
					md_filename := make_path (HEAP, "docs/generated/api/", name, ".md");
					write_to_file (md_filename, to_string (builder));
				}
			}
		}
	}

	delete_directory ("docs/generated/");
	inspect_directory ("docs/api/", true, null, visitor);
}

quick_sort :: (array : []$T, compare_func : (T, T) -> $R)
{
	partition :: (array : *T, low_index : s64, high_index : s64, compare_func : (T, T) -> R) -> s64
	{
		x := array[high_index];
		i := low_index - 1;

		for j : low_index..high_index - 1
		{
			if compare_func (array[j], x) <= 0
			{
				i += 1;
				tmp := array[i];
				array[i] = array[j];
				array[j] = tmp;
			}
		}
		tmp := array[i + 1];
		array[i + 1] = array[high_index];
		array[high_index] = tmp;
		
		return i + 1;
	}

	helper :: (array : *T, low_index : s64, high_index : s64, compare_func : (T, T) -> R)
	{
		if low_index < high_index
		{
			p := partition (array, low_index, high_index, compare_func);
			helper (array, low_index, p - 1, compare_func);
			helper (array, p + 1, high_index, compare_func);
		}
	}

	helper (array.data, 0, array.count - 1, compare_func);
}

#run build ();
