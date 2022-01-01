Profiled_Block :: struct
{
	number_of_times_profiled : s64;
	min_time := F64_POSITIVE_INFINITY;
	max_time := F64_NEGATIVE_INFINITY;
	total_time : f64;
	
	current_start_time : f64;
}

#scope_file

profiled_blocks : Hash_Map (string, Profiled_Block);

#scope_export

init_profiler :: inline ()
{
	assert (context.stack_trace != null, "Cannot use the profiler when stack trace is disabled.");
	init_map (*profiled_blocks, 1000, context.allocator);
}

write_profiling_data_to_builder :: (builder : *String_Builder)
{
	for profiled_blocks
	{
		print_line_to_builder (builder, it_index);
		print_line_to_builder (
			builder,
			"\t* profiled % times, \n\t* min: % ms,\n\t* max: % ms,\n\t* avg: % ms.",
			it.number_of_times_profiled,
			it.min_time * 1000,
			it.max_time * 1000,
			it.total_time * 1000 / xx it.number_of_times_profiled
		);
	}
}

#scope_file

find_or_add_profiled_block :: (block_name : string) -> *Profiled_Block #must
{
	procedure_name := context.stack_trace.info.name;
	filepath       := context.stack_trace.info.location.fully_pathed_filename;
	line           := context.stack_trace.info.location.line_number;
	id : string;
	if block_name
		id = fstring (TEMP, "%:%:%:%", filepath, procedure_name, line, block_name);
	else
		id = fstring (TEMP, "%:%:%", filepath, procedure_name, line);
	
	ptr := get_pointer (*profiled_blocks, id);
	if !ptr
	{
		id = clone_string (id, context.allocator);
		ptr = insert_into_map (*profiled_blocks, id);
	}
	
	return ptr;
}

#scope_export

profile :: (block_name := "") #expand
{
#if ENABLE_PROFILING
{
	assert (profiled_blocks.allocator.proc != null, "Profiler is not initialized.");
	procedure_info := context.stack_trace.info;
	`__profiled_block := find_or_add_profiled_block (block_name);
	__profiled_block.number_of_times_profiled += 1;
	__profiled_block.current_start_time = `platform_get_time ();
	`defer
	{
		elapsed := `platform_get_time () - __profiled_block.current_start_time;
		__profiled_block.total_time += elapsed;
		__profiled_block.min_time = min (__profiled_block.min_time, elapsed);
		__profiled_block.max_time = max (__profiled_block.max_time, elapsed);
	}
}
}
