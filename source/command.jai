Command :: struct
{
	Proc :: #type ([]string) -> s32;

	Arg :: struct
	{
		using variable : Variable;
		has_default_value : bool;
	}

	name : string;
	proc : Proc;
	args : [..]Arg;
}
