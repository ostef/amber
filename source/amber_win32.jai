#assert OS == .WINDOWS "amber_win32.jai should only be loaded on Windows.";

// We try to use the following naming conventions:
//          amber/source/amber_main.jai
// * amber/source/amber_main.jai    is the file name (filename)
// * amber_main.jai                 is the file basename
// * jai                            is the file extension
// * C:/amber/source/amber_main.jai is the absolute or full name
// * amber/source/amber_main.jai    is a relative or short name

// @Todo (stefan): Make sure we respect the above naming conventions everywhere

platform_get_module_filename :: (allocator : Allocator) -> string #must
{
	buffer := alloc (2 * MAX_PATH, TEMP);
	length := GetModuleFileNameW (null, buffer, MAX_PATH);
	
	return wide_to_utf8 (buffer, allocator);
}
@Amber_API

platform_get_full_filename :: (filename : string, allocator : Allocator) -> string #must
{
	wstr_filename := utf8_to_wide (filename, TEMP);
	length := GetFullPathNameW (wstr_filename, 0, null, null);
	if length == 0 then return "";
	buffer := alloc (2 * (length + 1), TEMP);
	GetFullPathNameW (wstr_filename, length, buffer, null);

	return wide_to_utf8 (buffer, allocator);
}
@Amber_API

platform_open_file :: (filename : string, flags : File_Open_Flags, attributes := File_Attributes.NORMAL) -> File_Handle #must
{
	access, share_mode : DWORD;
	if flagged (flags, .ACCESS_READ)
	{
		access |= GENERIC_READ;
		share_mode |= FILE_SHARE_READ;
	}

	if flagged (flags, .ACCESS_WRITE)
	{
		access |= GENERIC_WRITE;
		share_mode |= FILE_SHARE_WRITE;
	}

	open_mode : DWORD;
	if flagged (flags, .OPEN_IF_EXISTS) then open_mode = OPEN_EXISTING;
	else if flagged (flags, .OPEN_OR_CREATE) then open_mode = OPEN_ALWAYS;
	else if flagged (flags, .ALWAYS_CREATE) then open_mode = CREATE_ALWAYS;
	
	file := CreateFileW (utf8_to_wide (filename, TEMP), access, share_mode, null, open_mode, file_attributes_to_win32 (attributes), null);
	if file == INVALID_HANDLE_VALUE then return null;
	
	return file;
}
@Amber_API

platform_close_file :: (file : File_Handle)
{
	CloseHandle (file);
}
@Amber_API

platform_delete_file :: (filename : string) -> bool
{
	return DeleteFileW (utf8_to_wide (filename, TEMP)) != 0;
}
@Amber_API

platform_move_file :: (src : string, dest : string) -> bool
{
	return MoveFileW (utf8_to_wide (src, TEMP), utf8_to_wide (dest, TEMP)) != 0;
}
@Amber_API

platform_get_file_cursor :: (file : File_Handle) -> offset : s64
{
	offset := SetFilePointer (file, 0, null, FILE_CURRENT);
	
	return xx offset;
}
@Amber_API

platform_set_file_cursor :: (file : File_Handle, offset : s64, cursor := File_Cursor.BEGIN) -> moved : s64, success : bool
{
	win32_cursor : DWORD;
	if #complete cursor ==
	{
	case .BEGIN;   win32_cursor = FILE_BEGIN;
	case .END;     win32_cursor = FILE_END;
	case .CURRENT; win32_cursor = FILE_CURRENT;
	}
	
	moved := SetFilePointer (file, xx offset, null, win32_cursor);
	
	return xx moved, moved != INVALID_SET_FILE_POINTER;
}
@Amber_API

platform_set_eof_to_cursor :: (file : File_Handle) -> bool
{
	return SetEndOfFile (file) != 0;
}
@Amber_API

platform_read_file :: (file : File_Handle, buffer : *void, buffer_size : s64) -> read : s64, success : bool
{
	read : u32;
	ok := ReadFile (file, buffer, xx buffer_size, *read, null);
	
	return xx read, xx ok;
}
@Amber_API

platform_write_file :: (file : File_Handle, buffer : *void, count : s64) -> written : s64, success : bool
{
	written : u32;
	ok := WriteFile (file, buffer, xx count, *written, null); 
	
	return xx written, xx ok;
}
@Amber_API

platform_file_exists :: (filename : string) -> bool #must
{
	return GetFileAttributesW (utf8_to_wide (filename, TEMP)) != INVALID_FILE_ATTRIBUTES;
}
@Amber_API

#scope_file

win32_to_file_attributes :: (win32_attrs : DWORD) -> File_Attributes #must
{
	result : File_Attributes;
	if flagged (win32_attrs, FILE_ATTRIBUTE_DIRECTORY)
		set_flag (*result, .DIRECTORY);
	if flagged (win32_attrs, FILE_ATTRIBUTE_HIDDEN)
		set_flag (*result, .HIDDEN);
	if flagged (win32_attrs, FILE_ATTRIBUTE_READONLY)
		set_flag (*result, .READ_ONLY);
	if flagged (win32_attrs, FILE_ATTRIBUTE_REPARSE_POINT)
		set_flag (*result, .SYMLINK);
	if flagged (win32_attrs, FILE_ATTRIBUTE_TEMPORARY)
		set_flag (*result, .TEMPORARY);

	return result;
}

file_attributes_to_win32 :: (attributes : File_Attributes) -> DWORD #must
{
	win32_attrs : DWORD;
	if flagged (attributes, .DIRECTORY)
		set_flag (*win32_attrs, FILE_ATTRIBUTE_DIRECTORY);
	if flagged (attributes, .HIDDEN)
		set_flag (*win32_attrs, FILE_ATTRIBUTE_HIDDEN);
	if flagged (attributes, .READ_ONLY)
		set_flag (*win32_attrs, FILE_ATTRIBUTE_READONLY);
	if flagged (attributes, .SYMLINK)
		set_flag (*win32_attrs, FILE_ATTRIBUTE_REPARSE_POINT);
	if flagged (attributes, .TEMPORARY)
		set_flag (*win32_attrs, FILE_ATTRIBUTE_TEMPORARY);
		
	return win32_attrs;
}

#scope_export

platform_get_file_attributes :: (filename : string) -> File_Attributes, exists : bool
{
	win32_attrs := GetFileAttributesW (utf8_to_wide (filename, TEMP));
	if win32_attrs == INVALID_FILE_ATTRIBUTES then return 0, false;
	
	return win32_to_file_attributes (win32_attrs), true;
}
@Amber_API

platform_set_file_attributes :: (filename : string, attributes : File_Attributes) -> bool
{
	remove_flag (*attributes, .DIRECTORY);
	remove_flag (*attributes, .SYMLINK);
	
	return SetFileAttributesW (utf8_to_wide (filename, TEMP), file_attributes_to_win32 (attributes)) != 0;
}
@Amber_API

#scope_file

list_files_helper :: (dirname : string, parent_index : s64, all_files : *[..]File_Info) -> bool
{
	wildcard := utf8_to_wide (join (TEMP, dirname, "/*"), TEMP);
	find_data : WIN32_FIND_DATAW = ---;
	find_handle := FindFirstFileW (wildcard, *find_data);
	if find_handle == INVALID_HANDLE_VALUE
	{
		println ("FindFirstFileW failed: %", GetLastError ());
		
		return false;
	}
	defer FindClose (find_handle);
	
	prev_sibling_index := -1;
	while true
	{
		utf8_name := wide_to_utf8 (find_data.cFileName.data, TEMP);
		is_root := utf8_name == ".";
		// Include the root directory '.' if parent is null, because we return
		// the root in platform_list_files_in_directory. Otherwise ignore it.
		if is_root && parent_index < 0 || utf8_name != "." && utf8_name != ".."
		{
			if all_files.count == 0 then assert (is_root, "The first visited file should be the root, but it was '%'.", utf8_name);
			
			file_info := push_into_array (all_files);
			file_info.name = clone_string (utf8_name, all_files.allocator);
			file_info.full_name = join (all_files.allocator, dirname, "/", file_info.name);
			file_info.attributes = win32_to_file_attributes (find_data.dwFileAttributes);
			file_info.size   = cast (s64) find_data.nFileSizeHigh * (0xffff_ffff + 1) + cast (s64) find_data.nFileSizeLow;
			file_info.parent = ifx parent_index > -1 then *all_files.data[parent_index] else null;
			file_info.prev_sibling = ifx parent_index > -1 then *all_files.data[prev_sibling_index] else null;
			
			if prev_sibling_index > -1
				all_files.data[prev_sibling_index].next_sibling = file_info;
			else if parent_index > -1
				all_files.data[parent_index].first_child = file_info;
			
			if is_root then parent_index = all_files.count - 1;
			else prev_sibling_index = all_files.count - 1;
			
			if flagged (file_info.attributes, .DIRECTORY) && file_info.name != "."
				file_info.has_errors = !list_files_helper (file_info.full_name, all_files.count - 1, all_files);
		}
		
		if !FindNextFileW (find_handle, *find_data) then break;
	}
	
	return true;
}

