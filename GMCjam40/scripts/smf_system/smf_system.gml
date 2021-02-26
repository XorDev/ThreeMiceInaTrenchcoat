/// @description smf_model_create()
global.SMFtempSample = array_create(128);
global.animTempV = array_create(3);
global.AnimTempQ1 = array_create(8);
global.AnimTempQ2 = array_create(8);
global.AnimTempQ3 = array_create(8);
global.AnimTempQ4 = array_create(8);
global.AnimTempM = array_create(16);
global.AnimUniMap = ds_map_create();
global.AnimTempWorldDQ = [];
	
enum eAnimInterpolation{
	Keyframe, Linear, Quadratic}
		
enum eAnimNode{
	Name, WorldDQ, LocalDQ, WorldDQConjugate, LocalDQConjugate, Parent, Children, Descendants, IsBone, Length, PrimaryAxis, Locked, LockedPos, Num}

function smf_model() constructor
{
	//Create SMF model container
	mBuff = [];
	vBuff = [];
	vis = [];
	texPack = [];
	rig = new smf_rig();
	subRigs = [];
	subRigIndex = [];
	partitioned = false;
	compatibility = false;
	animMap = -1;
	animations = [];
	sampleStrips = [];
	
	/// @func destroy(deleteTextures)
	static destroy = function(deleteTextures) 
	{
		//Destroy model
		mbuff_delete(mBuff);
		vbuff_delete(vBuff);
	
		//Destroy rig
		rig.destroy();
	
		//Destroy animations
		var num = array_length(animations);
		if (num > 0)
		{
			ds_map_destroy(animMap);
		}
		for (var i = 0; i < num; i ++)
		{
			anim_delete(animations[i]);
		}
	
		//Destroy textures
		if (deleteTextures)
		{
			var num = array_length(texPack);
			for (var i = 0; i < num; i ++)
			{
				if sprite_exists(texPack[i])
				{
					sprite_delete(texPack[i]);
				}
			}
		}
	}
	
	/// @func submit([sample])
	static submit = function() 
	{	//Draw an SMF model. You must have set a compatible shader before drawing.
		var num = array_length(vBuff);
		if (num <= 0){exit;}
		var shader = shader_current();
		if (argument_count == 0 || shader < 0)
		{
			vbuff_draw(vBuff, texPack);
		}
		else
		{
			var sample = argument[0];
			var subRigNum = array_length(subRigs);
			var t = array_length(texPack);
			var prevR = -1;
			for (var i = 0; i < num; i ++)
			{
				if (subRigNum <= 1)
				{
					sample_set_uniform(shader, sample);
				}
				else
				{
					var r = subRigIndex[i];
					if (r != prevR)
					{
						//Subdivide the given sample
						var subRig = subRigs[r];
						var bNum = array_length(subRig);
						for (var b = 0; b < bNum; b ++)
						{
							array_copy(global.SMFtempSample, b * 8, sample, subRig[b] * 8, 8);
						}
						sample_set_uniform(shader, global.SMFtempSample);
						prevR = r;
					}
				}
				var tex = -1;
				if (t > 0)
				{
					var spr = texPack[i mod t];
					tex = (spr >= 0) ? sprite_get_texture(spr, 0) : -1;
				}
				vertex_submit(vBuff[i], pr_trianglelist, tex);
			}
		}
	}
	
	/// @func enable_compatibility(bonesPerPart, extraBones)
	static enable_compatibility = function(bonesPerPart, extraBones) 
	{	/*	This script will switch from the regular SMF format to a standard format containing the following:
				3D position
				3D normal
				Texture UVs
				Colour (in which both the bones and bone weights are baked)
			The format allows for a maximum of 16 bones per submitted model, so the model will
			also be split up into smaller segments containing 16 bones or less.
			Submitting multiple sample parts is a bit more taxing on the CPU, but the simple format and the
			limited number of bones makes this more likely to run on weaker devices.
	
			bonesPerPartition can be between 1 and 16. This is the number of bones in the core partition. 
			extraBones is the number of additional, neighbouring bones that will also be included in the partition.
			The sum of bonesPerPartition and extraBones cannot exceed 16, as this is a hard limit set by the 
			vertex format.*/
		bonesPerPart = clamp(bonesPerPart, 1, 16);
		extraBones = clamp(extraBones, 0, 16 - bonesPerPart);
		if Compatibility{
			show_debug_message("Error: Cannot modify compatibility model");
			exit;}

		//Partition the rig
		partition_rig(bonesPerPart, extraBones);
		Compatibility = true;

		//Convert to compatibility format
		var num = array_length(mBuff);
		var scale = mBuffStdBytesPerVert / mBuffBytesPerVert;
		for (var m = 0; m < num; m ++)
		{
			var buff = mBuff[m];
			var buffSize = buffer_get_size(buff);
			var newBuff = buffer_create(round(buffSize * scale), buffer_fixed, 1);
			for (var i = 0; i < buffSize; i += mBuffBytesPerVert)
			{
				//Copy position, normal and UVs
				buffer_copy(buff, i, 8 * 4, newBuff, round(i * scale)); 
				//Cram four bones and four weights into a single colour
				buffer_seek(buff, buffer_seek_start, i + 9 * 4);
				var b1 = buffer_read(buff, buffer_u8);
				var b2 = buffer_read(buff, buffer_u8);
				var b3 = buffer_read(buff, buffer_u8);
				var b4 = buffer_read(buff, buffer_u8);
				var w1 = round(buffer_read(buff, buffer_u8) * 15 / 255);
				var w2 = round(buffer_read(buff, buffer_u8) * 15 / 255);
				var w3 = round(buffer_read(buff, buffer_u8) * 15 / 255);
				var w4 = round(buffer_read(buff, buffer_u8) * 15 / 255);
				buffer_seek(newBuff, buffer_seek_start, round(i * scale + 8 * 4));
				buffer_write(newBuff, buffer_u8, round(b1 + 16 * w1));
				buffer_write(newBuff, buffer_u8, round(b2 + 16 * w2));
				buffer_write(newBuff, buffer_u8, round(b3 + 16 * w3));
				buffer_write(newBuff, buffer_u8, round(b4 + 16 * w4));
			}
			buffer_delete(buff);
			vertex_delete_buffer(vBuff[m]);
			mBuff[@ m] = newBuff;
			vBuff[@ m] = vertex_create_buffer_from_buffer(mBuff[m], global.mBuffStdFormat);
			vertex_freeze(vBuff[m]);
		}
	}
	
	/// @func get_animation(name)
	static get_animation = function(name) 
	{	/*	Search through the model's animations to find the animation with the given name.
			Returns the index of the new animation, or -1 if the animation does not exist.*/
		var animInd = animMap[? name];
		if is_undefined(animInd){return undefined;}
		return animations[animInd];
	}
	
	/// @func partition_rig(bonesPerPart, extraBones)
	static partition_rig = function(bonesPerPart, extraBones) 
	{	/*	Subdivides the given SMF model into smaller partitions depending on the rig structure.
			This is useful for allowing complex rigs while also limiting the number of uniforms
			that need to get passed to the GPU.
	
			You can specify the number of bones per partition. 
			You can also specify the number of extra bones to add to each partition in order to prevent tearing*/
		if (Compatibility){
			show_debug_message("Error: Cannot modify compatibility model");
			exit;}
		if (partitioned){
			show_debug_message("Error in script partition_rig: Model has already been partitioned");
			exit;}
		var nodeList = rig.nodeList;
		var bindMap = rig.bindMap;
		var nodeNum = ds_list_size(nodeList);
		var boneNum = rig.boneNum;
		var batchInd = 0;
		var batchNum = ceil(boneNum / bonesPerPart);
		var batchSize = array_create(batchNum);
		var batchMap = array_create(boneNum);
		var subRigPri = [];
		if (batchNum <= 1){return -1;}

		//Split up the rig first
		for (var i = 0; i < nodeNum; i ++)
		{
			var node = nodeList[| i];
			var children = node[eAnimNode.Children];
			var childNum = array_length(children);
			for (var j = 0; j < childNum; j ++)
			{
				var child = children[j];
				var bone = bindMap[| child];
				if (bone < 0){continue;}
				if (batchSize[batchInd] == 0)
				{
					subRigPri[batchInd] = ds_priority_create();
				}
				batchMap[bone] = batchInd;
				batchSize[batchInd] ++;
				if (batchSize[batchInd] >= bonesPerPart)
				{
					batchInd ++;
					batchSize[batchInd] = 0;
				}
			}
		}

		//Figure out which bones to add to which sub rig
		var newMbuff = [];
		var mBuffNum = array_length(mBuff);
		var bytesPerVert = mBuffBytesPerVert;
		var b1 = array_create(3);
		var b2 = array_create(3);
		var b3 = array_create(3);
		var b4 = array_create(3);
		var w1 = array_create(3);
		var w2 = array_create(3);
		var w3 = array_create(3);
		var w4 = array_create(3);
		for (var i = 0; i < mBuffNum; i ++)
		{
			var buff = mBuff[i];
			var buffSize = buffer_get_size(buff);
			for (var j = 0; j < buffSize; j += bytesPerVert)
			{
				for (var k = 0; k < 3; k ++)
				{
					buffer_seek(buff, buffer_seek_start, j + bytesPerVert - 8);
					b1[k] = buffer_read(buff, buffer_u8);
					b2[k] = buffer_read(buff, buffer_u8);
					b3[k] = buffer_read(buff, buffer_u8);
					b4[k] = buffer_read(buff, buffer_u8);
					w1[k] = buffer_read(buff, buffer_u8);
					w2[k] = buffer_read(buff, buffer_u8);
					w3[k] = buffer_read(buff, buffer_u8);
					w4[k] = buffer_read(buff, buffer_u8);
				}
				var batchInd = batchMap[b1[0]]; //Find the batch map of the bone with the highest influence
				var pri = subRigPri[batchInd];
		
				for (var k = 0; k < 3; k ++)
				{
					//Add first bone to priority
					var p = ds_priority_find_priority(pri, b1[k]);
					if is_undefined(p){
						ds_priority_add(pri, b1[k], w1[k]);}
					else if (p < w1[k]){
						ds_priority_change_priority(pri, b1[k], w1[k]);}
		
					//Add second bone to priority
					var p = ds_priority_find_priority(pri, b2[k]);
					if is_undefined(p){
						ds_priority_add(pri, b2[k], w2[k]);}
					else if (p < w2[k]){
						ds_priority_change_priority(pri, b2[k], w2[k]);}
		
					//Add third bone to priority
					var p = ds_priority_find_priority(pri, b3[k]);
					if is_undefined(p){
						ds_priority_add(pri, b3[k], w3[k]);}
					else if (p < w3[k]){
						ds_priority_change_priority(pri, b3[k], w3[k]);}
		
					//Add fourth bone to priority
					var p = ds_priority_find_priority(pri, b4[k]);
					if is_undefined(p){
						ds_priority_add(pri, b4[k], w4[k]);}
					else if (p < w4[k]){
						ds_priority_change_priority(pri, b4[k], w4[k]);}
				}
			}
		}

		//Trim the sub rigs
		subRigs = array_create(batchNum);
		for (var i = 0; i < batchNum; i ++)
		{
			var pri = subRigPri[i];
			var num = min(bonesPerPart + extraBones, ds_priority_size(pri));
			var subRig = array_create(num);
			for (var j = 0; j < num; j ++)
			{
				subRig[j] = ds_priority_delete_max(pri);
			}
			subRigs[@ i] = subRig;
			ds_priority_destroy(pri);
		}

		//Then split up the model buffer to smaller batches
		var totalBatches = 0;
		var bytesPerTri = bytesPerVert * 3;
		var batches = array_create(mBuffNum);
		for (var i = 0; i < mBuffNum; i ++)
		{
			batches[i] = array_create(batchNum, -1);
			var batch = batches[i];
			var buff = mBuff[i];
			var buffSize = buffer_get_size(buff);
			for (var j = 0; j < buffSize; j += bytesPerTri)
			{
				buffer_seek(buff, buffer_seek_start, j + bytesPerVert - 8);
				var b1 = buffer_read(buff, buffer_u8);
				var batchInd = batchMap[b1];
				if batch[batchInd] < 0
				{
					batch[@ batchInd] = buffer_create(1, buffer_grow, 1);
					totalBatches ++;
				}
		
				//Copy the triangle from the source to the new batch
				var buffPos = (buffer_tell(batch[batchInd]) div bytesPerTri) * bytesPerTri;
				buffer_copy(buff, j, bytesPerTri, batch[batchInd], buffPos);
		
				//Modify the bone indices to match the new bone map
				var subRig = subRigs[batchInd];
				var newBuff = batch[batchInd];
				var prevB1 = 0;
				for (var k = 0; k < 3; k ++)
				{
					//Read the old bone values
					buffer_seek(newBuff, buffer_seek_start, buffPos + k * bytesPerVert + bytesPerVert - 8); //Seek the position of the bone indices
					var b1 = _smf_get_array_index(subRig, buffer_read(newBuff, buffer_u8));
					var b2 = _smf_get_array_index(subRig, buffer_read(newBuff, buffer_u8));
					var b3 = _smf_get_array_index(subRig, buffer_read(newBuff, buffer_u8));
					var b4 = _smf_get_array_index(subRig, buffer_read(newBuff, buffer_u8));
					var w1 = buffer_read(newBuff, buffer_u8);
					var w2 = buffer_read(newBuff, buffer_u8) * (b2 >= 0);
					var w3 = buffer_read(newBuff, buffer_u8) * (b3 >= 0);
					var w4 = buffer_read(newBuff, buffer_u8) * (b4 >= 0);
					var sum = (w1 + w2 + w3 + w4) / 255;
					if (sum == 0){sum = 1;}
					//Write the new bone values
					buffer_seek(newBuff, buffer_seek_start, buffPos + k * bytesPerVert + bytesPerVert - 8); //Seek the position of the bone indices
					buffer_write(newBuff, buffer_u8, (b1 < 0) ? prevB1 : b1);
					buffer_write(newBuff, buffer_u8, (b2 < 0) ? 0 : b2);
					buffer_write(newBuff, buffer_u8, (b3 < 0) ? 0 : b3);
					buffer_write(newBuff, buffer_u8, (b4 < 0) ? 0 : b4);
					buffer_write(newBuff, buffer_u8, w1 / sum);
					buffer_write(newBuff, buffer_u8, w2 / sum);
					buffer_write(newBuff, buffer_u8, w3 / sum);
					buffer_write(newBuff, buffer_u8, w4 / sum);
					if (b1 >= 0){prevB1 = b1;}
				}
				buffer_seek(newBuff, buffer_seek_start, buffPos + bytesPerTri);
			}
		}

		//Now reassemble the new mbuff array
		var texNum = min(array_length(texPack), mBuffNum);
		var newMbuff = array_create(totalBatches);
		var newVbuff = array_create(totalBatches);
		var newTexpack = array_create(totalBatches);
		var newVis = array_create(totalBatches);
		var mbuffInd = 0;
		for (var i = 0; i < mBuffNum; i ++)
		{
			var tex = texPack[i mod texNum];
			var batch = batches[i];
			for (var j = 0; j < batchNum; j ++)
			{
				if (batch[j] >= 0)
				{
					var size = buffer_tell(batch[j]);
					newMbuff[mbuffInd] = buffer_create(size, buffer_fixed, 1);
					newTexpack[mbuffInd] = tex;
					newVis[mbuffInd] = vis[i];
					buffer_copy(batch[j], 0, size, newMbuff[mbuffInd], 0);
					buffer_delete(batch[j]);
					subRigInd[@ mbuffInd] = j;
					mbuffInd++;
				}
			}
	
			//Delete the old mbuff
			buffer_delete(mBuff[i]);
			vertex_delete_buffer(vBuff[i]);
		}
		mBuff = newMbuff;
		vBuff = vbuff_create_from_mbuff(newMbuff);
		texPack = newTexpack;
		vis = newVis;
		partitioned = true;
	}
}

