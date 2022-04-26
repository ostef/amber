Command :: struct
{
	Proc :: #type ([]string) -> s32;

	name : string;
	proc : Proc;
	arg_count : s64;
	first_optional_argument : s64;
}