#scope_export

// @Note (stefan): The File_Infos are allocated contiguously, and the first File_Info is also the root.
// This means you can ignore the all_files array, and only care about the root when you have to free the
// allocated File_Infos.
platform_list_files_in_directory :: (dirname : string, allocator : Allocator) -> root : *File_Info #must, all_files : []File_Info
{
	all_files : [..]File_Info;
	all_files.allocator = allocator;;
	ok := list_files_helper (dirname, -1, *all_files);
	if !ok
	{
		// @Note (stefan): If list_files_helper returned false then all_files
		// should be empty, and nothing got allocated. We still reset the array
		// for sanity though.
		reset_array (*all_files);
		
		return null, all_files;
	}
	
	return *all_files[0], all_files;
}
@Amber_API

platform_create_directory :: (dirname : string) -> bool
{
	return CreateDirectoryW (utf8_to_wide (dirname, TEMP), null) != 0;
}
@Amber_API

platform_delete_empty_directory :: (dirname : string) -> bool
{
	return RemoveDirectoryW (utf8_to_wide (dirname, TEMP)) != 0;
}
@Amber_API

platform_get_working_directory :: (allocator : Allocator) -> string #must
{
	length := GetCurrentDirectoryW (0, null);
	buffer := alloc (2 * (length + 1), TEMP);
	GetCurrentDirectoryW (length + 1, buffer);
	
	return wide_to_utf8 (buffer, allocator);
}
@Amber_API

platform_set_working_directory :: (dirname : string) -> bool
{
	return SetCurrentDirectoryW (utf8_to_wide (dirname, TEMP)) != 0;
}
@Amber_API

platform_load_library :: (filename : string) -> Library_Handle #must
{
	result := LoadLibraryW (utf8_to_wide (filename, TEMP));
	if result == INVALID_HANDLE_VALUE then return null;
	
	return result;
}
@Amber_API

platform_free_library :: (lib : Library_Handle)
{
	FreeLibrary (lib);
}
@Amber_API

platform_get_proc_address :: (lib : Library_Handle, proc_name : string) -> *void #must
{
	cstr_proc_name := clone_to_cstring (proc_name, TEMP);

	return GetProcAddress (lib, cstr_proc_name);
}
@Amber_API

#scope_file

win32_base_performance_counter : s64;

#scope_export

platform_get_time :: () -> f64 #must
{
	compare_and_swap :: (dest : *s64, old : s64, new : s64) -> bool, s64
	{
		actual_old := old;
		#asm
		{
			old === a;
			lock_cmpxchg.q old, [dest], new;
		}
		
		return actual_old == old, actual_old;
	}
	
	if win32_base_performance_counter == 0
	{
		counter : s64;
		ok := QueryPerformanceCounter (*counter);
		assert (ok != 0, "QueryPerformanceCounter failed.");
		compare_and_swap (*win32_base_performance_counter, 0, counter);
	}
	
	ticks : s64;
	ok := QueryPerformanceCounter (*ticks);
	assert (ok != 0, "QueryPerformanceCounter failed.");
	ticks -= win32_base_performance_counter;
	frequency : s64;

	ok = QueryPerformanceFrequency (*frequency);
	assert (ok != 0, "QueryPerformanceFrequency failed.");
	div := ticks / frequency;
	mod := ticks % frequency;

	return cast (f64) div + mod / cast (f64) frequency;
}
@Amber_API

platform_sleep_milliseconds :: (milliseconds : s64)
{
	Sleep (xx milliseconds);
}
@Amber_API

platform_heap_alloc :: inline (size : s64) -> *void
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null.");

	return HeapAlloc (heap, 0, xx size);
}
@Amber_API

platform_heap_realloc :: inline (ptr : *void, new_size : s64) -> *void
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null.");

	return HeapReAlloc (heap, 0, ptr, xx new_size);
}
@Amber_API

platform_heap_free :: inline (ptr : *void)
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null.");
	HeapFree (heap, 0, xx ptr);
}
@Amber_API

#scope_file

win32_cursors : struct
{
	arrow : HANDLE;
	arrow_busy : HANDLE;
	busy : HANDLE;
	cross : HANDLE;
	hand : HANDLE;
	ibeam : HANDLE;
	resize : HANDLE;
	resize_top_left_bottom_right : HANDLE;
	resize_top_right_bottom_left : HANDLE;
	resize_horizontal : HANDLE;
	resize_vertical : HANDLE;
	#place arrow;
	type : [11]HANDLE;
}

window_class : WNDCLASSEXW;
window : struct
{
	hwnd : HANDLE;
	hdc  : HANDLE;
	hglrc : HANDLE;
};

#scope_export

platform_open_error_box :: inline (fmt : string, args : ..Any)
{
	message := fstring (TEMP, fmt, ..args);
	MessageBoxW (window.hwnd, utf8_to_wide (message, TEMP), utf8_to_wide ("Amber", TEMP), MB_OK | MB_ICONERROR);
}
@Amber_API

platform_init_window_and_gl :: ()
{
	// Load cursors
	{
		using win32_cursors;
		arrow   = LoadCursorW (null, cast (*u16) IDC_ARROW);
		arrow_busy = LoadCursorW (null, cast (*u16) IDC_APPSTARTING);
		busy    = LoadCursorW (null, cast (*u16) IDC_WAIT);
		cross   = LoadCursorW (null, cast (*u16) IDC_CROSS);
		hand    = LoadCursorW (null, cast (*u16) IDC_HAND);
		ibeam   = LoadCursorW (null, cast (*u16) IDC_IBEAM);
		resize  = LoadCursorW (null, cast (*u16) IDC_SIZEALL);
		resize_top_left_bottom_right = LoadCursorW (null, cast (*u16) IDC_SIZENWSE);
		resize_top_right_bottom_left = LoadCursorW (null, cast (*u16) IDC_SIZENESW);
		resize_horizontal = LoadCursorW (null, cast (*u16) IDC_SIZEWE);
		resize_vertical   = LoadCursorW (null, cast (*u16) IDC_SIZENS);
	}
	
	// Register window class
	{
		using window_class;
		hInstance   = GetModuleHandleW (null);
		cbSize      = size_of (WNDCLASSEXW);
		lpszClassName = utf8_to_wide ("AMBER WINDOW CLASS", HEAP);
		style       = CS_OWNDC | CS_DBLCLKS;
		lpfnWndProc = xx window_proc;
		// @Todo (stefan): Set window icon.
		
		RegisterClassExW (*window_class);
	}
	
	// Create a dummy window so we can load OpenGL extensions
	{
		hwnd := CreateWindowExW (
			0,
			window_class.lpszClassName,
			window_class.lpszClassName,
			WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			null,
			null,
			window_class.hInstance,
			null
		);
		defer DestroyWindow (hwnd);
		
		hdc := GetDC (hwnd);
		defer ReleaseDC (hwnd, hdc);
		pfd : PIXELFORMATDESCRIPTOR;
		pfd.nSize = size_of (PIXELFORMATDESCRIPTOR);
		pfd.nVersion = 1;
		pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
		pfd.iPixelType = PFD_TYPE_RGBA;
		pfd.cColorBits = 32;
		pfd.cDepthBits = 24;
		pfd.cStencilBits = 8;
		pfd.iLayerType = PFD_MAIN_PLANE;
		pixel_format := ChoosePixelFormat (hdc, *pfd);
		SetPixelFormat (hdc, pixel_format, *pfd);
		
		hglrc := wglCreateContext (hdc);
		defer wglDeleteContext (hglrc);
		wglMakeCurrent (hdc, hglrc);
		defer wglMakeCurrent (hdc, null);
		
		// Load OpenGL function pointers and available extensions.
		platform_load_gl ();
	}

	// Create the actual window and graphics devices
	{
		using window;
		hwnd = CreateWindowExW (
			0,
			window_class.lpszClassName,
			utf8_to_wide ("Amber", TEMP),
			WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			null,
			null,
			window_class.hInstance,
			null
		);
		
		hdc = GetDC (hwnd);
		pfd : PIXELFORMATDESCRIPTOR;
		pfd.nSize = size_of (PIXELFORMATDESCRIPTOR);
		pfd.nVersion = 1;
		pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
		pfd.iPixelType = PFD_TYPE_RGBA;
		pfd.cColorBits = 32;
		pfd.cDepthBits = 24;
		pfd.cStencilBits = 8;
		
		attributes := s32.[
			WGL_DRAW_TO_WINDOW_ARB, 1,
			WGL_SUPPORT_OPENGL_ARB, 1,
			WGL_DOUBLE_BUFFER_ARB, 1,
			WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
			WGL_COLOR_BITS_ARB, 32,
			WGL_DEPTH_BITS_ARB, 24,
			WGL_STENCIL_BITS_ARB, 8,
			WGL_SAMPLE_BUFFERS_ARB, 1,
			WGL_SAMPLES_ARB, 4,
			0
		];
		pixel_format : s32;
		num_formats : u32;
		float_attributes := f32.[ 0, 0 ];
		valid := wglChoosePixelFormatARB (hdc, attributes.data, float_attributes.data, 1, *pixel_format, *num_formats);
		// We don't have multisampling, so let Windows choose the closest pixel format from the descriptor.
		if !valid || num_formats < 1
			pixel_format = ChoosePixelFormat (window.hdc, *pfd);
		SetPixelFormat (window.hdc, pixel_format, *pfd);
		
		hglrc = wglCreateContext (hdc);
		wglMakeCurrent (hdc, hglrc);
		ShowWindow (hwnd, SW_SHOWDEFAULT);
		SetFocus (hwnd);
	}

	platform_set_cursor (.ARROW);
}

