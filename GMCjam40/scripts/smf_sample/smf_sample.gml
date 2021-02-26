// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function sample_create_bind(rig) 
{	/*	Creates a sample with no transformations.
		The sample will only contain identity dual quaternions*/
	var boneNum = rig.boneNum;
	if (boneNum <= 0)
	{
		return -1;
	}
	var sample = array_create(boneNum * 8, 0);
	for (var i = 8 * (boneNum - 1) + 3; i >= 0; i -= 8)
	{
		sample[i] = 1;
	}
	return sample;
}

function sample_update_bind(rig, sample) 
{	/*	Updates a sample with no transformations.
		The sample will only contain identity dual quaternions*/
	var boneNum = rig.boneNum;
	if (boneNum <= 0){
		show_debug_message("ERROR in script sample_create_bind: No bones in rig");
		return [0, 0, 0, 1, 0, 0, 0, 0];}
	for (var i = 8 * boneNum - 1; i >= 0; i --)
	{
		sample[@ i] = ((i mod 8) == 3);
	}
	return sample;
}

function sample_set_uniform(shader, sample) 
{	//Sends the sample to the shader
	var aniUni = global.AnimUniMap[? string(shader) + "ani"];
	if (is_undefined(aniUni))
	{
		aniUni = shader_get_uniform(shader, "u_animate");
		global.AnimUniMap[? string(shader) + "ani"] = aniUni;
	}
	if (!is_array(sample))
	{
		shader_set_uniform_i(aniUni, false);
		exit;
	}
	shader_set_uniform_i(aniUni, true);
	var smpUni = global.AnimUniMap[? string(shader) + "smp"];
	if (is_undefined(smpUni))
	{
		smpUni = shader_get_uniform(shader, "u_boneDQ");
		global.AnimUniMap[? string(shader) + "smp"] = smpUni;
	}
	shader_set_uniform_f_array(smpUni, sample);
}

function sample_lerp(sample1, sample2, amount, targetSample) 
{	/*	Linearly interpolates between two samples.
		The samples must have the same number of bones.*/
	var num = array_length(sample1);
	var S1 = sample1;
	var S2 = sample2;
	var S = targetSample;

	//If amount is 0 or less, just copy over sample1
	if (amount <= 0){
		array_copy(S, 0, S1, 0, num);
		return S;}

	//If amount is 1 or larger, just copy over sample2
	if (amount >= 1){
		array_copy(S, 0, S2, 0, num);
		return S;}

	//Linearly interpolate between the two samples
	var i = 0;
	var t1 = 1 - amount;
	while (i < num)
	{
		//Make sure the dual quaternions are in the same half of the hypersphere
		var t2 = amount * sign(S1[i] * S2[i] + S1[i+1] * S2[i+1] + S1[i+2] * S2[i+2] + S1[i+3] * S2[i+3]);
		repeat 8
		{
			S[@ i] = S1[i] * t1 + S2[i] * t2;
			i ++;
		}
	}
	return S;
}

function sample_splice_branch(rig, nodeInd, destSample, srcSample, weight) 
{	/*	This script lets you combine one bone and all its descendants from one sample into another.
		Useful if you've only animated parts of the rig in one sample.
	
		weight should be between 0 and 1. At 0, there will be no change to the sample. At 1, the branch will be copied from the source to the destination.
		Anything inbetween will interpolate linearly. Note that the interpolation may accidentally detach bones from their parents.*/
	var D = destSample;
	var S = srcSample;

	var bindMap = rig.bindMap;
	var nodeList = rig.nodeList;
	var node = nodeList[| nodeInd];

	//Find the bone index of the parent node
	var descendants = node[eAnimNode.Descendants];
	var num = array_length(descendants);
	var parent = node[eAnimNode.Parent];
	var parBone = bindMap[| parent];
	if (parBone < 0)
	{
		parBone = bindMap[| nodeInd];
		if (parBone < 0)
		{
			//The parent node is not mapped to any bone. Simply interpolate between source and destination without transformation.
			b = 8 * bindMap[| nodeInd];
			for (var i = 0; i <= num; i ++)
			{
				if (b >= 0)
				{
					D[@ b]   += weight * (S[b]   - D[b]);
					D[@ b+1] += weight * (S[b+1] - D[b+1]);
					D[@ b+2] += weight * (S[b+2] - D[b+2]);
					D[@ b+3] += weight * (S[b+3] - D[b+3]);
					D[@ b+4] += weight * (S[b+4] - D[b+4]);
					D[@ b+5] += weight * (S[b+5] - D[b+5]);
					D[@ b+6] += weight * (S[b+6] - D[b+6]);
					D[@ b+7] += weight * (S[b+7] - D[b+7]);
				}
				if (i < num)
				{
					b = 8 * bindMap[| descendants[i]];
				}
			}
			return D;
		}
	}

	//Find the change in orientation from the source sample to the destination sample. Same as dq_multiply(D, dq_get_conjugate(S));
	var b = parBone * 8;
	var s0 = S[b], s1 = S[b+1], s2 = S[b+2], s3 = S[b+3], s4 = S[b+4], s5 = S[b+5], s6 = S[b+6], s7 = S[b+7];
	var d0 = D[b], d1 = D[b+1], d2 = D[b+2], d3 = D[b+3], d4 = D[b+4], d5 = D[b+5], d6 = D[b+6], d7 = D[b+7];
	var r0 =-d3 * s0 + d0 * s3 - d1 * s2 + d2 * s1;
	var r1 =-d3 * s1 + d1 * s3 - d2 * s0 + d0 * s2;
	var r2 =-d3 * s2 + d2 * s3 - d0 * s1 + d1 * s0;
	var r3 = d3 * s3 + d0 * s0 + d1 * s1 + d2 * s2;
	var r4 =-d3 * s4 + d0 * s7 - d1 * s6 + d2 * s5 - d7 * s0 + d4 * s3 - d5 * s2 + d6 * s1;
	var r5 =-d3 * s5 + d1 * s7 - d2 * s4 + d0 * s6 - d7 * s1 + d5 * s3 - d6 * s0 + d4 * s2;
	var r6 =-d3 * s6 + d2 * s7 - d0 * s5 + d1 * s4 - d7 * s2 + d6 * s3 - d4 * s1 + d5 * s0;
	var r7 = d3 * s7 + d0 * s4 + d1 * s5 + d2 * s6 + d7 * s3 + d4 * s0 + d5 * s1 + d6 * s2;

	//Transform the source sample so that it stays attached to the parent in the destination sample. Linearly interpolate between source and destination samples.
	b = 8 * bindMap[| nodeInd];
	for (var i = 0; i <= num; i ++)
	{
		if (b >= 0)
		{
			var s0 = S[b], s1 = S[b+1], s2 = S[b+2], s3 = S[b+3], s4 = S[b+4], s5 = S[b+5], s6 = S[b+6], s7 = S[b+7];
			var d0 = D[b], d1 = D[b+1], d2 = D[b+2], d3 = D[b+3], d4 = D[b+4], d5 = D[b+5], d6 = D[b+6], d7 = D[b+7];
			D[@ b]   += weight * (r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1 - d0);
			D[@ b+1] += weight * (r3 * s1 + r1 * s3 + r2 * s0 - r0 * s2 - d1);
			D[@ b+2] += weight * (r3 * s2 + r2 * s3 + r0 * s1 - r1 * s0 - d2);
			D[@ b+3] += weight * (r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2 - d3);
			D[@ b+4] += weight * (r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r7 * s0 + r4 * s3 + r5 * s2 - r6 * s1 - d4);
			D[@ b+5] += weight * (r3 * s5 + r1 * s7 + r2 * s4 - r0 * s6 + r7 * s1 + r5 * s3 + r6 * s0 - r4 * s2 - d5);
			D[@ b+6] += weight * (r3 * s6 + r2 * s7 + r0 * s5 - r1 * s4 + r7 * s2 + r6 * s3 + r4 * s1 - r5 * s0 - d6);
			D[@ b+7] += weight * (r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 + r7 * s2 - r4 * s0 - r5 * s1 - r6 * s2 - d7);
		}
		if (i < num)
		{
			b = 8 * bindMap[| descendants[i]];
		}
	}
	return D;
}

/// @func sample_get_node_dq(rig, nodeInd, sample, [targetQ])
function sample_get_node_dq() 
{	/*	Returns the world orientation of the node as a dual quaternion
		targetQ is an optional argument, in case you'd like to output directly to an existing dual quaternion.
		If targetQ is not provided, a new dual quaternion is created*/
	var rig = argument[0];
	var nodeInd = argument[1];
	var sample = argument[2];
	var tempQ = (argument_count > 3) ? argument[3] : array_create(8);

	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;
	var nodeNum = ds_list_size(nodeList);
	if (rig.boneNum == 0 || nodeInd >= nodeNum || nodeInd < 0){
		//The node does not exist
		show_debug_message("ERROR in script sample_get_node_dq: Node " + string(nodeInd) + " does not exist");
		return -1;}

	var node = nodeList[| nodeInd];
	var boneInd = bindMap[| nodeInd];
	if (boneInd < 0)
	{
		var children = node[eAnimNode.Children];
		if (array_length(children) <= 0)
		{
			show_debug_message("ERROR in script sample_get_node_dq: The given node " + string(nodeInd) + " is not mapped to any bone and does not have any children.");
			array_copy(tempQ, 0, node[eAnimNode.WorldDQ], 0, 8);
			return tempQ;
		}
		for (var i = array_length(children) - 1; i >= 0 && boneInd < 0; i --)
		{
			boneInd = bindMap[| children[i]];
		}
		if (boneInd < 0)
		{
			show_debug_message("ERROR in script sample_get_node_dq: The given node " + string(nodeInd) + " is not mapped to any bone.");
			array_copy(tempQ, 0, node[eAnimNode.WorldDQ], 0, 8);
			return tempQ;
		}
	}

	var b = 8 * boneInd;
	var r3 = sample[b+3];
	var r4 = sample[b+4];
	var r5 = sample[b+5];
	var r6 = sample[b+6];
	if (r3 == 1 && r4 == 0 && r5 == 0 && r6 == 0)
	{	//An early out if this bone has not been transformed, letting us skip a dual quaternion multiplication
		array_copy(tempQ, 0, node[eAnimNode.WorldDQ], 0, 8);
		return tempQ;
	}
	var r0 = sample[b];
	var r1 = sample[b+1];
	var r2 = sample[b+2];
	var r7 = sample[b+7];
	var S = node[eAnimNode.WorldDQ];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	tempQ[@ 0] = r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1;
	tempQ[@ 1] = r3 * s1 + r1 * s3 + r2 * s0 - r0 * s2;
	tempQ[@ 2] = r3 * s2 + r2 * s3 + r0 * s1 - r1 * s0;
	tempQ[@ 3] = r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2;
	tempQ[@ 4] = r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r7 * s0 + r4 * s3 + r5 * s2 - r6 * s1;
	tempQ[@ 5] = r3 * s5 + r1 * s7 + r2 * s4 - r0 * s6 + r7 * s1 + r5 * s3 + r6 * s0 - r4 * s2;
	tempQ[@ 6] = r3 * s6 + r2 * s7 + r0 * s5 - r1 * s4 + r7 * s2 + r6 * s3 + r4 * s1 - r5 * s0;
	tempQ[@ 7] = r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 + r7 * s3 - r4 * s0 - r5 * s1 - r6 * s2;
	return tempQ;
}

/// @func sample_get_node_matrix(rig, nodeInd, sample, [targetMatrix])
function sample_get_node_matrix() 
{	/*	Returns the world orientation of the node as a matrix
		targetMatrix is an optional argument, in case you'd like to output directly to an existing matrix.
		If targetMatrix is not provided, a new matrix is created*/
	var tempQ = global.AnimTempQ4;
	sample_get_node_dq(argument[0], argument[1], argument[2], tempQ);
	if !is_array(tempQ){return matrix_build_identity();}
	smf_dq_normalize(tempQ);
	return smf_mat_create_from_dualquat(tempQ, (argument_count > 3) ? argument[3] : array_create(16));
}

function sample_get_node_position(rig, nodeInd, sample) 
{	//Returns the position of the given node as an array
	return smf_dq_get_translation(sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ4));
}

