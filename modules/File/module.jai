#scope_module

#import "Common";

#scope_export

#if OS == .WINDOWS    #load "win32.jai";
else #if OS == .LINUX #load "linux.jai";

/*
file_exists :: (filename : string) -> bool;
create_file :: (filename : string, flags : File_Flags, create_tree := true) -> File #must, bool;
open_file :: (filename : string, flags : File_Flags) -> File #must, bool;
delete_file :: (filename : string) -> bool;
set_file_attributes :: (filename : string, attr : File_Attributes);
move_file :: (filename : string, new_name : string) -> bool;
close_file :: (file : File);
get_file_size :: (file : File) -> s64 #must;
set_file_cursor :: (file : File, offset : s64, cursor : File_Cursor) -> moved : s64, success : bool;
set_end_of_file_to_cursor :: (file : File) -> bool;
read_file :: (file : File, buffer : *void, buffer_size : s64) -> read : s64, success : bool;
write_file :: (file : File, buffer : *void, count : s64) -> written : s64, success : bool;
copy_file :: (source : string, dest : string, override_if_exists := false) -> bool;

set_working_directory :: (path : string) -> bool;
create_directory :: (dirname : string) -> bool;
delete_empty_directory :: (dirname : string) -> bool;
inspect_directory :: (dirname : string, recurse : bool, user_data : $T, proc : (info : *File_Visit_Info, user_data : T), visit_files := true, visit_directories := false) -> bool;
*/

File_Flags :: enum_flags
{
	NONE    :: 0x00;
	READ    :: 0x01;
	WRITE   :: 0x02;
	EXECUTE :: 0x04;

	READ_WRITE :: READ | WRITE;
}

File_Attributes :: enum_flags
{
	NONE      :: 0x00;
	ARCHIVE   :: 0x01;
	HIDDEN    :: 0x02;
	NOT_CONTENT_INDEXED :: 0x04;
	OFFLINE   :: 0x08;
	READ_ONLY :: 0x10;
	SYSTEM    :: 0x20;
	TEMPORARY :: 0x40;
}

File_Cursor :: enum
{
	BEGIN;
	END;
	CURRENT;
}

File_Visit_Info :: struct
{
	name         : string;
	full_name    : string;
	//filetime     : u64;
	is_directory : bool;
	is_symlink   : bool;
	had_error    : bool;

	descend_into_directory : bool;
}

make_path :: (allocator : Allocator, allocator_data : *void, parts : ..string) -> string #must
{
	ensure_path :: (str : *string)
	{
		for i : 0..str.count - 1
		{
			if str.data[i] == #char "\\" then str.data[i] = #char "/";
		}

		first := 0;
		while first < str.count - 1
		{
			move_left := false;
			for i : first..str.count - 2
			{
				if move_left
				{
					str.data[i] = str.data[i + 1];
				}
				else
				{
					if str.data[i] == #char "/" && str.data[i + 1] == #char "/"
					{
						move_left = true;
					}

					first = i + 1;
				}
			}

			if move_left then str.count -= 1;
		}
	}

	result := join (allocator, allocator_data, ..parts);
	ensure_path (*result);

	return result;
}

make_path :: (allocator : Allocator, parts : ..string) -> string #must
{
	return inline make_path (allocator, null, ..parts);
}

paths_match :: (a : string, b : string) -> bool #must
{
	ai := 0;
	bi := 0;
	while ai < a.count && bi < b.count
	{
		// Skip multiple '/' in a row
		if a[ai] == #char "/"
		{
			while ai < a.count && a[ai + 1] == #char "/"  ai += 1;
		}
		
		if b[bi] == #char "/"
		{
			while bi < b.count && b[bi + 1] == #char "/"  bi += 1;
		}

		if a[ai] != b[bi] then return false;

		ai += 1;
		bi += 1;
	}

	if ai != a.count || bi != b.count then return false;

	return true;
}

strip_filename_from_path :: (filename : string) -> path_without_filename : string #must
{
	if filename.count == 0 then return "";
	result := filename;
	if result[result.count - 1] == #char "\\" || result[result.count - 1] == #char "/" then result.count -= 1;
	i := find_last_occurence (result, "\\/");
	if i == -1 then return "";
	result.count = i + 1;

	return result;
}

strip_extension_from_path :: (path : string) -> string #must
{
	result := path;
	i := find_last_occurence (result, ".");
	if i == -1 then return result;
	result.count = i;

	return result;
}

get_filename_from_path :: (path : string) -> string #must
{
	result := path;
	i := find_last_occurence (result, "\\/");
	if i == -1 then return path;
	result.data  += i + 1;
	result.count -= i + 1;

	return result;
}

