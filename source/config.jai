Color_Id :: u16;

Config :: struct
{
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
			}

			kind : Kind;
			union
			{
				as_int    : int;
				as_float  : f64;
				as_string : string;
				as_bool   : bool;
			};
		}

		name : string;
		value : Value;
	}

	variables : map.Hash_Map (string, Variable);
}
