to_rads :: (angle_in_degrees : $T) -> T #must
{
	return angle_in_degrees * PI / 180.0;
}

to_degs :: (angle_in_radians : $T) -> T #must
{
	return angle_in_radians * 180.0 / PI;
}

linear_interpolate :: (x : $T, y : T, t : T) -> T #must
{
	return x + t * (y - x);
}

lerp :: linear_interpolate;

lerp_angle :: (x : $T, y : T, t : T) -> T #must
{
	return wrap (lerp (x, y, t), 0, 2 * PI);
}

cosine_interpolate :: (x : $T, y : T, t : T) -> T #must
{
	t = (1 - cos (t * PI)) / 2;

	return inline lerp (x, y, t);
}

clerp :: cosine_interpolate;

smoothstep :: (x : $T, y : T, t : T) -> T #must
{
	t = clamp ((t - x) / (y - x), 0, 1);

	return t * t * (3 - 2 * t);
}
