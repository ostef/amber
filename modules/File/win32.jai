#assert OS == .WINDOWS "This file should only be loaded on Windows";

#scope_file

#import "Windows";
#import "Windows_Utf8";

win32_file_attributes :: inline (attr : File_Attributes) -> s32 #must
{
	win32_attr : s32;
	if attr == .NONE     then win32_attr  = FILE_ATTRIBUTE_NORMAL;
	if attr & .ARCHIVE   then win32_attr |= FILE_ATTRIBUTE_ARCHIVE;
	if attr & .HIDDEN    then win32_attr |= FILE_ATTRIBUTE_HIDDEN;
	if attr & .NOT_CONTENT_INDEXED then win32_attr |= FILE_ATTRIBUTE_NOT_CONTENT_INDEXED;
	if attr & .OFFLINE   then win32_attr |= FILE_ATTRIBUTE_OFFLINE;
	if attr & .READ_ONLY then win32_attr |= FILE_ATTRIBUTE_READONLY;
	if attr & .SYSTEM    then win32_attr |= FILE_ATTRIBUTE_SYSTEM;
	if attr & .TEMPORARY then win32_attr |= FILE_ATTRIBUTE_TEMPORARY;

	return win32_attr;
}

#scope_export

File :: HANDLE;

get_executable_path :: (allocator : Allocator, allocator_data := null) -> string #must
{
	buffer := alloc (2 * MAX_PATH, temp_allocator);
	length := GetModuleFileNameW (null, buffer, MAX_PATH);

	return wide_to_utf8 (buffer, allocator = allocator, allocator_data = allocator_data);
}

get_full_path :: (path : string, allocator : Allocator, allocator_data := null) -> string #must
{
	wide_path := utf8_to_wide (path);
	length := GetFullPathNameW (wide_path, 0, null, null);
	if length == 0 then return "";
	buffer := alloc (size_of (u16) * (length + 1), temp_allocator);
	GetFullPathNameW (wide_path, length, buffer, null);

	return wide_to_utf8 (buffer, allocator = allocator, allocator_data = allocator_data);
}

path_leads_to_directory :: (path : string) -> bool #must
{
	wstr_path := utf8_to_wide (path);
	attr := GetFileAttributesW (wstr_path);

	return attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY;
}

path_leads_to_file :: (path : string) -> bool #must
{
	wstr_path := utf8_to_wide (path);
	attr := GetFileAttributesW (wstr_path);

	return attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY) != FILE_ATTRIBUTE_DIRECTORY;
}

file_exists :: (filename : string) -> bool #must
{
	wstr_filename := utf8_to_wide (filename);

	return GetFileAttributesW (wstr_filename) != INVALID_FILE_ATTRIBUTES;
}

create_file :: (filename : string, flags : File_Flags, create_tree := true) -> File #must, bool
{
	access, share_mode : s32;
	if flags & File_Flags.READ
	{
		access |= GENERIC_READ;
		share_mode |= FILE_SHARE_READ;
	}

	if flags & File_Flags.WRITE
	{
		access |= GENERIC_WRITE;
		share_mode |= FILE_SHARE_WRITE;
	}

	if flags & File_Flags.EXECUTE
	{
		access |= GENERIC_EXECUTE;
		share_mode |= FILE_SHARE_DELETE;
	}

	if create_tree
	{
		tree := strip_filename_from_path (filename);
		create_directory_tree (tree);
	}

	wstr_filename := utf8_to_wide (filename);
	file := CreateFileW (wstr_filename, access, share_mode, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);

	return file, file != INVALID_HANDLE_VALUE;
}

open_file :: (filename : string, flags : File_Flags) -> File #must, bool
{
	access, share_mode : s32;
	if flags & File_Flags.READ
	{
		access |= GENERIC_READ;
		share_mode |= FILE_SHARE_READ;
	}

	if flags & File_Flags.WRITE
	{
		access |= GENERIC_WRITE;
		share_mode |= FILE_SHARE_WRITE;
	}

	if flags & File_Flags.EXECUTE
	{
		access |= GENERIC_EXECUTE;
		share_mode |= FILE_SHARE_DELETE;
	}

	wstr_filename := utf8_to_wide (filename);
	file := CreateFileW (wstr_filename, access, share_mode, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, null);

	return file, file != INVALID_HANDLE_VALUE;
}

delete_file :: (filename : string) -> bool
{
	wstr_filename := utf8_to_wide (filename);
	
	return DeleteFileW (wstr_filename) != 0;
}

set_file_attributes :: (filename : string, attr : File_Attributes)
{
	wstr_filename := utf8_to_wide (filename);

	return SetFileAttributesW (wstr_filename, win32_file_attributes (attr)) != 0;
}

move_file :: (filename : string, new_name : string) -> bool
{
	wstr_filename := utf8_to_wide (filename);
	wstr_new_name := utf8_to_wide (new_name);

	return MoveFileW (wstr_filename, wstr_new_name) != 0;
}

close_file :: (file : File)
{
	CloseHandle (file);
}

