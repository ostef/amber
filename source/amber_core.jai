ENABLE_ASSERTS :: !RELEASE;

always_panic :: inline (fmt := "", args : ..Any, location := #caller_location)
{
	// Prevent assert ()->...->assert ()->...->assert ()->...->assert () infinite loop (format_string might assert for example)
	if context.handling_assertion_failure then return;
	context.handling_assertion_failure = true;
	context.assertion_failed (location, fstring (temp_allocator, fmt, ..args));
	context.handling_assertion_failure = false;
}

always_assert :: inline (assertion : bool, fmt := "", args : ..Any, location := #caller_location)
{
	if !assertion
	{
		// Prevent assert ()->...->assert ()->...->assert ()->...->assert () infinite loop (format_string might assert for example)
		if context.handling_assertion_failure then return;
		context.handling_assertion_failure = true;
		context.assertion_failed (location, fstring (temp_allocator, fmt, ..args));
		context.handling_assertion_failure = false;
	}
}

panic :: (fmt := "", args : ..Any, location := #caller_location) #expand
{
#if ENABLE_ASSERTS
	always_panic (fmt, ..args, location);
}

// @Note (stefan): We take a Code instead of a bool so we choose whether or not the expression gets
// evaluated ourselves. The expression we want to assert might take a long time to execute, so we
// need to be able to not evaluate the expression when assertions are disabled, or we won't get much
// performance boost in release builds.
assert :: (assertion_expr : Code, fmt := "", args : ..Any, location := #caller_location) #expand
{
#if ENABLE_ASSERTS
	always_assert (#insert assertion_expr, fmt, ..args, location);
}

offset_of :: inline ($T : Type, $member : string) -> s64 #must
{
	#insert #run fstring (heap_allocator, BODY, member);

BODY :: #string END
dummy : T = ---;

return cast (*void) (*dummy.%) - cast (*void) *dummy;
END
}

swap :: inline (a : $T, b : T) -> b : T #must, a : T #must
{
	return b, a;
}

// Math

S8_MIN  : s8 :  -128;
S8_MAX  : s8 :   127;
U8_MAX  : u8 :   255;
S16_MIN : s16 : -32768;
S16_MAX : s16 :  32767;
U16_MAX : u16 :  0xffff;
S32_MIN : s32 :  0x8000_0000;
S32_MAX : s32 :  0x7fff_ffff;
U32_MAX : u32 :  0xffff_ffff;
S64_MIN : s64 :  0x8000_0000_0000_0000;
S64_MAX : s64 :  0x7fff_ffff_ffff_ffff;
U64_MAX : u64 :  0xffff_ffff_ffff_ffff;

F32_MIN : f32 : 0h0080_0000;
F32_MAX : f32 : 0h7f7f_ffff;
F32_MIN_SUBNORMAL : f32 : 0h0000_0001;
F32_MAX_SUBNORMAL : f32 : 0h007f_ffff;
F32_POSITIVE_INFINITY : f32 : 0h7f80_0000;
F32_NEGATIVE_INFINITY : f32 : 0hff80_0000;
F32_NAN : f32 : 0h7fc0_0000;
F32_EPSILON : f32 : 0h3400_0000;

F64_MIN : f64 : 0h0010_0000_0000_0000;
F64_MAX : f64 : 0h7fef_ffff_ffff_ffff;
F64_MIN_SUBNORMAL : f64 : 0h0000_0000_0000_0001;
F64_MAX_SUBNORMAL : f64 : 0h000f_ffff_ffff_ffff;
F64_POSITIVE_INFINITY : f64 : 0h7ff0_0000_0000_0000;
F64_NEGATIVE_INFINITY : f64 : 0hfff0_0000_0000_0000;
F64_NAN : f64 : 0h7ff8_0000_0000_0000;
F64_EPSILON : f64 : 0h3cb0_0000_0000_0000;

MAX_REPRESENTABLE_INT_AS_F32 :: 16777217;

PI   : f32 : 3.1415927;
PI64 : f64 : 3.141592653589793;

count_digits :: inline (value : s64) -> s64 #must
{
	if value == 0 then return 1;
	
	count := 0;
	if value < 0
	{
		count += 1;
		value = -value;
	}
	while value
	{
		count += 1;
		value /= 10;
	}
	
	return count;
}

is_nan :: (value : f32) -> bool #must
{
	uf := <<cast (*u32) *value;
	unbiased_exponent := (uf >> 23) & 0xff;
	
	if unbiased_exponent == 0xff
	{
		raw_mantissa := uf & 0x7f_ffff;
		if raw_mantissa == 0 then return false;

		return true;
	}

	return false;
}

is_inf :: (value : f32) -> bool #must
{
	uf := <<cast (*u32) *value;
	unbiased_exponent := (uf >> 23) & 0xff;
	
	if unbiased_exponent == 0xff
	{
		raw_mantissa := uf & 0x7f_ffff;
		if raw_mantissa == 0 then return true;

		return false;
	}

	return false;
}

is_nan :: (value : f64) -> bool #must
{
	uf := <<cast (*u64) *value;
	unbiased_exponent := cast (s32) ((uf >> 52) & 0x7ff);

	if unbiased_exponent == 0x7ff
	{
		raw_mantissa := uf & 0x000f_ffff_ffff_ffff;
		if raw_mantissa == 0 then return false;

		return true;
	}

	return false;
}

is_inf :: (value : f64) -> bool #must
{
	uf := <<cast (*u64) *value;
	unbiased_exponent := cast (s32) ((uf >> 52) & 0x7ff);

	if unbiased_exponent == 0x7ff
	{
		raw_mantissa := uf & 0x000f_ffff_ffff_ffff;
		if raw_mantissa == 0 then return true;

		return false;
	}

	return false;
}

sign :: inline (val : $T) -> T #must
{
	     if val < 0 then return -1;
	else if val > 0 then return  1;

	return 0;
}

abs :: inline (val : $T) -> T #must
{
	if val < 0 then return -val;

	return val;
}

min :: inline (x : $T, y : T) -> T #must
{
	if y < x then return y;

	return x;
}

max :: inline (x : $T, y : T) -> T #must
{
	if y > x then return y;

	return x;
}

min :: (first : $T, args : ..T) -> T #must
{
	result := first;
	for args
	{
		if it < result then result = it;
	}

	return result;
}

max :: (first : $T, args : ..T) -> T #must
{
	result := first;
	for args
	{
		if it > result then result = it;
	}

	return result;
}

clamp :: inline (x : $T, min : T, max : T) -> T #must
{
	if x < min then return min;
	if x > max then return max;

	return x;
}

saturate :: clamp01;
clamp01 :: inline (x : $T) -> T #must
{
	return clamp (x, 0, 1);
}

round :: inline (x : $T) -> T #must
{
	return cast (T) (cast (int) (x + sign (x) * 0.5));
}

floor :: inline (x : $T) -> T #must
{
	i := cast (int) round (x);
	diff := x - i;

	return cast (T) (i - cast (int) (diff < 0));
}

ceil :: inline (x : $T) -> T #must
{
	i := cast (int) round (x);
	diff := i - x;

	return cast (T) (i + cast (int) (diff < 0));
}

wrap :: inline (a : int, min : int, max : int) -> int #must
{
	a += min;
	a %= (max - min);
	if a < 0 then a += (max - min);
	a -= min;

	return a;
}

wrap :: inline (a : int, max : int) -> int #must
{
	a %= max;
	if a < 0 then a += max;

	return a;
}

wrap :: inline (a : f32, max : f32) -> f32 #must
{
	a = fmod (a, max);
	if a < 0 then a += max;

	return a;
}

wrap :: inline (a : f32, min : f32, max : f32) -> f32 #must
{
	a += min;
	a = fmod (a, (max - min));
	if a < 0 then a += (max - min);
	a -= min;

	return a;
}

wrap :: inline (a : f64, max : f64) -> f64 #must
{
	a = fmod (a, max);
	if a < 0 then a += max;

	return a;
}

wrap :: inline (a : f64, min : f64, max : f64) -> f64 #must
{
	a += min;
	a = fmod (a, (max - min));
	if a < 0 then a += (max - min);
	a -= min;

	return a;
}

range_map :: inline (value : f32, low : f32, high : f32, mapped_low : f32, mapped_high : f32) -> f32 #must
{
	value -= low;
	value /= high - low;
	value *= mapped_high - mapped_low;
	value += mapped_low;

	return value;
}

range_map :: inline (value : f32, mapped_low : f32, mapped_high : f32) -> f32 #must
{
	return range_map (value, 0, 1, mapped_low, mapped_high);
}

range_map :: inline (value : f64, low : f64, high : f64, mapped_low : f64, mapped_high : f64) -> f64 #must
{
	value -= low;
	value /= high - low;
	value *= mapped_high - mapped_low;
	value += mapped_low;

	return value;
}

range_map :: inline (value : f64, mapped_low : f64, mapped_high : f64) -> f64 #must
{
	return range_map (value, 0, 1, mapped_low, mapped_high);
}

snap_up :: inline (value : f32, grid_size : f32) -> f32 #must
{
	return ceil (value / grid_size) * grid_size;
}

snap :: inline (value : f32, grid_size : f32) -> f32 #must
{
	return round (value / grid_size) * grid_size;
}

snap_down :: inline (value : f32, grid_size : f32) -> f32 #must
{
	return floor (value / grid_size) * grid_size;
}

lerp :: inline (a : $T, b : T, t : f32) -> T #must
{
	return cast (T) (a * (1 - t) + b * t);
}

sin   :: (angle : f64) -> f64 #foreign crt;
cos   :: (angle : f64) -> f64 #foreign crt;
tan   :: (angle : f64) -> f64 #foreign crt;
acos  :: (x : f64) -> f64 #foreign crt;
asin  :: (x : f64) -> f64 #foreign crt;
atan  :: (x : f64) -> f64 #foreign crt;
atan2 :: (y : f64, x : f64) -> f64 #foreign crt;
sqrt  :: (x : f64) -> f64 #foreign crt;
pow   :: (x : f64, power: f64) -> f64 #foreign crt;
exp   :: (x : f64) -> f64 #foreign crt;
fmod  :: (x : f64, divisor: f64) -> f64 #foreign crt;
log   :: (x : f64) -> f64 #foreign crt;

sin   :: (angle: f32) -> f32 #foreign crt "sinf";
cos   :: (angle: f32) -> f32 #foreign crt "cosf";
tan   :: (angle: f32) -> f32 #foreign crt "tanf";
acos  :: (x : f32) -> f32 #foreign crt "acosf";
asin  :: (x : f32) -> f32 #foreign crt "asinf";
atan  :: (x : f32) -> f32 #foreign crt "atanf";
atan2 :: (y : f32, x : f32) -> f32 #foreign crt "atan2f";
sqrt  :: (x : f32) -> f32 #foreign crt "sqrtf";
pow   :: (x : f32, power: f32) -> f32 #foreign crt "powf";
exp   :: (x : f32) -> f32 #foreign crt "expf";
fmod  :: (x : f32, divisor: f32) -> f32 #foreign crt "fmodf";   // x64 & arm only.
log   :: (x : f32) -> f32 #foreign crt "logf";

#scope_file

#if OS == .WINDOWS    then crt :: #foreign_system_library "msvcrt";
else #if OS == .LINUX then crt :: #foreign_system_library "libm";

#scope_export

// Flags

flagged :: inline (val : $T, flag : T) -> bool #must
{
	return (val & flag) == flag;
}

set_flag :: inline (val : *$T, flag : T)
{
	<<val |= flag;
}

set_flag :: inline (val : $T, flag : T) -> T #must
{
	return val | flag;
}

remove_flag :: inline (val : *$T, flag : T)
{
	<<val &= ~flag;
}

remove_flag :: inline (val : $T, flag : T) -> T #must
{
	return val & ~flag;
}

toggle_flag :: inline (val : *$T, flag : T)
{
	<<val ^= flag;
}

toggle_flag :: inline (val : $T, flag : T) -> T #must
{
	return val ^ flag;
}

initialize_item :: (ptr : *$T)
{
	initializer :: initializer_of (T);

#if initializer
{
	inline initializer (ptr);
}
else
{
	memset (ptr, 0, size_of (T));
}
}

// Allocation

align_address :: (addr : s64, align : s64) -> s64 #must
{
	assert (align > 0 && (align & (align - 1)) == 0, "Invalid alignment (got %, expected a power of two).", align);

	return (addr + (align - 1)) & -align;
}

#scope_file

ALIGNED_OVERFLOW_PAGE_ALLOCATION :: 32;

add_page :: (storage : *Temporary_Storage, min_size : s64) -> bool
{
	data_size := storage.original_size - ALIGNED_OVERFLOW_PAGE_ALLOCATION;
	data_size = max (data_size, min_size);
	total_size := data_size + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
	assert (storage.overflow_allocator != null, "Overflow allocator was null.");
	mem := alloc (total_size, storage.overflow_allocator, storage.overflow_allocator_data);
	if !mem then return false;

	page := cast (*Temporary_Storage.Overflow_Page) mem;
	page.next = storage.overflow_pages;
	page.allocator = storage.overflow_allocator;
	page.allocator_data = storage.overflow_allocator_data;
	page.size = data_size;

	storage.overflow_pages = page;
	storage.data = mem + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
	storage.size = data_size;
	storage.occupied = 0;
	
	return true;
}

free_pages :: (storage : *Temporary_Storage)
{
	current := storage.overflow_pages;
	while current
	{
		next := current.next;
		free (current, current.allocator, current.allocator_data);
		current = next;
	}
	storage.overflow_pages = null;
}

#scope_export

temp_allocator :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void
{
	ALIGNMENT :: 8;

	if #complete mode ==
	{
	case .FREE;
		return null;
		
	case .RESIZE; #through;
	case .ALLOCATE;
		storage := context.temporary_storage;
		// @Note (stefan): We could fall back to context.allocator like Basic if the temporary storage is null,
		// but what if the user just forgot to initialize a temporary storage? We don't want to possibly leak memory!
		assert (storage != null, "Temporary storage was null.");
		
		aligned_size := (size + 7) & ~7;
		if aligned_size > storage.size - storage.occupied
		{
			if !add_page (storage, aligned_size)
				return null;
		}
		
		result := storage.data + storage.occupied;
		storage.occupied += xx aligned_size;
		storage.high_water_mark = max (storage.high_water_mark, storage.occupied);
		if mode == .RESIZE
			memcpy (result, old_ptr, min (old_size, size));
		
		return result;
	}
	
	return null;
}

reset_temporary_storage :: ()
{
	storage := context.temporary_storage;
	if !storage then return;
	
	storage.data = storage.original_data;
	storage.size = storage.original_size;
	storage.occupied = 0;
	storage.high_water_mark = 0;
	free_pages (storage);
}

// heap_allocator is in amber_platform.jai, because it calls platform_heap_XXX and these are only accessible to
// extensions as hooks. We want extensions to be able to load amber_core.jai.

trap_allocator :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void		// We can't #must because we ignore the return value when mode == .FREE
{
	panic ("Called trap_allocator with parameters mode=%, size=%, old_size=%, old_ptr=%, allocator_data=%.", mode, size, old_size, old_ptr, allocator_data);

	return null;
}

alloc :: (size : s64, allocator : Allocator, allocator_data := null) -> *void #must
{
	assert (allocator != null, "Allocator is null.");
	if size == 0 then return null;
	
	return allocator (.ALLOCATE, size, 0, null, allocator_data);
}

realloc :: (ptr : *void, old_size : s64, new_size : s64, allocator : Allocator, allocator_data := null) -> *void #must
{
	assert (allocator != null, "Allocator is null.");
	if !ptr then return alloc (new_size, allocator, allocator_data);
	
	if new_size == 0
	{
		free (ptr, allocator, allocator_data);
	
		return null;
	}

	return allocator (.RESIZE, new_size, old_size, ptr, allocator_data);
}

free :: (ptr : *void, allocator : Allocator, allocator_data := null)
{
	assert (allocator != null, "Allocator is null.");
	if ptr then allocator (.FREE, 0, 0, ptr, allocator_data);
}

free :: (array : []$T, allocator : Allocator, allocator_data := null)
{
	inline free (array.data, allocator, allocator_data);
}

free :: (str : string, allocator : Allocator, allocator_data := null)
{
	inline free (str.data, allocator, allocator_data);
}

alloc_item :: ($T : Type, allocator : Allocator, allocator_data := null, $initialize := true) -> *T #must
{
	ptr := cast (*T) alloc (size_of (T), allocator, allocator_data);
#if initialize then initialize_item (ptr);

	return ptr;
}

// Allocating an array of 0 elements returns an array with a null data pointer and count = 0.
alloc_array :: inline ($T : Type, count : s64, allocator : Allocator, allocator_data := null, $initialize := true) -> []T #must
{
	assert (count >= 0, "Invalid count (got %, expected count >= 0).", count);

	result : []T = ---;
	result.count = count;
	result.data  = cast (*T) alloc (size_of (T) * count, allocator, allocator_data);

	if count > 0
	{
#if initialize
{
	initializer :: initializer_of (T);
	#if initializer
	{
		for * result
			initializer (it);
	}
	else
	{
		memset (result.data, 0, size_of (T) * count);
	}
}
	}

	return result;
}

alloc_string :: inline (count : s64, allocator : Allocator, allocator_data := null, $initialize := false) -> string #must
{
	array := inline alloc_array (u8, count, allocator, allocator_data, initialize);
	result : string = ---;
	result.count = array.count;
	result.data  = array.data;

	return result;
}

clone_array :: inline (array : []$T, allocator : Allocator, allocator_data := null) -> []T #must
{
	result : []T = ---;
	result.data = alloc (size_of (T) * array.count, allocator, allocator_data);
	memcpy (result.data, array.data, size_of (T) * array.count);
	result.count = array.count;
	
	return result;
}

// Array

init_array :: inline (array : *[..]$T, capacity : s64, allocator : Allocator, allocator_data := null)
{
	assert (capacity >= 0);
	array.data = alloc (size_of (T) * capacity, allocator, allocator_data);
	array.count = 0;
	array.allocated = capacity;
	array.allocator = allocator;
	array.allocator_data = allocator_data;
}

clear_array :: inline (array : *[..]$T)
{
	array.count = 0;
}

reset_array :: inline (array : *[..]$T)
{
	free (array.data, array.allocator, array.allocator_data);
	array.data = null;
	array.count = 0;
	array.allocated = 0;
}

grow_array :: inline (array : *[..]$T, additional_elements : s64)
{
	assert (array.allocator != null, "Array is not initialized (allocator is null). In the modules provided with the Jai compiler, a null allocator is treated as the context's allocator, but we prefer being explicit with what allocators are used.");
	new_capacity := array.allocated + additional_elements;
	new_data := realloc (array.data, size_of (T) * array.allocated, size_of (T) * new_capacity, array.allocator, array.allocator_data);
	array.data = new_data;
	array.allocated = new_capacity;
}

push_into_array :: inline (array : *[..]$T, $initialize := true) -> *T #must
{
	if array.count == array.allocated then grow_array (array, array.allocated + 8);
	ptr := *array.data[array.count];
#if initialize then initialize_item (ptr);
	array.count += 1;
	
	return ptr;
}

push_into_array :: inline (array : *[..]$T, item : T) -> *T
{
	ptr := push_into_array (array, initialize = false);
	<<ptr = item;
	
	return ptr;
}

pop_off_array :: inline (array : *[..]$T) -> T
{
	assert (array.count > 0);
	array.count -= 1;
	
	return array.data[array.count];
}

insert_into_array :: inline (array : *[..]$T, position : s64, $initialize := true) -> *T #must
{
	assert (position >= 0 && position <= array.count, "Index % out of range [%, %].", position, 0, array.count);
	
	if array.count == array.allocated then grow_array (array, array.allocated + 8);
	if position < array.count then push_into_array (array, array[position]);
#if initialize then initialize_item (*array[position]);

	return *array.data[position];
}

insert_into_array :: inline (array : *[..]$T, position : s64, item : T) -> *T
{
	ptr := insert_into_array (array, position, initialize = false);
	<<ptr = item;
	
	return ptr;
}

sorted_insert_into_array :: inline (array : *[..]$T, position : s64, $initialize := false) -> *T #must
{
	assert (position >= 0 && position <= array.count, "Index % out of range [%, %].", position, 0, array.count);

	if array.count == array.allocated then grow_array (array, array.count + 8);
	array.count += 1;
	for < i : array.count - 1..position + 1
		array.data[i] = array.data[i - 1];
	ptr := *array.data[position];
#if initialize then initialize_item (ptr);

	return ptr;
}

sorted_insert_into_array :: inline (array : *[..]$T, position : s64, elem : T) -> *T
{
	ptr := sorted_insert_into_array (array, position);
	<<ptr = elem;

	return ptr;
}

remove_from_array :: inline (array : *[..]$T, position : s64) -> T
{
	assert (position >= 0 && position <= array.count, "Index % out of range [%, %].", position, 0, array.count - 1);
	
	result := array.data[position];
	array.data[position] = array.data[array.count - 1];
	array.count -= 1;
	
	return result;
}

sorted_remove_from_array :: (array : *[..]$T, position : s64)
{
	assert (array.count > 0, "Index % out of range: array has no elements.", position);
	assert (position >= 0 && position < array.count, "Index % out of range [%, %].", position, 0, array.count - 1);

	for i : position..array.count - 2
		array.data[i] = array.data[i + 1];
	array.count -= 1;
}

advance :: (array : []$T, count := 1) -> []T #must
{
	if count > array.count then count = array.count;
	result := array;
	result.data  += count;
	result.count -= count;
	
	return result;
}

// String

advance :: (str : string, count := 1) -> string #must
{
	if count > str.count then count = str.count;
	result := str;
	result.data  += count;
	result.count -= count;

	return result;
}

null_terminated_length :: inline (ptr : *$T) -> s64 #must
{
	i := 0;
	while ptr[i]
		i += 1;
		
	return i;
}

cstring_length :: inline (cstr : *u8) -> s64 #must
{
	return null_terminated_length (cstr);
}

array_to_string :: (array : []u8) -> string #must
{
	result : string = ---;
	result.data  = array.data;
	result.count = array.count;
	
	return result;
}

cstring_to_string :: (cstr : *u8) -> string #must
{
	result : string;
	result.data  = cstr;
	result.count = cstring_length (cstr);

	return result;
}

to_array :: (str : string) -> []u8 #must
{
	result : []u8 = ---;
	result.data  = str.data;
	result.count = str.count;

	return result;
}

to_string :: (array : []u8) -> string #must { return inline array_to_string (array); }
to_string :: (cstr  :  *u8) -> string #must { return inline cstring_to_string (cstr); }	// @Note (stefan): This is already in Runtime_Support.jai, but it does not handle the case where cstr is null
// @Note (stefan): This must be a macro, because we take the address of char, which is on the stack if we use a function.
to_string :: (char : u8) -> string #expand
{
	result : string = ---;
	result.data = *char;
	result.count = 1;

	return result;
}

clone_string :: (cstr : *u8, allocator : Allocator, allocator_data := null) -> string #must
{
	return inline clone_string (to_string (cstr), allocator, allocator_data);
}

clone_string :: (str : string, allocator : Allocator, allocator_data := null) -> string #must
{
	result : string;
	result.data  = cast (*u8) alloc (str.count, allocator, allocator_data);
	result.count = str.count;
	memcpy (result.data, str.data, str.count);

	return result;
}

clone_to_array :: (str : string, allocator : Allocator, allocator_data := null) -> []u8 #must
{
	result : []u8;
	result.data  = cast (*u8) alloc (str.count, allocator, allocator_data);
	result.count = str.count;
	memcpy (result.data, str.data, str.count);

	return result;
}

clone_to_cstring :: (str : string, allocator : Allocator, allocator_data := null) -> *u8 #must
{
	result := cast (*u8) alloc (str.count + 1, allocator, allocator_data);
	memcpy (result, str.data, str.count);
	result[str.count] = 0;

	return result;
}

to_upper :: inline (char : u8) -> u8 #must
{
	if char >= #char "a" && char <= #char "z" then return char + #char "A" - #char "a";
	else return char;
}

to_lower :: inline (char : u8) -> u8 #must
{
	if char >= #char "A" && char <= #char "Z" then return char + #char "a" - #char "A";
	else return char;
}

to_upper :: inline (str : string)
{
	for i : 0..str.count - 1
	{
		str[i] = to_upper (str[i]);
	}
}

to_lower :: inline (str : string)
{
	for i : 0..str.count - 1
	{
		str[i] = to_lower (str[i]);
	}
}

clone_to_upper :: inline (str : string, allocator : Allocator, allocator_data := null) -> string #must
{
	result := clone_string (str, allocator, allocator_data);
	to_upper (result);

	return result;
}

clone_to_lower :: inline (str : string, allocator : Allocator, allocator_data := null) -> string #must
{
	result := clone_string (str, allocator, allocator_data);
	to_lower (result);

	return result;
}

digit_to_char :: inline (digit : int, base := 10) -> u8 #must
{
	assert (base >= 2 && base <= 16, "Invalid base (got %, expected base in [2, 16]).", base);
	assert (digit >= 0 && digit < base, "Invalid digit (got %, expected digit in [0, %]).", digit, base - 1);
	UP_TO_BASE16_DIGITS :: "0123456789abcdef";

	return UP_TO_BASE16_DIGITS[digit];
}

char_to_digit :: inline (char : u8, base := 10) -> int #must
{
	assert (base >= 2 && base <= 16, "Invalid base (got %, expected base in [2, 16]).", base);
	assert (is_digit (char, base), "Character % is not a digit of base %.", char, base);

	if char >= #char "0" && char <= #char "9" then return char - #char "0";
	if char >= #char "A" && char <= #char "F" then return 10 + char - #char "A";

	return 10 + char - #char "a";
}

is_space :: inline (codepoint : u32) -> bool #must
{
	return codepoint == #char " " || codepoint == #char "\t" || codepoint == #char "\n" || codepoint == #char "\r";
}

is_digit :: inline (codepoint : u32) -> bool #must
{
	return codepoint >= #char "0" && codepoint <= #char "9";
}

is_bin_digit :: inline (codepoint : u32) -> bool #must
{
	return codepoint == #char "0" || codepoint == #char "1";
}

is_hex_digit :: inline (codepoint : u32) -> bool #must
{
	return codepoint >= #char "0" && codepoint <= #char "9" ||
		   codepoint >= #char "a" && codepoint <= #char "f" ||
		   codepoint >= #char "A" && codepoint <= #char "F";
}

is_digit :: inline (codepoint : u32, base : s64) -> bool #must
{
	assert (base >= 2 && base <= 16, "Invalid base (got %, expected base in [2, 16]).", base);

	if base <= 10
	{
		return codepoint >= #char "0" && codepoint <= (#char "0" + base - 1);
	}
	else
	{
		return codepoint >= #char "0" && codepoint <= #char "9" ||
			   codepoint >= #char "a" && codepoint <= (#char "a" + base - 11) ||
			   codepoint >= #char "A" && codepoint <= (#char "A" + base - 11);
	}
}

is_alpha :: inline (codepoint : u32) -> bool #must
{
	return codepoint >= #char "a" && codepoint <= #char "z" ||
		   codepoint >= #char "A" && codepoint <= #char "Z";
}

is_alpha_num :: inline (codepoint : u32) -> bool #must
{
	return is_alpha (codepoint) || is_digit (codepoint) || codepoint == #char "_";
}

is_upper :: inline (codepoint : u32) -> bool #must
{
	return codepoint >= #char "A" && codepoint <= #char "Z";
}

is_lower :: inline (codepoint : u32) -> bool #must
{
	return codepoint >= #char "a" && codepoint <= #char "z";
}

starts_with :: (str : string, other : string) -> bool #must
{
	if str.count < other.count then return false;
	temp := str;
	temp.count = other.count;

	return temp == other;
}

join :: (allocator : Allocator, allocator_data : *void, args : ..string) -> string #must
{
	count : s64;
	for args
		count += it.count;

	result := alloc_string (count, allocator, allocator_data);
	offset : s64;
	for args
	{
		memcpy (result.data + offset, it.data, it.count);
		offset += it.count;
	}

	return result;
}

/*
join :: (allocator : Allocator, args : ..string) -> string #must
{
	return inline join (allocator, null, ..args);
}
*/

join_with_separator :: (allocator : Allocator, allocator_data : *void, separator : string, args : ..string) -> string #must
{
	count := 0;
	for args
	{
		count += it.count;
		if it_index != args.count - 1 then count += separator.count;
	}

	result := alloc_string (count, allocator, allocator_data);
	
	i := 0;
	for args
	{
		memcpy (result.data + i, it.data, it.count);
		i += it.count;
		memcpy (result.data + i, separator.data, separator.count);
		i += separator.count;
	}

	return result;
}

/*
join_with_separator :: (allocator : Allocator, separator : string, args : ..string) -> string #must
{
	return inline join_with_separator (allocator, null, separator, ..args);
}
*/

// String Builder

String_Builder :: [..]u8;

init_string_builder :: inline (builder : *String_Builder, capacity : s64, allocator : Allocator, allocator_data := null)
{
	inline init_array (builder, capacity, allocator, allocator_data);
}

reset_string_builder :: inline (builder : *String_Builder)
{
	inline reset_array (builder);
}

clear_string_builder :: inline (builder : *String_Builder)
{
	builder.count = 0;
}

grow_string_builder :: inline (builder : *String_Builder, additional_elements : s64)
{
	inline grow_array (builder, additional_elements);
}

builder_to_string :: inline (builder : String_Builder) -> string #must
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

builder_clone_to_string :: inline (builder : String_Builder, allocator : Allocator, allocator_data := null, $null_terminate := true) -> string #must
{
	result : string;
#if null_terminate count := builder.count + 1;
else               count := builder.count;
	result.data  = cast (*u8) alloc (count, allocator, allocator_data);
	memcpy (result.data, builder.data, builder.count);
	result.count = builder.count;
#if null_terminate result.data[result.count] = 0;

	return result;
}

builder_clone_to_cstring :: inline (builder : String_Builder, allocator : Allocator, allocator_data := null) -> *u8 #must
{
	result : *u8;
	result = cast (*u8) alloc (builder.count + 1, allocator, allocator_data);
	memcpy (result, builder.data, builder.count);
	result[builder.count] = 0;

	return result;
}

print_char_to_builder :: inline (builder : *String_Builder, char : u8)
{
	inline push_into_array (builder, char);
}

print_escaped_char_to_builder :: inline (builder : *String_Builder, char : u8)
{
	if char ==
	{
	case #char "\r";
		print_string_to_builder (builder, "\\r");

	case #char "\n";
		print_string_to_builder (builder, "\\n");

	case #char "\t";
		print_string_to_builder (builder, "\\t");

	case #char "\"";
		print_string_to_builder (builder, "\\\"");

	case #char "\\";
		print_string_to_builder (builder, "\\\\");

	case;
		print_char_to_builder (builder, char);
	}
}

print_string_to_builder :: inline (builder : *String_Builder, str : string)
{
	if builder.count + str.count > builder.allocated then grow_string_builder (builder, str.count + 128);
	memcpy (builder.data + builder.count, str.data, str.count);
	builder.count += str.count;
}

print_cstring_to_builder :: inline (builder : *String_Builder, cstr : *u8)
{
	str : string;
	str.data  = cstr;
	str.count = cstring_length (cstr);
	inline print_string_to_builder (builder, str);
}

print_escaped_string_to_builder :: inline (builder : *String_Builder, str : string)
{
	if builder.count + str.count > builder.allocated then grow_string_builder (builder, str.count + 128);

	print_char_to_builder (builder, #char "\"");
	for i : 0..str.count - 1
		print_escaped_char_to_builder (builder, str[i]);
	print_char_to_builder (builder, #char "\"");
}

Int_Format :: struct
{
	base := 10;
}

parse_int_formatting_string :: (format : string) -> Int_Format #must, format_was_valid : bool
{
	str := format;
	int_format : Int_Format;
	if str.count == 0 then return int_format, false;

	format_was_valid := true;
	if str == "0b" then int_format.base = 2;
	if str == "0o" then int_format.base = 8;
	if str == "0x" then int_format.base = 16;

	return int_format, format_was_valid;
}

print_s64_to_builder :: (builder : *String_Builder, value : s64, base := 10, print_base_prefix := false, min_digits := 1)
{
	if value < 0
	{
		value = -value;
		print_char_to_builder (builder, #char "-");
	}

	inline print_u64_to_builder (builder, cast (u64) value, base, print_base_prefix, min_digits);
}

print_u64_to_builder :: (builder : *String_Builder, value : u64, base := 10, print_base_prefix := false, min_digits := 1)
{
	assert (base > 1 && base <= 16, "Invalid base (got %, expected base in [2, 16]).", base);

	if print_base_prefix
	{
		if base ==
		{
		case 2;  print_string_to_builder (builder, "0b");
		case 8;  print_string_to_builder (builder, "0o");
		case 10;
		case 16; print_string_to_builder (builder, "0x");
		case;
			print_char_to_builder (builder, #char "b");
			print_u64_to_builder (builder, xx base);
			print_char_to_builder (builder, #char "_");
		}
	}

	dummy_value := value;
	digit_count := 0;
	if dummy_value == 0 then digit_count = 1;
	while dummy_value
	{
		digit_count += 1;
		dummy_value /= (xx base);
	}

	// The minimum base we can have is 2, and for a 64 bit number we can at most print 64 digits
	character_buffer : [64]u8 = ---;
	for i : 0..digit_count - 1
	{
		digit := value % (xx base);
		character_buffer[digit_count - 1 - i] = digit_to_char (xx digit, base);
		value /= xx base;
	}

	for i : 0..digit_count - 1  print_char_to_builder (builder, character_buffer[i]);
}

Float_Format :: struct
{
	digits_after_decimal := -1;
}

parse_float_formatting_string :: (format : string) -> Float_Format #must, format_was_valid : bool
{
	str := format;
	float_format : Float_Format;
	if str.count == 0 then return float_format, false;

	format_was_valid := true;
	if str[0] == #char "."
	{
		str = advance (str);
		digits, str, ok := string_to_u64 (str);
		float_format.digits_after_decimal = xx digits;
		if !ok then format_was_valid = false;
	}

	return float_format, format_was_valid;
}

print_f32_to_builder :: (builder : *String_Builder, value : f32, digits_after_decimal : int)
{
	inline print_f64_to_builder (builder, xx value, digits_after_decimal);
}

#scope_file

#import "stb_sprintf";

#scope_export

print_f64_to_builder :: (builder : *String_Builder, value : f64, digits_after_decimal : int)
{
	buffer : [100]u8;
	fmt : *u8;
	if digits_after_decimal != -1 then fmt = format_string_to_cstring (temp_allocator, "%%.%f", digits_after_decimal);
	else fmt = "%f";
	stbsp_snprintf (buffer.data, buffer.count, fmt, value);
	print_cstring_to_builder (builder, buffer.data);
}

print_bool_to_builder :: (builder : *String_Builder, value : bool)
{
	if value then print_string_to_builder (builder, "true");
	else          print_string_to_builder (builder, "false");
}

print_pointer_to_builder :: (builder : *String_Builder, value : *void)
{
	if value then print_u64_to_builder (builder, cast (u64) value, base = 16);
	else          print_string_to_builder (builder, "null");
}

print_type_to_builder :: (builder : *String_Builder, info : *Type_Info)
{
	if info.type ==
	{
	case .STRUCT;
		info_struct := cast (*Type_Info_Struct) info;

		if info_struct.name
		{
			print_string_to_builder (builder, info_struct.name);
		}
		else
		{
			if flagged (info_struct.struct_flags, .UNION)
				print_string_to_builder (builder, "(anonymous union)");
			else
				print_string_to_builder (builder, "(anonymous struct)");
		}

		if info_struct.polymorph_source_struct
		{
			print_string_to_builder (builder, "(");
			for * param : info_struct.specified_parameters
			{
				if it_index != 0 then print_string_to_builder (builder, ", ");
				print_string_to_builder (builder, param.name);

				if param.offset_into_constant_storage >= 0
				{
					print_string_to_builder (builder, " = ");
					param_value : Any;
					param_value.type = param.type;
					param_value.value_pointer = info_struct.constant_storage_buffer + param.offset_into_constant_storage;
					print_any_to_builder (builder, param_value, "");
				}
			}
			print_string_to_builder (builder, ")");
		}

	case .POINTER;
		info_pointer := cast (*Type_Info_Pointer) info;
		print_string_to_builder (builder, "*");
		if info_pointer.relative_pointer_size ==
		{
		case 1; print_string_to_builder (builder, "~s8 ");
		case 2; print_string_to_builder (builder, "~s16 ");
		case 4; print_string_to_builder (builder, "~s32 ");
		case 8; print_string_to_builder (builder, "~s64 ");
		}
		print_type_to_builder (builder, info_pointer.pointer_to);

	case .ARRAY;
		info_array := cast (*Type_Info_Array) info;
		if info_array.array_type ==
		{
		case .FIXED;     print_to_builder (builder, "[%]", info_array.array_count);
		case .VIEW;      print_to_builder (builder, "[]");
		case .RESIZABLE; print_to_builder (builder, "[..]");
		}
		print_type_to_builder (builder, info_array.element_type);

	case .TYPE;
		print_string_to_builder (builder, "Type");

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		if info_enum.name
			print_string_to_builder (builder, info_enum.name);
		else
			print_string_to_builder (builder, "(anonymous enum)");

	case .STRING;
		info_string := cast (*Type_Info_String) info;
		print_string_to_builder (builder, "string");
		if info_string.relative_pointer_size ==
		{
		case 1; print_string_to_builder (builder, "~s8");
		case 2; print_string_to_builder (builder, "~s16");
		case 4; print_string_to_builder (builder, "~s32");
		case 8; print_string_to_builder (builder, "~s64");
		}

	case .PROCEDURE;
		info_procedure := cast (*Type_Info_Procedure) info;
		print_string_to_builder (builder, "procedure ");
		print_string_to_builder (builder, "(");
		for info_procedure.argument_types
		{
			if it_index != 0 then print_string_to_builder (builder, ", ");
			print_type_to_builder (builder, it);
		}
		print_string_to_builder (builder, ")");

		if info_procedure.return_types
		{
			print_string_to_builder (builder, " -> ");
			if info_procedure.return_types.count > 1 then print_string_to_builder (builder, "(");
			for info_procedure.return_types
			{
				if it_index != 0 then print_string_to_builder (builder, ", ");
				print_type_to_builder (builder, it);
			}
			if info_procedure.return_types.count > 1 then print_string_to_builder (builder, ")");
		}

		proc_flags := info_procedure.procedure_flags;
		if proc_flags & .IS_ELSEWHERE    then print_string_to_builder (builder, " #elsewhere");
		if proc_flags & .IS_COMPILE_TIME then print_string_to_builder (builder, " #compiler");
		if proc_flags & .IS_C_CALL       then print_string_to_builder (builder, " #c_call");
		if proc_flags & .IS_INTRINSIC    then print_string_to_builder (builder, " #intrinsic");

	case .CODE;
		print_string_to_builder (builder, "Code");

	case .INTEGER;
		info_integer := cast (*Type_Info_Integer) info;
		if info_integer.runtime_size ==
		{
		case 1; print_string_to_builder (builder, ifx info_integer.signed then "s8"  else "u8");
		case 2; print_string_to_builder (builder, ifx info_integer.signed then "s16" else "u16");
		case 4; print_string_to_builder (builder, ifx info_integer.signed then "s32" else "u32");
		case 8; print_string_to_builder (builder, ifx info_integer.signed then "s64" else "u64");
		}

	case .FLOAT;
		if info.runtime_size == 
		{
		case 4; print_string_to_builder (builder, "f32");
		case 8; print_string_to_builder (builder, "f64");
		}

	case .BOOL;
		print_string_to_builder (builder, "bool");

	case .VOID;
		print_string_to_builder (builder, "void");

	case .VARIANT;
		info_variant := cast (*Type_Info_Variant) info;
		print_string_to_builder (builder, info_variant.name);
	
	case;
		print_string_to_builder (builder, "(unhandled type)");
	}
}

print_any_to_builder :: (builder : *String_Builder, item : Any, format := "", is_member_or_element := false)
{
	info := item.type;

	if info.type ==
	{
	case .STRING;
		if format == "escaped" || is_member_or_element
			print_escaped_string_to_builder (builder, any_to_string (item));
		else
			print_string_to_builder (builder, any_to_string (item));

	case .BOOL;
		print_bool_to_builder (builder, <<cast (*bool) item.value_pointer);

	case .INTEGER;
		info_integer := cast (*Type_Info_Integer) info;
		int_format := parse_int_formatting_string (format);
		if info_integer.signed then print_s64_to_builder (builder, any_sized_int_to_s64 (info_integer.runtime_size, item.value_pointer),  int_format.base);
		else                        print_u64_to_builder (builder, any_sized_uint_to_u64 (info_integer.runtime_size, item.value_pointer), int_format.base);

	case .FLOAT;
		info_float := cast (*Type_Info_Float) info;
		float_format := parse_float_formatting_string (format);
		if info_float.runtime_size ==
		{
		case 4; print_f64_to_builder (builder, xx <<cast (*f32) item.value_pointer, float_format.digits_after_decimal);
		case 8; print_f64_to_builder (builder, xx <<cast (*f64) item.value_pointer, float_format.digits_after_decimal);
		}

	case .ENUM;
		info_enum := cast (*Type_Info_Enum) info;
		info_integer := cast (*Type_Info_Integer) info_enum.internal_type;
		enum_value := 0;
		if info_integer.signed then enum_value = any_sized_int_to_s64 (info_integer.runtime_size, item.value_pointer);
		else                        enum_value = xx any_sized_uint_to_u64 (info_integer.runtime_size, item.value_pointer);

		if info_enum.enum_type_flags & .FLAGS
		{
			flags_value := cast (u64) enum_value;
			flags_printed : u64;
			first := true;
			for info_enum.values
			{
				value := cast (u64) it;
				flag := flags_value & value;
				if flag != value then flag = 0;
				if flag == 0 then continue;
				if !(flag & ~flags_printed) then continue;
				flags_printed |= flag;

				if !first then print_string_to_builder (builder, " | ");
				print_string_to_builder (builder, info_enum.names[it_index]);
				first = false;
			}

			out_of_range := flags_value & ~flags_printed;
			if out_of_range != 0
			{
				if !first then print_string_to_builder (builder, " | ");
				print_u64_to_builder (builder, out_of_range, base = 16, print_base_prefix = true);
			}
		}
		else
		{
			index := -1;
			for info_enum.values
			{
				if it == enum_value
				{
					index = it_index;

					break;
				}
			}

			if index == -1
			{
				print_string_to_builder (builder, info_enum.name);
				print_string_to_builder (builder, ", OoR (");
				print_s64_to_builder (builder, xx enum_value);
				print_string_to_builder (builder, ")");
			}
			else
			{
				print_string_to_builder (builder, info_enum.names[index]);
			}
		}

	case .POINTER;
		info_pointer := cast (*Type_Info_Pointer) info;

		// @Todo (stefan): Print the pointed type ?
		if info_pointer.relative_pointer_size
		{
			absolute_pointer, offset := relative_to_absolute_pointer (info_pointer.relative_pointer_size, item.value_pointer);
			if absolute_pointer
			{
				print_string_to_builder (builder, "~");
				print_s64_to_builder (builder, offset);
				print_string_to_builder (builder, " (");
				print_u64_to_builder (builder, cast (u64) absolute_pointer, base = 16);
				print_string_to_builder (builder, ")");
			}
			else
			{
				print_string_to_builder (builder, "~null");
			}
		}
		else
		{
			ptr := <<cast (**void) item.value_pointer;
			print_pointer_to_builder (builder, ptr);
		}

	case .VOID;
		print_string_to_builder (builder, "void");

	case .CODE;
		print_string_to_builder (builder, "Code");

	case .PROCEDURE;
		val := <<cast (**void) item.value_pointer;
		print_string_to_builder (builder, "procedure ");
		print_pointer_to_builder (builder, val);

	case .OVERLOAD_SET;
		print_string_to_builder (builder, "(procedure overloads)");

	case .TYPE;
		type_value := <<cast (**Type_Info) item.value_pointer;
		if type_value then print_type_to_builder (builder, type_value);
		else               print_string_to_builder (builder, "Type (null)");

	case .ARRAY;
		info_array := cast (*Type_Info_Array) info;
		print_type_to_builder (builder, info_array.element_type);
		print_string_to_builder (builder, ".[");

		count : s64;
		data  : *void;
		if info_array.array_type == .FIXED
		{
			count = info_array.array_count;
			data  = item.value_pointer;
		}
		else
		{
			if info_array.relative_pointer_size
			{
				size := info_array.relative_pointer_size;
				count = any_sized_int_to_s64 (size, item.value_pointer);
				data  = relative_to_absolute_pointer (size, item.value_pointer + size);
			}
			else
			{
				count = <<cast (*s64) item.value_pointer;
				data  = <<cast (**void) (item.value_pointer + 8);
			}
		}

		for i : 0..count - 1
		{
			curr : Any = ---;
			curr.type          = info_array.element_type;
			curr.value_pointer = data + info_array.element_type.runtime_size * i;
			print_string_to_builder (builder, " ");
			print_any_to_builder (builder, curr, "", is_member_or_element = true);
			if i < count - 1 then print_string_to_builder (builder, ",");
			print_string_to_builder (builder, " ");
		}
		print_string_to_builder (builder, "]");

	case .VARIANT;
		info_variant := cast (*Type_Info_Variant) info;
		new_any : Any;
		new_any.type = info_variant.variant_of;
		new_any.value_pointer = item.value_pointer;
		print_any_to_builder (builder, new_any, format, is_member_or_element);
	
	case;
		// @Todo (stefan): Structs
		print_string_to_builder (builder, "(unhandled type)");
	}
}

print_to_builder :: (builder : *String_Builder, fmt : string, args : ..Any)
{
	arg_index := 0;
	cursor := 0;
	printed := 0;
	while cursor < fmt.count
	{
		char := fmt[cursor];
		if arg_index == args.count || char != #char "%"
		{
			cursor += 1;

			continue;
		}

		str_to_print : string;
		str_to_print.data  = fmt.data + printed;
		str_to_print.count = cursor - printed;
		print_string_to_builder (builder, str_to_print); 
		cursor += 1;
		format_string := "";

		if cursor < fmt.count
		{
			next := fmt[cursor];
			// @Incomplete (stefan): When there is no arguments left, this prints '%%' instead of '%'. Fix this.
			if next == #char "%"
			{
				print_char_to_builder (builder, #char "%");
				cursor += 1;
				printed = cursor;

				continue;
			}

			// Read formatting string
			if next == #char "*"
			{
				fmt_cursor := cursor + 1;
				while fmt_cursor < fmt.count
				{
					current := fmt[fmt_cursor];
					if fmt_cursor == cursor + 1 && current == #char "*"
					{
						cursor += 1;

						break;
					}

					if current == #char "*"
					{
						format_string.data  = fmt.data + cursor + 1;
						format_string.count = fmt_cursor - cursor - 1;
						cursor = fmt_cursor + 1;

						break;
					}

					fmt_cursor += 1;
				}
			}
		}

		print_any_to_builder (builder, args[arg_index], format_string);
		arg_index += 1;
		printed = cursor;
	}

	str_to_print : string;
	str_to_print.data  = fmt.data + printed;
	str_to_print.count = cursor - printed;
	print_string_to_builder (builder, str_to_print);
}

print_line_to_builder :: inline (builder : *String_Builder, fmt : string, args : ..Any)
{
	print_to_builder (builder, fmt, ..args);
	print_string_to_builder (builder, "\n");
}

print_newline_to_builder :: inline (builder : *String_Builder)
{
	print_string_to_builder (builder, "\n");
}

// String formatting

print :: (fmt : string, args : ..Any)
{
	formatted := format_string (temp_allocator, fmt, ..args);
	write_string (formatted);
}

println :: (fmt : string, args : ..Any)
{
	inline print (fmt, ..args);
	inline print ("\n");
}

print :: (val : Any)
{
	inline print ("%", val);
}

println :: (val : Any)
{
	inline println ("%", val);
}

fstring :: format_string;
format_string :: (allocator : Allocator, allocator_data : *void, fmt : string, args : ..Any) -> string #must
{
	builder : String_Builder;
	init_string_builder (*builder, fmt.count + 128, allocator, allocator_data);
	print_to_builder (*builder, fmt, ..args);

	return builder_to_string (builder);
}

// @Note (stefan): We have this version because the two allocators we use most of the time is heap_allocator and temp_allocator and they don't need allocator_data.
// @Compiler_Bug (stefan): The compiler (beta 80) can't resolve between the overload above and the one below when trying to match the one above. It's fine for now because
// we never use the first one, but if we end up needing it then we'll have to wait until the bug is fixed.
format_string :: (allocator : Allocator, fmt : string, args : ..Any) -> string #must
{
	return inline format_string (allocator, null, fmt, ..args);
}

fcstring :: format_string_to_cstring;
format_string_to_cstring :: (allocator : Allocator, allocator_data : *void, fmt : string, args : ..Any) -> *u8 #must
{
	builder : String_Builder;
	init_string_builder (*builder, fmt.count + 128, allocator, allocator_data);
	print_to_builder (*builder, fmt, ..args);
	print_char_to_builder (*builder, 0);

	return builder.data;
}

format_string_to_cstring :: (allocator : Allocator, fmt : string, args : ..Any) -> *u8 #must
{
	return inline format_string_to_cstring (allocator, null, fmt, ..args);
}

// Any

any_to_s64 :: (item : Any) -> s64
{
	assert (item.type.type == .INTEGER);
	info_integer := cast (*Type_Info_Integer) item.type;

	if info_integer.signed
		return any_sized_int_to_s64 (info_integer.runtime_size, item.value_pointer);
	else
		return xx any_sized_uint_to_u64 (info_integer.runtime_size, item.value_pointer);
}

any_to_string :: (item : Any) -> string
{
	assert (item.type.type == .STRING);
	
	info_string := cast (*Type_Info_String) item.type;
	str : string = ---;
	if !info_string.relative_pointer_size
	{
		str = <<cast (*string) item.value_pointer;
	}
	else
	{
		ptr_size := info_string.relative_pointer_size;
		str.count = any_sized_int_to_s64 (ptr_size, item.value_pointer);
		str.data  = relative_to_absolute_pointer (ptr_size, cast (*u8) item.value_pointer + ptr_size);
	}

	return str;
}

any_sized_int_to_s64 :: (size : s64, ptr : *void) -> s64
{
	if size ==
	{
	case 1; return xx <<cast (*s8)  ptr;
	case 2; return xx <<cast (*s16) ptr;
	case 4; return xx <<cast (*s32) ptr;
	case 8; return xx <<cast (*s64) ptr;
	case;
		assert (false, "Invalid integer size.");
	}

	
	return 0;
}

any_sized_uint_to_u64 :: (size : s64, ptr : *void) -> u64
{
	if size ==
	{
	case 1; return xx <<cast (*u8)  ptr;
	case 2; return xx <<cast (*u16) ptr;
	case 4; return xx <<cast (*u32) ptr;
	case 8; return xx <<cast (*u64) ptr;
	case;
		assert (false, "Invalid unsigned integer size.");
	}

	
	return 0;
}

relative_to_absolute_pointer :: (size : s64, relative_ptr : *void) -> pointer : *void, offset : int
{
	offset := 0;
	if size ==
	{
	case 1;
		ival := <<cast (*s8) relative_ptr;
		if ival then offset = ival ^ 0x80;
		else return null, 0;
		
	case 2;
		ival := <<cast (*s16) relative_ptr;
		if ival then offset = ival ^ 0x8000;
		else return null, 0;

	case 4;
		ival := <<cast (*s32) relative_ptr;
		if ival then offset = ival ^ 0x8000_0000;
		else return null, 0;

	case 8;
		ival := <<cast (*s64) relative_ptr;
		if ival then offset = ival ^ 0x8000_0000_0000_0000;
		else return null, 0;

	case;
		assert (false, "Invalid relative pointer size.");
	}

	ptr := cast (*u8) relative_ptr + offset;

	return ptr, offset;
}

// String conversion

string_starts_with :: inline (str : string, with : string) -> bool
{
	if str.count < with.count then return false;
	for i : 0..with.count - 1
	{
		if str[i] != with[i] return false;
	}
	
	return true;
}

string_to_s64 :: (str : string) -> value : s64 #must, success : bool, remainder : string
{
	if str.count == 0 then return 0, false, str;

	negative := false;
	temp_str := str;
	if temp_str[0] == #char "-" || temp_str[0] == #char "+"
	{
		negative = temp_str[0] == #char "-";
		temp_str = advance (temp_str);
	}

	unsigned_value, success, remainder := string_to_u64 (temp_str);
	if !success then return 0, false, str;
	signed_value := cast (s64) unsigned_value;
	if negative then signed_value = -signed_value;

	return signed_value, true, remainder;
}

string_to_s64 :: (str : string, base : int) -> value : s64 #must, success : bool, remainder : string
{
	if str.count == 0 then return 0, false, str;

	negative := false;
	temp_str := str;
	if temp_str[0] == #char "-" || temp_str[0] == #char "+"
	{
		negative = temp_str[0] == #char "-";
		temp_str = advance (temp_str);
	}

	unsigned_value, success, remainder := string_to_u64 (temp_str, base);
	if !success then return 0, false, str;
	signed_value := cast (s64) unsigned_value;
	if negative then signed_value = -signed_value;

	return signed_value, true, remainder;
}

string_to_u64 :: (str : string) -> value : u64 #must, success : bool, remainder : string
{
	if str.count == 0 then return 0, false, str;
	
	base := 10;
	curr := str;
	if starts_with (curr, "0b")
	{
		base = 2;
		curr = advance (curr, "0b".count);
	}
	else if starts_with (curr, "0o")
	{
		base = 8;
		curr = advance (curr, "0o".count);
	}
	else if starts_with (curr, "0x")
	{
		base = 16;
		curr = advance (curr, "0x".count);
	}
	else if starts_with (curr, "b")
	{
		curr = advance (curr);
		val, ok, remainder := string_to_u64 (curr, 16);
		if !ok then return 0, false, str;
		base = xx val;
		curr = remainder;
		curr = advance (curr);
	}
	
	value, success, remainder := string_to_u64 (curr, base);
	
	return value, success, remainder;
}

string_to_u64 :: (str : string, base : int) -> value : u64 #must, success : bool, remainder : string
{
	if str.count == 0 then return 0, false, str;

	curr := str;	
	digit_count := 0;
	while digit_count < curr.count
	{
		if !is_digit (curr[digit_count], base) then break;
		digit_count += 1;
	}

	if digit_count == 0 then return 0, false, str;

	result : u64;
	x := 1;
	for i : 0..digit_count - 1
	{
		digit  := char_to_digit (curr[digit_count - 1 - i], base);
		result += xx (digit * x);
		x      *= base;
	}

	return result, true, advance (curr, xx digit_count);
}

string_to_bool :: (str : string, $treat_01_as_bool := true) -> value : bool #must, success : bool, remainder : string
{
	starts_with :: (str : string, with : string) -> bool
	{
		if str.count < with.count then return false;

		i := 0;
		while i < with.count
		{
			if str[i] != with[i] then return false;
			i += 1;
		}

		if i != str.count && is_alpha_num (str[i]) then return false;

		return true;
	}

	if str.count == 0 then return false, false, str;

	if string_starts_with (str, "true")  then return true, true, advance (str, "true".count);
	if string_starts_with (str, "false") then return false, true, advance (str, "false".count);
#if treat_01_as_bool
{
	if string_starts_with (str, "1") then return true, true, advance (str, "1".count);
	if string_starts_with (str, "0") then return false, true, advance (str, "0".count);
}

	return false, false, str;
}

// @Note (stefan): I assure you this is useful!
string_to_string :: inline (str : string) -> string, bool
{
	return str, true;
}

// Vec2

vec2f :: make_vec2f;
make_vec2f :: inline (x : f32 = 0, y : f32 = 0) -> Vec2f #must
{
	return make_vec2 (x, y);
}

make_vec2f :: inline (vec : $V/Vec2) -> Vec2f #must
{
	return make_vec2f (xx vec.x, xx vec.y);
}

vec2i :: make_vec2i;
make_vec2i :: inline (x : s32 = 0, y : s32 = 0) -> Vec2i #must
{
	return make_vec2 (x, y);
}

make_vec2i :: inline (vec : $V/Vec2) -> Vec2i #must
{
	return make_vec2i (xx vec.x, xx vec.y);
}

vec2 :: make_vec2;
make_vec2 :: inline (x : $T, y : T) -> Vec2 (T) #must
{
	result : Vec2 (T) = ---;
	result.x = x;
	result.y = y;
	
	return result;
}

clamp :: inline (vec : Vec2f, min : Vec2f, max : Vec2f) -> Vec2f #must
{
	result : Vec2f = ---;
	result.x = clamp (vec.x, min.x, max.x);
	result.y = clamp (vec.y, min.y, max.y);
	
	return result;
}

round :: inline (vec : Vec2f) -> Vec2f #must
{
	result : Vec2f = ---;
	result.x = round (vec.x);
	result.y = round (vec.y);
	
	return result;
}

/*
floor :: inline (vec : $V/Vec2) -> V #must
{
	result : V = ---;
	result.x = floor (vec.x);
	result.y = floor (vec.y);
	
	return result;
}

ceil :: inline (vec : $V/Vec2) -> V #must
{
	result : V = ---;
	result.x = ceil (vec.x);
	result.y = ceil (vec.y);
	
	return result;
}
*/

dot :: inline (left : $V/Vec2, right : V) -> V.T #must
{
	return left.x * right.x + left.y * right.y;
}

sqrd_length :: inline (using vec : $V/Vec2) -> V.T #must
{
	return x * x + y * y;
}

length :: inline (vec : $V/Vec2) -> V.T #must
{
	sq_len := sqrd_length (vec);
	
	return sqrt (sq_len);
}

normalized :: inline (using vec : $V/Vec2, fallback : V = .{ 0, 0 }) -> V #must
{
	len := length (vec);
	if len == 0 then return fallback;
	
	return vec2 (x / len, y / len);
}

angle :: inline (a : $V/Vec2, b : V) -> V.T #must
{
	return atan2 (a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y);
}

operator + :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x + right.x;
	result.y = left.y + right.y;
	
	return result;
}

operator - :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x - right.x;
	result.y = left.y - right.y;
	
	return result;
}

operator - :: inline (vec : $V/Vec2) -> V #must
{
	result : V = ---;
	result.x = -vec.x;
	result.y = -vec.y;
	
	return result;
}

operator * :: inline (vec : $V/Vec2, scalar : V.T) -> V #must #symmetric
{
	result : V = ---;
	result.x = vec.x * scalar;
	result.y = vec.y * scalar;
	
	return result;
}

operator / :: inline (vec : $V/Vec2, scalar : V.T) -> V #must
{
	result : V = ---;
	result.x = vec.x / scalar;
	result.y = vec.y / scalar;
	
	return result;
}

operator == :: inline (left : $V/Vec2, right : V) -> bool #must
{
	return left.x == right.x && left.y == right.y;
}

// Rect

rectf :: make_rectf;
ltrbf :: make_rectf;
make_rectf :: inline (x1 : f32, y1 : f32, x2 : f32, y2 : f32) -> Rectf #must
{
	return make_rect (x1, y1, x2, y2);
}

make_rectf :: inline (other : $R/Rect) -> Rectf #must
{
	return make_rectf (xx other.x1, xx other.y1, xx other.x2, xx other.y2);
}

xywhf :: make_rectf_size;
make_rectf_size :: inline (x : f32, y : f32, w : f32, h : f32) -> Rectf #must
{
	return make_rect_size (x, y, w, h);
}

recti :: make_recti;
ltrbi :: make_recti;
make_recti :: inline (x1 : s32, y1 : s32, x2 : s32, y2 : s32) -> Recti #must
{
	return make_rect (x1, y1, x2, y2);
}

make_recti :: inline (other : $R/Rect) -> Recti #must
{
	return make_recti (xx other.x1, xx other.y1, xx other.x2, xx other.y2);
}

xywhi :: make_recti_size;
make_recti_size :: inline (x : s32, y : s32, w : s32, h : s32) -> Recti #must
{
	return make_rect_size (x, y, w, h);
}

ltrb :: make_rect;
make_rect :: inline (x1 : $T, y1 : T, x2 : T, y2 : T) -> Rect (T) #must
{
	result : Rect (T) = ---;
	result.x1 = x1;
	result.y1 = y1;
	result.x2 = x2;
	result.y2 = y2;
	
	return result;
}

xywh :: make_rect_size;
make_rect_size :: inline (x : $T, y : T, w : T, h : T) -> Rect (T) #must
{
	result : Rect (T) = ---;
	result.x1 = x;
	result.y1 = y;
	result.x2 = x + w;
	result.y2 = y + h;
	
	return result;
}

rect_top_left :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.left, rect.top);
}

rect_top_right :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.right, rect.top);
}

rect_bottom_left :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.left, rect.bottom);
}

rect_bottom_right :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (rect.right, rect.bottom);
}

rect_x :: inline (using rect : $R/Rect) -> R.T #must
{
	return x1;
}

rect_y :: inline (using rect : $R/Rect) -> R.T #must
{
	return y1;
}

rect_width :: inline (using rect : $R/Rect) -> R.T #must
{
	return x2 - x1;
}

rect_height :: inline (using rect : $R/Rect) -> R.T #must
{
	return y2 - y1;
}

rect_position :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (x1, y1);
}

rect_size :: inline (using rect : $R/Rect) -> R.V #must
{
	return vec2 (x2 - x1, y2 - y1);
}

expand_all_sides :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.x1 -= amount;
	result.y1 -= amount;
	result.x2 += amount;
	result.y2 += amount;
	
	return result;
}

