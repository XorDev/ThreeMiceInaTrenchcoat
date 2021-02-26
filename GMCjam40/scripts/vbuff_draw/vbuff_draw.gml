/// @description vbuff_draw(vBuff, texture)
/// @param vBuff
/// @param texture
function vbuff_draw(argument0, argument1) {
	/*
		Draws the given vbuff.
		vBuff can be either a vertex buffer or an array of vertex buffers.
		texture can be either a texture index or an array of sprite indices
	*/
	var spr, tex;
	var vBuff = argument0;
	var tex = argument1;
	if is_array(vBuff)
	{
		var n = array_length(vBuff);
		if is_array(tex)
		{
			var texPack = tex;
			var t = array_length(texPack);
			for (var i = 0; i < n; i ++)
			{
				if t > 0
				{
					spr = texPack[i mod t];
					tex = (spr >= 0) ? sprite_get_texture(spr, 0) : -1;
				}
				else
				{
					tex = -1;
				}
				vertex_submit(vBuff[i], pr_trianglelist, tex);
			}
		}
		else
		{
			for (var i = 0; i < n; i ++)
			{
				vertex_submit(vBuff[i], pr_trianglelist, tex);
			}
		}
	}
	else
	{
		vertex_submit(vBuff, pr_trianglelist, tex);
	}


}
