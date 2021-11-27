// @Todo (stefan): Handle UTF-16 endianness.

UNICODE_INVALID : u32 : 0xfffd;
UNICODE_BOM     : u32 : 0xfeff;
// @Note (stefan): End of input does not exist as a unicode codepoint.
// It is just symbolic, so we give it a value outside the range of
// possible unicode codepoints
UNICODE_EOI : u32 : 0xffff_ffff;
UNICODE_MAX : u32 : 0x0010_ffff;

utf8_decode :: (buffer : []u8) -> codepoint : u32, size : s64
{
	// @Note (stefan): from https://github.com/gingerBill/gb/blob/master/gb.h
	UTF8_FIRST :: u8.[
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x00-0x0F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x10-0x1F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x20-0x2F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x30-0x3F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x40-0x4F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x50-0x5F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x60-0x6F
		0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x70-0x7F
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x80-0x8F
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x90-0x9F
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xA0-0xAF
		0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xB0-0xBF
		0xf1, 0xf1, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xC0-0xCF
		0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xD0-0xDF
		0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x23, 0x03, 0x03, // 0xE0-0xEF
		0x34, 0x04, 0x04, 0x04, 0x44, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xF0-0xFF
	];

	Utf8_Accept_Range :: struct
	{
		lo, hi : u8;
	}

	UTF8_ACCEPT_RANGES :: Utf8_Accept_Range.[
		Utf8_Accept_Range.{ 0x80, 0xbf },
		Utf8_Accept_Range.{ 0xa0, 0xbf },
		Utf8_Accept_Range.{ 0x80, 0x9f },
		Utf8_Accept_Range.{ 0x90, 0xbf },
		Utf8_Accept_Range.{ 0x80, 0x8f },
	];

	if buffer.count > 0
	{
		b0 := buffer[0];
		x  := UTF8_FIRST[b0];
		
		if x >= 0xf0
		{
			mask := (cast (u32) x << 31) >> 31;
			
			return (cast (u32) b0 & (~mask)) | (UNICODE_INVALID & mask), 1;
		}
		else if b0 < 0x80
		{
			return b0, 1;
		}

		sz := x & 7;
		b1 := buffer[1];
		range := UTF8_ACCEPT_RANGES[x >> 4];
		if b1 < range.lo || b1 > range.hi then return UNICODE_INVALID, 1;

		if sz == 2
			return ((cast (u32) b0 & 0x1f) << 6) | (cast (u32) b1 & 0x3f), 2;

		b2 := buffer[2];
		if b2 < 0x80 || b2 > 0xbf then return UNICODE_INVALID, 1;

		if sz == 3
			return ((cast (u32) b0 & 0x1f) << 12) | ((cast (u32) b1 & 0x3f) << 6) | (cast (u32) b2 & 0x3f), 3;

		b3 := buffer[3];
		if b3 < 0x80 ||b3 > 0xbf then return UNICODE_INVALID, 1;

		return ((cast (u32) b0 & 0x07) << 18) | ((cast (u32) b1 & 0x3f) << 12) | ((cast (u32) b2 & 0x3f) << 6) | ((cast (u32) b3 & 0x3f)), 4;
	}

	return UNICODE_INVALID, 1;
}

utf8_encode :: (buffer : []u8, codepoint : u32) -> size : s64
{
	i := codepoint;
	MASK : u8 : 0x3f;

	if i <= (1 << 7) - 1
	{
		buffer[0] = cast (u8) codepoint;

		return 1;
	}
	else if i <= (1 << 11) - 1
	{
		buffer[0] = 0xc0 |  cast (u8) (codepoint >> 6);
		buffer[1] = 0x80 | (cast (u8) (codepoint) & MASK);

		return 2;
	}
	else if i > UNICODE_MAX || (i >= 0xd800 && i <= 0xdfff)
	{
		codepoint = UNICODE_INVALID;
		buffer[0] = 0xe0 |  cast (u8) (codepoint >> 12);
		buffer[1] = 0x80 | (cast (u8) (codepoint >> 6) & MASK);
		buffer[2] = 0x80 | (cast (u8) (codepoint) & MASK);
	
		return 3;
	}
	else if i <= (1 << 16) - 1
	{
		buffer[0] = 0xe0 |  cast (u8) (codepoint >> 12);
		buffer[1] = 0x80 | (cast (u8) (codepoint >> 6) & MASK);
		buffer[2] = 0x80 | (cast (u8) (codepoint) & MASK);

		return 3;
	}
	else
	{
		buffer[0] = 0xf0 |  cast (u8) (codepoint >> 18);
		buffer[1] = 0x80 | (cast (u8) (codepoint >> 12) & MASK);
		buffer[2] = 0x80 | (cast (u8) (codepoint >> 6) & MASK);
		buffer[3] = 0x80 | (cast (u8) (codepoint) & MASK);
	
		return 4;
	}
}

