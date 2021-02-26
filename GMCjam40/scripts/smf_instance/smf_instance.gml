/// @description smf_instance_create(modelInd)
/// @param modelInd
function smf_instance(_model) constructor 
{
	model = _model;
	rig = model.rig;
	currAnim = -1;
	animSpeed = 0;
	timer = 0;
	animLerp = 1;
	lerpSpd = .2;
	sample = -1;
	prevSample = -1;
	backupSample = -1;
	smooth = true;
	fastSampling = false;
	newAnim = -1;
	newTimer = 0;
	
	if (rig >= 0)
	{
		sample = sample_create_bind(rig);
		prevSample = sample_create_bind(rig);
	}
	
	/// @func fastSampleTest() 
	static fastSampleTest = function()
	{
		if (fastSampling)
		{
			show_debug_message("Error in SMF instance: Can't edit fast-sampling instance!");
			return true;
		}
		return false;
	}
	
	/// @func step(timeStep) 
	static step = function(timeStep)
	{	/*	Animate and interpolate between animations for the given animation instance.
			Must be used once per step.*/
		//Load relevant data
		//If the current animation does not exist, create a bind pose sample and exit the script.
		if (currAnim < 0 && newAnim < 0){
			sample_update_bind(model.rig, sample);
			exit;}

		//Update the current instance's sample
		if (currAnim >= 0)
		{
			var sampleStrip = model.sampleStrips[currAnim];
			if (fastSampling)
			{
				sample = sampleStrip.get_nearest_frame(timer);
			}
			else
			{
				sampleStrip.update_sample(timer, sample, smooth);

				//Linearly interpolate between the two samples
				if (animLerp < 1)
				{
					sample_lerp(prevSample, sample, animLerp, sample);
					animLerp += lerpSpd * timeStep;
				}
			}
		}

		//Switch animations
		if (newAnim >= 0)
		{
			if (currAnim >= 0)
			{	//Copy the current sample over to the previous sample
				animLerp = 0;
				array_copy(prevSample, 0, sample, 0, array_length(sample));
			}
			else
			{	//If there was no previous animation, update the sample immediately
				var sampleStrip = model.sampleStrips[newAnim];
				sampleStrip.update_sample(newTimer, sample, smooth);
			}
			currAnim = newAnim;
			newAnim = -1;
			timer = newTimer;
		}

		//Increment the current animation's timer
		if (currAnim >= 0)
		{
			var animInd = model.animations[currAnim];
			if (animInd.loop)
			{
				timer = frac(timer + animSpeed * timeStep + 1);
			}
			else
			{
				timer = clamp(timer + animSpeed * timeStep, 0, 1);
			}
		}
	}
	
	/// @func draw() 
	static draw = function()
	{
		model.submit(sample);
	}
	
	/// @func getAnimSpeed(anim)
	static getAnimSpeed = function(animName)
	{
		var anim = model.get_animation("Jump");
		if is_undefined(anim){return 0;}
		return 1000 / anim.playTime / game_get_speed(gamespeed_fps);
	}
	
	/// @func fast_sampling(enable) 
	static fast_sampling = function(enable)
	{	/*	This script enables fast animation sampling from the animation instance.
			This means that the samples are not interpolated at all, but are taken directly from the sample strip.åå
	
			//IMPORTANT//
				When fast sampling is enabled, the sample must NOT be edited! This runs the risk of editing the sample strip itself,
				resulting in possibly breaking the entire animation.
			//IMPORTANT//*/
		if (enable && !fastSampling)
		{
			backupSample = sample;
		}
		if (!enable && fastSampling)
		{
			sample = backupSample;
		}
		fastSampling = enable;
	}
	
	/// @func play(animName, animSpeed, lerpSpeed, resetTimer) 
	static play = function(animName, spd, lerpSpeed, resetTimer) 
	{	/*	Play an animation in the given animation instance.
			If the animation is already playing, this script will only set the animation speed.*/
		var animMap = model.animMap;
		var animInd = animMap[? animName];
		if is_undefined(animInd){
			show_debug_message("Error in SMF instance's function \"play\": Could not find animation " + string(animName));
			return -1;}
		//Set anim speed and lerp speed even if the animation index hasn't changed
		lerpSpd = lerpSpeed;
		animSpeed = spd;
		if (!resetTimer && currAnim == animInd){
			exit;}
		newAnim = animInd;
		newTimer = (1 - resetTimer) * frac(timer);
	}
	
	/// @func lerp_sample(inst1, inst2, amount) 
	static lerp_sample = function(inst1, inst2, amount) 
	{	//Linearly interpolates between the samples of the two instances, and saves it to the target instance
		if fastSampleTest(){exit;}
		sample_lerp(inst1.sample, inst2.sample, amount, sample);
	}
	
	/// @func splice_branch(sourceInst, nodeInd, weight) 
	static splice_branch = function(sourceInst, nodeInd, weight) 
	{	/*	This script lets you combine one bone and all its descendants from one sample into another.
			Useful if you've only animated parts of the rig in one sample.
	
			weight should be between 0 and 1. At 0, there will be no change to the sample. At 1, the branch will be copied from the source to the destination.
			Anything inbetween will interpolate linearly. Note that the interpolation may accidentally detach bones from their parents.*/
		if fastSampleTest(){exit;}
		sample_splice_branch(rig, nodeInd, sample, sourceInst.sample, weight);
	}
	
	/// @func node_yaw(node, degrees)
	static node_yaw = function(node, degrees)
	{	//Yaw a node around its up axis
		if fastSampleTest(){exit;}
		sample_node_yaw(rig, node, sample, degtorad(degrees), true);
	}
	
	/// @func node_pitch(node, degrees)
	static node_pitch = function(node, degrees)
	{	//Pitch a node around its side axis
		if fastSampleTest(){exit;}
		sample_node_pitch(rig, node, sample, degtorad(degrees), true);
	}
	
	/// @func node_roll(node, degrees)
	static node_roll = function(node, degrees)
	{	//Roll a node around its axis
		if fastSampleTest(){exit;}
		sample_node_roll(rig, node, sample, degtorad(degrees), true);
	}
	
	/// @func node_rotate(node, degrees, ax, ay, az)
	static node_rotate = function(node, degrees, ax, ay, az)
	{	//Rotates a node around a custom rig-space axis
		if fastSampleTest(){exit;}
		sample_node_rotate_axis(rig, node, sample, degtorad(degrees), ax, ay, az, true);
	}
	
	/// @func node_rotate_x(node, degrees)
	static node_rotate_x = function(node, degrees) 
	{	//Rotates a node around the rig-space x-axis
		if fastSampleTest(){exit;}
		sample_node_rotate_x(rig, node, sample, degtorad(degrees));
	}
	
	/// @func node_rotate_y(node, degrees)
	static node_rotate_y = function(node, degrees) 
	{	//Rotates a node around the rig-space y-axis
		if fastSampleTest(){exit;}
		sample_node_rotate_y(rig, node, sample, degtorad(degrees));
	}
	
	/// @func node_rotate_z(node, degrees)
	static node_rotate_z = function(node, degrees) 
	{	//Rotates a node around the rig-space z-axis
		if fastSampleTest(){exit;}
		sample_node_rotate_z(rig, node, sample, degtorad(degrees));
	}
	
	/// @func node_drag(node, xx, yy, zz, transformChildren) 
	static node_drag = function(node, xx, yy, zz, transformChildren) 
	{	/*	Move a node towards a given coordinate.
			Given coordinates must be in the same space as the rig, not in world space.
	
			If the selected node is representing a bone, it will be restrained by its parents.
			If both its parent and its grandparent are bones, a two-joint inverse kinematic operation is performed.*/
		if fastSampleTest(){exit;}
		sample_node_drag(rig, node, sample, xx, yy, zz, transformChildren);
	}
	
	/// @func node_move_ik(node, xx, yy, zz, moveFromCurrent, transformChildren) 
	static node_move_ik = function(node, xx, yy, zz, moveFromCurrent, transformChildren) 
	{	/*	Move a node towards a given coordinate.
			Given coordinates must be in the same space as the rig, not in world space.
	
			If the selected node is representing a bone, it will be restrained by its parents.
			If both its parent and its grandparent are bones, a two-joint inverse kinematic operation is performed.*/
		if fastSampleTest(){exit;}
		sample_node_move(rig, node, sample, xx, yy, zz, moveFromCurrent, transformChildren);
	}
	
	/// @func node_move_ik_fast(node, xx, yy, zz, moveFromCurrent, transformChildren) 
	static node_move_ik_fast = function(node, xx, yy, zz, moveFromCurrent, transformChildren) 
	{	/*	Move a node towards a given coordinate.
			Given coordinates must be in the same space as the rig, not in world space.
	
			If the selected node is representing a bone, it will be restrained by its parents.
			If both its parent and its grandparent are bones, a two-joint inverse kinematic operation is performed.*/
		if fastSampleTest(){exit;}
		sample_node_move_fast(rig, node, sample, xx, yy, zz, moveFromCurrent, transformChildren);
	}
	
	/// @func node_get_dq(node) 
	static node_get_dq = function(node)
	{	//Returns the current rig-space dual quaternion of the given node
		return sample_get_node_dq(rig, node, sample);
	}
	
	/// @func node_get_matrix(node) 
	static node_get_matrix = function(node) 
	{	//Returns the rig-space matrix of the given node
		return sample_get_node_matrix(rig, node, sample);
	}
	
	/// @func node_get_position(node) 
	static node_get_position = function(node) 
	{	/*Returns the rig-space position of the node as an array of the following format:
				[x, y, z];*/
		return sample_get_node_position(rig, node, sample);
	}
	
	/// @func get_animation() 
	function get_animation(inst) 
	{	//Returns the instance's current animation
		if (currAnim < 0){
			return -1;}
		var animArray = model.animations;
		return animArray[currAnim];
	}
}