expand_left :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.left -= amount;
	
	return result;
}

expand_top :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.top -= amount;
	
	return result;
}

expand_right :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.right += amount;
	
	return result;
}

expand_bottom :: inline (using rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.bottom += amount;
	
	return result;
}

truncate_all_sides :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.x1 += amount;
	result.y1 += amount;
	result.x2 -= amount;
	result.y2 -= amount;
	
	return result;
}

truncate_left :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.left += amount;
	
	return result;
}

truncate_top :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.top += amount;
	
	return result;
}

truncate_right :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.right -= amount;
	
	return result;
}

truncate_bottom :: inline (rect : $R/Rect, amount : R.T) -> R #must
{
	result := rect;
	result.bottom -= amount;
	
	return result;
}

set_position :: inline (rect : $R/Rect, new_x : R.T, new_y : R.T) -> R #must
{
	width  := rect_width (rect);
	height := rect_height (rect);
	result : R = ---;
	result.x1 = new_x;
	result.y1 = new_y;
	result.x2 = new_x + width;
	result.y2 = new_y + height;
	
	return result;
}

set_position :: inline (rect : $R/Rect, new_position : R.V) -> R #must
{
	return set_position (rect, new_position.x, new_position.y);
}

move :: inline (rect : $R/Rect, x_amount : R.T, y_amount : R.T) -> R #must
{
	result := rect;
	result.x1 += x_amount;
	result.y1 += y_amount;
	result.x2 += x_amount;
	result.y2 += y_amount;
	
	return result;
}

