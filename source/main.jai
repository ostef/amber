#import "Runtime";
mem  :: #import "Memory";
fmt  :: #import "Fmt";
log  :: #import "Log";
str  :: #import "String";
builder :: #import "String/Builder";
strconv :: #import "String/Convert";
path :: #import "Path";
using linalg :: #import "Linalg";
math :: #import "Math";
algo :: #import "Algorithm";
unicode :: #import "Unicode";
utf8    :: #import "Unicode/UTF8";
for_expansion :: utf8.for_expansion;

array   :: #import "Containers/Array";
map     :: #import "Containers/Hash_Map";
for_expansion :: map.for_expansion;
list    :: #import "Containers/List";
for_expansion :: list.for_expansion;
storage :: #import "Containers/Storage";
for_expansion :: storage.for_expansion;

ps     :: #import "Process";
fs     :: #import "File_System";
io     :: #import "IO";
window :: #import "Window";
input  :: #import "Input";
gl     :: #import "GL";
render :: #import "Render_Core";
imdraw :: #import "ImDraw";
font   :: #import "Font";

types :: #import "Types";

#load "buffer.jai";
#load "view.jai";
#load "screen_view/screen_view.jai";
#load "config/config.jai";
#load "jai_lang.jai";

FONT_DIR :: "fonts/";
DEFAULT_FONT_NAME :: "Roboto";
WINDOW_CAPTION_HEIGHT :: 32;
WINDOW_CAPTION_BUTTON_ICON_SIZE :: 10;
WINDOW_CAPTION_BUTTON_MARGIN :: 4;

MIN_FONT_HEIGHT :: 5;

g_window : window.Window;
g_main_font : *font.Font;
g_buffer_font : *font.Font;
g_is_running : bool;
g_logo_textures : struct
{
	FILES :: string.[ "logo/16.png", "logo/32.png", "logo/48.png", "logo/256.png" ];
	all : [4]render.Texture;
	#place all;
	x16, x32, x48, x256  : render.Texture;
};
g_viewport_size : Vec2i;

g_config : Config;
g_buffers : storage.Storage (Buffer, 20);
g_views : storage.Storage (*View, 20);
g_screen_views : storage.Storage (Screen_View, 20);
g_text_infos   : storage.Storage (Text_Info, 20);
g_active_screen_view : *Screen_View;

create_buffer :: () -> *Buffer #must
{
	result, id := storage.find_free_slot (*g_buffers);
	result.id = id;
	init (result, 1000);
	return result;
}

destroy_buffer :: (id : Buffer.Id)
{
	buffer := get (id);
	reset (buffer);
	storage.release_slot (*g_buffers, id);
}

get :: inline (id : Buffer.Id) -> *Buffer #must
{
	return storage.get_item (g_buffers, id);
}

operator == :: inline (a : Buffer.Id, b : Buffer.Id) -> bool #must
{
	return storage.equals (g_buffers, a, b);
}

get :: inline (id : View.Global_Id) -> *View #must
{
	return <<storage.get_item (g_views, id);
}

operator == :: inline (a : View.Global_Id, b : View.Global_Id) -> bool #must
{
	return storage.equals (g_views, a, b);
}

create_screen_view :: (
	buffer_id : Buffer.Id,
	text_info_id : Text_Info.Id,
	read_only : bool,
	area : math.Rectf
) -> *Screen_View #must
{
	result, id := storage.find_free_slot (*g_screen_views);
	view_id := storage.insert (*g_views, result);
	result.id = id;
	result.global_id = view_id;
	init (result, buffer_id, text_info_id, read_only, area);
	return result;
}

destroy_screen_view :: (id : Screen_View.Id)
{
	view := get (id);
	reset (view);
	storage.release_slot (*g_views, view.global_id);
	storage.release_slot (*g_screen_views, id);
}

get :: inline (id : Screen_View.Id) -> *Screen_View #must
{
	return storage.get_item (g_screen_views, id);
}

operator == :: inline (a : Screen_View.Id, b : Screen_View.Id) -> bool #must
{
	return storage.equals (g_screen_views, a, b);
}

create_text_info :: (buffer_id : Buffer.Id) -> *Text_Info #must
{
	assert (storage.is_valid (g_buffers, buffer_id), "Invalid buffer id.");
	result, id := storage.find_free_slot (*g_text_infos);
	result.id = id;
	result.buffer_id = buffer_id;
	array.init (*result.infos, get_count (get (buffer_id)) / 10, mem.HEAP_ALLOC);
	return result;
}

destroy_text_info :: (id : Text_Info.Id)
{
	text_info := get (id);
	array.reset (*text_info.infos);
	storage.release_slot (*g_text_infos, id);
}

get :: inline (id : Text_Info.Id) -> *Text_Info #must
{
	return storage.get_item (g_text_infos, id);
}

operator == :: inline (a : Text_Info.Id, b : Text_Info.Id) -> bool #must
{
	return storage.equals (g_text_infos, a, b);
}

