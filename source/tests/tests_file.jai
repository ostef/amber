#load "../amber_types.jai";
#load "../amber_core.jai";
#load "../amber_platform.jai";

EXPECTED_RESULT :: "-.\n--a\n---aa\n----aaa.txt\n---ab.txt\n--b\n---ba\n----baa\n----bab.txt\n---bb.txt\n---bc\n----bca.txt\n--c.txt\n";

main :: ()
{
	print_tree :: (builder : *String_Builder, root : *File_Info, indentation_level := 0)
	{
		assert (root.name != "", "name was null.");
		assert (root.full_name != "", "name was null.");
		
		for 0..indentation_level
			print_to_builder (builder, "-");
		print_to_builder (builder, "%\n", root.name);
		for :children root
			print_tree (builder, it, indentation_level + 1);
	}
	
	println ("Beginning file tests.");
	root := platform_list_files_in_directory ("dir", TEMP);
	assert (root != null, "Root was null.");
	assert (root.first_child != null, "first child was null.");
	builder : String_Builder;
	builder.allocator = TEMP;
	print_tree (*builder, root);
	print (to_string (builder));
	assert (to_string (builder) == EXPECTED_RESULT, "Expected\n%\n, got\n%\n", EXPECTED_RESULT, to_string (builder));
	println ("File tests - OK");
}
