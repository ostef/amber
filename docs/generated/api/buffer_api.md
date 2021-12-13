# Buffer API

[Buffer_ID]: #Buffer_ID
<h2 id="Buffer_ID">
Type:
</h2>

```jai
// Declaration goes here
```

## Description:
Used to identify a buffer in the editor. You can check if a buffer exists by calling [buffer_exists].

---

[Buffer_Cursor_ID]: #Buffer_Cursor_ID
<h2 id="Buffer_Cursor_ID">
Type:
</h2>

```jai
// Declaration goes here
```

## Description:
Used to identifier a cursor in a buffer. You can check if a cursor exists by calling [buffer_cursor_exists].

---

[Buffer_Cursor]: #Buffer_Cursor
<h2 id="Buffer_Cursor">
Struct:
</h2>

```jai
Buffer_Cursor :: struct
{
	offset : s64;
	selection : s64;
}
```

## Description:
Holds information about a buffer cursor. Cursors are identified by a [Buffer_Cursor_ID].

## Members:
**offset** is the offset of the cursor in the buffer, in the range [0; buffer count - 1].  
**selection** is the selection of the cursor. If **selection** is negative, then the selection goes backwards, if it is positive then the selection goes forward.  

---

[get_buffer_count]: #get_buffer_count
<h2 id="get_buffer_count">
Procedure:
</h2>

```jai
get_buffer_count :: () -> s64
```

## Description:
Ask the editor for the total number of opened buffers.

## Returns:
The number of opened buffers in the editor.  

---

[get_active_buffer]: #get_active_buffer
<h2 id="get_active_buffer">
Procedure:
</h2>

```jai
get_active_buffer :: () -> Buffer_ID
```

## Description:
Ask the editor for the id of the currently active buffer.
Shorthand for `split_get_active_buffer (get_active_split ())`.

## Returns:
The id of the active buffer.  

---

[buffer_exists]: #buffer_exists
<h2 id="buffer_exists">
Procedure:
</h2>

```jai
buffer_exists :: (id : Buffer_ID) -> bool
```

## Description:
Ask the editor if a buffer with a given id exists.

## Params:
**id** is the id of the buffer.  

## Returns:
*true* if the buffer exists, *false* otherwise.  

---

[buffer_load_file]: #buffer_load_file
<h2 id="buffer_load_file">
Procedure:
</h2>

```jai
buffer_load_file :: (buffer_id : Buffer_ID, filename : string) -> bool
```

## Description:
Load a file to the given buffer. If the file can't be opened, the function fails and the buffer is not modified.

## Params:
**buffer_id** is the id of the buffer.  
**filename** is the file name of the file to load.  

## Returns:
*true* on success, *false* otherwise.  

---

[buffer_write_to_file]: #buffer_write_to_file
<h2 id="buffer_write_to_file">
Procedure:
</h2>

```jai
buffer_write_to_file :: (buffer_id : Buffer_ID) -> bool
```

## Description:
Write the contents of a buffer to its associated file. If no file is associated with the buffer, the function fails and the return value is *false*.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
*true* on success, *false* otherwise.  

---

[buffer_clear]: #buffer_clear
<h2 id="buffer_clear">
Procedure:
</h2>

```jai
buffer_clear :: (buffer_id : Buffer_ID)
```

## Description:
Clear the given buffer, as well as its history. All cursors are removed and the write head is moved to offset 0. No memory is freed, and the `filename` and `name` of the buffer remain untouched.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_history_get_edit_count]: #buffer_history_get_edit_count
<h2 id="buffer_history_get_edit_count">
Procedure:
</h2>

```jai
buffer_history_get_edit_count :: (buffer_id : Buffer_ID) -> s64
```

## Description:
Get the number of edits in the buffer history.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The total number of individual edits in the history, including `BATCH_BEGIN` and `BATCH_END` edits. See [Buffer History] for more information.  

---

[buffer_history_get_undo_cursor]: #buffer_history_get_undo_cursor
<h2 id="buffer_history_get_undo_cursor">
Procedure:
</h2>

```jai
buffer_history_get_undo_cursor :: (buffer_id : Buffer_ID) -> s64
```

## Description:
Get the undo cursor of the buffer history. The undo cursor is the index of the last undone edit. See [Buffer History] for more information.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The undo cursor of the buffer history.  

---

[buffer_clear_history]: #buffer_clear_history
<h2 id="buffer_clear_history">
Procedure:
</h2>

```jai
buffer_clear_history :: (buffer_id : Buffer_ID)
```

## Description:
Clear the buffer history, the memory allocated for the edit stack and edit text buffer is not freed.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_clear_redo_history]: #buffer_clear_redo_history
<h2 id="buffer_clear_redo_history">
Procedure:
</h2>

```jai
buffer_clear_redo_history :: (buffer_id : Buffer_ID)
```

## Description:
Clear the redo history of the buffer, effectively setting the edit count to the undo cursor. See [Buffer History] for more information.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_get_split]: #buffer_get_split
<h2 id="buffer_get_split">
Procedure:
</h2>

