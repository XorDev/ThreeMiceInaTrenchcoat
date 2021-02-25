/// @description
if global.disableDraw{exit;}

event_inherited();

//Draw the level
gpu_set_texfilter(true);
shader_set(sh_colmesh_world);
shader_set_lightdir(sh_colmesh_world);
vertex_submit(modLevel, pr_trianglelist, sprite_get_texture(texCorona, 0));
shader_reset();

//Draw debug collision shapes
if global.drawDebug
{
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height));
}