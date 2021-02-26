function smf_dq_create(radians, ax, ay, az, x, y, z) 
{
	//Creates a dual quaternion from axis angle and a translation vector
	//Source: http://en.wikipedia.org/wiki/Dual_quaternion
	var c, s;
	radians *= .5;
	var c = cos(radians);
	var s = sin(radians);
	ax *= s;
	ay *= s;
	az *= s;

	return [ax, ay, az, c,
			.5 * (x * c + y * az - z * ax),
			.5 * (y * c + z * ax - x * az),
			.5 * (z * c + x * ay - y * ax),
			.5 * (- x * ax - y * ay - z * az)];
}
function smf_dq_create_from_matrix(M, targetDQ) 
{	
	//---------------Create dual quaternion from a matrix
	//Source: http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
	//Creates a dual quaternion from a matrix
	var DQ = targetDQ;
	var T = 1 + M[0] + M[5] + M[10]
	if (T > 0.)
	{
	    var S = sqrt(T) * 2;
	    DQ[@ 0] = (M[9] - M[6]) / S;
	    DQ[@ 1] = (M[2] - M[8]) / S;
	    DQ[@ 2] = (M[4] - M[1]) / S;
	    DQ[@ 3] = -0.25 * S;  //I have modified this
	}
	else if (M[0] > M[5] && M[0] > M[10])
	{// Column 0: 
	   var S = sqrt(max(0., 1.0 + M[0] - M[5] - M[10])) * 2;
	    DQ[@ 0] = 0.25 * S;
	    DQ[@ 1] = (M[4] + M[1]) / S;
	    DQ[@ 2] = (M[2] + M[8]) / S;
	    DQ[@ 3] = (M[9] - M[6]) / S;
	} 
	else if (M[5] > M[10])
	{// Column 1: 
	    var S = sqrt(max(0., 1.0 + M[5] - M[0] - M[10])) * 2;
	    DQ[@ 0] = (M[4] + M[1]) / S;
	    DQ[@ 1] = 0.25 * S;
	    DQ[@ 2] = (M[9] + M[6]) / S;
	    DQ[@ 3] = (M[2] - M[8]) / S;
	} 
	else 
	{// Column 2:
		var S  = sqrt(max(0., 1.0 + M[10] - M[0] - M[5])) * 2;
	    DQ[@ 0] = (M[2] + M[8]) / S;
	    DQ[@ 1] = (M[9] + M[6]) / S;
	    DQ[@ 2] = 0.25 * S;
	    DQ[@ 3] = (M[4] - M[1]) / S;
	}
	DQ[@ 4] = .5 * (M[12] * DQ[3] + M[13] * DQ[2] - M[14] * DQ[1]);
	DQ[@ 5] = .5 * (M[13] * DQ[3] + M[14] * DQ[0] - M[12] * DQ[2]);
	DQ[@ 6] = .5 * (M[14] * DQ[3] + M[12] * DQ[1] - M[13] * DQ[0]);
	DQ[@ 7] =-.5 * (M[12] * DQ[0] + M[13] * DQ[1] + M[14] * DQ[2]);
	return DQ;
}
function smf_dq_duplicate(DQ) 
{	//Duplicates the given dual quaternion and returns the index of the new one
	var Q = array_create(8);
	array_copy(Q, 0, DQ, 0, 8);
	return Q;
}
function smf_dq_get_conjugate(DQ, targetDQ) 
{
	var R = targetDQ;
	R[@ 0] = -DQ[0];
	R[@ 1] = -DQ[1];
	R[@ 2] = -DQ[2];
	R[@ 3] =  DQ[3];
	R[@ 4] = -DQ[4];
	R[@ 5] = -DQ[5];
	R[@ 6] = -DQ[6];
	R[@ 7] =  DQ[7];
	return R;
}
function smf_dq_get_translation(DQ) 
{//Returns the translation of a given dual quaternion
	var q0 = DQ[0], q1 = DQ[1], q2 = DQ[2], q3 = DQ[3], q4 = DQ[4], q5 = DQ[5], q6 = DQ[6], q7 = DQ[7];
	return [2 * (-q7 * q0 + q4 * q3 + q6 * q1 - q5 * q2), 
			2 * (-q7 * q1 + q5 * q3 + q4 * q2 - q6 * q0), 
			2 * (-q7 * q2 + q6 * q3 + q5 * q0 - q4 * q1)];
}
function smf_dq_get_x(DQ) {
	//Returns the x component of the translation of a given dual quaternion
	gml_pragma("forceinline");
	return 2 * (-DQ[7] * DQ[0] + DQ[4] * DQ[3] + DQ[6] * DQ[1] - DQ[5] * DQ[2]);
}
function smf_dq_get_y(DQ) 
{	//Returns the y component of the translation of a given dual quaternion
	gml_pragma("forceinline");
	return 2 * (-DQ[7] * DQ[1] + DQ[5] * DQ[3] + DQ[4] * DQ[2] - DQ[6] * DQ[0]);
}
function smf_dq_get_z(DQ) 
{	//Returns the z component of the translation of a given dual quaternion
	gml_pragma("forceinline");
	return 2 * (-DQ[7] * DQ[2] + DQ[6] * DQ[3] + DQ[5] * DQ[0] - DQ[4] * DQ[1]);
}
function smf_dq_invert(DQ) 
{
	DQ[@ 0] = -DQ[0];
	DQ[@ 1] = -DQ[1];
	DQ[@ 2] = -DQ[2];
	DQ[@ 3] = -DQ[3];
	DQ[@ 4] = -DQ[4];
	DQ[@ 5] = -DQ[5];
	DQ[@ 6] = -DQ[6];
	DQ[@ 7] = -DQ[7];
	return DQ;
}
function smf_dq_lerp(DQ1, DQ2, amount, targetDQ) 
{
	var R = DQ1;
	var S = DQ2;
	var v2 = amount;
	var v1 = 1 - v2;
	var T = targetDQ;
	T[@ 0] = R[0] * v1 + S[0] * v2;
	T[@ 1] = R[1] * v1 + S[1] * v2;
	T[@ 2] = R[2] * v1 + S[2] * v2;
	T[@ 3] = R[3] * v1 + S[3] * v2;
	T[@ 4] = R[4] * v1 + S[4] * v2;
	T[@ 5] = R[5] * v1 + S[5] * v2;
	T[@ 6] = R[6] * v1 + S[6] * v2;
	T[@ 7] = R[7] * v1 + S[7] * v2;
	return T;
}
function smf_dq_multiply(R, S, targetDQ) {
	//Multiplies two dual quaternions and outputs the result to target
	//R * S = (A * C, A * D + B * C)
	var T = targetDQ;
	var r0 = R[0], r1 = R[1], r2 = R[2], r3 = R[3], r4 = R[4], r5 = R[5], r6 = R[6], r7 = R[7];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	var Qx = r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1;
	var Qy = r3 * s1 + r1 * s3 + r2 * s0 - r0 * s2;
	var Qz = r3 * s2 + r2 * s3 + r0 * s1 - r1 * s0;
	var Qw = r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2;
	var Dx = r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r7 * s0 + r4 * s3 + r5 * s2 - r6 * s1;
	var Dy = r3 * s5 + r1 * s7 + r2 * s4 - r0 * s6 + r7 * s1 + r5 * s3 + r6 * s0 - r4 * s2;
	var Dz = r3 * s6 + r2 * s7 + r0 * s5 - r1 * s4 + r7 * s2 + r6 * s3 + r4 * s1 - r5 * s0;
	var Dw = r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 + r7 * s3 - r4 * s0 - r5 * s1 - r6 * s2;
	T[@ 0] = Qx;
	T[@ 1] = Qy;
	T[@ 2] = Qz;
	T[@ 3] = Qw;
	T[@ 4] = Dx;
	T[@ 5] = Dy;
	T[@ 6] = Dz;
	T[@ 7] = Dw;
	return T;
}
function smf_dq_normalize(DQ) 
{
	var l = 1 / sqrt(sqr(DQ[0]) + sqr(DQ[1]) + sqr(DQ[2]) + sqr(DQ[3]));
	DQ[@ 0] *= l
	DQ[@ 1] *= l
	DQ[@ 2] *= l
	DQ[@ 3] *= l
	var d = DQ[0] * DQ[4] + DQ[1] * DQ[5] + DQ[2] * DQ[6] + DQ[3] * DQ[7];
	DQ[@ 4] = (DQ[4] - DQ[0] * d) * l;
	DQ[@ 5] = (DQ[5] - DQ[1] * d) * l;
	DQ[@ 6] = (DQ[6] - DQ[2] * d) * l;
	DQ[@ 7] = (DQ[7] - DQ[3] * d) * l;
	return DQ;
}
function smf_dq_quadratic_interpolate(A, B, C, amount, targetDQ) 
{
	var t0 = .5 * sqr(1 - amount);
	var t1 = .5 * amount * amount;
	var t2 = 2 * amount * (1 - amount);
	var T = targetDQ;
	var b0 = B[0], b1 = B[1], b2 = B[2], b3 = B[3], b4 = B[4], b5 = B[5], b6 = B[6], b7 = B[7];
	T[@ 0] = t0 * (A[0] + b0) + t1 * (b0 + C[0]) + t2 * b0;
	T[@ 1] = t0 * (A[1] + b1) + t1 * (b1 + C[1]) + t2 * b1;
	T[@ 2] = t0 * (A[2] + b2) + t1 * (b2 + C[2]) + t2 * b2;
	T[@ 3] = t0 * (A[3] + b3) + t1 * (b3 + C[3]) + t2 * b3;
	T[@ 4] = t0 * (A[4] + b4) + t1 * (b4 + C[4]) + t2 * b4;
	T[@ 5] = t0 * (A[5] + b5) + t1 * (b5 + C[5]) + t2 * b5;
	T[@ 6] = t0 * (A[6] + b6) + t1 * (b6 + C[6]) + t2 * b6;
	T[@ 7] = t0 * (A[7] + b7) + t1 * (b7 + C[7]) + t2 * b7;
	return T;
}
function smf_dq_set_translation(DQ, x, y, z) 
{
	DQ[@ 4] = .5 * (x * DQ[3] + y * DQ[2] - z * DQ[1]); 
	DQ[@ 5] = .5 * (y * DQ[3] + z * DQ[0] - x * DQ[2]);
	DQ[@ 6] = .5 * (z * DQ[3] + x * DQ[1] - y * DQ[0]); 
	DQ[@ 7] =-.5 * (x * DQ[0] + y * DQ[1] + z * DQ[2]);
}