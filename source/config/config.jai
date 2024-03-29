#load "variable.jai";
#load "parse.jai";

Color_Id :: u16;

Config :: struct
{
	variables : map.Hash_Map (string, Variable.Value);
}

init_config :: (config : *Config)
{
	map.init (*config.variables, 100, mem.HEAP_ALLOC);
}

set :: inline (config : *Config, name : string, value : Variable.Value) -> overwritten : bool
{
	name_in_map := name;
	ptr := map.get_ptr (config.variables, name);
	overwritten := ptr != null;
	if !ptr
	{
		ptr = map.insert (*config.variables, str.clone (name, mem.HEAP_ALLOC), value);
	}
	else
	{
		if ptr.kind == .STRING
			mem.free (ptr.as_string, mem.HEAP_ALLOC);
		<<ptr = value;
	}
	if ptr.kind == .STRING
		ptr.as_string = str.clone (ptr.as_string, mem.HEAP_ALLOC);

	return overwritten;
}

set :: inline (config : *Config, name : string, value : bool) -> overwritten : bool
{
	val : Variable.Value;
	val.kind = .BOOL;
	val.as_bool = value;
	return set (config, name, val);
}

set :: inline (config : *Config, name : string, value : int) -> overwritten : bool
{
	val : Variable.Value;
	val.kind = .INT;
	val.as_int = value;
	return set (config, name, val);
}

set :: inline (config : *Config, name : string, value : float) -> overwritten : bool
{
	val : Variable.Value;
	val.kind = .FLOAT;
	val.as_float = value;
	return set (config, name, val);
}

set :: inline (config : *Config, name : string, value : string) -> overwritten : bool
{
	val : Variable.Value;
	val.kind = .STRING;
	val.as_string = value;
	return set (config, name, val);
}

get :: inline (config : Config, name : string) -> Variable.Value, ok : bool
{
	ptr := map.get_ptr (config.variables, name);
	if !ptr
		return .{}, false;
	return <<ptr, true;
}

get :: inline (config : Config, name_fmt : string, args : ..Any) -> Variable.Value, ok : bool
{
	val, ok := get (config, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args));
	return val, ok;
}

get_int :: inline (config : Config, name : string, fallback := 0) -> int, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .INT
		return fallback, false;
	return val.as_int, true;
}

get_int :: inline (config : Config, name_fmt : string, args : ..Any, fallback := 0) -> int, ok : bool
{
	val, ok := get_int (config, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args), fallback);
	return val, ok;
}

get_float :: inline (config : Config, name : string, fallback := 0.0) -> float, ok : bool
{
	val, ok := get (config, name);
	if !ok || (val.kind != .FLOAT && val.kind != .INT)
		return fallback, false;
	if val.kind == .INT
		return xx val.as_int, true;
	return val.as_float, true;
}

get_float :: inline (config : Config, name_fmt : string, args : ..Any, fallback := 0.0) -> float, ok : bool
{
	val, ok := get_float (config, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args), fallback);
	return val, ok;
}

get_string :: inline (config : Config, name : string, fallback := "") -> string, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .STRING
		return fallback, false;
	return val.as_string, true;
}

get_string :: inline (config : Config, name_fmt : string, args : ..Any, fallback := "") -> string, ok : bool
{
	val, ok := get_string (config, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args), fallback);
	return val, ok;
}

get_bool :: inline (config : Config, name : string, fallback := false) -> bool, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .BOOL
		return fallback, false;
	return val.as_bool, true;
}

get_bool :: inline (config : Config, name_fmt : string, args : ..Any, fallback := false) -> bool, ok : bool
{
	val, ok := get_bool (config, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args), fallback);
	return val, ok;
}

get_rgba :: inline (config : Config, name : string, fallback := math.RGBA.{ 0, 0, 0, 0 }) -> math.RGBA, ok : bool
{
	val, ok := get (config, name);
	if !ok || val.kind != .RGBA
		return fallback, false;
	return val.as_rgba, true;
}

get_rgba :: inline (config : Config, name_fmt : string, args : ..Any, fallback := math.RGBA.{ 0, 0, 0, 0 }) -> math.RGBA, ok : bool
{
	val, ok := get_rgba (config, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args), fallback);
	return val, ok;
}

get_enum :: inline (config : Config, name : string, fallback : $T) -> T, ok : bool
#modify { return types.is_enum (T); }
{
	val, ok := get_string (config, name);
	if !ok
		return fallback, false;
	info_enum := type_info (T);
	for info_enum.names
	{
		if it == val
			return cast (T) info_enum.values[it_index], true;
	}

	return fallback, false;
}

get_enum :: inline (config : Config, name_fmt : string, args : ..Any, fallback : $T) -> T, ok : bool
#modify { return types.is_enum (T); }
{
	val, ok := get_enum (config, T, fmt.format (mem.TEMP_ALLOC, name_fmt, ..args), fallback);
	return val, ok;
}
