// A view on a buffer of text. There can be multiple views
// on the same buffer, for example when the same buffer is
// on screen twice, side by side like programmers often do.
// It does not have to refer to something that is actually
// on the screen, for example we might imagine a view that
// is on somebody else's computer, when working with someone
// else, or more simply a view that is not currently visible.
View :: struct
{
	Global_Id :: #type, isa storage.Slot_Info;	// Global view Id, across all view types

	Procs :: struct
	{
		on_cursor_added   : (*View, index : s64);
		on_cursor_removed : (*View, index : s64, Cursor);
	}

	Cursor :: struct
	{
		char_index : s64;
		selection  : s64;
	}

	ALL_CURSORS :: -1;

	global_id : Global_Id;
	type : Type;	// Actual Jai type
	buffer_id : Buffer.Id;
	read_only : bool;
	cursors : [..]Cursor;
	is_dirty : bool;
	using procs : Procs;
}

init :: (
	view : *View,
	type : Type,
	buffer_id : Buffer.Id,
	read_only : bool
)
{
	assert (storage.is_valid (g_buffers, buffer_id), "Invalid buffer id.");
	view.buffer_id = buffer_id;
	view.read_only = read_only;
	array.init (*view.cursors, 20, mem.HEAP_ALLOC);
	add_cursor (view, 0);
	view.is_dirty = true;
}

reset :: (using view : *View)
{
	array.reset (*cursors);
}

set_views_dirty :: (buffer_id : Buffer.Id)
{
	for g_views
	{
		if it.buffer_id == buffer_id
			it.is_dirty = true;
	}
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
	while i > 0 && char_at (buffer, i - 1) != #char "\n"
		i -= 1;
	return cursor.char_index - i;
}

insert :: (using view : *View, codepoint : u32, cursor_index := view.ALL_CURSORS) -> bool
{
	if read_only
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
		delete (view, cursor_index);
	insert (buffer, codepoint);
	for other_view, view_id : g_views
	{
		if other_view.buffer_id != buffer_id
			continue;
		for * other, other_index : other_view.cursors
		{
			if view_id == global_id && cursor_index == other_index
				continue;
			if other.char_index >= cursor.char_index
				other.char_index += 1;
			clamp_cursor (other_view, other_index, 0, get_count (buffer));
		}
	}
	cursor.char_index += 1;

	return true;
}

delete :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if read_only
		return false;
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= delete (view, i);
		return ok;
	}

	buffer := get (buffer_id);
	cursor := *cursors[cursor_index];
	move_cursor (buffer, cursor.char_index);
	if !delete (buffer, cursor.selection)
		return false;
	if cursor.selection < 0
		cursor.char_index += cursor.selection;
	for other_view, view_id : g_views
	{
		if other_view.buffer_id != buffer_id
			continue;
		for * other, other_index : other_view.cursors
		{
			if view_id == global_id && cursor_index == other_index
				continue;
			if other.char_index > cursor.char_index
			{
				if cursor.selection != 0
					other.char_index -= math.abs (cursor.selection);
				else
					other.char_index -= 1;
				clamp_cursor (other_view, other_index, 0, get_count (buffer));
			}
		}
	}
	cursor.selection = 0;

	return true;
}

backspace :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if read_only
		return false;
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= backspace (view, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	if cursor.selection != 0
		return delete (view, cursor_index);
	buffer := get (buffer_id);
	move_cursor (buffer, cursor.char_index);
	if !backspace (buffer)
		return false;
	for other_view, view_id : g_views
	{
		if other_view.buffer_id != buffer_id
			continue;
		for * other, other_index : other_view.cursors
		{
			if view_id == global_id && cursor_index == other_index
				continue;
			if other.char_index >= cursor.char_index
				other.char_index -= 1;
			clamp_cursor (other_view, other_index, 0, get_count (buffer));
		}
	}
	cursor.char_index -= 1;

	return true;
}

clamp_cursor :: (using view : *View, cursor_index : s64, x : s64, y : s64)
{
	cursor := *cursors[cursor_index];
	cursor.char_index = math.clamp (cursor.char_index, x, y);
	if cursor.char_index + cursor.selection < x
		cursor.selection = x - cursor.char_index;
	if cursor.char_index + cursor.selection > y
		cursor.selection = y - cursor.char_index;
}

