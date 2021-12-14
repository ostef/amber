#scope_file

F64_MANTISSA_BITS :: 52;
F64_EXPONENT_BITS :: 11;
F64_BIAS          :: 1023;

POW10_ADDITIONAL_BITS :: 120;

mul_shift_mod1e9 :: inline (m : u64, mul : *u64, j : s32) -> u32
{
#if DEBUG
{
	println ("mul[0]=%", mul[0]);
	println ("mul[1]=%", mul[1]);
	println ("mul[2]=%", mul[2]);
}
	high0 : u64 = ---;						// 64
	low0 := umul128 (m, mul[0], *high0);	// 0
	high1 : u64 = ---;						// 128
	low1 := umul128 (m, mul[1], *high1);	// 64
	high2 : u64 = ---;						// 192
	low2 := umul128 (m, mul[2], *high2);	// 128
#if DEBUG
{
	println ("high0=%", high0);
	println ("low0=%", low0);
	println ("high1=%", high1);
	println ("low1=%", low1);
	println ("high2=%", high2);
	println ("low2=%", low2);
}
	//s0low := low0;					// 0, unused
	s0high := low1 + high0;				// 64
	c1 := cast (u32) (s0high < low1);
	s1low := low2 + high1 + c1;			// 128
	c2 := cast (u32) (s1low < low2);	// high1 + c1 can't overflow, so compare against low2
	s1high := high2 + c2;				// 192
#if DEBUG
{
	if j < 128 || j > 180
		println (j);
}
	ryu_assert (j >= 128);
	ryu_assert (j <= 180);
	if j < 160	// j: [128, 160)
	{
		r0 := cast (u64) mod1e9 (s1high);
		r1 := cast (u64) mod1e9 ((r0 << 32) | (s1low >> 32));
		r2 := cast (u64) ((r1 << 32) | (s1low & 0xffffffff));
		result := mod1e9 (r2 >> (j - 128));
#if DEBUG
{
		println ("j < 160, result=%", result);
}
		return result;
	}
	else	// j: [160, 192)
	{
		r0 := cast (u64) mod1e9 (s1high);
		r1 := cast (u64) ((r0 << 32) | (s1low >> 32));
		result := mod1e9 (r1 >> (j - 160));
#if DEBUG
{
		println ("j >= 160, result=%", result);
}
		return result;
	}
	return 0;	// Unreachable
}

