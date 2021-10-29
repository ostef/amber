#load "amber_types.jai";
#load "amber_core.jai";
#load "amber_math.jai";
#load "amber_unicode.jai";
#load "amber_platform.jai";
#load "amber_gl.jai";
#load "amber_draw.jai";
#load "amber_font.jai";
#load "amber_buffer.jai";
#load "amber_layout.jai";
#load "amber_split.jai";
#load "amber_language.jai";
#load "amber_extension.jai";

CURSOR_ROUNDING :: 3.0;
CURSOR_MARGIN   :: 0;

viewport_size : Vec2i;
running : bool;
splits       : Slot_Array (Split);
buffers      : Slot_Array (Buffer);
text_layouts : Slot_Array (Text_Layout);
active_split_id : Split_ID;

handle_event :: inline (event : Event) -> Event_Result #must
{
	using result : Event_Result;
	if event.kind ==
	{
	case .WINDOW_CLOSE;
		running = false;
		
	case .WINDOW_RESIZE;
		for * split : splits
		{
			new_area := rectf (
				(split.area.x1 / cast (f32) viewport_size.x) * event.viewport_size.x,
				(split.area.y1 / cast (f32) viewport_size.y) * event.viewport_size.y,
				(split.area.x2 / cast (f32) viewport_size.x) * event.viewport_size.x,
				(split.area.y2 / cast (f32) viewport_size.y) * event.viewport_size.y
			);
			split_set_area (split.id, new_area);
		}
		viewport_size = event.viewport_size;
	
	case .MOUSE_PRESS;
		for splits
		{
			if contains (it.area, event.mouse_position)
			{
				active_split_id = it.id;
				
				break;
			}
		}
	}
	
	return result;
}

main :: ()
{
	FONT_NAME :: "fonts/jetbrainsmono/JetBrainsMono-Regular.ttf";
	
	platform_init_window_and_gl ();
	viewport_size = platform_get_viewport_size ();
	draw_init ();
	font_init ();
	init_slot_array (*buffers, 20, heap_allocator);
	init_slot_array (*text_layouts, 20, heap_allocator);
	init_slot_array (*splits, 10, heap_allocator);
	load_extension ("user.dll");
	init_extensions ();
	font_load_from_file (FONT_NAME);
	split_create_first ();
	
	running = true;
	frame_start := platform_get_time ();
	while running
	{
		previous_frame_start := frame_start;
		frame_start = platform_get_time ();
		delta_time := cast (f32) (frame_start - previous_frame_start);
		reset_temporary_storage ();
		event : Event;
		event_result : Event_Result;
		platform_reset_input_state ();
		while platform_get_next_event (*event)
		{
			event_result ||= handle_event (event);
			extensions_result, propagate := extensions_on_event (event);
			event_result ||= extensions_result;
			if !propagate then continue;
			if active_split_id != NULL_SPLIT
				event_result ||= split_handle_event (active_split_id, event);
		}

		if active_split_id != NULL_SPLIT
			split_update (active_split_id, *event_result, delta_time);
		extensions_on_update ();
		
		draw_begin ();
		for splits
			split_draw (it.id);
		draw_end ();
		platform_swap_window_buffers ();
		frame_end := platform_get_time ();
		platform_sleep_milliseconds (cast (s64) max (16 - (frame_end - frame_start) * 1000, 0));
	}

	terminate_and_free_extensions ();
}

draw_text :: (font_id : Font_ID, height : u32, position : Vec2f, text : string, color : RGBA)
{
	prev_texture := draw_get_texture ();
	defer draw_set_texture (prev_texture);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);
	
	font := get_font (font_id);
	page := load_page (font, height);
	pen : Vec2f;
	for i : 0..text.count - 1
	{
		codepoint : u32 = text[i];
		if codepoint ==
		{
		case #char "\n";
			pen.x = 0;
			pen.y += page.ascent - page.descent;
		
		case #char "\t";
			pen.x = snap_up (pen.x + page.space_advance, page.space_advance * 4.0);
		
		case;
			glyph := load_glyph (page, codepoint);
			glyph_rect := xywhf (
				pen.x + glyph.bitmap_bearing_x,
				pen.y - glyph.bitmap_bearing_y + page.ascent,
				xx glyph.bitmap_width,
				xx glyph.bitmap_height
			);
			glyph_rect = move (glyph_rect, round (position.x), round (position.y));
			draw_set_texture (glyph.atlas_texture);
			draw_rect (glyph_rect, color, uv_rect = glyph.uv_rect);
			pen.x += glyph.advance;
		}
	}
}
@Amber_API