get_file_size :: (file : File) -> s64 #must
{
	size := GetFileSize (file, null);

	return xx size;
}

set_file_cursor :: (file : File, offset : s64, cursor := File_Cursor.BEGIN) -> moved : s64, success : bool
{
	win32_cursor : SetFilePointer_MoveMethod;
	if cursor ==
	{
	case .BEGIN;   win32_cursor = FILE_BEGIN;
	case .END;     win32_cursor = FILE_END;
	case .CURRENT; win32_cursor = FILE_CURRENT;
	}

	moved := SetFilePointer (file, xx offset, null, win32_cursor);

	return xx moved, moved != INVALID_SET_FILE_POINTER;
}

set_end_of_file_to_cursor :: (file : File) -> bool
{
	return SetEndOfFile (file) != 0;
}

read_file :: (file : File, buffer : *void, buffer_size : s64) -> read : s64, success : bool
{
	read : u32;
	ok := ReadFile (file, buffer, xx buffer_size, *read, null);

	return xx read, xx ok;
}

write_file :: (file : File, buffer : *void, count : s64) -> written : s64, success : bool
{
	written : u32;
	ok := WriteFile (file, buffer, xx count, *written, null);

	return xx written, xx ok;
}

copy_file :: (source : string, dest : string, overwrite := false) -> bool
{
	wstr_source := utf8_to_wide (source);
	wstr_dest   := utf8_to_wide (dest);
	
	return CopyFileW (wstr_source, wstr_dest, xx (!overwrite)) != 0;
}

get_working_directory :: (allocator : Allocator, allocator_data := null) -> string #must
{
	length := GetCurrentDirectoryW (0, null);
	buffer := alloc (2 * (length + 1), allocator, allocator_data);
	GetCurrentDirectoryW (length + 1, buffer);

	return wide_to_utf8 (buffer, allocator = allocator, allocator_data = allocator_data);
}

set_working_directory :: (path : string) -> bool
{
	wstr_path := utf8_to_wide (path);

	return SetCurrentDirectoryW (wstr_path) != 0;
}

create_directory :: (dirname : string) -> bool
{
	wstr_dirname := utf8_to_wide (dirname);

	return CreateDirectoryW (wstr_dirname, null) != 0;
}

delete_empty_directory :: (dirname : string) -> bool
{
	wstr_dirname := utf8_to_wide (dirname);

	return RemoveDirectoryW (wstr_dirname) != 0;
}

// Copied from File_Utilities
inspect_directory :: (dirname : string, recurse : bool, user_data : $T, proc : (info : *File_Visit_Info, user_data : T), visit_files := true, visit_directories := true, visit_symlinks := true) -> bool
{
	// @Todo (stefan): Handle is_symlink and had_error.
	if !proc then return true;

	dirs := make_array (string, 10, heap_allocator);
	push_into_array (*dirs, clone_string (dirname, heap_allocator));
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

		mark := get_temporary_storage_mark ();
		wildcard := utf8_to_wide (join (temp_allocator, current_dir, "/*"));

		find_data : WIN32_FIND_DATAW = ---;
		handle := FindFirstFileW (wildcard, *find_data);
		if handle == INVALID_HANDLE_VALUE then continue;

		set_temporary_storage_mark (mark);

		while true
		{
			name := wide_to_utf8 (find_data.cFileName.data, allocator = heap_allocator);
			full_name := make_path (heap_allocator, current_dir, "/", name);
			defer
			{
				free (name, heap_allocator);
				free (full_name, heap_allocator);
			}

			info.name      = name;
			info.full_name = full_name;

			if find_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
			{
				if name != "." && name != ".."
				{
					info.descend_into_directory = recurse;

					if visit_directories
					{
						info.is_directory = true;
						//info.filetime;	// @Todo
						proc (*info, user_data);
					}

					if info.descend_into_directory then push_into_array (*dirs, clone_string (full_name, heap_allocator));
				}
			}
			else
			{
				if visit_files
				{
					info.is_directory = false;
					//info.filetime;	// @Todo
					proc (*info, user_data);
				}
			}

			if !FindNextFileW (handle, *find_data) then break;
		}

		FindClose (handle);
	}

	return true;
}

#scope_file

//#import "Win32";

GENERIC_READ    :: 0x8000_0000;
GENERIC_WRITE   :: 0x4000_0000;
GENERIC_EXECUTE :: 0x2000_0000;

INVALID_SET_FILE_POINTER :: 0xffff_ffff;

CopyFileW :: (lpExistingFileName : *u16, lpNewFileName : *u16, bFailIfExists : s32) -> s32 #foreign kernel32;
GetCurrentDirectoryW :: (nBufferLength : s32, lpBuffer : *u16) -> s32 #foreign kernel32;
SetCurrentDirectoryW :: (lpPathName : *u16) -> s32 #foreign kernel32;
SetEndOfFile :: (hFile : *void) -> s32 #foreign kernel32;

kernel32 :: #foreign_system_library "kernel32";