utf8_codepoint_at_byte :: inline (utf8_str : string, byte_offset : s64) -> codepoint : u32, size : s64
{
	buffer : []u8 = ---;
	buffer.data  = utf8_str.data  + byte_offset;
	buffer.count = utf8_str.count - byte_offset;
	codepoint, size := utf8_decode (buffer);
	
	return codepoint, size;
}

utf8_codepoint_size :: (codepoint : u32) -> size : s64 #must
{
	if codepoint <= 0x7f
		return 1;
	else if codepoint <= 0x7ff
		return 2;
	else if codepoint <= 0xffff
		return 3;
	else if codepoint <= 0x1fffff
		return 4;
	
	return 0;
}

utf8_to_utf16  :: (utf8_str : string, allocator : Allocator, null_terminate := false) -> []u16 #must
{
	utf16_str : []u16;
	for utf8 (utf8_str)
		utf16_str.count += utf16_codepoint_size (it);
	utf16_str.data = alloc (size_of (u16) * (utf16_str.count + xx null_terminate), allocator);
	byte_offset := 0;
	for utf8 (utf8_str)
		byte_offset += utf16_encode (advance (utf16_str, byte_offset), it);
	if null_terminate then utf16_str.data[utf16_str.count] = 0;
	
	return utf16_str;
}

utf8_to_utf32  :: (utf8_str : string, allocator : Allocator, null_terminate := false) -> []u32 #must
{
	len := utf8_string_length (utf8_str);
	result : []u32 = ---;
	result.data  = alloc (size_of (u32) * (len + xx null_terminate), allocator);
	result.count = len;
	for utf8 (utf8_str)
		result[it_index] = it;
	if null_terminate then result.data[result.count] = 0;
	
	return result;
}

utf16_decode :: (buffer : []u16) -> codepoint : u32, size : s64
{
	if buffer.count > 0
	{
		b0 := buffer[0];
		if b0 >= 0xd800 && b0 <= 0xdbff
		{
			b0 -= 0xd800;
			b0 *= 0x400;
			b1 := buffer[1];
			b1 -= 0xdc00;
			codepoint := cast (u32) (b0 + b1 + 0x10000);
			
			return codepoint, 2;
		}
		else if b0 <= 0xd7ff || (b0 >= 0xe000 && b0 <= 0xffff)
		{
			codepoint := cast (u32) b0;
			
			return codepoint, 1;
		}
		else
		{
			return UNICODE_INVALID, 1;
		}
	}
	
	return UNICODE_INVALID, 1;
}

utf16_encode :: (buffer : []u16, codepoint : u32) -> size : s64
{
	if codepoint <= 0xd7ff || (codepoint >= 0xe000 && codepoint <= 0xffff)
	{
		buffer[0] = cast (u16) codepoint;
		
		return 1;
	}
	else if codepoint > UNICODE_MAX || (codepoint >= 0xd800 && codepoint <= 0xdfff)
	{
		buffer[0] = cast (u16) UNICODE_INVALID;
		
		return 1;
	}
	else
	{
		codepoint -= 0x10000;
		high_surrogate := cast (u16) (0xd800 + (codepoint >> 10));
		low_surrogate  := cast (u16) (0xdc00 + (codepoint & 0x03ff));
		buffer[0] = high_surrogate;
		buffer[1] = low_surrogate;
		
		return 2;
	}
}

utf16_codepoint_at_byte :: inline (utf16_str : []u16, byte_offset : s64) -> codepoint : u32, size : s64
{
	buffer : []u16 = ---;
	buffer.data  = utf16_str.data  + byte_offset;
	buffer.count = utf16_str.count - byte_offset;
	codepoint, size := utf16_decode (buffer);
	
	return codepoint, size;
}

utf16_codepoint_size :: (codepoint : u32) -> size : s64
{
	if codepoint <= 0xd7ff || (codepoint >= 0xe000 && codepoint <= 0xffff)
		return 1;
	else if codepoint > UNICODE_MAX || (codepoint >= 0xd800 && codepoint <= 0xdfff)
		return 1;
	else
		return 2;
}

