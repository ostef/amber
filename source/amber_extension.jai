Extension :: struct
{
	Init_Proc      :: #type (*Amber_Hooks, Extension_ID) -> bool;
	Terminate_Proc :: #type (*Amber_Hooks);
	
	filename  : string;
	lib       : Library_Handle;
	init      : Init_Proc;
	terminate : Terminate_Proc;
	hooks     : Amber_Hooks;
	loaded      : bool;
	initialized : bool;
}

#scope_file

extensions : [..]Extension;

#scope_export

get_extension :: inline (id : Extension_ID) -> *Extension #must
{
	assert (id > 0 && id <= xx extensions.count, "Invalid extension id (%).", cast (s64) id);
	
	return *extensions[cast (s64) (id - 1)];
}

get_hooks :: inline (extension_id : Extension_ID) -> *Amber_Hooks #must
{
	return *get_extension (extension_id).hooks;
}

load_extension :: (name : string) -> bool, Extension_ID
{
	if !name then return false, 0;
	if !extensions.allocator.proc then extensions.allocator = HEAP;
	filename := join (HEAP, "extensions/", name, ".dll");
	extension : *Extension;
	extension_id : Extension_ID;
	
	for * extensions
	{
		if it.filename == filename
		{
			if it.loaded then return false, cast (Extension_ID) (it_index + 1);
			extension = it;
			extension_id = cast (Extension_ID) (it_index + 1);
			
			break;
		}
	}
	
	if !extension
	{
		extension = push_into_array (*extensions);
		extension_id = cast (Extension_ID) extensions.count;
	}
	extension.filename = filename;
	extension.lib = platform_load_library (filename);
	if !extension.lib
		return false, 0;
	extension.init = cast (Extension.Init_Proc) platform_get_proc_address (extension.lib, "init_extension");
	if !extension.init
		return false, 0;
	extension.terminate = cast (Extension.Terminate_Proc) platform_get_proc_address (extension.lib, "terminate_extension");
	if !extension.terminate
		return false, 0;
	extension.hooks.amber_config = *config;
	load_api (*extension.hooks);
	extension.loaded = true;
	
	return true, extension_id;
}

init_extensions :: inline ()
{
	for * extension : extensions
	{
		if !extension.loaded then continue;
		extension.initialized = extension.init (*extension.hooks, cast (Extension_ID) (it_index + 1));
	}
}

fill_extensions_config :: inline (root : *Config_Root)
{
	for * extension : extensions
	{
		if !extension.initialized then continue;
		if extension.hooks.extension_config.value_pointer
			config_fill_variables (extension.hooks.extension_config, root);
	}
}

terminate_and_free_extensions :: inline ()
{
	for * extension : extensions
	{
		id := cast (Extension_ID) (it_index + 1);
		if extension.loaded
			extension.terminate (*extension.hooks);
		language_unregister_for_extension (id);
		command_unregister_for_extension (id);
		platform_free_library (extension.lib);
		extension.lib = null;
		extension.init = null;
		extension.terminate = null;
		memset (*extension.hooks.callbacks, 0, size_of (Extension_Callbacks));
		extension.loaded = false;
	}
}

extensions_on_event :: inline (event : Event) -> Event_Result, bool
{
	result : Event_Result;
	for * extensions
	{
		if !it.loaded || !it.initialized then continue;
		if it.hooks.on_event
		{
			extension_result, propagate := it.hooks.on_event (*it.hooks, event);
			result ||= extension_result;
			if !propagate then return result, false;
		}
	}
	
	return result, true;
}

extensions_on_update :: inline ()
{
	for * extensions
	{
		if !it.loaded || !it.initialized then continue;
		if it.hooks.on_update
			it.hooks.on_update (*it.hooks);
	}
}
