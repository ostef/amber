f32 :: float32;
f64 :: float64;

Buffer_ID      :: #type, distinct u32; @Amber_API
Text_Layout_ID :: #type, distinct u32; @Amber_API
Split_ID       :: #type, distinct u32; @Amber_API

NULL_BUFFER      : Buffer_ID      : 0; @Amber_API
NULL_TEXT_LAYOUT : Text_Layout_ID : 0; @Amber_API
NULL_SPLIT       : Split_ID       : 0; @Amber_API

EOL_Sequence :: enum u8
{
	LF   :: 0;
	CRLF :: 1;
#if OS == .WINDOWS
	PLATFORM :: CRLF;
else
	PLATFORM :: LF;
}
@Amber_API

Buffer_Cursor :: struct
{
	offset    : s64;
	selection : s64;
}
@Amber_API

Buffer_Cursor_ID :: #type, distinct s64; @Amber_API

ALL_CURSORS : Buffer_Cursor_ID : -1; @Amber_API
WRITE_HEAD  : Buffer_Cursor_ID : 0;  @Amber_API

// @Note (stefan): I would like to put this inside the Buffer_Edit struct,
// but I need to be able to print the full type when generating hooks,
// and for now I don't know how to get the namespace of a type.
Buffer_Edit_Kind :: enum
{
	INSERT :: 0;
	BACKSPACE :: 1;
	DELETE    :: 2;
	MOVE_LINE_UP   :: 3;
	MOVE_LINE_DOWN :: 4;

	BATCH_BEGIN :: 100;
	BATCH_END   :: 101;
}
@Amber_API

Buffer_Edit :: struct
{
	kind : Buffer_Edit_Kind;
	line_index : s64;
	cursor_id : Buffer_Cursor_ID;
	cursor : Buffer_Cursor;
	offset_in_edit_buffer : s64;
}
@Amber_API

History_Buffering :: enum
{
	DONT_PUSH :: 0;
	PUSH_TEXT :: 1;
	PUSH_EDIT :: 2;
}
@Amber_API

// Command

Command_Proc :: #type (*Amber_Hooks, []string) -> bool;

Command_Info :: struct
{
	name : string;
	proc : Command_Proc;
	arg_count : s64;
	first_optional_argument : s64;
}

Key_Binding :: struct
{
	mods : Mods;
	key_code : Key_Code;
}

Key_Combination :: []Key_Binding;

// Language

Language :: struct
{
	Process_Buffer_Proc :: #type (*Amber_Hooks, Buffer_ID);
	
	id : Language_ID;
	extension_id : Extension_ID;
	name : string;
	default_associated_filenames  : []string;
	default_associated_file_extensions : []string;
	process_buffer : Process_Buffer_Proc;
}

Language_ID :: #type, distinct u32;
PLAIN_TEXT : Language_ID : 0;

// Extension

Extension_ID :: #type, distinct u32;

MAIN_PROGRAM : Extension_ID : 0;

Extension_Callbacks :: struct
{
	on_event  : (*Amber_Hooks, Event) -> Event_Result, bool;
	on_update : (*Amber_Hooks);
}

// Font

Font_ID :: #type, distinct u32;

NULL_FONT : Font_ID : 0;

Glyph_Info :: struct
{
	codepoint : u32;
	advance : f32;
	bearing : Vec2f;
	size    : Vec2f;
	bitmap_bearing : Vec2f;
	bitmap_size    : Vec2f;
}

Font_Weight :: enum
{
	THIN    :: 1;
	EXTRA_LIGHT :: 2;
	LIGHT   :: 3;
	REGULAR :: 0;
	MEDIUM  :: 4;
	BOLD    :: 5;
	EXTRA_BOLD :: 6;
}

Font_Style :: enum_flags u8
{
	NORMAL     :: 0x0;
	ITALIC     :: 0x1;
	UNDERLINED :: 0x2;
}