function smf_model_load(path) 
{
	if !file_exists(path){return -1;}
	var ext = string_lower(filename_ext(path));
	if (ext == ".obj")
	{
		return smf_model_load_obj(path);
	}
	if (ext == ".smf")
	{
		var loadBuff = buffer_load(path); 

		//Check if the buffer has been compressed. If it has, decompress it
		var decompressedBuff = buffer_decompress(loadBuff);
		if (decompressedBuff >= 0)
		{
			buffer_delete(loadBuff);
			loadBuff = decompressedBuff;
		}
		var model = smf_model_load_from_buffer(loadBuff, path);
		buffer_delete(loadBuff);

		return model;
	}
	show_debug_message("smf_model_load could not load file " + string(path));
	return -1;
}

function smf_model_get_animation(model, name) 
{
	return model.get_animation(name);
}

function smf_model_load_from_buffer() 
{
	var HeaderText, loadBuff, size, n, versionNum;
	loadBuff = argument[0];
	var path = "";
	if (argument_count > 1){path = argument[1];}
	buffer_seek(loadBuff, buffer_seek_start, 0);
	HeaderText = buffer_read(loadBuff, buffer_string);
	versionNum = 0;
	if HeaderText != "SnidrsModelFormat"
	{
		show_debug_message("The given buffer does not contain a valid SMF model");
		return -1;
	}
	versionNum = buffer_read(loadBuff, buffer_f32);

	var partitioned = false;
	var compatibility = false;

	//This importer supports versions 6, 7 and 8
	if (versionNum > 8)
	{
		show_error("This was made with a newer version of SMF.", false);
		return -1;
	}
	else if (versionNum == 8)
	{
		partitioned = true;
		compatibility = buffer_read(loadBuff, buffer_bool);
	}
	else if (versionNum < 6)
	{
		show_error("This was made with an unsupported version of SMF.", false);
		return -1;
	}

	//Create SMF model container
	var model = new smf_model();

	//Load buffer positions
	var texPos = buffer_read(loadBuff, buffer_u32);
	var matPos = buffer_read(loadBuff, buffer_u32);
	var modPos = buffer_read(loadBuff, buffer_u32);
	var nodPos = buffer_read(loadBuff, buffer_u32);
	var colPos = buffer_read(loadBuff, buffer_u32);
	var rigPos = buffer_read(loadBuff, buffer_u32);
	var aniPos = buffer_read(loadBuff, buffer_u32);
	var selPos = buffer_read(loadBuff, buffer_u32);
	var subPos = buffer_read(loadBuff, buffer_u32);
	buffer_read(loadBuff, buffer_u32); //Placeholder

	//Version 6 "compiled"
	if (versionNum == 6)
	{
		if buffer_read(loadBuff, buffer_u8) //If compiled
		{
			show_error("This was made with an unsupported version of SMF.", false);
			return -1;
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Load number of models
	var modelNum = buffer_read(loadBuff, buffer_u8);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Load textures
	var texMap = ds_map_create();
	buffer_seek(loadBuff, buffer_seek_start, texPos);
	var n = buffer_read(loadBuff, buffer_u8);
	if (n > 0)
	{
		var s = surface_create(8, 8);
		surface_set_target(s);
		draw_clear(c_white);
		surface_reset_target();
		var blankSprite = sprite_create_from_surface(s, 0, 0, 8, 8, 0, 0, 0, 0);
		var texBuff = buffer_create(1, buffer_fast, 1);
		for (var t = 0; t < n; t ++)
		{
			var name = buffer_read(loadBuff, buffer_string);
			var w = buffer_read(loadBuff, buffer_u16);
			var h = buffer_read(loadBuff, buffer_u16);
			var spr = asset_get_index(filename_change_ext(filename_name(path), "_" + string(name)));
			if (sprite_exists(spr)) //Check if the texture is already in the game files
			{
				texMap[? name] = spr;
			}
			else if (w > 0 and h > 0)
			{
				surface_resize(s, w, h);
				buffer_resize(texBuff, w * h * 4)
				buffer_copy(loadBuff, buffer_tell(loadBuff), w * h * 4, texBuff, 0);
				buffer_set_surface(texBuff, s, 0);
				texMap[? name] = sprite_create_from_surface(s, 0, 0, w, h, 0, 0, 0, 0);
			}
			else if is_undefined(texMap[? name])
			{
				texMap[? name] = sprite_duplicate(blankSprite);
			}
			buffer_seek(loadBuff, buffer_seek_relative, w * h * 4);
		}
		sprite_delete(blankSprite);
		surface_free(s);
		buffer_delete(texBuff);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////
	//Load models
	buffer_seek(loadBuff, buffer_seek_start, modPos);
	model.mBuff = array_create(modelNum);
	model.vBuff = array_create(modelNum);
	model.texPack = array_create(modelNum);
	model.vis = array_create(modelNum);
	model.subRigIndex = array_create(modelNum);
	for (var m = 0; m < modelNum; m ++)
	{
		//Read vertex buffers
		var size = buffer_read(loadBuff, buffer_u32);
		var mBuff = buffer_create(size, buffer_fixed, 1);
		buffer_copy(loadBuff, buffer_tell(loadBuff), size, mBuff, 0);
		var vBuff = vertex_create_buffer_from_buffer(mBuff, compatibility ? global.mBuffStdFormat : global.mBuffFormat);
		vertex_freeze(vBuff);
		model.mBuff[m] = mBuff;
		model.vBuff[m] = vBuff;
		model.subRigIndex[m] = 0;
	
		buffer_seek(loadBuff, buffer_seek_relative, size);
	
		var matName = buffer_read(loadBuff, buffer_string);
		var texName = buffer_read(loadBuff, buffer_string);
		var texInd = texMap[? texName];
		model.texPack[m] = is_undefined(texInd) ? -1 : texInd;
		model.vis[m] = buffer_read(loadBuff, buffer_u8);
		
		//Ignore skinning info
		var n = buffer_read(loadBuff, buffer_u32);
		repeat n{buffer_seek(loadBuff, buffer_seek_relative, buffer_read(loadBuff, buffer_u8) * 4);}
		var n = buffer_read(loadBuff, buffer_u32);
		buffer_seek(loadBuff, buffer_seek_relative, n * 4);
	
		//Read partition index
		if partitioned
		{
			model.subRigIndex[m] = buffer_read(loadBuff, buffer_u8);
		}
	}
	ds_map_destroy(texMap);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Load rig
	buffer_seek(loadBuff, buffer_seek_start, rigPos);
	var nodeNum, i, j, nodeList, node, worldDQ;
	nodeNum = buffer_read(loadBuff, buffer_u8);
	if (nodeNum > 0)
	{
		model.rig = new smf_rig();
		nodeList = model.rig.nodeList;
		for (i = 0; i < nodeNum; i ++)
		{
			node = array_create(eAnimNode.Num, 0);
			worldDQ = array_create(8);
			for (j = 0; j < 8; j ++)
			{
				worldDQ[j] = buffer_read(loadBuff, buffer_f32);
			}
			node[@ eAnimNode.WorldDQ] = worldDQ;
			node[@ eAnimNode.Parent] = buffer_read(loadBuff, buffer_u8);
			node[@ eAnimNode.IsBone] = buffer_read(loadBuff, buffer_u8);
			node[@ eAnimNode.PrimaryAxis] = [0, 0, 1];
	
			//Add node to node list
			nodeList[| i] = node;
			_anim_rig_update_node(model.rig, i);
		}
		_anim_rig_update_bindmap(model.rig);
	}
	if (buffer_read(loadBuff, buffer_u8) == 232) //An extension to the rig format
	{
		var bytesPerNode = buffer_read(loadBuff, buffer_u8);
		var buffPos = buffer_tell(loadBuff);
		for (var i = 0; i < nodeNum; i ++)
		{
			node = nodeList[| i];
			node[@ eAnimNode.Locked] = buffer_peek(loadBuff, buffPos + bytesPerNode * i, buffer_u8);
			if (bytesPerNode >= 13)
			{
				var pAxis = array_create(3);
				pAxis[0] = buffer_peek(loadBuff, buffPos + bytesPerNode * i + 1, buffer_f32);
				pAxis[1] = buffer_peek(loadBuff, buffPos + bytesPerNode * i + 5, buffer_f32);
				pAxis[2] = buffer_peek(loadBuff, buffPos + bytesPerNode * i + 9, buffer_f32);
				node[@ eAnimNode.PrimaryAxis] = pAxis;
			}
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Load rig partitions
	if (partitioned)
	{
		buffer_seek(loadBuff, buffer_seek_start, subPos);
		var num = buffer_read(loadBuff, buffer_u8);
		model.subRigs = array_create(num);
		for (var i = 0; i < num; i ++)
		{
			var boneNum = buffer_read(loadBuff, buffer_u8);
			var subRig = array_create(boneNum);
			for (var j = 0; j < boneNum; j ++)
			{
				subRig[j] = buffer_read(loadBuff, buffer_u8);
			}
			model.subRigs[i] = subRig;
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Load animation
	buffer_seek(loadBuff, buffer_seek_start, aniPos);
	var animNum, animName, anim, keyframeNum, keyframeGrid, keyframeTime, keyframeInd, deltaDQ, keyframe, a, f, i, l, localDQ;
	localDQ = array_create(8);
	animNum = buffer_read(loadBuff, buffer_u8);
	if (animNum > 0)
	{
		model.animMap = ds_map_create();
		model.animations = array_create(animNum);
		for (a = 0; a < animNum; a ++)
		{
			animName = buffer_read(loadBuff, buffer_string);
			anim = new smf_anim(animName);
			keyframeNum = buffer_read(loadBuff, buffer_u8);
			keyframeGrid = anim.keyframeGrid;
			anim.loop = true;
			anim.nodeNum = nodeNum;
			anim.interpolation = eAnimInterpolation.Quadratic;
			for (f = 0; f < keyframeNum; f ++)
			{
				keyframeTime = buffer_read(loadBuff, buffer_f32);
				keyframeInd = anim_add_keyframe(anim, keyframeTime);
				keyframe = keyframeGrid[# 1, keyframeInd];
				for (i = 0; i < nodeNum; i ++)
				{
					for (l = 0; l < 8; l ++)
					{
						//Read delta local dual quaternion of the keyframe node
						localDQ[l] = buffer_read(loadBuff, buffer_f32);
					}
					node = nodeList[| i];
					deltaDQ = keyframe[i];
					smf_dq_multiply(node[eAnimNode.LocalDQConjugate], localDQ, deltaDQ);
					if (node[eAnimNode.IsBone])
					{
						deltaDQ[@ 4] = 0;
						deltaDQ[@ 5] = deltaDQ[2] * node[eAnimNode.Length];
						deltaDQ[@ 6] = -deltaDQ[1] * node[eAnimNode.Length];
						deltaDQ[@ 7] = 0;
					}
				}
			}
			model.animMap[? animName] = a;
			model.animations[a] = anim;
		}
	}
	//Load additional animation info (only used in v8)
	if (buffer_read(loadBuff, buffer_u8) == 239)
	{
		for (a = 0; a < animNum; a ++)
		{
			anim = model.animations[a];
			anim.playTime = buffer_read(loadBuff, buffer_f32);
			anim.sampleFrameMultiplier = buffer_read(loadBuff, buffer_u8);
			anim.loop = buffer_read(loadBuff, buffer_bool);
		}
	}
	//Generate sample strips for each animation
	for (a = 0; a < animNum; a ++)
	{
		anim = model.animations[a];
		array_set(model.sampleStrips, a, new smf_samplestrip(model.rig, anim));
	}

	return model;
}
function smf_model_load_obj(path) 
{
	if (!file_exists(path)){return -1;}
	var model = new smf_model();
	var obj = mbuff_load_obj_ext(path, true);
	if (!is_array(obj)){return -1;}
	model.mBuff = obj[0];
	model.texPack = obj[1];
	model.vBuff = vbuff_create_from_mbuff(obj[0]);
	return model;
}

/// @func smf_model_submit(model, [sample]
function smf_model_submit() 
{
	var model = argument[0];
	if (argument_count == 1)
	{
		model.submit();
	}
	else
	{
		model.submit(argument[1]);
	}
}
function smf_model_destroy(model, deleteTextures) 
{
	model.destroy(deleteTextures);
	delete model;
}
function smf_model_enable_compatibility(model, bonesPerPart, extraBones)
{
	model.enable_compatibility(bonesPerPart, extraBones);
}
function smf_model_partition_rig(model, bonesPerPart, extraBones)
{
	model.partition_rig(bonesPerPart, extraBones);
}
function smf_model_save(model, path, incTex) 
{
	var mBuff = model.mBuff;
	var texPack = model.texPack;
	var vis = model.vis;
	var rig = model.rig;
	var animArray = model.animations;
	var partitioned = model.partitioned;
	var subRigIndex = model.subRigIndex;
	var subRigs = model.subRigs;
	var modelNum = array_length(mBuff);

	////////////////////////////////////////////////////////////////////
	//Create buffer and write header
	var saveBuff = buffer_create(100, buffer_grow, 1);
	buffer_write(saveBuff, buffer_string, "SnidrsModelFormat");
	if partitioned
	{
		buffer_write(saveBuff, buffer_f32, 8); //Version number
		buffer_write(saveBuff, buffer_bool, model.Compatibility); //Compatibility
	}
	else
	{
		buffer_write(saveBuff, buffer_f32, 7); //Version number
	}

	var header = buffer_tell(saveBuff);
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the textures
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the materials
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the models
	buffer_write(saveBuff, buffer_u32, 0); //OLD nodes
	buffer_write(saveBuff, buffer_u32, 0); //OLD collision buffer
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the rig
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the animation
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the saved selections
	buffer_write(saveBuff, buffer_u32, 0); //Buffer position of the partitions
	buffer_write(saveBuff, buffer_u32, 0); //Placeholder
	buffer_write(saveBuff, buffer_u8, modelNum);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Write textures
	gpu_set_zwriteenable(false);
	gpu_set_ztestenable(false);
	gpu_set_cullmode(cull_noculling);
	var texPos = buffer_tell(saveBuff);
	buffer_poke(saveBuff, header, buffer_u32, texPos);
	buffer_write(saveBuff, buffer_u8, 0); //Number of textures, this will be overwritten later
	//Write the used textures
	var writtenTexMap = ds_map_create();
	var n = array_length(mBuff);
	gpu_set_blendmode_ext(bm_one, bm_zero);
	var s = surface_create(1, 1);
	var texBuff = buffer_create(1, buffer_fast, 1);
	for (var t = 0; t < modelNum; t ++)
	{
		var tex = texPack[t];
		if !is_undefined(writtenTexMap[? tex]){continue;}
		writtenTexMap[? tex] = true;
		buffer_write(saveBuff, buffer_string, string(tex));
		if incTex
		{
			var w = sprite_get_width(tex);
			var h = sprite_get_height(tex);
			surface_resize(s, w, h);
			surface_set_target(s);
			draw_clear_alpha(c_white, 0);
			draw_sprite_ext(tex, 0, 0, h, 1, -1, 0, c_white, 1);
			surface_reset_target();
			buffer_resize(texBuff, w * h * 4);
			buffer_get_surface(texBuff, s, 0);
		
			buffer_write(saveBuff, buffer_u16, w);
			buffer_write(saveBuff, buffer_u16, h);
			buffer_copy(texBuff, 0, w * h * 4, saveBuff, buffer_tell(saveBuff));
			buffer_seek(saveBuff, buffer_seek_relative, w * h * 4);
		}
		else
		{
			buffer_write(saveBuff, buffer_u16, 0);
			buffer_write(saveBuff, buffer_u16, 0);
		}
	}
	surface_free(s);
	buffer_poke(saveBuff, texPos, buffer_u8, ds_map_size(writtenTexMap));
	gpu_set_blendmode(bm_normal);
	ds_map_destroy(writtenTexMap);
	buffer_delete(texBuff);

	if !incTex
	{
		//Save textures
		buffer_write(saveBuff, buffer_u8, 99);
		var texNum = min(array_length(texPack), array_length(mBuff));
		for (var i = 0; i < texNum; i ++)
		{
			sprite_save(texPack[i], 0, filename_change_ext(path, "_" + string(texPack[i]) + ".png"));
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Write materials
	buffer_poke(saveBuff, header + 4, buffer_u32, buffer_tell(saveBuff));
	//Count the number of used materials
	buffer_write(saveBuff, buffer_u8, 1);

	//Material settings
	buffer_write(saveBuff, buffer_string, "Default");
	buffer_write(saveBuff, buffer_u8, 1);
		
	//Effect modifyers
	buffer_write(saveBuff, buffer_u8, 0.2 * 127);
	buffer_write(saveBuff, buffer_u8, 4);
	buffer_write(saveBuff, buffer_u8, 0);
	buffer_write(saveBuff, buffer_u8, 0);
	buffer_write(saveBuff, buffer_u8, 0);

	//Normal map
	buffer_write(saveBuff, buffer_u8, false);
		
	//Outlines
	buffer_write(saveBuff, buffer_u8, false);
		
	//Reflections
	buffer_write(saveBuff, buffer_u8, false);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Write models
	buffer_poke(saveBuff, header + 2 * 4, buffer_u32, buffer_tell(saveBuff));
	for (var m = 0; m < modelNum; m ++)
	{
		var size = buffer_get_size(mBuff[m]);
		buffer_write(saveBuff, buffer_u32, size);
		buffer_copy(mBuff[m], 0, size, saveBuff, buffer_tell(saveBuff));
		buffer_seek(saveBuff, buffer_seek_relative, size);
	
		buffer_write(saveBuff, buffer_string, "Default");
		buffer_write(saveBuff, buffer_string, string(texPack[m]));
		
		//Write whether or not this model is visible
		buffer_write(saveBuff, buffer_u8, vis[m]);
	
		//Don't write skinning info
		buffer_write(saveBuff, buffer_u32, 0);
		buffer_write(saveBuff, buffer_u32, 0);
	
		//Write partition index
		if partitioned
		{
			buffer_write(saveBuff, buffer_u8, subRigIndex[m]);
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Don't write nodes
	buffer_poke(saveBuff, header + 3 * 4, buffer_u32, buffer_tell(saveBuff));
	buffer_write(saveBuff, buffer_u8, 0);
	buffer_write(saveBuff, buffer_u8, 0);
	buffer_write(saveBuff, buffer_u8, 127);
	buffer_write(saveBuff, buffer_u8, 127);
	buffer_write(saveBuff, buffer_u8, 127);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Don't write collision buffer
	buffer_poke(saveBuff, header + 4 * 4, buffer_u32, buffer_tell(saveBuff));
	buffer_write(saveBuff, buffer_u32, 0);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Write rig
	buffer_poke(saveBuff, header + 5 * 4, buffer_u32, buffer_tell(saveBuff));
	var nodeNum, nodeList, node, frameNum, DQ, i, k;
	nodeNum = 0;
	if (is_struct(rig))
	{
		nodeList = rig.nodeList;
		nodeNum = ds_list_size(nodeList);
	}
	buffer_write(saveBuff, buffer_u8, nodeNum);
	//Write node hierarchy
	for (i = 0; i < nodeNum; i ++)
	{
		node = nodeList[| i];
		DQ = node[eAnimNode.WorldDQ];
		for (k = 0; k < 8; k ++)
		{
			buffer_write(saveBuff, buffer_f32, DQ[k]);
		}
		buffer_write(saveBuff, buffer_u8, node[eAnimNode.Parent]);
		buffer_write(saveBuff, buffer_u8, node[eAnimNode.IsBone]);
	}
	//We also want to save some additional node info, but they have to be appended to make the format be backwards compatible
	buffer_write(saveBuff, buffer_u8, 232);
	buffer_write(saveBuff, buffer_u8, 13);
	for (var i = 0; i < nodeNum; i ++)
	{
		node = nodeList[| i];
		buffer_write(saveBuff, buffer_u8, node[eAnimNode.Locked]);
		var pAxis = node[eAnimNode.PrimaryAxis];
		buffer_write(saveBuff, buffer_f32, pAxis[0]);
		buffer_write(saveBuff, buffer_f32, pAxis[1]);
		buffer_write(saveBuff, buffer_f32, pAxis[2]);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Write rig partitions
	if partitioned
	{
		buffer_poke(saveBuff, header + 8 * 4, buffer_u32, buffer_tell(saveBuff));
		var num = array_length(subRigs);
		buffer_write(saveBuff, buffer_u8, num);
		for (var i = 0; i < num; i ++)
		{
			var subRig = subRigs[i];
			var boneNum = array_length(subRig);
			buffer_write(saveBuff, buffer_u8, boneNum);
			for (var j = 0; j < boneNum; j ++)
			{
				buffer_write(saveBuff, buffer_u8, subRig[j]);
			}
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Write animations
	var animInd;
	buffer_poke(saveBuff, header + 6 * 4, buffer_u32, buffer_tell(saveBuff));
	var animationNum = array_length(animArray);
	buffer_write(saveBuff, buffer_u8, animationNum);
	for (var a = 0; a < animationNum; a ++)
	{
		animInd = animArray[a];
		buffer_write(saveBuff, buffer_string, animInd.name);
		var keyframeGrid = animInd.keyframeGrid;
		frameNum = ds_grid_height(keyframeGrid);
		buffer_write(saveBuff, buffer_u8, frameNum);
		for (var f = 0; f < frameNum; f ++)
		{
			var keyframe = keyframeGrid[# 1, f];
			buffer_write(saveBuff, buffer_f32, keyframeGrid[# 0, f]);
			for (var i = 0; i < nodeNum; i ++)
			{
				//Get the change in local orientation from the rig to the frame
				node = nodeList[| i];
				if (i < array_length(keyframe))
				{
					DQ = smf_dq_multiply(node[eAnimNode.LocalDQ], keyframe[i], global.AnimTempQ1);
				}
				else
				{
					DQ = [0, 0, 0, 1, 0, 0, 0, 0];
				}
				for (var k = 0; k < 8; k ++)
				{
					buffer_write(saveBuff, buffer_f32, DQ[k]);
				}
			}
		}
	}
	//We also want to save some animation settings, but they have to be appended to make the format be backwards compatible
	buffer_write(saveBuff, buffer_u8, 239);
	for (var a = 0; a < animationNum; a ++)
	{
		animInd = animArray[a];
		buffer_write(saveBuff, buffer_f32, animInd.playTime);
		buffer_write(saveBuff, buffer_u8, animInd.sampleFrameMultiplier);
		buffer_write(saveBuff, buffer_bool, animInd.loop);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Don't write selections
	buffer_poke(saveBuff, header + 7 * 4, buffer_u32, buffer_tell(saveBuff));
	buffer_write(saveBuff, buffer_u8, 0);

	buffer_save(saveBuff, path);
	buffer_delete(saveBuff);
}