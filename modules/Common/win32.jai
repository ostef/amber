#assert OS == .WINDOWS "This file should only be loaded on Windows.";

#scope_module

platform_heap_alloc :: inline (size : s64) -> *void
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null.");

	return HeapAlloc (heap, 0, xx size);
}

platform_heap_realloc :: inline (ptr : *void, new_size : s64) -> *void
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null.");

	return HeapReAlloc (heap, 0, ptr, xx new_size);
}

platform_heap_free :: inline (ptr : *void)
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null.");
	HeapFree (heap, 0, xx ptr);
}

GetStdHandle :: (nStdHandle : s32) -> *void #foreign kernel32;
SetConsoleTextAttribute :: (hConsoleOutput : *void, wAttributes : u16) -> s32 #foreign kernel32;
WriteFile :: (file : HANDLE, buffer : *void, length : u32, written : *u32, overlapped : *void) -> BOOL #foreign kernel32;

#scope_file

GetProcessHeap :: () -> *void #foreign kernel32;
HeapAlloc :: (hHeap : *void, dwFlags : u32, dwBytes : u64) -> *void #foreign kernel32;
HeapReAlloc :: (hHeap : *void, dwFlags : u32, lpMem : *void, dwBytes : u64) -> *void #foreign kernel32;
HeapFree :: (hHeap : *void, dwFlags : u32, lpMem : *void) -> s32 #foreign kernel32;

kernel32 :: #foreign_system_library "kernel32";		// For HeapAlloc, HeapFree, ...
