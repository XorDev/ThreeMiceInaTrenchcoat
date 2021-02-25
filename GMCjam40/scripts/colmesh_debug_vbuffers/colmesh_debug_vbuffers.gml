/*
	This script will generate primitives with a custom format that allows for dynamic non-uniform scaling scaling.
	These are mostly used for debugging the collision system.
*/
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_texcoord();
vertex_format_add_color();
global.ColMeshFormat = vertex_format_end();

function colmesh_debug_draw_capsule(x, y, z, xup, yup, zup, radius, height, colour)
{
	var type = eColMeshShape.Capsule;
	var vbuff = global.ColMeshDebugShapes[type];
	if (vbuff < 0)
	{
		global.ColMeshDebugShapes[type] = colmesh_create_capsule(20, 10, 1, 1);
		vbuff = global.ColMeshDebugShapes[type];
	}
	shader_set(sh_colmesh_debug);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_color"), color_get_red(colour) / 255, color_get_green(colour) / 255, color_get_blue(colour) / 255, 1);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), radius);
	matrix_set(matrix_world, colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, 1, 1, height));
	vertex_submit(vbuff, pr_trianglelist, -1);
	shader_reset();
	matrix_set(matrix_world, matrix_build_identity());
}
function colmesh_debug_draw_cylinder(x, y, z, xup, yup, zup, radius, height, colour)
{
	var type = eColMeshShape.Cylinder;
	var vbuff = global.ColMeshDebugShapes[type];
	if (vbuff < 0)
	{
		global.ColMeshDebugShapes[type] = colmesh_create_cylinder(20, 1, 1);
		vbuff = global.ColMeshDebugShapes[type];
	}
	shader_set(sh_colmesh_debug);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_color"), color_get_red(colour) / 255, color_get_green(colour) / 255, color_get_blue(colour) / 255, 1);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), 0);
	matrix_set(matrix_world, colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, radius, radius, height));
	vertex_submit(vbuff, pr_trianglelist, -1);
	shader_reset();
	matrix_set(matrix_world, matrix_build_identity());
}
function colmesh_debug_draw_sphere(x, y, z, radius, colour)
{
	var type = eColMeshShape.Sphere;
	var vbuff = global.ColMeshDebugShapes[type];
	if (vbuff < 0)
	{
		global.ColMeshDebugShapes[type] = colmesh_create_sphere(20, 10, 1, 1);
		vbuff = global.ColMeshDebugShapes[type];
	}
	shader_set(sh_colmesh_debug);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_color"), color_get_red(colour) / 255, color_get_green(colour) / 255, color_get_blue(colour) / 255, 1);
	shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), radius);
	matrix_set(matrix_world, matrix_build(x, y, z, 0, 0, 0, 1, 1, 1));
	vertex_submit(vbuff, pr_trianglelist, -1);
	shader_reset();
	matrix_set(matrix_world, matrix_build_identity());
}

//Function for creating a sphere as a pr_trianglelist vertex buffer
function colmesh_create_sphere(hVerts, vVerts, hRep, vRep)
{
	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, global.ColMeshFormat);
	for (var xx = 0; xx < hVerts; xx ++)
	{
		var xa1 = xx / hVerts * 2 * pi;
		var xa2 = (xx+1) / hVerts * 2 * pi;
		var xc1 = cos(xa1);
		var xs1 = sin(xa1);
		var xc2 = cos(xa2);
		var xs2 = sin(xa2);
		for (var yy = 0; yy < vVerts; yy ++)
		{
			var ya1 = yy / vVerts * pi;
			var ya2 = (yy+1) / vVerts * pi;
			var yc1 = cos(ya1);
			var ys1 = sin(ya1);
			var yc2 = cos(ya2);
			var ys2 = sin(ya2);
			
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc1 * ys1, xs1 * ys1, yc1);
			vertex_texcoord(vbuff, xx / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc2 * ys2, xs2 * ys2, yc2);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
		}
	}
	vertex_end(vbuff);
	vertex_freeze(vbuff);
	return vbuff;
}