function sample_fix(rig, sample) 
{	/*	This script will make sure all bones stay attached to their parents
		This is especially useful if you've done a bunch of node transformations
		that may detach bones from their parents.
		This script is a bit heavy, so use with care.*/
	var S = sample;
	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;
	var nodeNum = ds_list_size(nodeList);

	var worldDQ = global.AnimTempWorldDQ;
	if (nodeNum > array_length(worldDQ))
	{	//If the temporary world DQ array doesn't exist, create it and populate it with empty dual quats
		global.AnimTempWorldDQ = array_create(nodeNum);
		for (var i = 0; i < nodeNum; i ++)
		{
			global.AnimTempWorldDQ[i] = array_create(8);
		}
		var worldDQ = global.AnimTempWorldDQ;
	}

	for (var n = 0; n < nodeNum; n ++)
	{
		var b = bindMap[| n];
		if (b < 0){continue;}
		var node = nodeList[| n];
		var pNode = nodeList[| node[eAnimNode.Parent]];
	
		//Normalize sample DQ
		b *= 8;
		var s0 = S[b], s1 = S[b+1], s2 = S[b+2], s3 = S[b+3], s4 = S[b+4], s5 = S[b+5], s6 = S[b+6], s7 = S[b+7];
		var d = s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3;
		if d > 0 && d != 1
		{
			l = 1 / sqrt(d);
			s0 *= l;
			s1 *= l;
			s2 *= l;
			s3 *= l;
			d = s0 * s4 + s1 * s5 + s2 * s6 + s3 * s7;
			s4 = (s4 - s0 * d) * l;
			s5 = (s5 - s1 * d) * l;
			s6 = (s6 - s2 * d) * l;
			s7 = (s7 - s3 * d) * l;
		}
	
		//Find current bone orientation
		var Q = node[eAnimNode.WorldDQ];
		var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
		var w0 = s3 * q0 + s0 * q3 + s1 * q2 - s2 * q1;
		var w1 = s3 * q1 + s1 * q3 + s2 * q0 - s0 * q2;
		var w2 = s3 * q2 + s2 * q3 + s0 * q1 - s1 * q0;
		var w3 = s3 * q3 - s0 * q0 - s1 * q1 - s2 * q2;
		var w4 = s3 * q4 + s0 * q7 + s1 * q6 - s2 * q5 + s7 * q0 + s4 * q3 + s5 * q2 - s6 * q1;
		var w5 = s3 * q5 + s1 * q7 + s2 * q4 - s0 * q6 + s7 * q1 + s5 * q3 + s6 * q0 - s4 * q2;
		var w6 = s3 * q6 + s2 * q7 + s0 * q5 - s1 * q4 + s7 * q2 + s6 * q3 + s4 * q1 - s5 * q0;
		var w7 = s3 * q7 - s0 * q4 - s1 * q5 - s2 * q6 + s7 * q3 - s4 * q0 - s5 * q1 - s6 * q2;
	
		//Now we can continue the loop if the parent node is not a bone
		if !pNode[eAnimNode.IsBone]
		{
			var W = worldDQ[n];
			W[@ 0] = w0; W[@ 1] = w1; W[@ 2] = w2; W[@ 3] = w3; W[@ 4] = w4; W[@ 5] = w5; W[@ 6] = w6; W[@ 7] = w7;
			continue;
		}

		//Find the to-direction of the current bone
		var xto = w3 * w3 + w0 * w0 - w1 * w1 - w2 * w2;
		var yto = 2 * (w0 * w1 + w3 * w2);
		var zto = 2 * (w0 * w2 - w3 * w1);
		var l = xto * xto + yto * yto + zto * zto;
	
		//Find the translation of the parent bone
		var P = worldDQ[node[eAnimNode.Parent]];
		var p0 = P[0], p1 = P[1], p2 = P[2], p3 = P[3], p4 = P[4], p5 = P[5], p6 = P[6], p7 = P[7];
		var px = 2 * (-p7 * p0 + p4 * p3 + p6 * p1 - p5 * p2);
		var py = 2 * (-p7 * p1 + p5 * p3 + p4 * p2 - p6 * p0);
		var pz = 2 * (-p7 * p2 + p6 * p3 + p5 * p0 - p4 * p1);
	
		//Move the current bone so that it is attached to the parent bone in world space
		l = node[eAnimNode.Length] / sqrt(l);
		var nx = px + xto * l;
		var ny = py + yto * l;
		var nz = pz + zto * l;
		w4 = .5 * (nx * w3 + ny * w2 - nz * w1); 
		w5 = .5 * (ny * w3 + nz * w0 - nx * w2);
		w6 = .5 * (nz * w3 + nx * w1 - ny * w0); 
		w7 =-.5 * (nx * w0 + ny * w1 + nz * w2);
	
		var W = worldDQ[n];
		W[@ 0] = w0; W[@ 1] = w1; W[@ 2] = w2; W[@ 3] = w3; W[@ 4] = w4; W[@ 5] = w5; W[@ 6] = w6; W[@ 7] = w7;
	
		//Update the sample
		S[@ b]   = -w3 * q0 + w0 * q3 - w1 * q2 + w2 * q1;
		S[@ b+1] = -w3 * q1 + w1 * q3 - w2 * q0 + w0 * q2;
		S[@ b+2] = -w3 * q2 + w2 * q3 - w0 * q1 + w1 * q0;
		S[@ b+3] = w3 * q3 + w0 * q0 + w1 * q1 + w2 * q2;
		S[@ b+4] = -w3 * q4 + w0 * q7 - w1 * q6 + w2 * q5 - w7 * q0 + w4 * q3 - w5 * q2 + w6 * q1;
		S[@ b+5] = -w3 * q5 + w1 * q7 - w2 * q4 + w0 * q6 - w7 * q1 + w5 * q3 - w6 * q0 + w4 * q2;
		S[@ b+6] = -w3 * q6 + w2 * q7 - w0 * q5 + w1 * q4 - w7 * q2 + w6 * q3 - w4 * q1 + w5 * q0;
		S[@ b+7] = w3 * q7 + w0 * q4 + w1 * q5 + w2 * q6 + w7 * q3 + w4 * q0 + w5 * q1 + w6 * q2;
	}
	return S;
}

function sample_node_drag(rig, nodeInd, sample, newX, newY, newZ, transformChildren) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.

		The end-point of the node will attempt to move towards the target. 
		If the parent node is a bone, it will only point towards the point.*/
	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;
	if (nodeInd < 0 || nodeInd >= ds_list_size(nodeList)){return sample;}

	var cNode = nodeList[| nodeInd];
	var pNode = nodeList[| cNode[eAnimNode.Parent]];
	var cDQ = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);

	if (!cNode[eAnimNode.IsBone])
	{
		var Q = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
		var dx = newX - 2 * (-Q[7] * Q[0] + Q[4] * Q[3] + Q[6] * Q[1] - Q[5] * Q[2]); 
		var dy = newY - 2 * (-Q[7] * Q[1] + Q[5] * Q[3] + Q[4] * Q[2] - Q[6] * Q[0]);
		var dz = newZ - 2 * (-Q[7] * Q[2] + Q[6] * Q[3] + Q[5] * Q[0] - Q[4] * Q[1]);
		sample_node_translate(rig, nodeInd, sample, dx, dy, dz, true);
		exit;
	}

	var cx = 2 * (-cDQ[7] * cDQ[0] + cDQ[4] * cDQ[3] + cDQ[6] * cDQ[1] - cDQ[5] * cDQ[2]); 
	var cy = 2 * (-cDQ[7] * cDQ[1] + cDQ[5] * cDQ[3] + cDQ[4] * cDQ[2] - cDQ[6] * cDQ[0]);
	var cz = 2 * (-cDQ[7] * cDQ[2] + cDQ[6] * cDQ[3] + cDQ[5] * cDQ[0] - cDQ[4] * cDQ[1]);
	var cUpX = 2 * (cDQ[0] * cDQ[2] + cDQ[1] * cDQ[3]);
	var cUpY = 2 * (cDQ[1] * cDQ[2] - cDQ[0] * cDQ[3]);
	var cUpZ = cDQ[3] * cDQ[3] - cDQ[0] * cDQ[0] - cDQ[1] * cDQ[1] + cDQ[2] * cDQ[2];

	var pPos = sample_get_node_position(rig, cNode[eAnimNode.Parent], sample);

	var M = global.AnimTempM;
	var l = sqr(newX - pPos[0]) + sqr(newY - pPos[1]) + sqr(newZ - pPos[2]);
	if (l <= 0){exit;}
	l = 1 / sqrt(l);
	M[@ 0] = (newX - pPos[0]) * l;
	M[@ 1] = (newY - pPos[1]) * l;
	M[@ 2] = (newZ - pPos[2]) * l;
	M[@ 4] = cUpY * M[2] - cUpZ * M[1];
	M[@ 5] = cUpZ * M[0] - cUpX * M[2];
	M[@ 6] = cUpX * M[1] - cUpY * M[0];
	var l = M[4] * M[4] + M[5] * M[5] + M[6] * M[6];
	if (l <= 0){exit;}
	l = 1 / sqrt(l);
	M[@ 4] *= l;
	M[@ 5] *= l;
	M[@ 6] *= l;
	M[@ 8]  = M[1] * M[6] - M[2] * M[5];
	M[@ 9]  = M[2] * M[4] - M[0] * M[6];
	M[@ 10] = M[0] * M[5] - M[1] * M[4];
	var len = cNode[eAnimNode.Length];
	M[@ 12] = pPos[0] + M[0] * len;
	M[@ 13] = pPos[1] + M[1] * len;
	M[@ 14] = pPos[2] + M[2] * len;
	var R = smf_dq_create_from_matrix(M, global.AnimTempQ3);
	if (R[0] * cDQ[0] + R[1] * cDQ[1] + R[2] * cDQ[2] + R[3] * cDQ[3] < 0){R[@ 0] *= -1; R[@ 1] *= -1; R[@ 2] *= -1; R[@ 3] *= -1; R[@ 4] *= -1; R[@ 5] *= -1; R[@ 6] *= -1; R[@ 7] *= -1;}
	var b = 8 * bindMap[| nodeInd];
	var S = cNode[eAnimNode.WorldDQConjugate];
	sample[@ b]   = R[3] * S[0] + R[0] * S[3] + R[1] * S[2] - R[2] * S[1];
	sample[@ b+1] = R[3] * S[1] + R[1] * S[3] + R[2] * S[0] - R[0] * S[2];
	sample[@ b+2] = R[3] * S[2] + R[2] * S[3] + R[0] * S[1] - R[1] * S[0];
	sample[@ b+3] = R[3] * S[3] - R[0] * S[0] - R[1] * S[1] - R[2] * S[2];
	sample[@ b+4] = R[3] * S[4] + R[0] * S[7] + R[1] * S[6] - R[2] * S[5] + R[7] * S[0] + R[4] * S[3] + R[5] * S[2] - R[6] * S[1];
	sample[@ b+5] = R[3] * S[5] + R[1] * S[7] + R[2] * S[4] - R[0] * S[6] + R[7] * S[1] + R[5] * S[3] + R[6] * S[0] - R[4] * S[2];
	sample[@ b+6] = R[3] * S[6] + R[2] * S[7] + R[0] * S[5] - R[1] * S[4] + R[7] * S[2] + R[6] * S[3] + R[4] * S[1] - R[5] * S[0];
	sample[@ b+7] = R[3] * S[7] - R[0] * S[4] - R[1] * S[5] - R[2] * S[6] + R[7] * S[3] - R[4] * S[0] - R[5] * S[1] - R[6] * S[2];

	var children = cNode[eAnimNode.Children];
	var num = array_length(children);
	if transformChildren
	{
		var Q = global.AnimTempQ2;
		var S = cDQ;
		S[@ 0] = -S[0];
		S[@ 1] = -S[1];
		S[@ 2] = -S[2];
		S[@ 4] = -S[4];
		S[@ 5] = -S[5];
		S[@ 6] = -S[6];
		Q[@ 0] = R[3] * S[0] + R[0] * S[3] + R[1] * S[2] - R[2] * S[1];
		Q[@ 1] = R[3] * S[1] + R[1] * S[3] + R[2] * S[0] - R[0] * S[2];
		Q[@ 2] = R[3] * S[2] + R[2] * S[3] + R[0] * S[1] - R[1] * S[0];
		Q[@ 3] = R[3] * S[3] - R[0] * S[0] - R[1] * S[1] - R[2] * S[2];
		Q[@ 4] = R[3] * S[4] + R[0] * S[7] + R[1] * S[6] - R[2] * S[5] + R[7] * S[0] + R[4] * S[3] + R[5] * S[2] - R[6] * S[1];
		Q[@ 5] = R[3] * S[5] + R[1] * S[7] + R[2] * S[4] - R[0] * S[6] + R[7] * S[1] + R[5] * S[3] + R[6] * S[0] - R[4] * S[2];
		Q[@ 6] = R[3] * S[6] + R[2] * S[7] + R[0] * S[5] - R[1] * S[4] + R[7] * S[2] + R[6] * S[3] + R[4] * S[1] - R[5] * S[0];
		Q[@ 7] = R[3] * S[7] - R[0] * S[4] - R[1] * S[5] - R[2] * S[6] + R[7] * S[3] - R[4] * S[0] - R[5] * S[1] - R[6] * S[2];
		for (var i = 0; i < num; i ++)
		{
			sample_node_transform(rig, children[i], sample, Q, transformChildren);
		}
	}
	else
	{
		for (var i = 0; i < num; i ++)
		{
			sample_node_translate(rig, children[i], sample, M[@ 12] - cx, M[@ 13] - cy, M[@ 14] - cz, true);
		}
	}

	return [M[@ 12], M[@ 13], M[@ 14]];
}

function sample_node_yaw(rig, nodeInd, sample, radians, transformChildren) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.*/
	var Q = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ4);
	if !is_array(Q){return sample;}
	var node = rig.nodeList[| nodeInd];

	//Find world-space axis to rotate around
	var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	var aX = s * 2 * (q2 * q0 + q3 * q1);
	var aY = s * 2 * (q2 * q1 - q3 * q0);
	var aZ = s * (q3 * q3 - q0 * q0 - q1 * q1 + q2 * q2);

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	if (node[eAnimNode.IsBone])
	{
		smf_dq_multiply(Q, node[eAnimNode.LocalDQConjugate], Q);
		var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
	}
	var pX = 2 * (-q7 * q0 + q4 * q3 + q6 * q1 - q5 * q2);
	var pY = 2 * (-q7 * q1 + q5 * q3 + q4 * q2 - q6 * q0);
	var pZ = 2 * (-q7 * q2 + q6 * q3 + q5 * q0 - q4 * q1);

	//Reuse the array that was created earlier and create new transformation dual quaternion
	Q[@ 0] = aX;
	Q[@ 1] = aY;
	Q[@ 2] = aZ;
	Q[@ 3] = c;
	Q[@ 4] = pY * aZ - pZ * aY;
	Q[@ 5] = pZ * aX - pX * aZ;
	Q[@ 6] = pX * aY - pY * aX;
	Q[@ 7] = 0;

	//Transform the node and all its descendants in the sample
	sample_node_transform(rig, nodeInd, sample, Q, transformChildren);

	//Superfluous return statement, but return the sample anyway
	return sample;


}

function sample_node_pitch(rig, nodeInd, sample, radians, transformChildren)
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.*/
	var Q = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ4);
	if !is_array(Q){return sample;}
	var node = rig.nodeList[| nodeInd];

	//Find world-space axis to rotate around
	var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	var aX = s * 2 * (q0 * q1 - q2 * q3);
	var aY = s * (q3 * q3 - q0 * q0 + q1 * q1 - q2 * q2);
	var aZ = s * 2 * (q1 * q2 + q0 * q3);

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	if (node[eAnimNode.IsBone])
	{
		smf_dq_multiply(Q, node[eAnimNode.LocalDQConjugate], Q);
		var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
	}
	var pX = 2 * (-q7 * q0 + q4 * q3 + q6 * q1 - q5 * q2);
	var pY = 2 * (-q7 * q1 + q5 * q3 + q4 * q2 - q6 * q0);
	var pZ = 2 * (-q7 * q2 + q6 * q3 + q5 * q0 - q4 * q1);

	//Reuse the array that was created earlier and create new transformation dual quaternion
	Q[@ 0] = aX;
	Q[@ 1] = aY;
	Q[@ 2] = aZ;
	Q[@ 3] = c;
	Q[@ 4] = pY * aZ - pZ * aY;
	Q[@ 5] = pZ * aX - pX * aZ;
	Q[@ 6] = pX * aY - pY * aX;
	Q[@ 7] = 0;

	//Transform the node and all its descendants in the sample
	sample_node_transform(rig, nodeInd, sample, Q, transformChildren);

	//Superfluous return statement, but return the sample anyway
	return sample;
}

