/// @description samplestrip_create(rigInd, animInd)
/// @param rigInd
/// @param animInd
function smf_samplestrip(_rig, _anim) constructor
{	/*	Creates a pre-computed sample strip.

		Allows for linear interpolation between precomputed samples.
		This is much, much faster than generating samples from scratch each step!*/
	rig = _rig;
	anim = _anim;
	steps = anim.keyframeNum * anim.sampleFrameMultiplier;
	strip = array_create(steps + 1);
	
	/// @func create_sample(time)
	static create_sample = function(time)
	{	/*	Linearly interpolates between precomputed samples. Precomputes samples if they don't exist yet.
			This is much, much faster than generating samples from scratch each step!
			This script outputs to a new sample.*/
		return update_sample(time, array_create(rig.boneNum * 8, 0), true);
	}
	
	/// @func update_sample(time, trgSample, interpolate) 
	static update_sample = function(time, trgSample, interpolate) 
	{	//Updates a previously created sample. The previous sample will be overwritten.*/
		//Force time between 0 and 1, inclusive 0 and 1.
		var timeDiv = floor(time);
		if (time != 0 && time == timeDiv){time = 1;}
		else{time -= timeDiv;}
		var timer = min(time, 0.999999) * steps;
		var pos = floor(timer);
		var sample1 = get_sample(pos);
		if (!interpolate)
		{
			array_copy(trgSample, 0, sample1, 0, array_length(sample1));
			return trgSample;
		}
		//Linearly interpolate between the two nearest samples
		var sample2 = get_sample(pos + 1);
		return sample_lerp(sample1, sample2, frac(timer), trgSample);
	}
	
	/// @func get_sample(index) 
	static get_sample = function(index) 
	{
		var sample = strip[index];
		if (!is_array(sample))
		{
			var steps = array_length(strip) - 1;
			var itpl = anim.interpolation;
			var time = index / steps;
			sample = anim_generate_sample(rig, anim, time);
			strip[@ index] = sample;
		
			//Check for locked bones
			var nodeList = rig.nodeList;
			var nodeNum = ds_list_size(nodeList);
			var keyframeArray = -1;
			for (var i = 0; i < nodeNum; i ++)
			{
				var node = nodeList[| i];
				if (!node[eAnimNode.Locked]){continue;}
		
				//This bone is supposed to be locked in place, but the animation interpolation may have moved it. Use inverse kinematics to move it back in place.
				switch itpl
				{
					case eAnimInterpolation.Linear:
						if (!is_array(keyframeArray))
						{
							keyframeArray = anim.keyframe_get_linear(time);
						}
						var posA = anim.keyframe_get_node_position(rig, keyframeArray[0], i);
						var posB = anim.keyframe_get_node_position(rig, keyframeArray[1], i);
						var newX = lerp(posA[0], posB[0], keyframeArray[2]);
						var newY = lerp(posA[1], posB[1], keyframeArray[2]);
						var newZ = lerp(posA[2], posB[2], keyframeArray[2]);
						sample_node_move(rig, i, sample, newX, newY, newZ, true, false);
						break;
			
					case eAnimInterpolation.Quadratic:
						if (!is_array(keyframeArray))
						{
							keyframeArray = anim.keyframe_get_quadratic(time);
						}
						var posA = anim.keyframe_get_node_position(rig, keyframeArray[0], i);
						var posB = anim.keyframe_get_node_position(rig, keyframeArray[1], i);
						var posC = anim.keyframe_get_node_position(rig, keyframeArray[2], i);
						var newX = smf_quadratic_interpolate(posA[0], posB[0], posC[0], keyframeArray[3]);
						var newY = smf_quadratic_interpolate(posA[1], posB[1], posC[1], keyframeArray[3]);
						var newZ = smf_quadratic_interpolate(posA[2], posB[2], posC[2], keyframeArray[3]);
						sample_node_move(rig, i, sample, newX, newY, newZ, true, false);
						break;
				}
			}
		}
		return sample;
	}
	
	/// @func get_nearest_frame(time) 
	static get_nearest_frame = function(time) 
	{	/*	Returns the sample in the given animation's sample strip that is closest to the given time.
			No real-time interpolation will be performed, so this takes practically no toll on the CPU.
	
			////IMPORTANT////
			You should NOT edit this sample, as that will also edit the samplestrip!!
			////IMPORTANT////*/
		var timer = min(time, 0.999999) * steps;
		return get_sample(round(timer));
	}
}

//Compatibility scripts
function samplestrip_create(rig, anim)
{
	return new smf_samplestrip(rig, anim);
}
function samplestrip_create_sample(sampleStrip, time) 
{
	return sampleStrip.create_sample(time);
}
function samplestrip_update_sample(sampleStrip, time, trgSample, interpolate) 
{
	return sampleStrip.update_sample(time, trgSample, interpolate);
}
function samplestrip_get_sample(sampleStrip, index) 
{
	return sampleStrip.get_sample(index);
}
function samplestrip_get_anim(sampleStrip) 
{
	return sampleStrip.anim;
}
function samplestrip_get_frame(sampleStrip, time) 
{
	return sampleStrip.get_nearest_frame(time);
}
function samplestrip_get_rig(sampleStrip) 
{
	return sampleStrip.rig;
}
function samplestrip_write_to_buffer(saveBuff, sampleStrip) 
{
	/*
		Writes a sample strip to the given buffer

		Script made by TheSnidr 2018
		www.TheSnidr.com
	*/
	var strip = sampleStrip.strip;
	var steps = sampleStrip.steps;

	//Write header
	buffer_write(saveBuff, buffer_string, "SnidrsSampleStrip");

	//Write rig and animation to buffer
	rig_write_to_buffer(saveBuff, sampleStrip.rig);
	anim_write_to_buffer(saveBuff, sampleStrip.anim);

	//Write samplestrip to buffer
	buffer_write(saveBuff, buffer_u32, steps);
	var num = sampleStrip.rig.boneNum * 8;
	for (var i = 0; i <= steps; i ++)
	{
		//Update the samples if they don't exist yet
		var sample = strip[i];
		if !is_array(sample)
		{
			sample = anim_generate_sample(sampleStrip.rig, sampleStrip.anim, i / steps);
			strip[@ i] = sample;
		}
		for (var j = 0; j < num; j ++)
		{
			buffer_write(saveBuff, buffer_f32, sample[j]);
		}
	}
}
function samplestrip_read_from_buffer(loadBuff) 
{	//Reads a sample strip from the given buffer

	//Read header
	var header = buffer_read(loadBuff, buffer_string);
	if (header != "SnidrsSampleStrip")
	{
		show_debug_message("Error in script samplestrip_read_from_buffer:  Trying to read from a section that does not contain a samplestrip.");
	}

	//Read rig and animation to buffer
	var rig = rig_read_from_buffer(loadBuff);
	var anim = anim_read_from_buffer(loadBuff);

	//Read samplestrip from buffer
	var sampleStrip = new samplestrip(rig, anim);
	var steps = buffer_read(loadBuff, buffer_u32);
	var strip = array_create(steps + 1);
	var num = rig.boneNum * 8;
	sampleStrip.strip = strip;
	for (var i = 0; i <= steps; i ++)
	{
		//Update the samples if they don't exist yet
		var sample = array_create(num);
		for (var j = 0; j < num; j ++)
		{
			sample[@ j] = buffer_read(loadBuff, buffer_f32);
		}
		strip[@ i] = sample;
	}

	return sampleStrip;
}