move :: inline (rect : $R/Rect, amount : R.V) -> R #must
{
	return move (rect, amount.x, amount.y);
}

set_width :: inline (rect : $R/Rect, new_w : R.T) -> R #must
{
	result := rect;
	result.x2 = result.x1 + new_w;
	
	return result;
}

set_height :: inline (rect : $R/Rect, new_h : R.T) -> R #must
{
	result := rect;
	result.y2 = result.y1 + new_h;
	
	return result;
}

set_size :: inline (rect : $R/Rect, new_w : R.T, new_h : R.T) -> R #must
{
	result := rect;
	result.x2 = result.x1 + new_w;
	result.y2 = result.y1 + new_h;
	
	return result;
}

set_size :: inline (rect : $R/Rect, new_size : R.V) -> R #must
{
	return set_size (rect, new_size.w, new_size.h);
}

grow :: inline (rect : $R/Rect, x_amount : R.T, y_amount : R.T) -> R #must
{
	result := rect;
	result.x2 += x_amount;
	result.y2 += y_amount;
	
	return result;
}

grow :: inline (rect : $R/Rect, amount : R.V) -> R #must
{
	return grow (rect, amount.w, amount.h);
}

clip :: inline (rect : $R/Rect, clip_by : R) -> R #must
{
	result : R = ---;
	result.x1 = max (rect.x1, clip_by.x1);
	result.y1 = max (rect.y1, clip_by.y1);
	result.x2 = min (rect.x2, clip_by.x2);
	result.y2 = min (rect.y2, clip_by.y2);
	
	return result;
}

