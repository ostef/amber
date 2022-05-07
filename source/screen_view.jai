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
		effects  : imdraw.Text_Effects;	// 1-byte
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

	id : Id;
	buffer_id : Buffer.Id;
	infos : [..]Info_Range;
}

Screen_View :: struct
{
	Id :: type_of (g_screen_views).Slot_Info;

	Line :: struct
	{
		unwrapped_line_index : s64;
		first_char_index     : s64;
	}

	id : Id;
	#as using base : View;
	text_info_id : Text_Info.Id;
	area    : math.Rectf;
	extents : Vec2f;
	scroll  : Vec2f;
	glyph_rects   : [..]math.Rectf;
	wrapped_lines : [..]Line;
}

handle_window_message :: (using view : *Screen_View, msg : window.Message)
{
	if msg.kind ==
	{
	case .WINDOW_MAXIMIZED; #through;
	case .WINDOW_RESIZED;
		current_available := vec2i (g_viewport_size.x, g_viewport_size.y - WINDOW_CAPTION_HEIGHT);
		new_available := vec2i (msg.viewport_width, msg.viewport_height - WINDOW_CAPTION_HEIGHT);
		x_ratio := area.x1 / cast (f32) current_available.x;
		y_ratio := (area.y1 - WINDOW_CAPTION_HEIGHT) / cast (f32) current_available.y;
		width_ratio := math.rect_width (area) / cast (f32) current_available.x;
		height_ratio := math.rect_height (area) / cast (f32) current_available.y;
		area.x1 = math.round (x_ratio * cast (f32) new_available.x);
		area.y1 = WINDOW_CAPTION_HEIGHT + math.round (y_ratio * cast (f32) new_available.y);
		area.x2 = area.x1 + width_ratio * cast (f32) new_available.x;
		area.y2 = area.y1 + height_ratio * cast (f32) new_available.y;
	}
}

draw :: (using view : Screen_View)
{
	imdraw.scope_clip_rect (math.recti (area));
	imdraw.draw_rect_outline (area, math.RGBA_WHITE, 2);
	//imdraw.draw_text (g_main_font, 22, vec2f ((area.x1 + area.x2) * 0.5, WINDOW_CAPTION_HEIGHT + (area.y1 + area.y2) * 0.5),
	//	"Nothing to see here for the moment", math.rgba (170, 170, 170), anchor = .CENTER);
	prev_texture := imdraw.get_texture ();
	defer imdraw.set_texture (prev_texture);
	prev_shader := imdraw.set_shader (*font.g_glyph_shader);
	defer imdraw.set_shader (prev_shader);

	buffer := get (buffer_id);
	position := math.rect_position (area);
	font_height := get_int (g_config, "buffer_font_height", fallback = 16);
	font_height = math.max (font_height, MIN_FONT_HEIGHT);
	page := font.load_page (g_buffer_font, cast (u32) font_height);
	pen := vec2f (0, cast (f32) page.ascent);
	for codepoint, i : buffer
	{
		drew_cursor := false;
		for cursors
		{
			if it.char_index == i
			{
				advance := cast (f32) page.space_advance;
				if codepoint == #char "\t"
					advance = math.snap_up (pen.x + page.space_advance, page.space_advance * 4.0) - pen.x;
				rect := math.xywhf (
					math.round (position.x) + pen.x,
					math.round (position.y) + pen.y - page.ascent,
					advance,
					cast (f32) (page.ascent - page.descent)
				);
				imdraw.set_texture (null);
				imdraw.draw_rect (rect, math.RGBA_WHITE);
				drew_cursor = true;
			}
		}
		if codepoint ==
		{
		case #char "\n";
			pen.x = 0;
			pen.y += page.ascent - page.descent;
		case #char "\t";
			glyph := font.load_glyph (page, codepoint);
			pen.x = math.snap_up (pen.x + glyph.advance, page.space_advance * 4.0);
		case;
			glyph := font.render_glyph (page, codepoint);
			glyph_rect := math.xywhf (
				math.round (position.x) + pen.x + glyph.bitmap_bearing_x,
				math.round (position.y) + pen.y - glyph.bitmap_bearing_y,
				cast (f32) glyph.bitmap_width,
				cast (f32) glyph.bitmap_height
			);
			pen.x += glyph.advance;
			imdraw.set_texture (glyph.atlas_texture);
			if drew_cursor
				imdraw.draw_rect (glyph_rect, math.RGBA_BLACK, glyph.uv_rect);
			else
				imdraw.draw_rect (glyph_rect, math.RGBA_WHITE, glyph.uv_rect);
		}
	}
}
