#import "Ryu" (DEBUG = false);
#import "Common";
#import "Math";

test_f32_to_string :: ()
{
	println (f32_to_string (F32_NAN, context.allocator));
	println (f32_to_string (F32_POSITIVE_INFINITY, context.allocator));
	println (f32_to_string (F32_NEGATIVE_INFINITY, context.allocator));
	println (f32_to_string (0.0, context.allocator));
	println (f32_to_string (-0.0, context.allocator));
	println (f32_to_string (F32_MIN_SUBNORMAL, context.allocator));
	println (f32_to_string (F32_MAX_SUBNORMAL, context.allocator));
	println (f32_to_string (F32_MIN, context.allocator));
	println (f32_to_string (F32_EPSILON, context.allocator));
	println (f32_to_string (F32_MAX, context.allocator));
	println (f32_to_string (1.0, context.allocator));
	println (f32_to_string (-1.0, context.allocator));
	println (f32_to_string (123.456, context.allocator));
	println (f32_to_string (-123.456, context.allocator));
	println (f32_to_string (PI, context.allocator));
	println (f32_to_string (12345678, context.allocator));
	println (f32_to_string (12, context.allocator));
	println (f32_to_string (0.123456, context.allocator));
	println (f32_to_string (0.001234, context.allocator));
}

test_f64_to_fixed :: ()
{
	println ("% : %", f64_to_fixed (F32_NAN, 17, context.allocator), F32_NAN);
	println ("% : %", f64_to_fixed (F32_POSITIVE_INFINITY, 17, context.allocator), F32_POSITIVE_INFINITY);
	println ("% : %", f64_to_fixed (F32_NEGATIVE_INFINITY, 17, context.allocator), F32_NEGATIVE_INFINITY);
	println ("% : %", f64_to_fixed (0.0, 17, context.allocator), 0.0);
	println ("% : %", f64_to_fixed (-0.0, 17, context.allocator), -0.0);
	println ("% : %", f64_to_fixed (F32_MIN_SUBNORMAL, 50, context.allocator), F32_MIN_SUBNORMAL);
	println ("% : %", f64_to_fixed (F32_MAX_SUBNORMAL, 50, context.allocator), F32_MAX_SUBNORMAL);
	println ("% : %", f64_to_fixed (F32_MIN, 40, context.allocator), F32_MIN);
	println ("% : %", f64_to_fixed (F32_EPSILON, 17, context.allocator), F32_EPSILON);
	println ("% : %", f64_to_fixed (F32_MAX, 17, context.allocator), F32_MAX);
	println ("% : %", f64_to_fixed (1.0, 17, context.allocator), 1.0);
	println ("% : %", f64_to_fixed (-1.0, 17, context.allocator), -1.0);
	println ("% : %", f64_to_fixed (123.456, 17, context.allocator), 123.456);
	println ("% : %", f64_to_fixed (-123.456, 17, context.allocator), -123.456);
	println ("% : %", f64_to_fixed (PI, 17, context.allocator), PI);
	println ("% : %", f64_to_fixed (PI64, 17, context.allocator), PI64);
	println ("% : %", f64_to_fixed (12345678, 17, context.allocator), 12345678);
	println ("% : %", f64_to_fixed (12, 17, context.allocator), 12);
	println ("% : %", f64_to_fixed (0.123456, 17, context.allocator), 0.123456);
	println ("% : %", f64_to_fixed (0.001234, 17, context.allocator), 0.001234);
}

main :: ()
{
	//test_f32_to_string ();
	test_f64_to_fixed ();
}