contains :: inline (rect : $R/Rect, point : R.V) -> bool #must
{
	return point.x >= rect.x1 && point.x <= rect.x2 && point.y >= rect.y1 && point.y <= rect.y2;
}

operator == :: inline (left : $R/Rect, right : R) -> bool #must
{
	return left.x1 == right.x1 && left.y1 == right.y1 && left.x2 == right.x2 && left.y2 == right.y2;
}

// RGBA

rgba :: make_rgba;
make_rgba :: inline (r : u8, g : u8, b : u8, a : u8 = 255) -> RGBA #must
{
	result : RGBA = ---;
	result.r = r;
	result.g = g;
	result.b = b;
	result.a = a;
	
	return result;
}

make_rgba :: inline (using color : RGBAf) -> RGBA #must
{
	result : RGBA = ---;
	result.r = cast (u8) (r * 255);
	result.g = cast (u8) (g * 255);
	result.b = cast (u8) (b * 255);
	result.a = cast (u8) (a * 255);
	
	return result;
}

make_rgba :: inline (color : RGBA, a : u8) -> RGBA #must
{
	result : RGBA = ---;
	result.r = color.r;
	result.g = color.g;
	result.b = color.b;
	result.a = a;
	
	return result;
}

operator == :: inline (left : RGBA, right : RGBA) -> bool #must
{
	return left.r == right.r && left.g == right.g && left.b == right.b && left.a == right.a;
}

