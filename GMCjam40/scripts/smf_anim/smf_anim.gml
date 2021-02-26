// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function smf_anim(_name) constructor
{	//Creates a new empty animation
	name = _name;
	nodeNum = 0;
	keyframeGrid = ds_grid_create(2, 0);
	interpolation = eAnimInterpolation.Quadratic;
	loop = true;
	sampleFrameMultiplier = 5;
	playTime = 1000; //In milliseconds
	keyframeNum = 0;
	
	/// @func destroy()
	static destroy = function() 
	{
		ds_grid_destroy(keyframeGrid);
	}
	
	/// @func duplicate()
	static duplicate = function() 
	{
		var newAnim = new smf_anim(name + "2");
		newAnim.nodeNum = nodeNum;
		newAnim.interpolation = interpolation;
		newAnim.loop = loop;
		newAnim.sampleFrameMultiplier = sampleFrameMultiplier;
		newAnim.playTime = playTime;
		newAnim.keyframeNum = keyframeNum;
		ds_grid_resize(newAnim.keyframeGrid, 2, keyframeNum);
		for (var i = 0; i < keyframeNum; i ++)
		{
			var keyframe = keyframeGrid[# 1, i];
			var newKeyframe = array_create(nodeNum);
			for (var j = 0; j < nodeNum; j ++)
			{
				newKeyframe[j] = array_create(8);
				array_copy(newKeyframe[j], 0, keyframe[j], 0, 8);
			}
			newAnim.keyframeGrid[# 0, i] = keyframeGrid[# 0, i];
			newAnim.keyframeGrid[# 1, i] = newKeyframe;
		}
		return newAnim;
	}
	
	/// @func update()
	static update = function() 
	{	//Updates a keyframe to the animation's rig so that it has the correct amount of bones
		for (var f = 0; f < keyframeNum; f ++)
		{
			var oldKeyframe = keyframeGrid[# 1, f];
			var num = min(nodeNum, array_length(oldKeyframe));
			var keyframe = array_create(nodeNum);
			array_copy(keyframe, 0, oldKeyframe, 0, array_length(oldKeyframe));
			for (var i = num; i < nodeNum; i ++)
			{
				keyframe[i] = [0, 0, 0, 1, 0, 0, 0, 0]; //Identity dual quaternion
			}
			keyframeGrid[# 1, f] = keyframe;
		}
	}
	
	/// @func generate_sample(rig, time, [interpolation])
	static generate_sample = function() 
	{	/*	Allows you to generate a sample directly from the animation. This is a relatively slow process, but can still be used for a few objects at a time.
			I would much rather recommend using samplestrips that generating news samples directly!*/
		//Get model index and animation index
		var rig = argument[0];
		var time = argument[1];
		var itpl = interpolation;
		if (argument_count > 2)
		{
			itpl = argument[2];
		}

		//Make sure the rig actually contains bones
		if (rig.boneNum <= 0){return [0, 0, 0, 1, 0, 0, 0, 0];}

		//Force time between 0 and 1, inclusive 0 and 1.
		var timeDiv = floor(time);
		if (time != 0 && time == timeDiv){time = 1;}
		else{time -= timeDiv;}

		//Resize animation if it is the wrong size
		var nodeList = rig.nodeList;
		if (ds_list_size(nodeList) != nodeNum)
		{
			nodeNum = ds_list_size(nodeList);
			update();
		}

		var bonesInSample = 0;
		var tempDQ = global.AnimTempQ3;
		var worldDQ = global.AnimTempWorldDQ;
		if (nodeNum > array_length(worldDQ))
		{	//If the temporary world DQ array doesn't exist, create it and populate it with empty dual quats
			global.AnimTempWorldDQ = array_create(nodeNum);
			for (var i = 0; i < nodeNum; i ++)
			{
				global.AnimTempWorldDQ[i] = array_create(8);
			}
			worldDQ = global.AnimTempWorldDQ;
		}
		var node = nodeList[| 0];
		array_copy(worldDQ[0], 0, node[eAnimNode.WorldDQ], 0, 8);
		var returnSample = array_create(rig.boneNum * 8, 0);
		switch itpl
		{
			case eAnimInterpolation.Keyframe:
				var keyframeA = keyframeGrid[# 1, keyframe_get(time)];
				for (var i = 0; i < nodeNum; i ++)
				{
					//Find local change in orientation
					array_copy(tempDQ, 0, keyframeA[i], 0, 8);
			
					//Find local and then world orientation of the node
					node = nodeList[| i];
					smf_dq_multiply(node[eAnimNode.LocalDQ], tempDQ, tempDQ);
					smf_dq_multiply(worldDQ[node[eAnimNode.Parent]], tempDQ, worldDQ[i]);
		
					//If this node is not a bone, continue the loop
					if !node[eAnimNode.IsBone]{continue;}
		
					//Create delta world dual quaternion and add it to the sample
					smf_dq_normalize(smf_dq_multiply(worldDQ[i], node[eAnimNode.WorldDQConjugate], tempDQ));
					array_copy(returnSample, bonesInSample * 8, tempDQ, 0, 8);
					bonesInSample ++;
				}
				break;
		
			case eAnimInterpolation.Linear:
				var keyframeArray = keyframe_get_linear(time);
				var keyframeA = keyframeGrid[# 1, keyframeArray[0]];
				var keyframeB = keyframeGrid[# 1, keyframeArray[1]];
				for (var i = 0; i < nodeNum; i ++)
				{
					//Find interpolated local change in orientation
					var A = keyframeA[i];
					var B = keyframeB[i];
					if (smf_quat_dot(A, B) < 0){smf_dq_invert(A);}
					smf_dq_lerp(A, B, keyframeArray[2], tempDQ);
					smf_dq_normalize(tempDQ);
					
					//Find local and then world orientation of the node
					node = nodeList[| i];
					smf_dq_multiply(node[eAnimNode.LocalDQ], tempDQ, tempDQ);
					smf_dq_multiply(worldDQ[node[eAnimNode.Parent]], tempDQ, worldDQ[i]);
					
					//If this node is not a bone, continue the loop
					if !node[eAnimNode.IsBone]{continue;}
					
					//Create delta world dual quaternion and add it to the sample
					smf_dq_normalize(smf_dq_multiply(worldDQ[i], node[eAnimNode.WorldDQConjugate], tempDQ));
					array_copy(returnSample, bonesInSample * 8, tempDQ, 0, 8);
					bonesInSample ++;
				}
				break;
	
			case eAnimInterpolation.Quadratic:
				var keyframeArray = keyframe_get_quadratic(time);
				var keyframeA = keyframeGrid[# 1, keyframeArray[0]];
				var keyframeB = keyframeGrid[# 1, keyframeArray[1]];
				var keyframeC = keyframeGrid[# 1, keyframeArray[2]];
				for (var i = 0; i < nodeNum; i ++)
				{
					//Make sure all DQs describe rotations within the same half of the hypersphere
					var A = keyframeA[i];
					var B = keyframeB[i];
					var C = keyframeC[i];
					if (smf_quat_dot(A, B) < 0){smf_dq_invert(A);}
					if (smf_quat_dot(B, C) < 0){smf_dq_invert(C);}
			
					//Find interpolated local change in orientation
					smf_dq_quadratic_interpolate(A, B, C, keyframeArray[3], tempDQ);
					smf_dq_normalize(tempDQ);
			
					//Find local and then world orientation of the node
					node = nodeList[| i];
					smf_dq_multiply(node[eAnimNode.LocalDQ], tempDQ, tempDQ);
					smf_dq_multiply(worldDQ[node[eAnimNode.Parent]], tempDQ, worldDQ[i]);
		
					//If this node is not a bone, continue the loop
					if !node[eAnimNode.IsBone]{continue;}
		
					//Create delta world dual quaternion and add it to the sample
					smf_dq_normalize(smf_dq_multiply(worldDQ[i], node[eAnimNode.WorldDQConjugate], tempDQ));
					array_copy(returnSample, bonesInSample * 8, tempDQ, 0, 8);
					bonesInSample ++;
				}
				break;
		}
		return returnSample;


	}
	
	/// @func add_keyframe(time)
	static keyframe_add = function(time) 
	{	//Creates a blank keyframe. Returns the index of the new keyframe
		time = floor(clamp(time, 0, 0.99999) * 1000) / 1000;
		
		//Make sure there doesn't already exist a keyframe at this position
		var keyframe;
		var keyframeInd = keyframeNum;
		for (var i = 0; i < keyframeNum; i ++)
		{
			if (keyframeGrid[# 0, i] == time)
			{
				keyframeInd = i;
				keyframe = keyframeGrid[# 1, i];
				break;
			}
		}
		if (keyframeInd == keyframeNum)
		{	//Add time and keyframe to keyframe list
			keyframeNum ++;
			ds_grid_resize(keyframeGrid, 2, keyframeInd + 1);
			keyframe = array_create(nodeNum, 0);
		}
		for (var i = 0; i < nodeNum; i ++)
		{
			keyframe[i] = [0, 0, 0, 1, 0, 0, 0, 0]; //Identity dual quaternion
		}
		keyframeGrid[# 0, keyframeInd] = time;
		keyframeGrid[# 1, keyframeInd] = keyframe;

		//Sort the grid by ascending time
		ds_grid_sort(keyframeGrid, 0, true);

		//Find the index of the new keyframe
		for (var i = 0; i < keyframeNum; i ++)
		{
			if keyframeGrid[# 0, i] == time
			{
				keyframeInd = i;
				break;
			}
		}
		return keyframeInd;
	}

	/// @func keyframe_delete(keyframeInd)
	static keyframe_delete = function(keyframeInd) 
	{	//Deletes the given keyframe from the animation
		//Shift all keyframes below the deleted keyframe up by one
		for (var i = keyframeInd + 1; i < keyframeNum; i ++)
		{
			keyframeGrid[# 0, i - 1] = keyframeGrid[# 0, i];
			keyframeGrid[# 1, i - 1] = keyframeGrid[# 1, i];
		}
		keyframeNum --;
		ds_grid_resize(keyframeGrid, 2, keyframeNum);
	}

	/// @func keyframe_duplicate(keyframeInd, time)
	static keyframe_duplicate = function(keyframeSrc, time) 
	{
		time = floor(clamp(time, 0, 0.99999) * 1000) / 1000;

		//Make sure there doesn't already exist a keyframe at this position
		for (var i = 0; i < keyframeNum; i ++)
		{
			if (keyframeGrid[# 0, i] == time)
			{
				return keyframeGrid[# 0, i];
			}
		}

		//Add time and keyframe to keyframe list
		var srcKeyframe = keyframeGrid[# 1, keyframeSrc];
		var keyframeInd = keyframeNum;
		ds_grid_resize(keyframeGrid, 2, keyframeInd + 1);
		keyframeNum ++;
		var keyframe = array_create(nodeNum, 0);
		for (var i = 0; i < nodeNum; i ++)
		{
			keyframe[i] = array_create(8);
			array_copy(keyframe[i], 0, srcKeyframe[i], 0, 8);
		}
		keyframeGrid[# 0, keyframeInd] = time;
		keyframeGrid[# 1, keyframeInd] = keyframe;

		//Sort the grid by ascending time
		ds_grid_sort(keyframeGrid, 0, true);

		//Find the index of the new keyframe
		for (var i = 0; i < keyframeNum; i ++)
		{
			if keyframeGrid[# 0, i] == time
			{
				keyframeInd = i;
				break;
			}
		}
		return keyframeInd;
	}

	/// @func keyframe_clear(keyframeInd)
	static keyframe_clear = function(keyframeInd) 
	{
		var keyframe = array_create(nodeNum);
		for (var i = 0; i < nodeNum; i ++)
		{
			keyframe[i] = [0, 0, 0, 1, 0, 0, 0, 0];
		}
		keyframeGrid[# 1, keyframeInd] = keyframe;
	}

	/// @func keyframe_get_node_dq(rig, keyframeInd, nodeInd) 
	static keyframe_get_node_dq = function(rig, keyframeInd, nodeInd) 
	{	/*	Finds the rig-space dual quaternion of the given node.
			This needs to multiply backwards in the hierarchy all the way to the root node, and as such, this is fairly slow.*/
		var keyframe = keyframeGrid[# 1, keyframeInd];
		if !is_array(keyframe){
			show_debug_message("Error in script keyframe_get_node_dq: Trying to read from non-existing keyframe " + string(keyframeInd)); 
			exit;}
	
		//Multiply backwards in the hierarchy to find the node's dual quaternion
		var nodeList = rig.nodeList;
		var localDQ = global.AnimTempQ4;
		var worldDQ = [0, 0, 0, 1, 0, 0, 0, 0];
		while (nodeInd > 0)
		{
			var node = nodeList[| nodeInd];
			var deltaLocal = keyframe[nodeInd];
			smf_dq_multiply(node[eAnimNode.LocalDQ], keyframe[nodeInd], localDQ);
			smf_dq_multiply(localDQ, worldDQ, worldDQ);
			nodeInd = node[eAnimNode.Parent];
		}
		node = nodeList[| 0];
		smf_dq_multiply(node[eAnimNode.LocalDQ], keyframe[0], localDQ);
		smf_dq_multiply(localDQ, worldDQ, worldDQ);
		smf_dq_multiply(node[eAnimNode.WorldDQ], worldDQ, worldDQ);
		return worldDQ;
	}
	
	/// @func keyframe_get_node_matrix(rig, keyframeInd, node)
	static keyframe_get_node_matrix = function(rig, keyframeInd, node) 
	{
		return smf_mat_create_from_dualquat(keyframe_get_node_dq(rig, keyframeInd, node), array_create(16));
	}
	
	/// @func keyframe_get_node_position(rig, keyframeInd, node)
	static keyframe_get_node_position = function(rig, keyframeInd, node)
	{
		return smf_dq_get_translation(keyframe_get_node_dq(rig, keyframeInd, node));
	}

	/// @func keyframe_get_string(keyframeInd)
	static keyframe_get_string = function(keyframeInd) 
	{	//Writes a keyframe to a string, for copying more easily to clipboard
		var keyframe = keyframeGrid[# 1, keyframeInd];
		if !is_array(keyframe){
			show_debug_message("Error in script anim_keyframe_get_string: Trying to read from non-existing keyframe " + string(keyframeInd)); 
			exit;}
		//Create string
		var num = array_length(keyframe);
		var str = "KEYFRAME/";
		for (var i = 0; i < num; i ++)
		{
			var deltaDQ = keyframe[i];
			for (var j = 0; j < 8; j ++)
			{
				if (deltaDQ[j] == 0 || deltaDQ[j] == 1)
				{
					str += string(round(deltaDQ[j])) + "/";
				}
				else
				{
					str += string_format(deltaDQ[j], 1, 8) + "/";
				}
			}
		}
		return str;
	}
	
	/// @func keyframe_set_from_string(keyframeInd, str)
	static keyframe_set_from_string = function(keyframeInd, str)
	{	//Overwrites a keyframe from a string
		if !is_string(str){return false;}
		var pos = string_pos("/", str);
		var probe = string_copy(str, 1, pos-1);
		if probe != "KEYFRAME"
		{
			show_debug_message("Error in script keyframe_set_from_string: The given string does not contain a keyframe"); 
			return false;
		}
		str = string_delete(str, 1, pos);
		var keyframe = array_create(string_count("/", str) / 8);
		var deltaDQ = array_create(8);
		var i = 0;
		var j = 0;
		while (str != "")
		{
			pos = string_pos("/", str);
			probe = string_copy(str, 1, pos-1);
			str = string_delete(str, 1, pos);
			deltaDQ[j] = real(probe);
			j ++;
			if (j >= 8)
			{
				keyframe[@ i++] = deltaDQ;
				deltaDQ = array_create(8);
				j = 0;
			}
		}
		keyframeGrid[# 1, keyframeInd] = keyframe;
		return true;
	}

	/// @func keyframe_set_from_sample(rig, keyframeInd, sample)
	static keyframe_set_from_sample = function(rig, keyframeInd, sample) 
	{	/*	Creates a keyframe at the given time using the given sample as reference
			Returns the index of the new keyframe*/
		var nodeList = rig.nodeList;

		//Create keyframe
		var keyframe = keyframeGrid[# 1, keyframeInd];
		var localDQ = global.AnimTempQ1;
		var deltaLocalDQ = global.AnimTempQ2;
		var parentConj = global.AnimTempQ3;
		var worldDQ = global.AnimTempWorldDQ;
		if (nodeNum > array_length(worldDQ))
		{	
			//If the temporary world DQ array doesn't exist, create it and populate it with empty dual quats
			global.AnimTempWorldDQ = array_create(nodeNum);
			for (var i = 0; i < nodeNum; i ++)
			{
				global.AnimTempWorldDQ[i] = array_create(8);
			}
			var worldDQ = global.AnimTempWorldDQ;
		}
		var node = nodeList[| 0];
		array_copy(worldDQ[0], 0, node[eAnimNode.WorldDQ], 0, 8);
		for (var i = 0; i < nodeNum; i ++)
		{
			node = nodeList[| i];
			smf_dq_get_conjugate(worldDQ[node[eAnimNode.Parent]], parentConj)
			sample_get_node_dq(rig, i, sample, worldDQ[i]);
			smf_dq_multiply(parentConj, worldDQ[i], localDQ);
			smf_dq_multiply(node[eAnimNode.LocalDQConjugate], localDQ, deltaLocalDQ);
			if node[eAnimNode.IsBone]
			{
				deltaLocalDQ[4] = 0;
				deltaLocalDQ[5] = deltaLocalDQ[2] * node[eAnimNode.Length];
				deltaLocalDQ[6] = -deltaLocalDQ[1] * node[eAnimNode.Length];
				deltaLocalDQ[7] = 0;
			}
			smf_dq_normalize(deltaLocalDQ);
			array_copy(keyframe[i], 0, deltaLocalDQ, 0, 8);
		}
	}
	
	/// @func keyframe_set_node_dq(rig, keyframeInd, nodeInd, DQ, moveFromCurrent, transformChildren) 
	static keyframe_set_node_dq = function(rig, keyframeInd, nodeInd, DQ, moveFromCurrent, transformChildren) 
	{
		var nodeList = rig.nodeList;
		var keyframe = keyframeGrid[# 1, keyframeInd];
		if !is_array(keyframe)
		{
			show_debug_message("Error in script anim_keyframe_set_node_dq: Trying to modify non-existing keyframe " + string(keyframeInd)); 
			exit;
		}

		//Create a keyframe sample
		var keyframeTime = keyframeGrid[# 0, keyframeInd];
		var sample = generate_sample(rig, keyframeTime, eAnimInterpolation.Keyframe);

		sample_node_set_dq(rig, nodeInd, sample, DQ, moveFromCurrent, transformChildren)
		sample_update_locked_bones(rig, nodeInd, sample, transformChildren);
		keyframe_set_from_sample(rig, keyframeInd, sample);
	}
	
	/// @func keyframe_set_time(keyframeInd, time) 
	static keyframe_set_time = function(keyframeInd, time) 
	{
		time = clamp(time, 0, 0.99999);
		for (var i = 0; i < keyframeNum; i ++)
		{
			if (keyframeGrid[# 0, i] == time)
			{
				exit;
			}
		}
		keyframeGrid[# 0, keyframeInd] = time;
	}
	
	/// @func keyframe_get(time)
	static keyframe_get = function(time) 
	{
		var a = 0;
		var minD = 1;
		for (var i = 0; i < keyframeNum; i ++)
		{
			var d = abs(keyframeGrid[# 0, i] - time);
			if (d >= minD)
			{
				break;
			}
			minD = d;
			a = i;
		}
		return a;
	}
	
	/// @func keyframe_get_linear(time)
	static keyframe_get_linear = function(time) 
	{
		var a = 0;
		var b = 0;
		var d = 0;
		for (var j = 0; j < keyframeNum; j ++)
		{
			if (keyframeGrid[# 0, j] > time)
			{
				b = j; 
				break;
			}
		}
		if loop
		{	//If the animation is looping, make "a" loop around to the end of the animation if "b" is 0
			a = (b - 1 + keyframeNum) mod keyframeNum;
		}
		else
		{
			if b == 0
			{	//If we're not looping, "b" cannot be 0, and so is moved to the end of the animation instead
				b = keyframeNum - 1; 
				a = b;
			} 
			else
			{
				a = max(b - 1, 0);
			}
		}
		if (a != b)
		{
			var tb = keyframeGrid[# 0, b]; 
			tb += (time > tb);
			var ta = keyframeGrid[# 0, a]; 
			ta -= (ta > tb);
			if (tb == ta){d = 0;}
			else
			{
				d = (time - ta) / (tb - ta);
			}
		}

		return [a, b, d];
	}
	
	/// @func keyframe_get_quadratic(time)
	static keyframe_get_quadratic = function(time) 
	{
		var a = 0;
		var b = 0;
		var c = 0;
		var d = 0;
		for (var j = 0; j < keyframeNum; j ++)
		{
			a = j;
			b = (a + 1) mod keyframeNum;
			c = (a + 2) mod keyframeNum;
			var ta = keyframeGrid[# 0, a];
			var tb = keyframeGrid[# 0, b];
			var tc = keyframeGrid[# 0, c];
			if (loop)
			{
				if (time > tc)
				{
					tb += (tb < ta);
					tc += (tc < tb);
				}
				tb -= (tb > tc);
				ta -= (ta > tb);
			}
			else
			{
				if (a == keyframeNum - 2)
				{
					c = keyframeNum - 1;
					tc = 1;
				}
				if (a == keyframeNum - 1)
				{
					if (time > tc)
					{
						b = keyframeNum - 1;
						tb = ta;
						c = keyframeNum - 1;
						tc = 1;
					}
					else
					{
						a = 0;
						ta = 0;
						b = 0;
						tb = 0;
					}
				}
			}
			if (time >= (ta + tb) * .5 && time <= (tb + tc) * .5)
			{
				if (time < tb)
				{
					d = (time - (ta + tb) * .5) / (tb - ta);
				}
				else
				{
					d = (tc == tb) ? 1 : .5 + (time - tb) / (tc - tb);
				}
				break;
			}
		}

		return [a, b, c, d];
	}
}

//Compatibility scripts
function anim_create(name)
{
	return new smf_anim(name);
}
/// @func anim_generate_sample(rig, anim, time, [interpolation])
function anim_generate_sample() 
{
	var rig = argument[0];
	var anim = argument[1];
	var time = argument[2];
	var interpolation = anim.interpolation;
	if (argument_count > 3)
	{
		interpolation = argument[3];
	}
	return anim.generate_sample(rig, time, interpolation);
}
function anim_delete(anim) 
{
	anim.destroy();
	delete anim;
}
function anim_duplicate(anim) 
{
	return anim.duplicate();
}
function anim_add_keyframe(anim, time) 
{
	return anim.keyframe_add(time);
}
function anim_delete_keyframe(anim, keyframeInd) 
{	
	return anim.keyframe_delete(keyframeInd);
}
function anim_duplicate_keyframe(anim, keyframeInd, time) 
{
	return anim.keyframe_duplicate(keyframeInd, time);
}
function anim_keyframe_clear(anim, keyframeInd) 
{
	return anim.keyframe_clear(keyframeInd);
}
function anim_keyframe_get_node_dq(rig, anim, keyframeInd, nodeInd) 
{	
	return anim.keyframe_get_node_dq(rig, keyframeInd, nodeInd);
}
function anim_keyframe_get_node_matrix(rig, anim, keyframeInd, node) 
{
	return anim.keyframe_get_node_matrix(rig, keyframeInd, node);
}
function anim_keyframe_get_node_position(rig, anim, keyframeInd, node) 
{
	return anim.keyframe_get_node_position(rig, keyframeInd, node);
}
function anim_keyframe_get_string(anim, keyframeInd) 
{	
	return anim.keyframe_get_string(keyframeInd);
}
function anim_keyframe_set_from_string(anim, keyframeInd, str)
{	
	return anim.keyframe_set_from_string(keyframeInd, str);
}
function anim_keyframe_set_from_sample(rig, anim, keyframeInd, sample) 
{	
	return anim.keyframe_set_from_sample(rig, keyframeInd, sample) ;
}
function anim_keyframe_set_node_dq(rig, anim, keyframeInd, nodeInd, DQ, moveFromCurrent, transformChildren) 
{
	return anim.keyframe_set_node_dq(rig, keyframeInd, nodeInd, DQ, moveFromCurrent, transformChildren);
}
function anim_keyframe_set_time(anim, keyframeInd, time) 
{
	return anim.keyframe_set_time(keyframeInd, time);
}
function anim_get_interpolation(anim) 
{
	return anim.interpolation;
}
function anim_get_keyframe_num(anim)
{
	return ds_grid_height(anim.keyframeGrid);
}
function anim_get_loop(anim) 
{
	return anim.loop;
}
function anim_get_name(anim) 
{
	return animIndex.name;
}
function anim_get_playtime(anim) 
{
	return animIndex.playTime;
}
function anim_get_sample_frame_multiplier(anim) 
{
	return anim.sampleFrameMultiplier;
}
function anim_set_name(anim, name) 
{
	anim.name = name;
}
function anim_set_playtime(anim, playTime) 
{
	anim.playTime = playTime;
}
function anim_set_interpolation(anim, type) 
{	/*	Type can be one of the following:
		eAnimInterpolation.Linear
		eAnimInterpolation.Quadratic*/
	anim.interpolation = type;
}
function anim_set_loop(anim, loop) 
{
	anim.loop = loop;
}
function _anim_get_keyframe(anim, time) 
{
	return anim.keyframe_get(time);
}
function _anim_get_keyframe_linear(anim, time) 
{
	return anim.keyframe_get_linear(time);
}
function _anim_get_keyframe_quadratic(anim, time) 
{
	return anim.keyframe_get_quadratic(time);
}
function anim_set_sample_frame_multiplier(anim, frameMultiplier) 
{	/*	When playing an animation, the animation is automatically cut up into smaller pieces that are linearly interpolated.
		This is ridiculously much more efficient than generating a new sample each step. 

		The animation is split into (number of keyframes) x (frame multiplier) frames.
		A higher number of steps will improve the quality of the animation, and will not affect the speed of the game, but will increase memory usage.*/
	anim.sampleFrameMultiplier = frameMultiplier;
}

function anim_write_to_buffer(saveBuff, anim)
{
	var keyframeGrid = anim.keyframeGrid;
	var keyframeNum = ds_grid_height(keyframeGrid);
	var nodeNum = anim.nodeNum;

	//Write header
	buffer_write(saveBuff, buffer_string, "SnidrsAnimation");

	//Write animation properties
	buffer_write(saveBuff, buffer_string, anim.name);
	buffer_write(saveBuff, buffer_u16, nodeNum);
	buffer_write(saveBuff, buffer_u16, anim.playTime);
	buffer_write(saveBuff, buffer_bool, anim.loop);
	buffer_write(saveBuff, buffer_u8, anim.interpolation);
	buffer_write(saveBuff, buffer_u8, anim.sampleFrameMultiplier);
	
	//Write keyframes
	buffer_write(saveBuff, buffer_u16, keyframeNum);
	for (var j = 0; j < keyframeNum; j ++)
	{
		var keyframeTime = keyframeGrid[# 0, j];
		var keyframe = keyframeGrid[# 1, j];
		var n = array_length(keyframe);
	
		//Write time of keyframe
		buffer_write(saveBuff, buffer_f32, keyframeTime);
		for (var k = 0; k < nodeNum; k ++)
		{
			if (k >= n)
			{
				keyframe[k] = [0, 0, 0, 1, 0, 0, 0, 0];
			}
			var deltaDQ = keyframe[k];
			for (var l = 0; l < 8; l ++)
			{
				//Write delta local dual quaternion of the keyframe node
				buffer_write(saveBuff, buffer_f32, deltaDQ[l]);
			}
		}
	}
}

function anim_read_from_buffer(loadBuff)
{
	//Read header
	var header = buffer_read(loadBuff, buffer_string);
	if (header != "SnidrsAnimation")
	{
		show_debug_message("ERROR in script anim_read_from_buffer: Trying to read from a section that does not contain animation.");
		return -1;
	}

	//Read animation
	var animName = buffer_read(loadBuff, buffer_string);
	var anim = new smf_anim(animName);
	var nodeNum = buffer_read(loadBuff, buffer_u16);
	anim.nodeNum = nodeNum;
	anim.playTime = buffer_read(loadBuff, buffer_u16);
	anim.loop = buffer_read(loadBuff, buffer_bool);
	anim.interpolation = buffer_read(loadBuff, buffer_u8);
	anim.sampleFrameMultiplier = buffer_read(loadBuff, buffer_u8);
	
	//Read keyframes
	var keyframeNum = buffer_read(loadBuff, buffer_u16);
	var keyframeGrid = anim.keyframeGrid;
	for (var j = 0; j < keyframeNum; j ++)
	{
		//Read keyframe
		var keyframeTime = buffer_read(loadBuff, buffer_f32);
		var keyframeInd = anim_add_keyframe(anim, keyframeTime);
		var keyframe = keyframeGrid[# 1, keyframeInd];
		for (var k = 0; k < nodeNum; k ++)
		{
			var deltaDQ = keyframe[k];
			for (var l = 0; l < 8; l ++)
			{
				//Read delta local dual quaternion of the keyframe node
				deltaDQ[@ l] = buffer_read(loadBuff, buffer_f32);
			}
		}
	}
	return anim;
}
function _anim_update(anim) 
{
	anim.update();
}