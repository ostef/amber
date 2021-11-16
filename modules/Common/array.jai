// @Note (stefan): Basic array procedures. This kind of thing is provided in the
// Basic module, but we have our naming conventions and slightly different ways
// of doing things. For example, we want procedures that allocate or need an allocator
// to take a non default argument Allocator as parameter. Since this will be the
// fundations of our biggest projects, we want it to be clear, and unambiguous, which
// to me is often not the case in (beta) Basic.

slice :: (array : []$T, start : s64, count : s64) -> []T #must
{
	if array.count == 0
	{
		assert (start == 0 && count == 0, "Invalid slice range (got [%, %], expected [0, 0]).", start, start + count);

		return array;
	}
	
	assert (start >= 0 && start + count <= array.count && start <= array.count && count >= 0 && count <= array.count,
		"Invalid slice range (got [%, %], expected [%, %]).", start, start + count, 0, array.count);
	result := array;
	result.data += start;
	result.count = count;

	return result;
}

slice :: (array : []$T, count : s64) -> []T #must
{
	return inline slice (array, 0, count);
}

advance :: (array : []$T, count := 1) -> []T #must
{
	count = min (array.count, count);
	result := array;
	result.data  += count;
	result.count -= count;

	return result;
}

clone_array_as_resizable :: (array : []$T, capacity : int, allocator : Allocator, allocator_data := null) -> [..]T #must
{
	assert (capacity >= 0, "Invalid capacity (got %, expected capacity >= 0).", capacity);

	count := array.count;
	if capacity < count then count = capacity;
	result : [..]T;
	result.data           = cast (*T) alloc (capacity * size_of (T), allocator, allocator_data);
	memcpy (result.data, array.data, count * size_of (T));
	result.count          = count;
	result.allocated      = capacity;
	result.allocator      = allocator;
	result.allocator_data = allocator_data;

	return result;
}

clone_array_as_resizable :: (array : []$T, allocator : Allocator, allocator_data := null) -> [..]T #must
{
	return inline clone_array_as_resizable (array, array.count, allocator, allocator_data);
}

clone_array :: (array : []$T, allocator : Allocator, allocator_data := null) -> []T #must
{
	result : []T;
	result.data  = cast (*T) alloc (array.count * size_of (T), allocator, allocator_data);
	memcpy (result.data, array.data, array.count * size_of (T));
	result.count = array.count;

	return result;
}

copy_array :: (destination : *[..]$T, source : []T)
{
	if destination.allocated < source.count then resize_array (destination, source.count * 2);
	memcpy (destination.data, source.data, size_of (T) * source.count);
	destination.count = source.count;
}

init_array :: (array : *[..]$T, capacity : int, allocator : Allocator, allocator_data := null)
{
	assert (capacity >= 0, "Invalid capacity (got %, expected capacity >= 0).", capacity);

	array.data           = cast (*T) alloc (capacity * size_of (T), allocator, allocator_data);
	array.count          = 0;
	array.allocated      = capacity;
	array.allocator      = allocator;
	array.allocator_data = allocator_data;
}

make_array :: ($T : Type, capacity : int, allocator : Allocator, allocator_data := null) -> [..]T #must
{
	result : [..]T = ---;
	inline init_array (*result, capacity, allocator, allocator_data);

	return result;
}

// For us, reset means "free the data and set everything to 0 except the allocator" and clear means
// remove all elements without deallocating.
reset_array :: (array : *[..]$T)
{
	free (array.data, array.allocator, array.allocator_data);
	array.data      = null;
	array.count     = 0;
	array.allocated = 0;
}

clear_array :: (array : *[..]$T)
{
	array.count = 0;
}

array_top :: inline (array : [..]$T) -> T #must
{
	assert (array.count > 0, "Array is empty.");

	return array[array.count - 1];
}

insert_to_array :: (array : *[..]$T, position : int, $initialize := false) -> *T #must
{
	assert (position >= 0 && position <= array.count, "Index % out of range [%, %].", position, 0, array.count);

	if array.count == array.allocated then resize_array (array, array.count * 2 + 8);

	if position != array.count then array.data[array.count] = array.data[position];
	array.count += 1;
	ptr := *array.data[array.count];
	#if initialize
	{
		inline initialize_item (ptr);
	}

	return ptr;
}

insert_to_array :: (array : *[..]$T, position : int, elem : T) -> *T
{
	ptr := inline insert_to_array (array, position);
	<<ptr = elem;

	return ptr;
}