clear_selection :: (using view : *View, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= clear_selection (view, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	if cursor.selection == 0
		return false;
	cursor.selection = 0;
	return true;
}

move_cursor :: (using view : *View, char_index : s64, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor (view, char_index, select, i);
		return ok;
	}

	buffer := get (buffer_id);
	char_index = math.clamp (char_index, 0, get_count (buffer));
	cursor := *cursors[cursor_index];
	if cursor.char_index == char_index
		return false;
	while cursor.char_index < char_index
	{
		cursor.char_index += 1;
		if select then cursor.selection -= 1;
	}
	while cursor.char_index > char_index
	{
		cursor.char_index -= 1;
		if select then cursor.selection += 1;
	}
	clamp_cursor (view, cursor_index, 0, get_count (buffer));
	return true;
}

move_cursor_forward :: (using view : *View, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_forward (view, select, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == get_count (buffer)
		return false;
	cursor.char_index += 1;
	if select then cursor.selection -= 1;

	return true;
}

move_cursor_backward :: (using view : *View, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_backward (view, select, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == 0
		return false;
	cursor.char_index -= 1;
	if select then cursor.selection += 1;

	return true;
}

move_cursor_to_next_alphanum_boundary :: (using view : *View, select : bool, treat_underscores_as_boundary : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_next_alphanum_boundary (view, select, treat_underscores_as_boundary, i);
		return ok;
	}

	moved : bool;
	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == get_count (buffer)
		return false;
	while unicode.is_space (char_at (buffer, cursor.char_index))
	{
		moved |= move_cursor_forward (view, select, cursor_index);
		if is_at_eol (buffer, cursor.char_index)
			return moved;
	}
	first := char_at (buffer, cursor.char_index);
	moved |= move_cursor_forward (view, select, cursor_index);
	if cursor.char_index == get_count (buffer)
		return moved;
	char := char_at (buffer, cursor.char_index);
	while !unicode.is_space (char)
	{
		if unicode.is_alnum (first) != unicode.is_alnum (char)
			break;
		if char == #char "_" && treat_underscores_as_boundary
			break;
		if is_at_eol (buffer, cursor.char_index)
			break;
		moved |= move_cursor_forward (view, select, cursor_index);
		if cursor.char_index == get_count (buffer)
			break;
		char = char_at (buffer, cursor.char_index);
	}

	return moved;
}

move_cursor_to_previous_alphanum_boundary :: (using view : *View, select : bool, treat_underscores_as_boundary : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_previous_alphanum_boundary (view, select, treat_underscores_as_boundary, i);
		return ok;
	}

	moved : bool;
	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == 0
		return false;
	while unicode.is_space (char_at (buffer, cursor.char_index - 1))
	{
		moved |= move_cursor_backward (view, select, cursor_index);
		if is_at_bol (buffer, cursor.char_index)
			return moved;
	}
	if cursor.char_index == 0
		return moved;
	first := char_at (buffer, cursor.char_index - 1);
	moved |= move_cursor_backward (view, select, cursor_index);
	if cursor.char_index == 0
		return moved;
	char := char_at (buffer, cursor.char_index - 1);
	while cursor.char_index > 0 && !unicode.is_space (char)
	{
		if unicode.is_alnum (first) != unicode.is_alnum (char)
			break;
		if char_at (buffer, cursor.char_index) == #char "_" && treat_underscores_as_boundary
			break;
		moved |= move_cursor_backward (view, select, cursor_index);
		if is_at_bol (buffer, cursor.char_index)
			break;
		char = char_at (buffer, cursor.char_index - 1);
	}

	return moved;
}

move_cursor_to_previous_line :: (using view : *View, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_previous_line (view, select, i);
		return ok;
	}

	buffer := get (buffer_id);
	li, ci := get_cursor_line_and_column (view, cursor_index);
	moved := move_cursor_to_bol (view, select, cursor_index);
	// @Note (stefan): ||= short-circuits! We use |= instead
	// otherwise the calls below might not be done.
	moved |= move_cursor_backward (view, select, cursor_index);
	if li != 0
		moved |= move_cursor_to_column (view, ci, select, cursor_index);

	return moved;
}

