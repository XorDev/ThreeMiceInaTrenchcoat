/// @description texpack_add_texpack(target, source)
/// @param target
/// @param source
function texpack_add_texpack(argument0, argument1) {
	var trg = argument0;
	var src = argument1;

	var trgNum = array_length(trg);
	var srcNum = array_length(src);
	for (var i = trgNum; i < trgNum + srcNum; i ++)
	{
		trg[@ i] = src[i - trgNum];
	}
	return trg;


}