platform_get_next_event :: inline (out : *Event) -> bool #must
{
	msg : MSG;
	initialize_item (*current_event);
	if PeekMessageW (*msg, window.hwnd, 0, 0, PM_REMOVE)
	{
		TranslateMessage (*msg);
		DispatchMessageW (*msg);
		<<out = current_event;
		
		return true;
	}

	return false;
}

platform_swap_window_buffers :: inline ()
{
	SwapBuffers (window.hdc);
}

platform_set_cursor :: inline (type : Cursor_Type)
{
	SetCursor (win32_cursors.type[cast (int) type]);
}
@Amber_API

platform_get_window_size :: inline () -> Vec2i #must
{
	rect : RECT;
	GetWindowRect (window.hwnd, *rect);

	return vec2i (rect.right - rect.left, rect.bottom - rect.top);
}
@Amber_API

platform_get_viewport_size :: inline () -> Vec2i #must
{
	rect : RECT;
	GetClientRect (window.hwnd, *rect);

	return vec2i (rect.right - rect.left, rect.bottom - rect.top);
}
@Amber_API

platform_is_window_focused :: inline () -> bool #must
{
	return GetFocus () == window.hwnd;
}
@Amber_API

platform_get_mod_state :: () -> Mods #must
{
	result : Mods;
	if (GetAsyncKeyState (VK_SHIFT) & 0x8000) != 0
		result |= .SHIFT;
	if (GetAsyncKeyState (VK_CONTROL) & 0x8000) != 0
		result |= .CONTROL;
	if (GetAsyncKeyState (VK_MENU) & 0x8000) != 0
		result |= .ALT;
	
	return result;
}
@Amber_API

platform_get_mouse_position :: () -> Vec2f #must
{
	result : POINT;
	GetCursorPos (*result);
	ScreenToClient (window.hwnd, *result);

	return vec2f (xx result.x, xx result.y);
}
@Amber_API

#scope_file

prev_keyboard_state : [Key_Code.COUNT]bool;
prev_mouse_state    : [Mouse_Button.COUNT]bool;
keyboard_state : [Key_Code.COUNT]bool;
mouse_state    : [Mouse_Button.COUNT]bool;

#scope_export

platform_reset_input_state :: ()
{
	memcpy (prev_keyboard_state.data, keyboard_state.data, size_of (type_of (prev_keyboard_state)));
	memcpy (prev_mouse_state.data, mouse_state.data, size_of (type_of (prev_mouse_state)));
	for * keyboard_state
	{
		<<it = (GetAsyncKeyState (xx it_index) & 0x8000) != 0;
	}
	mouse_state[0] = (GetAsyncKeyState (VK_LBUTTON) & 0x8000) != 0;
	mouse_state[1] = (GetAsyncKeyState (VK_MBUTTON) & 0x8000) != 0;
	mouse_state[2] = (GetAsyncKeyState (VK_RBUTTON) & 0x8000) != 0;
}

platform_get_key_state :: inline (key_code : Key_Code) -> Key_State #must
{
	prev_state := prev_keyboard_state[cast (s64) key_code];
	state      := keyboard_state[cast (s64) key_code];
	if prev_state && !state
		return .RELEASED;
	else if !prev_state && state
		return .PRESSED;
	else if !prev_state && !state
		return .UP;
	
	return .DOWN;
}
@Amber_API

platform_get_mouse_button_state :: inline (mouse_button : Mouse_Button) -> Button_State #must
{
	prev_state := prev_mouse_state[cast (s64) mouse_button];
	state      := mouse_state[cast (s64) mouse_button];
	if prev_state && !state
		return .RELEASED;
	else if !prev_state && state
		return .PRESSED;
	else if !prev_state && !state
		return .UP;
	
	return .DOWN;
}
@Amber_API

/*
platform_get_window_title :: (allocator : Allocator) -> string #must
platform_set_window_title :: (title : string)
platform_get_mouse_wheel_state :: () -> Vec2f #must
platform_get_window_position :: () -> Vec2i #must
*/

LOGFONTW :: struct
{
	lfHeight : LONG;
	lfWidth  : LONG;
	lfEscapement  : LONG;
	lfOrientation : LONG;
	lfWeight : LONG;
	lfItalic : u8;
	lfUnderline : u8;
	lfStrikeOut : u8;
	lfCharSet : u8;
	lfOutPrecision : u8;
	lfClipPrecision : u8;
	lfQuality : u8;
	lfPitchAndFamily : u8;
	lfFaceName : [32]u16;
}

LOGFONTA :: struct
{
	lfHeight : LONG;
	lfWidth  : LONG;
	lfEscapement  : LONG;
	lfOrientation : LONG;
	lfWeight : LONG;
	lfItalic : u8;
	lfUnderline : u8;
	lfStrikeOut : u8;
	lfCharSet : u8;
	lfOutPrecision : u8;
	lfClipPrecision : u8;
	lfQuality : u8;
	lfPitchAndFamily : u8;
	lfFaceName : [32]u8;
}

DEFAULT_CHARSET : u8 : 1;

TEXTMETRICW :: struct
{
	tmHeight : LONG;
	tmAscent : LONG;
	tmDescent : LONG;
	tmInternalLeading : LONG;
	tmExternalLeading : LONG;
	tmAveCharWidth : LONG;
	tmMaxCharWidth : LONG;
	tmWeight : LONG;
	tmOverhang : LONG;
	tmDigitizedAspectX : LONG;
	tmDigitizedAspectY : LONG;
	tmFirstChar : u16;
	tmLastChar : u16;
	tmDefaultChar : u16;
	tmBreakChar : u16;
	tmItalic : u8;
	tmUnderlined : u8;
	tmStruckOut : u8;
	tmPitchAndFamily : u8;
	tmCharSet : u8;
}

TEXTMETRICA :: struct
{
	tmHeight : LONG;
	tmAscent : LONG;
	tmDescent : LONG;
	tmInternalLeading : LONG;
	tmExternalLeading : LONG;
	tmAveCharWidth : LONG;
	tmMaxCharWidth : LONG;
	tmWeight : LONG;
	tmOverhang : LONG;
	tmDigitizedAspectX : LONG;
	tmDigitizedAspectY : LONG;
	tmFirstChar : u8;
	tmLastChar : u8;
	tmDefaultChar : u8;
	tmBreakChar : u8;
	tmItalic : u8;
	tmUnderlined : u8;
	tmStruckOut : u8;
	tmPitchAndFamily : u8;
	tmCharSet : u8;
}

FONTENUMPROCW :: #type (lplf : *LOGFONTW, lptm : *TEXTMETRICW, dwType : DWORD, lpData : LPARAM) -> s32 #c_call;
FONTENUMPROCA :: #type (lplf : *LOGFONTA, lptm : *TEXTMETRICA, dwType : DWORD, lpData : LPARAM) -> s32 #c_call;

