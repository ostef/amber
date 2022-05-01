// Metadata about the text in a buffer, for rendering.
// This is the thing that a syntax colorizer would modify.
// It might make it so that all 'if's are in bold, and
// of color-id 'keyword' for example.
Text_Info :: struct
{
	Id :: type_of (g_text_infos).Slot_Info;

	Info :: struct
	{
		weight   : font.Weight;		// 1-byte
		effects  : font.Effects;	// 1-byte
		color_id : Color_Id;		// 2-bytes
	}	// 4-bytes

	// We don't want to have an Info for each character,
	// because that wouldn't be very efficient, so we have
	// an info for a range of characters.
	Info_Range :: struct
	{
		range : Vec2i;		// 8-bytes
		using info : Info;	// 4-bytes
	}	// 12-bytes, 16-bytes with padding

	// If we have a buffer with 5000 lines, let's say
	// on average it has 80 character long lines,
	// with 15 tokens per lines, and we don't merge
	// similar tokens together, we have 15 * 5000
	// Info_Ranges, so 15 * 5000 * 16 bytes = 1,2 MB

	buffer_id : Buffer.Id;
	infos : [..]Info_Range;
}

Screen_View :: struct
{
	Id :: type_of (g_screen_views).Slot_Info;

	Line :: struct
	{
		unwrapped_line_index  : s64;
		first_char_index      : s64;
	}

	#as using base : View;
	text_info : Text_Info.Id;
	area    : math.Rectf;
	extents : Vec2f;
	scroll  : Vec2f;
	glyph_rects   : [..]math.Rectf;
	wrapped_lines : [..]Line;
}

draw :: (using view : Screen_View)
{
}
