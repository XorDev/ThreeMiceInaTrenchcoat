///@desc enemy init
//Enemy variables
z = 00;
face = 0;
radius = 0;
tex = sprite_get_texture(spr_pug,0);

var buff = colmesh_load_obj_to_buffer("XorOwl.obj");
vbuff = vertex_create_buffer_from_buffer(buff, global.ColMeshFormat);

function draw()
{
	matrix_set(matrix_world,matrix_build(x,y,z,0,0,face,1,1,1));
	vertex_submit(vbuff,pr_trianglelist,tex);
	matrix_set(matrix_world,matrix_build_identity());
}