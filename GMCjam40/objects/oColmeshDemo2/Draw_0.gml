/// @description
if global.disableDraw{exit;}


event_inherited();

//Draw ground
shader_set(sh_colmesh_collider);
shader_set_lightdir(sh_colmesh_collider);
shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_radius"), 0);
shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_color"), .2, .7, .25);
matrix_set(matrix_world, block.M);
vertex_submit(global.modBlock, pr_trianglelist, -1);
matrix_set(matrix_world, matrix_build_identity());
shader_reset();

//Cast a ray in the looking direction of the player
var ray = levelColmesh.castRay(x, y, z + height, x + charMat[0] * 500, y + charMat[1] * 500, z - radius - 5 + charMat[2] * 500);
if (is_array(ray))
{
	var dx = ray[0] - x;
	var dy = ray[1] - y;
	var dz = ray[2] - z - height;
	var l = sqrt(dx * dx + dy * dy + dz * dz);
	colmesh_debug_draw_capsule(x, y, z + height, dx, dy, dz, 1, l, c_red);
	colmesh_debug_draw_sphere(ray[0], ray[1], ray[2], 5, c_red);
}

//Draw debug collision shapes
if global.drawDebug
{
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height), false);
}