function sample_node_roll(rig, nodeInd, sample, radians, transformChildren)
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.*/
	var Q = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ4);
	if !is_array(Q){return sample;}
	var node = rig.nodeList[| nodeInd];

	//Find world-space axis to rotate around
	var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	var aX = s * (q3 * q3 + q0 * q0 - q1 * q1 - q2 * q2);
	var aY = s * 2 * (q0 * q1 + q3 * q2);
	var aZ = s * 2 * (q0 * q2 - q3 * q1);

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	if (node[eAnimNode.IsBone])
	{
		smf_dq_multiply(Q, node[eAnimNode.LocalDQConjugate], Q);
		var q0 = Q[0], q1 = Q[1], q2 = Q[2], q3 = Q[3], q4 = Q[4], q5 = Q[5], q6 = Q[6], q7 = Q[7];
	}
	var pX = 2 * (-q7 * q0 + q4 * q3 + q6 * q1 - q5 * q2);
	var pY = 2 * (-q7 * q1 + q5 * q3 + q4 * q2 - q6 * q0);
	var pZ = 2 * (-q7 * q2 + q6 * q3 + q5 * q0 - q4 * q1);

	//Reuse the array that was created earlier and create new transformation dual quaternion
	Q[@ 0] = aX;
	Q[@ 1] = aY;
	Q[@ 2] = aZ;
	Q[@ 3] = c;
	Q[@ 4] = pY * aZ - pZ * aY;
	Q[@ 5] = pZ * aX - pX * aZ;
	Q[@ 6] = pX * aY - pY * aX;
	Q[@ 7] = 0;

	//Transform the node and all its descendants in the sample
	sample_node_transform(rig, nodeInd, sample, Q, transformChildren);

	//Superfluous return statement, but return the sample anyway
	return sample;
}

function sample_node_rotate_x(rig, nodeInd, sample, radians) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.
		The node will rotate around its parent's position. If the node is not a bone, it will rotate around its own position.*/
	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;
	if (nodeInd < 0 || nodeInd >= ds_list_size(nodeList)){return sample;}
	var node = nodeList[| nodeInd];
	var Q = node[eAnimNode.IsBone] ? sample_get_node_dq(rig, node[eAnimNode.Parent], sample, global.AnimTempQ1) : sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
	if (!is_array(Q)){return sample;}

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	//Contents copied from dq_get_translation
	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	var pY = - s * 2 * (-Q[7] * Q[1] + Q[5] * Q[3] + Q[4] * Q[2] - Q[6] * Q[0]);
	var pZ = s * 2 * (-Q[7] * Q[2] + Q[6] * Q[3] + Q[5] * Q[0] - Q[4] * Q[1]);

	var descendants = node[eAnimNode.Descendants];
	var num = array_length(descendants);
	var b = bindMap[| nodeInd];

	//Transform this node and all its descendants
	for (var i = 0; i <= num; i ++)
	{
		if (b >= 0)
		{
			b *= 8;
			var s0 = sample[b];
			var s1 = sample[b+1];
			var s2 = sample[b+2];
			var s3 = sample[b+3];
			var s4 = sample[b+4];
			var s5 = sample[b+5];
			var s6 = sample[b+6];
			var s7 = sample[b+7];
			sample[@ b]	  = c * s0 + s * s3;
			sample[@ b+1] = c * s1 - s * s2;
			sample[@ b+2] = c * s2 + s * s1;
			sample[@ b+3] = c * s3 - s * s0;
			sample[@ b+4] = c * s4 + s * s7 + pZ * s2 + pY * s1;
			sample[@ b+5] = c * s5 - s * s6 + pZ * s3 - pY * s0;
			sample[@ b+6] = c * s6 + s * s5 - pZ * s0 - pY * s3;
			sample[@ b+7] = c * s7 - s * s4 - pZ * s1 + pY * s2;
		}
		if (i < num)
		{
			b = bindMap[| descendants[i]];
		}
	}
	return sample;
}

function sample_node_rotate_y(rig, nodeInd, sample, radians) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.
		The node will rotate around its parent's position. If the node is not a bone, it will rotate around its own position.*/
	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;
	if (nodeInd < 0 || nodeInd >= ds_list_size(nodeList)){return sample;}
	var node = nodeList[| nodeInd];
	var Q = node[eAnimNode.IsBone] ? sample_get_node_dq(rig, node[eAnimNode.Parent], sample, global.AnimTempQ1) : sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
	if (!is_array(Q)){return sample;}

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	//Contents copied from dq_get_translation
	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	var pX = s * 2 * (-Q[7] * Q[0] + Q[4] * Q[3] + Q[6] * Q[1] - Q[5] * Q[2]);
	var pZ = - s * 2 * (-Q[7] * Q[2] + Q[6] * Q[3] + Q[5] * Q[0] - Q[4] * Q[1]);

	var descendants = node[eAnimNode.Descendants];
	var num = array_length(descendants);
	var b = bindMap[| nodeInd];

	//Transform this node and all its descendants
	for (var i = 0; i <= num; i ++)
	{
		if (b >= 0)
		{
			b *= 8;
			var s0 = sample[b];
			var s1 = sample[b+1];
			var s2 = sample[b+2];
			var s3 = sample[b+3];
			var s4 = sample[b+4];
			var s5 = sample[b+5];
			var s6 = sample[b+6];
			var s7 = sample[b+7];
			sample[@ b]	  = c * s0 + s * s2;
			sample[@ b+1] = c * s1 + s * s3;
			sample[@ b+2] = c * s2 - s * s0;
			sample[@ b+3] = c * s3 - s * s1;
			sample[@ b+4] = c * s4 + s * s6 - pX * s1 + pZ * s3;
			sample[@ b+5] = c * s5 + s * s7 + pX * s0 - pZ * s2;
			sample[@ b+6] = c * s6 - s * s4 + pX * s3 + pZ * s1;
			sample[@ b+7] = c * s7 - s * s5 - pX * s2 - pZ * s0;
		}
		if (i < num)
		{
			b = bindMap[| descendants[i]];
		}
	}
	return sample;
}

function sample_node_rotate_z(rig, nodeInd, sample, radians) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.
		The node will rotate around its parent's position. If the node is not a bone, it will rotate around its own position.*/
	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;
	if (nodeInd < 0 || nodeInd >= ds_list_size(nodeList)){return sample;}
	var node = nodeList[| nodeInd];
	var Q = node[eAnimNode.IsBone] ? sample_get_node_dq(rig, node[eAnimNode.Parent], sample, global.AnimTempQ1) : sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
	if (!is_array(Q)){return sample;}

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	//Contents copied from dq_get_translation
	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	var pX = - s * 2 * (-Q[7] * Q[0] + Q[4] * Q[3] + Q[6] * Q[1] - Q[5] * Q[2]);
	var pY = s * 2 * (-Q[7] * Q[1] + Q[5] * Q[3] + Q[4] * Q[2] - Q[6] * Q[0]);

	var descendants = node[eAnimNode.Descendants];
	var num = array_length(descendants);
	var b = bindMap[| nodeInd];

	//Transform this node and all its descendants
	for (var i = 0; i <= num; i ++)
	{
		if (b >= 0)
		{
			b *= 8;
			var s0 = sample[b];
			var s1 = sample[b+1];
			var s2 = sample[b+2];
			var s3 = sample[b+3];
			var s4 = sample[b+4];
			var s5 = sample[b+5];
			var s6 = sample[b+6];
			var s7 = sample[b+7];
			sample[@ b]	  = c * s0 - s * s1;
			sample[@ b+1] = c * s1 + s * s0;
			sample[@ b+2] = c * s2 + s * s3;
			sample[@ b+3] = c * s3 - s * s2;
			sample[@ b+4] = c * s4 - s * s5 + pX * s2 + pY * s3;
			sample[@ b+5] = c * s5 + s * s4 + pX * s3 - pY * s2;
			sample[@ b+6] = c * s6 + s * s7 - pX * s0 + pY * s1;
			sample[@ b+7] = c * s7 - s * s6 - pX * s1 - pY * s0;
		}
		if (i < num)
		{
			b = bindMap[| descendants[i]];
		}
	}
	return sample;
}

function sample_node_rotate_axis(rig, nodeInd, sample, radians, aX, aY, aZ, transformChildren) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.
		The node will rotate around its parent's position. If the node is not a bone, it will rotate around its own position*/

	//Load arguments
	var nodeList = rig.nodeList;
	if (nodeInd < 0 || nodeInd >= ds_list_size(nodeList)){return sample;}
	var node = nodeList[| nodeInd];

	radians *= .5;
	var s = sin(radians);
	var c = cos(radians);
	aX *= s;
	aY *= s;
	aZ *= s;
	var Q = node[eAnimNode.IsBone] ? sample_get_node_dq(rig, node[eAnimNode.Parent], sample, global.AnimTempQ4) : sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ4);

	//Find the pivot position (position of the root of the bone, typically at the parent's position)
	//Contents copied from dq_get_translation
	var pX = 2 * (-Q[7] * Q[0] + Q[4] * Q[3] + Q[6] * Q[1] - Q[5] * Q[2]);
	var pY = 2 * (-Q[7] * Q[1] + Q[5] * Q[3] + Q[4] * Q[2] - Q[6] * Q[0]);
	var pZ = 2 * (-Q[7] * Q[2] + Q[6] * Q[3] + Q[5] * Q[0] - Q[4] * Q[1]);

	//Reuse the array that was created earlier and create new transformation dual quaternion
	Q[@ 0] = aX;
	Q[@ 1] = aY;
	Q[@ 2] = aZ;
	Q[@ 3] = c;
	Q[@ 4] = pY * aZ - pZ * aY;
	Q[@ 5] = pZ * aX - pX * aZ;
	Q[@ 6] = pX * aY - pY * aX;
	Q[@ 7] = 0;

	//Transform the node and all its descendants in the sample
	sample_node_transform(rig, nodeInd, sample, Q, transformChildren);

	//Superfluous return statement, but return the sample anyway
	return sample;
}

function sample_normalize(sample) 
{	/*	Normalizes a sample.
		Useful after you've modified a sample to make sure all dual quats are normalized.*/
	var S = sample;
	var i = array_length(S);
	repeat (i div 8)
	{
		i -= 8;
		var l = S[i] * S[i] + S[i+1] * S[i+1] + S[i+2] * S[i+2] + S[i+3] * S[i+3];
		if (l != 1 && l != 0)
		{
			l = 1 / sqrt(l);
			S[@ i]	 *= l
			S[@ i+1] *= l
			S[@ i+2] *= l
			S[@ i+3] *= l
		}
		var d = S[i] * S[i+4] + S[i+1] * S[i+5] + S[i+2] * S[i+6] + S[i+3] * S[i+7];
		if (d != 0)
		{
			S[@ i+4] = (S[i+4] - S[i]   * d) * l;
			S[@ i+5] = (S[i+5] - S[i+1] * d) * l;
			S[@ i+6] = (S[i+6] - S[i+2] * d) * l;
			S[@ i+7] = (S[i+7] - S[i+3] * d) * l;
		}
	}
}

function sample_node_move(rig, nodeInd, sample, newX, newY, newZ, moveFromCurrent, transformChildren) 
{	/*	This script lets you modify a sample.

		The end-point of the node will move to the given position, and the parent and grandparent will attempt to follow using inverse kinematics. 
		Any descendants of the node will also move.*/
	var nodeList = rig.nodeList;

	var cNode = nodeList[| nodeInd];
	var pNode = nodeList[| cNode[eAnimNode.Parent]];

	//If the parent is a bone and the parent is not locked, use the IK script on the selected node
	if (cNode[eAnimNode.IsBone] && pNode[eAnimNode.IsBone] && !pNode[eAnimNode.Locked])
	{
		sample_node_ik(rig, nodeInd, sample, newX, newY, newZ, moveFromCurrent, transformChildren);
		exit;
	}

	//If the parent is not a bone, drag the end-point of the bone towards the new position
	sample_node_drag(rig, nodeInd, sample, newX, newY, newZ, transformChildren)
}

function sample_node_move_fast(rig, nodeInd, sample, newX, newY, newZ, moveFromCurrent, transformChildren)
{	/*	This script lets you modify a sample.

		The end-point of the node will move to the given position, and the parent and grandparent will attempt to follow using inverse kinematics. 
		Any descendants of the node will also move.*/
	var nodeList = rig.nodeList;
	var bindMap = rig.bindMap;

	var cNode = nodeList[| nodeInd];
	var pNode = nodeList[| cNode[eAnimNode.Parent]];

	//If this node is not a bone, just move it
	if (!cNode[eAnimNode.IsBone])
	{
		var Q = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
		var dx = newX - 2 * (-Q[7] * Q[0] + Q[4] * Q[3] + Q[6] * Q[1] - Q[5] * Q[2]); 
		var dy = newY - 2 * (-Q[7] * Q[1] + Q[5] * Q[3] + Q[4] * Q[2] - Q[6] * Q[0]);
		var dz = newZ - 2 * (-Q[7] * Q[2] + Q[6] * Q[3] + Q[5] * Q[0] - Q[4] * Q[1]);
		sample_node_translate(rig, nodeInd, sample, dx, dy, dz, true);
		return true;
	}

	//If the parent is a bone and the parent is not locked, simply use the IK script on the selected node
	if (pNode[eAnimNode.IsBone] && !pNode[eAnimNode.Locked])
	{
		sample_node_ik_fast(rig, nodeInd, sample, newX, newY, newZ, moveFromCurrent, transformChildren);
		return true;
	}

	//If the parent is not a bone, drag the end-point of the bone towards the new position
	sample_node_drag(rig, nodeInd, sample, newX, newY, newZ, transformChildren)
	return true;
}

