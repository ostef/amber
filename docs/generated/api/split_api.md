# Split API

[Split_ID]: #Split_ID
<h2 id="Split_ID">
Type:
</h2>

```jai
Split_ID :: #type, distinct u32
```

## Description:
Used to identify a split in the editor. You can check if a split exists by calling [split_exists].

---

[get_split_count]: #get_split_count
<h2 id="get_split_count">
Procedure:
</h2>

```jai
get_split_count :: () -> s64
```

## Description:
Ask the editor for the total number of splits.

## Returns:
The number of splits in the editor.  

---

[get_active_split]: #get_active_split
<h2 id="get_active_split">
Procedure:
</h2>

```jai
get_active_split :: () -> Split_ID
```

## Description:
Ask the editor for the id of the currently active split.

## Returns:
The id of the active split.  

---

[set_active_split]: #set_active_split
<h2 id="set_active_split">
Procedure:
</h2>

```jai
set_active_split :: (
	split_id : Split_ID
)
```

## Description:
Set the active split in the editor.

## Params:
**id** is the id of the new split.  

---

[split_exists]: #split_exists
<h2 id="split_exists">
Procedure:
</h2>

```jai
split_exists :: (
	id : Split_ID
) -> bool
```

## Description:
Ask the editor if a split with a given id exists.

## Params:
**id** is the id of the split.  

## Returns:
*true* if the split exists, *false* otherwise.  

---

[split_open_buffer]: #split_open_buffer
<h2 id="split_open_buffer">
Procedure:
</h2>

```jai
split_open_buffer :: (
	split_id : Split_ID
) -> Buffer_ID
```

## Description:
Open a new buffer in the split, with a newly created text layout. The name of the buffer is set to '(unnamed)'.

## Params:
**split_id** is the id of the split.  

## Returns:
The id of the newly opened buffer.  

---

[split_close_buffer]: #split_close_buffer
<h2 id="split_close_buffer">
Procedure:
</h2>

```jai
split_close_buffer :: (
	split_id : Split_ID, 
	buffer_index : s64
)
```

## Description:
Close an opened buffer in the split. The associated text layout is destroyed as well.

## Params:
**split_id** is the id of the split.  
**buffer_index** is the index of the buffer to close in the split.  

---

[split_get_area]: #split_get_area
<h2 id="split_get_area">
Procedure:
</h2>

```jai
split_get_area :: (
	split_id : Split_ID
) -> Rectf
```

## Description:
Get the area used by the split.

## Params:
**split_id** is the id of the split.  

## Returns:
The split area.  

---

[split_set_area]: #split_set_area
<h2 id="split_set_area">
Procedure:
</h2>

```jai
split_set_area :: (
	split_id : Split_ID, 
	area : Rectf
)
```

## Description:
Set the area of the split.

## Params:
**split_id** is the id of the split.  
**area** is the new area.  

---

[split_get_text_layout_area]: #split_get_text_layout_area
<h2 id="split_get_text_layout_area">
Procedure:
</h2>

```jai
split_get_text_layout_area :: (
	split_id : Split_ID
) -> Rectf
```

## Description:
Get the area the can be used by the text layout, removing the bottom info bar from the split area. This is *not* the actual area stored by the text layout.

## Params:
**split_id** is the id of the split.  

## Returns:
The area that can be used by the text layout.  

---

[split_get_buffer_count]: #split_get_buffer_count
<h2 id="split_get_buffer_count">
Procedure:
</h2>

```jai
split_get_buffer_count :: (
	split_id : Split_ID
) -> s64
```

## Description:
Get the number of opened buffers in the split.

## Params:
**split_id** is the id of the split.  

## Returns:
The number of opened buffers.  

---

[split_get_buffer]: #split_get_buffer
<h2 id="split_get_buffer">
Procedure:
</h2>

```jai
split_get_buffer :: (
	split_id : Split_ID, 
	index : s64
) -> Buffer_ID
```

## Description:
Get the id of the given buffer in the split.

## Params:
**split_id** is the id of the split.  
**index** is the index of the buffer in the split.  

## Returns:
The buffer id at **index**.  

---

[split_get_active_buffer_index]: #split_get_active_buffer_index
<h2 id="split_get_active_buffer_index">
Procedure:
</h2>

