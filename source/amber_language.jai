#scope_file

languages : Slot_Array (Language);

#scope_export

language_register :: (language : Language) -> bool, Language_ID
{
	if !languages.allocator then languages.allocator = heap_allocator;
	if !language.name || !language.process_buffer
		return false, 0;
	for languages
	{
		if it.name == language.name
			return false, cast (Language_ID) it_index;
	}
	_, index := insert_into_slot_array (*languages, language);
	
	return true, cast (Language_ID) index;
}
@Amber_API

language_process_buffer :: (buffer_id : Buffer_ID)
{
	buffer := get_buffer (buffer_id);
	if buffer.language_id == PLAIN_TEXT
		return;
	
	language  := get_ptr (*languages, cast (s64) buffer.language_id - 1);
	extension := get_extension (language.extension_id);
	language.process_buffer (*extension.hooks, buffer_id);
}