// Convert `digits` to a sequence of decimal digits. Append the digits to the result.
// The caller has to guarantee that:
//   10^(olength-1) <= digits < 10^olength
// e.g., by passing `olength` as `decimalLength9(digits)`.
append_n_digits :: inline (olength : u32, digits : u32, result : *u8)
{
#if DEBUG
{
	println ("DIGITS=%", digits);
}
	i : u32 = 0;
	while digits >= 10000
	{
		c : u32 = digits % 10000;
		digits /= 10000;
		c0 : u32 = (c % 100) << 1;
		c1 : u32 = (c / 100) << 1;
		memcpy (result + olength - i - 2, DIGIT_TABLE.data + c0, 2);
		memcpy (result + olength - i - 4, DIGIT_TABLE.data + c1, 2);
		i += 4;
	}
	if digits >= 100
	{
		c : u32 = (digits % 100) << 1;
		digits /= 100;
		memcpy (result + olength - i - 2, DIGIT_TABLE.data + c, 2);
		i += 2;
	}
	if digits >= 10
	{
		c : u32 = digits << 1;
		memcpy (result + olength - i - 2, DIGIT_TABLE.data + c, 2);
	}
	else
	{
		result[0] = cast (u8) (#char "0" + digits);
	}
}

// Convert `digits` to a sequence of decimal digits. Print the first digit, followed by a decimal
// dot '.' followed by the remaining digits. The caller has to guarantee that:
//   10^(olength-1) <= digits < 10^olength
// e.g., by passing `olength` as `decimalLength9(digits)`.
append_d_digits :: inline (olength : u32, digits : u32, result : *u8)
{
#if DEBUG
{
	println ("DIGITS=%", digits);
}
	i : u32 = 0;
	while digits >= 10000
	{
		c : u32 = digits % 10000;
		digits /= 10000;
		c0 : u32 = (c % 100) << 1;
		c1 : u32 = (c / 100) << 1;
		memcpy (result + olength + 1 - i - 2, DIGIT_TABLE.data + c0, 2);
		memcpy (result + olength + 1 - i - 4, DIGIT_TABLE.data + c1, 2);
		i += 4;
	}
	if digits >= 100
	{
		c : u32 = (digits % 100) << 1;
		digits /= 100;
		memcpy (result + olength + 1 - i - 2, DIGIT_TABLE.data + c, 2);
		i += 2;
	}
	if digits >= 10
	{
		c : u32 = digits << 1;
		result[2] = DIGIT_TABLE[c + 1];
		result[1] = #char ".";
		result[0] = DIGIT_TABLE[c];
	}
	else
	{
		result[1] = #char ".";
		result[0] = cast (u8) (#char "0" + digits);
	}
}

// Convert `digits` to decimal and write the last `count` decimal digits to result.
// If `digits` contains additional digits, then those are silently ignored.
append_c_digits :: inline (count : u32, digits : u32, result : *u8)
{
#if DEBUG
{
	println ("DIGITS=%", digits);
}
	// Copy pairs of digits from DIGIT_TABLE.
	i : u32 = 0;
	while (i < count - 1)
	{
		c : u32 = (digits % 100) << 1;
		digits /= 100;
		memcpy (result + count - i - 2, DIGIT_TABLE.data + c, 2);
		i += 2;
	}
	// Generate the last digit if count is odd.
	if i < count
		result[count - i - 1] = cast (u8) (#char "0" + (digits % 10));
}

// Convert `digits` to decimal and write the last 9 decimal digits to result.
// If `digits` contains additional digits, then those are silently ignored.
append_nine_digits :: inline (digits : u32, result : *u8)
{
#if DEBUG
{
	println ("DIGITS=%", digits);
}
	if digits == 0
	{
		memset (result, #char "0", 9);

		return;
	}
	i : u32 = 0;
	while i < 5
	{
		c : u32 = digits % 10000;
		digits /= 10000;
		c0 : u32 = (c % 100) << 1;
		c1 : u32 = (c / 100) << 1;
		memcpy (result + 7 - i, DIGIT_TABLE.data + c0, 2);
		memcpy (result + 5 - i, DIGIT_TABLE.data + c1, 2);
		i += 4;
	}
	result[0] = cast (u8) (#char "0" + digits);
}

index_for_exponent :: inline (e : u32) -> u32 #must
{
	return (e + 15) / 16;
}

pow10_bits_for_index :: inline (idx : u32) -> u32 #must
{
	return 16 * idx + POW10_ADDITIONAL_BITS;
}

length_for_index :: inline (idx : u32) -> u32 #must
{
	// +1 for ceil, +16 for mantissa, +8 to round up when dividing by 9
	return (log10pow2 (16 * cast (s32) idx) + 1 + 16 + 8) / 9;
}

copy_special_str_printf :: inline (result : *u8, sign : bool, mantissa : u64) -> s32
{
	if mantissa
	{
		memcpy (result, NAN_STRING.data, NAN_STRING.count);

		return NAN_STRING.count;
	}
	if sign
		result[0] = #char "-";
	memcpy (result + cast (s32) sign, INF_STRING.data, INF_STRING.count);

	return cast (s32) sign + INF_STRING.count;
}

#scope_export

f64_to_fixed_buffered :: (f : f64, precision : u32, result : *u8) -> s32
{
	bits := f64_to_bits (f);
#if DEBUG
{
	print ("IN=");
	for < bit : 63..0
		print (((bits >> bit) & 1));
	print ("\n");
}
	// Decode bits into sign, mantissa, and exponent.
	ieee_sign := ((bits >> (F64_MANTISSA_BITS + F64_EXPONENT_BITS)) & 1) != 0;
	ieee_mantissa := bits & ((1 << F64_MANTISSA_BITS) - 1);
	ieee_exponent := cast (u32) ((bits >> F64_MANTISSA_BITS) & ((1 << F64_EXPONENT_BITS) - 1));

	// Case distinction; exit early for the easy cases.
	if ieee_exponent == ((1 << F64_EXPONENT_BITS) - 1)
		return copy_special_str_printf (result, ieee_sign, ieee_mantissa);
	if ieee_exponent == 0 && ieee_mantissa == 0
	{
		index : s32 = 0;
		if ieee_sign
		{
			result[index] = #char "-";
			index += 1;
		}
		result[index] = #char "0";
		index += 1;
		if precision > 0
		{
			result[index] = #char ".";
			index += 1;
			memset (result + index, #char "0", precision);
			index += cast (s32) precision;
		}

		return index;
	}

	e2 : s32 = ---;
	m2 : u64 = ---;
	if ieee_exponent == 0
	{
		e2 = 1 - F64_BIAS - F64_MANTISSA_BITS;
		m2 = ieee_mantissa;
	}
	else
	{
		e2 = cast (s32) ieee_exponent - F64_BIAS - F64_MANTISSA_BITS;
		m2 = (1 << F64_MANTISSA_BITS) | ieee_mantissa;
	}

#if DEBUG
{
	println ("-> % * 2^%", m2, e2);
}

	index : s32 = 0;
	nonzero := false;
	if ieee_sign
	{
		result[index] = #char "-";
		index += 1;
	}
	if e2 >= -52
	{
		idx := ifx e2 < 0 then 0 else index_for_exponent (cast (u32) e2);
		p10bits := pow10_bits_for_index (idx);
		len := cast (s32) length_for_index (idx);
#if DEBUG
{
	println ("idx=%", idx);
	println ("len=%", len);
}
		for < i : len - 1..0
		{
			j := cast (u32) (cast (s32) p10bits - e2);
			// Temporary: j is usually around 128, and by shifting a bit, we push it to 128 or above, which is
			// a slightly faster code path in mulShift_mod1e9. Instead, we can just increase the multipliers.
			digits := mul_shift_mod1e9 (m2 << 8, POW10_SPLIT[POW10_OFFSET[idx] + i].data, cast (s32) (j + 8));
			if nonzero
			{
				append_nine_digits (digits, result + index);
				index += 9;
			}
			else if digits != 0
			{
				olength := decimal_length9 (digits);
				append_n_digits (olength, digits, result + index);
				index += cast (s32) olength;
				nonzero = true;
			}
		}
	}
	if !nonzero
	{
		result[index] = #char "0";
		index += 1;
	}
	if precision > 0
	{
		result[index] = #char ".";
		index += 1;
	}
#if DEBUG
{
	println ("e2=%", e2);
}
	if e2 < 0
	{
		idx := -e2 / 16;
#if DEBUG
{
		println ("idx=%", idx);
}
		blocks := precision / 9 + 1;
		// 0 = don't round up; 1 = round up unconditionally; 2 = round up if odd.
		round_up : s32 = 0;
		i : u32 = 0;
		if blocks <= MIN_BLOCK_2[idx]
		{
			i = blocks;
			memset (result + index, #char "0", precision);
			index += cast (s32) precision;
		}
		else if i < MIN_BLOCK_2[idx]
		{
			i = MIN_BLOCK_2[idx];
			memset (result + index, #char "0", 9 * i);
			index += cast (s32) (9 * i);
		}
		while i < blocks
		{
			j := ADDITIONAL_BITS_2 + (-e2 - 16 * idx);
			p := POW10_OFFSET_2[idx] + i - MIN_BLOCK_2[idx];
			if p >= POW10_OFFSET_2[idx + 1]
			{
				// If the remaining digits are all 0, then we might as well use memset.
				// No rounding required in this case.
				fill := precision - 9 * i;
				memset (result + index, #char "0", fill);
				index += cast (s32) fill;

				break;
			}
			// Temporary: j is usually around 128, and by shifting a bit, we push it to 128 or above, which is
			// a slightly faster code path in mulShift_mod1e9. Instead, we can just increase the multipliers.
			digits := mul_shift_mod1e9 (m2 << 8, POW10_SPLIT_2[p].data, j + 8);
#if DEBUG
{
			println ("digits=%", digits);
}
			if i < blocks - 1
			{
				append_nine_digits (digits, result + index);
				index += 9;
			}
			else
			{
				maximum := precision - 9 * i;
				last_digit : u32 = 0;
				for k : 0..9 - cast (s32) maximum - 1
				{
					last_digit = digits % 10;
					digits /= 10;
				}
#if DEBUG
{
				println ("last_digit=%", last_digit);
}
				if last_digit != 5
				{
					round_up = cast (s32) (last_digit > 5);
				}
				else
				{
					// Is m * 10^(additionalDigits + 1) / 2^(-e2) integer?
					required_twos := -e2 - cast (s32) precision - 1;
					trailing_zeroes := required_twos <= 0 || (required_twos < 60 && multiple_of_power_of_2 (m2, cast (u32) required_twos));
					round_up = cast (s32) (ifx trailing_zeroes then 2 else 1);
#if DEBUG
{
					println ("required_twos=%", required_twos);
					println ("trailing_zeroes=%", trailing_zeroes);
}
				}
				if maximum > 0
				{
					append_c_digits (maximum, digits, result + index);
					index += cast (s32) maximum;
				}

				break;
			}
			i += 1;
		}
#if DEBUG
{
		println ("round_up=%", round_up);
}

		if round_up != 0
		{
			round_index := index;
			dot_index : s32 = 0;	// '.' can't be located at index 0
			while true
			{
				round_index -= 1;
				c := result[round_index];
				if round_index == -1 || c  == #char "-"
				{
					result[round_index + 1] = #char "1";
					if dot_index > 0
					{
						result[dot_index] = #char "0";
						result[dot_index + 1] = #char ".";
					}
					result[index] = #char "0";
					index += 1;

					break;
				}
				if c == #char "."
				{
					dot_index = round_index;

					continue;
				}
				else if c == #char "9"
				{
					result[round_index] = #char "0";
					round_up = 1;

					continue;
				}
				else
				{
					if round_up == 2 && (c % 2) == 0
						break;
					result[round_index] = c + 1;

					break;
				}
			}
		}
	}
	else
	{
		memset (result + index, #char "0", precision);
		index += cast (s32) precision;
	}
	
	return index;
}

f64_to_fixed :: (f : f64, precision : u32, allocator : Allocator) -> string #must
{
	result : string = ---;
	result.data = allocator.proc (.ALLOCATE, 2000, 0, null, allocator.data);
	result.count = f64_to_fixed_buffered (f, precision, result.data);
	
	return result;
}
