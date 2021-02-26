// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function smf_rig() constructor
{
	nodeList = ds_list_create();
	bindMap = ds_list_create();
	boneNum = 0;
	nodeNum = 0;
	
	static destroy = function()
	{
		ds_list_destroy(nodeList);
		ds_list_destroy(bindMap);
	}
	static clear = function() 
	{
		ds_list_clear(nodeList);
		ds_list_clear(bindMap);
		boneNum = 0;
	}
	static get_node_number = function()
	{
		return ds_list_size(nodeList);
	}
	static lock_positions = function(sample)
	{
		nodeNum = ds_list_size(nodeList);
		for (var i = 0; i < nodeNum; i ++)
		{
			var node = nodeList[| i];
			if (node[eAnimNode.IsBone] && !node[eAnimNode.Locked]){continue;}
			node[@ eAnimNode.LockedPos] = sample_get_node_position(self, i, sample);
		}
	}
	static transform = function(DQ, xScale, yScale, zScale) 
	{
		nodeNum = ds_list_size(nodeList);
		for (var i = 0; i < nodeNum; i ++)
		{
			var node = nodeList[| i];
			smf_dq_multiply(DQ, node[eAnimNode.WorldDQ], node[eAnimNode.WorldDQ]);
			var nPos = smf_dq_get_translation(node[eAnimNode.WorldDQ]);
			smf_dq_set_translation(node[eAnimNode.WorldDQ], nPos[0] * xScale, nPos[1] * yScale, nPos[2] * zScale);
			update_node(i);
		}
	}
	
	/// @func node_create(pos, parent, isBone)
	static node_create = function(pos, parent, isBone)
	{
		var nodeInd = ds_list_size(nodeList);
		var node = array_create(eAnimNode.Num, 0);

		//If the parent does not exist or if this is the first node, it cannot represent a bone
		if (parent < 0 || ds_list_size(nodeList) == 0)
		{
			isBone = false;
		}

		//Create the node, which is a 10-index array containing a dual quaternion, the parent index and whether or not the node is attached to its parent
		node[@ eAnimNode.Name] = string(ds_list_size(nodeList));
		node[@ eAnimNode.Parent] = max(parent, 0);
		node[@ eAnimNode.IsBone] = isBone;
		node[@ eAnimNode.Children] = [];
		node[@ eAnimNode.Descendants] = [];
		node[@ eAnimNode.PrimaryAxis] = [1, 0, 0];
		var parentNode = nodeList[| parent];
		if isBone
		{
			//If this node is attached to its parent, make it have the same orientation as the parent
			node[@ eAnimNode.WorldDQ] = smf_dq_duplicate(parentNode[eAnimNode.WorldDQ]);
			smf_dq_set_translation(node[eAnimNode.WorldDQ], pos[0], pos[1], pos[2]);
		}
		else
		{
			//This node is detached, no orientation info is inherited from the parent
			node[@ eAnimNode.WorldDQ] = smf_dq_create(0, 1, 0, 0, pos[0], pos[1], pos[2]);
		}

		nodeList[| nodeInd] = node;
		update_node(nodeInd);
		update_bindmap();
		return nodeInd;
	}
	
	/// @func node_insert(nodeInd)
	static node_insert = function(nodeInd)
	{
		var nodeNum = ds_list_size(nodeList);
		if (nodeInd <= 0 || ds_list_size(nodeList) < 2){
			show_debug_message("ERROR in script node_insert: Could not insert node at position " + string(nodeInd));
			exit;}

		//Find the middle point between the current node and its parent
		var childNode = nodeList[| nodeInd];
		var childPos = smf_dq_get_translation(childNode[eAnimNode.WorldDQ]);
		var parent = childNode[eAnimNode.Parent];
		var parentNode = nodeList[| parent];
		var parentPos = smf_dq_get_translation(parentNode[eAnimNode.WorldDQ]);
		var newX = (childPos[0] + parentPos[0]) * .5
		var newY = (childPos[1] + parentPos[1]) * .5
		var newZ = (childPos[2] + parentPos[2]) * .5

		//Create new node
		var node = array_create(eAnimNode.Num);
		node[eAnimNode.Parent] = parent;
		node[eAnimNode.IsBone] = childNode[eAnimNode.IsBone];
		node[eAnimNode.Descendants] = [];
		node[eAnimNode.WorldDQ] = smf_dq_duplicate(childNode[eAnimNode.WorldDQ]);
		smf_dq_set_translation(node[eAnimNode.WorldDQ], newX, newY, newZ);
		ds_list_insert(nodeList, nodeInd, node);

		//Shift the parents of the nodes that come after the new node
		nodeNum = ds_list_size(nodeList);
		childNode[@ eAnimNode.Parent] = nodeInd;
		for (i = nodeInd+2; i < nodeNum; i ++)
		{
			node = nodeList[| i];
			if node[eAnimNode.Parent] >= nodeInd
			{
				node[@ eAnimNode.Parent] ++;
			}
		}
		
		//Update node, child and grandchild
		update_bindmap();
		update_node(nodeInd);
		var i, j, childArray, childNum, grandchildArray, child, grandchildNum;
		node = nodeList[| nodeInd];
		childArray = node[eAnimNode.Children];
		childNum = array_length(childArray);
		for (i = 0; i < childNum; i ++)
		{
			child = nodeList[| childArray[i]];
			update_node(childArray[i]);
			grandchildArray = child[eAnimNode.Children];
			grandchildNum = array_length(grandchildArray);
			for (j = 0; j < grandchildNum; j ++)
			{
				update_node(grandchildArray[j]);
			}
		}
		return nodeInd;
	}
	
	/// @func node_get_dq(nodeInd)
	static node_get_dq = function(nodeInd) 
	{
		var node = nodeList[| nodeInd];
		if is_undefined(node){
			show_debug_message("ERROR in script node_get_dq: Invalid nodeIndex " + string(nodeInd));
			return false;}
		return node[eAnimNode.WorldDQ];
	}
	
	/// @func node_delete(nodeInd)
	static node_delete = function(nodeInd) 
	{
		//Exit if the node index doesn't make sense
		if (nodeInd < 0){
			show_debug_message("ERROR in script node_delete: Trying to delete a nodeInd < 0");
			return false;}

		var nodeNum = ds_list_size(nodeList);
		var node = nodeList[| nodeInd];
		var childArray = node[eAnimNode.Children];
		var parent = node[eAnimNode.Parent];

		//Exit if the node doesn't exist
		if nodeInd >= nodeNum{
			show_debug_message("ERROR in script node_delete: Node " + string(nodeInd) + " does not exist in rig");
			return false;}
	
		//Delete node from list
		ds_list_delete(nodeList, nodeInd);
		nodeNum --;

		//Alter the parent indices of the nodes that come after the deleted node accordingly
		for (i = nodeInd; i < nodeNum; i ++)
		{
			node = nodeList[| i];
			if node[eAnimNode.Parent] > nodeInd
			{
				node[@ eAnimNode.Parent] = max(node[eAnimNode.Parent] - 1, 0);
			}
			else if node[eAnimNode.Parent] == nodeInd
			{
				node[@ eAnimNode.Parent] = parent;
			}
			//If the first node has been deleted, the next node in line will replace it
			if i == 0
			{
				node[@ eAnimNode.IsBone] = false;
			}
		}

		//Update bindmap
		update_bindmap();

		//Update node, child and grandchild
		var i, j, childNum, grandchildArray, child, grandchildNum;
		childNum = array_length(childArray);
		for (i = 0; i < childNum; i ++)
		{
			child = nodeList[| childArray[i] - 1];
			update_node(childArray[i] - 1);
			grandchildArray = child[eAnimNode.Children];
			grandchildNum = array_length(grandchildArray);
			for (j = 0; j < grandchildNum; j ++)
			{
				update_node(grandchildArray[j]);
			}
		}

		return true;
	}
	
	/// @func node_move(nodeInd, px, py, pz)
	static node_move = function(nodeInd, px, py, pz)
	{
		var node = nodeList[| nodeInd];
		smf_dq_set_translation(node[eAnimNode.WorldDQ], px, py, pz);

		//Update node, child and grandchild
		update_node(nodeInd);
		var i, j, childArray, childNum, grandchildArray, child, grandchildNum;
		childArray = node[eAnimNode.Children];
		childNum = array_length(childArray);
		for (i = 0; i < childNum; i ++)
		{
			child = nodeList[| childArray[i]];
			update_node(childArray[i]);
			grandchildArray = child[eAnimNode.Children];
			grandchildNum = array_length(grandchildArray);
			for (j = 0; j < grandchildNum; j ++)
			{
				update_node(grandchildArray[j]);
			}
		}
	}
	
	/// @func node_rotate(nodeInd, radians)
	static node_rotate = function(nodeInd, radians)
	{
		var node = nodeList[| nodeInd];
		smf_dq_multiply(node[eAnimNode.WorldDQ], smf_dq_create(radians, 1, 0, 0, 0, 0, 0), node[eAnimNode.WorldDQ]);
		update_node(nodeInd);

		//Update all children of this node
		var nodeNum = ds_list_size(nodeList);
		for (var i = nodeInd + 1; i < nodeNum; i ++)
		{
			var childNode = nodeList[| i];
			if childNode[eAnimNode.Parent] == nodeInd
			{
				update_node(i);
			}
		}
	}
	
	/// @func node_set_locked(nodeInd, enable)
	static node_set_locked = function(nodeInd, enable)
	{
		//Exit if we're trying to enable bone for the first node
		if (nodeInd == 0){
			show_debug_message("ERROR in script node_set_locked: Cannot make the first node in the hierarchy represent a bone");
			return false;}
	
		//Exit if the node index doesn't make sense
		if (nodeInd < 0){
			show_debug_message("ERROR in script node_set_locked: Invalid nodeIndex " + string(nodeInd));
			return false;}
	
		var cNode = nodeList[| nodeInd];
		cNode[@ eAnimNode.Locked] = enable;
		return true;
	}
	/// @func node_get_locked(nodeInd)
	static node_get_locked = function(nodeInd)
	{
		var node = nodeList[| nodeInd];
		return node[eAnimNode.Locked];
	}
	
	/// @func node_set_parent(nodeInd, parent)
	static node_set_parent = function(nodeInd, parent) 
	{	/*	This script can potentially mess up your rig structure. There are checks in place 
			to avoid endless loops and such, but it may still mess up a lot. Use with care!*/

		//Exit if we're trying to change the parent of the first node
		if (nodeInd == 0){
			show_debug_message("ERROR in script node_set_parent: Cannot change the parent of the first node");
			return false;}
	
		//Exit if the node index doesn't make sense
		if (nodeInd < 0){
			show_debug_message("ERROR in script node_set_parent: Trying to edit a nodeIndex < 0");
			return false;}
			
		//Exit if the node doesn't exist
		var node = nodeList[| nodeInd];
		if !is_array(node){
			show_debug_message("ERROR in script node_set_parent: Node " + string(nodeInd) + " does not exist in rig");
			return false;}

		//Exit if the new parent's index is larger or equal to the current node
		if parent >= node[eAnimNode.Parent]{
			show_debug_message("ERROR in script node_set_parent: Cannot assign parent that has a higher node index than the child");
			return false;}

		node[@ eAnimNode.Parent] = parent;
		update_bindmap();

		return true;
	}
	
	/// @func node_set_bone(nodeInd, enable)
	static node_set_bone = function(nodeInd, enable) 
	{
		//Exit if we're trying to enable bone for the first node
		if (nodeInd == 0){
			show_debug_message("ERROR in script node_set_bone: Cannot make the first node in the hierarchy represent a bone");
			return false;}
	
		//Exit if the node index doesn't make sense
		if nodeInd < 0{
			show_debug_message("ERROR in script node_set_bone: Invalid nodeIndex " + string(nodeInd));
			return false;}

		var node = nodeList[| nodeInd];
		if !is_array(node){
			show_debug_message("ERROR in script node_set_bone: Invalid nodeIndex " + string(nodeInd));
			return false;}

		node[@ eAnimNode.IsBone] = enable;
		if !enable
		{
			node[@ eAnimNode.Length] = 0;
		}
		else
		{
			update_node(nodeInd);
		}
		update_bindmap(nodeInd);
		return true;
	}
	
	/// @func node_get_bone(nodeInd)
	static node_get_bone = function(nodeInd)
	{
		var node = nodeList[| nodeInd];
		if (is_undefined(node)){
			show_debug_message("ERROR in script node_get_bone: Invalid node index " + string(nodeInd));
			return false;}
		return node[eAnimNode.IsBone];
	}

	/// @func update_node(nodeInd)
	static update_node = function(nodeInd) 
	{	/*	Updates a node's orientation in relation to its parent. The following needs to be correct:
				WorldDQ
				IsBone
				Parent*/
		//Get node's current orientation
		var node = nodeList[| nodeInd];
		var nodeDQ = node[eAnimNode.WorldDQ];
		var nodePos = smf_dq_get_translation(nodeDQ);

		//Find parent node's position
		var parentNode = nodeList[| node[eAnimNode.Parent]];
		var parentPos = smf_dq_get_translation(parentNode[eAnimNode.WorldDQ]);
		var boneVx = nodePos[0] - parentPos[0];
		var boneVy = nodePos[1] - parentPos[1];
		var boneVz = nodePos[2] - parentPos[2];

		//Create the node's new orientation
		if node[eAnimNode.IsBone]
		{
			var nodeUp = smf_quat_get_up(nodeDQ);
			var nodeM = smf_mat_create(nodePos[0], nodePos[1], nodePos[2], boneVx, boneVy, boneVz, nodeUp[0], nodeUp[1], nodeUp[2], 1, 1, 1);
			smf_dq_normalize(smf_dq_create_from_matrix(nodeM, nodeDQ));
			node[@ eAnimNode.Length] = sqrt(sqr(boneVx) + sqr(boneVy) + sqr(boneVz));
	
			//Update primary axis
			var gNode = nodeList[| parentNode[eAnimNode.Parent]];
			var gPos = smf_dq_get_translation(gNode[eAnimNode.WorldDQ]);
			var upAxisX = boneVx;
			var upAxisY = boneVy;
			var upAxisZ = boneVz;
			var pAxisX = nodePos[0] - gPos[0];
			var pAxisY = nodePos[1] - gPos[1];
			var pAxisZ = nodePos[2] - gPos[2];
			var dp = (upAxisX * pAxisX + upAxisY * pAxisY + upAxisZ * pAxisZ) / (pAxisX * pAxisX + pAxisY * pAxisY + pAxisZ * pAxisZ);
			upAxisX -= pAxisX * dp;
			upAxisY -= pAxisY * dp;
			upAxisZ -= pAxisZ * dp;
			var l = upAxisX * upAxisX + upAxisY * upAxisY + upAxisZ * upAxisZ;
			if (l == 0)
			{
				node[@ eAnimNode.PrimaryAxis] = [0, 0, 1];
			}
			else
			{
				l = 1 / sqrt(l);
				node[@ eAnimNode.PrimaryAxis] = [upAxisX * l, upAxisY * l, upAxisZ * l];
			}
		}
		else if !is_array(node[eAnimNode.PrimaryAxis])
		{
			node[@ eAnimNode.PrimaryAxis] = [0, 0, 1];
		}
		//Save node info
		node[@ eAnimNode.WorldDQConjugate] = smf_dq_get_conjugate(nodeDQ, array_create(8));
		node[@ eAnimNode.LocalDQ] = smf_dq_multiply(parentNode[eAnimNode.WorldDQConjugate], nodeDQ, array_create(8));
		node[@ eAnimNode.LocalDQConjugate] = smf_dq_get_conjugate(node[eAnimNode.LocalDQ], array_create(8));
	}
	
	/// @func update_bindmap()
	static update_bindmap = function() 
	{	/*	This script must be used after adding or removing nodes in the rig.
			It keeps the sample mapping list updated so that nodes that aren't attached
			to their parents aren't included in the sample.
			It also keeps track of all nodes' descendants*/
		if bindMap < 0
		{
			bindMap = ds_list_create();
		}
		ds_list_clear(bindMap);

		var sampleBoneInd = 0;
		nodeNum = ds_list_size(nodeList);
		for (var i = 0; i < nodeNum; i ++)
		{
			var node = nodeList[| i];
			if node[eAnimNode.IsBone]
			{
				bindMap[| i] = sampleBoneInd;
				sampleBoneInd ++;
			}
			else
			{
				bindMap[| i] = -1;
			}
	
			//Loop through all ancestors and add this node to their descendant arrays
			node[@ eAnimNode.Children] = [];
			node[@ eAnimNode.Descendants] = [];
			var ancestor = i;
			var ancestorNode = nodeList[| ancestor];
			while (ancestor > 0)
			{
				ancestor = ancestorNode[eAnimNode.Parent];
				ancestorNode = nodeList[| ancestor];
				descendants = ancestorNode[eAnimNode.Descendants];
				descendants[@ array_length(descendants)] = i;
				if (ancestor == node[eAnimNode.Parent])
				{
					children = ancestorNode[eAnimNode.Children];
					children[@ array_length(children)] = i;
				}
			}
		}
		boneNum = sampleBoneInd;
	}
}