```jai
buffer_get_split :: (buffer_id : Buffer_ID) -> Split_ID
```

## Description:
Get the split this buffer is attached to. See [Splits] for more information.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The id of the split this buffer is attached to.  

---

[buffer_get_text_layout]: #buffer_get_text_layout
<h2 id="buffer_get_text_layout">
Procedure:
</h2>

```jai
buffer_get_text_layout :: (buffer_id : Buffer_ID) -> Text_Layout_ID
```

## Description:
Get the text layout associated with the buffer. See [Text Layouts] for more information.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The id of the text layout associated with the buffer.  

---

[buffer_get_language]: #buffer_get_language
<h2 id="buffer_get_language">
Procedure:
</h2>

```jai
buffer_get_language :: (buffer_id : Buffer_ID) -> Language_ID
```

## Description:
Get the language associated with the buffer. See [Languages] for more information.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The id of the language associated with the buffer.  

---

[buffer_set_language]: #buffer_set_language
<h2 id="buffer_set_language">
Procedure:
</h2>

```jai
buffer_set_language :: (buffer_id : Buffer_ID, language_id : Language_ID)
```

## Description:
Set the language associated with the buffer. See [Languages] for more information.

## Params:
**buffer_id** is the id of the buffer.  
**language_id** is the id of the language.  

---

[buffer_get_filename]: #buffer_get_filename
<h2 id="buffer_get_filename">
Procedure:
</h2>

```jai
buffer_get_filename :: (buffer_id : Buffer_ID, allocator : Allocator) -> string
```

## Description:
Get a clone of the filename of the buffer, allocated with **allocator**.

## Params:
**buffer_id** is the id of the buffer.  
**allocator** is the allocator used to allocate the string.  

## Returns:
A clone of the buffer's filename, newly allocated.  

---

[buffer_set_filename]: #buffer_set_filename
<h2 id="buffer_set_filename">
Procedure:
</h2>

```jai
buffer_set_filename :: (buffer_id : Buffer_ID, filename : string)
```

## Description:
Set the filename of the buffer to **filename**. The buffer language is detected from the filename and automatically changed.

## Params:
**buffer_id** is the id of the buffer.  
**filename** is the new filename.  

---

[buffer_get_name]: #buffer_get_name
<h2 id="buffer_get_name">
Procedure:
</h2>

```jai
buffer_get_name :: (buffer_id : Buffer_ID, allocator : Allocator) -> string
```

## Description:
Get a clone of the name of the buffer, allocated with **allocator**.

## Params:
**buffer_id** is the id of the buffer.  
**allocator** is the allocator used to allocate the string.  

## Returns:
A clone of the buffer's name, newly allocated.  

---

[buffer_set_name]: #buffer_set_name
<h2 id="buffer_set_name">
Procedure:
</h2>

```jai
buffer_set_name :: (buffer_id : Buffer_ID, name : string)
```

## Description:
Set the name of the buffer to **name**.

## Params:
**buffer_id** is the id of the buffer.  
**name** is the new name.  

---

[buffer_get_codepoint]: #buffer_get_codepoint
<h2 id="buffer_get_codepoint">
Procedure:
</h2>

```jai
buffer_get_codepoint :: (buffer_id : Buffer_ID, index : s64) -> u32
```

## Description:
Get the unicode codepoint at **index** in the given buffer.
The index has to be in the range [0; `buffer_get_count (buffer_id)`).

## Params:
**buffer_id** is the id of the buffer.  
**index** is the index in the range [0; `buffer_get_count (buffer_id)` - 1].  

## Returns:
The unicode codepoint at the given index.  

---

[buffer_get_count]: #buffer_get_count
<h2 id="buffer_get_count">
Procedure:
</h2>

```jai
buffer_get_count :: (buffer_id : Buffer_ID) -> s64
```

## Description:
Get the number of characters in the buffer.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The number of characters in the buffer.  

---

[buffer_cursor_exists]: #buffer_cursor_exists
<h2 id="buffer_cursor_exists">
Procedure:
</h2>

```jai
buffer_cursor_exists :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
```

## Description:
Ask the editor if the given cursor id is valid for the buffer.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the cursor id to query.  

## Returns:
*true* if the cursor exists, *false* otherwise.  

---

[buffer_get_cursor]: #buffer_get_cursor
<h2 id="buffer_get_cursor">
Procedure:
</h2>

```jai
buffer_get_cursor :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> Buffer_Cursor
```

## Description:
Get the cursor with id **cursor_id** in the buffer.
The cursor has to exist (see [buffer_cursor_exists]).

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the cursor id to query. This parameter cannot be `ALL_CURSORS`.  

## Returns:
The cursor information, as a [Buffer_Cursor].  

---

[buffer_get_cursor_line_index]: #buffer_get_cursor_line_index
<h2 id="buffer_get_cursor_line_index">
Procedure:
</h2>