//Compatibility scripts
function smf_instance_create(model)
{
	return new smf_instance(model);
}
function smf_instance_play_animation(inst, animName, animSpeed, lerpSpeed, resetTimer) 
{
	inst.play(animName, animSpeed, lerpSpeed, resetTimer);
}
function smf_instance_lerp(inst1, inst2, amount, target) 
{
	target.lerp_sample(inst1, inst2, amount);
}
function smf_instance_splice_branch(targetInst, sourceInst, nodeInd, weight) 
{
	targetInst.splice_branch(sourceInst, nodeInd, weight);
}
function smf_instance_node_yaw(inst, node, degrees)
{
	inst.node_yaw(node, degrees);
}
function smf_instance_node_pitch(inst, node, degrees)
{
	inst.node_pitch(node, degrees);
}
function smf_instance_node_roll(inst, node, degrees)
{
	inst.node_roll(node, degrees);
}
function smf_instance_node_rotate_axis(inst, node, degrees, ax, ay, az) 
{
	inst.node_rotate(node, degrees, ax, ay, az);
}
function smf_instance_node_rotate_x(inst, node, degrees) 
{	
	inst.node_rotate_x(node, degrees) 
}
function smf_instance_node_rotate_y(inst, node, degrees) 
{
	inst.node_rotate_y(node, degrees) 
}
function smf_instance_node_rotate_z(inst, node, degrees) 
{
	inst.node_rotate_z(node, degrees) 
}
function smf_instance_node_drag(inst, node, xx, yy, zz, transformChildren) 
{
	inst.node_drag(node, xx, yy, zz, transformChildren);
}
function smf_instance_node_move_ik(inst, node, xx, yy, zz, moveFromCurrent, transformChildren) 
{
	inst.node_move_ik(node, xx, yy, zz, moveFromCurrent, transformChildren);
}
function smf_instance_node_move_ik_fast(inst, node, xx, yy, zz, moveFromCurrent, transformChildren) 
{
	inst.node_move_ik_fast(node, xx, yy, zz, moveFromCurrent, transformChildren) 
}
function smf_instance_step(inst, timeStep) 
{
	inst.step(timeStep);
}
function smf_instance_draw(inst) 
{
	inst.draw();
}
function smf_instance_enable_fast_sampling(inst, enable) 
{
	inst.fast_sampling(enable);
}
function smf_instance_set_animation_speed(inst, animSpeed) 
{
	inst.animSpeed = animSpeed;
}
function smf_instance_set_smooth(inst, smooth) 
{
	inst.smooth = smooth;
}
function smf_instance_set_timer(inst, timer) 
{
	inst.timer = timer;
}
function smf_instance_get_node_dq(inst, node) 
{
	return inst.node_get_dq(node);
}
function smf_instance_get_node_matrix(inst, node) 
{
	return inst.node_get_matrix(node);
}
function smf_instance_get_node_position(inst, node) 
{
	return inst.node_get_position(node);
}
function smf_instance_get_sample(inst) 
{
	return inst.sample;
}
function smf_instance_get_timer(inst) 
{
	return inst.timer;
}
function smf_instance_get_animation(inst) 
{
	return inst.get_animation();
}
function smf_instance_get_fast_sampling(inst) 
{
	return inst.fastSampling;
}