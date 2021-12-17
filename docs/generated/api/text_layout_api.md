# Text Layout API

[Text_Layout_ID]: #Text_Layout_ID
<h2 id="Text_Layout_ID">
Type:
</h2>

```jai
Text_Layout_ID :: #type, distinct u32
```

## Description:
Used to identify a text layout in the editor. You can check if a text layout exists by calling [text_layout_exists].

---

[get_text_layout_count]: #get_text_layout_count
<h2 id="get_text_layout_count">
Procedure:
</h2>

```jai
get_text_layout_count :: () -> s64
```

## Description:
Ask the editor for the total number of opened text layouts.

## Returns:
The number of opened text layoutes in the editor.  

---

[get_active_text_layout]: #get_active_text_layout
<h2 id="get_active_text_layout">
Procedure:
</h2>

```jai
get_active_text_layout :: () -> Text_Layout_ID
```

## Description:
Ask the editor for the id of the currently active text layout.
Shorthand for `buffer_get_text_layout (get_active_buffer ())`.

## Returns:
The id of the active text layout.  

---

[text_layout_exists]: #text_layout_exists
<h2 id="text_layout_exists">
Procedure:
</h2>

```jai
text_layout_exists :: (
	id : Text_Layout_ID
) -> bool
```

## Description:
Ask the editor if a text layout with a given id exists.

## Params:
**id** is the id of the text layout.  

## Returns:
*true* if the text layout exists, *false* otherwise.  

---

[text_layout_clear]: #text_layout_clear
<h2 id="text_layout_clear">
Procedure:
</h2>

```jai
text_layout_clear :: (
	layout_id : Text_Layout_ID
)
```

## Description:
Clear the cached data in the text layout. `is_dirty` is set to *true*.

## Params:
**layout_id** is the id of the text layout.  

---

[text_layout_get_split]: #text_layout_get_split
<h2 id="text_layout_get_split">
Procedure:
</h2>

```jai
text_layout_get_split :: (
	layout_id : Text_Layout_ID
) -> Split_ID
```

## Description:
Get the split associated with the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The id of the split associated with the text layout.  

---

[text_layout_get_buffer]: #text_layout_get_buffer
<h2 id="text_layout_get_buffer">
Procedure:
</h2>

```jai
text_layout_get_buffer :: (
	layout_id : Text_Layout_ID
) -> Buffer_ID
```

## Description:
Get the buffer associated with the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The id of the buffer associated with the text layout.  

---

[text_layout_get_font]: #text_layout_get_font
<h2 id="text_layout_get_font">
Procedure:
</h2>

```jai
text_layout_get_font :: (
	layout_id : Text_Layout_ID
) -> Font_ID
```

## Description:
Get the font associated with the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The id of the font associated with the text layout.  

---

[text_layout_set_font]: #text_layout_set_font
<h2 id="text_layout_set_font">
Procedure:
</h2>

```jai
text_layout_set_font :: (
	layout_id : Text_Layout_ID, 
	font_id : Font_ID
)
```

## Description:
Set the font associated with the text layout. `is_dirty` is set to *true*.

## Params:
**layout_id** is the id of the text layout.  
**font_id** is the id of the new font.  

---

[text_layout_get_font_height]: #text_layout_get_font_height
<h2 id="text_layout_get_font_height">
Procedure:
</h2>

```jai
text_layout_get_font_height :: (
	layout_id : Text_Layout_ID
) -> u32
```

## Description:
Get the font height of the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The font height of the text layout.  

---

[text_layout_set_font_height]: #text_layout_set_font_height
<h2 id="text_layout_set_font_height">
Procedure:
</h2>

```jai
text_layout_set_font_height :: (
	layout_id : Text_Layout_ID, 
	font_height : u32
)
```

## Description:
Set the font height of the text layout. `is_dirty` is set to *true*.

## Params:
**layout_id** is the id of the text layout.  
**font_height** is the new font height.  

---

[text_layout_get_column_width]: #text_layout_get_column_width
<h2 id="text_layout_get_column_width">
Procedure:
</h2>

```jai
text_layout_get_column_width :: (
	layout_id : Text_Layout_ID
) -> f32
```

## Description:
Get the column width used by the text layout. Effectively this returns the space advance of the font with the layout font height. We currently assume fonts are monospace.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The column width used by the text layout.  

---

[text_layout_get_line_height]: #text_layout_get_line_height
<h2 id="text_layout_get_line_height">
Procedure:
</h2>

```jai
text_layout_get_line_height :: (
	layout_id : Text_Layout_ID
) -> f32
```

## Description:
Get the line height of the text layout. Effectively this returns the line height of the font with the layout font height.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The line height of the text layout.  

---

[text_layout_is_dirty]: #text_layout_is_dirty
<h2 id="text_layout_is_dirty">
Procedure:
</h2>

```jai
text_layout_is_dirty :: (
	layout_id : Text_Layout_ID
) -> bool
```

