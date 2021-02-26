function smf_mat_create(x, y, z, toX, toY, toZ, upX, upY, upZ, xScale, yScale, zScale) 
{	//Creates a 4x4 matrix with the to-direction as master
	var l = toX * toX + toY * toY + toZ * toZ;
	if (l > 0){
		l = 1 / sqrt(l);}
	else{
		show_debug_message("ERROR in script smf_mat_create: Supplied zero-length vector for to-vector.");}
	toX *= l;
	toY *= l;
	toZ *= l;

	//Orthogonalize up-vector to to-vector
	var dot = upX * toX + upY * toY + upZ * toZ;
	upX -= toX * dot;
	upY -= toY * dot;
	upZ -= toZ * dot;

	//Normalize up-vector
	l = upX * upX + upY * upY + upZ * upZ;
	if (l > 0){
		l = 1 / sqrt(l);}
	else{
		show_debug_message("ERROR in script smf_mat_create: Supplied zero-length vector for up-vector, or the up- and to-vectors are parallel.");}
		
	upX *= l;
	upY *= l;
	upZ *= l;

	//Create side vector
	var siX, siY, siZ;
	siX = upY * toZ - upZ * toY;
	siY = upZ * toX - upX * toZ;
	siZ = upX * toY - upY * toX;

	//Return a 4x4 matrix
	return [toX * xScale, toY * xScale, toZ * xScale, 0,
			siX * yScale, siY * yScale, siZ * yScale, 0,
			upX * zScale, upY * zScale, upZ * zScale, 0,
			x,  y,  z,  1];
}

function smf_mat_create_from_axisangle(ax, ay, az, radians) 
{	//Normalise the input vector
	var l = ax * ax + ay * ay + az * az;
	if (l != 0 && l != 1)
	{
		l = 1 / sqrt(l);
		ax *= l;
		ay *= l;
		az *= l;
	}
	//Build the rotation matrix
	var c = cos(-radians);
	var s = sin(-radians);
	var omc = 1 - c;
	var R = array_create(16, 0);
	R[0]  = omc * ax * ax + c;
	R[1]  = omc * ax * ay + s * az;
	R[2]  = omc * ax * az - s * ay;
	R[4]  = omc * ay * ax - s * az;
	R[5]  = omc * ay * ay + c;
	R[6]  = omc * ay * az + s * ax;
	R[8]  = omc * az * ax + s * ay;
	R[9]  = omc * az * ay - s * ax;
	R[10] = omc * az * az + c;
	R[15] = 1;
	return R;
}

function smf_mat_create_from_dualquat(DQ, targetM) 
{	//Dual quaternion must be normalized
	//Source: http://en.wikipedia.org/wiki/Dual_quaternion
	gml_pragma("forceinline");
	var q0 = DQ[0], q1 = DQ[1], q2 = DQ[2], q3 = DQ[3], q4 = DQ[4], q5 = DQ[5], q6 = DQ[6], q7 = DQ[7];
	targetM[@ 0] = q3 * q3 + q0 * q0 - q1 * q1 - q2 * q2;
	targetM[@ 1] = 2 * (q0 * q1 + q2 * q3);
	targetM[@ 2] = 2 * (q0 * q2 - q1 * q3);
	targetM[@ 3] = 0;
	targetM[@ 4] = 2 * (q0 * q1 - q2 * q3);
	targetM[@ 5] = q3 * q3 - q0 * q0 + q1 * q1 - q2 * q2;
	targetM[@ 6] = 2 * (q1 * q2 + q0 * q3);
	targetM[@ 7] = 0;
	targetM[@ 8] = 2 * (q0 * q2 + q1 * q3);
	targetM[@ 9] = 2 * (q1 * q2 - q0 * q3);
	targetM[@ 10] = q3 * q3 - q0 * q0 - q1 * q1 + q2 * q2;
	targetM[@ 11] = 0;
	targetM[@ 12] = 2 * (-q7 * q0 + q4 * q3 + q6 * q1 - q5 * q2);
	targetM[@ 13] = 2 * (-q7 * q1 + q5 * q3 + q4 * q2 - q6 * q0); 
	targetM[@ 14] = 2 * (-q7 * q2 + q6 * q3 + q5 * q0 - q4 * q1);
	targetM[@ 15] = 1;
	return targetM;
}