EnumFontFamiliesExW :: (hdc : HDC, lpLogFont : *LOGFONTW, lpProc : FONTENUMPROCW, lParam : LPARAM, dwFlags : DWORD) -> s32 #foreign gdi32;
EnumFontFamiliesExA :: (hdc : HDC, lpLogFont : *LOGFONTA, lpProc : FONTENUMPROCA, lParam : LPARAM, dwFlags : DWORD) -> s32 #foreign gdi32;

print_fontsw :: (lplf : *LOGFONTW, lptm : *TEXTMETRICW, dwType : DWORD, lpData : LPARAM) -> s32 #c_call
{
	ctx : Context;
	push_context ctx
	{
		wide_name := wide_to_utf8 (lplf.lfFaceName.data, TEMP);
		println (wide_name);
	}
	
	return 1;
}

print_fontsa :: (lplf : *LOGFONTA, lptm : *TEXTMETRICA, dwType : DWORD, lpData : LPARAM) -> s32 #c_call
{
	ctx : Context;
	push_context ctx
	{
		if lpData == 0
		{
			filter : LOGFONTA;
			filter.lfCharSet = DEFAULT_CHARSET;
			memcpy (filter.lfFaceName.data, lplf.lfFaceName.data, 32);
			EnumFontFamiliesExA (window.hdc, *filter, print_fontsa, 1, 0);
		}
		println ("name: % height: % width: % weight: % italic: % strikeout: % underline: % pitch: %", to_string (lplf.lfFaceName.data), lplf.lfHeight, lplf.lfWidth, lplf.lfWeight, lplf.lfItalic, lplf.lfStrikeOut, lplf.lfUnderline, lplf.lfPitchAndFamily);
	}
	
	return 1;
}

platform_enum_font_families :: (allocator : Allocator) -> []Font_Info #must
{
	filter : LOGFONTA;
	filter.lfCharSet = DEFAULT_CHARSET;
	EnumFontFamiliesExA (window.hdc, *filter, print_fontsa, 0, 0);
	result : []Font_Info;
	
	return result;
}

#scope_file

wm_char_utf16_high_surrogate : u16;

win32_vk_to_key_code :: (vk : WPARAM) -> Key_Code #must
{
	return cast (Key_Code) vk;
}

is_repeat :: (lparam : LPARAM) -> bool #must
{
	return (lparam >> 30) != 0;
}

current_event : Event;

window_proc :: (hwnd : HANDLE, msg : u32, wparam : WPARAM, lparam : LPARAM) -> LRESULT #c_call
{
	ctx : Context;
	push_context ctx
	{
		if msg ==
		{
		case WM_CLOSE;
			current_event.kind = .WINDOW_CLOSE;
		
		case WM_MOVE;
			current_event.kind = .WINDOW_MOVE;
			current_event.window_position.x = xx LOWORD_L (lparam);
			current_event.window_position.y = xx HIWORD_L (lparam);
	
		case WM_SIZE;
			current_event.kind = .WINDOW_RESIZE;
			current_event.viewport_size.x = xx LOWORD_L (lparam);
			current_event.viewport_size.y = xx HIWORD_L (lparam);
	
		case WM_SYSKEYDOWN; #through;
		case WM_SYSKEYUP; #through;
		case WM_KEYDOWN; #through;
		case WM_KEYUP;
			if msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN
				current_event.kind = ifx is_repeat (lparam) then Event.Kind.KEY_REPEAT else Event.Kind.KEY_PRESS;
			else
				current_event.kind = .KEY_RELEASE;
			current_event.mods = platform_get_mod_state ();
			current_event.key_code = win32_vk_to_key_code (wparam);
			keyboard_state[cast (s64) current_event.key_code] = current_event.kind != .KEY_RELEASE;
			
			// Handle ALT+F4 and such
			if msg == WM_SYSKEYDOWN || msg == WM_SYSKEYUP
				return DefWindowProcW (hwnd, msg, wparam, lparam);
	
		case WM_CHAR;
			codepoint := cast (u32) wparam;
			UTF16_HI_SURROGATE  :: cast (u16) 0xd800;
			UTF16_LO_SURROGATE  :: cast (u16) 0xdc00;
			UTF16_SURROGATE_END :: cast (u16) 0xdfff;
	
			if codepoint >= UTF16_HI_SURROGATE && codepoint < UTF16_LO_SURROGATE
			{
				wm_char_utf16_high_surrogate = cast (u16) codepoint;
			}
			else
			{
				if codepoint >= UTF16_LO_SURROGATE && codepoint <= UTF16_SURROGATE_END
				{
					low_surrogate := cast (u16) codepoint;
					codepoint  = (wm_char_utf16_high_surrogate - UTF16_HI_SURROGATE) << 10;
					codepoint |= (low_surrogate - UTF16_HI_SURROGATE);
					codepoint += 0x10000;
				}
				
				if codepoint >= #char " " && codepoint != 127 || is_space (codepoint)
				{
					current_event.kind      = .TEXT_INPUT;
					current_event.mods      = platform_get_mod_state ();
					current_event.codepoint = codepoint;
				}
			}

		case WM_LBUTTONDOWN; #through;
		case WM_LBUTTONUP; #through;
		case WM_LBUTTONDBLCLK; #through;
		case WM_MBUTTONDOWN; #through;
		case WM_MBUTTONUP; #through;
		case WM_MBUTTONDBLCLK; #through;
		case WM_RBUTTONDOWN; #through;
		case WM_RBUTTONUP; #through;
		case WM_RBUTTONDBLCLK;
			if msg ==
			{
			case WM_LBUTTONDOWN;
				current_event.kind = .MOUSE_PRESS;
				current_event.mouse_button = .LEFT;
			
			case WM_LBUTTONUP;
				current_event.kind = .MOUSE_RELEASE;
				current_event.mouse_button = .LEFT;
			
			case WM_LBUTTONDBLCLK;
				current_event.kind = .MOUSE_REPEAT;
				current_event.mouse_button = .LEFT;
			
			case WM_MBUTTONDOWN;
				current_event.kind = .MOUSE_PRESS;
				current_event.mouse_button = .MIDDLE;
			
			case WM_MBUTTONUP;
				current_event.kind = .MOUSE_RELEASE;
				current_event.mouse_button = .MIDDLE;
			
			case WM_MBUTTONDBLCLK;
				current_event.kind = .MOUSE_REPEAT;
				current_event.mouse_button = .MIDDLE;
			
			case WM_RBUTTONDOWN;
				current_event.kind = .MOUSE_PRESS;
				current_event.mouse_button = .RIGHT;
			
			case WM_RBUTTONUP;
				current_event.kind = .MOUSE_RELEASE;
				current_event.mouse_button = .RIGHT;
			
			case WM_RBUTTONDBLCLK;
				current_event.kind = .MOUSE_REPEAT;
				current_event.mouse_button = .RIGHT;
			}
			current_event.mouse_position.x = cast (f32) LOWORD_L (lparam);
			current_event.mouse_position.y = cast (f32) HIWORD_L (lparam);
			current_event.mods = platform_get_mod_state ();
			mouse_state[cast (s64) current_event.mouse_button] = current_event.kind != .MOUSE_RELEASE;
		
		case WM_MOUSEHWHEEL; #through;
		case WM_MOUSEWHEEL;
			current_event.kind = .MOUSE_WHEEL;
			if msg == WM_MOUSEHWHEEL
				current_event.mouse_wheel.x = HIWORD_W (wparam) / 120.0;
			else
				current_event.mouse_wheel.y = HIWORD_W (wparam) / 120.0;
			current_event.mods = platform_get_mod_state ();
			current_event.mouse_position = platform_get_mouse_position ();
		
		// @Todo (stefan): Touchpad inertia scrolling.
		case WM_MOUSEMOVE;
			current_event.kind = .MOUSE_MOVE;
			current_event.mods = platform_get_mod_state ();
			current_event.mouse_position.x = cast (f32) LOWORD_L (lparam);
			current_event.mouse_position.y = cast (f32) HIWORD_L (lparam);
		
		case;
			return DefWindowProcW (hwnd, msg, wparam, lparam);
		}
	}
	
	return 0;
}

// @Note (stefan): We have our utf16 procedures in amber_unicode.jai, but these are big endian, and windows is little endian.

wide_to_utf8 :: (data: *u16, allocator : Allocator) -> result: string, success: bool
{
	query_result := WideCharToMultiByte (CP_UTF8, 0, data, -1, null, 0, null, null);

	if query_result <= 0
		return "", false;

	name := "";
	name_bytes := cast (*u8) alloc (query_result, allocator);
	result := WideCharToMultiByte (CP_UTF8, 0, data, -1, name_bytes, query_result, null, null);

	if result > 0
	{
		assert (result <= query_result);
		
		name.data  = name_bytes;
		name.count = result - 1;  // Do not include the terminating zero.
		assert (name.data[name.count] == 0);
		
		return name, true;
	}

	return "", false;
}