## Description:
Ask the editor if the given text layout should be recomputed.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The dirty state of the text layout.  

---

[text_layout_set_dirty]: #text_layout_set_dirty
<h2 id="text_layout_set_dirty">
Procedure:
</h2>

```jai
text_layout_set_dirty :: (
	layout_id : Text_Layout_ID
)
```

## Description:
Notify the editor that the given text layout should be recomputed.

## Params:
**layout_id** is the id of the text layout.  

---

[text_layout_get_area]: #text_layout_get_area
<h2 id="text_layout_get_area">
Procedure:
</h2>

```jai
text_layout_get_area :: (
	layout_id : Text_Layout_ID
) -> Rectf
```

## Description:
Get the area available to the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The area used by the text layout.  

---

[text_layout_set_area]: #text_layout_set_area
<h2 id="text_layout_set_area">
Procedure:
</h2>

```jai
text_layout_set_area :: (
	layout_id : Text_Layout_ID, 
	area : Rectf
)
```

## Description:
Set the area available to the text layout. `is_dirty` is set to *true*.

## Params:
**layout_id** is the id of the text layout.  
**area** is the new area.  

---

[text_layout_update_area]: #text_layout_update_area
<h2 id="text_layout_update_area">
Procedure:
</h2>

```jai
text_layout_update_area :: (
	layout_id : Text_Layout_ID
)
```

## Description:
Set the area available to the text layout to `split_get_text_layout_area (text_layout_get_split (layout_id))`. `is_dirty` is set to *true*.

## Params:
**layout_id** is the id of the text layout.  

---

[text_layout_get_extents]: #text_layout_get_extents
<h2 id="text_layout_get_extents">
Procedure:
</h2>

```jai
text_layout_get_extents :: (
	layout_id : Text_Layout_ID
) -> Vec2f
```

## Description:
Get the extents of the text, computed by the text layout (see [text_layout_compute]).

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The extents of the text.  

---

[text_layout_get_scroll]: #text_layout_get_scroll
<h2 id="text_layout_get_scroll">
Procedure:
</h2>

```jai
text_layout_get_scroll :: (
	layout_id : Text_Layout_ID
) -> Vec2f
```

## Description:
Get the scroll on the x and y axis (column and line) of the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The scroll on the x and y axis (column and line) of the text layout in (column width, line height) units.  

---

[text_layout_set_scroll]: #text_layout_set_scroll
<h2 id="text_layout_set_scroll">
Procedure:
</h2>

```jai
text_layout_set_scroll :: (
	layout_id : Text_Layout_ID, 
	scroll : Vec2f
)
```

## Description:
Set the scroll on the x and y axis (column and line) of the text layout.

## Params:
**layout_id** is the id of the text layout.  
**scroll** is the new scroll value, in (column width, line height) units.  

---

[text_layout_set_scroll_x]: #text_layout_set_scroll_x
<h2 id="text_layout_set_scroll_x">
Procedure:
</h2>

```jai
text_layout_set_scroll_x :: (
	layout_id : Text_Layout_ID, 
	scroll_x : f32
)
```

## Description:
Set the scroll on the x axis (column) of the text layout.

## Params:
**layout_id** is the id of the text layout.  
**scroll_x** is the new scroll value, in column width units.  

---

[text_layout_set_scroll_y]: #text_layout_set_scroll_y
<h2 id="text_layout_set_scroll_y">
Procedure:
</h2>

```jai
text_layout_set_scroll_y :: (
	layout_id : Text_Layout_ID, 
	scroll_y : f32
)
```

## Description:
Set the scroll on the y axis (column and line) of the text layout.

## Params:
**layout_id** is the id of the text layout.  
**scroll_y** is the new scroll value, in line height units.  

---

[text_layout_scroll_x]: #text_layout_scroll_x
<h2 id="text_layout_scroll_x">
Procedure:
</h2>

```jai
text_layout_scroll_x :: (
	layout_id : Text_Layout_ID, 
	add_scroll : f32
)
```

## Description:
Scroll the text layout on the x axis.

## Params:
**layout_id** is the id of the text layout.  
**add_scroll** is the scroll value to add on the x axis, in column width.  

---

[text_layout_get_max_scroll]: #text_layout_get_max_scroll
<h2 id="text_layout_get_max_scroll">
Procedure:
</h2>

```jai
text_layout_get_max_scroll :: (
	layout_id : Text_Layout_ID
) -> Vec2f
```

## Description:
Get the maximum scroll of the text layout on the x and y axis.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The maximum scroll on the x and y axis (column and line) of the text layout in (column width, line height) units.  

---

[text_layout_get_visual_scroll]: #text_layout_get_visual_scroll
<h2 id="text_layout_get_visual_scroll">
Procedure:
</h2>

```jai
text_layout_get_visual_scroll :: (
	layout_id : Text_Layout_ID
) -> Vec2f
```

## Description:
Get the visual scroll of the text layout on the x and y axis.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The visual scroll on the x and y axis, in (column width, line height) units.  

