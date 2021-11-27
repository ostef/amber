// @Note (stefan): For now, String_Builder is just a resizable array of u8s. Later
// on, we might make it a more complex data structure that is more efficient.
String_Builder :: [..]u8;

init_string_builder :: (builder : *String_Builder, capacity : s64, allocator : Allocator)
{
	inline init_array (builder, capacity, allocator);
}

// @Note (stefan): We could use #bake_arguments here...
make_string_builder :: (capacity : s64, allocator : Allocator) -> String_Builder #must
{
	return inline make_array (u8, capacity, allocator);
}

// For us, reset means "free the data and set everything to 0 except the allocator".
reset_string_builder :: (builder : *String_Builder)
{
	inline reset_array (builder);
}

clear_string_builder :: (builder : *String_Builder)
{
	builder.count = 0;
}

resize_string_builder :: (builder : *String_Builder, new_capacity : s64)
{
	inline resize_array (builder, new_capacity);
}

builder_to_string :: (builder : String_Builder) -> string #must
{
	result : string;
	result.data  = builder.data;
	result.count = builder.count;

	return result;
}

to_string :: inline (builder : String_Builder) -> string #must
{
	return builder_to_string (builder);
}

builder_to_cstring :: (builder : *String_Builder) -> *u8 #must
{
	print_char_to_builder (builder, 0);
	
	return builder.data;
}

builder_clone_to_string :: (builder : String_Builder, allocator : Allocator, $null_terminate := true) -> string #must
{
	result : string;
#if null_terminate count := builder.count + 1;
else               count := builder.count;
	result.data  = cast (*u8) alloc (count, allocator);
	memcpy (result.data, builder.data, builder.count);
	result.count = builder.count;
#if null_terminate result.data[result.count] = 0;

	return result;
}

builder_clone_to_cstring :: (builder : String_Builder, allocator : Allocator) -> *u8 #must
{
	result : *u8;
	result = cast (*u8) alloc (builder.count + 1, allocator);
	memcpy (result, builder.data, builder.count);
	result[builder.count] = 0;

	return result;
}