function sample_node_ik(rig, nodeInd, sample, newX, newY, newZ, moveFromCurrent, transformChildren) 
{	/*	Snidr's Two-joint Inverse Kinematics Algorithm
		This is a two-joint IK algorithm I've invented myself. It is a very crude way of doing inverse kinematics, but it works well for small adjustments of foot position and the like.

		The algorithm will move the given node and its parent.
		If transformChildren is set to true, it will also rotate the children of the given node. If it's false, it will only translate them so that they don't get detached.
	
		This version of the script should be stable for any position. IK is performed by rotating the child and parent nodes around the primary axis (which is either
		defined in the model tool, or created on the fly using an educated guess), and then around a perpendicular axis. This makes sure bones are never twisted in unnatural
		angles.
	
		Set moveFromCurrent to true if you'd like the primary axis to rotate according to the current orientation of the parent bone.
		For most cases, this option can be set to false.*/

	/*//////////////////////////////////////////////////////////////
			Find child, parent, and grandparent nodes
	*///////////////////////////////////////////////////////////////
	var bindMap = rig.bindMap;
	var nodeList = rig.nodeList;
	var cNode = nodeList[| nodeInd];
	var pNode = nodeList[| cNode[eAnimNode.Parent]];
	var gNode = nodeList[| pNode[eAnimNode.Parent]];
	if (!cNode[eAnimNode.IsBone] || !pNode[eAnimNode.IsBone])
	{
		show_debug_message("Error in script sample_node_ik: Cannot perform inverse kinematics on nodes that aren't bones"); 
		exit;
	}

	/*///////////////////////////////////////////////////////////////
			Find child node dual quat, position and up-vector
	*////////////////////////////////////////////////////////////////
	var Cb = 8 * bindMap[| nodeInd];
	var r0 = sample[Cb];
	var r1 = sample[Cb+1];
	var r2 = sample[Cb+2];
	var r3 = sample[Cb+3];
	var r4 = sample[Cb+4];
	var r5 = sample[Cb+5];
	var r6 = sample[Cb+6];
	var r7 = sample[Cb+7];
	var S = cNode[eAnimNode.WorldDQ];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	var C0 = r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1;
	var C1 = r3 * s1 + r1 * s3 + r2 * s0 - r0 * s2;
	var C2 = r3 * s2 + r2 * s3 + r0 * s1 - r1 * s0;
	var C3 = r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2;
	var C4 = r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r7 * s0 + r4 * s3 + r5 * s2 - r6 * s1;
	var C5 = r3 * s5 + r1 * s7 + r2 * s4 - r0 * s6 + r7 * s1 + r5 * s3 + r6 * s0 - r4 * s2;
	var C6 = r3 * s6 + r2 * s7 + r0 * s5 - r1 * s4 + r7 * s2 + r6 * s3 + r4 * s1 - r5 * s0;
	var C7 = r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 + r7 * s3 - r4 * s0 - r5 * s1 - r6 * s2;
	var Cx = 2 * (-C7 * C0 + C4 * C3 + C6 * C1 - C5 * C2);
	var Cy = 2 * (-C7 * C1 + C5 * C3 + C4 * C2 - C6 * C0);
	var Cz = 2 * (-C7 * C2 + C6 * C3 + C5 * C0 - C4 * C1);
	var Cupx = 2 * (C0 * C2 + C1 * C3);
	var Cupy = 2 * (C1 * C2 - C0 * C3);
	var Cupz = C3 * C3 - C0 * C0 - C1 * C1 + C2 * C2;

	/*/////////////////////////////////////////////////////////////////
			Find parent node dual quat, position and up-vector
	*//////////////////////////////////////////////////////////////////
	var Pb = 8 * bindMap[| cNode[eAnimNode.Parent]];
	var r0 = sample[Pb];
	var r1 = sample[Pb+1];
	var r2 = sample[Pb+2];
	var r3 = sample[Pb+3];
	var r4 = sample[Pb+4];
	var r5 = sample[Pb+5];
	var r6 = sample[Pb+6];
	var r7 = sample[Pb+7];
	var S = pNode[eAnimNode.WorldDQ];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	var P0 = r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1;
	var P1 = r3 * s1 + r1 * s3 + r2 * s0 - r0 * s2;
	var P2 = r3 * s2 + r2 * s3 + r0 * s1 - r1 * s0;
	var P3 = r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2;
	var P4 = r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r7 * s0 + r4 * s3 + r5 * s2 - r6 * s1;
	var P5 = r3 * s5 + r1 * s7 + r2 * s4 - r0 * s6 + r7 * s1 + r5 * s3 + r6 * s0 - r4 * s2;
	var P6 = r3 * s6 + r2 * s7 + r0 * s5 - r1 * s4 + r7 * s2 + r6 * s3 + r4 * s1 - r5 * s0;
	var P7 = r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 + r7 * s3 - r4 * s0 - r5 * s1 - r6 * s2;
	var Px = 2 * (-P7 * P0 + P4 * P3 + P6 * P1 - P5 * P2);
	var Py = 2 * (-P7 * P1 + P5 * P3 + P4 * P2 - P6 * P0);
	var Pz = 2 * (-P7 * P2 + P6 * P3 + P5 * P0 - P4 * P1);
	var Pupx = 2 * (P0 * P2 + P1 * P3);
	var Pupy = 2 * (P1 * P2 - P0 * P3);
	var Pupz = P3 * P3 - P0 * P0 - P1 * P1 + P2 * P2;

	/*/////////////////////////////////////////////////////////////////////
			Find grandparent node dual quat, position and up-vector
	*//////////////////////////////////////////////////////////////////////
	var S = gNode[eAnimNode.WorldDQ];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	var G0 = r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1;
	var G1 = r3 * s1 + r1 * s3 + r2 * s0 - r0 * s2;
	var G2 = r3 * s2 + r2 * s3 + r0 * s1 - r1 * s0;
	var G3 = r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2;
	var G4 = r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r7 * s0 + r4 * s3 + r5 * s2 - r6 * s1;
	var G5 = r3 * s5 + r1 * s7 + r2 * s4 - r0 * s6 + r7 * s1 + r5 * s3 + r6 * s0 - r4 * s2;
	var G6 = r3 * s6 + r2 * s7 + r0 * s5 - r1 * s4 + r7 * s2 + r6 * s3 + r4 * s1 - r5 * s0;
	var G7 = r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 + r7 * s3 - r4 * s0 - r5 * s1 - r6 * s2;
	var Gx = 2 * (-G7 * G0 + G4 * G3 + G6 * G1 - G5 * G2);
	var Gy = 2 * (-G7 * G1 + G5 * G3 + G4 * G2 - G6 * G0);
	var Gz = 2 * (-G7 * G2 + G6 * G3 + G5 * G0 - G4 * G1);

	/*////////////////////////////////////////////////////////
			Find start position and bone vectors
	*/////////////////////////////////////////////////////////
	var oldX = Cx;
	var oldY = Cy;
	var oldZ = Cz;
	var pOldX = Px;
	var pOldY = Py;
	var pOldZ = Pz;
	var GtoCx = Cx - Gx;
	var GtoCy = Cy - Gy;
	var GtoCz = Cz - Gz;
	var GtoPx = Px - Gx;
	var GtoPy = Py - Gy;
	var GtoPz = Pz - Gz;
	var GtoNx = newX - Gx;
	var GtoNy = newY - Gy;
	var GtoNz = newZ - Gz;

	/*////////////////////////////////////////////////////
			Find distance between the bones
	*/////////////////////////////////////////////////////
	var p_c = cNode[eAnimNode.Length]; //Parent to Child
	var g_p = pNode[eAnimNode.Length]; //Grandparent to Parent
	var g_n = sqrt(GtoNx * GtoNx + GtoNy * GtoNy + GtoNz * GtoNz); //Grandparent to new position

	/*////////////////////////////////////////////////////
			Limit the distance from G to new pos
	*/////////////////////////////////////////////////////
	var a = clamp(g_n, abs(g_p - p_c) + g_p * .01, (g_p + p_c) * .99);
	if (a != g_n)
	{
		var d = a / g_n;
		GtoNx *= d;
		GtoNy *= d;
		GtoNz *= d;
		newX = Gx + GtoNx;
		newY = Gy + GtoNy;
		newZ = Gz + GtoNz;
		g_n = a;
	}

	/*////////////////////////////////////////////////////////////////////////////////////////////////////////
		Find the middle point within the intersection between two spheres, one placed at the grandparent
		and one placed at the new position, with radii the length of the parent bone and the length of
		the child bone respectively.
		Also find the distance from this middle point to the parent (named here as "intersectionRadius")
	*/////////////////////////////////////////////////////////////////////////////////////////////////////////
	var g_nsqr = g_n * g_n;
	var p_csqr = p_c * p_c;
	var g_psqr = g_p * g_p;
	var intersectionRadius = sqrt(p_csqr - sqr(g_psqr - p_csqr - g_nsqr) / (4 * g_nsqr));
	var l = sqrt(g_psqr - intersectionRadius * intersectionRadius) / g_n;
	if (g_nsqr < p_csqr - g_psqr){l = -l;} //If the child is too close to the grandparent, the "middle" point is on the other side of the grandparent, and l must be negative
	var middleX = Gx + GtoNx * l;
	var middleY = Gy + GtoNy * l;
	var middleZ = Gz + GtoNz * l;

	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////
		The next step is to rotate around the primary axis (which has either been defined in the model 
		tool, or will be created using info already available)
	*//////////////////////////////////////////////////////////////////////////////////////////////////////////
	var primaryAxis = cNode[eAnimNode.PrimaryAxis];
	if (!moveFromCurrent && is_array(primaryAxis))
	{
		var primX = primaryAxis[0];
		var primY = primaryAxis[1];
		var primZ = primaryAxis[2];
	}
	else
	{
		var primX = Cx - Px;
		var primY = Cy - Py;
		var primZ = Cz - Pz;
		var axisX = GtoPx + GtoCx;
		var axisY = GtoPy + GtoCy;
		var axisZ = GtoPz + GtoCz;
		var dp = (primX * axisX + primY * axisY + primZ * axisZ) / (axisX * axisX + axisY * axisY + axisZ * axisZ);
		primX -= axisX * dp;
		primY -= axisY * dp;
		primZ -= axisZ * dp;
		var l = primX * primX + primY * primY + primZ * primZ;
		if (l == 0)
		{
			return false;
		}
		l = 1 / sqrt(l);
		primX *= l;
		primY *= l;
		primZ *= l;
		if !moveFromCurrent
		{
			cNode[@ eAnimNode.PrimaryAxis] = [primX, primY, primZ];
		}
	}

	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////
		Usually, you would use the vectors available to find an angle to rotate around.
		However, we can use some vector trickery to find the sine and cosine of the angle directly, 
		completely avoiding trigonometric functions altogether.
	*//////////////////////////////////////////////////////////////////////////////////////////////////////////
	var dp = primX * GtoCx + primY * GtoCy + primZ * GtoCz;
	var oldDx = GtoCx - dp * primX;
	var oldDy = GtoCy - dp * primY;
	var oldDz = GtoCz - dp * primZ;

	var dp = primX * GtoNx + primY * GtoNy + primZ * GtoNz;
	var newDx = GtoNx - dp * primX;
	var newDy = GtoNy - dp * primY;
	var newDz = GtoNz - dp * primZ;

	var l = (oldDx * oldDx + oldDy * oldDy + oldDz * oldDz) * (newDx * newDx + newDy * newDy + newDz * newDz);
	if (l == 0){return false;}
	var l = 1 / sqrt(l);
	var _sin = l * ((oldDy * newDz - oldDz * newDy) * primX + (oldDz * newDx - oldDx * newDz) * primY + (oldDx * newDy - oldDy * newDx) * primZ);
	var _cos = l * (oldDx * newDx + oldDy * newDy + oldDz * newDz);

	/*/////////////////////////////////////////////////////////////////////////////////
			Find the new temporary orientations of the child and parent bones
	*//////////////////////////////////////////////////////////////////////////////////
	var rx = GtoCx, ry = GtoCy, rz = GtoCz;
	var d = (1 - _cos) * (primX * rx + primY * ry + primZ * rz);
	GtoCx = rx * _cos + primX * d + (primY * rz - primZ * ry) * _sin;
	GtoCy = ry * _cos + primY * d + (primZ * rx - primX * rz) * _sin;
	GtoCz = rz * _cos + primZ * d + (primX * ry - primY * rx) * _sin;

	var rx = Cupx, ry = Cupy, rz = Cupz;
	var d = (1 - _cos) * (primX * rx + primY * ry + primZ * rz);
	Cupx = rx * _cos + primX * d + (primY * rz - primZ * ry) * _sin;
	Cupy = ry * _cos + primY * d + (primZ * rx - primX * rz) * _sin;
	Cupz = rz * _cos + primZ * d + (primX * ry - primY * rx) * _sin;

	var rx = GtoPx, ry = GtoPy, rz = GtoPz;
	var d = (1 - _cos) * (primX * rx + primY * ry + primZ * rz);
	GtoPx = rx * _cos + primX * d + (primY * rz - primZ * ry) * _sin;
	GtoPy = ry * _cos + primY * d + (primZ * rx - primX * rz) * _sin;
	GtoPz = rz * _cos + primZ * d + (primX * ry - primY * rx) * _sin;

	var rx = Pupx, ry = Pupy, rz = Pupz;
	var d = (1 - _cos) * (primX * rx + primY * ry + primZ * rz);
	Pupx = rx * _cos + primX * d + (primY * rz - primZ * ry) * _sin;
	Pupy = ry * _cos + primY * d + (primZ * rx - primX * rz) * _sin;
	Pupz = rz * _cos + primZ * d + (primX * ry - primY * rx) * _sin;

	/*///////////////////////////////////////////////////////////////////////////////////////
		The algorithm is more robust if we also rotate around a secondary axis, which is
		perpendicular to the primary axis. This is not necessary for small adjustments, 
		but is needed for larger movements.
	*////////////////////////////////////////////////////////////////////////////////////////
	var secX = GtoCy * primZ - GtoCz * primY;
	var secY = GtoCz * primX - GtoCx * primZ;
	var secZ = GtoCx * primY - GtoCy * primX;
	var l = secX * secX + secY * secY + secZ * secZ;
	if (l == 0){return false;}
	var l = 1 / sqrt(l);
	secX *= l;
	secY *= l;
	secZ *= l;

	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////
		Usually, you would use the vectors available to find an angle to rotate around.
		However, we can use some vector trickery to find the sine and cosine of the angle directly, 
		completely avoiding trigonometric functions altogether.
	*//////////////////////////////////////////////////////////////////////////////////////////////////////////
	var oldDx, oldDy, oldDz;
	dp = secX * GtoCx + secY * GtoCy + secZ * GtoCz;
	oldDx = GtoCx - dp * secX;
	oldDy = GtoCy - dp * secY;
	oldDz = GtoCz - dp * secZ;

	var newDx, newDy, newDz;
	dp = secX * GtoNx + secY * GtoNy + secZ * GtoNz;
	newDx = GtoNx - dp * secX;
	newDy = GtoNy - dp * secY;
	newDz = GtoNz - dp * secZ;

	var l = (oldDx * oldDx + oldDy * oldDy + oldDz * oldDz) * (newDx * newDx + newDy * newDy + newDz * newDz);
	if (l == 0){return false;}
	var l = 1 / sqrt(l);
	var _sin = l * ((oldDy * newDz - oldDz * newDy) * secX + (oldDz * newDx - oldDx * newDz) * secY + (oldDx * newDy - oldDy * newDx) * secZ);
	var _cos = l * (oldDx * newDx + oldDy * newDy + oldDz * newDz);

	/*/////////////////////////////////////////////////////////////////////////////////
			Find the new temporary orientations of the child and parent bones
	*//////////////////////////////////////////////////////////////////////////////////
	var rx = Cupx, ry = Cupy, rz = Cupz;
	var d = (1 - _cos) * (secX * rx + secY * ry + secZ * rz);
	Cupx = rx * _cos + secX * d + (secY * rz - secZ * ry) * _sin;
	Cupy = ry * _cos + secY * d + (secZ * rx - secX * rz) * _sin;
	Cupz = rz * _cos + secZ * d + (secX * ry - secY * rx) * _sin;

	var rx = GtoPx, ry = GtoPy, rz = GtoPz;
	var d = (1 - _cos) * (secX * rx + secY * ry + secZ * rz);
	GtoPx = rx * _cos + secX * d + (secY * rz - secZ * ry) * _sin;
	GtoPy = ry * _cos + secY * d + (secZ * rx - secX * rz) * _sin;
	GtoPz = rz * _cos + secZ * d + (secX * ry - secY * rx) * _sin;

	var rx = Pupx, ry = Pupy, rz = Pupz;
	var d = (1 - _cos) * (secX * rx + secY * ry + secZ * rz);
	Pupx = rx * _cos + secX * d + (secY * rz - secZ * ry) * _sin;
	Pupy = ry * _cos + secY * d + (secZ * rx - secX * rz) * _sin;
	Pupz = rz * _cos + secZ * d + (secX * ry - secY * rx) * _sin;

	/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		Orthogonalize the perpendicular parent vector to the vector pointing from the grandparent to the new position, and find the new parent position
	*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	var mx = Gx + GtoPx - middleX;
	var my = Gy + GtoPy - middleY;
	var mz = Gz + GtoPz - middleZ;
	var dp = mx * secX + my * secY + mz * secZ;
	mx -= secX * dp;
	my -= secY * dp;
	mz -= secZ * dp;
	var dp = (mx * GtoNx + my * GtoNy + mz * GtoNz) / g_nsqr;
	mx -= GtoNx * dp;
	my -= GtoNy * dp;
	mz -= GtoNz * dp;
	var m = mx * mx + my * my + mz * mz;
	if (m > 0)
	{
		m = intersectionRadius / sqrt(m);
	}
	Px = middleX + mx * m;
	Py = middleY + my * m;
	Pz = middleZ + mz * m;

	/*////////////////////////////////
		Construct parent matrix
	*/////////////////////////////////
	var M0 = (Px - Gx) / g_p;
	var M1 = (Py - Gy) / g_p;
	var M2 = (Pz - Gz) / g_p;
	var M4 = Pupy * M2 - Pupz * M1;
	var M5 = Pupz * M0 - Pupx * M2;
	var M6 = Pupx * M1 - Pupy * M0;
	m = M4 * M4 + M5 * M5 + M6 * M6;
	if (m == 0)
	{
		return false;
	}
	l = 1 / sqrt(m);
	M4 *= l;
	M5 *= l;
	M6 *= l;
	var M8  = M1 * M6 - M2 * M5;
	var M9  = M2 * M4 - M0 * M6;
	var M10 = M0 * M5 - M1 * M4;

	/*///////////////////////////////////////////////////////////
		Convert the parent's matrix into dual quaternion
	*////////////////////////////////////////////////////////////
	var T = 1. + M0 + M5 + M10;
	if (T > 0.)
	{
	    var S = sqrt(T) * 2.;
	    var Q0 = (M9 - M6) / S;
	    var Q1 = (M2 - M8) / S;
	    var Q2 = (M4 - M1) / S;
	    var Q3 = -.25 * S;  //I have modified this
	}
	else if (M0 > M5 && M0 > M10)
	{// Column 0: 
	    var S = sqrt(1. + M0 - M5 - M10) * 2.;
	    var Q0 = .25 * S;
	    var Q1 = (M4 + M1) / S;
	    var Q2 = (M2 + M8) / S;
	    var Q3 = (M9 - M6) / S;
	} 
	else if (M5 > M10)
	{// Column 1: 
	    var S = sqrt(1. + M5 - M0 - M10) * 2.;
	    var Q0 = (M4 + M1) / S;
	    var Q1 = .25 * S;
	    var Q2 = (M9 + M6) / S;
	    var Q3 = (M2 - M8) / S;
	} 
	else 
	{// Column 2:
	    var S  = sqrt(1. + M10 - M0 - M5) * 2.;
	    var Q0 = (M2 + M8) / S;
	    var Q1 = (M9 + M6) / S;
	    var Q2 = .25 * S;
	    var Q3 = (M4 - M1) / S;
	}
	if (Q0 * P0 + Q1 * P1 + Q2 * P2 + Q3 * P3 < 0.)
	{
		Q0 = -Q0;
		Q1 = -Q1;
		Q2 = -Q2;
		Q3 = -Q3;
	}
	var Q4 = .5 * (Px * Q3 + Py * Q2 - Pz * Q1);
	var Q5 = .5 * (Py * Q3 + Pz * Q0 - Px * Q2);
	var Q6 = .5 * (Pz * Q3 + Px * Q1 - Py * Q0);
	var Q7 =-.5 * (Px * Q0 + Py * Q1 + Pz * Q2);

	/*///////////////////////////////////////////////////////////
		Transform the sample dual quaternion of the parent
	*////////////////////////////////////////////////////////////
	var S = pNode[eAnimNode.WorldDQConjugate];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	sample[@ Pb]   = Q3 * s0 + Q0 * s3 + Q1 * s2 - Q2 * s1;
	sample[@ Pb+1] = Q3 * s1 + Q1 * s3 + Q2 * s0 - Q0 * s2;
	sample[@ Pb+2] = Q3 * s2 + Q2 * s3 + Q0 * s1 - Q1 * s0;
	sample[@ Pb+3] = Q3 * s3 - Q0 * s0 - Q1 * s1 - Q2 * s2;
	sample[@ Pb+4] = Q3 * s4 + Q0 * s7 + Q1 * s6 - Q2 * s5 + Q7 * s0 + Q4 * s3 + Q5 * s2 - Q6 * s1;
	sample[@ Pb+5] = Q3 * s5 + Q1 * s7 + Q2 * s4 - Q0 * s6 + Q7 * s1 + Q5 * s3 + Q6 * s0 - Q4 * s2;
	sample[@ Pb+6] = Q3 * s6 + Q2 * s7 + Q0 * s5 - Q1 * s4 + Q7 * s2 + Q6 * s3 + Q4 * s1 - Q5 * s0;
	sample[@ Pb+7] = Q3 * s7 - Q0 * s4 - Q1 * s5 - Q2 * s6 + Q7 * s3 - Q4 * s0 - Q5 * s1 - Q6 * s2;

	/*////////////////////////////
		Transform descendants
	*/////////////////////////////
	var children = pNode[eAnimNode.Children];
	var childNum = array_length(children);
	if (childNum > 0)
	{
		if (transformChildren)
		{
			var R = global.AnimTempQ1;
			R[@ 0] = -Q3 * P0 + Q0 * P3 - Q1 * P2 + Q2 * P1;
			R[@ 1] = -Q3 * P1 + Q1 * P3 - Q2 * P0 + Q0 * P2;
			R[@ 2] = -Q3 * P2 + Q2 * P3 - Q0 * P1 + Q1 * P0;
			R[@ 3] =  Q3 * P3 + Q0 * P0 + Q1 * P1 + Q2 * P2;
			R[@ 4] = -Q3 * P4 + Q0 * P7 - Q1 * P6 + Q2 * P5 - Q7 * P0 + Q4 * P3 - Q5 * P2 + Q6 * P1;
			R[@ 5] = -Q3 * P5 + Q1 * P7 - Q2 * P4 + Q0 * P6 - Q7 * P1 + Q5 * P3 - Q6 * P0 + Q4 * P2;
			R[@ 6] = -Q3 * P6 + Q2 * P7 - Q0 * P5 + Q1 * P4 - Q7 * P2 + Q6 * P3 - Q4 * P1 + Q5 * P0;
			R[@ 7] =  Q3 * P7 + Q0 * P4 + Q1 * P5 + Q2 * P6 + Q7 * P3 + Q4 * P0 + Q5 * P1 + Q6 * P2;
			for (var i = 0; i < childNum; i ++)
			{
				var child = children[i];
				if (child == nodeInd){continue;}
				//Transform node
				sample_node_transform(rig, child, sample, R, true);
			}
		}
		else
		{
			//Translate the node's children
			var dx = (newX - pOldX);
			var dy = (newY - pOldY);
			var dz = (newZ - pOldZ);
			for (var i = 0; i < childNum; i ++)
			{
				var child = children[i];
				if (child == nodeInd){continue;}
				sample_node_translate(rig, child, sample, dx, dy, dz, true);
			}
		}
	}

	/*////////////////////////////////
		Construct child matrix
	*/////////////////////////////////
	var M0 = (newX - Px) / p_c;
	var M1 = (newY - Py) / p_c;
	var M2 = (newZ - Pz) / p_c;
	var M4 = Cupy * M2 - Cupz * M1;
	var M5 = Cupz * M0 - Cupx * M2;
	var M6 = Cupx * M1 - Cupy * M0;
	m = M4 * M4 + M5 * M5 + M6 * M6;
	if (m == 0)
	{
		return false;
	}
	l = 1 / sqrt(m);
	M4 *= l;
	M5 *= l;
	M6 *= l;
	var M8  = M1 * M6 - M2 * M5;
	var M9  = M2 * M4 - M0 * M6;
	var M10 = M0 * M5 - M1 * M4;

	/*///////////////////////////////////////////////////////////
		Convert the child's matrix into dual quaternion
	*////////////////////////////////////////////////////////////
	var T = 1. + M0 + M5 + M10;
	if (T > 0.)
	{
	    var S = sqrt(T) * 2.;
	    Q0 = (M9 - M6) / S;
	    Q1 = (M2 - M8) / S;
	    Q2 = (M4 - M1) / S;
	    Q3 = -.25 * S;  //I have modified this
	}
	else if (M0 > M5 && M0 > M10)
	{// Column 0: 
	    var S = sqrt(1. + M0 - M5 - M10) * 2.;
	    Q0 = .25 * S;
	    Q1 = (M4 + M1) / S;
	    Q2 = (M2 + M8) / S;
	    Q3 = (M9 - M6) / S;
	} 
	else if (M5 > M10)
	{// Column 1: 
	    var S = sqrt(1. + M5 - M0 - M10) * 2.;
	    Q0 = (M4 + M1) / S;
	    Q1 = .25 * S;
	    Q2 = (M9 + M6) / S;
	    Q3 = (M2 - M8) / S;
	} 
	else 
	{// Column 2:
	    var S  = sqrt(1. + M10 - M0 - M5) * 2.;
	    Q0 = (M2 + M8) / S;
	    Q1 = (M9 + M6) / S;
	    Q2 = .25 * S;
	    Q3 = (M4 - M1) / S;
	}
	if (Q0 * C0 + Q1 * C1 + Q2 * C2 + Q3 * C3 < 0.)
	{
		Q0 = -Q0;
		Q1 = -Q1;
		Q2 = -Q2;
		Q3 = -Q3;
	}
	var Q4 = .5 * (newX * Q3 + newY * Q2 - newZ * Q1);
	var Q5 = .5 * (newY * Q3 + newZ * Q0 - newX * Q2);
	var Q6 = .5 * (newZ * Q3 + newX * Q1 - newY * Q0);
	var Q7 =-.5 * (newX * Q0 + newY * Q1 + newZ * Q2);

	/*///////////////////////////////////////////////////////////
		Transform the sample dual quaternion of the child
	*////////////////////////////////////////////////////////////
	var S = cNode[eAnimNode.WorldDQConjugate];
	var s0 = S[0], s1 = S[1], s2 = S[2], s3 = S[3], s4 = S[4], s5 = S[5], s6 = S[6], s7 = S[7];
	sample[@ Cb]   = Q3 * s0 + Q0 * s3 + Q1 * s2 - Q2 * s1;
	sample[@ Cb+1] = Q3 * s1 + Q1 * s3 + Q2 * s0 - Q0 * s2;
	sample[@ Cb+2] = Q3 * s2 + Q2 * s3 + Q0 * s1 - Q1 * s0;
	sample[@ Cb+3] = Q3 * s3 - Q0 * s0 - Q1 * s1 - Q2 * s2;
	sample[@ Cb+4] = Q3 * s4 + Q0 * s7 + Q1 * s6 - Q2 * s5 + Q7 * s0 + Q4 * s3 + Q5 * s2 - Q6 * s1;
	sample[@ Cb+5] = Q3 * s5 + Q1 * s7 + Q2 * s4 - Q0 * s6 + Q7 * s1 + Q5 * s3 + Q6 * s0 - Q4 * s2;
	sample[@ Cb+6] = Q3 * s6 + Q2 * s7 + Q0 * s5 - Q1 * s4 + Q7 * s2 + Q6 * s3 + Q4 * s1 - Q5 * s0;
	sample[@ Cb+7] = Q3 * s7 - Q0 * s4 - Q1 * s5 - Q2 * s6 + Q7 * s3 - Q4 * s0 - Q5 * s1 - Q6 * s2;

	/*////////////////////////////
		Transform descendants
	*/////////////////////////////
	var descendants = cNode[eAnimNode.Descendants];
	var descendantNum = array_length(descendants);
	if (descendantNum > 0)
	{
		if (transformChildren)
		{
			var R0 = -Q3 * C0 + Q0 * C3 - Q1 * C2 + Q2 * C1;
			var R1 = -Q3 * C1 + Q1 * C3 - Q2 * C0 + Q0 * C2;
			var R2 = -Q3 * C2 + Q2 * C3 - Q0 * C1 + Q1 * C0;
			var R3 =  Q3 * C3 + Q0 * C0 + Q1 * C1 + Q2 * C2;
			var R4 = -Q3 * C4 + Q0 * C7 - Q1 * C6 + Q2 * C5 - Q7 * C0 + Q4 * C3 - Q5 * C2 + Q6 * C1;
			var R5 = -Q3 * C5 + Q1 * C7 - Q2 * C4 + Q0 * C6 - Q7 * C1 + Q5 * C3 - Q6 * C0 + Q4 * C2;
			var R6 = -Q3 * C6 + Q2 * C7 - Q0 * C5 + Q1 * C4 - Q7 * C2 + Q6 * C3 - Q4 * C1 + Q5 * C0;
			var R7 =  Q3 * C7 + Q0 * C4 + Q1 * C5 + Q2 * C6 + Q7 * C3 + Q4 * C0 + Q5 * C1 + Q6 * C2;
			for (var i = 0; i < descendantNum; i ++)
			{
				//Transform node
				b = bindMap[| descendants[i]];
				if (b >= 0)
				{
					b *= 8;
					var s0 = sample[b];
					var s1 = sample[b+1];
					var s2 = sample[b+2];
					var s3 = sample[b+3];
					var s4 = sample[b+4];
					var s5 = sample[b+5];
					var s6 = sample[b+6];
					var s7 = sample[b+7];
					sample[@ b]	  = R3 * s0 + R0 * s3 + R1 * s2 - R2 * s1;
					sample[@ b+1] = R3 * s1 - R0 * s2 + R1 * s3 + R2 * s0;
					sample[@ b+2] = R3 * s2 + R0 * s1 - R1 * s0 + R2 * s3;
					sample[@ b+3] = R3 * s3 - R0 * s0 - R1 * s1 - R2 * s2;
					sample[@ b+4] = R3 * s4 + R0 * s7 + R1 * s6 - R2 * s5 + R4 * s3 + R5 * s2 - R6 * s1 + R7 * s0;
					sample[@ b+5] = R3 * s5 - R0 * s6 + R1 * s7 + R2 * s4 - R4 * s2 + R5 * s3 + R6 * s0 + R7 * s1;
					sample[@ b+6] = R3 * s6 + R0 * s5 - R1 * s4 + R2 * s7 + R4 * s1 - R5 * s0 + R6 * s3 + R7 * s2;
					sample[@ b+7] = R3 * s7 - R0 * s4 - R1 * s5 - R2 * s6 - R4 * s0 - R5 * s1 - R6 * s2 + R7 * s3;
				}
			}
		}
		else
		{
			//Translate the node's children
			var dx = (newX - oldX) * .5;
			var dy = (newY - oldY) * .5;
			var dz = (newZ - oldZ) * .5;
			for (var i = 0; i < descendantNum; i ++)
			{
				var b = bindMap[| descendants[i]];
				if (b < 0){continue;}
				b *= 8;
				var s0 = sample[b];
				var s1 = sample[b+1];
				var s2 = sample[b+2];
				var s3 = sample[b+3];
				sample[@ b+4] += + dx * s3 + dy * s2 - dz * s1;
				sample[@ b+5] += - dx * s2 + dy * s3 + dz * s0;
				sample[@ b+6] += + dx * s1 - dy * s0 + dz * s3;
				sample[@ b+7] += - dx * s0 - dy * s1 - dz * s2;
			}
		}
	}
	return true;
}
function sample_node_ik_fast(rig, nodeInd, sample, newX, newY, newZ, moveFromCurrent, transformChildren) 
{	/*	Snidr's Two-joint Inverse Kinematics Algorithm
		This is a two-joint IK algorithm I've invented myself. It is a very crude way of doing inverse kinematics, but it works well for small adjustments of foot position and the like.

		The algorithm will move the given node and its parent.
		If transformChildren is set to true, it will also rotate the children of the given node. If it's false, it will only translate them so that they don't get detached.
	
		This version of the script is useful for smaller adjustments. Large changes may result in bones getting twisted in unnatural angles.
	
		Set moveFromCurrent to true if you'd like the primary axis to rotate according to the current orientation of the parent bone.
		For most cases, this option can be set to false.*/

	/*//////////////////////////////////////////////////////////////
			Find child, parent, and grandparent nodes
	*///////////////////////////////////////////////////////////////
	var bindMap = rig.bindMap;
	var nodeList = rig.nodeList;
	var cNode = nodeList[| nodeInd];
	var pNode = nodeList[| cNode[eAnimNode.Parent]];
	var gNode = nodeList[| pNode[eAnimNode.Parent]];
	if (!cNode[eAnimNode.IsBone] || !pNode[eAnimNode.IsBone])
	{
		show_debug_message("Error in script sample_node_ik_fast: Cannot perform inverse kinematics on nodes that aren't bones"); 
		exit;
	}

	/*///////////////////////////////////////////////////////////////
			Find child node dual quat, position and up-vector
	*////////////////////////////////////////////////////////////////
	var Cb = 8 * bindMap[| nodeInd];
	var c0 = sample[Cb];
	var c1 = sample[Cb+1];
	var c2 = sample[Cb+2];
	var c3 = sample[Cb+3];
	var c4 = sample[Cb+4];
	var c5 = sample[Cb+5];
	var c6 = sample[Cb+6];
	var c7 = sample[Cb+7];
	var C = cNode[eAnimNode.WorldDQ];
	var s0 = C[0], s1 = C[1], s2 = C[2], s3 = C[3], s4 = C[4], s5 = C[5], s6 = C[6], s7 = C[7];
	var C0 = c3 * s0 + c0 * s3 + c1 * s2 - c2 * s1;
	var C1 = c3 * s1 + c1 * s3 + c2 * s0 - c0 * s2;
	var C2 = c3 * s2 + c2 * s3 + c0 * s1 - c1 * s0;
	var C3 = c3 * s3 - c0 * s0 - c1 * s1 - c2 * s2;
	var C4 = c3 * s4 + c0 * s7 + c1 * s6 - c2 * s5 + c7 * s0 + c4 * s3 + c5 * s2 - c6 * s1;
	var C5 = c3 * s5 + c1 * s7 + c2 * s4 - c0 * s6 + c7 * s1 + c5 * s3 + c6 * s0 - c4 * s2;
	var C6 = c3 * s6 + c2 * s7 + c0 * s5 - c1 * s4 + c7 * s2 + c6 * s3 + c4 * s1 - c5 * s0;
	var C7 = c3 * s7 - c0 * s4 - c1 * s5 - c2 * s6 + c7 * s3 - c4 * s0 - c5 * s1 - c6 * s2;
	var Cx = 2 * (-C7 * C0 + C4 * C3 + C6 * C1 - C5 * C2);
	var Cy = 2 * (-C7 * C1 + C5 * C3 + C4 * C2 - C6 * C0);
	var Cz = 2 * (-C7 * C2 + C6 * C3 + C5 * C0 - C4 * C1);
	var Cupx = 2 * (C0 * C2 + C1 * C3);
	var Cupy = 2 * (C1 * C2 - C0 * C3);
	var Cupz = C3 * C3 - C0 * C0 - C1 * C1 + C2 * C2;

	/*/////////////////////////////////////////////////////////////////////
			Find grandparent node dual quat, position and up-vector
	*//////////////////////////////////////////////////////////////////////
	var Pb = 8 * bindMap[| cNode[eAnimNode.Parent]];
	var p0 = sample[Pb];
	var p1 = sample[Pb+1];
	var p2 = sample[Pb+2];
	var p3 = sample[Pb+3];
	var p4 = sample[Pb+4];
	var p5 = sample[Pb+5];
	var p6 = sample[Pb+6];
	var p7 = sample[Pb+7];
	var G = gNode[eAnimNode.WorldDQ];
	var s0 = G[0], s1 = G[1], s2 = G[2], s3 = G[3], s4 = G[4], s5 = G[5], s6 = G[6], s7 = G[7];
	var G0 = p3 * s0 + p0 * s3 + p1 * s2 - p2 * s1;
	var G1 = p3 * s1 + p1 * s3 + p2 * s0 - p0 * s2;
	var G2 = p3 * s2 + p2 * s3 + p0 * s1 - p1 * s0;
	var G3 = p3 * s3 - p0 * s0 - p1 * s1 - p2 * s2;
	var G4 = p3 * s4 + p0 * s7 + p1 * s6 - p2 * s5 + p7 * s0 + p4 * s3 + p5 * s2 - p6 * s1;
	var G5 = p3 * s5 + p1 * s7 + p2 * s4 - p0 * s6 + p7 * s1 + p5 * s3 + p6 * s0 - p4 * s2;
	var G6 = p3 * s6 + p2 * s7 + p0 * s5 - p1 * s4 + p7 * s2 + p6 * s3 + p4 * s1 - p5 * s0;
	var G7 = p3 * s7 - p0 * s4 - p1 * s5 - p2 * s6 + p7 * s3 - p4 * s0 - p5 * s1 - p6 * s2;
	var Gx = 2 * (-G7 * G0 + G4 * G3 + G6 * G1 - G5 * G2);
	var Gy = 2 * (-G7 * G1 + G5 * G3 + G4 * G2 - G6 * G0);
	var Gz = 2 * (-G7 * G2 + G6 * G3 + G5 * G0 - G4 * G1);

	/*/////////////////////////////////////////////////////////////////
			Find parent node dual quat, position and up-vector
	*//////////////////////////////////////////////////////////////////
	var P = pNode[eAnimNode.WorldDQ];
	var s0 = P[0], s1 = P[1], s2 = P[2], s3 = P[3];
	var P0 = p3 * s0 + p0 * s3 + p1 * s2 - p2 * s1;
	var P1 = p3 * s1 + p1 * s3 + p2 * s0 - p0 * s2;
	var P2 = p3 * s2 + p2 * s3 + p0 * s1 - p1 * s0;
	var P3 = p3 * s3 - p0 * s0 - p1 * s1 - p2 * s2;
	var P4 = p3 * s4 + p0 * s7 + p1 * s6 - p2 * s5 + p7 * s0 + p4 * s3 + p5 * s2 - p6 * s1;
	var P5 = p3 * s5 + p1 * s7 + p2 * s4 - p0 * s6 + p7 * s1 + p5 * s3 + p6 * s0 - p4 * s2;
	var P6 = p3 * s6 + p2 * s7 + p0 * s5 - p1 * s4 + p7 * s2 + p6 * s3 + p4 * s1 - p5 * s0;
	var P7 = p3 * s7 - p0 * s4 - p1 * s5 - p2 * s6 + p7 * s3 - p4 * s0 - p5 * s1 - p6 * s2;
	var Px = 2 * (-P7 * P0 + P4 * P3 + P6 * P1 - P5 * P2);
	var Py = 2 * (-P7 * P1 + P5 * P3 + P4 * P2 - P6 * P0);
	var Pz = 2 * (-P7 * P2 + P6 * P3 + P5 * P0 - P4 * P1);
	var Pupx = 2 * (P0 * P2 + P1 * P3);
	var Pupy = 2 * (P1 * P2 - P0 * P3);
	var Pupz = P3 * P3 - P0 * P0 - P1 * P1 + P2 * P2;

	/*////////////////////////////////////////////////////////
			Find start position and bone vectors
	*/////////////////////////////////////////////////////////
	var oldX = Cx;
	var oldY = Cy;
	var oldZ = Cz;
	var pOldX = Px;
	var pOldY = Py;
	var pOldZ = Pz;
	var GtoNx = newX - Gx;
	var GtoNy = newY - Gy;
	var GtoNz = newZ - Gz;

	/*////////////////////////////////////////////////////
			Find distance between the bones
	*/////////////////////////////////////////////////////
	var p_c = cNode[eAnimNode.Length]; //Parent to Child
	var g_p = pNode[eAnimNode.Length]; //Grandparent to Parent
	var g_n = sqrt(GtoNx * GtoNx + GtoNy * GtoNy + GtoNz * GtoNz); //Grandparent to new position

	/*////////////////////////////////////////////////////
			Limit the distance from G to new pos
	*/////////////////////////////////////////////////////
	var a = clamp(g_n, abs(g_p - p_c) + g_p * .001, (g_p + p_c) * .999);
	if (a != g_n)
	{
		var d = a / g_n;
		GtoNx *= d;
		GtoNy *= d;
		GtoNz *= d;
		newX = Gx + GtoNx;
		newY = Gy + GtoNy;
		newZ = Gz + GtoNz;
		g_n = a;
	}

	/*////////////////////////////////////////////////////////////////////////////////////////////////////////
		Find the middle point within the intersection between two spheres, one placed at the grandparent
		and one placed at the new position, with radii the length of the parent bone and the length of
		the child bone respectively.
		Also find the distance from this middle point to the parent (named here as "intersectionRadius")
	*/////////////////////////////////////////////////////////////////////////////////////////////////////////
	var g_nsqr = g_n * g_n;
	var p_csqr = p_c * p_c;
	var g_psqr = g_p * g_p;
	var intersectionRadius = sqrt(max(p_csqr - sqr(g_psqr - p_csqr - g_nsqr) / (4 * g_nsqr), 0));
	var l = sqrt(max(g_psqr - intersectionRadius * intersectionRadius, 0.)) / g_n;
	if (g_nsqr < p_csqr - g_psqr){l = -l;} //If the child is too close to the grandparent, the "middle" point is on the other side of the grandparent, and l must be negative
	var middleX = Gx + GtoNx * l;
	var middleY = Gy + GtoNy * l;
	var middleZ = Gz + GtoNz * l;

	/*/////////////////////////////////////////////////////////////////////////////////////////////////////////
		The next step is to rotate around the primary axis (which has either been defined in the model 
		tool, or will be created using info already available)
	*//////////////////////////////////////////////////////////////////////////////////////////////////////////
	var primaryAxis = cNode[eAnimNode.PrimaryAxis];
	if (!moveFromCurrent && is_array(primaryAxis))
	{
		var primX = primaryAxis[0];
		var primY = primaryAxis[1];
		var primZ = primaryAxis[2];
	}
	else
	{
		var primX = Cx - Px;
		var primY = Cy - Py;
		var primZ = Cz - Pz;
		var axisX = Px + Cx - 2 * Gx;
		var axisY = Py + Cy - 2 * Gz;
		var axisZ = Pz + Cz - 2 * Gz;
		var dp = (primX * axisX + primY * axisY + primZ * axisZ) / (axisX * axisX + axisY * axisY + axisZ * axisZ);
		primX -= axisX * dp;
		primY -= axisY * dp;
		primZ -= axisZ * dp;
		var l = primX * primX + primY * primY + primZ * primZ;
		if (l == 0)
		{
			return false;
		}
		l = 1 / sqrt(l);
		primX *= l;
		primY *= l;
		primZ *= l;
		if !moveFromCurrent
		{
			cNode[@ eAnimNode.PrimaryAxis] = [primX, primY, primZ];
		}
	}

	if (moveFromCurrent)
	{
		//Rotate the primary vector by the transformation of the parent bone
		var crossX = p1 * primZ - p2 * primY + p3 * primX;
		var crossY = p2 * primX - p0 * primZ + p3 * primY;
		var crossZ = p0 * primY - p1 * primX + p3 * primZ;
		primX += 2 * (p1 * crossZ - p2 * crossY);
		primY += 2 * (p2 * crossX - p0 * crossZ);
		primZ += 2 * (p0 * crossY - p1 * crossX);
	}

	/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		Orthogonalize this vector to the vector pointing from the grandparent to the new position and displace the parent
	*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	var dp = (primX * GtoNx + primY * GtoNy + primZ * GtoNz) / g_nsqr;
	var mx = primX - GtoNx * dp;
	var my = primY - GtoNy * dp;
	var mz = primZ - GtoNz * dp;
	var m = mx * mx + my * my + mz * mz;
	if (m > 0)
	{
		m = intersectionRadius / sqrt(m);
	}
	Px = middleX + mx * m;
	Py = middleY + my * m;
	Pz = middleZ + mz * m;

	/*////////////////////////////////
		Construct parent matrix
	*/////////////////////////////////
	var M0 = (Px - Gx) / g_p;
	var M1 = (Py - Gy) / g_p;
	var M2 = (Pz - Gz) / g_p;
	var M4 = Pupy * M2 - Pupz * M1;
	var M5 = Pupz * M0 - Pupx * M2;
	var M6 = Pupx * M1 - Pupy * M0;
	m = M4 * M4 + M5 * M5 + M6 * M6;
	if (m == 0)
	{
		return false;
	}
	l = 1 / sqrt(m);
	M4 *= l;
	M5 *= l;
	M6 *= l;
	var M8  = M1 * M6 - M2 * M5;
	var M9  = M2 * M4 - M0 * M6;
	var M10 = M0 * M5 - M1 * M4;

	/*///////////////////////////////////////////////////////////
		Convert the parent's matrix into dual quaternion
	*////////////////////////////////////////////////////////////
	var T = 1 + M0 + M5 + M10;
	if (T > 0.)
	{
	    var S = sqrt(T) * 2;
	    var Q0 = (M9 - M6) / S;
	    var Q1 = (M2 - M8) / S;
	    var Q2 = (M4 - M1) / S;
	    var Q3 = -0.25 * S;  //I have modified this
	}
	else if (M0 > M5 && M0 > M10)
	{// Column 0: 
	    var S = sqrt(1.0 + M0 - M5 - M10) * 2;
	    var Q0 = 0.25 * S;
	    var Q1 = (M4 + M1) / S;
	    var Q2 = (M2 + M8) / S;
	    var Q3 = (M9 - M6) / S;
	} 
	else if (M5 > M10)
	{// Column 1: 
	    var S = sqrt(1.0 + M5 - M0 - M10) * 2;
	    var Q0 = (M4 + M1) / S;
	    var Q1 = 0.25 * S;
	    var Q2 = (M9 + M6) / S;
	    var Q3 = (M2 - M8) / S;
	} 
	else 
	{// Column 2:
	    var S  = sqrt(1.0 + M10 - M0 - M5) * 2;
	    var Q0 = (M2 + M8) / S;
	    var Q1 = (M9 + M6) / S;
	    var Q2 = 0.25 * S;
	    var Q3 = (M4 - M1) / S;
	}

	//Make sure the new world-space DQ is in the same half of the hypersphere as the previous
	if (Q0 * P0 + Q1 * P1 + Q2 * P2 + Q3 * P3 < 0)
	{
		Q0 = -Q0;
		Q1 = -Q1;
		Q2 = -Q2;
		Q3 = -Q3;
	}
	var Q4 = .5 * (Px * Q3 + Py * Q2 - Pz * Q1);
	var Q5 = .5 * (Py * Q3 + Pz * Q0 - Px * Q2);
	var Q6 = .5 * (Pz * Q3 + Px * Q1 - Py * Q0);
	var Q7 =-.5 * (Px * Q0 + Py * Q1 + Pz * Q2);

	/*////////////////////////////////////////////////
		Transform the sample of the parent
	*/////////////////////////////////////////////////
	//Get the conjugate of the parent's bindpose world matrix
	var s0 = - P[0], s1 = - P[1], s2 = - P[2], s3 = P[3], s4 = - P[4], s5 = - P[5], s6 = - P[6], s7 = P[7];
	sample[@ Pb]   = Q3 * s0 + Q0 * s3 + Q1 * s2 - Q2 * s1;
	sample[@ Pb+1] = Q3 * s1 + Q1 * s3 + Q2 * s0 - Q0 * s2;
	sample[@ Pb+2] = Q3 * s2 + Q2 * s3 + Q0 * s1 - Q1 * s0;
	sample[@ Pb+3] = Q3 * s3 - Q0 * s0 - Q1 * s1 - Q2 * s2;
	sample[@ Pb+4] = Q3 * s4 + Q0 * s7 + Q1 * s6 - Q2 * s5 + Q7 * s0 + Q4 * s3 + Q5 * s2 - Q6 * s1;
	sample[@ Pb+5] = Q3 * s5 + Q1 * s7 + Q2 * s4 - Q0 * s6 + Q7 * s1 + Q5 * s3 + Q6 * s0 - Q4 * s2;
	sample[@ Pb+6] = Q3 * s6 + Q2 * s7 + Q0 * s5 - Q1 * s4 + Q7 * s2 + Q6 * s3 + Q4 * s1 - Q5 * s0;
	sample[@ Pb+7] = Q3 * s7 - Q0 * s4 - Q1 * s5 - Q2 * s6 + Q7 * s3 - Q4 * s0 - Q5 * s1 - Q6 * s2;

	/*////////////////////////////
		Transform descendants
	*/////////////////////////////
	var children = pNode[eAnimNode.Children];
	var childNum = array_length(children);
	if (childNum > 0)
	{
		if (transformChildren)
		{
			var R = global.AnimTempQ1;
			R[@ 0] = -Q3 * P0 + Q0 * P3 - Q1 * P2 + Q2 * P1;
			R[@ 1] = -Q3 * P1 + Q1 * P3 - Q2 * P0 + Q0 * P2;
			R[@ 2] = -Q3 * P2 + Q2 * P3 - Q0 * P1 + Q1 * P0;
			R[@ 3] =  Q3 * P3 + Q0 * P0 + Q1 * P1 + Q2 * P2;
			R[@ 4] = -Q3 * P4 + Q0 * P7 - Q1 * P6 + Q2 * P5 - Q7 * P0 + Q4 * P3 - Q5 * P2 + Q6 * P1;
			R[@ 5] = -Q3 * P5 + Q1 * P7 - Q2 * P4 + Q0 * P6 - Q7 * P1 + Q5 * P3 - Q6 * P0 + Q4 * P2;
			R[@ 6] = -Q3 * P6 + Q2 * P7 - Q0 * P5 + Q1 * P4 - Q7 * P2 + Q6 * P3 - Q4 * P1 + Q5 * P0;
			R[@ 7] =  Q3 * P7 + Q0 * P4 + Q1 * P5 + Q2 * P6 + Q7 * P3 + Q4 * P0 + Q5 * P1 + Q6 * P2;
			for (var i = 0; i < childNum; i ++)
			{
				var child = children[i];
				if (child == nodeInd){continue;}
				//Transform node
				sample_node_transform(rig, child, sample, R, true);
			}
		}
		else
		{
			//Translate the node's children
			var dx = (newX - pOldX);
			var dy = (newY - pOldY);
			var dz = (newZ - pOldZ);
			for (var i = 0; i < childNum; i ++)
			{
				var child = children[i];
				if (child == nodeInd){continue;}
				sample_node_translate(rig, child, sample, dx, dy, dz, true);
			}
		}
	}
	
	/*////////////////////////////
		Transform descendants
	*/////////////////////////////
	var children = pNode[eAnimNode.Children];
	var childNum = array_length(children);
	if (childNum > 0)
	{
		if (transformChildren)
		{
			var R = global.AnimTempQ1;
			R[@ 0] = -Q3 * P0 + Q0 * P3 - Q1 * P2 + Q2 * P1;
			R[@ 1] = -Q3 * P1 + Q1 * P3 - Q2 * P0 + Q0 * P2;
			R[@ 2] = -Q3 * P2 + Q2 * P3 - Q0 * P1 + Q1 * P0;
			R[@ 3] =  Q3 * P3 + Q0 * P0 + Q1 * P1 + Q2 * P2;
			R[@ 4] = -Q3 * P4 + Q0 * P7 - Q1 * P6 + Q2 * P5 - Q7 * P0 + Q4 * P3 - Q5 * P2 + Q6 * P1;
			R[@ 5] = -Q3 * P5 + Q1 * P7 - Q2 * P4 + Q0 * P6 - Q7 * P1 + Q5 * P3 - Q6 * P0 + Q4 * P2;
			R[@ 6] = -Q3 * P6 + Q2 * P7 - Q0 * P5 + Q1 * P4 - Q7 * P2 + Q6 * P3 - Q4 * P1 + Q5 * P0;
			R[@ 7] =  Q3 * P7 + Q0 * P4 + Q1 * P5 + Q2 * P6 + Q7 * P3 + Q4 * P0 + Q5 * P1 + Q6 * P2;
			for (var i = 0; i < childNum; i ++)
			{
				var child = children[i];
				if (child == nodeInd){continue;}
				//Transform node
				sample_node_transform(rig, child, sample, R, true);
			}
		}
		else
		{
			//Translate the node's children
			var dx = (newX - oldX);
			var dy = (newY - oldY);
			var dz = (newZ - oldZ);
			for (var i = 0; i < childNum; i ++)
			{
				var child = children[i];
				if (child == nodeInd){continue;}
				sample_node_translate(rig, child, sample, dx, dy, dz, true);
			}
		}
	}

	/*////////////////////////////////
		Construct child matrix
	*/////////////////////////////////
	var M0 = (newX - Px) / p_c;
	var M1 = (newY - Py) / p_c;
	var M2 = (newZ - Pz) / p_c;
	var M4 = Cupy * M2 - Cupz * M1;
	var M5 = Cupz * M0 - Cupx * M2;
	var M6 = Cupx * M1 - Cupy * M0;
	m = M4 * M4 + M5 * M5 + M6 * M6;
	if (m == 0)
	{
		return false;
	}
	l = 1 / sqrt(m);
	M4 *= l;
	M5 *= l;
	M6 *= l;
	var M8  = M1 * M6 - M2 * M5;
	var M9  = M2 * M4 - M0 * M6;
	var M10 = M0 * M5 - M1 * M4;

	/*///////////////////////////////////////////////////////////
		Convert the child's matrix into dual quaternion
	*////////////////////////////////////////////////////////////
	var T = 1 + M0 + M5 + M10;
	if (T > 0.)
	{
	    var S = sqrt(T) * 2;
	    Q0 = (M9 - M6) / S;
	    Q1 = (M2 - M8) / S;
	    Q2 = (M4 - M1) / S;
	    Q3 = -0.25 * S;  //I have modified this
	}
	else if (M0 > M5 && M0 > M10)
	{// Column 0: 
	    var S = sqrt(1.0 + M0 - M5 - M10) * 2;
	    Q0 = 0.25 * S;
	    Q1 = (M4 + M1) / S;
	    Q2 = (M2 + M8) / S;
	    Q3 = (M9 - M6) / S;
	} 
	else if (M5 > M10)
	{// Column 1: 
	    var S = sqrt(1.0 + M5 - M0 - M10) * 2;
	    Q0 = (M4 + M1) / S;
	    Q1 = 0.25 * S;
	    Q2 = (M9 + M6) / S;
	    Q3 = (M2 - M8) / S;
	} 
	else 
	{// Column 2:
	    var S  = sqrt(1.0 + M10 - M0 - M5) * 2;
	    Q0 = (M2 + M8) / S;
	    Q1 = (M9 + M6) / S;
	    Q2 = 0.25 * S;
	    Q3 = (M4 - M1) / S;
	}

	//Make sure the new world-space DQ is in the same half of the hypersphere as the previous
	if (Q0 * C0 + Q1 * C1 + Q2 * C2 + Q3 * C3 < 0)
	{
		Q0 = -Q0;
		Q1 = -Q1;
		Q2 = -Q2;
		Q3 = -Q3;
	}
	var Q4 = .5 * (newX * Q3 + newY * Q2 - newZ * Q1);
	var Q5 = .5 * (newY * Q3 + newZ * Q0 - newX * Q2);
	var Q6 = .5 * (newZ * Q3 + newX * Q1 - newY * Q0);
	var Q7 =-.5 * (newX * Q0 + newY * Q1 + newZ * Q2);

	/*///////////////////////////////////////////
		Transform the sample of the child
	*////////////////////////////////////////////
	//Get the conjugate of the child's bindpose world matrix
	var s0 = - C[0], s1 = - C[1], s2 = - C[2], s3 = C[3], s4 = - C[4], s5 = - C[5], s6 = - C[6], s7 = C[7];
	sample[@ Cb]   = Q3 * s0 + Q0 * s3 + Q1 * s2 - Q2 * s1;
	sample[@ Cb+1] = Q3 * s1 + Q1 * s3 + Q2 * s0 - Q0 * s2;
	sample[@ Cb+2] = Q3 * s2 + Q2 * s3 + Q0 * s1 - Q1 * s0;
	sample[@ Cb+3] = Q3 * s3 - Q0 * s0 - Q1 * s1 - Q2 * s2;
	sample[@ Cb+4] = Q3 * s4 + Q0 * s7 + Q1 * s6 - Q2 * s5 + Q7 * s0 + Q4 * s3 + Q5 * s2 - Q6 * s1;
	sample[@ Cb+5] = Q3 * s5 + Q1 * s7 + Q2 * s4 - Q0 * s6 + Q7 * s1 + Q5 * s3 + Q6 * s0 - Q4 * s2;
	sample[@ Cb+6] = Q3 * s6 + Q2 * s7 + Q0 * s5 - Q1 * s4 + Q7 * s2 + Q6 * s3 + Q4 * s1 - Q5 * s0;
	sample[@ Cb+7] = Q3 * s7 - Q0 * s4 - Q1 * s5 - Q2 * s6 + Q7 * s3 - Q4 * s0 - Q5 * s1 - Q6 * s2;
	
	/*////////////////////////////
		Transform descendants
	*/////////////////////////////
	var descendants = cNode[eAnimNode.Descendants];
	var descendantNum = array_length(descendants);
	if (descendantNum > 0)
	{
		if (transformChildren)
		{
			var R0 = -Q3 * C0 + Q0 * C3 - Q1 * C2 + Q2 * C1;
			var R1 = -Q3 * C1 + Q1 * C3 - Q2 * C0 + Q0 * C2;
			var R2 = -Q3 * C2 + Q2 * C3 - Q0 * C1 + Q1 * C0;
			var R3 =  Q3 * C3 + Q0 * C0 + Q1 * C1 + Q2 * C2;
			var R4 = -Q3 * C4 + Q0 * C7 - Q1 * C6 + Q2 * C5 - Q7 * C0 + Q4 * C3 - Q5 * C2 + Q6 * C1;
			var R5 = -Q3 * C5 + Q1 * C7 - Q2 * C4 + Q0 * C6 - Q7 * C1 + Q5 * C3 - Q6 * C0 + Q4 * C2;
			var R6 = -Q3 * C6 + Q2 * C7 - Q0 * C5 + Q1 * C4 - Q7 * C2 + Q6 * C3 - Q4 * C1 + Q5 * C0;
			var R7 =  Q3 * C7 + Q0 * C4 + Q1 * C5 + Q2 * C6 + Q7 * C3 + Q4 * C0 + Q5 * C1 + Q6 * C2;
			for (var i = 0; i < descendantNum; i ++)
			{
				//Transform node
				b = bindMap[| descendants[i]];
				if (b >= 0)
				{
					b *= 8;
					var s0 = sample[b];
					var s1 = sample[b+1];
					var s2 = sample[b+2];
					var s3 = sample[b+3];
					var s4 = sample[b+4];
					var s5 = sample[b+5];
					var s6 = sample[b+6];
					var s7 = sample[b+7];
					sample[@ b]	  = R3 * s0 + R0 * s3 + R1 * s2 - R2 * s1;
					sample[@ b+1] = R3 * s1 - R0 * s2 + R1 * s3 + R2 * s0;
					sample[@ b+2] = R3 * s2 + R0 * s1 - R1 * s0 + R2 * s3;
					sample[@ b+3] = R3 * s3 - R0 * s0 - R1 * s1 - R2 * s2;
					sample[@ b+4] = R3 * s4 + R0 * s7 + R1 * s6 - R2 * s5 + R4 * s3 + R5 * s2 - R6 * s1 + R7 * s0;
					sample[@ b+5] = R3 * s5 - R0 * s6 + R1 * s7 + R2 * s4 - R4 * s2 + R5 * s3 + R6 * s0 + R7 * s1;
					sample[@ b+6] = R3 * s6 + R0 * s5 - R1 * s4 + R2 * s7 + R4 * s1 - R5 * s0 + R6 * s3 + R7 * s2;
					sample[@ b+7] = R3 * s7 - R0 * s4 - R1 * s5 - R2 * s6 - R4 * s0 - R5 * s1 - R6 * s2 + R7 * s3;
				}
			}
		}
		else
		{
			//Translate the node's children
			var dx = newX * .5 - (-C7 * C0 + C4 * C3 + C6 * C1 - C5 * C2);
			var dy = newY * .5 - (-C7 * C1 + C5 * C3 + C4 * C2 - C6 * C0);
			var dz = newZ * .5 - (-C7 * C2 + C6 * C3 + C5 * C0 - C4 * C1);
			for (var i = 0; i < descendantNum; i ++)
			{
				var b = bindMap[| descendants[i]];
				if (b < 0){continue;}
				b *= 8;
				var s0 = sample[b];
				var s1 = sample[b+1];
				var s2 = sample[b+2];
				var s3 = sample[b+3];
				sample[@ b+4] +=   dx * s3 + dy * s2 - dz * s1;
				sample[@ b+5] += - dx * s2 + dy * s3 + dz * s0;
				sample[@ b+6] +=   dx * s1 - dy * s0 + dz * s3;
				sample[@ b+7] += - dx * s0 - dy * s1 - dz * s2;
			}
		}
	}

	return true;
}