utf8_to_wide :: (utf8_str : string, allocator : Allocator) -> data: *u16, success: bool, result_length_in_bytes: s32 {
	if !utf8_str
		return null, true, 0;
	query_num_chars := MultiByteToWideChar (CP_UTF8, 0, utf8_str.data, cast(s32) utf8_str.count, null, 0);
	if query_num_chars <= 0
		return null, false, 0;
	
	name := "";
	name_u16s := cast (*u16) alloc ((query_num_chars + 1) * size_of (u16), allocator);
	result_num_chars := MultiByteToWideChar (CP_UTF8, 0, utf8_str.data, cast(s32) utf8_str.count, name_u16s, query_num_chars);

	if result_num_chars > 0
	{
		assert (result_num_chars <= query_num_chars);
		name_u16s[result_num_chars] = 0;
		
		return name_u16s, true, result_num_chars * 2;
	}

	return name_u16s, false, 0;
}

CP_UTF8 : u32 : 65001;

WideCharToMultiByte :: (
	CodePage: u32,
	dwFlags: s32,
	lpWideCharStr: *u16,
	cchWideChar: s32,
	lpMultiByteStr: *u8,
	cbMultiByte: s32,
	lpDefaultChar: *u8,
	lpUsedDefaultChar: *s32
) -> s32 #foreign kernel32;

MultiByteToWideChar :: (
	CodePage: u32,
	dwFlags: s32,
	lpMultiByteStr: *u8,
	cbMultiByte: s32,
	lpWideCharStr: *u16,
	cchWideChar: s32
) -> s32 #foreign kernel32;

HANDLE :: *void;
INVALID_HANDLE_VALUE : HANDLE : cast (HANDLE) -1;
WORD   :: u16;
DWORD  :: u32;
BOOL   :: s32;
LONG   :: s32;
ULONG  :: u32;
WPARAM :: u64;
LPARAM :: s64;
LRESULT :: s64;

POINT :: struct
{
	x, y : LONG;
}

RECT :: struct
{
	left, top, right, bottom : LONG;
}

SECURITY_ATTRIBUTES :: struct
{
	nLength : DWORD;
	lpSecurityDescriptor : *void;
	bInheritHandle : BOOL;
}

GENERIC_EXECUTE : DWORD : 0x2000_0000;
GENERIC_WRITE   : DWORD : 0x4000_0000;
GENERIC_READ    : DWORD : 0x8000_0000;
FILE_SHARE_READ  : DWORD : 0x01;
FILE_SHARE_WRITE : DWORD : 0x02;

CREATE_ALWAYS : DWORD : 2;
OPEN_EXISTING : DWORD : 3;
OPEN_ALWAYS   : DWORD : 4;

FILE_ATTRIBUTE_NORMAL : DWORD : 0x80;
FILE_ATTRIBUTE_DIRECTORY : DWORD : 0x10;
FILE_ATTRIBUTE_READONLY : DWORD : 0x01;
FILE_ATTRIBUTE_REPARSE_POINT : DWORD : 0x400;
FILE_ATTRIBUTE_HIDDEN : DWORD : 0x02;
FILE_ATTRIBUTE_TEMPORARY : DWORD : 0x100;

CreateFileW :: (
	lpFileName : *u16,
	dwDesiredAccess : DWORD,
	dwShareMode : DWORD,
	lpSecurityAttributes : *SECURITY_ATTRIBUTES,
	dwCreationDisposition : DWORD,
	dwFlagsAndAttributes : DWORD,
	hTemplateFile : HANDLE
) -> HANDLE #foreign kernel32;

CloseHandle :: (hObject : HANDLE) -> BOOL #foreign kernel32;
DeleteFileW :: (lpFileName : *u16) -> BOOL #foreign kernel32;
MoveFileW :: (lpExistingFileName : *u16, lpNewFileName : *u16) -> BOOL #foreign kernel32;

FILE_BEGIN   : DWORD : 0;
FILE_CURRENT : DWORD : 1;
FILE_END     : DWORD : 2;

SetFilePointer :: (
	hFile : HANDLE,
	lDistanceToMove : LONG,
	lpDistanceToMoveHigh : *LONG,
	dwMoveMethod : DWORD
) -> DWORD #foreign kernel32;

INVALID_SET_FILE_POINTER : DWORD : 0xffff_ffff;

SetEndOfFile :: (hFile : HANDLE) -> BOOL #foreign kernel32;

OVERLAPPED :: struct
{
	Internal : *ULONG;
	InternalHigh : *ULONG;
	union
	{
		struct
		{
			Offset : DWORD;
			OffsetHigh : DWORD;
		};
		Pointer : *void;
	};
	hEvent : HANDLE;
}

ReadFile :: (
	hFile : HANDLE,
	lpBuffer : *void,
	nNumberOfBytesToRead : DWORD,
	lpNumberOfBytesRead : *DWORD,
	lpOverlapped : *OVERLAPPED
) -> BOOL #foreign kernel32;

WriteFile :: (
	hFile : HANDLE,
	lpBuffer : *void,
	nNumberOfBytesToWrite : DWORD,
	lpNumberOfBytesWritten : *DWORD,
	lpOverlapped : *OVERLAPPED
) -> BOOL #foreign kernel32;

INVALID_FILE_ATTRIBUTES : DWORD : 0xffff_ffff;

MAX_PATH :: 260;

FILETIME :: struct
{
	dwLowDateTime  : DWORD;
	dwHighDateTime : DWORD;
}

WIN32_FIND_DATAW :: struct
{
	dwFileAttributes : DWORD;
	ftCreationTime   : FILETIME;
	ftLastAccessTime : FILETIME;
	ftLastWriteTime  : FILETIME;
	nFileSizeHigh : DWORD;
	nFileSizeLow  : DWORD;
	dwReserved0 : DWORD;
	dwReserved1 : DWORD;
	cFileName          : [MAX_PATH]u16;
	cAlternateFileName : [4]u16;
	dwFileType    : DWORD;
	dwCreatorType : DWORD;
	wFinderFlags  : WORD;
}

GetFullPathNameW :: (lpFileName : *u16, nBufferLength : DWORD, lpBuffer : *u16, lpFilePart : **u16) -> DWORD #foreign kernel32;
//PathCanonicalizeW :: (pszBuf : *u16, pszPath : *u16) -> BOOL #foreign shlwapi;
GetModuleHandleW :: (lpModuleName : *u16) -> HANDLE #foreign kernel32;
GetModuleFileNameW :: (hModule : HANDLE, lpFilename : *u16, nSize : DWORD) -> DWORD #foreign kernel32;
GetFileAttributesW :: (lpFileName : *u16) -> DWORD #foreign kernel32;
SetFileAttributesW :: (lpFileName : *u16, dwFileAttributes : DWORD) -> BOOL #foreign kernel32;
FindFirstFileW :: (lpFileName : *u16, lpFindFileData : *WIN32_FIND_DATAW) -> HANDLE #foreign kernel32;
FindNextFileW :: (hFindFile : HANDLE, lpFindFileData : *WIN32_FIND_DATAW) -> BOOL #foreign kernel32;
FindClose :: (hFindFile : HANDLE) -> BOOL #foreign kernel32;
CreateDirectoryW :: (lpPathName : *u16, lpSecurityAttributes : *SECURITY_ATTRIBUTES) -> BOOL #foreign kernel32;
RemoveDirectoryW :: (lpPathName : *u16) -> BOOL #foreign kernel32;
GetCurrentDirectoryW :: (nBufferLength : DWORD, lpBuffer : *u16) -> DWORD #foreign kernel32;
SetCurrentDirectoryW :: (lpPathName : *u16) -> BOOL #foreign kernel32;
LoadLibraryW :: (lpLibFileName : *u16) -> HANDLE #foreign kernel32;
FreeLibrary :: (hLibModule : HANDLE) -> BOOL #foreign kernel32;
GetProcAddress :: (hModule : HANDLE, lpProcName : *u8) -> *void #foreign kernel32;
Sleep :: (dwMilliseconds : DWORD) #foreign kernel32;
GetProcessHeap :: () -> HANDLE #foreign kernel32;
HeapAlloc :: (hHeap : HANDLE, dwFlags : DWORD, dwBytes : u64) -> *void #foreign kernel32;
HeapReAlloc :: (hHeap : HANDLE, dwFlags : DWORD, lpMem : *void, dwBytes : u64) -> *void #foreign kernel32;
HeapFree :: (hHeap : HANDLE, dwFlags : DWORD, lpMem : *void) -> s32 #foreign kernel32;
QueryPerformanceCounter :: (lpPerformanceCount : *s64) -> BOOL #foreign kernel32;
QueryPerformanceFrequency :: (lpFrequency : *s64) -> BOOL #foreign kernel32;