// RGBAf

rgbaf :: make_rgbaf;
make_rgbaf :: inline (r : f32 = 0, g : f32 = 0, b : f32 = 0, a : f32 = 0) ->  RGBAf #must
{
	result : RGBAf = ---;
	result.r = saturate (r);
	result.g = saturate (g);
	result.b = saturate (b);
	result.a = saturate (a);
	
	return result;
}

make_rgbaf :: inline (using color : RGBA) -> RGBAf #must
{
	result : RGBAf = ---;
	result.r = r / 255.0;
	result.g = g / 255.0;
	result.b = b / 255.0;
	result.a = a / 255.0;
	
	return result;
}

invert :: inline (using color : RGBA) -> RGBA #must
{
	result : RGBA = ---;
	result.r = 255 - r;
	result.g = 255 - g;
	result.b = 255 - b;
	result.a = a;
	
	return result;
}

dim :: inline (using color : RGBA, factor : f32) -> RGBA #must
{
	result : RGBA = ---;
	result.r = xx clamp (r / factor, 0, 255);
	result.g = xx clamp (g / factor, 0, 255);
	result.b = xx clamp (b / factor, 0, 255);
	result.a = a;
	
	return result;
}

operator == :: inline (left : RGBAf, right : RGBAf) -> bool #must
{
	return left.r == right.r && left.g == right.g && left.b == right.b && left.a == right.a;
}