get_filename_extension :: (filename : string) -> extension : string #must
{
	result := filename;
	i := find_last_occurence (result, ".");
	if i == -1 then return "";
	result.data  += i + 1;
	result.count -= i + 1;

	return result;
}

clear_file :: (file : File)
{
	set_file_cursor (file, 0, .BEGIN);
	set_end_of_file_to_cursor (file);
}

read_lines_from_file :: (filename : string, count : int, allocator : Allocator, allocator_data := null) -> []string #must, bool
{
	result := make_array (string, 10, allocator, allocator_data);
	file, opened := open_file (filename, File_Flags.READ);
	if !opened then return result, false;
	defer close_file (file);
	file_size := get_file_size (file);

	builder := make_string_builder (100, temp_allocator);
	char : u8;
	char_count := 0;
	line_count := 0;

	while line_count < count && char_count < file_size
	{
		read, ok := read_file (file, *char, 1);
		if !ok then return result, false;
		char_count += read;

		if char == #char "\n"
		{
			push_to_array (*result, builder_clone_to_string (builder, allocator, allocator_data));
			clear_string_builder (*builder);
			line_count += 1;
		}
		else if char != #char "\r"
		{
			print_char_to_builder (*builder, char);
		}
	}

	return result, true;
}

read_entire_file :: (filename : string, allocator : Allocator, allocator_data := null, null_terminate := true) -> file_contents : string #must, success : bool
{
	file, opened := open_file (filename, File_Flags.READ);
	if !opened then return "", false;
	file_size := get_file_size (file);
	buffer := alloc_string (file_size + xx null_terminate, allocator, allocator_data);
	read, ok := read_file (file, buffer.data, file_size);
	if !ok
	{
		free (buffer.data, allocator, allocator_data);

		return "", false;
	}
	if null_terminate then buffer[file_size] = 0;
	buffer.count = file_size;
	close_file (file);

	return buffer, true;
}

write_to_file :: (filename : string, buffer : string, append := false, create := true) -> written : s64, success : bool
{
	file   : File;
	opened : bool;
	// @Fix @Linux (stefan): If create is true then we overwrite the file if it exists, and append has no effect
	if create then file, opened = create_file (filename, File_Flags.WRITE);
	else           file, opened = open_file (filename, File_Flags.WRITE);
	if !opened then return 0, false;
	if !append then clear_file (file);
	written, success := write_file (file, buffer.data, buffer.count);
	close_file (file);
	
	return written, success;
}

create_directory_tree :: (tree : string) -> bool
{
	path := tree;
	while path.count != 0 && path[path.count - 1] == #char "/"
		path.count -= 1;
	if path == "" then return false;
	
	parent := strip_filename_from_path (path);
	create_directory_tree (parent);

	return create_directory (path);
}

purge_directory :: (dirname : string) -> bool
{
	visitor :: (info : *File_Visit_Info, data : *void)
	{
		if info.is_directory
		{
			delete_directory (info.full_name);
		}
		else
		{
			delete_file (info.full_name);
		}
	}

	return inspect_directory (dirname, recurse = false, null, visitor);
}

delete_directory :: (dirname : string) -> bool
{
	inline purge_directory (dirname);

	return delete_empty_directory (dirname);
}

copy_files :: (source : string, dest : string, recurse := true) -> bool
{
	paths : [2]string;
	paths[0] = source;
	paths[1] = dest;

	visitor :: (info : *File_Visit_Info, paths : [2]string)
	{
		relative_path := advance (info.full_name, paths[0].count);
		dest_path := join (temp_allocator, paths[1], "/", relative_path);
		create_directory_tree (strip_filename_from_path (dest_path));
		copy_file (info.full_name, dest_path);
	}

	return inspect_directory (paths[0], recurse, paths, visitor);
}

find_files_with_extension :: (dirname : string, extension : string, allocator : Allocator, allocator_data := null, recurse := true) -> []string
{
	Visitor_Data :: struct
	{
		filenames : *[..]string;
		extension : string;
	}
	
	result := make_array (string, 10, allocator, allocator_data);

	visitor :: (info : *File_Visit_Info, data : Visitor_Data)
	{
		file_extension := get_filename_extension (info.full_name);
		if file_extension == data.extension then push_to_array (data.filenames, clone_string (info.full_name, data.filenames.allocator, data.filenames.allocator_data));
	}

	data : Visitor_Data;
	data.filenames = *result;
	data.extension = extension;
	inspect_directory (dirname, recurse, data, visitor);

	return result;
}

purge_and_copy_files :: (source : string, dest : string) -> bool
{
	// Purge
	if !delete_directory (dest) then return false;
	// Copy 
	if !create_directory_tree (dest) then return false;
	
	return copy_files (source, dest);
}