function sample_node_set_dq(rig, nodeInd, sample, DQ, moveFromCurrent, transformChildren) 
{	/*	This script lets you modify a sample.
		The end-point of the node will move to the given position, and the parent and grandparent will attempt to follow using inverse kinematics. 
		Any descendants of the node will also move.*/
	var node = rig.nodeList[| nodeInd];
	var px = smf_dq_get_x(DQ);
	var py = smf_dq_get_y(DQ);
	var pz = smf_dq_get_z(DQ);
	var to = smf_quat_get_to(DQ);

	//If this node is not a bone, just move it
	if (!node[eAnimNode.IsBone])
	{
		sample_node_move(rig, nodeInd, sample, px, py, pz, moveFromCurrent, true);
		exit;
	}

	//Transform this node and its descendants
	var b = rig.bindMap[| nodeInd];
	if (b > 0)
	{
		var SQ = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ4);
		var deltaDQ = smf_dq_multiply(DQ, smf_dq_get_conjugate(SQ, SQ), global.AnimTempQ4);
		sample_node_transform(rig, nodeInd, sample, deltaDQ, transformChildren);
	}

	//Transform the parent
	px -= to[0] * node[eAnimNode.Length];
	py -= to[1] * node[eAnimNode.Length];
	pz -= to[2] * node[eAnimNode.Length];
	sample_node_move(rig, node[eAnimNode.Parent], sample, px, py, pz, moveFromCurrent, false);
}

