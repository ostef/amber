#import "Common";
#import "Math";
#import "Random";
#import "Ryu";

BUFFER_SIZE :: 2000;

u64_bits_to_f64 :: inline (bits : u64) -> f64
{
	f : f64;
	memcpy (*f, *bits, size_of (f64));

	return f;
}

Mean_And_Variance :: struct
{
	n : s64;
	min : f64;
	max : f64;
	mean : f64;
	m2 : f64;
}

update :: (mv : *Mean_And_Variance, x : f64)
{
	if x < mv.min then mv.min = x;
	if x > mv.max then mv.max = x;
	mv.n += 1;
	d := x - mv.mean;
	mv.mean += d / mv.n;
	d2 := x - mv.mean;
	mv.m2 += d * d2;
}

variance :: (mv : *Mean_And_Variance) -> f64
{
	return mv.m2 / (mv.n - 1);
}

stddev :: (mv : *Mean_And_Variance) -> f64
{
	return sqrt (variance (mv));
}

generate_double :: (r : *u64) -> f64
{
	low := random ();
	hi := random ();
	<<r = ((cast (u64) hi) << 32 | low);
	f := u64_bits_to_f64 (<<r);

	return f;
}

#import "stb_sprintf";

bench64_fixed :: (samples : u32, iterations : u32, precision : u32, verbose : bool)
{
	bufferown : [BUFFER_SIZE]u8;
	buffer : [BUFFER_SIZE]u8;
	fmt : [100]u8;
	
	stbsp_snprintf (fmt.data, fmt.count, "%%.%df", precision);
	mv1 : Mean_And_Variance;
	mv1.min = F64_POSITIVE_INFINITY;
	mv1.max = F64_NEGATIVE_INFINITY;
	mv2 : Mean_And_Variance;
	mv2.min = F64_POSITIVE_INFINITY;
	mv2.max = F64_NEGATIVE_INFINITY;
	throwaway := 0;
	for i : 0..samples - 1
	{
		r : u64;
		f := generate_double (*r);
		t1 := get_time ();
		for j : 0..iterations - 1
		{
			f64_to_fixed_buffered (f, precision, bufferown.data);
			throwaway += bufferown[2];
		}
		t2 := get_time ();
		delta1 := ((t2 - t1) * 1000000000.0) / cast (f64) iterations;
		update (*mv1, delta1);

		t1 = get_time ();
		for j : 0..iterations - 1
		{
			stbsp_snprintf (buffer.data, buffer.count, fmt.data, f);
			throwaway += buffer[2];
		}
		t2 = get_time ();
		delta2 := ((t2 - t1) * 1000000000.0) / cast (f64) iterations;
		update (*mv2, delta2);
	}
	if !verbose
	{
		print ("64 (nanoseconds): %*8.3* %*8.3* %*8.3* %*8.3*", mv1.mean, stddev (*mv1), mv1.min, mv1.max);
		print ("      %*8.3* %*8.3* %*8.3* %*8.3*", mv2.mean, stddev (*mv2), mv2.min, mv2.max);
		print ("\n");
	}
}

main :: ()
{
	samples := 10000;
	iterations := 1000;
	precision := 6;
	verbose := false;
	println ("Ryu: Mean   Stddev    Min    Max        stb_sprintf: Mean   Stddev    Min    Max");
	bench64_fixed (xx samples, xx iterations, xx precision, verbose);
}
