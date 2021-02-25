/// @description
if global.disableDraw{exit;}

event_inherited();

//Draw ground
shader_set(sh_colmesh_collider);
shader_set_lightdir(sh_colmesh_collider);
shader_reset();

//Draw debug collision shapes
if global.drawDebug
{
	matrix_set(matrix_world, matrix_build_identity());
	levelColmesh.debugDraw(levelColmesh.getRegion(x, y, z, xup, yup, zup, radius, height));
}

//Cast a ray in the looking direction of the player
//var ray = levelColmesh.castRay(x, y, z + height, x + charMat[0] * 100, y + charMat[1] * 100, z - radius - 50 + charMat[2] * 100);
/*if (ray[6])
{
	shader_set(sh_colmesh_collider);
	
	var dx = ray[0] - x;
	var dy = ray[1] - y;
	var dz = ray[2] - z - height;
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_radius"), 1);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_color"), 1, 0, 0);
	matrix_set(matrix_world, colmesh_matrix_build_from_vector(x, y, z + height, dx, dy, dz, 1, 1, sqrt(dx * dx + dy * dy + dz * dz)));
	vertex_submit(global.modCapsule, pr_trianglelist, -1);

	shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_radius"), 5);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_collider, "u_color"), .8, .3, .2);
	matrix_set(matrix_world, matrix_build(ray[0], ray[1], ray[2], 0, 0, 0, 1, 1, 1));
	vertex_submit(global.modSphere, pr_trianglelist, -1);
		
	matrix_set(matrix_world, matrix_build_identity());
	shader_reset();
}