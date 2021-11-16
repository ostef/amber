#load "utils.jai";
#load "easing.jai";
#load "approx.jai";
#load "random.jai";

#scope_module

f32 :: float32;
f64 :: float64;

#scope_export

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

F32_MIN :: 0h0080_0000;
F32_MAX :: 0h7f7f_ffff;
F32_MIN_SUBNORMAL :: 0h0000_0001;
F32_MAX_SUBNORMAL :: 0h007f_ffff;
F32_POSITIVE_INFINITY :: 0h7f80_0000;
F32_NEGATIVE_INFINITY :: 0hff80_0000;
F32_NAN :: 0h7fc0_0000;
F32_EPSILON :: 0h3400_0000;

F64_MIN :: 0h0010_0000_0000_0000;
F64_MAX :: 0h7fef_ffff_ffff_ffff;
F64_MIN_SUBNORMAL :: 0h0000_0000_0000_0001;
F64_MAX_SUBNORMAL :: 0h000f_ffff_ffff_ffff;
F64_POSITIVE_INFINITY :: 0h7ff0_0000_0000_0000;
F64_NEGATIVE_INFINITY :: 0hfff0_0000_0000_0000;
F64_NAN :: 0h7ff8_0000_0000_0000;
F64_EPSILON :: 0h3cb0_0000_0000_0000;

MAX_REPRESENTABLE_INT_AS_F32 :: 16777217;

PI    :: 3.1415927;
PI64  :: 3.141592653589793;

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

#scope_module

#if OS == .WINDOWS crt :: #foreign_system_library "msvcrt";
else #if OS == .LINUX crt :: #foreign_system_library "libm";
