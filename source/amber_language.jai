#scope_file

languages : Slot_Array (Language);

#scope_export

get_language :: inline (language_id : Language_ID) -> *Language #must
{
	assert (language_exists (language_id), "Invalid language id (%).", language_id);
	assert (language_id != PLAIN_TEXT, "PLAIN_TEXT is not a registered language, but a predefined id. Don't call get_language with it!");
	
	return get_ptr (*languages, cast (s64) language_id - 1);
}

language_exists :: inline (id : Language_ID) -> bool #must
{
	return id == PLAIN_TEXT || id > 0 && id <= xx languages.max_occupied && languages.slots[cast (s64) id - 1].occupied;
}
@Amber_API

language_get_extension :: inline (language_id : Language_ID) -> Extension_ID #must
{
	language := get_language (language_id);
	
	return language.extension_id;
}
@Amber_API

language_get_name :: inline (language_id : Language_ID, allocator : Allocator, allocator_data := null) -> string #must
{
	if language_id == PLAIN_TEXT
		return clone_string ("Plain Text", allocator, allocator_data);
	language := get_language (language_id);
	
	return clone_string (language.name, allocator, allocator_data);
}
@Amber_API

language_get_associated_filenames :: inline (language_id : Language_ID, allocator : Allocator, allocator_data := null) -> []string #must
{
	if language_id == PLAIN_TEXT
		return string.[];
	language := get_language (language_id);
	result := clone_array (language.associated_filenames, allocator, allocator_data);
	for * result
	{
		<<it = clone_string (<<it, allocator, allocator_data);
	}
	
	return result;
}
@Amber_API

language_get_associated_file_extensions :: inline (language_id : Language_ID, allocator : Allocator, allocator_data := null) -> []string #must
{
	if language_id == PLAIN_TEXT
		return string.[];
	language := get_language (language_id);
	result := clone_array (language.associated_file_extensions, allocator, allocator_data);
	for * result
	{
		<<it = clone_string (<<it, allocator, allocator_data);
	}
	
	return result;
}
@Amber_API

language_detect :: inline (filename : string) -> Language_ID
{
	basename  := filename_get_basename (filename);
	extension := filename_get_extension (filename);
	for lang : languages
	{
		for lang.associated_filenames
			if basename == it then return lang.id;
		for lang.associated_file_extensions
			if extension == it then return lang.id;
	}
	
	return PLAIN_TEXT;
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
			return false, cast (Language_ID) (it_index + 1);
	}
	inserted, index := insert_into_slot_array (*languages, language);
	inserted.id = cast (Language_ID) (index + 1);
	// @Note (stefan): We don't make assumptions about where the memory for the
	// following members comes from, so we allocate new memory for them.
	inserted.name = clone_string (language.name, heap_allocator);
	inserted.associated_filenames  = clone_array (language.associated_filenames, heap_allocator);
	for * inserted.associated_filenames
	{
		<<it = clone_string (<<it, heap_allocator);
	}
	inserted.associated_file_extensions = clone_array (language.associated_file_extensions, heap_allocator);
	for * inserted.associated_file_extensions
	{
		<<it = clone_string (<<it, heap_allocator);
	}
	
	return true, inserted.id;
}
@Amber_API

language_unregister :: inline (language_id : Language_ID)
{
	assert (language_exists (language_id), "Invalid language id (%).", language_id);
	
	using language := get_language (language_id);
	free (name, heap_allocator);
	for associated_filenames
		free (it, heap_allocator);
	free (associated_filenames, heap_allocator);
	for associated_file_extensions
		free (it, heap_allocator);
	free (associated_file_extensions, heap_allocator);
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