move_cursor_to_next_line :: (using view : *View, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_next_line (view, select, i);
		return ok;
	}

	buffer := get (buffer_id);
	li, ci := get_cursor_line_and_column (view, cursor_index);
	moved := move_cursor_to_eol (view, select, cursor_index);
	moved |= move_cursor_forward (view, select, cursor_index);
	if li != buffer.line_lengths.count - 1
		move_cursor_to_column (view, ci, select, cursor_index);

	return moved;
}

move_cursor_to_bol :: (using view : *View, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_bol (view, select, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	if cursor.char_index == 0
		return false;
	buffer := get (buffer_id);
	while cursor.char_index > 0 && char_at (buffer, cursor.char_index - 1) != #char "\n"
	{
		cursor.char_index -= 1;
		if select then cursor.selection += 1;
	}
	return true;
}

move_cursor_to_eol :: (using view : *View, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_eol (view, select, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	if cursor.char_index == get_count (buffer)
		return false;
	while cursor.char_index < get_count (buffer) && char_at (buffer, cursor.char_index) != #char "\n"
	{
		cursor.char_index += 1;
		if select then cursor.selection -= 1;
	}
	return true;
}

move_cursor_to_column :: (using view : *View, target : s64, select : bool, cursor_index := view.ALL_CURSORS) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok : bool;
		for i : 0..cursors.count - 1
			ok |= move_cursor_to_column (view, target, select, i);
		return ok;
	}

	cursor := *cursors[cursor_index];
	buffer := get (buffer_id);
	move_cursor_to_bol (view, select, cursor_index);
	prev_char_index := cursor.char_index;
	i := 0;
	while i < target && cursor.char_index < get_count (buffer) && char_at (buffer, cursor.char_index) != #char "\n"
	{
		cursor.char_index += 1;
		if select then cursor.selection -= 1;
		i += 1;
	}

	return cursor.char_index != prev_char_index;
}

cursors_overlap :: inline (a : View.Cursor, b : View.Cursor) -> bool #must
{
	return b.selection > 0 && a.char_index >= b.char_index && a.char_index < b.char_index + b.selection
		|| b.selection < 0 && a.char_index >= b.char_index + b.selection && a.char_index < b.char_index
		|| a.char_index == b.char_index;
}

cursor_selects :: inline (cursor : View.Cursor, char_index : s64) -> bool #must
{
	return cursor.selection > 0 && char_index >= cursor.char_index && char_index < cursor.char_index + cursor.selection
		|| cursor.selection < 0 && char_index >= cursor.char_index + cursor.selection && char_index < cursor.char_index;
}

cursor_overlaps :: inline (cursor : View.Cursor, char_index : s64) -> bool #must
{
	return cursor_selects (cursor, char_index) || cursor.char_index == char_index;
}

merge_overlapping_cursors :: (buffer_id : Buffer.Id)
{
	for g_views
	{
		if it.buffer_id == buffer_id
			merge_overlapping_cursors (it);
	}
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
				remove_cursor (view, it_index);
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
	// @Incomplete (stefan): We don't notify the view that cursors
	// have been swapped.
	algo.qsort (cursors, (a, b) => (a.char_index - b.char_index));
}

clear_cursors :: inline (using view : *View)
{
	while cursors.count > 1
		remove_cursor (view, cursors.count - 1);
}

add_cursor :: (using view : *View, char_index : s64) -> bool
{
	buffer := get (buffer_id);
	assert (char_index >= 0 && char_index <= get_count (buffer), "Bounds check failure.");
	for cursors
	{
		if cursor_overlaps (it, char_index)
			return false;
	}
	ptr := array.push (*cursors);
	ptr.char_index = char_index;
	if on_cursor_added
		on_cursor_added (view, cursors.count - 1);
	return true;
}

