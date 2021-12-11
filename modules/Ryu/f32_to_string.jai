#scope_module

F32_MANTISSA_BITS : s32 : 23;
F32_EXPONENT_BITS : s32 : 8;
F32_BIAS          : s32 : 127;

#scope_export

// A floating decimal representing m * 10^e.
F32_Decimal :: struct
{
	mantissa : u32;
	// Decimal exponent's range is -45 to 38
	// inclusive, and can fit in a short if needed.
	exponent : s32;
}

f32_to_decimal :: inline (ieee_mantissa : u32, ieee_exponent : u32) -> F32_Decimal #must
{
	e2 : s32 = ---;
	m2 : u32 = ---;
	if ieee_exponent == 0
	{
		// We subtract 2 so that the bounds computation has 2 additional bits.
		e2 = 1 - F32_BIAS - F32_MANTISSA_BITS - 2;
		m2 = ieee_mantissa;
	}
	else
	{
		e2 = cast (s32) ieee_exponent - F32_BIAS - F32_MANTISSA_BITS - 2;
		m2 = (1 << F32_MANTISSA_BITS) | ieee_mantissa;
	}
	even := (m2 & 1) == 0;
	accept_bounds := even;
	
	// Step 2: Determine the interval of valid decimal representations.
	mv := cast (u32) (4 * m2);
	mp := cast (u32) (4 * m2 + 2);
	mm_shift := cast (u32) (ieee_mantissa != 0 || ieee_exponent <= 1);
	mm := cast (u32) (4 * m2 - 1 - mm_shift);

	// Step 3: Convert to a decimal power base using 64-bit arithmetic.
	vr : u32 = ---;
	vp : u32 = ---;
	vm : u32 = ---;
	e10 : s32 = ---;
	vm_is_trailing_zeroes := false;
	vr_is_trailing_zeroes := false;
	last_removed_digit : u8 = 0;
	if e2 >= 0
	{
		q := log10pow2 (e2);
		e10 = cast (s32) q;
		k := cast (s32) F32_POW5_INV_BITCOUNT + pow5bits (cast (s32) q) - 1;
		i := -e2 + cast (s32) q + k;
		vr = mul_pow5_inv_div_pow2 (mv, q, i);
		vp = mul_pow5_inv_div_pow2 (mp, q, i);
		vm = mul_pow5_inv_div_pow2 (mm, q, i);
		if q != 0 && (vp - 1) / 10 <= vm / 10
		{
			// We need to know one removed digit even if we are not going to loop below. We could use
			// q = X - 1 above, except that would require 33 bits for the result, and we've found that
			// 32-bit arithmetic is faster even on 64-bit machines.
			l := F32_POW5_INV_BITCOUNT + pow5bits (cast (s32) (q - 1)) - 1;
			last_removed_digit = cast (u8) (mul_pow5_inv_div_pow2 (mv, q - 1, -e2 + cast (s32) q - 1 + l) % 10);
		}
		if q <= 9
		{
			// The largest power of 5 that fits in 24 bits is 5^10, but q <= 9 seems to be safe as well.
			// Only one of mp, mv, and mm can be a multiple of 5, if any.
			if mv % 5 == 0
				vr_is_trailing_zeroes = multiple_of_power_of_5 (mv, q);
			else if accept_bounds
				vm_is_trailing_zeroes = multiple_of_power_of_5 (mm, q);
			else
				vp -= cast (u32) multiple_of_power_of_5 (mp, q);
		}
	}
	else
	{
		q := log10pow5 (-e2);
		e10 = cast (s32) q + e2;
		i := -e2 - cast (s32) q;
		k := pow5bits (i) - F32_POW5_BITCOUNT;
		j := cast (s32) q - k;
		vr = mul_pow5_div_pow2 (mv, cast (u32) i, j);
		vp = mul_pow5_div_pow2 (mp, cast (u32) i, j);
		vm = mul_pow5_div_pow2 (mm, cast (u32) i, j);
		if q != 0 && (vp - 1) / 10 <= vm / 10
		{
			j = cast (s32) q - 1 - (pow5bits (i + 1) - F32_POW5_BITCOUNT);
			last_removed_digit = cast (u8) (mul_pow5_div_pow2 (mv, cast (u32) (i + 1), 1) % 10);
		}
		if q <= 1
		{
			// {vr,vp,vm} is trailing zeros if {mv,mp,mm} has at least q trailing 0 bits.
			// mv = 4 * m2, so it always has at least two trailing 0 bits.
			vr_is_trailing_zeroes = true;
			if accept_bounds
			{
				// mm = mv - 1 - mmShift, so it has 1 trailing 0 bit iff mmShift == 1.
				vm_is_trailing_zeroes = mm_shift == 1;
			}
			else
			{
				// mp = mv + 2, so it always has at least one trailing 0 bit.
				vp -= 1;
			}
		}
		else if q < 31
		{
			vr_is_trailing_zeroes = multiple_of_power_of_2 (mv, q - 1);
		}
	}

	// Step 4: Find the shortest decimal representation in the interval of valid representations.
	removed : s32 = 0;
	output : u32 = ---;
	if vm_is_trailing_zeroes || vr_is_trailing_zeroes
	{
		// General case, which happens rarely (~4.0%).
		while vp / 10 > vm / 10
		{
			vm_is_trailing_zeroes &= vm % 10 == 0;
			vr_is_trailing_zeroes &= last_removed_digit == 0;
			last_removed_digit = cast (u8) (vr % 10);
			vr /= 10;
			vp /= 10;
			vm /= 10;
			removed += 1;
		}

		if vm_is_trailing_zeroes
		{
			while vm % 10 == 0
			{
				vr_is_trailing_zeroes &= last_removed_digit == 0;
				last_removed_digit = cast (u8) (vr % 10);
				vr /= 10;
				vp /= 10;
				vm /= 10;
				removed += 1;
			}
		}

		if vr_is_trailing_zeroes && last_removed_digit == 5 && vr % 2 == 0
		{
			// Round even if the exact number is .....50..0.
			last_removed_digit = 4;
		}
		// We need to take vr + 1 if vr is outside bounds or we need to round up.
		output = vr + cast (u32) ((vr == vm && (!accept_bounds || !vm_is_trailing_zeroes)) || last_removed_digit >= 5);
	}
	else
	{
		// Specialized for the common case (~96.0%). Percentages below are relative to this.
		// Loop iterations below (approximately):
		// 0: 13.6%, 1: 70.7%, 2: 14.1%, 3: 1.39%, 4: 0.14%, 5+: 0.01%
		while vp / 10 > vm / 10
		{
			last_removed_digit = cast (u8) (vr % 10);
			vr /= 10;
			vp /= 10;
			vm /= 10;
			removed += 1;
		}
		output = vr + cast (u32) (vr == vm || last_removed_digit >= 5);
	}
	
	result : F32_Decimal = ---;
	result.exponent = e10 + removed;
	result.mantissa = output;

	return result;
}