Font_Info :: struct
{
	id : Font_ID;
	filename : string;
	family_name : string;
	weight  : Font_Weight;
	style   : Font_Style;
	point_size : f32;
	ascent  : f32;
	descent : f32;
	advance : f32;
}

// Input

Event_Result :: struct
{
	buffer_modified  : bool;
	scroll_to_cursor : bool;
	show_scrollbar   : bool;
}

operator || :: inline (left : Event_Result, right : Event_Result) -> Event_Result #must
{
	result : Event_Result = ---;
	result.buffer_modified  = left.buffer_modified  || right.buffer_modified;
	result.scroll_to_cursor = left.scroll_to_cursor || right.scroll_to_cursor;
	result.show_scrollbar   = left.show_scrollbar   || right.show_scrollbar;
	
	return result;
}

Event :: struct
{
	Kind :: enum
	{
		UNKNOWN       :: 0;
		KEY_PRESS     :: 1;
		KEY_REPEAT    :: 2;
		KEY_RELEASE   :: 3;
		MOUSE_MOVE    :: 4;
		MOUSE_PRESS   :: 5;
		MOUSE_REPEAT  :: 6;
		MOUSE_RELEASE :: 7;
		MOUSE_WHEEL   :: 8;
		TEXT_INPUT    :: 9;

		WINDOW_CLOSE  :: 100;
		WINDOW_MOVE   :: 101;
		WINDOW_RESIZE :: 102;
	}
	
	kind : Kind;
	union
	{
		using input_event : struct
		{
			mods : Mods;
			key_code : Key_Code;
			mouse_position : Vec2f;
			mouse_button   : Mouse_Button;
			mouse_wheel    : Vec2f;
			codepoint : u32;
		};
		using window_event : struct
		{
			window_position : Vec2i;
			viewport_size   : Vec2i;
		};
	};
}

Mouse_Button :: enum
{
	LEFT   :: 0;
	MIDDLE :: 1;
	RIGHT  :: 2;
	COUNT;
}

Mods :: enum_flags
{
	NONE    :: 0x00;
	SHIFT   :: 0x01;
	CONTROL :: 0x02;
	ALT     :: 0x04;
}