utf16_to_utf8  :: (utf16_str : []u16, allocator : Allocator, null_terminate := false) -> string #must
{
	utf8_str : string;
	for utf16 (utf16_str)
		utf8_str.count += utf8_codepoint_size (it);
	utf8_str.data = alloc (utf8_str.count + xx null_terminate, allocator);
	byte_offset := 0;
	for utf16 (utf16_str)
		byte_offset += utf8_encode (advance (to_array (utf8_str), byte_offset), it);
	if null_terminate then utf8_str.data[utf8_str.count] = 0;
	
	return utf8_str;
}

utf16_to_utf32 :: (utf16_str : []u16, allocator : Allocator, null_terminate := false) -> []u32 #must
{
	len := utf16_string_length (utf16_str);
	result : []u32 = ---;
	result.data  = alloc (size_of (u32) * (len + xx null_terminate), allocator);
	result.count = len;
	for utf16 (utf16_str)
		result[it_index] = it;
	if null_terminate then result.data[result.count] = 0;
	
	return result;
}

utf32_to_utf8  :: (utf32_str : []u32, allocator : Allocator, null_terminate := false) -> string #must
{
	utf8_str : string;
	for utf32_str
		utf8_str.count += utf8_codepoint_size (it);
	utf8_str.data = alloc (utf8_str.count + xx null_terminate, allocator);
	byte_offset := 0;
	for utf32_str
		byte_offset += utf8_encode (advance (to_array (utf8_str), byte_offset), it);
	if null_terminate then utf8_str.data[utf8_str.count] = 0;
	
	return utf8_str;
}

utf32_to_utf16 :: (utf32_str : []u32, allocator : Allocator, null_terminate := false) -> []u16 #must
{
	utf16_str : []u16;
	for utf32_str
		utf16_str.count += utf16_codepoint_size (it);
	utf16_str.data = alloc (size_of (u16) * (utf16_str.count + xx null_terminate), allocator);
	byte_offset := 0;
	for utf32_str
		byte_offset += utf16_encode (advance (utf16_str, byte_offset), it);
	if null_terminate then utf16_str.data[utf16_str.count] = 0;
	
	return utf16_str;
}

utf8_string_length :: inline (utf8_str : string) -> s64 #must, valid : bool
{
	length := 0;
	i := 0;
	while i < utf8_str.count
	{
		c := utf8_str[i];
		if  c < 0x80
			i += 1;
		else if (c & 0xe0) == 0xc0
			i += 2;
		else if (c & 0xf0) == 0xe0
			i += 3;
		else if (c & 0xf8) == 0xf0
			i += 4;
		else
			return length, false;

		length += 1;
	}
	
	return length, true;
}

utf16_string_length :: inline (utf16_str : []u16) -> s64 #must, valid : bool
{
	length := 0;
	i := 0;
	while i < utf16_str.count
	{
		c := utf16_str[i];
		if c <= 0xd7ff || (c >= 0xe000 && c <= 0xffff)
			i += 1;
		else if c >= 0xd800 && c <= 0xdbff
			i += 2;
		else
			return length, false;

		length += 1;
	}
	
	return length, true;
}

utf32_string_length :: inline (utf32_str : []u32) -> s64 #must
{
	return utf32_str.count;
}

utf8_equals_utf8 :: (left : string, right : string) -> bool #must
{
	return left == right;
}

utf8_equals_utf16 :: (utf8_str : string, utf16_str : []u16) -> bool #must
{
	len := utf8_string_length (utf8_str);
	if len != utf16_string_length (utf16_str) then return false;
	
	utf8_byte := 0;
	utf16_byte := 0;
	for i : 0..len - 1
	{
		utf8_codepoint, utf8_codepoint_size := utf8_codepoint_at_byte (utf8_str, utf8_byte);
		utf8_byte += utf8_codepoint_size;
		utf16_codepoint, utf16_codepoint_size := utf16_codepoint_at_byte (utf16_str, utf16_byte);
		utf16_byte += utf16_codepoint_size;
		if utf8_codepoint != utf16_codepoint then return false;
	}
	
	return true;
}

utf8_equals_utf32 :: (utf8_str : string, utf32_str : []u32) -> bool #must
{
	len := utf8_string_length (utf8_str);
	if len != utf32_string_length (utf32_str) then return false;
	
	utf8_byte := 0;
	for i : 0..len - 1
	{
		utf8_codepoint, utf8_codepoint_size := utf8_codepoint_at_byte (utf8_str, utf8_byte);
		utf8_byte += utf8_codepoint_size;
		if utf8_codepoint != utf32_str[i] then return false;
	}
	
	return true;
}

