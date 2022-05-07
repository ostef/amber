#import "Runtime";
mem  :: #import "Memory";
fmt  :: #import "Fmt";
log  :: #import "Log";
str  :: #import "String";
path :: #import "Path";
array :: #import "Containers/Array";
fs :: #import "File_System";
ps :: #import "Process";
jaic :: #import "Compiler";

DATA_DIR :: "data/";
BUILD_DIR :: "bin/";
INT_DIR   :: "int/";
OUTPUT_NAME :: "amber";

Output_Type :: type_of (jaic.Build_Options.output_type);

g_build_dir := BUILD_DIR;
g_int_dir   := INT_DIR;
g_use_llvm  : bool;
g_time_info : bool;
g_link_info : bool;
g_import_path : [..]string;

set_default_build_options :: (options : *jaic.Build_Options, output_type : Output_Type, output_name : string, dir := "")
{
	if dir
		options.output_path = str.join (mem.HEAP_ALLOC, g_build_dir, dir);
	else
		options.output_path = g_build_dir;
	options.intermediate_path = g_int_dir;
	fs.create_directory_tree (options.output_path);
	fs.create_directory_tree (options.intermediate_path);
	options.backend = .X64;
	if g_use_llvm then options.backend = .LLVM;
	options.text_output_flags = 0;
	if g_time_info then options.text_output_flags |= .OUTPUT_TIMING_INFO;
	if g_link_info then options.text_output_flags |= .OUTPUT_LINK_LINE;
	options.output_executable_name = output_name;
	options.import_path = g_import_path;
}

compile_workspace :: (ws : Workspace, files : ..string) -> bool
{
	build_success := false;
	jaic.compiler_begin_intercept (ws);
	for files
		jaic.add_build_file (it, ws);
	while true
	{
		msg := jaic.compiler_wait_for_message ();
		if msg.workspace != ws
			continue;
		if msg.kind ==
		{
		case .COMPLETE;
			build_success = (cast (*jaic.Message_Complete) msg).error_code == .NONE;
			break;
		}
	}
	jaic.compiler_end_intercept (ws);

	return build_success;
}

build :: ()
{
	fill_default_context ();
	array.init (*g_import_path, 10, mem.HEAP_ALLOC);
	options := jaic.get_build_options ();
	for options.import_path
		array.push (*g_import_path, fs.get_full_filename (it, mem.HEAP_ALLOC));
	args := options.compile_time_command_line;
	run_on_success := false;
	i := 0;
	while i < args.count
	{
		defer i += 1;
		if args[i] ==
		{
		case "llvm";
			g_use_llvm = true;
		case "x64";
			g_use_llvm = false;
		case "run";
			run_on_success = true;
		case "link_info";
			g_link_info = true;
		case "time_info";
			g_time_info = true;
		}
	}
	#if OS == .WINDOWS
	{
		g_build_dir = str.join (mem.HEAP_ALLOC, g_build_dir, "win");
		g_int_dir   = str.join (mem.HEAP_ALLOC, g_int_dir, "win");
	}
	if g_use_llvm
	{
		g_build_dir = str.join (mem.HEAP_ALLOC, g_build_dir, "_llvm");
		g_int_dir   = str.join (mem.HEAP_ALLOC, g_int_dir, "_llvm");
	}
	else
	{
		g_build_dir = str.join (mem.HEAP_ALLOC, g_build_dir, "_x64");
		g_int_dir   = str.join (mem.HEAP_ALLOC, g_int_dir, "_x64");
	}
	g_build_dir = str.join (mem.HEAP_ALLOC, g_build_dir, "/");
	g_int_dir   = str.join (mem.HEAP_ALLOC, g_int_dir, "/");
	log.message ("Import path is: %.", g_import_path);
	log.message ("Build        directory: {:'}.", g_build_dir);
	log.message ("Intermediate directory: {:'}.", g_int_dir);
	fs.set_working_directory (path.get_parent_dir (#filepath));
	fs.delete_directory (g_build_dir);
	fs.delete_directory (g_int_dir);
	ws := jaic.compiler_create_workspace ("Amber");
	{
		options := jaic.get_build_options (ws);
		set_default_build_options (*options, .EXECUTABLE, OUTPUT_NAME);
		jaic.set_build_options (options, ws);
	}
	build_success := compile_workspace (ws, "source/main.jai");
	if build_success
		log.message ("Workspace '%':\tBuild successful.", jaic.get_name (ws));
	else
		log.error ("Workspace '%':\tBuild failed.", jaic.get_name (ws));
	if build_success
	{
		log.message ("Copying contents of {:'} into {:'}.", DATA_DIR, g_build_dir);
		//fs.copy_directory (DATA_DIR, g_build_dir);	// @Compiler_Bug: crash in CopyFileW...
		ps.run_command ("cp", "-r", "data/*", g_build_dir);
		if run_on_success
		{
			cmd := path.join (mem.HEAP_ALLOC, g_build_dir, OUTPUT_NAME);
			log.message ("Running %", cmd);
			ps.run_command (cmd, working_directory = g_build_dir, output = .PRINT);
		}
	}
	jaic.set_build_options_dc (.{ do_output = false, write_added_strings = false });
}

#run build ();