function sample_node_set_matrix(rig, nodeInd, sample, M, moveFromCurrent, transformChildren)  
{	/*	This script lets you modify a sample.
		The end-point of the node will move to the given position, and the parent and grandparent will attempt to follow using inverse kinematics. 
		Any descendants of the node will also move.*/
	var node = rig.nodeList[| nodeInd];

	//If this node is not a bone, just move it
	if (!node[eAnimNode.IsBone])
	{
		sample_node_move(rig, nodeInd, sample, M[12], M[13], M[14], moveFromCurrent, true);
		exit;
	}

	//Transform this node and its descendants
	var b = rig.bindMap[| nodeInd];
	if (b > 0)
	{
		var DQ = smf_dq_create_from_matrix(M, global.AnimTempQ2);
		var SQ = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
		var deltaDQ = smf_dq_multiply(DQ, smf_dq_get_conjugate(SQ, SQ), DQ);
		sample_node_transform(rig, nodeInd, sample, deltaDQ, transformChildren);
	}
	//Transform the parent
	var px = M[12] - M[0] * node[eAnimNode.Length];
	var py = M[13] - M[1] * node[eAnimNode.Length];
	var pz = M[14] - M[2] * node[eAnimNode.Length];
	sample_node_move(rig, node[eAnimNode.Parent], sample, px, py, pz, moveFromCurrent, false);
}

