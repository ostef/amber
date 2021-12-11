#scope_module

ryu_assert :: (expr : Code, location := #caller_location) #expand
{
	value := #insert expr;
	if !value
	{
		// Prevent assert ()->...->assert ()->...->assert ()->...->assert () infinite loop (format_string might assert for example)
		if context.handling_assertion_failure then return;
		context.handling_assertion_failure = true;
		context.assertion_failed (location, "");
		context.handling_assertion_failure = false;
	}
}

// Returns the number of decimal digits in v, which must not contain more than 9 digits.
decimal_length9 :: inline (v : u32) -> u32 #must
{
	// Function precondition: v is not a 10-digit number.
	// (f2s: 9 digits are sufficient for round-tripping.)
	// (d2fixed: We print 9-digit blocks.)
	ryu_assert (v < 1000000000);
	if v >= 100000000 then return 9;
	if v >=  10000000 then return 8;
	if v >=   1000000 then return 7;
	if v >=    100000 then return 6;
	if v >=     10000 then return 5;
	if v >=      1000 then return 4;
	if v >=       100 then return 3;
	if v >=        10 then return 2;
	
	return 1;
}

// Returns e == 0 ? 1 : [log_2(5^e)]; requires 0 <= e <= 3528.
log2pow5 :: inline (e : s32) -> s32 #must
{
	// This approximation works up to the point that the multiplication overflows at e = 3529.
	// If the multiplication were done in 64 bits, it would fail at 5^4004 which is just greater
	// than 2^9297.
	ryu_assert (e >= 0);
	ryu_assert (e <= 3528);

	return cast (s32) ((cast (u32) e * 1217359) >> 19);
}

// Returns e == 0 ? 1 : ceil(log_2(5^e)); requires 0 <= e <= 3528.
pow5bits :: inline (e : s32) -> s32 #must
{
	// This approximation works up to the point that the multiplication overflows at e = 3529.
	// If the multiplication were done in 64 bits, it would fail at 5^4004 which is just greater
	// than 2^9297.
	ryu_assert (e >= 0);
	ryu_assert (e <= 3528);

	return cast (s32) ((cast (u32) e * 1217359) >> 19) + 1;
}

// Returns e == 0 ? 1 : ceil(log_2(5^e)); requires 0 <= e <= 3528.
ceil_log2pow5 :: inline (e : s32) -> s32 #must
{
	return log2pow5 (e) + 1;
}

// Returns floor(log_10(2^e)); requires 0 <= e <= 1650.
log10pow2 :: inline (e : s32) -> u32 #must
{
	// The first value this approximation fails for is 2^1651 which is just greater than 10^297.
	ryu_assert (e >= 0);
	ryu_assert (e <= 1650);

	return (cast (u32) e * 78913) >> 18;
}

// Returns floor(log_10(5^e)); requires 0 <= e <= 2620.
log10pow5 :: inline (e : s32) -> u32 #must
{
	// The first value this approximation fails for is 5^2621 which is just greater than 10^1832.
	ryu_assert (e >= 0);
	ryu_assert (e <= 2620);

	return (cast (u32) e * 732923) >> 20;
}

copy_special_str :: inline (result : *u8, sign : bool, exponent : bool, mantissa : bool) -> s32
{
	if mantissa
	{
		memcpy (result, "NaN".data, 3);

		return 3;
	}
	if sign
		result[0] = #char "-";
	if exponent
	{
		memcpy (result + cast (s32) sign, "Inf".data, 3);

		return cast (s32) sign + 3;
	}

	memcpy (result + cast (s32) sign, "0e0".data, 3);
	
	return cast (s32) sign + 3;
}

f32_to_bits :: inline (f : f32) -> u32 #must
{
	bits : u32 = 0;
	memcpy (*bits, *f, size_of (f32));

	return bits;
}

f64_to_bits :: inline (f : f64) -> u64 #must
{
	bits : u64 = 0;
	memcpy (*bits, *f, size_of (f64));

	return bits;
}