IDC_ARROW    :: 32512;
IDC_APPSTARTING :: 32650;
IDC_WAIT     :: 32514;
IDC_CROSS    :: 32515;
IDC_HAND     :: 32649;
IDC_IBEAM    :: 32513;
IDC_SIZEALL  :: 32646;
IDC_SIZENWSE :: 32642;
IDC_SIZENESW :: 32643;
IDC_SIZEWE   :: 32644;
IDC_SIZENS   :: 32645;

LoadCursorW :: (hInstance : HANDLE, lpCursorName : *u16) -> HANDLE #foreign user32;

WNDPROC :: #type (hwnd : HANDLE, uMsg : u32, wParam : WPARAM, lParam : LPARAM) -> LRESULT #c_call;
DefWindowProcW :: (hwnd : HANDLE, uMsg : u32, wParam : WPARAM, lParam : LPARAM) -> LRESULT #foreign user32;

WNDCLASSEXW :: struct
{
	cbSize : u32;
	style  : u32;
	lpfnWndProc : WNDPROC;
	cbClsExtra : s32;
	cbWndExtra : s32;
	hInstance : HANDLE;
	hIcon : HANDLE;
	hCursor : HANDLE;
	hbrBackground : HANDLE;
	lpszMenuName : *u16;
	lpszClassName : *u16;
	hIconSm : HANDLE;
}

CS_OWNDC   : u32 : 0x20;
CS_DBLCLKS : u32 : 0x08;

CW_USEDEFAULT : s32 : 0x80000000;

WS_OVERLAPPED  : DWORD : 0x00000000;
WS_CAPTION     : DWORD : 0x00c00000;
WS_SYSMENU     : DWORD : 0x00080000;
WS_THICKFRAME  : DWORD : 0x00040000;
WS_MINIMIZEBOX : DWORD : 0x00020000;
WS_MAXIMIZEBOX : DWORD : 0x00010000;
WS_OVERLAPPEDWINDOW : DWORD : WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;

PIXELFORMATDESCRIPTOR :: struct
{
	nSize           : WORD;
	nVersion        : WORD;
	dwFlags         : DWORD;
	iPixelType      : u8;
	cColorBits      : u8;
	cRedBits        : u8;
	cRedShift       : u8;
	cGreenBits      : u8;
	cGreenShift     : u8;
	cBlueBits       : u8;
	cBlueShift      : u8;
	cAlphaBits      : u8;
	cAlphaShift     : u8;
	cAccumBits      : u8;
	cAccumRedBits   : u8;
	cAccumGreenBits : u8;
	cAccumBlueBits  : u8;
	cAccumAlphaBits : u8;
	cDepthBits      : u8;
	cStencilBits    : u8;
	cAuxBuffers     : u8;
	iLayerType      : u8;
	bReserved       : u8;
	dwLayerMask     : DWORD;
	dwVisibleMask   : DWORD;
	dwDamageMask    : DWORD;
}

PFD_DOUBLEBUFFER            : DWORD : 0x00000001;
PFD_STEREO                  : DWORD : 0x00000002;
PFD_DRAW_TO_WINDOW          : DWORD : 0x00000004;
PFD_DRAW_TO_BITMAP          : DWORD : 0x00000008;
PFD_SUPPORT_GDI             : DWORD : 0x00000010;
PFD_SUPPORT_OPENGL          : DWORD : 0x00000020;
PFD_GENERIC_FORMAT          : DWORD : 0x00000040;
PFD_NEED_PALETTE            : DWORD : 0x00000080;
PFD_NEED_SYSTEM_PALETTE     : DWORD : 0x00000100;
PFD_SWAP_EXCHANGE           : DWORD : 0x00000200;
PFD_SWAP_COPY               : DWORD : 0x00000400;
PFD_SWAP_LAYER_BUFFERS      : DWORD : 0x00000800;
PFD_GENERIC_ACCELERATED     : DWORD : 0x00001000;
PFD_SUPPORT_DIRECTDRAW      : DWORD : 0x00002000;
PFD_DIRECT3D_ACCELERATED    : DWORD : 0x00004000;
PFD_SUPPORT_COMPOSITION     : DWORD : 0x00008000;

PFD_TYPE_RGBA        : u8 : 0;
PFD_TYPE_COLORINDEX  : u8 : 1;

PFD_MAIN_PLANE       : u8 : 0;
PFD_OVERLAY_PLANE    : u8 : 1;
PFD_UNDERLAY_PLANE   : u8 : 255;

MSG :: struct
{
	hwnd     : HANDLE;
	message  : u32;
	wParam   : WPARAM;
	lParam   : LPARAM;
	time     : DWORD;
	pt       : POINT;
	lPrivate : DWORD;
}

SW_SHOWDEFAULT : s32 : 10;

PM_REMOVE : u32 : 1;

HIWORD_W :: (wparam: WPARAM) -> s16 #expand { return cast, no_check (s16) ((cast, no_check (s32) (wparam) >> 16) & 0xffff); }
LOWORD_W :: (wparam: WPARAM) -> s16 #expand { return cast, no_check (s16) (wparam); }
HIWORD_L :: (lparam: LPARAM) -> s16 #expand { return cast, no_check (s16) ((cast, no_check (s32) (lparam) >> 16) & 0xffff); }
LOWORD_L :: (lparam: LPARAM) -> s16 #expand { return cast, no_check (s16) (lparam); }

RegisterClassExW :: (class : *WNDCLASSEXW) -> WORD #foreign user32;
CreateWindowExW :: (
	dwExStyle : DWORD,
	lpClassName : *u16,
	lpWindowName : *u16,
	dwStyle : DWORD,
	X : s32,
	Y : s32,
	nWidth : s32,
	nHeight : s32,
	hWndParent : HANDLE,
	hMenu : HANDLE,
	hInstance : HANDLE,
	lpParam : *void
) -> HANDLE #foreign user32;
DestroyWindow :: (hWnd : HANDLE) -> BOOL #foreign user32;
GetDC :: (hWnd : HANDLE) -> HANDLE #foreign user32;
ReleaseDC :: (hWnd : HANDLE, hDC : HANDLE) -> s32 #foreign user32;
SwapBuffers :: (hDC : HANDLE) -> BOOL #foreign gdi32;
SetCursor :: (hCursor : HANDLE) -> HANDLE #foreign user32;
ChoosePixelFormat :: (hdc : HANDLE, ppfd : *PIXELFORMATDESCRIPTOR) -> s32 #foreign gdi32;
SetPixelFormat :: (hdc : HANDLE, format : s32, ppfd : *PIXELFORMATDESCRIPTOR) -> BOOL #foreign gdi32;
ShowWindow :: (hWnd : HANDLE, nShowCmd : s32) -> BOOL #foreign user32;
PeekMessageW :: (lpMsg : *MSG, hWnd : HANDLE, wMsgFilterMin : u32, wMsgFilterMax : u32, wRemoveMsg : u32) -> BOOL #foreign user32;
TranslateMessage :: (lpMsg : *MSG) -> BOOL #foreign user32;
DispatchMessageW :: (lpMsg : *MSG) -> LRESULT #foreign user32;
GetWindowRect :: (hWnd : HANDLE, lpRect : *RECT) -> BOOL #foreign user32;
GetClientRect :: (hWnd : HANDLE, lpRect : *RECT) -> BOOL #foreign user32;
GetFocus :: () -> HANDLE #foreign user32;
SetFocus :: (hWnd : HANDLE) -> HANDLE #foreign user32;
MessageBoxW :: (hWnd : HANDLE, lpText : *u16, lpCaption : *u16, uType : u32) -> BOOL #foreign user32;
GetCursorPos :: (lpPoint : *POINT) -> BOOL #foreign user32;
ScreenToClient :: (hWnd : HANDLE, lpPoint : *POINT) -> BOOL #foreign user32;

POINTS :: struct
{
	x : s16;
	y : s16;
}

GESTURENOTIFYSTRUCT :: struct
{
	cbSize : u32;
	dwFlags : DWORD;
	hwndTarget : HANDLE;
	ptsLocation : POINTS;
	dwInstanceID : DWORD;
}

