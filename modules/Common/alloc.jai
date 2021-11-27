#scope_file

align_address :: (addr : s64, align : int) -> s64 #must
{
	assert (align > 0 && (align & (align - 1)) == 0, "Invalid alignment (got %, expected a power of two).", align);	// Make sure align is a power of 2

	return (addr + (align - 1)) & -align;
}

HEAP_ALLOCATOR_ALIGNMENT :: 8;

#scope_export

HEAP :: Allocator.{ heap_allocator_proc, null };

// Use the OS's heap allocator to allocate, reallocate or free memory.
// The memory is aligned to 8 bytes.
// When allocating a 0 sized block of memory, the procedure returns null.
// Only 'size' writeable bytes are returned, even though we always allocate 8 more bytes for alignment.
// On allocation failure, the result is null.
// Resizing a null block of memory to a non-zero size is the same as allocating one.
// Resizing a non null block of memory to zero size is the same as freeing it.
// A resized memory block might be moved if necessary. (old_ptr == HEAP (.RESIZE, new_size, old_size, old_ptr, null) is not always true).
// If the OS's heap reallocation routine fails, we free the block and allocate a new one ourselves, copying the bytes to the new location.
// Freeing a null pointer won't do anything and is paerfectly valid.
heap_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void		// We can't #must because we ignore the return value when mode == .FREE
{
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

TRAP :: Allocator.{ trap_allocator_proc, null };

trap_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void		// We can't #must because we ignore the return value when mode == .FREE
{
	assert (false, "Called trap_allocator with parameters mode=%, size=%, old_size=%, old_ptr=%, allocator_data=%.", mode, size, old_size, old_ptr, allocator_data);

	return null;
}

#scope_file

Basic :: #import "Basic";	// For __temporary_allocator stuff

#scope_export

TEMP                    :: Basic.temp;
reset_temporary_storage :: Basic.reset_temporary_storage;

Temporary_Storage_State :: Basic.Temporary_Storage_State;

get_temporary_storage_mark :: Basic.get_temporary_storage_mark;
set_temporary_storage_mark :: Basic.set_temporary_storage_mark;

setup_local_storage :: () #expand
{
	__mark := get_temporary_storage_mark ();
	`defer set_temporary_storage_mark (__mark);
}

// @Note (stefan): Should we specify the behaviour for size == 0 and ptr == null before calling the Allocator when allocating/reallocating/freeing ?
// Or should this be handled by the Allocator, and we don't care about possibly having a different behaviour for each Allocator ?

alloc :: (size : s64, allocator : Allocator) -> *void #must
{
	return allocator.proc (.ALLOCATE, size, 0, null, allocator.data);
}

alloc :: ($T : Type, count : s64, allocator : Allocator) -> *T #must
{
	return cast (*T) alloc (count * size_of (T), allocator);
}

realloc :: (ptr : *void, old_size : s64, new_size : s64, allocator : Allocator) -> *void #must
{
	return allocator.proc (.RESIZE, new_size, old_size, ptr, allocator.data);
}

free :: (memory : *void, allocator : Allocator)
{
	allocator.proc (.FREE, 0, 0, memory, allocator.data);
}

free :: (array : []$T, allocator : Allocator)
{
	inline free (array.data, allocator);
}

free :: (str : string, allocator : Allocator)
{
	inline free (str.data, allocator);
}

alloc_item :: ($T : Type, allocator : Allocator, $initialize := true) -> *T #must
{
	ptr := cast (*T) alloc (size_of (T), allocator);
#if initialize inline initialize_item (ptr);

	return ptr;
}

// Allocating an array of 0 elements returns an array with a null data pointer and count = 0.
alloc_array :: ($T : Type, count : s64, allocator : Allocator, $initialize := true) -> []T #must
{
	assert (count >= 0, "Invalid count (got %, expected count >= 0).", count);

	result : []T = ---;
	result.data  = cast (*T) alloc (size_of (T) * count, allocator);
	result.count = count;

	if count > 0
	{
		#if initialize
		{
			INITIALIZER :: initializer_of (T);

			#if INITIALIZER
			{
				for * result
				{
					inline INITIALIZER (it);
				}
			}
			else
			{
				memset (result.data, 0, size_of (T) * count);
			}
		}
	}

	return result;
}

alloc_string :: (count : s64, allocator : Allocator, $initialize := false) -> string #must
{
	return to_string (inline alloc_array (u8, count, allocator, initialize));
}