Key_Code :: enum
{
	UNKNOWN             :: 0x00;
	BACKSPACE           :: 0x08;
	TAB                 :: 0x09;
	CLEAR               :: 0x0c;
	RETURN              :: 0x0d;
	SHIFT               :: 0x10;
	CONTROL             :: 0x11;
	ALT                 :: 0x12;
	PAUSE               :: 0x13;
	CAPS_LOCK           :: 0x14;
	KANA                :: 0x15;
	HANGUL              :: 0x15;
	IME_ON              :: 0x16;
	JUNJA               :: 0x17;
	FINAL               :: 0x18;
	HANJA               :: 0x19;
	KANJI               :: 0x19;
	IME_OFF             :: 0x1a;
	ESCAPE              :: 0x1b;
	CONVERT             :: 0x1c;
	NONCONVERT          :: 0x1d;
	ACCEPT              :: 0x1e;
	MODE_CHANGE         :: 0x1f;
	SPACE               :: 0x20;
	PAGE_UP             :: 0x21;
	PAGE_DOWN           :: 0x22;
	END                 :: 0x23;
	HOME                :: 0x24;
	LEFT                :: 0x25;
	UP                  :: 0x26;
	RIGHT               :: 0x27;
	DOWN                :: 0x28;
	SELECT              :: 0x29;
	PRINT               :: 0x2a;
	EXECUTE             :: 0x2b;
	PRINT_SCREEN        :: 0x2c;
	INSERT              :: 0x2d;
	DELETE              :: 0x2e;
	HELP                :: 0x2f;
	ZERO                :: 0x30;
	ONE                 :: 0x31;
	TWO                 :: 0x32;
	THREE               :: 0x33;
	FOUR                :: 0x34;
	FIVE                :: 0x35;
	SIX                 :: 0x36;
	SEVEN               :: 0x37;
	EIGHT               :: 0x38;
	NINE                :: 0x39;
	A                   :: 0x41;
	B                   :: 0x42;
	C                   :: 0x43;
	D                   :: 0x44;
	E                   :: 0x45;
	F                   :: 0x46;
	G                   :: 0x47;
	H                   :: 0x48;
	I                   :: 0x49;
	J                   :: 0x4a;
	K                   :: 0x4b;
	L                   :: 0x4c;
	M                   :: 0x4d;
	N                   :: 0x4e;
	O                   :: 0x4f;
	P                   :: 0x50;
	Q                   :: 0x51;
	R                   :: 0x52;
	S                   :: 0x53;
	T                   :: 0x54;
	U                   :: 0x55;
	V                   :: 0x56;
	W                   :: 0x57;
	X                   :: 0x58;
	Y                   :: 0x59;
	Z                   :: 0x5a;
	LEFT_SUPER          :: 0x5b;
	RIGHT_SUPER         :: 0x5c;
	APPLICATION         :: 0x5d;
	SLEEP               :: 0x5f;
	NUMPAD_0            :: 0x60;
	NUMPAD_1            :: 0x61;
	NUMPAD_2            :: 0x62;
	NUMPAD_3            :: 0x63;
	NUMPAD_4            :: 0x64;
	NUMPAD_5            :: 0x65;
	NUMPAD_6            :: 0x66;
	NUMPAD_7            :: 0x67;
	NUMPAD_8            :: 0x68;
	NUMPAD_9            :: 0x69;
	NUMPAD_STAR         :: 0x6a;
	NUMPAD_PLUS         :: 0x6b;
	NUMPAD_SEPARATOR    :: 0x6c;
	NUMPAD_MINUS        :: 0x6d;
	NUMPAD_PERIOD       :: 0x6e;
	NUMPAD_SLASH        :: 0x6f;
	F1                  :: 0x70;
	F2                  :: 0x71;
	F3                  :: 0x72;
	F4                  :: 0x73;
	F5                  :: 0x74;
	F6                  :: 0x75;
	F7                  :: 0x76;
	F8                  :: 0x77;
	F9                  :: 0x78;
	F10                 :: 0x79;
	F11                 :: 0x7a;
	F12                 :: 0x7b;
	F13                 :: 0x7c;
	F14                 :: 0x7d;
	F15                 :: 0x7e;
	F16                 :: 0x7f;
	F17                 :: 0x80;
	F18                 :: 0x81;
	F19                 :: 0x82;
	F20                 :: 0x83;
	F21                 :: 0x84;
	F22                 :: 0x85;
	F23                 :: 0x86;
	F24                 :: 0x87;
	NUM_LOCK            :: 0x90;
	SCROLL_LOCK         :: 0x91;
	LEFT_SHIFT          :: 0xa0;
	RIGHT_SHIFT         :: 0xa1;
	LEFT_CONTROL        :: 0xa2;
	RIGHT_CONTROL       :: 0xa3;
	LEFT_ALT            :: 0xa4;
	RIGHT_ALT           :: 0xa5;
	BROWSER_BACK        :: 0xa6;
	BROWSER_FORWARD     :: 0xa7;
	BROWSER_REFRESH     :: 0xa8;
	BROWSER_STOP        :: 0xa9;
	BROWSER_SEARCH      :: 0xaa;
	BROWSER_FAVORITES   :: 0xab;
	BROWSER_HOME        :: 0xac;
	VOLUME_MUTE         :: 0xad;
	VOLUME_DOWN         :: 0xae;
	VOLUME_UP           :: 0xaf;
	MEDIA_NEXT          :: 0xb0;
	MEDIA_PREVIOUS      :: 0xb1;
	MEDIA_STOP          :: 0xb2;
	MEDIA_PLAy_PAUSE    :: 0xb3;
	LAUNCH_MAIL         :: 0xb4;
	LAUNCH_MEDIA_SELECT :: 0xb5;
	LAUNCH_APP1         :: 0xb6;
	LAUNCH_APP2         :: 0xb7;
	OEM_1               :: 0xba;
	US_COLON     :: OEM_1;
	US_SEMICOLON :: OEM_1;
	OEM_PLUS            :: 0xbb;
	OEM_COMMA           :: 0xbc;
	OEM_MINUS           :: 0xbd;
	OEM_PERIOD          :: 0xbe;
	OEM_2               :: 0xbf;
	US_SLASH              :: OEM_2;
	US_INTERROGATION_MARK :: OEM_2;
	OEM_3               :: 0xc0;
	US_BACKTICK :: OEM_3;
	US_TILDE    :: OEM_3;
	OEM_4               :: 0xdb;
	US_OPENING_SQUARE_BRACKET :: OEM_4;
	US_OPENING_CURLY_BRACKET  :: OEM_4;
	OEM_5               :: 0xdc;
	US_BACKSLASH    :: OEM_5;
	US_VERTICAL_BAR :: OEM_5;
	OEM_6               :: 0xdd;
	US_CLOSING_SQUARE_BRACKET :: OEM_6;
	US_CLOSING_CURLY_BRACKET  :: OEM_6;
	OEM_7               :: 0xde;
	US_SINGLE_QUOTE :: OEM_7;
	US_DOUBLE_QUOTE :: OEM_7;
	OEM_8               :: 0xdf;
	OEM_102             :: 0xe2;
	PROCESS_KEY         :: 0xe5;
	ATTN                :: 0xf6;
	CRSEL               :: 0xf7;
	EXSEL               :: 0xf8;
	ERASE_EOF           :: 0xf9;
	PLAY                :: 0xfa;
	ZOOM                :: 0xfb;
	PA1                 :: 0xfd;
	OEM_CLEAR           :: 0xfe;
	COUNT;
}

