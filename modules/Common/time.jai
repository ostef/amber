#if OS == .WINDOWS
{
	get_time :: () -> f64 #must
	{
		#import "Atomics";
		
		if os_base_performance_counter == 0
		{
			counter : s64;
			ok := QueryPerformanceCounter (*counter);
			assert (ok != 0, "QueryPerformanceCounter failed.");
			compare_and_swap (*os_base_performance_counter, 0, counter);
		}

		ticks : s64;
		ok := QueryPerformanceCounter (*ticks);
		assert (ok != 0, "QueryPerformanceCounter failed.");
		ticks -= os_base_performance_counter;

		frequency : s64;
		ok = QueryPerformanceFrequency (*frequency);
		assert (ok != 0, "QueryPerformanceFrequency failed.");

		div := ticks / frequency;
		mod := ticks % frequency;

		return cast (f64) div + mod / cast (f64) frequency;
	}

	os_base_performance_counter : s64;
}
else #if OS == .LINUX
{
	get_time :: () -> f64 #must
	{
		#import "Atomics";
	
		if os_base_performance_counter.tv_nsec == 0 && os_base_performance_counter.tv_sec == 0
		{
			counter : timespec;
			ok := clock_gettime (CLOCK_MONOTONIC_RAW, *counter);
			assert (ok == 0);

			#assert (size_of (type_of (counter)) == 16);
			compare_and_swap (*os_base_performance_counter, cast (s64) 0, cast (s64) 0, counter.tv_sec, counter.tv_nsec);
		}

		counter : timespec;
		ok := clock_gettime (CLOCK_MONOTONIC_RAW, *counter);
		assert (ok == 0);

		seconds := cast (f64) (counter.tv_sec - os_base_performance_counter.tv_sec);
		NANO_TO_SECS : f64 : 0.000000001;
		fraction := cast (f64) (counter.tv_nsec - os_base_performance_counter.tv_nsec) * NANO_TO_SECS;

		return seconds + fraction;
	}

	os_base_performance_counter : timespec #align 16;
}

#scope_file