add_cursor_on_previous_line :: (using view : *View, cursor_index : s64) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok := false;
		max_cursor_index := cursors.count - 1;
		for i : 0..max_cursor_index
			ok |= add_cursor_on_previous_line (view, i);
		return ok;
	}

	li := get_cursor_line_and_column (view, cursor_index);
	if li == 0
		return add_cursor (view, 0);
	buffer := get (buffer_id);
	line_len := buffer.line_lengths[li - 1];
	char_index := cursors[cursor_index].char_index - line_len;

	return add_cursor (view, char_index);
}

add_cursor_on_next_line :: (using view : *View, cursor_index : s64) -> bool
{
	if cursor_index == ALL_CURSORS
	{
		ok := false;
		max_cursor_index := cursors.count - 1;
		for i : 0..max_cursor_index
			ok |= add_cursor_on_next_line (view, i);
		return ok;
	}

	li := get_cursor_line_and_column (view, cursor_index);
	buffer := get (buffer_id);
	if li == buffer.line_lengths.count - 1
		return add_cursor (view, 0);
	line_len := buffer.line_lengths[li];
	char_index := cursors[cursor_index].char_index + line_len;

	return add_cursor (view, char_index);
}

remove_cursor :: (using view : *View, cursor_index : s64)
{
	if cursors.count == 1
		return;
	cursor := array.ordered_remove_at (*cursors, cursor_index);
	if on_cursor_removed
		on_cursor_removed (view, cursor_index, cursor);
}

handle_window_message :: (using view : *View, msg : window.Message)
{
	buffer := get (buffer_id);
	if !read_only
	{
		if msg.kind ==
		{
		case .TEXT_INPUT;
			if insert (view, msg.codepoint)
				merge_overlapping_cursors (buffer_id);
		case .KEY_PRESSED; #through;
		case .KEY_REPEATED;
			if msg.key_code ==
			{
			case .TAB;
				if insert (view, #char "\t")
					merge_overlapping_cursors (buffer_id);
			case .RETURN;
				if insert (view, #char "\n")
					merge_overlapping_cursors (buffer_id);
			case .BACKSPACE;
				if backspace (view)
					merge_overlapping_cursors (buffer_id);
			case .DELETE;
				if delete (view)
					merge_overlapping_cursors (buffer_id);
			}
		}
	}
	if msg.kind ==
	{
	case .KEY_PRESSED; #through;
	case .KEY_REPEATED;
		if msg.key_code ==
		{
		case .ESCAPE;
			clear_cursors (view);
			clear_selection (view);
		case .UP;
			if msg.mods == (input.Mods.ALT | .SHIFT)
				add_cursor_on_previous_line (view, ALL_CURSORS);
			else
			{
				if !flagged (msg.mods, .SHIFT)
					clear_selection (view);
				move_cursor_to_previous_line (view, flagged (msg.mods, .SHIFT));
				merge_overlapping_cursors (buffer_id);
			}
		case .DOWN;
			if msg.mods == (input.Mods.ALT | .SHIFT)
				add_cursor_on_next_line (view, ALL_CURSORS);
			else
			{
				if !flagged (msg.mods, .SHIFT)
					clear_selection (view);
				move_cursor_to_next_line (view, flagged (msg.mods, .SHIFT));
				merge_overlapping_cursors (buffer_id);
			}
		case .LEFT;
			if !flagged (msg.mods, .SHIFT)
				clear_selection (view);
			treat_underscore_as_boundary := get_bool (g_config, "treat_underscore_as_alpha_numeric_boundary");
			if flagged (msg.mods, .CTRL)
				move_cursor_to_previous_alphanum_boundary (view, flagged (msg.mods, .SHIFT), treat_underscore_as_boundary);
			else
				move_cursor_backward (view, flagged (msg.mods, .SHIFT));
			merge_overlapping_cursors (buffer_id);
		case .RIGHT;
			if !flagged (msg.mods, .SHIFT)
				clear_selection (view);
			treat_underscore_as_boundary := get_bool (g_config, "treat_underscore_as_alpha_numeric_boundary");
			if flagged (msg.mods, .CTRL)
				move_cursor_to_next_alphanum_boundary (view, flagged (msg.mods, .SHIFT), treat_underscore_as_boundary);
			else
				move_cursor_forward (view, flagged (msg.mods, .SHIFT));
			merge_overlapping_cursors (buffer_id);
		}
	}
}