function sample_node_transform(rig, nodeInd, sample, DQ, transformChildren)
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.

		Note, this script in particular can mess up your rig structure. Unless you know what you're doing, 
		you may be better off using the other real-time sample editing scripts!*/
	var b = rig.bindMap[| nodeInd];
	var node = rig.nodeList[| nodeInd];
	var children = node[eAnimNode.Children];
	var num = array_length(children);
	var r0 = DQ[0], r1 = DQ[1], r2 = DQ[2], r3 = DQ[3], r4 = DQ[4], r5 = DQ[5], r6 = DQ[6], r7 = DQ[7];

	//Transform node
	if (b >= 0)
	{
		if (!transformChildren)
		{
			var PQ = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ1);
		}
		b *= 8;
		var s0 = sample[b];
		var s1 = sample[b+1];
		var s2 = sample[b+2];
		var s3 = sample[b+3];
		var s4 = sample[b+4];
		var s5 = sample[b+5];
		var s6 = sample[b+6];
		var s7 = sample[b+7];
		sample[@ b]	  = r3 * s0 + r0 * s3 + r1 * s2 - r2 * s1;
		sample[@ b+1] = r3 * s1 - r0 * s2 + r1 * s3 + r2 * s0;
		sample[@ b+2] = r3 * s2 + r0 * s1 - r1 * s0 + r2 * s3;
		sample[@ b+3] = r3 * s3 - r0 * s0 - r1 * s1 - r2 * s2;
		sample[@ b+4] = r3 * s4 + r0 * s7 + r1 * s6 - r2 * s5 + r4 * s3 + r5 * s2 - r6 * s1 + r7 * s0;
		sample[@ b+5] = r3 * s5 - r0 * s6 + r1 * s7 + r2 * s4 - r4 * s2 + r5 * s3 + r6 * s0 + r7 * s1;
		sample[@ b+6] = r3 * s6 + r0 * s5 - r1 * s4 + r2 * s7 + r4 * s1 - r5 * s0 + r6 * s3 + r7 * s2;
		sample[@ b+7] = r3 * s7 - r0 * s4 - r1 * s5 - r2 * s6 - r4 * s0 - r5 * s1 - r6 * s2 + r7 * s3;
		if (!transformChildren)
		{
			var NQ = sample_get_node_dq(rig, nodeInd, sample, global.AnimTempQ2);
			var dx = smf_dq_get_x(NQ) - smf_dq_get_x(PQ);
			var dy = smf_dq_get_y(NQ) - smf_dq_get_y(PQ);
			var dz = smf_dq_get_z(NQ) - smf_dq_get_z(PQ);
			//Translate all of this node's children
			for (var i = 0; i < num; i ++)
			{
				sample_node_translate(rig, children[i], sample, dx, dy, dz, true);
			}
		}
	}

	//Transform all of this node's children
	if (transformChildren || b < 0)
	{
		for (var i = 0; i < num; i ++)
		{
			sample_node_transform(rig, children[i], sample, DQ, transformChildren);
		}
	}
	return sample;
}

