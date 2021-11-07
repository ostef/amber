#scope_file

#import "freetype255";

#scope_export

DISALLOW_NON_MONOSPACE_FONTS :: true;

Font :: struct
{
	using info : Font_Info;
	ft_face : FT_Face;
	pages   : Hash_Map (u32, Font_Page);
}

Font_Glyph :: struct
{
	codepoint : u32;
	
	width, height : u32;
	bearing_x, bearing_y : s32;
	advance : u32;
	bitmap_bearing_x, bitmap_bearing_y : s32;
	bitmap_width, bitmap_height : u32;

	uv_rect : Rectf;
	atlas_texture : Texture_Handle;
}

Font_Page :: struct
{
	font    : *Font;
	height  : u32;
	atlases : [..]Font_Atlas;
	glyphs  : Hash_Map (u32, Font_Glyph);
	ascent, descent : s32;
	space_advance : u32;
}

Font_Atlas :: struct
{
	texture     : Texture_Handle;
	framebuffer : Framebuffer_Handle;
	width, height : u32;
	pen_x, pen_y  : u32;
	row_end : u32;
}

DEFAULT_FONT_ATLAS_WIDTH  : u32 : 1024;
DEFAULT_FONT_ATLAS_HEIGHT : u32 : 1024;

#scope_file

ft : *FT_Library;
fonts : Slot_Array (Font);

#scope_export

glyph_shader : Shader_Handle;

font_exists :: (id : Font_ID) -> bool #must
{
	return id > 0 && id <= xx fonts.max_occupied && fonts.slots[cast (s64) id - 1].occupied;
}
@Amber_API

get_font :: inline (id : Font_ID) -> *Font #must
{
	assert (font_exists (id), "Invalid font id (%).", id);
	
	return get_ptr (*fonts, cast (s64) id - 1);
}

font_init :: inline ()
{
	ft_error := FT_Init_FreeType (*ft);
	assert (ft_error == FT_Err_Ok, "Could not initialize FreeType.");
	init_slot_array (*fonts, 10, heap_allocator);
	glyph_shader = create_shader (VERTEX_SHADER, GLYPH_FRAGMENT_SHADER);
	assert (glyph_shader != 0, "Could not create glyph shader.");
}

font_load_from_file :: (filename : string) -> bool, Font_ID
{
	ft_face : FT_Face;
	ft_error := FT_New_Face (ft, clone_to_cstring (filename, temp_allocator), 0, *ft_face);
	if ft_error != FT_Err_Ok
	{
		//log_error ("Could not load font '%': (FreeType) '%'.", filename, ft_error);
		
		return false, NULL_FONT;
	}
	font, index := insert_into_slot_array (*fonts);
	font.id = cast (Font_ID) index + 1;
	font.filename = clone_string (filename, heap_allocator);
	font.ft_face = ft_face;
	init_map (*font.pages, 10, heap_allocator);

	return true, cast (Font_ID) index + 1;
}
@Amber_API

cleanup_font :: (using font : *Font)
{
	free (filename, heap_allocator);
	filename = "";
	FT_Done_Face (ft_face);
	ft_face = null;
	for * page, height : pages
	{
		for atlas, i : page.atlases
			destroy_framebuffer_and_texture (atlas.framebuffer, atlas.texture);
		reset_array (*page.atlases);
		reset_map (*page.glyphs);
	}
	reset_map (*pages);
}