#scope_file

to_chars_unoptimized :: (v : F32_Decimal, sign : bool, result : *u8) -> s32
{
	index : s32 = 0;
	if sign
	{
		result[index] = #char "-";
		index += 1;
	}
	output := v.mantissa;
	length := cast (s32) decimal_length9 (output);

	i : s32 = 0;
	while output >= 10
	{
		result[index + length - i] = cast (u8) (#char "0" + (output % 10));
		output /= 10;
		i += 1;
	}
	result[index] = cast (u8) (#char "0" + (output % 10));

	// Print the decimal point if needed
	if length > 1
	{
		result[index + 1] = #char ".";
		index += length + 1;
	}
	else
	{
		index += 1;
	}

	// Print the exponent
	result[index] = #char "e";
	index += 1;
	exp := v.exponent + cast (s32) length - 1;
	if exp < 0
	{
		result[index] = #char "-";
		index += 1;
		exp = -exp;
	}
	if exp >= 10
	{
		result[index] = cast (u8) (#char "0" + (exp / 10));
		index += 1;
		result[index] = cast (u8) (#char "0" + (exp % 10));
		index += 1;
	}
	else
	{
		result[index] = cast (u8) (#char "0" + exp);
		index += 1;
	}

	return index;
}

to_chars :: (v : F32_Decimal, sign : bool, result : *u8) -> s32
{
	// Write v into result, reversed.
	index : s32 = 0;
	if sign
	{
		result[index] = #char "-";
		index += 1;
	}
	output := v.mantissa;
	length := cast (s32) decimal_length9 (output);

	// Print the decimal digits.
	// The following code is equivalent to:
	// for (uint32_t i = 0; i < length - 1; ++i) {
	//   const uint32_t c = output % 10;
	//   output /= 10;
	//   result[index + length - i] = (char) ('0' + c);
	// }
	// result[index] = '0' + output % 10;
	i : s32 = 0;
	while output >= 10000
	{
		c := output % 10000;
		output /= 10000;
		c0 := (c % 100) << 1;
		c1 := (c / 100) << 1;
		memcpy (result + index + length - i - 1, DIGIT_TABLE.data + c0, 2);
		memcpy (result + index + length - i - 3, DIGIT_TABLE.data + c1, 2);
		i += 4;
	}
	if output >= 100
	{
		c := (output % 100) << 1;
		output /= 100;
		memcpy (result + index + length - i - 1, DIGIT_TABLE.data + c, 2);
		i += 2;
	}
	if output >= 10
	{
		c := output << 1;
		// We can't use memcpy here: the decimal dot goes between these two digits.
		result[index + length - i] = DIGIT_TABLE[c + 1];
		result[index] = DIGIT_TABLE[c];
	}
	else
	{
		result[index] = cast (u8) (#char "0" + output);
	}

	// Print the decimal point if needed
	if length > 1
	{
		result[index + 1] = #char ".";
		index += length + 1;
	}
	else
	{
		index += 1;
	}

	// Print the exponent
	result[index] = #char "e";
	index += 1;
	exp := v.exponent + cast (s32) length - 1;
	if exp < 0
	{
		result[index] = #char "-";
		index += 1;
		exp = -exp;
	}

	if exp >= 10
	{
		memcpy (result + index, DIGIT_TABLE.data + 2 * exp, 2);
		index += 2;
	}
	else
	{
		result[index] = cast (u8) (#char "0" + exp);
		index += 1;
	}

	return index;
}

#scope_export

f32_to_string_buffered :: (f : f32, result : *u8) -> s32
{
	// Step 1: Decode the floating-point number, and unify normalized and subnormal cases.
	// Decode bits into sign, mantissa, and exponent.
	bits := f32_to_bits (f);
	ieee_sign := cast (bool) ((bits >> (F32_MANTISSA_BITS + F32_EXPONENT_BITS)) & 1);
	ieee_mantissa := bits & ((1 << F32_MANTISSA_BITS) - 1);
	ieee_exponent := (bits >> F32_MANTISSA_BITS) & ((1 << F32_EXPONENT_BITS) - 1);
	// Case distinction; exit early for the easy cases.
	if ieee_exponent == ((1 << F32_EXPONENT_BITS) - 1) || (ieee_exponent == 0 && ieee_mantissa == 0)
		return copy_special_str (result, ieee_sign, ieee_exponent != 0, ieee_mantissa != 0);
	v := f32_to_decimal (ieee_mantissa, ieee_exponent);

	return to_chars_unoptimized (v, ieee_sign, result);
}

f32_to_string :: (f : f32, allocator : Allocator) -> string #must
{
	result : string = ---;
	result.data = allocator.proc (.ALLOCATE, 16, 0, null, allocator.data);
	result.count = f32_to_string_buffered (f, result.data);
	
	return result;
}