handle_window_message :: (msg : window.Message)
{
	for * g_screen_views
		handle_window_message (it, msg);
	if msg.kind ==
	{
	case .WINDOW_CLOSED;
		g_is_running = false;
	case .MOUSE_BUTTON_RELEASED;
		if msg.mouse_button == .LEFT
		{
			if is_caption_button_hovered (.CLOSE)
				window.close (g_window);
			if is_caption_button_hovered (.MAXIMIZE)
			{
				if window.is_maximized (g_window)
					window.restore (g_window);
				else
					window.maximize (g_window);
			}
			if is_caption_button_hovered (.MINIMIZE)
				window.minimize (g_window);
		}
	case .WINDOW_MAXIMIZED; #through;
	case .WINDOW_RESIZED;
		g_viewport_size.x = msg.viewport_width;
		g_viewport_size.y = msg.viewport_height;
	}
}

main :: ()
{
	error :: (fmt_str : string, args : ..Any) #expand
	{
		window.show_error_box (fmt_str, ..args);
		`return;
	}

	fill_default_context ();
	gl.load ();
	g_window = window.create ("Amber", -1, -1, -1, -1, window.Creation_Flags.VISIBLE | .CUSTOM_CAPTION);
	if !g_window
		error ("Could not create main window.");
	defer window.destroy (g_window);
	window.set_caption_hit_test (g_window, window_caption_hit_test);
	g_viewport_size.x, g_viewport_size.y = window.get_viewport_size (g_window);
	gl_ctx := gl.create_context (g_window);
	if !gl_ctx
		error ("Could not create GL context.");
	defer gl.destroy_context (g_window, gl_ctx);
	imdraw_ctx := imdraw.create_context (g_window, gl_ctx);
	if !imdraw_ctx
		error ("Could not create ImDraw context.");
	defer imdraw.destroy_context (imdraw_ctx);
	g_main_font = font.load_family (FONT_DIR, DEFAULT_FONT_NAME, mem.HEAP_ALLOC);
	if !g_main_font
		error ("Could not load font %.", DEFAULT_FONT_NAME);
	defer font.destroy_family (*g_main_font, mem.HEAP_ALLOC);
	for * g_logo_textures.all
	{
		if !render.load_texture_from_file (it, g_logo_textures.FILES[it_index])
			error ("Could not load texture '%'.", g_logo_textures.FILES[it_index]);
	}
	defer render.destroy_texture (*g_logo_textures.x16);
	defer render.destroy_texture (*g_logo_textures.x32);
	defer render.destroy_texture (*g_logo_textures.x48);
	defer render.destroy_texture (*g_logo_textures.x256);

	storage.init (*g_buffers, mem.HEAP_ALLOC);
	storage.init (*g_views, mem.HEAP_ALLOC);
	storage.init (*g_screen_views, mem.HEAP_ALLOC);
	storage.init (*g_text_infos, mem.HEAP_ALLOC);

	map.init (*g_config.variables, 100, mem.HEAP_ALLOC);
	parser : Config_Parser;
	if !init_from_file (*parser, "config.amber", mem.HEAP_ALLOC)
		error ("Could not read file 'config.amber'.");
	parse (*parser);
	fill_variables (*g_config, parser);
	g_buffer_font = font.load_family (FONT_DIR, get_string (g_config, "buffer_font"), mem.HEAP_ALLOC);
	if !g_buffer_font
		error ("Could not load font %.", get_string (g_config, "buffer_font"));
	defer font.destroy_family (*g_buffer_font, mem.HEAP_ALLOC);

	buffer := create_buffer ();
	if !load_file (buffer, "example.jai")
		log.error ("Could not load file 'example.jai' into buffer.");
	text_info := create_text_info (buffer.id);
	g_active_screen_view = create_screen_view (buffer.id, text_info.id, false, math.xywhf (0, xx WINDOW_CAPTION_HEIGHT, g_viewport_size.x * 0.5, xx (g_viewport_size.y - WINDOW_CAPTION_HEIGHT)));
	view := create_screen_view (buffer.id, text_info.id, false, math.xywhf (g_viewport_size.x * 0.5, xx WINDOW_CAPTION_HEIGHT, g_viewport_size.x * 0.5, xx (g_viewport_size.y - WINDOW_CAPTION_HEIGHT)));

	g_is_running = true;
	while g_is_running
	{
		mem.reset_temporary_storage ();
		window.poll_messages (g_window);
		msg : window.Message;
		while window.get_next_message (g_window, *msg)
			handle_window_message (msg);
		input.update ();

		for * g_text_infos
			update (it);
		for * g_screen_views
			update (it);
		for * g_buffers
			it.is_dirty = false;

		gl.ClearColor (0.1, 0.1, 0.1, 1);
		gl.Clear (gl.COLOR_BUFFER_BIT);
		imdraw.begin (imdraw_ctx);
			for * g_screen_views
				draw (it);
			draw_window_caption ();
		imdraw.end ();
		window.swap_buffers (g_window);
		ps.sleep (10);
	}
}

window_caption_hit_test :: (win : window.Window, mx : s32, my : s32) -> on_caption : bool #must
{
	if is_caption_button_hovered (.CLOSE) || is_caption_button_hovered (.MAXIMIZE) || is_caption_button_hovered (.MINIMIZE)
		return false;
	if my < WINDOW_CAPTION_HEIGHT
		return true;
	return false;
}

Caption_Button :: enum
{
	CLOSE    :: 0;
	MAXIMIZE :: 1;
	MINIMIZE :: 2;
}

get_caption_button_rect :: inline (button : Caption_Button) -> math.Rectf
{
	margin := 0.0;
	if !window.is_maximized (g_window)
		margin = cast (f32) WINDOW_CAPTION_BUTTON_MARGIN;
	button_size := WINDOW_CAPTION_HEIGHT - margin * 2;
	vw := window.get_viewport_size (g_window);
	i := cast (int) button;
	return math.xywhf (
		cast (f32) (vw - (i + 1) * (button_size + margin)), margin,
		button_size, button_size
	);
	}

is_caption_button_hovered :: inline (button : Caption_Button) -> bool
{
	mx, my := window.get_mouse_position (g_window);
	return math.contains (get_caption_button_rect (button), vec2f (xx mx, xx my));
}

draw_window_caption :: ()
{
	vw, vh := window.get_viewport_size (g_window);
	imdraw.draw_rect (math.xywhf (0, 0, xx vw, xx WINDOW_CAPTION_HEIGHT), math.rgba (40, 40, 40));
	// Draw title
	text_rect := imdraw.draw_text (
		g_main_font,
		14,
		vec2f (vw * 0.5, WINDOW_CAPTION_HEIGHT * 0.5),
		"Amber",
		math.rgba (170, 170, 170),
		anchor = .CENTER
	);
	// Draw logo
	imdraw.set_texture (*g_logo_textures.x48);
	imdraw.draw_rect (math.xywhf ((WINDOW_CAPTION_HEIGHT - 24) * 0.5, (WINDOW_CAPTION_HEIGHT - 24) * 0.5, 24, 24), math.RGBA_WHITE);
	//math.xywhf (text_rect.x1 - 30, (WINDOW_CAPTION_HEIGHT - 24) * 0.5, 24, 24), math.RGBA_WHITE);
	imdraw.set_texture (null);
	// Draw buttons when hovered
	for i : 0..2
	{
		if is_caption_button_hovered (cast (Caption_Button) i)
		{
			c := math.rgba (60, 60, 60);
			if input.is_mouse_button_down (.LEFT)
			{
				if i == 0
					c = math.rgba (170, 30, 30);
				else
					c = math.rgba (80, 80, 80);
			}
			else if i == 0
				c = math.rgba (200, 60, 60);
			imdraw.draw_rect (get_caption_button_rect (cast (Caption_Button) i), c, 4);
		}
	}
	// Draw button symbols
	r := get_caption_button_rect (.CLOSE);
	r = math.xywhf (
		(r.x1 + r.x2 - WINDOW_CAPTION_BUTTON_ICON_SIZE) * 0.5,
		(r.y1 + r.y2 - WINDOW_CAPTION_BUTTON_ICON_SIZE) * 0.5,
		xx WINDOW_CAPTION_BUTTON_ICON_SIZE,
		xx WINDOW_CAPTION_BUTTON_ICON_SIZE
	);
	c := math.rgba (170, 170, 170);
	imdraw.draw_line (vec2f (r.x1, r.y1), vec2f (r.x2, r.y2), c, 1);
	imdraw.draw_line (vec2f (r.x1, r.y2), vec2f (r.x2, r.y1), c, 1);
	r = get_caption_button_rect (.MAXIMIZE);
	r = math.xywhf (
		(r.x1 + r.x2 - WINDOW_CAPTION_BUTTON_ICON_SIZE) * 0.5 + 0.5,
		(r.y1 + r.y2 - WINDOW_CAPTION_BUTTON_ICON_SIZE) * 0.5 + 0.5,
		xx WINDOW_CAPTION_BUTTON_ICON_SIZE,
		xx WINDOW_CAPTION_BUTTON_ICON_SIZE
	);
	imdraw.draw_rect_outline (r, c, 1);
	r = get_caption_button_rect (.MINIMIZE);
	r = math.xywhf (
		(r.x1 + r.x2 - WINDOW_CAPTION_BUTTON_ICON_SIZE) * 0.5,
		(r.y1 + r.y2 - WINDOW_CAPTION_BUTTON_ICON_SIZE) * 0.5,
		xx WINDOW_CAPTION_BUTTON_ICON_SIZE,
		xx WINDOW_CAPTION_BUTTON_ICON_SIZE
	);
	imdraw.draw_line (vec2f (r.x1, (r.y1 + r.y2) * 0.5 + 0.5), vec2f (r.x2, (r.y1 + r.y2) * 0.5 + 0.5), c, 1);
}