//Function for creating a block as a pr_trianglelist vertex buffer
function colmesh_create_block(hRep, vRep)
{
	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, global.ColMeshFormat);
	
	//+z
	vertex_position_3d(vbuff, -1, -1, 1);
	vertex_normal(vbuff, 0, 0, 1);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, 1);
	vertex_normal(vbuff, 0, 0, 1);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, 1, 1);
	vertex_normal(vbuff, 0, 0, 1);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	
	vertex_position_3d(vbuff, -1, 1, 1);
	vertex_normal(vbuff, 0, 0, 1);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, 1);
	vertex_normal(vbuff, 0, 0, 1);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, 1, 1);
	vertex_normal(vbuff, 0, 0, 1);
	vertex_texcoord(vbuff, hRep, vRep);
	vertex_color(vbuff, c_white, 1);
	
	//-z
	vertex_position_3d(vbuff, -1, -1, -1);
	vertex_normal(vbuff, 0, 0, -1);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, 1, -1);
	vertex_normal(vbuff, 0, 0, -1);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, -1);
	vertex_normal(vbuff, 0, 0, -1);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	
	vertex_position_3d(vbuff, -1, 1, -1);
	vertex_normal(vbuff, 0, 0, -1);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, 1, -1);
	vertex_normal(vbuff, 0, 0, -1);
	vertex_texcoord(vbuff, hRep, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, -1);
	vertex_normal(vbuff, 0, 0, -1);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	
	//+x
	vertex_position_3d(vbuff, 1, -1, -1);
	vertex_normal(vbuff, 1, 0, 0);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, 1, -1);
	vertex_normal(vbuff, 1, 0, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, 1);
	vertex_normal(vbuff, 1, 0, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	
	vertex_position_3d(vbuff, 1, 1, -1);
	vertex_normal(vbuff, 1, 0, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, 1, 1);
	vertex_normal(vbuff, 1, 0, 0);
	vertex_texcoord(vbuff, hRep, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, 1);
	vertex_normal(vbuff, 1, 0, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	
	//-x
	vertex_position_3d(vbuff, -1, -1, -1);
	vertex_normal(vbuff, -1, 0, 0);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, -1, 1);
	vertex_normal(vbuff, -1, 0, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, 1, -1);
	vertex_normal(vbuff, -1, 0, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	
	vertex_position_3d(vbuff, -1, 1, -1);
	vertex_normal(vbuff, -1, 0, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, -1, 1);
	vertex_normal(vbuff, -1, 0, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, 1, 1);
	vertex_normal(vbuff, -1, 0, 0);
	vertex_texcoord(vbuff, hRep, vRep);
	vertex_color(vbuff, c_white, 1);
	
	//+y
	vertex_position_3d(vbuff, -1, 1, -1);
	vertex_normal(vbuff, 0, 1, 0);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, 1, 1);
	vertex_normal(vbuff, 0, 1, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, 1, -1);
	vertex_normal(vbuff, 0, 1, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	
	vertex_position_3d(vbuff, 1, 1, -1);
	vertex_normal(vbuff, 0, 1, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, 1, 1);
	vertex_normal(vbuff, 0, 1, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, 1, 1);
	vertex_normal(vbuff, 0, 1, 0);
	vertex_texcoord(vbuff, hRep, vRep);
	vertex_color(vbuff, c_white, 1);
	
	//-y
	vertex_position_3d(vbuff, -1, -1, -1);
	vertex_normal(vbuff, 0, -1, 0);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, -1);
	vertex_normal(vbuff, 0, -1, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, -1, 1);
	vertex_normal(vbuff, 0, -1, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	
	vertex_position_3d(vbuff, 1, -1, -1);
	vertex_normal(vbuff, 0, -1, 0);
	vertex_texcoord(vbuff, 0, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, 1, -1, 1);
	vertex_normal(vbuff, 0, -1, 0);
	vertex_texcoord(vbuff, hRep, vRep);
	vertex_color(vbuff, c_white, 1);
	vertex_position_3d(vbuff, -1, -1, 1);
	vertex_normal(vbuff, 0, -1, 0);
	vertex_texcoord(vbuff, hRep, 0);
	vertex_color(vbuff, c_white, 1);
	
	vertex_end(vbuff);
	vertex_freeze(vbuff);
	return vbuff;
}

//Function for creating a torus as a pr_trianglelist vertex buffer
function colmesh_create_torus(hVerts, vVerts, hRep, vRep)
{
	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, global.ColMeshFormat);
	for (var xx = 0; xx < hVerts; xx ++)
	{
		var xa1 = xx / hVerts * 2 * pi;
		var xa2 = (xx+1) / hVerts * 2 * pi;
		var xc1 = cos(xa1);
		var xs1 = sin(xa1);
		var xc2 = cos(xa2);
		var xs2 = sin(xa2);
		for (var yy = 0; yy < vVerts; yy ++)
		{
			var ya1 = yy / vVerts * 2 * pi;
			var ya2 = (yy+1) / vVerts * 2 * pi;
			var yc1 = cos(ya1);
			var ys1 = sin(ya1);
			var yc2 = cos(ya2);
			var ys2 = sin(ya2);
			
			vertex_position_3d(vbuff, xc1, xs1, 0);
			vertex_normal(vbuff, xc1 * ys1, xs1 * ys1, yc1);
			vertex_texcoord(vbuff, xx / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc1, xs1, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc2, xs2, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			
			vertex_position_3d(vbuff, xc1, xs1, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc2, xs2, 0);
			vertex_normal(vbuff, xc2 * ys2, xs2 * ys2, yc2);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc2, xs2, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
		}
	}
	vertex_end(vbuff);
	vertex_freeze(vbuff);
	return vbuff;
}

//Function for creating a disk as a pr_trianglelist vertex buffer
function colmesh_create_disk(hVerts, vVerts, hRep, vRep)
{
	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, global.ColMeshFormat);
	for (var xx = 0; xx < hVerts; xx ++)
	{
		var xa1 = xx / hVerts * 2 * pi;
		var xa2 = (xx+1) / hVerts * 2 * pi;
		var xc1 = cos(xa1);
		var xs1 = sin(xa1);
		var xc2 = cos(xa2);
		var xs2 = sin(xa2);
		
		vertex_position_3d(vbuff, 1, 0, 0);
		vertex_normal(vbuff, 0, 0, 1);
		vertex_texcoord(vbuff, hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc1, xs1, 0);
		vertex_normal(vbuff, 0, 0, 1);
		vertex_texcoord(vbuff, xc1 * hRep, xs1 * vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc2, xs2, 0);
		vertex_normal(vbuff, 0, 0, 1);
		vertex_texcoord(vbuff, xc2 * hRep, xs2 * vRep);
		vertex_color(vbuff, c_white, 1);
		
		vertex_position_3d(vbuff, 1, 0, 0);
		vertex_normal(vbuff, 0, 0, -1);
		vertex_texcoord(vbuff, hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc2, xs2, 0);
		vertex_normal(vbuff, 0, 0, -1);
		vertex_texcoord(vbuff, xc2 * hRep, xs2 * vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc1, xs1, 0);
		vertex_normal(vbuff, 0, 0, -1);
		vertex_texcoord(vbuff, xc1 * hRep, xs1 * vRep);
		vertex_color(vbuff, c_white, 1);
		
		for (var yy = 0; yy < vVerts; yy ++)
		{
			var ya1 = yy / vVerts * pi;
			var ya2 = (yy+1) / vVerts * pi;
			var yc1 = cos(ya1);
			var ys1 = sin(ya1);
			var yc2 = cos(ya2);
			var ys2 = sin(ya2);
			
			vertex_position_3d(vbuff, xc1, xs1, 0);
			vertex_normal(vbuff, xc1 * ys1, xs1 * ys1, yc1);
			vertex_texcoord(vbuff, xx / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc1, xs1, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc2, xs2, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			
			vertex_position_3d(vbuff, xc1, xs1, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc2, xs2, 0);
			vertex_normal(vbuff, xc2 * ys2, xs2 * ys2, yc2);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, xc2, xs2, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
		}
	}
	vertex_end(vbuff);
	vertex_freeze(vbuff);
	return vbuff;
}

//Function for creating a capsule as a pr_trianglelist vertex buffer
function colmesh_create_capsule(hVerts, vVerts, hRep, vRep)
{
	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, global.ColMeshFormat);
	for (var xx = 0; xx < hVerts; xx ++)
	{
		var xa1 = xx / hVerts * 2 * pi;
		var xa2 = (xx+1) / hVerts * 2 * pi;
		var xc1 = cos(xa1);
		var xs1 = sin(xa1);
		var xc2 = cos(xa2);
		var xs2 = sin(xa2);
		
		vertex_position_3d(vbuff, 0, 0, 0);
		vertex_normal(vbuff, xc1, xs1, 0);
		vertex_texcoord(vbuff, xx / hVerts * hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, 0, 0, 0);
		vertex_normal(vbuff, xc2, xs2, 0);
		vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, 0, 0, 1);
		vertex_normal(vbuff, xc1, xs1, 0);
		vertex_texcoord(vbuff, xx / hVerts * hRep, vRep);
		vertex_color(vbuff, c_white, 1);
		
		vertex_position_3d(vbuff, 0, 0, 0);
		vertex_normal(vbuff, xc2, xs2, 0);
		vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, 0, 0, 1);
		vertex_normal(vbuff, xc2, xs2, 0);
		vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, 0, 0, 1);
		vertex_normal(vbuff, xc1, xs1, 0);
		vertex_texcoord(vbuff, xx / hVerts * hRep, vRep);
		vertex_color(vbuff, c_white, 1);
		
		for (var yy = 0; yy < vVerts; yy ++)
		{
			var ya1 = yy / vVerts * pi / 2;
			var ya2 = (yy+1) / vVerts * pi / 2;
			var yc1 = cos(ya1);
			var ys1 = sin(ya1);
			var yc2 = cos(ya2);
			var ys2 = sin(ya2);
			
			//Draw the bottom hemisphere
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc1 * ys1, xs1 * ys1, - yc1);
			vertex_texcoord(vbuff, xx / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, - yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, - yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, - yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, - yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 0);
			vertex_normal(vbuff, xc2 * ys2, xs2 * ys2, - yc2);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			
			//Draw top hemisphere
			vertex_position_3d(vbuff, 0, 0, 1);
			vertex_normal(vbuff, xc1 * ys1, xs1 * ys1, yc1);
			vertex_texcoord(vbuff, xx / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 1);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 1);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			
			vertex_position_3d(vbuff, 0, 0, 1);
			vertex_normal(vbuff, xc1 * ys2, xs1 * ys2, yc2);
			vertex_texcoord(vbuff, xx / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 1);
			vertex_normal(vbuff, xc2 * ys2, xs2 * ys2, yc2);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, (yy+1) / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
			vertex_position_3d(vbuff, 0, 0, 1);
			vertex_normal(vbuff, xc2 * ys1, xs2 * ys1, yc1);
			vertex_texcoord(vbuff, (xx+1) / hVerts * hRep, yy / vVerts * vRep);
			vertex_color(vbuff, c_white, 1);
		}
	}
	vertex_end(vbuff);
	vertex_freeze(vbuff);
	return vbuff;
}

