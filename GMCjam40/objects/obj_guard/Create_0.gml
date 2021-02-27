///@desc enemy init
//Enemy variables

anim = false;
z = 0;
zspeed = 0;
face = 0;
target = -1;
awareness = 0;
smooth = 0;
sway = 0;

target_x = 0;
target_y = 0;
target_z = 0;

radius = 0;
tex = sprite_get_texture(spr_owl,0);

function draw()
{
	var _sway = dcos(sway*5)*speed*3;
	matrix_set(matrix_world,matrix_build(x,y,z,_sway,0,face,1,1,1));
	vertex_submit(global.buf_owl,pr_trianglelist,tex);
	matrix_set(matrix_world,matrix_build_identity());
}