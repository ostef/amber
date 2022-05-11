Variable :: struct
{
	Value :: struct
	{
		Kind :: enum
		{
			INT;
			FLOAT;
			STRING;
			BOOL;
			RGBA;
		}

		kind : Kind;	@Fmt_Tag
		using val : union
		{
			as_int    : int;
			as_float  : float;
			as_string : string;
			as_bool   : bool;
			as_rgba   : math.RGBA;
		};	@Fmt_Tagged_Union
	}

	name : string;
	value : Value;
}

set :: inline (value : *Variable.Value, val : $T)
{
	#if T == int
	{
		value.kind = .INT;
		value.as_int = val;
	}
	else #if T == float
	{
		value.kind = .FLOAT;
		value.as_float = val;
	}
	else #if T == bool
	{
		value.kind = .BOOL;
		value.as_bool = val;
	}
	else #if T == string
	{
		value.kind = .STRING;
		value.as_string = val;
	}
	else #if T == math.RGBA
	{
		value.kind = .RGBA;
		value.as_rgba = val;
	}
	else
		#assert false, "Invalid type, must be int, float, bool, string or RGBA.";
}

value_cast :: inline ($Target : Type, value : Variable.Value, $check_panic := true) -> Target #must, bool
{
	#if Target == int
	{
		if value.kind != .INT
		{
			#if check_panic
				panic ("Value is not an int.");
			return mem.default (Target), false;
		}
		return value.as_int, true;
	}
	else #if Target == float
	{
		if value.kind != .FLOAT
		{
			#if check_panic
				panic ("Value is not a float.");
			return mem.default (Target), false;
		}
		return value.as_float, true;
	}
	else #if Target == bool
	{
		if value.kind != .BOOL
		{
			#if check_panic
				panic ("Value is not a bool.");
			return mem.default (Target), false;
		}
		return value.as_bool, true;
	}
	else #if Target == string
	{
		if value.kind != .STRING
		{
			#if check_panic
				panic ("Value is not a string.");
			return mem.default (Target), false;
		}
		return value.as_string, true;
	}
	else #if Target == math.RGBA
	{
		if value.kind != .RGBA
		{
			#if check_panic
				panic ("Value is not a RGBA.");
			return mem.default (Target), false;
		}
		return value.as_rgba, true;
	}
	else
		#assert false, "Invalid type, must be int, float, bool, string or RGBA.";
}