GESTURECONFIG :: struct
{
	dwID : DWORD;
	dwWant : DWORD;
	dwBlock : DWORD;
}

GESTUREINFO :: struct
{
	cbSize : u32;
	dwFlags : DWORD;
	dwID : DWORD;
	hwndTarget : HANDLE;
	ptsLocation : POINTS;
	dwInstanceID : DWORD;
	dwSequenceID : DWORD;
	ullArguments : u64;
	cbExtraArgs : u32;
}

SetGestureConfig :: (hwnd : HANDLE, dwReserved : DWORD, cIDs : u32, pGestureConfig : *GESTURECONFIG, cbSize : u32) -> BOOL #foreign user32;
GetGestureInfo :: (hGestureInfo : HANDLE, pGestureInfo : *GESTUREINFO) -> BOOL #foreign user32;

MB_OK        : u32 : 0x00;
MB_ICONERROR : u32 : 0x10;

WM_NULL    : u32 : 0x0000;
WM_CREATE  : u32 : 0x0001;
WM_DESTROY : u32 : 0x0002;
WM_MOVE    : u32 : 0x0003;

WM_SIZE                         : u32 : 0x0005;
WM_SETFOCUS                     : u32 : 0x0007;
WM_KILLFOCUS                    : u32 : 0x0008;
WM_ENABLE                       : u32 : 0x000A;
WM_SETREDRAW                    : u32 : 0x000B;
WM_SETTEXT                      : u32 : 0x000C;
WM_GETTEXT                      : u32 : 0x000D;
WM_GETTEXTLENGTH                : u32 : 0x000E;
WM_PAINT                        : u32 : 0x000F;
WM_CLOSE                        : u32 : 0x0010;
WM_QUERYENDSESSION              : u32 : 0x0011;
WM_QUERYOPEN                    : u32 : 0x0013;
WM_ENDSESSION                   : u32 : 0x0016;
WM_QUIT                         : u32 : 0x0012;
WM_ERASEBKGND                   : u32 : 0x0014;
WM_SYSCOLORCHANGE               : u32 : 0x0015;
WM_SHOWWINDOW                   : u32 : 0x0018;
WM_WININICHANGE                 : u32 : 0x001A;
WM_SETTINGCHANGE                : u32 : WM_WININICHANGE;
WM_DEVMODECHANGE                : u32 : 0x001B;
WM_ACTIVATEAPP                  : u32 : 0x001C;
WM_FONTCHANGE                   : u32 : 0x001D;
WM_TIMECHANGE                   : u32 : 0x001E;
WM_CANCELMODE                   : u32 : 0x001F;
WM_SETCURSOR                    : u32 : 0x0020;
WM_MOUSEACTIVATE                : u32 : 0x0021;
WM_CHILDACTIVATE                : u32 : 0x0022;
WM_QUEUESYNC                    : u32 : 0x0023;
WM_GETMINMAXINFO                : u32 : 0x0024;

WM_NOTIFY                       : u32 : 0x004E;
WM_INPUTLANGCHANGEREQUEST       : u32 : 0x0050;
WM_INPUTLANGCHANGE              : u32 : 0x0051;
WM_TCARD                        : u32 : 0x0052;
WM_HELP                         : u32 : 0x0053;
WM_USERCHANGED                  : u32 : 0x0054;
WM_NOTIFYFORMAT                 : u32 : 0x0055;
WM_CONTEXTMENU                  : u32 : 0x007B;
WM_STYLECHANGING                : u32 : 0x007C;
WM_STYLECHANGED                 : u32 : 0x007D;
WM_DISPLAYCHANGE                : u32 : 0x007E;
WM_GETICON                      : u32 : 0x007F;
WM_SETICON                      : u32 : 0x0080;
WM_NCCREATE                     : u32 : 0x0081;
WM_NCDESTROY                    : u32 : 0x0082;
WM_NCCALCSIZE                   : u32 : 0x0083;
WM_NCHITTEST                    : u32 : 0x0084;
WM_NCPAINT                      : u32 : 0x0085;
WM_NCACTIVATE                   : u32 : 0x0086;
WM_GETDLGCODE                   : u32 : 0x0087;
WM_SYNCPAINT                    : u32 : 0x0088;
WM_NCMOUSEMOVE                  : u32 : 0x00A0;
WM_NCLBUTTONDOWN                : u32 : 0x00A1;
WM_NCLBUTTONUP                  : u32 : 0x00A2;
WM_NCLBUTTONDBLCLK              : u32 : 0x00A3;
WM_NCRBUTTONDOWN                : u32 : 0x00A4;
WM_NCRBUTTONUP                  : u32 : 0x00A5;
WM_NCRBUTTONDBLCLK              : u32 : 0x00A6;
WM_NCMBUTTONDOWN                : u32 : 0x00A7;
WM_NCMBUTTONUP                  : u32 : 0x00A8;
WM_NCMBUTTONDBLCLK              : u32 : 0x00A9;
WM_NCXBUTTONDOWN                : u32 : 0x00AB;
WM_NCXBUTTONUP                  : u32 : 0x00AC;
WM_NCXBUTTONDBLCLK              : u32 : 0x00AD;
WM_INPUT_DEVICE_CHANGE          : u32 : 0x00FE;
WM_INPUT                        : u32 : 0x00FF;
WM_KEYFIRST                     : u32 : 0x0100;
WM_KEYDOWN                      : u32 : 0x0100;
WM_KEYUP                        : u32 : 0x0101;
WM_CHAR                         : u32 : 0x0102;
WM_DEADCHAR                     : u32 : 0x0103;
WM_SYSKEYDOWN                   : u32 : 0x0104;
WM_SYSKEYUP                     : u32 : 0x0105;
WM_SYSCHAR                      : u32 : 0x0106;
WM_SYSDEADCHAR                  : u32 : 0x0107;
WM_UNICHAR                      : u32 : 0x0109;
WM_KEYLAST                      : u32 : 0x0109;
UNICODE_NOCHAR                  : u32 : 0xFFFF;
WM_IME_STARTCOMPOSITION         : u32 : 0x010D;
WM_IME_ENDCOMPOSITION           : u32 : 0x010E;
WM_IME_COMPOSITION              : u32 : 0x010F;
WM_IME_KEYLAST                  : u32 : 0x010F;
WM_INITDIALOG                   : u32 : 0x0110;
WM_COMMAND                      : u32 : 0x0111;
WM_SYSCOMMAND                   : u32 : 0x0112;
WM_TIMER                        : u32 : 0x0113;
WM_HSCROLL                      : u32 : 0x0114;
WM_VSCROLL                      : u32 : 0x0115;
WM_INITMENU                     : u32 : 0x0116;
WM_INITMENUPOPUP                : u32 : 0x0117;
WM_GESTURE                      : u32 : 0x0119;
WM_GESTURENOTIFY                : u32 : 0x011A;
WM_MENUSELECT                   : u32 : 0x011F;
WM_MENUCHAR                     : u32 : 0x0120;
WM_ENTERIDLE                    : u32 : 0x0121;
WM_MENURBUTTONUP                : u32 : 0x0122;
WM_MENUDRAG                     : u32 : 0x0123;
WM_MENUGETOBJECT                : u32 : 0x0124;
WM_UNINITMENUPOPUP              : u32 : 0x0125;
WM_MENUCOMMAND                  : u32 : 0x0126;
WM_CHANGEUISTATE                : u32 : 0x0127;
WM_UPDATEUISTATE                : u32 : 0x0128;
WM_QUERYUISTATE                 : u32 : 0x0129;

WM_CTLCOLORMSGBOX               : u32 : 0x0132;
WM_CTLCOLOREDIT                 : u32 : 0x0133;
WM_CTLCOLORLISTBOX              : u32 : 0x0134;
WM_CTLCOLORBTN                  : u32 : 0x0135;
WM_CTLCOLORDLG                  : u32 : 0x0136;
WM_CTLCOLORSCROLLBAR            : u32 : 0x0137;
WM_CTLCOLORSTATIC               : u32 : 0x0138;
MN_GETHMENU                     : u32 : 0x01E1;
WM_MOUSEFIRST                   : u32 : 0x0200;
WM_MOUSEMOVE                    : u32 : 0x0200;
WM_LBUTTONDOWN                  : u32 : 0x0201;
WM_LBUTTONUP                    : u32 : 0x0202;
WM_LBUTTONDBLCLK                : u32 : 0x0203;
WM_RBUTTONDOWN                  : u32 : 0x0204;
WM_RBUTTONUP                    : u32 : 0x0205;
WM_RBUTTONDBLCLK                : u32 : 0x0206;
WM_MBUTTONDOWN                  : u32 : 0x0207;
WM_MBUTTONUP                    : u32 : 0x0208;
WM_MBUTTONDBLCLK                : u32 : 0x0209;
WM_MOUSEWHEEL                   : u32 : 0x020A;
WM_XBUTTONDOWN                  : u32 : 0x020B;
WM_XBUTTONUP                    : u32 : 0x020C;
WM_XBUTTONDBLCLK                : u32 : 0x020D;
WM_MOUSEHWHEEL                  : u32 : 0x020E;
WM_MOUSELAST                    : u32 : 0x020E;