//Compatibility scripts
function rig_delete(rig) 
{
	rig.destroy();
	delete rig;
}
function rig_clear(rig) 
{
	return rig.clear();
}
function rig_get_node_number(rig) 
{
	return rig.get_node_number();
}
function rig_lock_positions(rig, sample)
{
	return rig.lock_positions(sample);
}
function rig_transform(rig, DQ, xScale, yScale, zScale) 
{
	return rig.transform(DQ, xScale, yScale, zScale);
}
function _anim_rig_update_node(rig, nodeInd) 
{
	return rig.update_node(nodeInd);
}
function rig_add_node(rig, pos, parent, isBone)
{
	return rig.node_create(pos, parent, isBone);
}
function rig_insert_node(rig, nodeInd)
{
	return rig.node_insert(nodeInd);
}
function rig_delete_node(rig, nodeInd) 
{
	return rig.node_delete(nodeInd);
}
function rig_move_node(rig, nodeInd, px, py, pz)
{
	return rig.node_move(nodeInd, px, py, pz);
}
function rig_rotate_node(rig, nodeInd, radians)
{
	return rig.node_rotate(nodeInd, radians);
}
function rig_node_get_bone(rig, nodeInd)
{
	return rig.node_get_bone(nodeInd);
}
function rig_node_get_dq(rig, nodeInd)
{
	return rig.node_get_dq(nodeInd);
}
function rig_node_set_bone(rig, nodeInd, enable) 
{
	return rig.node_set_bone(nodeInd, enable);
}
function rig_node_get_locked(rig, nodeInd)
{
	return rig.node_get_locked(nodeInd);
}
function rig_node_set_locked(rig, nodeInd, enable) 
{
	return rig.node_set_locked(nodeInd, enable);
}
function _anim_rig_update_bindmap(rig) 
{
	return rig.update_bindmap();
}
function rig_node_set_parent(rig, nodeInd, parent) 
{
	return rig.node_set_parent(nodeInd, parent);
}
function rig_write_to_buffer(saveBuff, rig) 
{
	//Write header
	buffer_write(saveBuff, buffer_string, "Rig");

	var nodeList = rig.nodeList;
	if (nodeList < 0)
	{
		buffer_write(saveBuff, buffer_u16, 0);
		exit;
	}
	var nodeNum = ds_list_size(nodeList);
	//Write rig
	buffer_write(saveBuff, buffer_u16, nodeNum);
	for (var i = 0; i < nodeNum; i ++)
	{
		var node = nodeList[| i];
	
		//Write node properties
		buffer_write(saveBuff, buffer_string, node[eAnimNode.Name]);
		buffer_write(saveBuff, buffer_bool, node[eAnimNode.IsBone]);
		buffer_write(saveBuff, buffer_u16, node[eAnimNode.Parent]);
		buffer_write(saveBuff, buffer_u8, node[eAnimNode.Locked]);
		var pAxis = node[eAnimNode.PrimaryAxis];
		buffer_write(saveBuff, buffer_f32, pAxis[0]);
		buffer_write(saveBuff, buffer_f32, pAxis[1]);
		buffer_write(saveBuff, buffer_f32, pAxis[2]);
	
		//Write node world orientation
		var worldDQ = node[eAnimNode.WorldDQ];
		for (var j = 0; j < 8; j ++)
		{
			buffer_write(saveBuff, buffer_f32, worldDQ[j]);
		}
	}
}
function rig_read_from_buffer(loadBuff) 
{
	var rig = new smf_rig();
	var nodeList = rig.nodeList;

	//Read header
	var header = buffer_read(loadBuff, buffer_string);
	if (header != "Rig")
	{
		show_debug_message("Error in script anim_rig_read_from_buffer: Trying to read from a section that does not contain a rig.");
		exit;
	}

	//Read rig	
	var nodeNum = buffer_read(loadBuff, buffer_u16);
	for (var i = 0; i < nodeNum; i ++)
	{
		var node = array_create(eAnimNode.Num, 0);
		nodeList[| i] = node;
	
		//Read node properties
		node[@ eAnimNode.Name] = buffer_read(loadBuff, buffer_string);
		node[@ eAnimNode.IsBone] = buffer_read(loadBuff, buffer_bool);
		node[@ eAnimNode.Parent] = buffer_read(loadBuff, buffer_u16);
		node[@ eAnimNode.Locked] = buffer_read(loadBuff, buffer_u8);
		var pAxisX = buffer_read(loadBuff, buffer_f32);
		var pAxisY = buffer_read(loadBuff, buffer_f32);
		var pAxisZ = buffer_read(loadBuff, buffer_f32);
	
		//Read node world orientation
		var worldDQ = array_create(8);
		for (var j = 0; j < 8; j ++)
		{
			worldDQ[j] = buffer_read(loadBuff, buffer_f32);
		}
		node[@ eAnimNode.WorldDQ] = worldDQ;
	
		//Add node to node list
		_anim_rig_update_node(rig, i);
		node[@ eAnimNode.PrimaryAxis] = [pAxisX, pAxisY, pAxisZ];
	}
	_anim_rig_update_bindmap(rig);
	return rig;
}