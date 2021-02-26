/// @description mbuff_combine(target, source)
/// @param target
/// @param source
function mbuff_combine(argument0, argument1) {
	/*
		Lets you combine two model buffers into one.
	
		Script created by TheSnidr, 2019
		www.TheSnidr.com
	*/
	var trg = argument0;
	var src = argument1;

	var srcSize = buffer_get_size(src);
	var trgSize = buffer_get_size(trg);

	buffer_resize(trg, srcSize + trgSize);
	buffer_copy(src, 0, srcSize, trg, trgSize);


}
