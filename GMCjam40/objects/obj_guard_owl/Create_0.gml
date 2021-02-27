///@desc enemy init
//Enemy variables

event_inherited();

function draw()
{
	var _sway = dcos(sway*3)*speed*3;
	matrix_set(matrix_world,matrix_build(x,y,z,_sway,0,face+90,6,6,6));
	vertex_submit(global.modOwl,pr_trianglelist, sprite_get_texture(spr_owl, 0));
	matrix_set(matrix_world,matrix_build_identity());
}