/// @description mbuff_add(target, source)
/// @param target
/// @param source
function mbuff_add(argument0, argument1) {
	/*
		Returns a new array containing both source and target arrays
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var trg = argument0;
	var src = argument1;
	if !is_array(trg){trg = [trg];}
	if !is_array(src){src = [src];}

	var trgNum = array_length(trg);
	var srcNum = array_length(src);
	var ret = array_create(trgNum + srcNum);
	array_copy(ret, 0, trg, 0, trgNum);
	array_copy(ret, trgNum, src, 0, srcNum);

	return ret;


}
