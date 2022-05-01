// A view on a buffer of text. There can be multiple views
// on the same buffer, for example when the same buffer is
// on screen twice, side by side like programmers often do.
// It does not have to refer to something that is actually
// on the screen, for example we might imagine a view that
// is on somebody else's computer, when working with someone
// else, or more simply a view that is not currently visible.
View :: struct
{
	Global_Id :: type_of (g_views).Slot_Info;	// Global view Id, across all view types

	Cursor :: struct
	{
		char_index : s64;
		selection  : s64;
	}

	ALL_CURSORS :: -1;

	global_id : Global_Id;
	type : Type;	// Actual Jai type
	buffer_id : Buffer.Id;
	has_write_access : bool;
	cursors : [..]Cursor;
}

get_cursor_line_and_column :: (using view : View, cursor_index : s64) -> line_index : s64, column_index : s64
{
	cursor := cursors[cursor_index];
	buffer := get (buffer_id);
	line_index, column_index := get_line_and_column (buffer, cursor.char_index);
	return line_index, column_index;
}

get_column_index :: (using view : View, cursor_index : s64) -> s64 #must
{
	cursor := cursors[cursor_index];
	buffer := get (buffer_id);
	i := cursor.char_index;
	while i > 0 && char_at (buffer, i - 1)
		i -= 1;
	return cursor.char_index - i;
}

insert :: (using view : *View, codepoint : u32, cursor_index := view.ALL_CURSORS) -> bool
{
	if !has_write_access
		return false;
	if cursor_index == ALL_CURSORS
	{
		for i : 0..cursors.count - 1
			insert (view, codepoint, i);
		return true;
	}

	buffer := get (buffer_id);
	cursor := *cursors[cursor_index];
	move_cursor (buffer, cursor.char_index);
	if cursor.selection != 0
		delete (buffer, cursor.selection);
	insert (buffer, codepoint);
	for other_view, view_id : g_views
	{
		if other_view.buffer_id == buffer_id
			continue;
		for * other, other_index : cursors
		{
			if view_id == global_id && cursor_index == other_index
				continue;
			if other.char_index >= cursor.char_index
				other.char_index += 1;
		}
	}
	cursor.char_index += 1;

	return true;
}

delete :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if !has_write_access
		return false;
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= delete (view, i);
		return ok;
	}

	buffer := get (buffer_id);
	cursor := *cursors[cursor_index];
	move_cursor (buffer, cursor.char_index);
	ok := delete (buffer, cursor.selection);
	for other_view, view_id : g_views
	{
		if other_view.buffer_id == buffer_id
			continue;
		for * other, other_index : cursors
		{
			if view_id == global_id && cursor_index == other_index
				continue;
			if other.char_index > cursor.char_index
				other.char_index -= 1;
		}
	}

	return ok;
}

backspace :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if !has_write_access
		return false;
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= backspace (view, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	if cursor.selection != 0
		return delete (view, cursor_index);
	buffer := get (buffer_id);
	move_cursor (buffer, cursor.char_index);
	ok := backspace (buffer);
	for other_view, view_id : g_views
	{
		if other_view.buffer_id == buffer_id
			continue;
		for * other, other_index : cursors
		{
			if view_id == global_id && cursor_index == other_index
				continue;
			if other.char_index >= cursor.char_index
				other.char_index -= 1;
		}
	}
	cursor.char_index -= 1;

	return ok;
}

move_cursor_forward :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_forward (view, i);
		return ok;
	}

	cursor := cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == get_count (buffer)
		return false;
	cursor.char_index += 1;

	return true;
}

move_cursor_backward :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_backward (view, i);
		return ok;
	}

	cursor := cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == 0
		return false;
	cursor.char_index -= 1;

	return true;
}

move_cursor_to_previous_line :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_to_previous_line (view, i);
		return ok;
	}

	buffer := get (buffer_id);
	ci := get_column_index (view, cursor_index);
	ok := move_cursor_to_bol (view, cursor_index);
	ok ||= move_cursor_backward (view, cursor_index);
	ok ||= move_cursor_to_column (view, ci, cursor_index);

	return ok;
}

move_cursor_to_next_line :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_to_next_line (view, i);
		return ok;
	}

	buffer := get (buffer_id);
	ci := get_column_index (view, cursor_index);
	ok := move_cursor_to_eol (view, cursor_index);
	ok ||= move_cursor_forward (view, cursor_index);
	ok ||= move_cursor_to_column (view, ci, cursor_index);

	return ok;
}

move_cursor_to_bol :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_to_bol (view, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	if cursor.char_index == 0
		return false;
	buffer := get (buffer_id);
	li, ci := get_line_and_column (buffer, cursor.char_index);
	while cursor.char_index > 0 && char_at (buffer, cursor.char_index - 1) != #char "\n"
		cursor.char_index -= 1;
	return true;
}

move_cursor_to_eol :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_to_eol (view, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == get_count (buffer)
		return false;
	li, ci := get_line_and_column (buffer, cursor.char_index);
	while cursor.char_index < get_count (buffer) && char_at (buffer, cursor.char_index) != #char "\n"
		cursor.char_index += 1;
	return true;
}

move_cursor_to_column :: (using view : *View, target : s64, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok ||= move_cursor_to_column (view, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	moved := move_cursor_to_bol (view, cursor_index);
	i := 0;
	while i < target && cursor.char_index < get_count (buffer) && char_at (buffer, cursor.char_index) != #char "\n"
		cursor.char_index += 1;

	return moved && i != 0;
}

cursors_overlap :: inline (a : View.Cursor, b : View.Cursor) -> bool #must
{
	return b.selection > 0 && a.char_index >= b.char_index && a.char_index < b.char_index + b.selection
		|| b.selection < 0 && a.char_index >= b.char_index + b.selection && a.char_index < b.char_index
		|| a.char_index == b.char_index;
}

merge_overlapping_cursors :: (using view : *View)
{
	buffer := get (buffer_id);
	i := 0;
	while i < cursors.count
	{
		cursor := *cursors[i];
		merged := false;
		for * cursors
		{
			if it_index == i
				continue;
			if cursors_overlap (cursor, it)
			{
				cursor.char_index = it.char_index;
				array.ordered_remove_at (*cursors, it_index);
				merged = true;
				break;
			}
		}
		if merged
			i = 0;
		else
			i += 1;
	}
}

sort_cursors :: inline (using view : *View)
{
	algo.qsort (cursors, (a, b) => (a.char_index - b.char_index));
}

handle_window_message :: (using view : *View, msg : window.Message)
{
	buffer := get (buffer_id);
	if has_write_access
	{
		if msg.kind ==
		{
		case .TEXT_INPUT;
			insert (buffer, msg.codepoint);
		case .KEY_PRESSED; #through;
		case .KEY_REPEATED;
			if msg.key_code ==
			{
			case .TAB;
				insert (buffer, #char "\t");
			case .RETURN;
				insert (buffer, #char "\n");
			case .BACKSPACE;
				backspace (buffer);
			case .DELETE;
				delete (buffer);
			}
		}
	}
	if msg.kind ==
	{
	case .KEY_PRESSED; #through;
	case .KEY_REPEATED;
		if msg.key_code ==
		{
		case .UP;
			move_cursor_to_previous_line (view);
		case .DOWN;
			move_cursor_to_next_line (view);
		case .LEFT;
			move_cursor_backward (view);
		case .RIGHT;
			move_cursor_forward (view);
		}
	}
}