Cursor_Type :: enum
{
	ARROW  :: 0;
	ARROW_BUSY :: 1;
	BUSY   :: 2;
	CROSS  :: 3;
	HAND   :: 4;
	IBEAM  :: 5;
	RESIZE :: 6;
	RESIZE_TOP_LEFT  :: 7;
	RESIZE_TOP_RIGHT :: 8;
	RESIZE_BOTTOM_RIGHT :: RESIZE_TOP_LEFT;
	RESIZE_BOTOTM_LEFT  :: RESIZE_TOP_RIGHT;
	RESIZE_HORIZONTAL :: 9;
	RESIZE_VERTICAL   :: 10;
}

Key_State :: enum u8
{
	UP       :: 0;
	PRESSED  :: 1;
	DOWN     :: 2;
	RELEASED :: 3;
}

Button_State :: Key_State;

// File

File_Handle :: *void;

File_Cursor :: enum
{
	BEGIN   :: 0;
	END     :: 1;
	CURRENT :: 2;
}

File_Open_Flags :: enum_flags
{
	OPEN_IF_EXISTS :: 0x01;
	OPEN_OR_CREATE :: 0x02;
	ALWAYS_CREATE  :: 0x03;
	
	ACCESS_READ  :: 0x10;
	ACCESS_WRITE :: 0x20;
}

File_Attributes :: enum_flags
{
	NORMAL    :: 0x00;
	DIRECTORY :: 0x01;
	HIDDEN    :: 0x02;
	READ_ONLY :: 0x04;
	SYMLINK   :: 0x08;
	TEMPORARY :: 0x10;
}

File_Change_Kind :: enum
{
	UNKNOWN  :: 0;
	ADDED    :: 1;
	MODIFIED :: 2;
	RENAMED  :: 3;
}

File_Change :: struct
{
	kind : File_Change_Kind;
	dirname  : string;
	basename : string;
	last_change_time : f64;
}