// Range

rangei :: make_rangei;
make_rangei :: inline (min : s64, max : s64) -> Rangei #must
{
	return make_range (min, max);
}

rangef :: make_rangef;
make_rangef :: inline (min : f32, max : f32) -> Rangef #must
{
	return make_range (min, max);
}

make_range :: inline (min : $T, max : T) -> Range (T) #must
{
	result : Range (T) = ---;
	result.min = min;
	result.max = max;
	
	return result;
}

length :: inline (range : $R/Range) -> R.T #must
{
	return abs (range.max - range.min) + 1;
}

signed_length :: inline (range : $R/Range) -> R.T #must
{
	return (range.max + 1) - range.min;
}

contains :: inline (range : $R/Range, value : R.T) -> bool #must
{
	return value >= range.min && value <= range.max;
}

operator == :: inline (left : $R/Range, right : R) -> bool #must
{
	return left.min == right.min && left.max == right.max;
}

// Hashing

FNV_OFFSET_BASIS_32 : u32 : 0x811c_9dc5;
FNV_PRIME_32        : u32 : 0x0100_0193;

FNV_OFFSET_BASIS_64 : u64 : 0xcbf2_9ce4_8422_2325;
FNV_PRIME_64        : u64 : 0x0000_0100_0000_01b3;

