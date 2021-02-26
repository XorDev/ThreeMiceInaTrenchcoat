function smf_smoothstep(_min, _max, val) 
{
	// Scale, bias and saturate x to 0..1 range
	var xx = clamp((val - _min) / (_max - _min), 0.0, 1.0); 
	// Evaluate polynomial
	return xx * xx * (3 - 2 * xx);
}
function smf_quadratic_interpolate(A, B, C, amount) 
{
	var t0 = .5 * sqr(1 - amount);
	var t1 = .5 * amount * amount;
	var t2 = 2 * amount * (1 - amount);
	return t0 * (A + B) + t1 * (B + C) + t2 * B;
}
function smf_get_array_index(array, val) 
{	/*	Returns the array index of the given value.
		-1 if the value does not exist in the array*/
	for (var i = array_length(array) - 1; i >= 0; i --)
	{
		if (val == array[i])
		{
			return i;
		}
	}
	return -1;
}