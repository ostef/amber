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

language_get_name :: inline (language_id : Language_ID, allocator : Allocator) -> string #must
{
	if language_id == PLAIN_TEXT
		return clone_string ("Plain Text", allocator);
	language := get_language (language_id);
	
	return clone_string (language.name, allocator);
}
@Amber_API

language_get_associated_filenames :: inline (language_id : Language_ID, allocator : Allocator) -> []string #must
{
	if language_id == PLAIN_TEXT
		return string.[];
	language := get_language (language_id);
	filenames := language.default_associated_filenames;
	for config.language_associations
	{
		if it.language == language.name
		{
			if it.filenames.count != 0
			{
				filenames = it.filenames;

				break;
			}
		}
	}
	result := clone_array (filenames, allocator);
	for * result
	{
		<<it = clone_string (<<it, allocator);
	}
	
	return result;
}
@Amber_API

language_get_associated_file_extensions :: inline (language_id : Language_ID, allocator : Allocator) -> []string #must
{
	if language_id == PLAIN_TEXT
		return string.[];
	language := get_language (language_id);
	file_extensions := language.default_associated_file_extensions;
	for config.language_associations
	{
		if it.language == language.name
		{
			if it.extensions.count != 0
			{
				file_extensions = it.extensions;

				break;
			}
		}
	}
	result := clone_array (file_extensions, allocator);
	for * result
	{
		<<it = clone_string (<<it, allocator);
	}
	
	return result;
}
@Amber_API

language_match_filename :: inline (language_id : Language_ID, filename : string) -> bool
{
	language := get_language (language_id);
	filenames := language.default_associated_filenames;
	for config.language_associations
	{
		if it.language == language.name
		{
			if it.filenames.count != 0
			{
				filenames = it.filenames;

				break;
			}
		}
	}
	for filenames
		if it == filename
			return true;

	return false;
}
@Amber_API

language_match_extension :: inline (language_id : Language_ID, extension : string) -> bool
{
	language := get_language (language_id);
	file_extensions := language.default_associated_file_extensions;
	for config.language_associations
	{
		if it.language == language.name
		{
			if it.extensions.count != 0
			{
				file_extensions = it.extensions;

				break;
			}
		}
	}
	for file_extensions
		if it == extension
			return true;

	return false;
}
@Amber_API

language_detect :: inline (filename : string) -> Language_ID
{
	basename  := filename_get_basename (filename);
	extension := filename_get_extension (filename);
	for lang : languages
	{
		if language_match_extension (lang.id, extension)
			return lang.id;
		if language_match_filename (lang.id, basename)
			return lang.id;
	}
	
	return PLAIN_TEXT;
}
@Amber_API

language_register :: inline (language : Language) -> bool, Language_ID
{
	if !languages.allocator.proc then languages.allocator = HEAP;
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
	inserted.name = clone_string (language.name, HEAP);
	inserted.default_associated_filenames  = clone_array (language.default_associated_filenames, HEAP);
	for * inserted.default_associated_filenames
	{
		<<it = clone_string (<<it, HEAP);
	}
	inserted.default_associated_file_extensions = clone_array (language.default_associated_file_extensions, HEAP);
	for * inserted.default_associated_file_extensions
	{
		<<it = clone_string (<<it, HEAP);
	}
	
	return true, inserted.id;
}
@Amber_API

language_unregister :: inline (language_id : Language_ID)
{
	assert (language_exists (language_id), "Invalid language id (%).", language_id);
	
	using language := get_language (language_id);
	free (name, HEAP);
	for default_associated_filenames
		free (it, HEAP);
	free (default_associated_filenames, HEAP);
	for default_associated_file_extensions
		free (it, HEAP);
	free (default_associated_file_extensions, HEAP);
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