fnv1_hash :: (data : *void, count : s64) -> u32 #must
{
	hash := FNV_OFFSET_BASIS_32;

	for i : 0..count - 1 #no_abc
	{
		hash *= FNV_PRIME_32;
		hash ^= (cast (*u8) data)[i];
	}

	return hash;
}

fnv1a_hash :: (data : *void, count : s64) -> u32 #must
{
	hash := FNV_OFFSET_BASIS_32;

	for i : 0..count - 1 #no_abc
	{
		hash ^= (cast (*u8) data)[i];
		hash *= FNV_PRIME_32;
	}

	return hash;
}

fnv1_hash64 :: (data : *void, count : s64) -> u64 #must
{
	hash := FNV_OFFSET_BASIS_64;

	for i : 0..count - 1 #no_abc
	{
		hash *= FNV_PRIME_64;
		hash ^= (cast (*u8) data)[i];
	}

	return hash;
}

fnv1a_hash64 :: (data : *void, count : s64) -> u64 #must
{
	hash := FNV_OFFSET_BASIS_64;

	for i : 0..count - 1 #no_abc
	{
		hash ^= (cast (*u8) data)[i];
		hash *= FNV_PRIME_64;
	}

	return hash;
}

/* http://www.cse.yorku.ca/~oz/hash.html:
 *
 * "This algorithm (k=33) was first reported by dan bernstein many years ago in comp.lang.c. another version of this algorithm
 * (now favored by bernstein) uses xor:
 * 
 * hash(i) = hash(i - 1) * 33 ^ str[i];
 * 
 * the magic of number 33 (why it works better than many other constants, prime or not) has never been adequately explained.
 */
DJB2_DEFAULT_BASIS :: 5_381;
djb2_hash :: (data : *void, count : s64, h : u32 = DJB2_DEFAULT_BASIS) -> u32 #must
{
	for i : 0..count - 1 #no_abc
	{
		//h = (h << 5) + hash + (cast (*u8) data)[i];
		h = h * 33 ^ (cast (*u8) data)[i];
	}

	return h;
}

/* http://www.cse.yorku.ca/~oz/hash.html:
 *
 * "This algorithm was created for sdbm (a public-domain reimplementation of ndbm) database library. it was found to do well in
 * scrambling bits, causing better distribution of the keys and fewer splits. it also happens to be a good general hashing function
 * with good distribution. the actual function is
 *
 * hash(i) = hash(i - 1) * 65599 + str[i];
 *
 * what is included below is the faster version used in gawk. [there is even a faster, duff-device version] the magic constant 65599
 * was picked out of thin air while experimenting with different constants, and turns out to be a prime. this is one of the algorithms
 * used in berkeley db (see sleepycat) and elsewhere."
 */
SDBM_DEFAULT_BASIS :: 5_381;
sdbm_hash :: (data : *void, count : s64, h : u32 = SDBM_DEFAULT_BASIS) -> u32 #must
{
	for i : 0..count - 1 #no_abc
	{
		h = (h << 16) + (h << 6) - h + (cast (*u8) data)[i];
	}

	return h;
}

default_hash :: (str : string) -> u32 #must
{
	return fnv1a_hash (str.data, str.count);
}

default_hash64 :: (str : string) -> u64 #must
{
	return fnv1a_hash64 (str.data, str.count);
}

default_hash :: (val : $T) -> u32 #must
{
	return sdbm_hash (*val, size_of (T));
}

// Hash map

Hash_Map :: struct (
	TKey : Type,
	TVal : Type,
	hash_func : (TKey) -> u32 = null,
	comp_func : (TKey, TKey) -> bool = null,
	EXPAND_LIMIT := 70
)
{
	Entry :: struct
	{
		hash  : u32;
		key   : TKey;
		value : TVal;
	}

	count     : s64;
	allocated : s64;
	occupied  : s64;
	entries   : []Entry;

	allocator      : Allocator;
	allocator_data : *void;

#if hash_func
{
	hash_key :: hash_func;
}
else
{
	hash_key :: (key : TKey) -> u32
	{
		return default_hash (key);
	}
}

#if comp_func
{
	compare_keys :: comp_func;
}
else
{
	compare_keys :: (left : TKey, right : TKey) -> bool
	{
		return left == right;
	}
}

	MIN_CAPACITY        :: 32;
	NEVER_OCCUPIED_HASH :: 0;
	REMOVED_HASH        :: 1;
	FIRST_OCCUPIED_HASH :: 2;
}

