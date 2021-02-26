/// @description mbuff_save(mbuff, fname)
/// @param mbuff
/// @param fname
function mbuff_save(argument0, argument1) {
	/*
		Saves the given model buffer to the given filename

		Script created by TheSnidr
		www.thesnidr.com
	*/
	var fname, mBuff, modelNum, saveBuff, i, buffSize;
	var mBuff = argument0;
	var fname = argument1;
	modelNum = array_length(mBuff);

	saveBuff = buffer_create(1, buffer_grow, 1);

	mbuff_write_to_buffer(saveBuff, mBuff);

	buffer_save(saveBuff, fname);
	buffer_delete(saveBuff);


}