---

[text_layout_set_visual_scroll]: #text_layout_set_visual_scroll
<h2 id="text_layout_set_visual_scroll">
Procedure:
</h2>

```jai
text_layout_set_visual_scroll :: (
	layout_id : Text_Layout_ID, 
	scroll : Vec2f
)
```

## Description:
Set the visual scroll of the text layout on the x and y axis.

## Params:
**layout_id** is the id of the text layout.  
**scroll** is the new visual scroll.  

---

[text_layout_get_rect]: #text_layout_get_rect
<h2 id="text_layout_get_rect">
Procedure:
</h2>

```jai
text_layout_get_rect :: (
	layout_id : Text_Layout_ID, 
	index : s64
) -> Rectf
```

## Description:
Get the *absolute* rect (as displayed on the screen) of the character at **index**, computed by the text layout.

## Params:
**layout_id** is the id of the text layout.  
**index** is the index of the character.  

## Returns:
The *absolute* rect of the character at **index**.  

---

[text_layout_get_relative_rect]: #text_layout_get_relative_rect
<h2 id="text_layout_get_relative_rect">
Procedure:
</h2>

```jai
text_layout_get_relative_rect :: (
	layout_id : Text_Layout_ID, 
	index : s64
) -> Rectf
```

## Description:
Get the *relative* rect (without scroll) of the character at **index**, computed by the text layout.

## Params:
**layout_id** is the id of the text layout.  
**index** is the index of the character.  

## Returns:
The *relative* rect of the character at **index**.  

---

[text_layout_get_visible_range]: #text_layout_get_visible_range
<h2 id="text_layout_get_visible_range">
Procedure:
</h2>

```jai
text_layout_get_visible_range :: (
	layout_id : Text_Layout_ID
) -> Rangei
```

## Description:
Get the range of visible characters on the screen, as dictated by the scroll amount and area of the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The range of visible characters on the screen.  

---

[text_layout_get_visible_line_range]: #text_layout_get_visible_line_range
<h2 id="text_layout_get_visible_line_range">
Procedure:
</h2>

```jai
text_layout_get_visible_line_range :: (
	layout_id : Text_Layout_ID
) -> Rangei
```

## Description:
Get the range of visible *wrapped* lines on the screen, as dictated by the scroll amount and area of the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The range of visible lines on the screen.  

---

[text_layout_get_line_range]: #text_layout_get_line_range
<h2 id="text_layout_get_line_range">
Procedure:
</h2>

```jai
text_layout_get_line_range :: (
	layout_id : Text_Layout_ID, 
	line_index : s64
) -> Rangei
```

## Description:
Get the character range of the given *wrapped* line in the text layout.

## Params:
**layout_id** is the id of the text layout.  
**line_index** is the index of the *wrapped* line.  

## Returns:
The range of characters in the given line.  

---

[text_layout_get_closest_character]: #text_layout_get_closest_character
<h2 id="text_layout_get_closest_character">
Procedure:
</h2>

```jai
text_layout_get_closest_character :: (
	layout_id : Text_Layout_ID, 
	position : Vec2f
) -> s64
```

## Description:
Get the index of closest character to **position** as displayed on the screen.

## Params:
**layout_id** is the id of the text layout.  
**position** is the position of the point.  

## Returns:
The index of the closest character to the given point.  

---

[text_layout_get_base_line]: #text_layout_get_base_line
<h2 id="text_layout_get_base_line">
Procedure:
</h2>

```jai
text_layout_get_base_line :: (
	layout_id : Text_Layout_ID
) -> s64
```

## Description:
Get the first visible line of the text layout.

## Params:
**layout_id** is the id of the text layout.  

## Returns:
The first visible line.  

---

[text_layout_clear_colors]: #text_layout_clear_colors
<h2 id="text_layout_clear_colors">
Procedure:
</h2>

```jai
text_layout_clear_colors :: (
	layout_id : Text_Layout_ID
)
```

## Description:
Clear the array of colors in the text layout.

## Params:
**layout_id** is the id of the text layout.  

---

[text_layout_push_color]: #text_layout_push_color
<h2 id="text_layout_push_color">
Procedure:
</h2>

```jai
text_layout_push_color :: (
	layout_id : Text_Layout_ID, 
	range : Rangei, 
	color : RGBA
)
```

## Description:
Push a new color at the end of the colors array in the text layout.

## Params:
**layout_id** is the id of the text layout.  
**range** is the range of characters affected by the color.  
**color** is the color to push.  

---

[text_layout_compute]: #text_layout_compute
<h2 id="text_layout_compute">
Procedure:
</h2>

```jai
text_layout_compute :: (
	layout_id : Text_Layout_ID
)
```

## Description:
Process the associated buffer, and compute the rectangles of each character, as well as the wrapped lines array of the text layout. `is_dirty` is set to *false*.

## Params:
**layout_id** is the id of the text layout.  