for_expansion :: (map : *$T/Hash_Map, body : Code, flags : For_Flags) #expand
{
	for * entry, i : map.entries
	{
		if entry.hash < map.FIRST_OCCUPIED_HASH then continue;
		
		`it_index := entry.key;
#if flags & .POINTER
		`it := *entry.value;
else
		`it := entry.value;
		#insert (remove = { entry.hash = REMOVED_HASH; map.count -= 1; }) body;
	}
}

init_map :: (map : *Hash_Map, capacity : s64, allocator : Allocator, allocator_data := null)
{
	capacity = next_power_of_two (capacity);
	capacity = min (capacity, map.MIN_CAPACITY);
	
	map.count = 0;
	map.occupied = 0;
	map.allocated = capacity;
	map.allocator = allocator;
	map.allocator_data = allocator_data;
	map.entries = alloc_array (map.Entry, capacity, allocator, allocator_data);
	for * map.entries
		it.hash = map.NEVER_OCCUPIED_HASH;
}

reset_map :: (using map : *Hash_Map)
{
	free (entries.data, allocator, allocator_data);
	entries.data = null;
	entries.count = 0;
	count = 0;
	occupied = 0;
	allocated = 0;
}

clear_map :: (using map : *Hash_Map)
{
	count = 0;
	occupied = 0;
	for * entries
		it.hash = NEVER_OCCUPIED_HASH;
}

expand_map :: (map : *Hash_Map)
{
	old_entries := map.entries;
	new_capacity := map.allocated * 2;
	new_capacity = max (new_capacity, map.MIN_CAPACITY);
	
	map.entries = alloc_array (map.Entry, new_capacity, map.allocator, map.allocator_data);
	map.count = 0;
	map.occupied = 0;
	map.allocated = new_capacity;
	for entry, i : old_entries
	{
		if entry.hash >= map.FIRST_OCCUPIED_HASH
			insert_into_map (map, entry.key, entry.value);
	}
	free (old_entries.data, map.allocator, map.allocator_data);
}

insert_into_map :: (map : *Hash_Map, key : map.TKey, $initialize := true) -> *map.TVal #must, was_present : bool
{
	if (map.occupied + 1) * 100 >= map.allocated * map.EXPAND_LIMIT
		expand_map (map);
	assert (map.occupied <= map.allocated);
	
	hash := map.hash_key (key);
	if hash < map.FIRST_OCCUPIED_HASH then hash += map.FIRST_OCCUPIED_HASH;
	index := hash & (map.allocated - 1);
	
	// Check if the key-value pair is already in the map
	while map.entries[index].hash
	{
		entry := *map.entries[index];
		if entry.hash == hash && map.compare_keys (entry.key, key)
			return *entry.value, true;
		index += 1;
		if index >= map.allocated then index = 0;
	}
	
	map.occupied += 1;
	map.count    += 1;
	
	entry := *map.entries[index];
	entry.hash = hash;
	entry.key  = key;
#if initialize then initialize_item (*entry.value);

	return *entry.value, false;
}

insert_into_map :: (map : *Hash_Map, key : map.TKey, value : map.TVal) -> *map.TVal, was_present : bool
{
	ptr, was_present := insert_into_map (map, key);
	<<ptr = value;
	
	return ptr, was_present;
}

remove_from_map :: (map : *Hash_Map, key : map.TKey) -> found : bool
{
	hash := map.hash_key (key);
	if hash < map.FIRST_OCCUPIED_HASH then hash += map.FIRST_OCCUPIED_HASH;
	
	index := hash & (map.allocated - 1);
	while map.entries[index].hash
	{
		entry := *map.entries[index];
		
		if entry.hash == hash && map.compare_keys (entry.key, key)
		{
			entry.hash = REMOVED_HASH;
			map.count -= 1;
			
			return true;
		}
		
		index += 1;
		if index >= map.allocated then index = 0;
	}
	
	return false;
}

set_value :: (map : *Hash_Map, key : map.TKey, value : map.TVal)
{
	ptr := get_pointer (map, key);
	if ptr then <<ptr = value;
}

get_pointer :: (map : Hash_Map, key : map.TKey) -> *map.TVal #must
{
	if map.count == 0 then return null;
	
	hash := map.hash_key (key);
	if hash < map.FIRST_OCCUPIED_HASH then hash += map.FIRST_OCCUPIED_HASH;
	index := hash & (map.allocated - 1);
	
	while map.entries[index].hash
	{
		entry := *map.entries[index];
		if entry.hash == hash && map.compare_keys (entry.key, key)
			return *entry.value;
		index += 1;
		if index >= map.allocated then index = 0;
	}
	
	return null;
}

get_pointer :: (map : *Hash_Map, key : map.TKey) -> *map.TVal #must
{
	return inline get_pointer (<<map, key);
}

get_value :: (map : Hash_Map, key : map.TKey, fallback : map.TVal) -> map.TVal #must, found : bool
{
	ptr := inline get_pointer (map, key);
	if ptr then return <<ptr, true;

	return fallback, false;
}

get_value :: (map : *Hash_Map, key : map.TKey, fallback : map.TVal) -> map.TVal #must, found : bool
{
	ptr := inline get_pointer (map, key);
	if ptr then return <<ptr, true;

	return fallback, false;
}

next_power_of_two :: inline (x : s64) -> s64 #must
{
	assert (x > 0, "Invalid x (got %, expected x > 0).", x);
	p := 1;
	while x > p
		p += p;
	
	return p;
}

// Slot array

Slot_Array :: struct (T : Type)
{
	Slot :: struct
	{
		occupied : bool;
		value    : T;
	}
	
	allocated : s64;
	count     : s64;
	max_occupied : s64;
	slots        : *Slot;

	allocator      : Allocator;
	allocator_data : *void;
}

for_expansion :: (array : *Slot_Array, body : Code, flags : For_Flags) #expand
{
	BY_POINTER :: (flags & .POINTER) == .POINTER;
	REVERSE    :: (flags & .REVERSE) == .REVERSE;
	
#if REVERSE
{
	start := array.max_occupied - 1;
	end   := 0;
}
else
{
	start := 0;
	end   := array.max_occupied - 1;
}

	`it_index : s64;
	for <=REVERSE it_index : start..end
	{
		if !array.slots[it_index].occupied then continue;
		
#if BY_POINTER
		`it := *array.slots[it_index].value;
else
		`it := array.slots[it_index].value;
		#insert (remove = remove_from_slot_array (array, it_index)) body;
	}
}

operator [] :: inline (using array : Slot_Array, index : s64) -> array.T #must
{
	assert (index >= 0 && index < max_occupied, "Invalid index (expected [0,%), got %).", max_occupied, index);
	assert (slots[index].occupied, "Array slot is not occupied (index was %).", index);
	
	return slots[index].value;
}

get_value :: inline (using array : Slot_Array, index : s64) -> array.T #must
{
	assert (index >= 0 && index < max_occupied, "Invalid index (expected [0,%), got %).", max_occupied, index);
	assert (slots[index].occupied, "Array slot is not occupied (index was %).", index);
	
	return slots[index].value;
}

get_ptr :: inline (using array : *Slot_Array, index : s64) -> *array.T #must
{
	assert (index >= 0 && index < max_occupied, "Invalid index (expected [0,%), got %).", max_occupied, index);
	assert (slots[index].occupied, "Array slot is not occupied (index was %).", index);
	
	return *slots[index].value;
}

init_slot_array :: inline (array : *Slot_Array, capacity : s64, allocator : Allocator, allocator_data := null)
{
	array.allocated = capacity;
	array.count = 0;
	array.max_occupied = 0;
	array.slots = alloc (size_of (array.Slot) * capacity, allocator, allocator_data);
	for i : 0..array.allocated - 1
		array.slots[i].occupied = false;
	array.allocator = allocator;
	array.allocator_data = allocator_data;
}

reset_slot_array :: inline (using array : *Slot_Array)
{
	free (data, allocator, allocator_data);
	slots = null;
	max_occupied = 0;
	count = 0;
	allocated = 0;
}

clear_slot_array :: inline (using array : *Slot_Array)
{
	for i : 0..max_occupied - 1
		slots[i].occupied = false;
	max_occupied = 0;
}

grow_slot_array :: inline (using array : *Slot_Array, additional_elements : s64)
{
	assert (allocator != null, "Slot array is not initialized: allocator is null.");
	new_capacity := allocated + additional_elements;
	new_slots    := cast (*array.Slot) alloc (size_of (array.Slot) * new_capacity, allocator, allocator_data);
	memcpy (new_slots, slots, size_of (array.Slot) * max_occupied);
	free (slots, allocator, allocator_data);
	slots = new_slots;
	allocated = new_capacity;
	for i : max_occupied..allocated - 1
		slots[i].occupied = false;
}

insert_into_slot_array :: inline (using array : *Slot_Array, $initialize := true) -> *array.T #must, index : s64
{
	index := max_occupied;
	for i : 0..max_occupied - 1
	{
		if !slots[i].occupied
		{
			index = i;
		
			break;
		}
	}
	if index == allocated then grow_slot_array (array, allocated + 8);
	if index >= max_occupied then max_occupied = index + 1;
	count += 1;
	slots[index].occupied = true;
#if initialize
	initialize_item (*slots[index].value);
	
	return *slots[index].value, index;
}

insert_into_slot_array :: inline (using array : *Slot_Array, item : array.T) -> *array.T, index : s64
{
	ptr, index := insert_into_slot_array (array, initialize = false);
	<<ptr = item;
	
	return ptr, index;
}

remove_from_slot_array :: inline (using array : *Slot_Array, index : s64)
{
	assert (index >= 0 && index < max_occupied, "Invalid index (expected [0,%), got %).", max_occupied, index);
	slots[index].occupied = false;
	count -= 1;
	if index == max_occupied - 1
	{
		max_occupied -= 1;
		for < i : index - 1..0
		{
			if slots[i].occupied
				break;
			max_occupied -= 1;
		}
	}
}

// Filename utils

filename_get_basename :: inline (filename : string) -> string #must
{
	result := filename;
	result.data += result.count;
	result.count = 0;
	if result.count != filename.count && (result.data[-1] == #char "/" || result.data[-1] == #char "\\")
	{
		result.data -= 1;
		result.count += 1;
	}
	while result.count != filename.count
	{
		if result.data[-1] == #char "/" || result.data[-1] == #char "\\"
			break;
		result.data  -= 1;
		result.count += 1;
	}
	
	return result;
}

filename_get_extension :: inline (filename : string) -> string #must
{
	result := filename;
	result.data += result.count;
	result.count = 0;
	while result.count != filename.count
	{
		if result.data[-1] == #char "."
			break;
		if result.data[-1] == #char "/" || result.data[-1] == #char "\\"
			return "";
		result.data  -= 1;
		result.count += 1;
	}
	
	return result;
}

filename_remove_basename :: inline (filename : string) -> string #must
{
	basename := filename_get_basename (filename);
	result := filename;
	result.count = basename.data - filename.data;
	
	return result;
}

filename_remove_extension :: inline (filename : string) -> string #must
{
	extension := filename_get_extension (filename);
	if !extension then return filename;
	result := filename;
	result.count = extension.data - filename.data - 1;
	
	return result;
}
