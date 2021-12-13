# Buffer API

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
