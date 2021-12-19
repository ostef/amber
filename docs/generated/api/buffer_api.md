# Buffer API

[Buffer_ID]: #Buffer_ID
<h2 id="Buffer_ID">
Type:
</h2>

```jai
Buffer_ID :: #type, distinct u32
```

## Description:
Used to identify a buffer in the editor. You can check if a buffer exists by calling [buffer_exists].

---

[Buffer_Cursor_ID]: #Buffer_Cursor_ID
<h2 id="Buffer_Cursor_ID">
Type:
</h2>

```jai
Buffer_Cursor_ID :: #type, distinct s64
```

## Description:
Used to identify a cursor in a buffer. You can check if a cursor exists by calling [buffer_cursor_exists].

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

[Buffer_Edit_Kind]: #Buffer_Edit_Kind
<h2 id="Buffer_Edit_Kind">
Enum:
</h2>

```jai
Buffer_Edit_Kind :: enum 
{
	INSERT :: 0;
	BACKSPACE :: 1;
	DELETE :: 2;
	MOVE_LINE_UP :: 3;
	MOVE_LINE_DOWN :: 4;
	BATCH_BEGIN :: 100;
	BATCH_END :: 101;
}
```

## Description:
Describes the kind of an edit that has been made to a buffer.

## Members:
**INSERT** is an insert operation.  
**BACKSPACE** is a backspace operation.  
**DELETE** is a delete operation.  
**MOVE_LINE_UP** is a move line up operation.  
**MOVE_LINE_DOWN** is a move line down operation.  
**BATCH_BEGIN** is a batch begin operation.
When undoing or redoing a BATCH_END/BEGIN operation, everything is undone/redone until the matching BATCH_BEGIN/END operation.  
**BATCH_END** is a batch end operation.
When undoing or redoing a BATCH_END/BEGIN operation, everything is undone/redone until the matching BATCH_BEGIN/END operation.  

---

[Buffer_Edit]: #Buffer_Edit
<h2 id="Buffer_Edit">
Struct:
</h2>

```jai
Buffer_Edit :: struct 
{
	kind : Buffer_Edit_Kind;
	line_index : s64;
	cursor_id : Buffer_Cursor_ID;
	cursor : Buffer_Cursor;
	offset_in_edit_buffer : s64;
}
```

## Description:
Holds information about an edit made to a buffer.

## Members:
**kind** is the kind of edit that has been made. See [Buffer_Edit_Kind].  
**line_index** is the line index of the cursor on which the edit has been made. Used in move line up/down edits.  
**cursor_id** is the id of the cursor on which the edit has been made.  
**cursor** is the value state of the cursor when the edit has been made.  
**offset_in_edit_buffer** is the offset of the first character in the edit buffer.
The edit buffer holds the text data of the edits (see [Buffer_History]).  

---

[History_Buffering]: #History_Buffering
<h2 id="History_Buffering">
Enum:
</h2>

```jai
History_Buffering :: enum 
{
	DONT_PUSH :: 0;
	PUSH_TEXT :: 1;
	PUSH_EDIT :: 2;
}
```

## Description:
Describes how an operation should modify the buffer history.

## Members:
**DONT_PUSH** does not push a new edit to the history.  
**PUSH_TEXT** only pushes the text that was inserted/deleted.  
**PUSH_EDIT** pushes a new edit to the history, as well as the text.  

---

[EOL_Sequence]: #EOL_Sequence
<h2 id="EOL_Sequence">
Enum:
</h2>

```jai
EOL_Sequence :: enum u8 
{
	LF :: 0;
	CRLF :: 1;
	PLATFORM :: CRLF;
}
```

## Description:
Describe how lines must be ended when writing the contents of a buffer to a file.

