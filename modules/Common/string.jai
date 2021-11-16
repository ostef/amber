starts_with :: (str : string, other : string) -> bool #must
{
	if str.count < other.count then return false;

	return trim (str, str.count - other.count) == other;
}

starts_with_word :: (str : string, other : string) -> bool #must
{
	if str.count < other.count then return false;

	matches := trim (str, str.count - other.count) == other;
	ends_with_space := ifx str.count - other.count == 0 then true else is_space (str[other.count]);

	return matches && ends_with_space;
}

advance :: (str : string, count : int = 1) -> string #must
{
	if count > str.count then count = str.count;
	result := str;
	result.data  += count;
	result.count -= count;

	return result;
}

trim :: (str : string, count : int = 1) -> string #must, trimmed : string
{
	if count > str.count then count = str.count;
	result := str;
	result.count -= count;
	trimmed := str;
	trimmed.data += count;

	return result, trimmed;
}

trim_matched_at_ends :: (str : string, lookup : string) -> string #must
{
	result := str;
	while result.count > 0
	{
		advanced := false;
		for i : 0..lookup.count - 1
		{
			if result[0] == lookup[i]
			{
				result = advance (result);
				advanced = true;
				
				break;
			}
		}
		
		if !advanced then break;
	}

	while result.count > 0
	{
		trimmed := false;
		for i : 0..lookup.count - 1
		{
			if result[result.count - 1] == lookup[i]
			{
				result = trim (result);
				trimmed = true;
				
				break;
			}
		}
		
		if !trimmed then break;
	}

	return result;
}

skip_spaces :: (str : string) -> string #must, skipped : int
{
	result := str;
	while result.count && is_space (result[0]) result = advance (result);

	return result, result.data - str.data;
}

trim_spaces_at_ends :: (str : string) -> string #must
{
	result := skip_spaces (str);
	while result.count && is_space (result[result.count - 1]) result = trim (result);
	
	return result;
}

break_by :: (str : string, lookup : string, allocator : Allocator, allocator_data := null) -> []string #must
{
	result := make_array (string, 10, allocator, allocator_data);
	start := 0;
	for i : 0..str.count - 1
	{
		if find_first_occurence (lookup, to_string (str[i])) != -1
		{
			word : string;
			word.data = str.data + start;
			word.count = i - start;
			if word.count != 0 then push_to_array (*result, word);
			start = i + 1;
		}
	}

	if start != str.count
	{
		word : string;
		word.data = str.data + start;
		word.count = str.count - start;
		if word.count != 0 then push_to_array (*result, word);
	}

	return result;
}

break_by_spaces :: (str : string, allocator : Allocator, allocator_data := null) -> []string #must
{
	result := make_array (string, 10, allocator, allocator_data);
	start := 0;
	for i : 0..str.count - 1
	{
		if is_space (str[i])
		{
			word : string;
			word.data = str.data + start;
			word.count = i - start;
			word = skip_spaces (word);
			if word.count != 0 then push_to_array (*result, word);
			start = i + 1;
		}
	}

	if start != str.count
	{
		word : string;
		word.data = str.data + start;
		word.count = str.count - start;
		word = skip_spaces (word);
		if word.count != 0 then push_to_array (*result, word);
	}

	return result;
}

break_by_lines :: (str : string, allocator : Allocator, allocator_data := null) -> []string #must
{
	result := make_array (string, 10, allocator, allocator_data);
	start := 0;
	for i : 0..str.count - 1
	{
		if str[i] == #char "\r" || str[i] == #char "\n"
		{
			line : string;
			line.data = str.data + start;
			line.count = i - start;
			if line.count != 0 then push_to_array (*result, line);
			start = i + 1;
		}
	}

	if start != str.count
	{
		line : string;
		line.data = str.data + start;
		line.count = str.count - start;
		if line.count != 0 then push_to_array (*result, line);
	}

	return result;
}

is_null_terminated :: (str : string) -> bool #must
{
	return str[str.count - 1] == 0;
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

cstring_length :: (cstr : *u8) -> int #must
{
	if !cstr then return 0;

	count := 0;
	while cstr[count]
	{
		count += 1;
	}

	return count;
}

cstring_equals :: (left : *u8, right : *u8) -> bool #must
{
	if left == right then return true;
	if !left || !right then return false;

	while <<left && <<right
	{
		if <<left != <<right then return false;
		left  += 1;
		right += 1;
	}

	if <<left || <<right then return false;

	return true;
}

compare_strings :: (a: string, b: string) -> s64 #must
{
	i := 0;
	while i < a.count - 1 && i < b.count - 1 && a[i] == b[i]
		i += 1;

	return cast (s64) a[i] - cast (s64) b[i];
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

is_digit :: inline (codepoint : u32, base : int) -> bool #must
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

join :: (allocator : Allocator, allocator_data : *void, args : ..string) -> string #must
{
	count : s64;
	for args
	{
		count += it.count;
	}

	result := alloc_string (count, allocator, allocator_data);
	offset : s64;
	for args
	{
		memcpy (result.data + offset, it.data, it.count);
		offset += it.count;
	}

	return result;
}

join :: (allocator : Allocator, args : ..string) -> string #must
{
	return inline join (allocator, null, ..args);
}

join_with_separator :: (allocator : Allocator, allocator_data : *void, args : ..string, separator : string) -> string #must
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

join_with_separator :: (allocator : Allocator, args : ..string, separator : string) -> string #must
{
	return inline join_with_separator (allocator, null, ..args, separator);
}

slice :: (str : string, low : s64, high : s64) -> string #must
{
	array := slice (to_array (str), low, high);
	
	return to_string (array);
}

find_first_occurence_of_string :: (str : string, other : string) -> index : s64 #must
{
	for i : 0..str.count - 1 - (other.count - 1)
	{
		for j : 0..other.count - 1
		{
			if str[i + j] != other[j] then continue i;
		}

		return i;
	}

	return -1;
}

find_last_occurence_of_string :: (str : string, other : string) -> index : s64 #must
{
	for < i : str.count - 1 - (other.count - 1)..0
	{
		for j : 0..other.count - 1
		{
			if str[i + j] != other[j] then continue i;
		}

		return i;
	}

	return -1;
}

find_first_occurence :: (str : string, lookup : string) -> index : s64 #must
{
	for i : 0..str.count - 1
	{
		for j : 0..lookup.count - 1
		{
			if lookup[j] == str[i] then return i;
		}
	}

	return -1;
}

find_last_occurence :: (str : string, lookup : string) -> index : s64 #must
{
	for < i : str.count - 1..0
	{
		for j : 0..lookup.count - 1
		{
			if lookup[j] == str[i] then return i;
		}
	}

	return -1;
}