utf16_equals_utf16 :: (left : []u16, right : []u16) -> bool #must
{
	if left.count != right.count then return false;
	for i : 0..left.count - 1
	{
		if left[i] != right[i] then return false;
	}
	
	return true;
}

utf16_equals_utf8 :: (utf16_str : []u16, utf8_str : string) -> bool #must
{
	return inline utf8_equals_utf16 (utf8_str, utf16_str);
}

utf16_equals_utf32 :: (utf16_str : []u16, utf32_str : []u32) -> bool #must
{
	len := utf16_string_length (utf16_str);
	if len != utf32_string_length (utf32_str) then return false;
	
	utf16_byte := 0;
	for i : 0..len - 1
	{
		utf16_codepoint, utf16_codepoint_size := utf16_codepoint_at_byte (utf16_str, utf16_byte);
		utf16_byte += utf16_codepoint_size;
		if utf16_codepoint != utf32_str[i] then return false;
	}
	
	return true;
}

utf32_equals_utf32 :: (left : []u32, right : []u32) -> bool #must
{
	if left.count != right.count then return false;
	for i : 0..left.count - 1
	{
		if left[i] != right[i] then return false;
	}
	
	return true;
}

utf32_equals_utf8 :: (utf32_str : []u32, utf8_str : string) -> bool #must
{
	return inline utf8_equals_utf32 (utf8_str, utf32_str);
}

utf32_equals_utf16 :: (utf32_str : []u32, utf16_str : []u16) -> bool #must
{
	return inline utf16_equals_utf32 (utf16_str, utf32_str);
}

UTF8_String :: struct
{
	count : s64;
	data  : *u8;
	#place count;
	as_string : string;
}

UTF16_String :: struct
{
	count : s64;
	data  : *u16;
	#place count;
	as_array : []u16;
}

UTF32_String :: struct
{
	count : s64;
	data  : *u32;
	#place count;
	as_array : []u32;
}

utf8 :: (str : string) -> UTF8_String #must
{
	result : UTF8_String = ---;
	result.as_string = str;
	
	return result;
}

utf16 :: (str : []u16) -> UTF16_String #must
{
	result : UTF16_String = ---;
	result.as_array = str;
	
	return result;
}

utf32 :: (str : []u32) -> UTF32_String #must
{
	result : UTF32_String = ---;
	result.as_array = str;
	
	return result;
}

for_expansion :: (str : *UTF8_String, body : Code, flags : For_Flags) #expand
{
	`it_index := 0;
	byte_offset := 0;
	while byte_offset < str.count
	{
		`it, size := utf8_codepoint_at_byte (str.as_string, byte_offset);
		#insert (continue={ byte_offset += size; it_index += 1; continue; }) body;
		it_index    += 1;
		byte_offset += size;
	}
}

for_expansion :: (str : *UTF16_String, body : Code, flags : For_Flags) #expand
{
	`it_index := 0;
	byte_offset := 0;
	while byte_offset < str.count
	{
		`it, size := utf16_codepoint_at_byte (str.as_array, byte_offset);
		#insert (continue={ byte_offset += size; it_index += 1; continue; }) body;
		it_index    += 1;
		byte_offset += size;
	}
}

for_expansion :: (str : *UTF32_String, body : Code, flags : For_Flags) #expand
{
	for `it, `it_index : str.as_array
	{
		#insert body;
	}
}

operator == :: inline (left : UTF8_String, right : UTF8_String) -> bool #must
{
	return left.as_string == right.as_string;
}

operator == :: inline (left : UTF8_String, right : UTF16_String) -> bool #must #symmetric
{
	return inline utf8_equals_utf16 (left.as_string, right.as_array);
}

operator == :: inline (left : UTF8_String, right : UTF32_String) -> bool #must #symmetric
{
	return inline utf8_equals_utf32 (left.as_string, right.as_array);
}

operator == :: inline (left : UTF16_String, right : UTF16_String) -> bool #must
{
	return inline utf16_equals_utf16 (left.as_array, right.as_array);
}

operator == :: inline (left : UTF16_String, right : UTF32_String) -> bool #must #symmetric
{
	return inline utf16_equals_utf32 (left.as_array, right.as_array);
}

operator == :: inline (left : UTF32_String, right : UTF32_String) -> bool #must
{
	return inline utf32_equals_utf32 (left.as_array, right.as_array);
}
