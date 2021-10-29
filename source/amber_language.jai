#scope_file

languages : Slot_Array (Language);

#scope_export

get_language :: inline (language_id : Language_ID) -> *Language #must
{
	assert (language_exists (language_id), "Invalid language id (%).", language_id);
	
	return *languages[cast (s64) language_id - 1];
}

language_exists :: inline (id : Language_ID) -> bool #must
{
	return id > 0 && id <= xx languages.max_occupied && languages.slots[cast (s64) id - 1].occupied;
}
@Amber_API

language_register :: inline (language : Language) -> bool, Language_ID
{
	if !languages.allocator then languages.allocator = heap_allocator;
	if !language.name || !language.process_buffer
		return false, 0;
	for languages
	{
		if it.name == language.name
			return false, cast (Language_ID) it_index;
	}
	inserted, index := insert_into_slot_array (*languages, language);
	inserted.id = cast (Language_ID) (index + 1);
	inserted.name = clone_string (language.name, heap_allocator);
	inserted.associated_filenames  = clone_array (language.associated_filenames, heap_allocator);
	inserted.associated_extensions = clone_array (language.associated_extensions, heap_allocator);
	
	return true, cast (Language_ID) index;
}
@Amber_API

language_unregister :: inline (language_id : Language_ID)
{
	assert (language_exists (language_id), "Invalid language id (%).", language_id);
	
	using language := get_language (language_id);
	free (name, heap_allocator);
	free (associated_filenames, heap_allocator);
	free (associated_extensions, heap_allocator);
	remove_from_slot_array (*languages, cast (s64) language_id - 1);
}
@Amber_API

language_unregister_for_extension :: inline (extension_id : Extension_ID)
{
	for * languages
	{
		if it.extension_id == extension_id
			language_unregister (it.id);
	}
}
@Amber_API

language_process_buffer :: (buffer_id : Buffer_ID)
{
	buffer := get_buffer (buffer_id);
	text_layout_clear_colors (buffer.text_layout_id);
	if buffer.language_id == PLAIN_TEXT
	{
		text_layout_push_color (buffer.text_layout_id, rangei (0, buffer_get_count (buffer_id)), RGBA_WHITE);
	}
	else
	{
		language  := get_ptr (*languages, cast (s64) buffer.language_id - 1);
		extension := get_extension (language.extension_id);
		language.process_buffer (*extension.hooks, buffer_id);
	}
}