## Members:
**LF** appends a line feed ('\n') character at ends of lines.  
**CRLF** appends a carriage return and a line feed ('\r\n') at ends of lines.  
**PLATFORM** is `CRLF` if `OS == .WINDOWS`, `LF` otherwise.  

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
buffer_exists :: (
	id : Buffer_ID
) -> bool
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
buffer_load_file :: (
	buffer_id : Buffer_ID, 
	filename : string
) -> bool
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
buffer_write_to_file :: (
	buffer_id : Buffer_ID
) -> bool
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
buffer_clear :: (
	buffer_id : Buffer_ID
)
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
buffer_history_get_edit_count :: (
	buffer_id : Buffer_ID
) -> s64
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
buffer_history_get_undo_cursor :: (
	buffer_id : Buffer_ID
) -> s64
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
buffer_clear_history :: (
	buffer_id : Buffer_ID
)
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
buffer_clear_redo_history :: (
	buffer_id : Buffer_ID
)
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
buffer_get_split :: (
	buffer_id : Buffer_ID
) -> Split_ID
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
buffer_get_text_layout :: (
	buffer_id : Buffer_ID
) -> Text_Layout_ID
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
buffer_get_language :: (
	buffer_id : Buffer_ID
) -> Language_ID
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
buffer_set_language :: (
	buffer_id : Buffer_ID, 
	language_id : Language_ID
)
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
buffer_get_filename :: (
	buffer_id : Buffer_ID, 
	allocator : Allocator
) -> string
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
buffer_set_filename :: (
	buffer_id : Buffer_ID, 
	filename : string
)
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
buffer_get_name :: (
	buffer_id : Buffer_ID, 
	allocator : Allocator
) -> string
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
buffer_set_name :: (
	buffer_id : Buffer_ID, 
	name : string
)
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
buffer_get_codepoint :: (
	buffer_id : Buffer_ID, 
	index : s64
) -> u32
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

[buffer_get_codepoint_no_abc]: #buffer_get_codepoint_no_abc
<h2 id="buffer_get_codepoint_no_abc">
Procedure:
</h2>

```jai
buffer_get_codepoint_no_abc :: (
	buffer_id : Buffer_ID, 
	index : s64
) -> u32
```

## Description:
Get the unicode codepoint at **index** in the given buffer.

## Params:
**buffer_id** is the id of the buffer.  
**index** is the index.  

## Returns:
The unicode codepoint at the given index, 0 if the index is not in the range [0; `buffer_get_count (buffer_id)` - 1].  

---

[buffer_get_count]: #buffer_get_count
<h2 id="buffer_get_count">
Procedure:
</h2>

```jai
buffer_get_count :: (
	buffer_id : Buffer_ID
) -> s64
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
buffer_cursor_exists :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> bool
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
buffer_get_cursor :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> Buffer_Cursor
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
buffer_get_cursor_line_index :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> s64
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
buffer_get_cursor_column_index :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> s64
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
buffer_cursor_is_at_bol :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> bool
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
buffer_cursor_is_at_eol :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> bool
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
buffer_get_line_count :: (
	buffer_id : Buffer_ID
) -> s64
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
buffer_get_line_length :: (
	buffer_id : Buffer_ID, 
	line_index : s64
) -> s64
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
buffer_get_eol_sequence :: (
	buffer_id : Buffer_ID
) -> EOL_Sequence
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
buffer_set_eol_sequence :: (
	buffer_id : Buffer_ID, 
	eol_sequence : EOL_Sequence
)
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
buffer_move_cursor_forward :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
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
buffer_move_cursor_backward :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
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
buffer_move_cursor_to_offset :: (
	buffer_id : Buffer_ID, 
	new_offset : s64, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to a given offset.

## Params:
**buffer_id** is the id of the buffer.  
**new_offset** is the offset to move the cursor to.  
**cursor_id** is the id of the cursor to move. This parameter cannot be `ALL_CURSORS`.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_bol]: #buffer_move_cursor_to_bol
<h2 id="buffer_move_cursor_to_bol">
Procedure:
</h2>

```jai
buffer_move_cursor_to_bol :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to the beginning of the line.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_eol]: #buffer_move_cursor_to_eol
<h2 id="buffer_move_cursor_to_eol">
Procedure:
</h2>

