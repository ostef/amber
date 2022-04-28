#load "variable.jai";
#load "parse.jai";

Color_Id :: u16;

Config :: struct
{
	variables : map.Hash_Map (string, Variable.Value);
}

set :: inline (config : *Config, name : string, value : Variable.Value)
{
	ptr := map.get_ptr (config.variables, name);
	if !ptr
		ptr = map.insert (*config.variables, str.clone (name, mem.HEAP_ALLOC), value);
	else
	{
		if ptr.kind == .STRING
			mem.free (ptr.as_string, mem.HEAP_ALLOC);
		<<ptr = value;
	}
	if ptr.kind == .STRING
		ptr.as_string = str.clone (ptr.as_string, mem.HEAP_ALLOC);
}

set :: inline (config : *Config, name : string, value : bool)
{
	val : Variable.Value;
	val.kind = .BOOL;
	val.as_bool = value;
	set (config, name, val);
}

set :: inline (config : *Config, name : string, value : int)
{
	val : Variable.Value;
	val.kind = .INT;
	val.as_int = value;
	set (config, name, val);
}

set :: inline (config : *Config, name : string, value : float)
{
	val : Variable.Value;
	val.kind = .FLOAT;
	val.as_float = value;
	set (config, name, val);
}

set :: inline (config : *Config, name : string, value : string)
{
	val : Variable.Value;
	val.kind = .STRING;
	val.as_string = value;
	set (config, name, val);
}

get :: inline (config : Config, name : string) -> Variable.Value, ok : bool
{
	ptr := map.get_ptr (config.variables, name);
	if !ptr
		return .{}, false;
	return <<ptr, true;
}

get_int :: inline (config : Config, name : string, fallback := 0) -> int, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind == .INT
		return fallback, false;
	return val.as_int, true;
}

get_float :: inline (config : Config, name : string, fallback := 0.0) -> float, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .FLOAT
		return fallback, false;
	return val.as_float, true;
}

get_string :: inline (config : Config, name : string, fallback := "") -> string, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .STRING
		return fallback, false;
	return val.as_string, true;
}

get_bool :: inline (config : Config, name : string, fallback := false) -> bool, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .BOOL
		return fallback, false;
	return val.as_bool, true;
}

get_rgba :: inline (config : Config, name : string, fallback := math.RGBA.{ 0, 0, 0, 0 }) -> math.RGBA, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .RGBA
		return fallback, false;
	return val.as_rgba, true;
}
