// @Note (stefan): Make this its own module ?
// https://easings.net/

// The following ease in/out/inout procedures have been implemented:
//    Sine,
//    Quad,
//    Cubic,
//    Quart,
//    Quint,
//    Exp,
//    Circ,
//    Back,
//    Elastic,
//    Bounce

ease_in_sine :: inline (x : $T) -> T
{
	return 1 - cos ((x * PI) / 2);
}

ease_out_sine :: inline (x : $T) -> T
{
	return sin ((x * PI) / 2);
}

ease_inout_sine :: inline (x : $T) -> T
{
	return -(cos (x * PI) - 1) / 2;
}

ease_in_quad :: inline (x : $T) -> T
{
	return x * x;
}

ease_out_quad :: inline (x : $T) -> T
{
	return 1 - (1 - x) * (1 - x);
}

ease_inout_quad :: inline (x : $T) -> T
{
	if x < 0.5 then return 2 * x * x;
	else            return 1 - ((-2 * x + 2) * (-2 * x + 2)) / 2;
}

ease_in_cubic :: inline (x : $T) -> T
{
	return x * x * x;
}

ease_out_cubic :: inline (x : $T) -> T
{
	return 1 - (1 - x) * (1 - x) * (1 - x);
}

ease_inout_cubic :: inline (x : $T) -> T
{
	if x < 0.5 then return 4 * x * x * x;
	else            return 1 - ((-2 * x + 2) * (-2 * x + 2) * (-2 * x + 2)) / 2;
}

ease_in_quart :: inline (x : $T) -> T
{
	return x * x * x * x;
}

ease_out_quart :: inline (x : $T) -> T
{
	return 1 - (1 - x) * (1 - x) * (1 - x) * (1 - x);
}

ease_inout_quart :: inline (x : $T) -> T
{
	if x < 0.5 then return 8 * x * x * x * x;
	else            return 1 - ((-2 * x + 2) * (-2 * x + 2) * (-2 * x + 2) * (-2 * x + 2)) / 2;
}

ease_in_quint :: inline (x : $T) -> T
{
	return x * x * x * x * x;
}

ease_out_quint :: inline (x : $T) -> T
{
	return 1 - (1 - x) * (1 - x) * (1 - x) * (1 - x) * (1 - x);
}

ease_inout_quint :: inline (x : $T) -> T
{
	if x < 0.5 then return 16 * x * x * x * x * x;
	else            return 1 - ((-2 * x + 2) * (-2 * x + 2) * (-2 * x + 2) * (-2 * x + 2) * (-2 * x + 2)) / 2;
}

ease_in_exp :: inline (x : $T) -> T
{
	if x == 0 then return 0;
	else           return pow (2, 10 * x - 10);
}

ease_out_exp :: inline (x : $T) -> T
{
	if x == 1 then return 1;
	else           return 1 - pow (2, -10 * x);
}

ease_inout_exp :: inline (x : $T) -> T
{
	     if x == 0  then return 0;
	else if x == 1  then return 1;
	else if x < 0.5 then return pow (2, 20 * x - 10) / 2;
	else                 return (2 - pow (2, -20 * x + 10)) / 2;
}

ease_in_circ :: inline (x : $T) -> T
{
	return 1 - sqrt (1 - x * x);
}

ease_in_circ :: inline (x : $T) -> T
{
	return sqrt (1 - (x - 1) * (x - 1));
}

ease_inout_circ :: inline (x : $T) -> T
{
	if x < 0.5 then return (1 - sqrt (1 - (2 * x) * (2 * x))) / 2;
	else            return (sqrt (1 - (-2 * x + 2) * (-2 * x + 2)) + 1) / 2;
}

ease_in_back :: inline (x : $T) -> T
{
	C1 :: 1.70158;
	C3 :: C1 + 1;

	return C3 * x * x * x - C1 * x * x;
}

ease_out_back :: inline (x : $T) -> T
{
	C1 :: 1.70158;
	C3 :: C1 + 1;

	return 1 + C3 * (x - 1) * (x - 1) * (x - 1) + C1 * (x - 1) * (x - 1);
}

ease_inout_back :: inline (x : $T) -> T
{
	C1 :: 1.70158;
	C2 :: C1 + 1.525;

	if x < 0.5 then return ((2 * x) * (2 * x) * ((C2 + 1) * 2 * x - C2)) / 2;
	else            return ((2 * x - 2) * (2 * x - 2) * ((C2 + 1) * (x * 2 - 2) + C2) + 2) / 2;
}

ease_in_elastic :: inline (x : $T) -> T
{
	C4 :: (2 * PI) / 3;

	     if x == 0 then return 0;
	else if x == 1 then return 1;
	else                return -pow (2, 10 * x - 10) * sin ((x * 10 - 10.75) * C4);
}

ease_out_elastic :: inline (x : $T) -> T
{
	C4 :: (2 * PI) / 3;

	     if x == 0 then return 0;
	else if x == 1 then return 1;
	else                return pow (2, -10 * x) * sin ((x * 10 - 0.75) * C4) + 1;
}

ease_inout_elastic :: inline (x : $T) -> T
{
	C5 :: (2 * PI) / 4.5;

	     if x == 0  then return 0;
	else if x == 1  then return 1;
	else if x < 0.5 then return -(pow (2,  20 * x - 10) * sin ((20 * x - 11.125) * C5)) / 2;
	else                 return  (pow (2, -20 * x + 10) * sin ((20 * x - 11.125) * C5)) / 2 + 1;
}

ease_in_bounce :: inline (x : $T) -> T
{
	return 1 - ease_out_bounce (1 - x);
}

ease_out_bounce :: inline (x : $T) -> T
{
	N1 :: 7.5625;
	D1 :: 2.75;

	if x < 1 / D1
	{
		return N1 * x * x;
	}
	else if x < 2 / D1
	{
		x -= 1.5;

		return N1 * (x / D1) * x + 0.75;
	}
	else if x < 2.5 / D1
	{
		x -= 2.25;

		return N1 * (x / D1) * x + 0.9375;
	}
	else
	{
		x -= 2.625;

		return N1 * (x / D1) * x + 0.984375;
	}
}

ease_inout_bounce :: inline (x : $T) -> T
{
	if x < 0.5 then return (1 - ease_out_bounce (1 - 2 * x)) / 2;
	else            return (1 + ease_out_bounce (2 * x - 1)) / 2;
}