```jai
split_get_active_buffer_index :: (
	split_id : Split_ID
) -> s64
```

## Description:
Get the index of the active buffer opened in the split.

## Params:
**split_id** is the id of the split.  

## Returns:
The index of the active buffer.  

---

[split_set_active_buffer]: #split_set_active_buffer
<h2 id="split_set_active_buffer">
Procedure:
</h2>

```jai
split_set_active_buffer :: (
	split_id : Split_ID, 
	buffer_index : s64
)
```

## Description:
Set the active buffer index of the split.

## Params:
**split_id** is the id of the split.  
**buffer_index** is the index of the new active buffer.  

---

[split_get_active_buffer]: #split_get_active_buffer
<h2 id="split_get_active_buffer">
Procedure:
</h2>

```jai
split_get_active_buffer :: (
	split_id : Split_ID
) -> Buffer_ID
```

## Description:
Get the id of the active buffer opened in the split.

## Params:
**split_id** is the id of the split.  

## Returns:
The id of the active buffer.  

---

[split_get_active_text_layout]: #split_get_active_text_layout
<h2 id="split_get_active_text_layout">
Procedure:
</h2>

```jai
split_get_active_text_layout :: (
	split_id : Split_ID
) -> Text_Layout_ID
```

## Description:
Get the id of the active text layout in the split.

## Returns:
The id of the active text layout.  

---

[split_create_first]: #split_create_first
<h2 id="split_create_first">
Procedure:
</h2>

```jai
split_create_first :: () -> Split_ID
```

## Description:
Create the first split in the editor. Call this function when there is no split opened.

## Returns:
The id of the newly created split.  

---

[split_create_left]: #split_create_left
<h2 id="split_create_left">
Procedure:
</h2>

```jai
split_create_left :: (
	split_id : Split_ID
) -> Split_ID
```

## Description:
Create a new split at the left of the given split. The split width is halved.

## Params:
**split_id** is the id of the split.  

## Returns:
The newly created split.  

---

[split_create_right]: #split_create_right
<h2 id="split_create_right">
Procedure:
</h2>

```jai
split_create_right :: (
	split_id : Split_ID
) -> Split_ID
```

## Description:
Create a new split at the right of the given split. The split width is halved.

## Params:
**split_id** is the id of the split.  

## Returns:
The newly created split.  

---

[split_create_above]: #split_create_above
<h2 id="split_create_above">
Procedure:
</h2>

```jai
split_create_above :: (
	split_id : Split_ID
) -> Split_ID
```

## Description:
Create a new split above the given split. The split height is halved.

## Params:
**split_id** is the id of the split.  

## Returns:
The newly created split.  

---

[split_create_below]: #split_create_below
<h2 id="split_create_below">
Procedure:
</h2>

```jai
split_create_below :: (
	split_id : Split_ID
) -> Split_ID
```

## Description:
Create a new split below the given split. The split height is halved.

## Params:
**split_id** is the id of the split.  

## Returns:
The newly created split.  

---

[split_merge]: #split_merge
<h2 id="split_merge">
Procedure:
</h2>

```jai
split_merge :: (
	split_id : Split_ID
) -> Split_ID
```

## Description:
Merge the given split with the closest split.

## Params:
**split_id** is the id of the split.  

## Returns:
The id of the split which was merged with the given split.  

---

[split_get_scrollbar_rect]: #split_get_scrollbar_rect
<h2 id="split_get_scrollbar_rect">
Procedure:
</h2>

```jai
split_get_scrollbar_rect :: (
	split_id : Split_ID
) -> Rectf
```

## Description:
Get the rect of the split scrollbar on the screen.

## Params:
**split_id** is the id of the split.  

## Returns:
The rect of the scrollbar.  

---

[split_get_tab_rect]: #split_get_tab_rect
<h2 id="split_get_tab_rect">
Procedure:
</h2>

```jai
split_get_tab_rect :: (
	split_id : Split_ID, 
	buffer_index : s64
) -> Rectf
```

## Description:
Get the rect of buffer's tab caption.

## Params:
**split_id** is the id of the split.  
**buffer_index** is the indexx of the buffer.  

## Returns:
The rect of the buffer tab caption.  
