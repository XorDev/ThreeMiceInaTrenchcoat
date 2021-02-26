function smf_quat_create_from_matrix(M, targetQ) {
	//Creates a quaternion from a rotation matrix
	gml_pragma("forceinline");
	var Q = targetQ;
	//---------------Create orientation quaternion from the top left 3x3 part of the matrix
	//Source: http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
	var T = 1 + M[0] + M[5] + M[10]
	if (T > 0.)
	{
	    var S = sqrt(T) * 2;
	    Q[@ 0] = (M[9] - M[6]) / S;
	    Q[@ 1] = (M[2] - M[8]) / S;
	    Q[@ 2] = (M[4] - M[1]) / S;
	    Q[@ 3] = -0.25 * S;  //I have modified this
	}
	else if (M[0] > M[5] && M[0] > M[10])
	{// Column 0: 
	    var S = sqrt(1.0 + M[0] - M[5] - M[10]) * 2;
	    Q[@ 0] = 0.25 * S;
	    Q[@ 1] = (M[4] + M[1]) / S;
	    Q[@ 2] = (M[2] + M[8]) / S;
	    Q[@ 3] = (M[9] - M[6]) / S;
	} 
	else if (M[5] > M[10])
	{// Column 1: 
	    var S = sqrt(1.0 + M[5] - M[0] - M[10]) * 2;
	    Q[@ 0] = (M[4] + M[1]) / S;
	    Q[@ 1] = 0.25 * S;
	    Q[@ 2] = (M[9] + M[6]) / S;
	    Q[@ 3] = (M[2] - M[8]) / S;
	} 
	else 
	{// Column 2:
	    var S  = sqrt(1.0 + M[10] - M[0] - M[5]) * 2;
	    Q[@ 0] = (M[2] + M[8]) / S;
	    Q[@ 1] = (M[9] + M[6]) / S;
	    Q[@ 2] = 0.25 * S;
	    Q[@ 3] = (M[4] - M[1]) / S;
	}
	return Q;
}
function smf_quat_dot(Q, R) 
{
	return Q[0] * R[0] + Q[1] * R[1] + Q[2] * R[2] + Q[3] * R[3];
}
function smf_quat_get_conjugate(Q) 
{
	gml_pragma("forceinline");
	return [-Q[0], -Q[1], -Q[2], Q[3]];
}
function smf_quat_get_si(Q) 
{
	gml_pragma("forceinline");
	return [2 * (Q[0] * Q[1] - Q[2] * Q[3]), 
			sqr(Q[3]) - sqr(Q[0]) + sqr(Q[1]) - sqr(Q[2]),
			2 * (Q[1] * Q[2] + Q[0] * Q[3])]
}
function smf_quat_get_to(Q) 
{
	gml_pragma("forceinline");
	return [sqr(Q[3]) + sqr(Q[0]) - sqr(Q[1]) - sqr(Q[2]), 
			2 * (Q[0] * Q[1] + Q[3] * Q[2]),
			2 * (Q[0] * Q[2] - Q[3] * Q[1])];
}
function smf_quat_get_up(Q) {
	gml_pragma("forceinline");
	return [2 * (Q[2] * Q[0] + Q[3] * Q[1]), 
			2 * (Q[2] * Q[1] - Q[3] * Q[0]),
			sqr(Q[3]) - sqr(Q[0]) - sqr(Q[1]) + sqr(Q[2])];
}
function smf_quat_multiply(R, S, targetQ) 
{
	//Multiplies two quaternions and outputs the result to targetQ
	var T = targetQ;
	var Qx = R[3] * S[0] + R[0] * S[3] + R[1] * S[2] - R[2] * S[1];
	var Qy = R[3] * S[1] + R[1] * S[3] + R[2] * S[0] - R[0] * S[2];
	var Qz = R[3] * S[2] + R[2] * S[3] + R[0] * S[1] - R[1] * S[0];
	var Qw = R[3] * S[3] - R[0] * S[0] - R[1] * S[1] - R[2] * S[2];
	T[@ 0] = Qx;
	T[@ 1] = Qy;
	T[@ 2] = Qz;
	T[@ 3] = Qw;
	return T;
}
function smf_quat_transform_vector(Q, vx, vy, vz) {
	var crossX = Q[1] * vz - Q[2] * vy + Q[3] * vx;
	var crossY = Q[2] * vx - Q[0] * vz + Q[3] * vy;
	var crossZ = Q[0] * vy - Q[1] * vx + Q[3] * vz;
	var r = global.animTempV;
	r[@ 0] = vx + 2. * Q[1] * crossZ - Q[2] * crossY;
	r[@ 1] = vy + 2. * Q[2] * crossX - Q[0] * crossZ;
	r[@ 2] = vz + 2. * Q[0] * crossY - Q[1] * crossX;
	return r;
}