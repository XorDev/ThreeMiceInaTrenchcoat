/// @description _mbuff_get_triangle_weights(v1x, v1y, v2x, v2y, v3x, v3y, u, v)
/// @param v1x
/// @param v1y
/// @param v2x
/// @param v2y
/// @param v3x
/// @param v3y
/// @param u
/// @param v
function _mbuff_get_triangle_weights(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7) {
	/*
		Returns a 3-index array containing the weights of each vertex.
		Useful for interpolating between three vertices.
	*/
	var v1x = argument0;
	var v1y = argument1;
	var v2x = argument2;
	var v2y = argument3;
	var v3x = argument4;
	var v3y = argument5;
	var u = argument6;
	var v = argument7;
	var d = (v2y - v3y) * (v1x - v3x) + (v3x - v2x) * (v1y - v3y);
	if (d == 0){return [1, 0, 0];}
	d = 1 / d;
	var w1 = d * ((v2y - v3y) * (u - v3x) + (v3x - v2x) * (v - v3y));
	var w2 = d * ((v3y - v1y) * (u - v3x) + (v1x - v3x) * (v - v3y));
	var w3 = 1 - w1 - w2;

	return [w1, w2, w3];


}
