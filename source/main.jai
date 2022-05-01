#import "Runtime";
mem  :: #import "Memory";
fmt  :: #import "Fmt";
log  :: #import "Log";
str  :: #import "String";
builder :: #import "String/Builder";
strconv :: #import "String/Convert";
path :: #import "Path";
#import "Linalg";
math :: #import "Math";
utf8 :: #import "Unicode/UTF8";
for_expansion :: utf8.for_expansion;
algo :: #import "Algorithm";

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

#load "buffer.jai";
#load "view.jai";
#load "screen_view.jai";
#load "config/config.jai";

DEFAULT_FONT_DIR :: "fonts/roboto/";
DEFAULT_FONT_NAME :: "Roboto";
WINDOW_CAPTION_HEIGHT :: 32;
WINDOW_CAPTION_BUTTON_SIZE :: 24;
WINDOW_CAPTION_BUTTON_MARGIN :: (WINDOW_CAPTION_HEIGHT - WINDOW_CAPTION_BUTTON_SIZE) / 2;

g_window : window.Window;
g_default_font : *font.Font;
g_is_running : bool;
g_logo_textures : struct
{
	FILES :: string.[ "logo/16.png", "logo/32.png", "logo/48.png", "logo/256.png" ];
	all : [4]render.Texture;
	#place all;
	x16, x32, x48, x256  : render.Texture;
};

g_buffers : storage.Storage (Buffer, 20);
g_views : storage.Storage (*View, 20);
g_screen_views : storage.Storage (Screen_View, 20);
g_text_infos   : storage.Storage (Text_Info, 20);

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

get :: inline (id : Screen_View.Id) -> *Screen_View #must
{
	return storage.get_item (g_screen_views, id);
}

operator == :: inline (a : Screen_View.Id, b : Screen_View.Id) -> bool #must
{
	return storage.equals (g_screen_views, a, b);
}

get :: inline (id : Text_Info.Id) -> *Text_Info #must
{
	return storage.get_item (g_text_infos, id);
}

operator == :: inline (a : Text_Info.Id, b : Text_Info.Id) -> bool #must
{
	return storage.equals (g_text_infos, a, b);
}

get_views_attached_to_buffer :: (id : Buffer.Id, allocator : Allocator) -> [..]*View #must
{
	result : [..]*View;
	result.allocator = allocator;
	for g_views
	{
		if storage.equals (g_buffers, it.buffer_id, id)
			array.push (*result, it);
	}

	return result;
}

handle_window_message :: (msg : window.Message)
{
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
	gl_ctx := gl.create_context (g_window);
	if !gl_ctx
		error ("Could not create GL context.");
	defer gl.destroy_context (g_window, gl_ctx);
	imdraw_ctx := imdraw.create_context (g_window, gl_ctx);
	if !imdraw_ctx
		error ("Could not create ImDraw context.");
	defer imdraw.destroy_context (imdraw_ctx);
	g_default_font = font.load_family (DEFAULT_FONT_DIR, DEFAULT_FONT_NAME, mem.HEAP_ALLOC);
	if !g_default_font
		error ("Could not load font %.", DEFAULT_FONT_NAME);
	defer font.destroy_family (*g_default_font, mem.HEAP_ALLOC);
	for * g_logo_textures.all
	{
		if !render.load_texture_from_file (it, g_logo_textures.FILES[it_index])
			error ("Could not load texture '%'.", g_logo_textures.FILES[it_index]);
	}
	defer render.destroy_texture (*g_logo_textures.x16);
	defer render.destroy_texture (*g_logo_textures.x32);
	defer render.destroy_texture (*g_logo_textures.x48);
	defer render.destroy_texture (*g_logo_textures.x256);

	config : Config;
	map.init (*config.variables, 100, mem.HEAP_ALLOC);
	parser : Config_Parser;
	if !init_from_file (*parser, "config.amber", mem.HEAP_ALLOC)
		error ("Could not read file 'config.amber'.");
	parse (*parser);
	fill_variables (*config, parser);

	g_is_running = true;
	while g_is_running
	{
		mem.reset_temporary_storage ();
		window.poll_messages (g_window);
		msg : window.Message;
		while window.get_next_message (g_window, *msg)
			handle_window_message (msg);

		vw, vh := window.get_viewport_size (g_window);
		gl.ClearColor (0.1, 0.1, 0.1, 1);
		gl.Clear (gl.COLOR_BUFFER_BIT);
		imdraw.begin (imdraw_ctx);
			imdraw.draw_text (g_default_font, 22, vec2f (vw * 0.5, WINDOW_CAPTION_HEIGHT + (vh - WINDOW_CAPTION_HEIGHT) * 0.5),
				"Nothing to see here for the moment", math.rgba (170, 170, 170), anchor = .CENTER);
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
	vw := window.get_viewport_size (g_window);
	i := cast (int) button;
	return math.xywhf (
		cast (f32) (vw - (i + 1) * (WINDOW_CAPTION_BUTTON_SIZE + WINDOW_CAPTION_BUTTON_MARGIN)), xx WINDOW_CAPTION_BUTTON_MARGIN,
		xx WINDOW_CAPTION_BUTTON_SIZE, xx WINDOW_CAPTION_BUTTON_SIZE
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
		g_default_font,
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
	r := math.truncate_all_sides (get_caption_button_rect (.CLOSE), 7);
	c := math.rgba (170, 170, 170);
	imdraw.draw_line (vec2f (r.x1, r.y1), vec2f (r.x2, r.y2), c, 1);
	imdraw.draw_line (vec2f (r.x1, r.y2), vec2f (r.x2, r.y1), c, 1);
	r = math.truncate_all_sides (get_caption_button_rect (.MAXIMIZE), 7.5);
	imdraw.draw_rect_outline (r, c, 1);
	r = math.truncate_all_sides (get_caption_button_rect (.MINIMIZE), 7);
	imdraw.draw_line (vec2f (r.x1, (r.y1 + r.y2) * 0.5 + 0.5), vec2f (r.x2, (r.y1 + r.y2) * 0.5 + 0.5), c, 1);
}
