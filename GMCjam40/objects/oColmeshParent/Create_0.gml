/// @description
if (variable_global_exists("levelColmesh"))
{
	exit;
}

global.modCapsule = colmesh_create_capsule(20, 10, 1, 1);
global.modCylinder = colmesh_create_cylinder(20, 1, 1);
global.modSphere = colmesh_create_sphere(32, 16, 1, 1);
global.modBlock = colmesh_create_block(1, 1);
global.modTorus = colmesh_create_torus(20, 10, 1, 1);
global.modDisk = colmesh_create_disk(20, 10, 1, 1);

global.drawDebug = false;
global.disableDraw = false;
global.drawText = true;
global.demoText = "";

globalvar levelColmesh;
levelColmesh = new colmesh();

global.lightDir = [0, 0, -1];
global.camX = 0;
global.camY = 0;
global.camZ = 0;

global.coins = 0;

globalvar shader_set_lightdir;
shader_set_lightdir = function(shader)
{
	shader_set_uniform_f(shader_get_uniform(shader, "u_lightDir"), global.lightDir[0], global.lightDir[1], global.lightDir[2]);
}

globalvar colmeshdemo_draw_circular_shadow;
colmeshdemo_draw_circular_shadow = function(x, y, z, xup, yup, zup, radius, length, alpha)
{	/*
		This function will draw a circular shadow onto terrain beneath the given coordinates
		See this video for an explanation on how this works:
			https://www.youtube.com/watch?v=s0w85FvdPAs
	*/
	var M = colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, 1, 1, 1);
	
	gpu_set_zwriteenable(false);
	shader_set(sh_colmesh_shadow);
	gpu_set_blendmode_ext_sepalpha(bm_zero, bm_one, bm_one, bm_zero);
	matrix_set(matrix_world, matrix_multiply(matrix_build(0, 0, 0, 0, 0, 0, -radius, radius, -length), M));
	gpu_set_cullmode(cull_clockwise);

	shader_set_uniform_f(shader_get_uniform(sh_colmesh_shadow, "u_color"), 0, 0, 0, 1 - alpha);
	vertex_submit(global.modCylinder, pr_trianglelist, -1);

	//Draw cylinder with a special blend mode that filters away the parts of the cylinder that are drawn above the inverted cylinder, resulting in a projected circle
	gpu_set_blendmode_ext_sepalpha(bm_dest_color, bm_inv_dest_alpha, bm_one, bm_zero);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_shadow, "u_color"), 1 - alpha, 1 - alpha, 1 - alpha, 1);
	gpu_set_cullmode(cull_counterclockwise);
	vertex_submit(global.modCylinder, pr_trianglelist, -1);
	gpu_set_zwriteenable(true);
	gpu_set_blendmode(bm_normal);
	shader_reset();
}