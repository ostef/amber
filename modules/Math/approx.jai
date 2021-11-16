approx_zero :: (val : f32, epsilon := F32_EPSILON) -> bool
{
	return abs (val) <= epsilon;
}

approx_zero :: (val : f64, epsilon := F64_EPSILON) -> bool
{
	return abs (val) <= epsilon;
}

approx_equal :: (left : f32, right : f32, epsilon := F32_EPSILON) -> bool
{
	return abs (left - right) <= epsilon;
}

approx_equal :: (left : f64, right : f64, epsilon := F64_EPSILON) -> bool
{
	return abs (left - right) <= epsilon;
}
