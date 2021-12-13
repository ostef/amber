#import "Common";

Lexer :: struct
{
	filename : string;
	start, curr, end : *u8;
	line, column : s64;
}

lexer_init :: inline (lexer : *Lexer, filename : string, file_contents : string)
{
	lexer.filename = filename;
	lexer.start = file_contents.data;
	lexer.curr  = file_contents.data;
	lexer.end   = file_contents.data + file_contents.count;
	lexer.line   = 1;
	lexer.column = 1;
}

lexer_is_valid :: inline (using lexer : *Lexer) -> bool #must
{
	return curr < end;
}

lexer_error :: inline (using lexer : *Lexer, fmt : string, args : ..Any) -> bool
{
	println ("At line %, column %:", line, column);
	println (fmt, ..args);

	return false;
}

lexer_advance :: inline (using lexer : *Lexer, count := 1)
{
	i := 0;
	while i < count && curr < end
	{
		if <<curr == #char "\n"
		{
			line += 1;
			column = 0;
		}
		i += 1;
		curr += 1;
		column += 1;
	}
}

lexer_advance_to_next_line :: inline (using lexer : *Lexer)
{
	while curr < end && <<curr != #char "\n"
		lexer_advance (lexer);
	lexer_advance (lexer);
}

lexer_matches_string :: inline (using lexer : *Lexer, str : string) -> bool #must
{
	if curr + str.count > end then return false;

	for i : 0..str.count - 1
	{
		if curr[i] != str[i] then return false;
	}

	return true;
}

lexer_advance_if_matches_string :: inline (using lexer : *Lexer, str : string) -> bool
{
	if lexer_matches_string (lexer, str)
	{
		lexer_advance (lexer, str.count);

		return true;
	}

	return false;
}

Skipped_Spaces :: enum_flags
{
	NONE  :: 0x00;
	SPACE :: 0x01;
	TAB   :: 0x02;
	CR    :: 0x04;
	LF    :: 0x08;
}

lexer_skip_spaces :: inline (using lexer : *Lexer) -> Skipped_Spaces
{
	result := Skipped_Spaces.NONE;
	while curr < end
	{
		if <<curr == #char " "
			result |= Skipped_Spaces.SPACE;
		else if <<curr == #char "\t"
			result |= Skipped_Spaces.TAB;
		else if <<curr == #char "\r"
			result |= Skipped_Spaces.CR;
		else if <<curr == #char "\n"
			result |= Skipped_Spaces.LF;
		else
			return result;
		lexer_advance (lexer);
	}

	return result;
}

lexer_get_next_line :: inline (using lexer : Lexer) -> string #must
{
	result : string;
	result.data = curr;
	while result.data + result.count < end && result.data[result.count] != #char "\n"
		result.count += 1;
	
	return result;
}
