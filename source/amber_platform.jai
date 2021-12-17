#if OS == .WINDOWS then #load "amber_win32.jai";

platform_read_entire_file :: (filename : string, allocator : Allocator) -> string #must, bool
{
	file := platform_open_file (filename, File_Open_Flags.ACCESS_READ | .OPEN_IF_EXISTS);
	if !file then return "", false;
	defer platform_close_file (file);
	platform_set_file_cursor (file, 0, .END);
	size := platform_get_file_cursor (file);
	platform_set_file_cursor (file, 0, .BEGIN);
	buffer := alloc_string (size, allocator);
	read, ok := platform_read_file (file, buffer.data, buffer.count);
	if !ok
	{
		free (buffer, allocator);
		
		return "", false;
	}
	
	return buffer, true;
}
@Amber_API

platform_write_to_file :: (filename : string, buffer : string) -> written : s64, success : bool
{
	file := platform_open_file (filename, File_Open_Flags.ACCESS_WRITE | .OPEN_OR_CREATE);
	if !file then return 0, false;
	defer platform_close_file (file);
	written, success := platform_write_file (file, buffer.data, buffer.count);
	
	return written, success;
}
@Amber_API

platform_purge_directory :: (dirname : string) -> bool
{
	root := platform_list_files_in_directory (dirname, TEMP);
	if !root then return false;
	
	current : *File_Info = root.first_child;
	while current
	{
		if flagged (current.attributes, .DIRECTORY)
			platform_delete_directory (current.full_name);
		else
			platform_delete_file (current.full_name);
		current = current.next_sibling;
	}
	
	return true;
}
@Amber_API

platform_delete_directory :: (dirname : string) -> bool
{
	platform_purge_directory (dirname);
	
	return platform_delete_empty_directory (dirname);
}
@Amber_API

HEAP :: Allocator.{ heap_allocator_proc, null };

// Use the OS's heap allocator to allocate, reallocate or free memory.
// The memory is aligned to 8 bytes.
// When allocating a 0 sized block of memory, the procedure returns null.
// On allocation failure, the result is null.
// Resizing a null block of memory to a non-zero size is the same as allocating one.
// Resizing a non null block of memory to zero size is the same as freeing it.
// A resized memory block might be moved if necessary. (old_ptr == HEAP (.RESIZE, new_size, old_size, old_ptr, null) is not always true).
// If the OS's heap reallocation routine fails, we free the block and allocate a new one ourselves, copying the bytes to the new location.
// Freeing a null pointer is a no-op.
heap_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void		// We can't #must because we ignore the return value when mode == .FREE
{
	HEAP_ALLOCATOR_ALIGNMENT :: 8;

	if #complete mode ==
	{
	case .ALLOCATE;
		assert (size >= 0, "Invalid size (got %, expected size >= 0).", size);
		if size == 0 then return null;	// Return null if size is 0, malloc returns valid memory for size == 0 and this is UB with HeapAlloc, I don't like either of the two
		
		needed    := size + HEAP_ALLOCATOR_ALIGNMENT;		// Allocate enough memory for HEAP_ALLOCATOR_ALIGNMENT-byte alignment and to store the address shift
		unaligned := cast (*u8) platform_heap_alloc (needed);
		if !unaligned then return null;
		
		// Align to HEAP_ALLOCATOR_ALIGNMENT-bytes
		aligned := cast (*u8) align_address (cast (s64) unaligned, HEAP_ALLOCATOR_ALIGNMENT);
		if aligned == unaligned then aligned += HEAP_ALLOCATOR_ALIGNMENT;	// If we were already aligned, shift anyway because we have to make room to store the shift
		aligned[-1] = cast (u8) (aligned - unaligned);	// Store the shift

		return aligned;

	case .RESIZE;
		assert (size >= 0, "Invalid size (got %, expected size >= 0).", size);
		if !old_ptr then return heap_allocator_proc (.ALLOCATE, size, 0, null, allocator_data);
		if size == 0 then return heap_allocator_proc (.FREE, 0, 0, old_ptr, allocator_data);

		needed    := size + HEAP_ALLOCATOR_ALIGNMENT;		// For alignment
		aligned   := cast (*u8) old_ptr;
		unaligned := aligned - aligned[-1];
		new_ptr   := platform_heap_realloc (unaligned, needed);		// @Note (stefan): The memory block may be moved by the OS
		if new_ptr == unaligned then return aligned;	// Don't bother realigning if the block has not been moved

		if new_ptr
		{
			// The block has been moved, we need to realign it
			unaligned = cast (*u8) new_ptr;
			aligned   = cast (*u8) align_address (cast (s64) unaligned, HEAP_ALLOCATOR_ALIGNMENT);
			if aligned == unaligned then aligned += HEAP_ALLOCATOR_ALIGNMENT;
			aligned[-1] = cast (u8) (aligned - unaligned);	// Store the shift

			return aligned;
		}

		// platform_heap_realloc failed, free then allocate ourselves
		new_ptr = cast (*u8) heap_allocator_proc (.ALLOCATE, size, 0, null, allocator_data);
		memcpy (new_ptr, old_ptr, min (old_size, size));
		heap_allocator_proc (.FREE, 0, 0, old_ptr, allocator_data);

		return new_ptr;

	case .FREE;
		if !old_ptr then return null;
		
		aligned   := cast (*u8) old_ptr;
		unaligned := aligned - aligned[-1];
		platform_heap_free (unaligned);
	}

	return null;
}
@Amber_API

platform_is_key_down :: inline (key_code : Key_Code) -> bool #must
{
	state := platform_get_key_state (key_code);
	
	return state == .PRESSED || state == .DOWN;
}
@Amber_API

platform_is_mouse_button_down :: inline (button : Mouse_Button) -> bool #must
{
	state := platform_get_mouse_button_state (button);
	
	return state == .PRESSED || state == .DOWN;
}
@Amber_API
