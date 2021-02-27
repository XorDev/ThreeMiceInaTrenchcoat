///@desc Create objects

instance_create_depth(0,0,0,obj_deferred_control);

var _buff = colmesh_load_obj_to_buffer("Owl.obj");
global.buf_owl = vertex_create_buffer_from_buffer(_buff, global.ColMeshFormat);

var _buff = colmesh_load_obj_to_buffer("Pug.obj");
global.buf_pug = vertex_create_buffer_from_buffer(_buff, global.ColMeshFormat);

global.tex_owl = sprite_get_texture(spr_owl,0);
global.tex_pug = sprite_get_texture(spr_pug,0);