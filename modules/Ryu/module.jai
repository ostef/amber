// Port of the Ryū: Fast Float-to-String Conversion algorithm
// https://dl.acm.org/doi/10.1145/3296979.3192369
// https://github.com/ulfjack/ryu

#module_parameters (NAN_STRING := "NaN", INF_STRING := "Inf", DEBUG := false);

#if DEBUG
{
	#import "Common";	// For print, println
}

#load "common.jai";
#load "digit_table.jai";
#load "f32_intrinsics.jai";
#load "f32_to_shortest_full_table.jai";
#load "f32_to_shortest.jai";
#load "f64_intrinsics.jai";
#load "f64_to_fixed_full_table.jai";
#load "f64_to_fixed.jai";

#scope_module

f32 :: float32;
f64 :: float64;
