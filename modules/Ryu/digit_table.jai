#scope_module

// A table of all two-digit numbers. This is used to speed up decimal digit
// generation by copying pairs of digits into the final output.
DIGIT_TABLE :: #insert -> string
{
	result : [203]u8;
	result[0] = #char "\"";
	for i : 0..9
	{
		for j : 0..9
		{
			result[1 + i * 20 + j * 2] = cast (u8) (#char "0" + i);
			result[1 + i * 20 + j * 2 + 1] = cast (u8) (#char "0" + j);
		}
	}
	result[201] = #char "\"";
	result[202] = #char ";";
	str : string = ---;
	str.data = result.data;
	str.count = result.count;

	return str;
}