WM_EXITSIZEMOVE                 : u32 : 0x0232;
WM_DPICHANGED                   : u32 : 0x02E0;

VK_LBUTTON        :: 0x01;
VK_RBUTTON        :: 0x02;
VK_CANCEL         :: 0x03;
VK_MBUTTON        :: 0x04    /* NOT contiguous with L & RBUTTON */;
VK_XBUTTON1       :: 0x05    /* NOT contiguous with L & RBUTTON */;
VK_XBUTTON2       :: 0x06    /* NOT contiguous with L & RBUTTON */;
VK_BACK           :: 0x08;
VK_TAB            :: 0x09;
VK_CLEAR          :: 0x0C;
VK_RETURN         :: 0x0D;
VK_SHIFT          :: 0x10;
VK_CONTROL        :: 0x11;
VK_MENU           :: 0x12;
VK_PAUSE          :: 0x13;
VK_CAPITAL        :: 0x14;
VK_KANA           :: 0x15;
VK_HANGUL         :: 0x15;
VK_JUNJA          :: 0x17;
VK_FINAL          :: 0x18;
VK_HANJA          :: 0x19;
VK_KANJI          :: 0x19;
VK_ESCAPE         :: 0x1B;
VK_CONVERT        :: 0x1C;
VK_NONCONVERT     :: 0x1D;
VK_ACCEPT         :: 0x1E;
VK_MODECHANGE     :: 0x1F;
VK_SPACE          :: 0x20;
VK_PRIOR          :: 0x21;
VK_NEXT           :: 0x22;
VK_END            :: 0x23;
VK_HOME           :: 0x24;
VK_LEFT           :: 0x25;
VK_UP             :: 0x26;
VK_RIGHT          :: 0x27;
VK_DOWN           :: 0x28;
VK_SELECT         :: 0x29;
VK_PRINT          :: 0x2A;
VK_EXECUTE        :: 0x2B;
VK_SNAPSHOT       :: 0x2C;
VK_INSERT         :: 0x2D;
VK_DELETE         :: 0x2E;
VK_HELP           :: 0x2F;

// VK_0 - VK_9 are the same as ASCII '0' - '9' (0x30 - 0x39);
// 0x40 unassigned;
// VK_A - VK_Z are the same as ASCII 'A' - 'Z' (0x41 - 0x5A);

VK_LWIN           :: 0x5B;
VK_RWIN           :: 0x5C;
VK_APPS           :: 0x5D;
VK_SLEEP          :: 0x5F;
VK_NUMPAD0        :: 0x60;
VK_NUMPAD1        :: 0x61;
VK_NUMPAD2        :: 0x62;
VK_NUMPAD3        :: 0x63;
VK_NUMPAD4        :: 0x64;
VK_NUMPAD5        :: 0x65;
VK_NUMPAD6        :: 0x66;
VK_NUMPAD7        :: 0x67;
VK_NUMPAD8        :: 0x68;
VK_NUMPAD9        :: 0x69;
VK_MULTIPLY       :: 0x6A;
VK_ADD            :: 0x6B;
VK_SEPARATOR      :: 0x6C;
VK_SUBTRACT       :: 0x6D;
VK_DECIMAL        :: 0x6E;
VK_DIVIDE         :: 0x6F;
VK_F1             :: 0x70;
VK_F2             :: 0x71;
VK_F3             :: 0x72;
VK_F4             :: 0x73;
VK_F5             :: 0x74;
VK_F6             :: 0x75;
VK_F7             :: 0x76;
VK_F8             :: 0x77;
VK_F9             :: 0x78;
VK_F10            :: 0x79;
VK_F11            :: 0x7A;
VK_F12            :: 0x7B;
VK_F13            :: 0x7C;
VK_F14            :: 0x7D;
VK_F15            :: 0x7E;
VK_F16            :: 0x7F;
VK_F17            :: 0x80;
VK_F18            :: 0x81;
VK_F19            :: 0x82;
VK_F20            :: 0x83;
VK_F21            :: 0x84;
VK_F22            :: 0x85;
VK_F23            :: 0x86;
VK_F24            :: 0x87;
VK_NUMLOCK        :: 0x90;
VK_SCROLL         :: 0x91;
VK_OEM_NEC_EQUAL  :: 0x92;   // '=' key on numpad;
VK_OEM_FJ_JISHO   :: 0x92;   // 'Dictionary' key;
VK_OEM_FJ_MASSHOU :: 0x93;   // 'Unregister word' key;
VK_OEM_FJ_TOUROKU :: 0x94;   // 'Register word' key;
VK_OEM_FJ_LOYA    :: 0x95;   // 'Left OYAYUBI' key;
VK_OEM_FJ_ROYA    :: 0x96;   // 'Right OYAYUBI' key;
VK_LSHIFT         :: 0xA0;
VK_RSHIFT         :: 0xA1;
VK_LCONTROL       :: 0xA2;
VK_RCONTROL       :: 0xA3;
VK_LMENU          :: 0xA4;
VK_RMENU          :: 0xA5;
VK_BROWSER_BACK        :: 0xA6;
VK_BROWSER_FORWARD     :: 0xA7;
VK_BROWSER_REFRESH     :: 0xA8;
VK_BROWSER_STOP        :: 0xA9;
VK_BROWSER_SEARCH      :: 0xAA;
VK_BROWSER_FAVORITES   :: 0xAB;
VK_BROWSER_HOME        :: 0xAC;
VK_VOLUME_MUTE         :: 0xAD;
VK_VOLUME_DOWN         :: 0xAE;
VK_VOLUME_UP           :: 0xAF;
VK_MEDIA_NEXT_TRACK    :: 0xB0;
VK_MEDIA_PREV_TRACK    :: 0xB1;
VK_MEDIA_STOP          :: 0xB2;
VK_MEDIA_PLAY_PAUSE    :: 0xB3;
VK_LAUNCH_MAIL         :: 0xB4;
VK_LAUNCH_MEDIA_SELECT :: 0xB5;
VK_LAUNCH_APP1         :: 0xB6;
VK_LAUNCH_APP2         :: 0xB7;
VK_OEM_1          :: 0xBA;   // ';:' for US;
VK_OEM_PLUS       :: 0xBB;   // '+' any country;
VK_OEM_COMMA      :: 0xBC;   // ',' any country;
VK_OEM_MINUS      :: 0xBD;   // '-' any country;
VK_OEM_PERIOD     :: 0xBE;   // '.' any country;
VK_OEM_2          :: 0xBF;   // '/?' for US;
VK_OEM_3          :: 0xC0;   // '`~' for US;
VK_OEM_4          :: 0xDB;  //  '[{' for US;
VK_OEM_5          :: 0xDC;  //  '\|' for US;
VK_OEM_6          :: 0xDD;  //  ']}' for US;
VK_OEM_7          :: 0xDE;  //  ''"' for US;
VK_OEM_8          :: 0xDF;
VK_OEM_AX         :: 0xE1;  //  'AX' key on Japanese AX kbd;
VK_OEM_102        :: 0xE2;  //  "<>" or "\|" on RT 102-key kbd.;
VK_ICO_HELP       :: 0xE3;  //  Help key on ICO;
VK_ICO_00         :: 0xE4;  //  00 key on ICO;
VK_PROCESSKEY     :: 0xE5;
VK_ICO_CLEAR      :: 0xE6;
VK_PACKET         :: 0xE7;

GetAsyncKeyState :: (vKey : s32) -> s16 #foreign user32;

GetLastError :: () -> DWORD #foreign kernel32;

ERROR_SUCCESS : DWORD : 0x00;
ERROR_INVALID_FUNCTION : DWORD : 0x01;
ERROR_FILE_NOT_FOUND : DWORD : 0x02;
ERROR_PATH_NOT_FOUND : DWORD : 0x03;

kernel32 :: #foreign_system_library "Kernel32";
gdi32    :: #foreign_system_library "Gdi32";
user32   :: #foreign_system_library "User32";
opengl32 :: #foreign_system_library "Opengl32";
