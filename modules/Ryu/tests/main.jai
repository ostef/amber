#load "../module.jai";

F32_MIN :: 0h0080_0000;
F32_MAX :: 0h7f7f_ffff;
F32_MIN_SUBNORMAL :: 0h0000_0001;
F32_MAX_SUBNORMAL :: 0h007f_ffff;
F32_EPSILON :: 0h3400_0000;
F32_POSITIVE_INFINITY :: 0h7f80_0000;
F32_NEGATIVE_INFINITY :: 0hff80_0000;
F32_NAN :: 0h7fc0_0000;
PI :: 3.1415927;

print :: (str : string)
{
	write_string (str);
}

println :: (str : string)
{
	print (str);
	print ("\n");
}

main :: ()
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