```jai
buffer_get_cursor_line_index :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> s64
```

## Description:
Get the line index position of the given cursor in the buffer.
Currently, the line index and column index is only cached for the write head, so getting this information for other cursors require recalculation each time.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to query for line index. This parameter cannot be `ALL_CURSORS`.  

## Returns:
The line index position of the given cursor.
Line indices are in the range [0, `buffer_get_line_count (buffer_id)` - 1].  

---

[buffer_get_cursor_column_index]: #buffer_get_cursor_column_index
<h2 id="buffer_get_cursor_column_index">
Procedure:
</h2>

```jai
buffer_get_cursor_column_index :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> s64
```

## Description:
Get the column index position of the given cursor in the buffer.
Currently, the line index and column index is only cached for the write head, so getting this information for other cursors require recalculation each time.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to query for column index. This parameter cannot be `ALL_CURSORS`.  

## Returns:
The column index position of the given cursor. Column indices start from 0, to the length of the line minus one.  

---

[buffer_cursor_is_at_bol]: #buffer_cursor_is_at_bol
<h2 id="buffer_cursor_is_at_bol">
Procedure:
</h2>

```jai
buffer_cursor_is_at_bol :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
```

## Description:
Ask the editor if the given cursor is at the beginning of the line.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to query. This parameter cannot be `ALL_CURSORS`.  

## Returns:
*true* if the cursor is at the beginning of the line, *false* otherwise.  

---

[buffer_cursor_is_at_eol]: #buffer_cursor_is_at_eol
<h2 id="buffer_cursor_is_at_eol">
Procedure:
</h2>

```jai
buffer_cursor_is_at_eol :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID) -> bool
```

## Description:
Ask the editor if the given cursor is at the end of the line.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to query. This parameter cannot be `ALL_CURSORS`.  

## Returns:
*true* if the cursor is at the end of the line, *false* otherwise.  

---

[buffer_get_line_count]: #buffer_get_line_count
<h2 id="buffer_get_line_count">
Procedure:
</h2>

```jai
buffer_get_line_count :: (buffer_id : Buffer_ID) -> s64
```

## Description:
Get the number of lines in the buffer.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The number of lines in the buffer.  

---

[buffer_get_line_length]: #buffer_get_line_length
<h2 id="buffer_get_line_length">
Procedure:
</h2>

```jai
buffer_get_line_length :: (buffer_id : Buffer_ID, line_index : s64) -> s64
```

## Description:
Get the length of the line with index **line_index** in the buffer.

## Params:
**buffer_id** is the id of the buffer.  
**line_index** is the index of the line to query, in the range [0; `buffer_get_line_count (buffer_id) - 1`].  

## Returns:
The length of the given line.  

---

[buffer_get_eol_sequence]: #buffer_get_eol_sequence
<h2 id="buffer_get_eol_sequence">
Procedure:
</h2>

```jai
buffer_get_eol_sequence :: (buffer_id : Buffer_ID) -> EOL_Sequence
```

## Description:
Get the EOL sequence the buffer uses when writing to file (see [buffer_write_to_file], [EOL_Sequence]).

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
The EOL sequence of the buffer.  

---

[buffer_set_eol_sequence]: #buffer_set_eol_sequence
<h2 id="buffer_set_eol_sequence">
Procedure:
</h2>

```jai
buffer_set_eol_sequence :: (buffer_id : Buffer_ID, eol_sequence : EOL_Sequence)
```

## Description:
Set the EOL sequence the buffer uses when writing to file (see [buffer_write_to_file], [EOL_Sequence]).

## Params:
**buffer_id** is the id of the buffer.  
**eol_sequence** is the new eol sequence.  

---

[buffer_move_cursor_forward]: #buffer_move_cursor_forward
<h2 id="buffer_move_cursor_forward">
Procedure:
</h2>

```jai
buffer_move_cursor_forward :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select : bool) -> bool
```

## Description:
Move the cursor with id **cursor_id** forward by one character.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared and the cursor is not moved if the selection is not 0.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_backward]: #buffer_move_cursor_backward
<h2 id="buffer_move_cursor_backward">
Procedure:
</h2>

```jai
buffer_move_cursor_backward :: (buffer_id : Buffer_ID, cursor_id : Buffer_Cursor_ID, select : bool) -> bool
```

## Description:
Move the cursor with id **cursor_id** backward by one character.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared and the cursor is not moved if the selection is not 0.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_offset]: #buffer_move_cursor_to_offset
<h2 id="buffer_move_cursor_to_offset">
Procedure:
</h2>

```jai
buffer_move_cursor_to_offset :: (buffer_id : Buffer_ID, new_offset : s64, cursor_id : Buffer_Cursor_ID, select : bool) -> bool
```

## Description:
Move the given cursor to a given offset.

## Params:
**buffer_id** is the id of the buffer.  
**new_offset** is the offset to move the cursor to.  
**cursor_id** is the id of the cursor to move.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared and the cursor is not moved if the selection is not 0.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  
