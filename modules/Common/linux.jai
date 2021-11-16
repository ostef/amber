#assert OS == .LINUX "This file should only be loaded on Linux.";

#scope_module

platform_heap_alloc :: inline (size : s64) -> *void
{
	return malloc (xx size);
}

platform_heap_realloc :: inline (ptr : *void, new_size : s64) -> *void
{
	return realloc (ptr, xx new_size);
}

platform_heap_free :: inline (ptr : *void)
{
	free (ptr);
}

#scope_file

malloc :: (size : u64) -> *void #foreign libc;
realloc :: (ptr : *void, new_size : u64) -> *void #foreign libc;
free :: (ptr : *void) #foreign libc;

libc :: #foreign_system_library "libc";
