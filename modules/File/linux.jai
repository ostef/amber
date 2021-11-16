#assert OS == .LINUX "This file should only be loaded on Linux";

#scope_file

#import "POSIX";

#scope_export

File :: *FILE;

get_executable_path :: (allocator : Allocator, allocator_data := null) -> string #must
{
	buffer : [4096]u8;
	count := readlink ("/proc/self/exe", buffer.data, buffer.count);
	if count == 0 then return "";

	return clone_string (to_string (buffer.data), allocator, allocator_data);
}

get_full_path :: (path : string, allocator : Allocator, allocator_data := null) -> string #must
{
	buffer : [4096]u8;
	realpath (clone_to_cstring (path, temp_allocator), buffer.data);

	return clone_string (to_string (buffer.data), allocator, allocator_data);
}

path_leads_to_directory :: (path : string) -> bool #must
{
	result : stat_t;
	stat (clone_to_cstring (path, temp_allocator), *result);

	return S_ISDIR (result.st_mode);
}

path_leads_to_file :: (path : string) -> bool #must
{
	result : stat_t;
	stat (clone_to_cstring (path, temp_allocator), *result);

	return S_ISREG (result.st_mode);
}

file_exists :: (filename : string) -> bool #must
{
	return access (clone_to_cstring (filename, temp_allocator), 0) == 0;
}

create_file :: (filename : string, flags : File_Flags, create_tree := true) -> File #must, bool
{
	cfilename := clone_to_cstring (filename, temp_allocator);
	result : File;
	if flags == .WRITE
		result = fopen (cfilename, "wb");
	else
		result = fopen (cfilename, "wb+");

	return result, result != null;
}

open_file :: (filename : string, flags : File_Flags) -> File #must, bool
{
	cfilename := clone_to_cstring (filename, temp_allocator);
	result : File;
	if flags == .READ_WRITE
		result = fopen (cfilename, "rb+");
	else if flags == .READ
		result = fopen (cfilename, "rb");
	else if flags == .WRITE
		result = fopen (cfilename, "rb+");

	return result, result != null;
}

delete_file :: (filename : string) -> bool
{
	cfilename := clone_to_cstring (filename, temp_allocator);

	return _remove (cfilename) == 0;
}

set_file_attributes :: (filename : string, attr : File_Attributes)
{
}

move_file :: (filename : string, new_name : string) -> bool
{
	cfilename := clone_to_cstring (filename, temp_allocator);
	cnew_name := clone_to_cstring (new_name, temp_allocator);

	return rename (cfilename, cnew_name) == 0;
}

close_file :: (file : File)
{
	if file then fclose (file);
}

get_file_size :: (file : File) -> s64 #must
{
	position := ftell (file);
	if position == -1 then return 0;
	fseek (file, 0, SEEK_END);
	length := ftell (file);
	if length == -1 then return 0;
	fseek (file, position, SEEK_SET);

	return length;
}

set_file_cursor :: (file : File, offset : s64, cursor := File_Cursor.BEGIN) -> moved : s64, success : bool
{
	start := ftell (file);
	origin : u32;
	if cursor ==
	{
	case .BEGIN;   origin = SEEK_SET;
	case .END;     origin = SEEK_END;
	case .CURRENT; origin = SEEK_CUR;
	}

	success := fseek (file, offset, xx origin) != 0;
	curr    := ftell (file);

	return curr - start, success;
}

get_file_cursor :: (file : File) -> cursor : s64 #must
{
	return ftell (file);
}

set_end_of_file_to_cursor :: (file : File) -> bool
{
	file_descriptor := fileno (file);
	length := ftell (file);
	
	return ftruncate (file_descriptor, xx length) == 0;
}

read_file :: (file : File, buffer : *void, buffer_size : s64) -> read : s64, success : bool
{
	read := fread (buffer, 1, xx buffer_size, file);
	
	return xx read, ferror (file) == 0;
}

write_file :: (file : File, buffer : *void, count : s64) -> written : s64, success : bool
{
	written := fwrite (buffer, 1, xx count, file);

	return xx written, written == xx count;
}

copy_file :: (source : string, dest : string, override_if_exists := false) -> bool
{
	file_contents, ok := read_entire_file (source, temp_allocator);
	if !ok then return false;
	written, success := write_to_file (dest, file_contents);

	return success;
}

get_working_directory :: (allocator : Allocator, allocator_data := null) -> string #must
{
	buffer : [4096]u8;
	getcwd (buffer.data, buffer.count);
	result := clone_string (to_string (buffer.data), allocator, allocator_data);
	
	return result;
}

set_working_directory :: (path : string) -> bool
{
	cpath := clone_to_cstring (path, temp_allocator);

	return chdir (cpath) == 0;
}

create_directory :: (dirname : string) -> bool
{
	result := mkdir (clone_to_cstring (dirname, temp_allocator), 0x1ff);
	
	return result == 0 || errno () == EEXIST;
}

delete_empty_directory :: (dirname : string) -> bool
{
	return rmdir (clone_to_cstring (dirname, temp_allocator)) == 0;
}

// Copied from File_Utilities
inspect_directory :: (dirname : string, recurse : bool, user_data : $T, proc : (info : *File_Visit_Info, user_data : T), visit_files := true, visit_directories := true, visit_symlinks := true) -> bool
{
	if !proc then return true;

	dirs := make_array (string, 10, heap_allocator);
	push_to_array (*dirs, clone_string (dirname, heap_allocator));
	defer
	{
		for dirs
			free (it, heap_allocator);
		reset_array (*dirs);
	}

	info : File_Visit_Info = ---;
	current := 0;
	while current < dirs.count
	{
		current_dir := dirs[current];
		current += 1;

		dirp := opendir (clone_to_cstring (current_dir, temp_allocator));
		if !dirp then continue;
		defer closedir (dirp);
		
		entry := readdir (dirp);
		while entry
		{
			info.is_symlink = (entry.d_type == DT_LNK);
			if visit_symlinks || !info.is_symlink
			{
				name := to_string (entry.d_name.data);
				full_name := make_path (heap_allocator, current_dir, "/", name);
				defer free (full_name, heap_allocator);
				
				stats : stat_t;
				if stat (clone_to_cstring (full_name, temp_allocator), *stats) != 0
				{
					error := errno ();
					log_error ("File", "Unable to stat file '%': %.", full_name, error);
					if error != ENOENT && error != EACCES && error != ELOOP then return false;
					info.had_error = true;
				}

				info.name      = name;
				info.full_name = full_name;
				info.descend_into_directory = false;
				is_dir := S_ISDIR (stats.st_mode);
				if is_dir
				{
					if name != "." && name != ".."
					{
						info.descend_into_directory = recurse;
						if visit_directories
						{
							info.is_directory = true;
							proc (*info, user_data);
						}
					}

					if info.descend_into_directory then push_to_array (*dirs, clone_string (full_name, heap_allocator));
				}
				else if visit_files
				{
					info.is_directory = false;
					proc (*info, user_data);
				}
			}

			entry = readdir (dirp);
		}
	}

	return true;
}

#scope_file

chdir :: (path : *u8) -> s32 #foreign libc;
rmdir :: (path : *u8) -> s32 #foreign libc;
ferror :: (stream : *FILE) -> s32 #foreign libc;
ftruncate :: (fileno : s32, length : u64) -> s32 #foreign libc;
fileno :: (stream : *FILE) -> s32 #foreign libc;

libc :: #foreign_system_library "libc";