function sample_node_translate(rig, nodeInd, sample, dx, dy, dz, transformChildren) 
{	/*	This script lets you modify a sample.
		This is useful for head turning and procedural animations.

		Note, this script in particular can mess up your rig structure. Unless you know what you're doing, 
		you may be better off using the other real-time sample editing scripts!*/
	var b = rig.bindMap[| nodeInd];
	var node = rig.nodeList[| nodeInd];
	var children = node[eAnimNode.Children];
	var num = array_length(children);

	//Transform node
	if (b >= 0)
	{
		b *= 8;
		var s0 = sample[b];
		var s1 = sample[b+1];
		var s2 = sample[b+2];
		var s3 = sample[b+3];
		var tx = dx * .5;
		var ty = dy * .5;
		var tz = dz * .5;
		sample[@ b+4] += + tx * s3 + ty * s2 - tz * s1;
		sample[@ b+5] += - tx * s2 + ty * s3 + tz * s0;
		sample[@ b+6] += + tx * s1 - ty * s0 + tz * s3;
		sample[@ b+7] += - tx * s0 - ty * s1 - tz * s2;
	}

	//Transform all of this node's children
	if (transformChildren || b < 0)
	{
		for (var i = 0; i < num; i ++)
		{
			sample_node_translate(rig, children[i], sample, dx, dy, dz, transformChildren);
		}
	}
	return sample;
}

function sample_update_locked_bones(rig, nodeInd, sample, transformChildren)
{
	//Check for locked bones
	var nodeList = rig.nodeList;
	var node = nodeList[| nodeInd];
	var descendants = node[eAnimNode.Descendants];
	var num = array_length(descendants);
	for (var i = 0; i < num; i ++)
	{
		var cNode = nodeList[| descendants[i]];
		if (!cNode[eAnimNode.Locked]){continue;}
		var p = cNode[eAnimNode.LockedPos];
		if !is_array(p){continue;}
		if (cNode[eAnimNode.Parent] == nodeInd)
		{
			sample_node_drag(rig, descendants[i], sample, p[0], p[1], p[2], transformChildren);
		}
		else
		{
			sample_node_move(rig, descendants[i], sample, p[0], p[1], p[2], true, transformChildren);
		}
	}
}