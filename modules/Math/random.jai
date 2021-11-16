// https://en.wikipedia.org/wiki/Pseudorandom_number_generator
// https://en.wikipedia.org/wiki/Lehmer_random_number_generator

#scope_file

M :: 0x7fff_ffff;	// The modulus is the mersene prime M31: 2^31 - 1 = 2,147,483,647
A :: 16_807;

RAND_RANGE :: cast (u32) 0x1000_0000;
MASK       :: RAND_RANGE - 1;
#assert (RAND_RANGE & MASK) == 0;

_state := cast (s32) 0x0173_965;

#scope_export

random_seed :: (seed : s32)
{
	_state = seed & M;
	if _state == 0 || _state == 1 then _state += 2;
}

random :: () -> u32
{
	x := _state;
	hi := x / 127773;
	lo := x % 127773;
	_state = A * lo - 2836 * hi;
	if _state <= 0 then _state += M;

	return cast (u32) _state;
}

random_range :: (low : f32, high : f32) -> f32
{
	rand := random () & MASK;
	t := (rand / cast (f32) RAND_RANGE) * (high - low);

	return low + t;
}

random_rangei :: (low : int, high : int) -> int
{
	return cast (int) random_range (xx low, xx high);
}

random_chance :: (chance : f32) -> bool
{
	rand := random_range (0, 1);
	
	return rand <= chance;
}

shuffle :: (array : []$T, iterations := -1)
{
	if iterations == -1 then iterations = array.count;

	for i : 0..iterations - 1
	{
		first := random_rangei (0, array.count - 1);
		second := random_rangei (0, array.count - 1);
		temp := array[first];
		array[first] = array[second];
		array[second] = temp;
	}
} 