```jai
buffer_move_cursor_to_eol :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to the end of the line.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_previous_line]: #buffer_move_cursor_to_previous_line
<h2 id="buffer_move_cursor_to_previous_line">
Procedure:
</h2>

```jai
buffer_move_cursor_to_previous_line :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the cursor to the previous line, without changing the column index. If the cursor is already at the first line, move it to the beginning of the line.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_next_line]: #buffer_move_cursor_to_next_line
<h2 id="buffer_move_cursor_to_next_line">
Procedure:
</h2>

```jai
buffer_move_cursor_to_next_line :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the cursor to the next line, without changing the column index. If the cursor is already at the last line, move it to the end of the line.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_line]: #buffer_move_cursor_to_line
<h2 id="buffer_move_cursor_to_line">
Procedure:
</h2>

```jai
buffer_move_cursor_to_line :: (
	buffer_id : Buffer_ID, 
	line : s64, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to a new line index.

## Params:
**buffer_id** is the id of the buffer.  
**line_index** is the new line index to move the cursor to.
This parameter can be any signed integer, the cursor will stop at the first or last line in the buffer if the line index is outside the boundaries of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter cannot be `ALL_CURSORS`.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_column]: #buffer_move_cursor_to_column
<h2 id="buffer_move_cursor_to_column">
Procedure:
</h2>

```jai
buffer_move_cursor_to_column :: (
	buffer_id : Buffer_ID, 
	column_index : s64, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to a new column index.

## Params:
**buffer_id** is the id of the buffer.  
**column_index** is the new column index to move the cursor to.
This parameter can be any signed integer, the cursor will stop at the beginning or end of the line if the column index is outside the line boundaries.  
**cursor_id** is the id of the cursor to move. This parameter cannot be `ALL_CURSORS`.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_line_and_column]: #buffer_move_cursor_to_line_and_column
<h2 id="buffer_move_cursor_to_line_and_column">
Procedure:
</h2>

```jai
buffer_move_cursor_to_line_and_column :: (
	buffer_id : Buffer_ID, 
	line_index : s64, 
	column_index : s64, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to a new line and column index.

## Params:
**buffer_id** is the id of the buffer.  
**line_index** is the new line index to move the cursor to.
This parameter can be any signed integer, the cursor will stop at the first or last line in the buffer if the line index is outside the boundaries of the buffer.  
**column_index** is the new column index to move the cursor to.
This parameter can be any signed integer, the cursor will stop at the beginning or end of the line if the column index is outside the line boundaries.  
**cursor_id** is the id of the cursor to move. This parameter cannot be `ALL_CURSORS`.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_beginning]: #buffer_move_cursor_to_beginning
<h2 id="buffer_move_cursor_to_beginning">
Procedure:
</h2>

```jai
buffer_move_cursor_to_beginning :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to the beginning of the buffer.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter cannot be `ALL_CURSORS`.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_move_cursor_to_end]: #buffer_move_cursor_to_end
<h2 id="buffer_move_cursor_to_end">
Procedure:
</h2>

```jai
buffer_move_cursor_to_end :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the given cursor to the end of the buffer.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to move. This parameter cannot be `ALL_CURSORS`.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_skip_word_forward]: #buffer_skip_word_forward
<h2 id="buffer_skip_word_forward">
Procedure:
</h2>

