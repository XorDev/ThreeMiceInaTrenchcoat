
function smf_vector_cross(u, v) 
{
	gml_pragma("forceinline");
	return [u[1] * v[2] - u[2] * v[1],
			u[2] * v[0] - u[0] * v[2],
			u[0] * v[1] - u[1] * v[0]];
}
function smf_vector_dot(u, v) 
{
	gml_pragma("forceinline");
	return u[0]*v[0] + u[1]*v[1] + u[2]*v[2];
}
function smf_vector_normalize(v) 
{
	//Returns the unit vector with the same direction
	//Also returns the length of the original vector
	gml_pragma("forceinline");
	var l = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
	if l == 0{return [0, 0, 1, 0];}
	l = sqrt(l);
	var j = 1 / l;
	return [v[0] * j, v[1] * j, v[2] * j, l];
}
function smf_vector_orthogonalize(n, v) 
{
	gml_pragma("forceinline");
	var l = n[0] * v[0] + n[1] * v[1] + n[2] * v[2];
	return [v[0] - n[0] * l,
			v[1] - n[1] * l,
			v[2] - n[2] * l];
}
function smf_vector_rotate(v, axis, radians) 
{
	//Rotates the vector v around the given axis using Rodrigues' Rotation Formula
	var a = axis;
	var c = cos(radians);
	var s = sin(radians);
	var d = (1 - c) * (a[0] * v[0] + a[1] * v[1] + a[2] * v[2]);
	return [v[0] * c + a[0] * d + (a[1] * v[2] - a[2] * v[1]) * s,
			v[1] * c + a[1] * d + (a[2] * v[0] - a[0] * v[2]) * s,
			v[2] * c + a[2] * d + (a[0] * v[1] - a[1] * v[0]) * s]


}