function smf_mat_invert(M, targetM) 
{
	//Returns the inverse of a 4x4 matrix
	var m0 = M[0], m1 = M[1], m2 = M[2], m3 = M[3], m4 = M[4], m5 = M[5], m6 = M[6], m7 = M[7], m8 = M[8], m9 = M[9], m10 = M[10], m11 = M[11], m12 = M[12], m13 = M[13], m14 = M[14], m15 = M[15];
	var inv = targetM;
	inv[@ 0] =	m5 * m10 * m15 - m5 * m11 * m14 - m9 * m6  * m15 + m9 * m7 * m14 +m13 * m6 * m11 - m13 * m7 * m10;
	inv[@ 1] = -m1 * m10 * m15 + m1 * m11 * m14 + m9 * m2 * m15 - m9 * m3 * m14 - m13 * m2 * m11 + m13 * m3 * m10;
	inv[@ 2] =  m1 * m6 * m15 - m1 * m7 * m14 - m5 * m2 * m15 + m5 * m3 * m14 + m13 * m2 * m7 - m13 * m3 * m6;
	inv[@ 3] = -m1 * m6 * m11 + m1 * m7 * m10 + m5 * m2 * m11 - m5 * m3 * m10 - m9 * m2 * m7 + m9 * m3 * m6;
	inv[@ 4] = -m4 * m10 * m15 + m4 * m11 * m14 + m8 * m6  * m15 - m8 * m7 * m14 - m12 * m6 * m11 + m12 * m7 * m10;
	inv[@ 5] =  m0 * m10 * m15 - m0 * m11 * m14 - m8 * m2 * m15 + m8 * m3 * m14 + m12 * m2 * m11 - m12 * m3 * m10;
	inv[@ 6] = -m0 * m6 * m15 + m0 * m7 * m14 + m4 * m2 * m15 - m4 * m3 * m14 - m12 * m2 * m7 + m12 * m3 * m6;
	inv[@ 7] =  m0 * m6 * m11 - m0 * m7 * m10 - m4 * m2 * m11 + m4 * m3 * m10 + m8 * m2 * m7 - m8 * m3 * m6;
	inv[@ 8] =  m4 * m9 * m15 - m4 * m11 * m13 - m8 * m5 * m15 + m8 * m7 * m13 + m12 * m5 * m11 - m12 * m7 * m9;
	inv[@ 9] = -m0 * m9 * m15 + m0 * m11 * m13 + m8 * m1 * m15 - m8 * m3 * m13 - m12 * m1 * m11 + m12 * m3 * m9;
	inv[@ 10] = m0 * m5 * m15 - m0 * m7 * m13 - m4 * m1 * m15 + m4 * m3 * m13 + m12 * m1 * m7 - m12 * m3 * m5;
	inv[@ 11]= -m0 * m5 * m11 + m0 * m7 * m9 + m4 * m1 * m11 - m4 * m3 * m9 - m8 * m1 * m7 + m8 * m3 * m5;
	inv[@ 12]= -m4 * m9 * m14 + m4 * m10 * m13 +m8 * m5 * m14 - m8 * m6 * m13 - m12 * m5 * m10 + m12 * m6 * m9;
	inv[@ 13] = m0 * m9 * m14 - m0 * m10 * m13 - m8 * m1 * m14 + m8 * m2 * m13 + m12 * m1 * m10 - m12 * m2 * m9;
	inv[@ 14]= -m0 * m5 * m14 + m0 * m6 * m13 + m4 * m1 * m14 - m4 * m2 * m13 - m12 * m1 * m6 + m12 * m2 * m5;
	inv[@ 15] = m0 * m5 * m10 - m0 * m6 * m9 - m4 * m1 * m10 + m4 * m2 * m9 + m8 * m1 * m6 - m8 * m2 * m5;
	var _det = m0 * inv[0] + m1 * inv[4] + m2 * inv[8] + m3 * inv[12];
	if (_det == 0 ){
	    show_debug_message( "The determinant is zero.");
	    return M;}
	_det = 1 / _det;
	for(var i = 0; i < 16; i++)
	{
		inv[@ i] *= _det;
	}
	return inv;
}
function smf_mat_invert_fast(M, targetM) 
{
	//Returns the inverse of a 4x4 matrix. Assumes indices 3, 7 and 11 are 0, and index 15 is 1
	var m0 = M[0], m1 = M[1], m2 = M[2], m4 = M[4], m5 = M[5], m6 = M[6], m8 = M[8], m9 = M[9], m10 = M[10], m12 = M[12], m13 = M[13], m14 = M[14];
	var inv = targetM;
	inv[@ 0] =	m5 * m10 - m9 * m6;
	inv[@ 1] = -m1 * m10 + m9 * m2;
	inv[@ 2] =  m1 * m6 - m5 * m2;
	inv[@ 3] = 0;
	inv[@ 4] = -m4 * m10 + m8 * m6;
	inv[@ 5] =  m0 * m10 - m8 * m2;
	inv[@ 6] = -m0 * m6 + m4 * m2;
	inv[@ 7] =  0;
	inv[@ 8] =  m4 * m9 - m8 * m5;
	inv[@ 9] = -m0 * m9 + m8 * m1;
	inv[@ 10] = m0 * m5 - m4 * m1;
	inv[@ 11]=  0;
	inv[@ 12]= -m4 * m9 * m14 + m4 * m10 * m13 +m8 * m5 * m14 - m8 * m6 * m13 - m12 * m5 * m10 + m12 * m6 * m9;
	inv[@ 13] = m0 * m9 * m14 - m0 * m10 * m13 - m8 * m1 * m14 + m8 * m2 * m13 + m12 * m1 * m10 - m12 * m2 * m9;
	inv[@ 14]= -m0 * m5 * m14 + m0 * m6 * m13 + m4 * m1 * m14 - m4 * m2 * m13 - m12 * m1 * m6 + m12 * m2 * m5;
	inv[@ 15] = 1;
	var _det = m0 * inv[0] + m1 * inv[4] + m2 * inv[8];
	if (_det == 0 ){
	    show_debug_message( "The determinant is zero.");
	    return M;}
	_det = 1 / _det;
	for(var i = 0; i < 16; i++)
	{
		inv[@ i] *= _det;
	}
	return inv;
}
function smf_mat_orthogonalize(M) 
{
	gml_pragma("forceinline");
	//Normalize to-vector (which is master)
	var l = M[0] * M[0] + M[1] * M[1] + M[2] * M[2];
	if (l != 0 && l != 1)
	{
		l = 1 / sqrt(l);
		M[@ 0] = l * M[0];
		M[@ 1] = l * M[1];
		M[@ 2] = l * M[2];
	}
	//Orthogonalize up-vector and normalize the result
	l = M[0] * M[8] + M[1] * M[9] + M[2] * M[10];
	M[@ 8]  -= M[0] * l;
	M[@ 9]  -= M[1] * l;
	M[@ 10] -= M[2] * l;
	l = M[8] * M[8] + M[9] * M[9] + M[10] * M[10];
	if (l != 0 && l != 1)
	{
		l = 1 / sqrt(l);
		M[@ 8]  *= l;
		M[@ 9]  *= l;
		M[@ 10] *= l;
	}
	//Create side-vector using cross product
	M[@ 4] = M[2] * M[9]  - M[1] * M[10];
	M[@ 5] = M[0] * M[10] - M[2] * M[8];
	M[@ 6] = M[1] * M[8]  - M[0] * M[9];
	l = M[4] * M[4] + M[5] * M[5] + M[6] * M[6];
	if (l != 0 && l != 1)
	{
		l = 1 / sqrt(l);
		M[@ 4] *= l;
		M[@ 5] *= l;
		M[@ 6] *= l;
	}
	M[@ 3] = 0;
	M[@ 7] = 0;
	M[@ 11] = 0;
	M[@ 15] = 1;
	return M;
}