```jai
buffer_skip_word_forward :: (
	buffer_id : Buffer_ID, 
	stop_at_word_separators : bool, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the cursor with id **cursor_id** forward to the next alpha numeric boundary, treating end of lines as alpha numeric boundaries.

## Params:
**buffer_id** is the id of the buffer.  
**stop_at_word_separators** treat '_' as alpha numeric boundary.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared and the cursor is not moved if the selection is not 0.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_skip_word_backward]: #buffer_skip_word_backward
<h2 id="buffer_skip_word_backward">
Procedure:
</h2>

```jai
buffer_skip_word_backward :: (
	buffer_id : Buffer_ID, 
	stop_at_word_separators : bool, 
	cursor_id : Buffer_Cursor_ID, 
	select : bool
) -> bool
```

## Description:
Move the cursor with id **cursor_id** backward to the previous alpha numeric boundary, treating end of lines as alpha numeric boundaries.

## Params:
**buffer_id** is the id of the buffer.  
**stop_at_word_separators** treat '_' as alpha numeric boundary.  
**cursor_id** is the id of the cursor to move. This parameter can be `ALL_CURSORS` to move all cursors.  
**select** is set to *true* to select text while moving the cursor, *false* otherwise.
If this parameter is set to *false*, then the selection is cleared and the cursor is not moved if the selection is not 0.  

## Returns:
*true* if the cursor was modified (it has been moved, or the selection was cleared), *false* otherwise.  

---

[buffer_clear_selection]: #buffer_clear_selection
<h2 id="buffer_clear_selection">
Procedure:
</h2>

```jai
buffer_clear_selection :: (
	buffer_id : Buffer_ID
)
```

## Description:
Clear the selection of all the cursors in the buffer.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_clear_cursors]: #buffer_clear_cursors
<h2 id="buffer_clear_cursors">
Procedure:
</h2>

```jai
buffer_clear_cursors :: (
	buffer_id : Buffer_ID
)
```

## Description:
Remove all cursors except the write head.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_merge_duplicate_cursors]: #buffer_merge_duplicate_cursors
<h2 id="buffer_merge_duplicate_cursors">
Procedure:
</h2>

```jai
buffer_merge_duplicate_cursors :: (
	buffer_id : Buffer_ID
)
```

## Description:
Merge all cursors that overlap each other, including their selections.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_sort_cursors_by_offset]: #buffer_sort_cursors_by_offset
<h2 id="buffer_sort_cursors_by_offset">
Procedure:
</h2>

```jai
buffer_sort_cursors_by_offset :: (
	buffer_id : Buffer_ID
)
```

## Description:
Sort additional cursors by their offset in ascending order. The write head has a fixed index, so it cannot be moved and it has to be treated with a special case when iterating in a sorted manner.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_add_cursor_at_offset]: #buffer_add_cursor_at_offset
<h2 id="buffer_add_cursor_at_offset">
Procedure:
</h2>

```jai
buffer_add_cursor_at_offset :: (
	buffer_id : Buffer_ID, 
	target_offset : s64
) -> bool
```

## Description:
Create an additional cursor at the given offset, if it does not overlap another cursor (including its selection).

## Params:
**buffer_id** is the id of the buffer.  
**target_offset** is the offset of the cursor to create. This is effectively clamped to the boundaries of the buffer.  

## Returns:
*true* if a new cursor was added, *false* otherwise. If the cursor was not added, it is because would have overlapped another cursor, including its selection.  

---

[buffer_add_cursor_on_previous_line]: #buffer_add_cursor_on_previous_line
<h2 id="buffer_add_cursor_on_previous_line">
Procedure:
</h2>

```jai
buffer_add_cursor_on_previous_line :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> bool
```

## Description:
Create an additional cursor at the line above the given cursor, if it does not overlap another cursor (including its selection).

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the reference cursor. This parameter can be `ALL_CURSORS` to add a new cursor above all the cursors in the buffer at the time this function was called.  

## Returns:
*true* if at least one cursor was added, *false* otherwise. If a cursor was not added, it is because would have overlapped another cursor, including its selection, or the reference cursor is on the first line in the buffer.  

---

[buffer_add_cursor_on_next_line]: #buffer_add_cursor_on_next_line
<h2 id="buffer_add_cursor_on_next_line">
Procedure:
</h2>

```jai
buffer_add_cursor_on_next_line :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
) -> bool
```

## Description:
Create an additional cursor at the line below the given cursor, if it does not overlap another cursor (including its selection).

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the reference cursor. This parameter can be `ALL_CURSORS` to add a new cursor below all the cursors in the buffer at the time this function was called.  

## Returns:
*true* if at least one cursor was added, *false* otherwise. If a cursor was not added, it is because would have overlapped another cursor, including its selection, or the reference cursor is on the last line in the buffer.  

---

[buffer_remove_cursor]: #buffer_remove_cursor
<h2 id="buffer_remove_cursor">
Procedure:
</h2>

```jai
buffer_remove_cursor :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID
)
```

## Description:
Remove the cursor with the given id in the buffer. The order of the cursors is preserved. This parameter cannot be `WRITE_HEAD` `ALL_CURSORS` (prefer [buffer_clear_cursors] for that).

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor to remove.  

---

[buffer_history_push_edit]: #buffer_history_push_edit
<h2 id="buffer_history_push_edit">
Procedure:
</h2>

```jai
buffer_history_push_edit :: (
	buffer_id : Buffer_ID, 
	kind : Buffer_Edit_Kind, 
	cursor_id : Buffer_Cursor_ID
) -> *Buffer_Edit
```

## Description:
Push a new edit to the buffer history. The properties of the [Buffer_Edit] are filled appropriately.

## Params:
**buffer_id** is the id of the buffer.  
**kind** is the kind of edit to push.  
**cursor_id** is the id of the cursors on which the edit was made. This parameter must be set to `ALL_CURSORS` for edit kinds `BATCH_BEGIN`, `BATCH_END` (prefer [buffer_begin_batch_edit] and [buffer_end_batch_edit] for these kinds of edits).  

## Returns:
A pointer to the newly added Buffer_Edit.  

---

[buffer_history_push_char]: #buffer_history_push_char
<h2 id="buffer_history_push_char">
Procedure:
</h2>

```jai
buffer_history_push_char :: (
	buffer_id : Buffer_ID, 
	codepoint : u32
)
```

## Description:
Push a character to the buffer history edit buffer.

## Params:
**buffer_id** is the id of the buffer.  
**codepoint** is the Unicode codepoint to push into the edit buffer.  

---

[buffer_history_push_text]: #buffer_history_push_text
<h2 id="buffer_history_push_text">
Procedure:
</h2>

```jai
buffer_history_push_text :: (
	buffer_id : Buffer_ID, 
	text : 
)
```

## Description:
Push text to the buffer history edit buffer.

## Params:
**buffer_id** is the id of the buffer.  
**text** is the Unicode codepoints to push into the edit buffer.  

---

[buffer_begin_batch_edit]: #buffer_begin_batch_edit
<h2 id="buffer_begin_batch_edit">
Procedure:
</h2>

```jai
buffer_begin_batch_edit :: (
	buffer_id : Buffer_ID
)
```

## Description:
Push a new `BATCH_BEGIN` edit to the buffer history.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_end_batch_edit]: #buffer_end_batch_edit
<h2 id="buffer_end_batch_edit">
Procedure:
</h2>

```jai
buffer_end_batch_edit :: (
	buffer_id : Buffer_ID
)
```

## Description:
Push a new `BATCH_END` edit to the buffer history.

## Params:
**buffer_id** is the id of the buffer.  

---

[buffer_insert_at_cursor]: #buffer_insert_at_cursor
<h2 id="buffer_insert_at_cursor">
Procedure:
</h2>

```jai
buffer_insert_at_cursor :: (
	buffer_id : Buffer_ID, 
	codepoint : u32, 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
)
```

## Description:
Insert a Unicode codepoint to the buffer, at the given cursor.

## Params:
**buffer_id** is the id of the buffer.  
**codepoint** is the Unicode codepoint to insert.  
**cursor_id** is the cursor id at which to insert the codepoint. This parameter can be `ALL_CURSORS` to insert a character at all cursors.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

---

[buffer_insert_text_at_cursor]: #buffer_insert_text_at_cursor
<h2 id="buffer_insert_text_at_cursor">
Procedure:
</h2>

```jai
buffer_insert_text_at_cursor :: (
	buffer_id : Buffer_ID, 
	text : , 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
)
```

## Description:
Insert Unicode text to the buffer, at the given cursor.

## Params:
**buffer_id** is the id of the buffer.  
**text** is the Unicode text to insert.  
**cursor_id** is the cursor id at which to insert the codepoint. This parameter can be `ALL_CURSORS` to insert text at all cursors.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

---

[buffer_insert_utf8_text_at_cursor]: #buffer_insert_utf8_text_at_cursor
<h2 id="buffer_insert_utf8_text_at_cursor">
Procedure:
</h2>

```jai
buffer_insert_utf8_text_at_cursor :: (
	buffer_id : Buffer_ID, 
	text : string, 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
)
```

## Description:
Insert UTF-8 text to the buffer, at the given cursor.

## Params:
**buffer_id** is the id of the buffer.  
**text** is the UTF-8 text to insert.  
**cursor_id** is the cursor id at which to insert the codepoint. This parameter can be `ALL_CURSORS` to insert text at all cursors.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

---

[buffer_delete_selection]: #buffer_delete_selection
<h2 id="buffer_delete_selection">
Procedure:
</h2>

```jai
buffer_delete_selection :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
) -> bool
```

## Description:
Delete the selected text at the given cursor, or the character at the cursor if the selection is 0.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the cursor id at which to delete the selection. This parameter can be `ALL_CURSORS` to delete selection at all cursors.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

## Returns:
*true* if at least one character was deleted, *false* otherwise.  

---

[buffer_backspace_selection]: #buffer_backspace_selection
<h2 id="buffer_backspace_selection">
Procedure:
</h2>

```jai
buffer_backspace_selection :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
) -> bool
```

## Description:
Delete the character at the right of the cursor, unless the selection is not 0, in which case [buffer_delete_selection] is called instead.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the cursor id at which to backspace the selection. This parameter can be `ALL_CURSORS` to backspace selection at all cursors.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

## Returns:
*true* if at least one character was deleted, *false* otherwise.  

---

[buffer_move_line_up]: #buffer_move_line_up
<h2 id="buffer_move_line_up">
Procedure:
</h2>

```jai
buffer_move_line_up :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
) -> bool
```

## Description:
Move the line the given cursor is on by one towards the beginning of the buffer.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor. This parameter can be `ALL_CURSORS` to move all the lines that have at least one cursor on them. The algorithm sorts the cursors in ascending offset order if **cursor_id** is `ALL_CURSORS`.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

## Returns:
*true* if at least one line was moved, *false* otherwise.  

---

[buffer_move_line_down]: #buffer_move_line_down
<h2 id="buffer_move_line_down">
Procedure:
</h2>

```jai
buffer_move_line_down :: (
	buffer_id : Buffer_ID, 
	cursor_id : Buffer_Cursor_ID, 
	history_buffering : History_Buffering
) -> bool
```

## Description:
Move the line the given cursor is on by one towards the end of the buffer.

## Params:
**buffer_id** is the id of the buffer.  
**cursor_id** is the id of the cursor. This parameter can be `ALL_CURSORS` to move all the lines that have at least one cursor on them. The algorithm sorts the cursors in ascending offset order if **cursor_id** is `ALL_CURSORS`.  
**history_buffering** is the kind of history buffering to do for this operation (see [History_Buffering] for more information).  

## Returns:
*true* if at least one line was moved, *false* otherwise.  

---

[buffer_undo_last_edit]: #buffer_undo_last_edit
<h2 id="buffer_undo_last_edit">
Procedure:
</h2>

```jai
buffer_undo_last_edit :: (
	buffer_id : Buffer_ID
) -> bool
```

## Description:
Undo the last edit in the buffer history. Batch edits are handled as expected.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
*true* if an edit was undone, *false* otherwise.  

---

[buffer_redo_last_edit]: #buffer_redo_last_edit
<h2 id="buffer_redo_last_edit">
Procedure:
</h2>

```jai
buffer_redo_last_edit :: (
	buffer_id : Buffer_ID
) -> bool
```

## Description:
Redo the last edit in the buffer history. Batch edits are handled as expected.

## Params:
**buffer_id** is the id of the buffer.  

## Returns:
*true* if an edit was redone, *false* otherwise.  
