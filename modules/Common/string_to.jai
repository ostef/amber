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
	string_starts_with :: (str : string, with : string) -> bool
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