sorted_insert_to_array :: (array : *[..]$T, position : int, $initialize := false) -> *T #must
{
	assert (position >= 0 && position <= array.count, "Index % out of range [%, %].", position, 0, array.count);

	if array.count == array.allocated then resize_array (array, array.count * 2 + 8);

	array.count += 1;
	for < i : array.count - 1..position + 1
	{
		array.data[i] = array.data[i - 1];
	}
	ptr := *array.data[position];
	#if initialize
	{
		inline initialize_item (ptr);
	}

	return ptr;
}

sorted_insert_to_array :: (array : *[..]$T, position : int, elem : T) -> *T
{
	ptr := inline sorted_insert_to_array (array, position);
	<<ptr = elem;

	return ptr;
}

sorted_insert_to_array :: (array : *[..]$T, position : int, elems : ..T) -> *T
{
	ptr := null;
	for < elems
		ptr = sorted_insert_to_array (array, position, it);

	return ptr;
}

remove_from_array :: (array : *[..]$T, position : int)
{
	assert (array.count > 0, "Index % out of range: array has no elements.", position);
	assert (position >= 0 && position < array.count, "Index % out of range [%, %].", position, 0, array.count - 1);

	array.data[position] = array.data[array.count - 1];
	array.count -= 1;
}

sorted_remove_from_array :: (array : *[..]$T, position : int)
{
	assert (array.count > 0, "Index % out of range: array has no elements.", position);
	assert (position >= 0 && position < array.count, "Index % out of range [%, %].", position, 0, array.count - 1);

	for i : position..array.count - 2
	{
		array.data[i] = array.data[i + 1];
	}
	array.count -= 1;
}

push_to_array :: (array : *[..]$T, $initialize := false) -> *T #must
{
	if array.count == array.allocated then resize_array (array, array.count * 2 + 8);

	ptr := *array.data[array.count];
	array.count += 1;
	#if initialize
	{
		inline initialize_item (ptr);
	}

	return ptr;
}

push_to_array :: (array : *[..]$T, elem : T) -> *T
{
	if array.count == array.allocated then resize_array (array, array.count * 2 + 8);

	ptr := *array.data[array.count];
	<<ptr = elem;
	array.count += 1;

	return ptr;
}

push_to_array :: (array : *[..]$T, elems : ..T) -> []T
{
	if array.count + elems.count > array.allocated then resize_array (array, array.count * 2 + elems.count);
	
	result : []T = ---;
	result.data  = array.data + array.count;
	result.count = elems.count;
	for elems
	{
		array.data[array.count] = it;
		array.count += 1;
	}
	
	return result;
}

pop_from_array :: (array : *[..]$T) -> T
{
	assert (array.count > 0, "Cannot pop because array is empty.");
	array.count -= 1;
	
	return array.data[array.count];
}

resize_array :: (array : *[..]$T, new_capacity : int)
{
	assert (array.allocator != null, "Array is not initialized.");
	assert (new_capacity >= 0, "Invalid new_capacity (got %, expected new_capacity >= 0).", new_capacity);
	if new_capacity == array.allocated then return;

	if new_capacity == 0
	{
		inline reset_array (array);
	}
	else
	{
		array.data      = cast (*T) realloc (array.data, size_of (T) * array.allocated, size_of (T) * new_capacity, array.allocator, array.allocator_data);
		array.count     = min (array.count, new_capacity);
		array.allocated = new_capacity;
	}
}

find_first_occurence :: (array : []$T, elem : T) -> index : int #must
{
	for array
	{
		if it == elem then return it_index;
	}

	return -1;
}

find_last_occurence :: (array : []$T, elem : T) -> index : int #must
{
	for < array
	{
		if it == elem then return it_index;
	}

	return -1;
}

find_all_occurences :: (array : []$T, elem : T, out : *[..]int) -> found : int
{
	found := 0;
	for array
	{
		if it == elem
		{
			push_to_array (out, it_index);
			found += 1;
		}
	}

	return found;
}

insert_to_array_if_new :: (array : *[..]$T, position : int, elem : T) -> is_new : bool
{
	if find_first_occurence (<<array, elem) == -1
	{
		inline insert_to_array (array, position, elem);

		return true;
	}
	
	return false;
}

push_to_array_if_new :: (array : *[..]$T, elem : T) -> is_new : bool
{
	if find_first_occurence (<<array, elem) == -1
	{
		inline push_to_array (array, elem);

		return true;
	}

	return false;
}