File_Info :: struct
{
	name : string;
	full_name : string;
	attributes : File_Attributes;
	size : s64;
	//creation_time
	//last_access_time
	//last_write_time
	has_errors : bool;
	
	// @Note (stefan): The *~s64 are relative pointers. This means
	// that the value of parent is relative to the address of parent in
	// memory. Because File_Infos are stored contiguously in an array
	// we can refer to other elements in the array from within elements
	// in the array using relative pointers, because the offset between
	// elements is always constant, and so pointers won't get invalidated
	// by the allocated memory being moved.
	parent : *~s64 File_Info;
	first_child  : *~s64 File_Info;
	prev_sibling : *~s64 File_Info;
	next_sibling : *~s64 File_Info;
}

for_expansion :: (info : *File_Info, body : Code, flags : For_Flags) #expand
{
	`it := info;
	`it_index := 0;
	while it
	{
		#insert body;
		if flagged (it.attributes, .DIRECTORY)
			it = it.first_child;
		else if it.next_sibling
			it = it.next_sibling;
		else
			it = it.parent;
		it_index += 1;
	}
}

children :: (info : *File_Info, body : Code, flags : For_Flags) #expand
{
	`it := info.first_child;
	`it_index := 0;
	while it
	{
		#insert body;
		it = it.next_sibling;
		it_index += 1;
	}
}

// Library

Library_Handle :: *void;

// Math

Vec2 :: struct (T : Type)
{
	x, y : T;
	#place x;
	w, h : T;
	#place x;
	width, height : T;
	#place x;
	n : [2]T;
}

Vec2f :: Vec2 (f32);
Vec2i :: Vec2 (s32);

Rect :: struct (T : Type)
{
	V :: Vec2 (T);

	x1, y1, x2, y2 : T;
	#place x1;
	left, top, right, bottom : T;
	#place x1;
	l, t, r, b : T;
	#place x1;
	min, max : V;
	#place x1;
	n : [4]T;
}

Rectf :: Rect (f32);
Recti :: Rect (s32);

Color :: RGBA;
RGBA :: struct
{
	r, g, b, a : u8;
	#place r;
	value : u32;
	#place r;
	n : [4]u8;
}

RGBA_TRANSPARENT :: RGBA.{ 0, 0, 0, 0 };
RGBA_WHITE :: RGBA.{ 255, 255, 255, 255 };
RGBA_BLACK :: RGBA.{ 0, 0, 0, 255 };

Colorf :: RGBAf;
RGBAf :: struct
{
	r, g, b, a : f32;
	#place r;
	n : [4]f32;
}

RGBAF_TRANSPARENT :: RGBAf.{ 0, 0, 0, 0 };
RGBAF_WHITE :: RGBAf.{ 1, 1, 1, 1 };
RGBAF_BLACK :: RGBAf.{ 0, 0, 0, 1 };

Range :: struct (T : Type)
{
	min, max : T;
	#place min;
	low, high : T;
	#place min;
	first, second : T;
	#place min;
	a, b : T;
	#place min;
	x, y : T;
	#place min;
	n : [2]T;
}

Rangei :: Range (s64);
Rangeu :: Range (u64);
Rangef :: Range (f32);

for_expansion :: (range : *Range, body : Code, flags : For_Flags) #expand
{
	`it := range.min;
	`it_index := 0;
	while it <= range.max
	{
		defer { it += 1; it_index += 1; }
		#insert body;
	}
}

// Graphics

Texture_Handle     :: u32;
Framebuffer_Handle :: u32;
Shader_Handle      :: u32;

Vertex :: struct
{
	position   : Vec2f;
	tex_coords : Vec2f;
	color      : RGBA;
}

Rectangle_Corners :: enum_flags
{
	NONE         :: 0x00;
	TOP_LEFT     :: 0x01;
	TOP_RIGHT    :: 0x02;
	BOTTOM_RIGHT :: 0x04;
	BOTTOM_LEFT  :: 0x08;
	ALL :: TOP_LEFT | TOP_RIGHT | BOTTOM_RIGHT | BOTTOM_LEFT;
}