load_page :: (using font : *Font, height : u32) -> *Font_Page
{
	page, was_present := insert_into_map (*pages, height);
	if was_present then return page;
	
	page.font   = font;
	page.height = height;
	init_array (*page.atlases, 3, heap_allocator);
	init_map (*page.glyphs, 512, heap_allocator);
	space_glyph := load_glyph (page, #char " ");
	page.ascent        = xx (ft_face.size.metrics.ascender >> 6);
	page.descent       = xx (ft_face.size.metrics.descender >> 6);
	page.space_advance = xx (space_glyph.advance);
	
	return page;
}

add_atlas_to_page :: (using page : *Font_Page, atlas_width := DEFAULT_FONT_ATLAS_WIDTH, atlas_height := DEFAULT_FONT_ATLAS_HEIGHT) -> *Font_Atlas
{
	result := push_into_array (*atlases);
	result.width  = atlas_width;
	result.height = atlas_height;
	result.framebuffer, result.texture = create_framebuffer_and_texture (atlas_width, atlas_height, 1);
	
	return result;
}

load_glyph :: inline (font : *Font, codepoint : u32, height : u32) -> *Font_Glyph
{
	page := load_page (font, height);
	
	return load_glyph (page, codepoint);
}

load_glyph :: (using page : *Font_Page, codepoint : u32) -> *Font_Glyph
{
	glyph, was_present := insert_into_map (*glyphs, codepoint);
	if was_present then return glyph;
	
	FT_Set_Pixel_Sizes (font.ft_face, 0, height);
	ft_error := FT_Load_Char (font.ft_face, codepoint, FT_LOAD_RENDER);
	assert (ft_error == FT_Err_Ok, "Could not load glyph %.", codepoint);
	slot := font.ft_face.glyph;
	
	glyph.codepoint = codepoint;
	glyph.width     = xx (slot.metrics.width  >> 6);
	glyph.height    = xx (slot.metrics.height >> 6);
	glyph.bearing_x = xx (slot.metrics.horiBearingX >> 6);
	glyph.bearing_y = xx (slot.metrics.horiBearingY >> 6);
	glyph.advance   = xx (slot.metrics.horiAdvance >> 6);
	
	glyph.bitmap_width     = xx slot.bitmap.width;
	glyph.bitmap_height    = xx slot.bitmap.rows;
	glyph.bitmap_bearing_x = xx slot.bitmap_left;
	glyph.bitmap_bearing_y = xx slot.bitmap_top;
#if DISALLOW_NON_MONOSPACE_FONTS
{
	if codepoint != #char " "
		always_assert (glyph.advance == xx space_advance, "Font is not monospace (glyph % advance is %, space advance is %).", codepoint, glyph.advance, space_advance);
}

	atlas : *Font_Atlas;
	for * atlases
	{
		if it.width - it.pen_y > glyph.bitmap_width && it.height - it.pen_y > glyph.bitmap_height
		{
			atlas = it;
			
			break;
		}
	}
	
	if !atlas
	{
		atlas = push_into_array (*atlases);
		atlas.width  = DEFAULT_FONT_ATLAS_WIDTH;
		atlas.height = DEFAULT_FONT_ATLAS_HEIGHT;
		atlas.framebuffer, atlas.texture = create_framebuffer_and_texture (atlas.width, atlas.height);
		assert (atlas.framebuffer != 0 && atlas.texture != 0, "Could not create rendering objects for font atlas.");
	}
	
	glyph_texture := create_texture (glyph.bitmap_width, glyph.bitmap_height, 1, slot.bitmap.buffer);
	defer destroy_texture (glyph_texture);
	
	if atlas.width - atlas.pen_x < glyph.bitmap_width || atlas.height - atlas.pen_y < glyph.bitmap_height
	{
		atlas.pen_x = 0;
		atlas.pen_y = atlas.row_end;
		atlas.row_end += glyph.bitmap_height;
	}

	glyph.uv_rect = rectf (
		atlas.pen_x / cast (f32) atlas.width,
		1 - atlas.pen_y / cast (f32) atlas.height,
		(atlas.pen_x + glyph.bitmap_width) / cast (f32) atlas.width,
		1 - (atlas.pen_y + glyph.bitmap_height) / cast (f32) atlas.height
	);
	glyph.atlas_texture = atlas.texture;

	prev_texture := draw_set_texture (glyph_texture);
	defer draw_set_texture (prev_texture);
	prev_framebuffer := draw_set_framebuffer (atlas.framebuffer);
	defer draw_set_framebuffer (prev_framebuffer);
	prev_viewport := draw_set_viewport (recti (0, 0, xx atlas.width, xx atlas.height));
	defer draw_set_viewport (prev_viewport);
	prev_clip := draw_set_clipping (false);
	defer draw_set_clipping (prev_clip);
	prev_shader := draw_set_shader (glyph_shader);
	defer draw_set_shader (prev_shader);
	
	draw_rect (xywhf (
		xx atlas.pen_x,
		xx atlas.pen_y,
		xx glyph.bitmap_width,
		xx glyph.bitmap_height),
		RGBA_WHITE
	);
	
	atlas.pen_x += glyph.bitmap_width;
	atlas.row_end = max (atlas.row_end, atlas.pen_y + glyph.bitmap_height);
	
	return glyph;
}

font_get_line_height :: inline (font_id : Font_ID, font_height : u32) -> f32 #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);
	
	return cast (f32) (page.ascent - page.descent);
}
@Amber_API

font_get_space_advance :: inline (font_id : Font_ID, font_height : u32) -> f32 #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);
	
	return cast (f32) (page.space_advance);
}
@Amber_API

font_get_text_extents :: inline (font_id : Font_ID, font_height : u32, text : string) -> Vec2f #must
{
	font := get_font (font_id);
	page := load_page (font, font_height);

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
			glyph_rect = glyph_rect;
			pen.x += glyph.advance;
		}
	}
	pen.y += page.ascent - page.descent;
	
	return pen;
}
@Amber_API

GLYPH_FRAGMENT_SHADER :: #string END
#version 330 core

in vec2 Tex_Coords;
in vec4 Color;

out vec4 Frag_Color;

uniform sampler2D u_Texture;
uniform bool u_Use_Texture;

void main ()
{
	vec4 sampled = vec4 (1, 1, 1, 1);
	if (u_Use_Texture)
		sampled = vec4 (1, 1, 1, texture (u_Texture, Tex_Coords).r);
	Frag_Color = sampled * Color;
}
END