//Function for creating a cylinder as a pr_trianglelist vertex buffer
function colmesh_create_cylinder(steps, hRep, vRep)
{
	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, global.ColMeshFormat);
	for (var xx = 0; xx < steps; xx ++)
	{
		var xa1 = xx / steps * 2 * pi;
		var xa2 = (xx+1) / steps * 2 * pi;
		var xc1 = cos(xa1);
		var xs1 = sin(xa1);
		var xc2 = cos(xa2);
		var xs2 = sin(xa2);
		
		vertex_position_3d(vbuff, xc1, xs1, 0);
		vertex_normal(vbuff, xc1, xs1, 0);
		vertex_texcoord(vbuff, xx / steps * hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc2, xs2, 0);
		vertex_normal(vbuff, xc2, xs2, 0);
		vertex_texcoord(vbuff, (xx+1) / steps * hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc1, xs1, 1);
		vertex_normal(vbuff, xc1, xs1, 0);
		vertex_texcoord(vbuff, xx / steps * hRep, vRep);
		vertex_color(vbuff, c_white, 1);
		
		vertex_position_3d(vbuff, xc2, xs2, 0);
		vertex_normal(vbuff, xc2, xs2, 0);
		vertex_texcoord(vbuff, (xx+1) / steps * hRep, 0);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc2, xs2, 1);
		vertex_normal(vbuff, xc2, xs2, 0);
		vertex_texcoord(vbuff, (xx+1) / steps * hRep, vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc1, xs1, 1);
		vertex_normal(vbuff, xc1, xs1, 0);
		vertex_texcoord(vbuff, xx / steps * hRep, vRep);
		vertex_color(vbuff, c_white, 1);
		
		//Bottom lid
		vertex_position_3d(vbuff, 1, 0, 0);
		vertex_normal(vbuff, 0, 0, -1);
		vertex_texcoord(vbuff, hRep, .5 * vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc2, xs2, 0);
		vertex_normal(vbuff, 0, 0, -1);
		vertex_texcoord(vbuff, (.5 + .5 * xc2) * hRep, (.5 + .5 * xs2) * vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc1, xs1, 0);
		vertex_normal(vbuff, 0, 0, -1);
		vertex_texcoord(vbuff, (.5 + .5 * xc1) * hRep, (.5 + .5 * xs1) * vRep);
		vertex_color(vbuff, c_white, 1);
		
		//Top lid
		vertex_position_3d(vbuff, 1, 0, 1);
		vertex_normal(vbuff, 0, 0, 1);
		vertex_texcoord(vbuff, hRep, .5 * vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc1, xs1, 1);
		vertex_normal(vbuff, 0, 0, 1);
		vertex_texcoord(vbuff, (.5 + .5 * xc1) * hRep, (.5 + .5 * xs1) * vRep);
		vertex_color(vbuff, c_white, 1);
		vertex_position_3d(vbuff, xc2, xs2, 1);
		vertex_normal(vbuff, 0, 0, 1);
		vertex_texcoord(vbuff, (.5 + .5 * xc2) * hRep, (.5 + .5 * xs2) * vRep);
		vertex_color(vbuff, c_white, 1);
	}
	vertex_end(vbuff);
	vertex_freeze(vbuff);
	return vbuff;
}