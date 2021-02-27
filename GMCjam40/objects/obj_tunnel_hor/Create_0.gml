/// @description

function addToLevel()
{
	tex = sprite_get_texture(tex_button, 0);
	z = 0;
	
	//Add to colmesh
	var w = 32;
	var h = 64;
	var wallThickness = 5;
	var ceilingThickness = 10;
	levelColmesh.addShape(new colmesh_block(matrix_build(x, y, z, 0, 0, 0, w));
}