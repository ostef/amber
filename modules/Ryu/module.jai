// Port of the Ryū: Fast Float-to-String Conversion algorithm
// https://dl.acm.org/doi/10.1145/3296979.3192369
// https://github.com/ulfjack/ryu

#load "common.jai";
#load "digit_table.jai";
#load "f32_full_table.jai";
#load "f32_intrinsics.jai";
#load "f32_to_string.jai";

#scope_module

f32 :: float32;
f64 :: float64;

#scope_export

Ryu_Format :: struct
{
	exponent_form := false;
	max_digits_before_decimal : s32 = -1;	// If negative, assumed to be 6 (?). Does not count the sign.
	min_digits_after_decimal : s32 = -1;
	max_digits_after_decimal : s32 = -1;		// If negative, assumed to be 6 (?)
	force_sign := false;	// Print a '+' when positive
	align_sign := false;	// Print a ' ' when positive
	force_sign_on_exponent := false;	// Print a '+' when positive on exponent
	decimal_separator  : u8 = #char ".";
	exponent_separator : u8 = #char "e";
	nan_string := "NaN";
	inf_string := "Inf";
}
