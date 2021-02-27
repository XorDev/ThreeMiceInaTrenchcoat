/*
	ColMesh - 3D Collisions Made Easy!
	TheSnidr 2021
	
	License
	The ColMesh system is licensed under a CreativeCommons Attribution 4.0 International License.
		https://creativecommons.org/licenses/by/4.0/
	This means you are free to use it in both personal and commercial projects, free of charge.
	Appropriate credit is required.

	What is a ColMesh?
	A ColMesh is a collection of 3D primitives and triangle meshes against which you can cast rays and do collision checks. It is basically an easy-to-use 3D collision system for GMS 2.3.

	What does it do?
	It will push your player out of level geometry.
	It handles slope calculations for you so that your player doesn’t slide down slopes.
	It lets you move platforms around and gives you everything you need to make sure your player moves the same way.
	It lets you cast rays so that your player can shoot bullets or laser beams, and by casting a ray from the player’s previous coordinate to the new coordinate before doing collision checking, you can make sure the player never falls through level geometry.

	See forum topic for updated info:
		https://forum.yoyogames.com/index.php?threads/82765/
		
	Also feel free to join the Discord channel:
		www.TheSnidr.com
*/

#macro cmDebug true	//Set to false if you don't want the ColMesh system to output debug messages
#macro cmMaxRecursion 8	//The maximum recursion depth. Applies when you place a ColMesh inside itself
#macro cmFirstPassRadius 1.2 //The radius for the first pass when doing precise collision checking. 
#macro cmCol global.ColMeshCol //A global array that is used for returning a position after collision
#macro cmRay global.ColMeshRay //A global array that is used for ray casting
#macro cmTransform global.ColMeshTransformQueue //The calling object's transformation queue
#macro cmRecursion global.ColMeshRecursionCounter //A global variable counting number of recursions
#macro cmCallingObject global.ColMeshCallingObject
global.ColMeshCallingObject = -1;
global.ColMeshTransformQueue = -1;
global.ColMeshRecursionCounter = 0;
global.ColMeshRay = array_create(7);
global.ColMeshCol = array_create(7);
global.ColMeshDebugShapes = array_create(eColMeshShape.Num, -1);

/// @func colmesh()
function colmesh() : colmesh_shapes() constructor
{	/*
		Creates an empty ColMesh
	*/
	spHash = -1;
	triangle = -1;
	triangles = [];
	tempList = ds_list_create();
	shapeList = ds_list_create();	//List containing all the shapes of the colmesh
	regionSize = 0;
	queueArray = [];
	originX = 0;
	originY = 0;
	originZ = 0;
	minimum = [99999, 99999, 99999];
	maximum = [-99999, -99999, -99999];
	priority = array_create(cmMaxRecursion, -1);
	
	/// @func subdivide(regionSize)
	static subdivide = function(_regionSize)
	{
		/*
			This function will subdivide the colmesh into smaller regions, and save those regions to a ds_map.
			If the colmesh has already been subdivided, that is cleared first.
			A smaller region size will result in more regions, but fewer collision shapes per region.
		*/
		var debugTime = get_timer();
		
		//Clear old subdivision
		clearSubdiv();
		
		//Update subdivision parameters
		spHash = ds_map_create();
		regionSize = _regionSize;
		originX = (minimum[0] + maximum[0]) * .5;
		originY = (minimum[1] + maximum[1]) * .5;
		originZ = (minimum[2] + maximum[2]) * .5;
		
		//Subdivide
		var regionNum = 0;
		var shapeNum = ds_list_size(shapeList);
		for (var i = 0; i < shapeNum; i ++)
		{
			var shape = _getShape(shapeList[| i]);
			regionNum += shape._addToSubdiv(self);
		}
		
		colmesh_debug_message("colmesh.subdivide: Generated spatial hash with " + string(regionNum) + " regions in " + string((get_timer() - debugTime) / 1000) + " milliseconds");
	}
	
	/// @func clearSubdiv()
	static clearSubdiv = function()
	{
		/*
			Clears any data structures related to the subdivision of the colmesh
		*/
		if (spHash >= 0)
		{
			var region = ds_map_find_first(spHash);
			while (!is_undefined(region))
			{
				ds_list_destroy(spHash[? region]);
				region = ds_map_find_next(spHash, region);
			}
			ds_map_destroy(spHash);
			spHash = -1;
		}
		
		//Delete any queue lists that have been created in instances colliding with the colmesh
		var n = array_length(queueArray);
		for (var i = 0; i < n; i ++)
		{
			ds_queue_destroy(queueArray[i]);
		}
		queueArray = [];
	}
	
	/// @func clear()
	static clear = function()
	{
		/*
			Clears all info from the colmesh
		*/
		clearSubdiv();
		var h = 99999;
		triangles = [];
		queueArray = [];
		minimum = [h, h, h];
		maximum = [-h, -h, -h];
		ds_list_clear(tempList);
		ds_list_clear(shapeList);
		for (var i = 0; i < cmMaxRecursion; i ++)
		{
			if (priority[i] < 0) break;
			ds_priority_destroy(priority[i]);
			priority[i] = -1;
		}
	}
	
	/// @func destroy()
	static destroy = function()
	{
		/*
			Destroys the colmesh
		*/
		clear();
		ds_list_destroy(tempList);
		ds_list_destroy(shapeList);
	}
	
	/// @func getRegion(x, y, z, xup, yup, zup, radius, height)
	static getRegion = function(x, y, z, xup, yup, zup, radius, height) 
	{
		/*
			Returns a list containing all the shapes in the regions the AABB of the given capsule touches.
			If the colmesh is not subdivided, this will return a list of all the shapes in the colmesh.
		*/
		//If the colmesh is not subdivided, return the list containing all its collision shapes
		if (spHash < 0) return shapeList;
		
		//Find the boundaries for which to do collision checking
		xup *= height;
		yup *= height;
		zup *= height;
		var minx = x + min(xup, 0) - radius;
		var miny = y + min(yup, 0) - radius;
		var minz = z + min(zup, 0) - radius;
		var maxx = x + max(xup, 0) + radius;
		var maxy = y + max(yup, 0) + radius;
		var maxz = z + max(zup, 0) + radius;
		
		//If the capsule is fully outside the boundaries of the colmesh, return undefined
		if (maxx < minimum[0] || maxy < minimum[1] || maxz < minimum[2] || minx > maximum[0] || miny > maximum[1] || minz > maximum[2])
		{
			return undefined;
		}
		var x1 = floor((minx - originX) / regionSize);
		var y1 = floor((miny - originY) / regionSize);
		var z1 = floor((minz - originZ) / regionSize);
		var x2 = floor((maxx - originX) / regionSize);
		var y2 = floor((maxy - originY) / regionSize);
		var z2 = floor((maxz - originZ) / regionSize);
		
		//If the capsule only spans a single region, return that region
		if (x1 == x2 && y1 == y2 && z1 == z2)
		{
			var key = colmesh_get_key(x1, y1, z1);
			return spHash[? key];
		}
		
		//The capsule spans multiple regions. Loop through them all and add them to the temporary region list
		ds_list_clear(tempList);
		for (var xx = x1; xx <= x2; xx ++)
		{
			for (var yy = y1; yy <= y2; yy ++)
			{
				for (var zz = z1; zz <= z2; zz ++)
				{
					var key = colmesh_get_key(xx, yy, zz);
					var region = spHash[? key];
					if (is_undefined(region)){continue;}
					_addUnique(tempList, region);
				}
			}
		}
		return tempList;
	}
	
	#region Add shapes
	
	/// @func addShape(shape)
	static addShape = function(shape)
	{
		/*
			Adds the given shape to the ColMesh.
			Look in colmesh_shapes for a list of all the shapes that can be added.
			Typical usage:
				levelColmesh.addShape(new colmesh_sphere(x, y, z, radius));
		*/
		var _shape = _getShape(shape);
		var mm = _shape.getMinMax();
		_expandBoundaries(mm);
		if (_shape.type != eColMeshShape.Dynamic)
		{
			//Add the shape to the subdivision. Dynamic shapes take care of this themselves.
			_shape._addToSubdiv(self);
		}
		ds_list_add(shapeList, shape);
		return shape;
	}
	
	/// @func addTrigger(shape, colFunc*, rayFunc*)
	static addTrigger = function(shape, colFunc, rayFunc)
	{
		/*
			Create a trigger object. 
			This will not displace the player.
			colFunc is executed when the player collides with the object
			rayFunc is executed when a ray hits the object
		*/
		levelColmesh.addShape(shape);
		shape.setSolid(false);
		shape.setCollisionFunction(colFunc);
		shape.setRayFunction(rayFunc);
		return shape;
	}
	
	/// @func addDynamic(shape, M)
	static addDynamic = function(shape, M)
	{
		/*
			Adds a dynamic shape to the ColMesh.
			A dynamic is a special kind of shape container that can be moved, scaled and rotated dynamically.
			Look in colmesh_shapes for a list of all the shapes that can be added.
			
			You can also supply a whole different colmesh to a dynamic.
			Dynamics will not be saved when using colmesh.save or colmesh.writeToBuffer.
			
			Scaling must be uniform, ie. the same for all dimensions. Non-uniform scaling and shearing is automatically removed from the matrix.
			
			Typical usage:
				//Create event
				M = matrix_build(x, y, z, xangle, yangle, zangle, size, size, size); //Create a matrix
				dynamic = levelColmesh.addDynamic(new colmesh_sphere(0, 0, 0, radius), M); //Add a dynamic sphere to the colmesh, and save it to a variable called "dynamic"
				
				//Step event
				M = matrix_build(x, y, z, xangle, yangle, zangle, size, size, size); //Update the matrix
				dynamic.setMatrix(M, true); //"moving" should only be true if the orientation is updated every step
		*/
		return addShape(new colmesh_dynamic(shape, self, M, ds_list_size(shapeList)));
	}
	
	/// @func addMesh(mesh, [matrix])
	static addMesh = function(mesh, M)
	{
		/*
			Lets you add a mesh to the colmesh.
			"mesh" should be either a path to an OBJ file, an array containing buffers, or a buffer containing vertex info in the following format:
				3D position, 3x4 bytes
				3D normal, 3x4 bytes
				UV coords, 2x4 bytes
				Colour, 4 bytes
			This script does not return anything. The mesh as a whole does not have a handle. Triangles are added to the colmesh individually.
			
			Matrix is an optional argument in case you'd like to transform your mesh before adding it to the ColMesh
		*/
		var load = false;
		if (is_string(mesh))
		{
			load = true;
			mesh = colmesh_load_obj_to_buffer(mesh);
		}
		if (is_array(mesh))
		{
			load = true;
			var _mesh = buffer_create(1, buffer_fixed, 1);
			var num = array_length(mesh);
			var totalSize = 0;
			for (var i = 0; i < num; i ++) 
			{
				var buffSize = buffer_get_size(mesh[i]);
				var buffPos = totalSize;
				totalSize += buffSize;
				buffer_resize(mesh, totalSize);
				buffer_copy(mesh[i], 0, buffSize, mesh, buffPos);
			}
			mesh = _mesh;
		}
		if (mesh >= 0)
		{
			//Create triangle list from mesh
			var bytesPerVert = 3 * 4 + 3 * 4 + 2 * 4 + 4;
			var bytesPerTri = bytesPerVert * 3;
			var mBuffSize = buffer_get_size(mesh);
			var triNum = mBuffSize div bytesPerTri;
			array_resize(triangles, array_length(triangles) + triNum);
			for (var i = 0; i < triNum; i += 1)
			{
				static V = array_create(9);
				for (var j = 0; j < 3; j ++)
				{
					for (var k = 0; k < 3; k ++)
					{
						//Read vert position
					    V[j * 3 + k] = buffer_peek(mesh, i * bytesPerTri + j * bytesPerVert + k * 4, buffer_f32);
					}
				}
				if (is_array(M))
				{
					array_copy(V, 0, colmesh_matrix_transform_vertex(M, V[0], V[1], V[2]), 0, 3);
					array_copy(V, 3, colmesh_matrix_transform_vertex(M, V[3], V[4], V[5]), 0, 3);
					array_copy(V, 6, colmesh_matrix_transform_vertex(M, V[6], V[7], V[8]), 0, 3);
				}
				addTriangle(V);
			}
			if load
			{
				buffer_delete(mesh);
			}
			return true;
		}
		return false;
	}
	
	/// @func addTriangle(V[9])
	static addTriangle = function(V)
	{
		/*
			Add a single triangle to the colmesh.
		*/
		var shapeNum = ds_list_size(shapeList);
		if (array_length(triangles) <= shapeNum)
		{
			array_resize(triangles, shapeNum + 1);
		}
		//Construct normal vector
		var nx = (V[4] - V[1]) * (V[8] - V[2]) - (V[5] - V[2]) * (V[7] - V[1]);
		var ny = (V[5] - V[2]) * (V[6] - V[0]) - (V[3] - V[0]) * (V[8] - V[2]);
		var nz = (V[3] - V[0]) * (V[7] - V[1]) - (V[4] - V[1]) * (V[6] - V[0]);
		var l = nx * nx + ny * ny + nz * nz;
		if (l <= 0){return false;}
		l = 1 / sqrt(l);
		var tri = array_create(12);
		array_copy(tri, 0, V, 0, 9);
		tri[9]  = nx * l;
		tri[10] = ny * l;
		tri[11] = nz * l;
		addShape(tri);
		return -1;
	}
	
	/// @func removeShape(shape)
	static removeShape = function(shape)
	{
		/*
			Removes the given shape from the ColMesh.
			Cannot remove a mesh that has been added with colmesh.addMesh.
		*/
		var ind = ds_list_find_index(shapeList, shape);
		if (ind < 0){return false;}
		var _shape = _getShape(shape);
		_shape._removeFromSubdiv(self);
		ds_list_delete(shapeList, ind);
		return true;
	}
	
	#endregion
	
	/// @func displaceCapsule(x, y, z, xup, yup, zup, radius, height, slopeAngle, fast*, executeColFunc*)
	static displaceCapsule = function(x, y, z, xup, yup, zup, radius, height, slopeAngle, fast, executeColFunc)
	{	
		/*	
			Pushes a capsule out of a collision mesh.
			This will first use getRegion to get a list containing all shapes the capsule potentially could collide with.
			if "fast" is set to true, it sequentially performs collision checks with all those shapes, and return the result.
			
			If "fast" is set to false, it will process the shapes in two passes:
				The first pass sorts through all triangles in the region, and checks if there is a potential collision. 
				If there is, the triangle is added to a ds_priority based on the potential displacement of the capsule.
				The second pass makes the capsule avoid triangles, starting with the triangles that cause the greatest displacement.
			This will result in a more stable collision response for things like player characters. Fast mode is useful for moving the camera out of geometry.
			
			Returns an array of the following format:
			[x, y, z, Nx, Ny, Nz, collision (true or false)]
		*/
		var region = getRegion(x, y, z, xup, yup, zup, radius, height);
		return regionDisplaceCapsule(region, x, y, z, xup, yup, zup, radius, height, slopeAngle, fast, executeColFunc);
	}
	
	/// @func regionDisplaceCapsule(region, x, y, z, xup, yup, zup, radius, height, slopeAngle, fast*, executeColFunc*)
	static regionDisplaceCapsule = function(region, x, y, z, xup, yup, zup, radius, height, slopeAngle, _fast, _executeColFunc)
	{	
		/*
			Pushes a capsule out of a collision mesh.
			Slope is given in degrees, and is the maximum slope angle allowed before the capsule starts sliding downhill.
			
			if "fast" is set to true, it sequentially performs collision checks with all those shapes, and return the result.
			
			If "fast" is set to false, it will process the shapes in two passes:
				The first pass sorts through all triangles in the region, and checks if there is a potential collision. 
				If there is, the triangle is added to a ds_priority based on the potential displacement of the capsule.
				The second pass makes the capsule avoid triangles, starting with the triangles that cause the greatest displacement.
			This will result in a more stable collision response for things like player characters. Fast mode is useful for moving the camera out of geometry.
			
			Since dynamic shapes could potentially contain the colmesh itself, this script also needs a recursion counter to avoid infinite loops.
			You can change the maximum number of recursive calls by changing the cmMaxRecursion macro.
			
			Returns an array of the following format if there was a collision:
				[x, y, z, Nx, Ny, Nz, collision (true or false)]
		*/
		cmCol[0] = x;
		cmCol[1] = y;
		cmCol[2] = z;
		cmCol[6] = -1; //Until collision checking is done, this will store the highest dot product between triangle normal and up vector
		
		if (is_undefined(region))
		{
			//Exit the script if the given region does not exist
			return cmCol;
		}
		if (cmRecursion >= cmMaxRecursion)
		{
			//Exit the script if we've reached the recursive limit
			return cmCol;
		}
		var success = false;
		var i = ds_list_size(region);
		var fast = (is_undefined(_fast) ? false : _fast);
		var slope = ((slopeAngle <= 0) ? 1 : dcos(slopeAngle));
		var executeColFunc = (is_undefined(_executeColFunc) ? false : _executeColFunc);
		
		/*
			p is the center of the sphere for which we're doing collision checking. 
			If height is larger than 0, this will be overwritten by the closest point to the shape along the central axis of the capsule
		*/
		var p = cmCol;
		
		if (fast)
		{
			/*
				If we're doing fast collision checking, the collisions are done on a first-come-first-serve basis. 
				Fast collisions will also not save anything to the delta matrix queue
			*/
			repeat i
			{
				var shape = _getShape(region[| --i]);
				if (!shape.solid)
				{
					/*
						If this shape is not solid, continue the loop
					*/
					if (executeColFunc && variable_struct_exists(shape, "colFunc"))
					{
						++ cmRecursion;
						if (shape.capsuleCollision(cmCol[0], cmCol[1], cmCol[2], xup, yup, zup, radius, height))
						{
							shape.colFunc();
						}
						-- cmRecursion;
					}
					continue;
				}
				if (height != 0)
				{	
					//If height is larger than 0, this is a capsule, and we must find the most fitting point along the central axis of the capsule
					p = shape._capsuleGetRef(cmCol[0], cmCol[1], cmCol[2], xup, yup, zup, height);
				}
				++ cmRecursion;
				if (shape._displaceSphere(p[0], p[1], p[2], xup, yup, zup, height, radius, slope, fast))
				{
					success = true;
					if (executeColFunc && variable_struct_exists(shape, "colFunc"))
					{
						shape.colFunc();
					}
				}
				-- cmRecursion;
			}
			cmCol[6] = success;
			return cmCol;
		}
		
		if (cmRecursion == 0)
		{
			/*
				If this is the first recursive call, clear the transformation stack of the calling object
			*/
			cmTransform = -1;
			cmCallingObject = other;
			if (variable_instance_exists(cmCallingObject, "colMeshTransformQueue"))
			{
				if (ds_exists(cmCallingObject.colMeshTransformQueue, ds_type_queue))
				{
					cmTransform = cmCallingObject.colMeshTransformQueue;
					ds_queue_clear(cmTransform);
				}
			}
		}
		
		var P = priority[cmRecursion];
		if (P < 0)
		{
			/*
				We need a separate ds_priority for each recursive level, otherwise they'll mess with each other
			*/
			P = ds_priority_create();
			priority[cmRecursion] = P;
		}
		
		repeat i
		{
			/*
				First pass, find potential collisions and add them to the ds_priority
			*/
			var shapeInd = region[| --i];
			var shape = _getShape(shapeInd);
			if (!shape.solid && !executeColFunc){continue;}
			if (height != 0)
			{	
				//If height is larger than 0, this is a capsule, and we must find the most fitting point along the central axis of the capsule
				p = shape._capsuleGetRef(cmCol[0], cmCol[1], cmCol[2], xup, yup, zup, height);
			}
			var pri = shape._getPriority(p[0], p[1], p[2], radius * cmFirstPassRadius);
			if (pri >= 0)
			{
				ds_priority_add(P, shapeInd, pri);
			}
		}
		
		repeat (ds_priority_size(P))
		{
			/*
				Second pass, collide with the nearby shapes, starting with the closest one
			*/
			var shape = _getShape(ds_priority_delete_min(P));
			if (!shape.solid)
			{
				/*
					If this shape is not solid, execute its collision function if there is a collision
				*/
				if (executeColFunc && variable_struct_exists(shape, "colFunc"))
				{
					++ cmRecursion;
					if (shape.capsuleCollision(cmCol[0], cmCol[1], cmCol[2], xup, yup, zup, radius, height))
					{
						shape.colFunc();
					}
					-- cmRecursion;
				}
				continue;
			}
			if (height != 0)
			{	//If height is larger than 0, this is a capsule, and we must find the most fitting point along the central axis of the capsule
				p = shape._capsuleGetRef(cmCol[0], cmCol[1], cmCol[2], xup, yup, zup, height);
			}
			++ cmRecursion;
			if (shape._displaceSphere(p[0], p[1], p[2], xup, yup, zup, height, radius, slope, false))
			{
				success = true;
				if (executeColFunc && variable_struct_exists(shape, "colFunc"))
				{
					shape.colFunc();
				}
			}
			-- cmRecursion;
			if (success && slope < 1)
			{
				if (xup * cmCol[3] + yup * cmCol[4] + zup * cmCol[5] > slope)
				{
					slope = 1; //Set slope to 1 so that slope calculations are only done for the shape that displaces the player the most
				}
			}
		}
		cmCol[6] = success;
		return cmCol;
	}
	
	/// @func capsuleCollision(x, y, z, xup, yup, zup, radius, height)
	static capsuleCollision = function(x, y, z, xup, yup, zup, radius, height)
	{	
		/*	
			Returns whether or not the given capsule collides with the colmesh
		*/
		var region = getRegion(x, y, z, xup, yup, zup, radius, height);
		return regionCapsuleCollision(region, x, y, z, xup, yup, zup, radius, height);
	}
	
	/// @func regionCapsuleCollision(x, y, z, xup, yup, zup, radius, height)
	static regionCapsuleCollision = function(region, x, y, z, xup, yup, zup, radius, height)
	{
		/*
			Returns whether or not the given capsule collides with the given region
		*/
		if (is_undefined(region))
		{
			cmCol[0] = x;
			cmCol[1] = y;
			cmCol[2] = z;
			cmCol[6] = false;
			return cmCol;
		}
		if (cmRecursion >= cmMaxRecursion)
		{
			return false;
		}
		var i = ds_list_size(region);
		repeat (i)
		{
			++ cmRecursion;
			var col = _getShape(region[| --i]).capsuleCollision(x, y, z, xup, yup, zup, radius, height);
			-- cmRecursion;
			if (col) return true;
		}
		return false;
	}
	
	/// @func getDeltaMatrix()
	static getDeltaMatrix = function()
	{
		/*
			This is useful for getting the change in orientation in those cases where the player is standing on a dynamic shape.
			This script will "secretly" create a ds_queue in the calling object.
			If the player stands on a dynamic shape, its matrix and the inverse of its previous matrix are saved to that queue. This is done in colmesh_dynamic._displaceSphere.
			If the dynamic shape is inside multiple layers of colmeshes, their matrices and inverse previous matrices are also added to the queue.
			These matrices are all multiplied together in this function, resulting in their combined movements gathered in a single matrix.
			The reson they are saved to a queue and not just multiplied together immediately is that you usually want to get the delta matrix the step after the collision was performed.
			Since matrices are arrays, and arrays are stored by their handle, any changes to the arrays from the previous frame will also be applied to the delta matrix!
			
			Typical usage for making the player move:
				var D = levelColmesh.getDeltaMatrix();
				if (is_array(D))
				{
					var p = matrix_transform_vertex(D, x, y, z);
					x = p[0];
					y = p[1];
					z = p[2];
				}
				
			And for transforming a vector:
				var D = levelColmesh.getDeltaMatrix();
				if (is_array(D))
				{
					var p = matrix_transform_vector(D, xto, yto, zto);
					xto = p[0];
					yto = p[1];
					zto = p[2];
				}
			
			And for transforming a matrix:
				var D = levelColmesh.getDeltaMatrix();
				if (is_array(D))
				{
					colmesh_matrix_multiply_fast(D, targetMatrix, targetMatrix);
				}
		*/
		static initQueue = function()
		{
			other.colMeshTransformQueue = ds_queue_create();
			other.colMeshDeltaMat = matrix_build_identity();
			array_push(queueArray, other.colMeshTransformQueue);
		}
		if (!variable_instance_exists(other, "colMeshTransformQueue"))
		{	
			initQueue();
		}
		var queue = other.colMeshTransformQueue;
		if (!ds_exists(queue, ds_type_queue))
		{	
			initQueue();
			queue = other.colMeshTransformQueue;
		}
		var num = ds_queue_size(queue);
		if (num > 0)
		{
			//The first two matrices can simply be multiplied together
			var m = other.colMeshDeltaMat;
			var M = ds_queue_dequeue(queue); //The current world matrix
			var pI = ds_queue_dequeue(queue); //The inverse of the previous world matrix
			colmesh_matrix_multiply_fast(M, pI, m);
			repeat (num / 2 - 1)
			{
				//The subsequent matrices need to be multiplied with the target matrix in the correct order
				M = ds_queue_dequeue(queue); //The current world matrix
				pI = ds_queue_dequeue(queue); //The inverse of the previous world matrix
				colmesh_matrix_multiply_fast(m, pI, m);
				colmesh_matrix_multiply_fast(M, m, m);
			}
			return m;
		}
		return false;
	}
	
	/// @func getNearestPoint(x, y, z)
	static getNearestPoint = function(x, y, z)
	{
		/*
			Returns the nearest point on the colmesh to the given point.
			Only checks the region the point is in.
		*/
		return regionGetNearestPoint(getRegion(x, y, z, 0, 0, 0, 0, 0), x, y, z);
	}
	
	/// @func regionGetNearestPoint(region, x, y, z, radius)
	static regionGetNearestPoint = function(region, x, y, z)
	{	
		/*	
			Returns the nearest point in the region to the given point
		*/
		if (region < 0)
		{
			return false;
		}
		var i = ds_list_size(region);
		if (i == 0)
		{
			return false;
		}
		static ret = array_create(3);
		var minD = 9999999;
		ret[0] = x;
		ret[1] = y;
		ret[2] = z;
		repeat i
		{
			var shapeInd = abs(region[| --i]);
			var shape = _getShape(shapeList[| shapeInd]);
			var p = shape._getClosestPoint(x, y, z);
			var d = sqr(p[0] - x) + sqr(p[1] - y) + sqr(p[2] - z);
			if (d < minD)
			{
				minD = d;
				ret[0] = p[0];
				ret[1] = p[1];
				ret[2] = p[2];
			}
		}
		return ret;
	}
	
	#region Ray casting
	
	/// @func castRay(x1, y1, z1, x2, y2, z2, executeRayFunc*)
	static castRay = function(x1, y1, z1, x2, y2, z2, executeRayFunc)
	{
		/*
			Casts a ray from (x1, y1, z1) to (x2, y2, z2).
			If there was an intersection, it returns an array with the following format:
				[x, y, z, nX, nY, nZ, success]
			Returns false if there was no intersection.
		*/
		
		if (spHash < 0)
		{	//This ColMesh has not been subdivided. Cast a ray against all the shapes it contains
			return regionCastRay(shapeList, x1, y1, z1, x2, y2, z2);
		}
		if (!_constrain_ray(x1, y1, z1, x2, y2, z2))
		{	//The ray is fully outside the borders of this ColMesh
			cmRay[0] = x2;
			cmRay[1] = y2;
			cmRay[2] = z2;
			cmRay[6] = false;
			return cmRay;
		}
		x1 = cmRay[0];	y1 = cmRay[1];	z1 = cmRay[2];
		x2 = cmRay[3];	y2 = cmRay[4];	z2 = cmRay[5];
		var ldx = x2 - x1, ldy = y2 - y1, ldz = z2 - z1;
		var idx = (ldx != 0) ? 1 / ldx : 0;
		var idy = (ldy != 0) ? 1 / ldy : 0;
		var idz = (ldz != 0) ? 1 / ldz : 0;
		var incx = abs(idx) + (idx == 0);
		var incy = abs(idy) + (idy == 0);
		var incz = abs(idz) + (idz == 0);
		var ox = (x1 - originX) / regionSize;
		var oy = (y1 - originY) / regionSize;
		var oz = (z1 - originZ) / regionSize;
		var currX = ox, currY = oy, currZ = oz;
		var key = colmesh_get_key(floor(currX), floor(currY), floor(currZ));
		var prevKey = key;
		var t = 0, _t = 0;
		while (t < 1)
		{	//Find which region needs to travel the shortest to cross a wall
			var tMaxX = - frac(currX) * idx;
			var tMaxY = - frac(currY) * idy;
			var tMaxZ = - frac(currZ) * idz;
			if (tMaxX <= 0){tMaxX += incx;}
			if (tMaxY <= 0){tMaxY += incy;}
			if (tMaxZ <= 0){tMaxZ += incz;}
			if (tMaxX < tMaxY)
			{
				if (tMaxX < tMaxZ)
				{
					_t += tMaxX;
					currX = round((ox + ldx * _t));
					currY = (oy + ldy * _t);
					currZ = (oz + ldz * _t);
					key = colmesh_get_key(currX - (ldx < 0), floor(currY), floor(currZ));
				}
				else
				{
					_t += tMaxZ;
					currX = (ox + ldx * _t);
					currY = (oy + ldy * _t);
					currZ = round((oz + ldz * _t));
					key = colmesh_get_key(floor(currX), floor(currY), currZ - (ldz < 0));
				}
			}
			else
			{
				if (tMaxY < tMaxZ)
				{
					_t += tMaxY;
					currX = (ox + ldx * _t);
					currY = round((oy + ldy * _t));
					currZ = (oz + ldz * _t);
					key = colmesh_get_key(floor(currX), currY - (ldy < 0), floor(currZ));
				}
				else
				{
					_t += tMaxZ;
					currX = (ox + ldx * _t);
					currY = (oy + ldy * _t);
					currZ = round((oz + ldz * _t));
					key = colmesh_get_key(floor(currX), floor(currY), currZ - (ldz < 0));
				}
			}
			//Check for ray mesh intersections in the current region
			t = min(1, _t * regionSize);
			var region = spHash[? prevKey];
			if (!is_undefined(region))
			{
				if (is_array(regionCastRay(region, x1, y1, z1, x1 + ldx * t, y1 + ldy * t, z1 + ldz * t, executeRayFunc)))
				{
					return cmRay;
				}
			}
			prevKey = key;
		}
		return false;
	}
	
	/// @func regionCastRay(region, x1, y1, z1, x2, y2, z2, executeRayFunc*)
	static regionCastRay = function(region, x1, y1, z1, x2, y2, z2, _executeRayFunc) 
	{	
		/*	
			This ray casting script is faster than the regular colmesh raycasting script.
			However, it will only cast a ray onto the shapes in the current region, and is as such a "short-range" ray.
			If there was an intersection, it returns an array with the following format:
				[x, y, z, nX, nY, nZ, success]
			Returns false if there was no intersection.
		*/
		var success = false;
		if (is_undefined(region) || (x1 == x2 && y1 == y2 && z1 == z2))
		{
			return false;
		}
		if (cmRecursion == 0)
		{
			cmCallingObject = other;
		}
		if (cmRecursion >= cmMaxRecursion)
		{
			//Exit the script if we've reached the recursive limit
			return false;
		}
		var executeRayFunc = (is_undefined(_executeRayFunc) ? false : _executeRayFunc);
		cmRay[0] = x2;
		cmRay[1] = y2;
		cmRay[2] = z2;
		cmRay[6] = -1;
		var i = ds_list_size(region);
		repeat i
		{
			static temp = array_create(7);
			var shape = _getShape(region[| -- i]);
			if (!shape.solid){array_copy(temp, 0, cmRay, 0, 7);}
			++ cmRecursion;
			var ray = shape._castRay(x1, y1, z1);
			-- cmRecursion;
			if (ray)
			{
				if (executeRayFunc && !variable_struct_exists(shape, "rayFunc"))
				{
					if (!shape.rayFunc())
					{
						//The custom ray function returned false. Discard the collision and continue the loop
						array_copy(cmRay, 0, temp, 0, 7);
						continue;
					}
				}
				success = true;
			}
		}
		if (success)
		{
			return cmRay;
		}
		return false;
	}
		
	#endregion
	
	#region Supplementaries
	
	/// @func _expandBoundaries(AABB[6])
	static _expandBoundaries = function(AABB)
	{
		/*
			Expands the boundaries of the ColMesh. This will only come into effect once the ColMesh is subdivided.
		*/
		minimum[0] = min(minimum[0], AABB[0]);
		minimum[1] = min(minimum[1], AABB[1]);
		minimum[2] = min(minimum[2], AABB[2]);
		maximum[0] = max(maximum[0], AABB[3]);
		maximum[1] = max(maximum[1], AABB[4]);
		maximum[2] = max(maximum[2], AABB[5]);
	}
	
	/// @func _addUnique(target, source)
	static _addUnique = function(r1, r2)
	{
		/*
			Adds the unique list entries from source to target list
		*/
		if (r2 < 0)
		{
			return false;
		}
		if (ds_list_size(r1) == 0)
		{	//The target list is empty. Copy over the contents of r2 and call it a day
			ds_list_copy(r1, r2);
			return true;
		}
		var i = ds_list_size(r2);
		repeat i
		{
			var shapeInd = r2[| --i];
			if (ds_list_find_index(r1, shapeInd) < 0)
			{
				ds_list_add(r1, shapeInd);
			}
		}
		return true;
	}
	
	/// @func _getShape(shape)
	static _getShape = function(shape)
	{
		/*
			A supplementary function.
			If the given shape is a real value, it must contain a triangle index. 
			It will then load that triangle into the colmesh, and return the index of the colmesh.
			If it does not contain a real, the given shape is returned.
		*/
		if (is_array(shape))
		{	
			triangle = shape; 
			return self;
		}
		return shape;
	}
	
	/// @func _constrain_ray(x1, y1, z1, x2, y2, z2)
	static _constrain_ray = function(x1, y1, z1, x2, y2, z2) 
	{
		/*
			This script will truncate the ray from (x1, y1, z1) to (x2, y2, z2) so that it fits inside the bounding box of the colmesh.
			Returns false if the ray is fully outside the bounding box.
		*/
		///////////////////////////////////////////////////////////////////
		//Convert from world coordinates to local coordinates
		var sx = (maximum[0] - minimum[0]) * .5;
		var sy = (maximum[1] - minimum[1]) * .5;
		var sz = (maximum[2] - minimum[2]) * .5;
		var mx = (maximum[0] + minimum[0]) * .5;
		var my = (maximum[1] + minimum[1]) * .5;
		var mz = (maximum[2] + minimum[2]) * .5;
		x1 = (x1 - mx) / sx;
		y1 = (y1 - my) / sy;
		z1 = (z1 - mz) / sz;
		x2 = (x2 - mx) / sx;
		y2 = (y2 - my) / sy;
		z2 = (z2 - mz) / sz;
	
		if ((x1 < -1 && x2 < -1) || (y1 < -1 && y2 < -1) || (z1 < -1 && z2 < -1) || (x1 > 1 && x2 > 1) || (y1 > 1 && y2 > 1) || (z1 > 1 && z2 > 1))
		{	//The ray is fully outside the bounding box, and we can end the algorithm here
			return false;
		}
	
		var intersection = true;
		if (x1 < -1 || x2 < -1 || y1 < -1 || y2 < -1 || z1 < -1 || z2 < -1 || x1 > 1 || x2 > 1 || y1 > 1 || y2 > 1 || z1 > 1 || z2 > 1)
		{
			intersection = false;
		}
	
		///////////////////////////////////////////////////////////////////
		//Check X dimension
		var d = x2 - x1;
		if (d != 0)
		{
			//Check outside
			var s = sign(d);
			var t = (- s - x1) / d;
			if (abs(x1) > 1 && t >= 0 && t <= 1)
			{
				var itsY = lerp(y1, y2, t);
				var itsZ = lerp(z1, z2, t);
				if (abs(itsY) <= 1 && abs(itsZ) <= 1)
				{
					x1 = - s;
					y1 = itsY;
					z1 = itsZ;
					intersection = true;
				}
			}
			//Check inside
			var t = (s - x1) / d;
			if (t >= 0 && t <= 1)
			{
				var itsY = lerp(y1, y2, t);
				var itsZ = lerp(z1, z2, t);
				if (abs(itsY) <= 1 && abs(itsZ) <= 1)
				{
					x2 = s;
					y2 = itsY;
					z2 = itsZ;
					intersection = true;
				}
			}
		}
		///////////////////////////////////////////////////////////////////
		//Check Y dimension
		var d = y2 - y1;
		if (d != 0)
		{
			//Check outside
			var s = sign(d);
			var t = (- s - y1) / d;
			if (abs(y1) > 1 && t >= 0 && t <= 1)
			{
				var itsX = lerp(x1, x2, t);
				var itsZ = lerp(z1, z2, t);
				if (abs(itsX) <= 1 && abs(itsZ) <= 1)
				{
					x1 = itsX;
					y1 = - s;
					z1 = itsZ;
					intersection = true;
				}
			}
			//Check inside
			var t = (s - y1) / d;
			if (t >= 0 && t <= 1)
			{
				var itsX = lerp(x1, x2, t);
				var itsZ = lerp(z1, z2, t);
				if (abs(itsX) <= 1 && abs(itsZ) <= 1)
				{
					x2 = itsX;
					y2 = s;
					z2 = itsZ;
					intersection = true;
				}
			}
		}
		///////////////////////////////////////////////////////////////////
		//Check Z dimension
		var d = z2 - z1;
		if (d != 0)
		{
			//Check outside
			var s = sign(d);
			var t = (- s - z1) / d;
			if (abs(z1) > 1 && t >= 0 && t <= 1)
			{
				var itsX = lerp(x1, x2, t);
				var itsY = lerp(y1, y2, t);
				if (abs(itsX) <= 1 && abs(itsY) <= 1)
				{
					x1 = itsX;
					y1 = itsY;
					z1 = - s;
					intersection = true;
				}
			}
			//Check inside
			var t = (s - z1) / d;
			if (t >= 0 && t <= 1)
			{
				var itsX = lerp(x1, x2, t);
				var itsY = lerp(y1, y2, t);
				if (abs(itsY) <= 1 && abs(itsY) <= 1)
				{
					x2 = itsX;
					y2 = itsY;
					z2 = s;
					intersection = true;
				}
			}
		}
		if !intersection
		{
			return false;
		}

		///////////////////////////////////////////////////////////////////
		//Return the point of intersection in world space
		cmRay[0] = (x1 * sx + mx);
		cmRay[1] = (y1 * sy + my);
		cmRay[2] = (z1 * sz + mz);
		cmRay[3] = (x2 * sx + mx);
		cmRay[4] = (y2 * sy + my);
		cmRay[5] = (z2 * sz + mz);
		return true;
	}
		
	#endregion
	
	#region Saving and loading
	
	/// @func save(path)
	static save = function(path)
	{
		/*
			Saves the colmesh to a file.
			This function will not work in HTML5.
			For HTML5 you need to create a buffer, write the colmesh to it with colmesh.writeToBuffer, and save it with buffer_save_async.
		*/
		var buff = buffer_create(1, buffer_grow, 1);
		writeToBuffer(buff);
		buffer_resize(buff, buffer_tell(buff));
		buffer_save(buff, path);
		buffer_delete(buff);
	}
	
	/// @func load(path)
	static load = function(path)
	{
		/*
			Loads the colmesh from a file.
			This function will not work in HTML5.
			For HTML5 you need to load a buffer asynchronously, and read from that using colmesh.readFromBuffer.
		*/
		var buff = buffer_load(path);
		if (buff < 0)
		{
			colmesh_debug_message("colmesh.load: Could not find file " + string(path));
			return false;
		}
		var success = readFromBuffer(buff);
		buffer_delete(buff);
		return success;
	}
	
	/// @func writeToBuffer(saveBuff)
	static writeToBuffer = function(saveBuff)
	{
		/*
			Writes the colmesh to a buffer.
			This will not save dynamic shapes!
		*/
		var debugTime = current_time;
		var tempBuff = buffer_create(1, buffer_grow, 1);
		var shapeNum = ds_list_size(shapeList);
		
		//Write shape list
		buffer_write(tempBuff, buffer_u32, shapeNum);
		buffer_write(tempBuff, buffer_u32, array_length(triangles));
		for (var i = 0; i < shapeNum; i ++)
		{
			with _getShape(shapeList[| i])
			{
				if (!solid)
				{
					//Do not write non-solid objects
					buffer_write(tempBuff, buffer_u8, eColMeshShape.None);
					continue;
				}
				buffer_write(tempBuff, buffer_u8, type);
				switch type
				{
					case eColMeshShape.Mesh:
						for (var j = 0; j < 9; j ++)
						{
							buffer_write(tempBuff, buffer_f32, triangle[j]);
						}
						break;
					case eColMeshShape.Sphere:
						buffer_write(tempBuff, buffer_f32, x);
						buffer_write(tempBuff, buffer_f32, y);
						buffer_write(tempBuff, buffer_f32, z);
						buffer_write(tempBuff, buffer_f32, R);
						break;
					case eColMeshShape.Capsule:
						buffer_write(tempBuff, buffer_f32, x);
						buffer_write(tempBuff, buffer_f32, y);
						buffer_write(tempBuff, buffer_f32, z);
						buffer_write(tempBuff, buffer_f32, xup);
						buffer_write(tempBuff, buffer_f32, yup);
						buffer_write(tempBuff, buffer_f32, zup);
						buffer_write(tempBuff, buffer_f32, R);
						buffer_write(tempBuff, buffer_f32, H);
						break;
					case eColMeshShape.Cylinder:
						buffer_write(tempBuff, buffer_f32, x);
						buffer_write(tempBuff, buffer_f32, y);
						buffer_write(tempBuff, buffer_f32, z);
						buffer_write(tempBuff, buffer_f32, xup);
						buffer_write(tempBuff, buffer_f32, yup);
						buffer_write(tempBuff, buffer_f32, zup);
						buffer_write(tempBuff, buffer_f32, R);
						buffer_write(tempBuff, buffer_f32, H);
						break;
					case eColMeshShape.Torus:
						buffer_write(tempBuff, buffer_f32, x);
						buffer_write(tempBuff, buffer_f32, y);
						buffer_write(tempBuff, buffer_f32, z);
						buffer_write(tempBuff, buffer_f32, xup);
						buffer_write(tempBuff, buffer_f32, yup);
						buffer_write(tempBuff, buffer_f32, zup);
						buffer_write(tempBuff, buffer_f32, R);
						buffer_write(tempBuff, buffer_f32, r);
						break;
					case eColMeshShape.Cube:
						buffer_write(tempBuff, buffer_f32, x);
						buffer_write(tempBuff, buffer_f32, y);
						buffer_write(tempBuff, buffer_f32, z);
						buffer_write(tempBuff, buffer_f32, hsize);
						break;
					case eColMeshShape.Block:
						buffer_write(tempBuff, buffer_f32, M[0]);
						buffer_write(tempBuff, buffer_f32, M[1]);
						buffer_write(tempBuff, buffer_f32, M[2]);
						buffer_write(tempBuff, buffer_f32, M[4]);
						buffer_write(tempBuff, buffer_f32, M[5]);
						buffer_write(tempBuff, buffer_f32, M[6]);
						buffer_write(tempBuff, buffer_f32, M[8]);
						buffer_write(tempBuff, buffer_f32, M[9]);
						buffer_write(tempBuff, buffer_f32, M[10]);
						buffer_write(tempBuff, buffer_f32, M[12]);
						buffer_write(tempBuff, buffer_f32, M[13]);
						buffer_write(tempBuff, buffer_f32, M[14]);
						break;
				}
			}
		}

		//Write subdivision to buffer
		if (spHash >= 0)
		{
			buffer_write(tempBuff, buffer_u32, ds_map_size(spHash));
			buffer_write(tempBuff, buffer_f32, regionSize);
			buffer_write(tempBuff, buffer_f32, originX);
			buffer_write(tempBuff, buffer_f32, originY);
			buffer_write(tempBuff, buffer_f32, originZ);
			
			var key = ds_map_find_first(spHash);
			while (!is_undefined(key))
			{
				var region = spHash[? key];
				var num = ds_list_size(region);
				var n = num;
				buffer_write(tempBuff, buffer_u64, key);
				var numPos = buffer_tell(tempBuff);
				buffer_write(tempBuff, buffer_u32, num);
				repeat n
				{
					var shapeInd = region[| --n];
					buffer_write(tempBuff, buffer_u32, ds_list_find_index(shapeList, shapeInd));
				}
				buffer_poke(tempBuff, numPos, buffer_u32, num);
				key = ds_map_find_next(spHash, key);
			}
		}
		else
		{
			buffer_write(tempBuff, buffer_u32, 0);
		}

		//Write to savebuff
		var buffSize = buffer_tell(tempBuff);
		buffer_write(saveBuff, buffer_string, "ColMesh v3");
		buffer_write(saveBuff, buffer_u64, buffSize);
		buffer_copy(tempBuff, 0, buffSize, saveBuff, buffer_tell(saveBuff));
		buffer_seek(saveBuff, buffer_seek_relative, buffSize);
		colmesh_debug_message("Script colmesh.writeToBuffer: Wrote colmesh to buffer in " + string(current_time - debugTime) + " milliseconds");

		//Clean up
		buffer_delete(tempBuff);
	}
		
	/// @func readFromBuffer(loadBuff)
	static readFromBuffer = function(loadBuff) 
	{
		/*
			Reads a collision mesh from the given buffer.
		*/
		var debugTime = current_time;
		clear();
		
		//Make sure this is a colmesh
		var version = 3;
		var headerText = buffer_read(loadBuff, buffer_string);
		var buffSize = buffer_read(loadBuff, buffer_u64);
		var tempBuff = buffer_create(buffSize, buffer_fixed, 1);
		buffer_copy(loadBuff, buffer_tell(loadBuff), buffSize, tempBuff, 0);
		buffer_seek(loadBuff, buffer_seek_relative, buffSize);
		
		switch headerText
		{
			case "ColMesh v3":
				version = 3;
				break;
			case "ColMesh v2":
				version = 2;
				regionSize = buffer_read(tempBuff, buffer_f32);
				buffer_seek(tempBuff, buffer_seek_relative, 36);
				subdivide(regionSize);
				break;
			case "ColMesh":
				version = 1;
				regionSize = buffer_read(tempBuff, buffer_f32);
				buffer_seek(tempBuff, buffer_seek_relative, 54);
				subdivide(regionSize);
				break;
			default:
				colmesh_debug_message("ERROR in script colmesh.readFromBuffer: Could not find colmesh in buffer.");
				return false;
		}
		
		//Read shape list
		var shapeNum = buffer_read(tempBuff, buffer_u32);
		var triNum = buffer_read(tempBuff, buffer_u32);
		array_resize(triangles, triNum);
		for (var i = 0; i < shapeNum; i ++)
		{
			switch buffer_read(tempBuff, buffer_u8)
			{
				case eColMeshShape.Mesh:
					static V = array_create(9);
					for (var j = 0; j < 9; j ++)
					{
						V[j] = buffer_read(tempBuff, buffer_f32);
					}
					addTriangle(V);
					break;
				case eColMeshShape.Sphere:
					var _x = buffer_read(tempBuff, buffer_f32);
					var _y = buffer_read(tempBuff, buffer_f32);
					var _z = buffer_read(tempBuff, buffer_f32);
					var R  = buffer_read(tempBuff, buffer_f32);
					addShape(new colmesh_sphere(_x, _y, _z, R));
					break;
				case eColMeshShape.Capsule:
					var _x  = buffer_read(tempBuff, buffer_f32);
					var _y  = buffer_read(tempBuff, buffer_f32);
					var _z  = buffer_read(tempBuff, buffer_f32);
					var xup = buffer_read(tempBuff, buffer_f32);
					var yup = buffer_read(tempBuff, buffer_f32);
					var zup = buffer_read(tempBuff, buffer_f32);
					var R   = buffer_read(tempBuff, buffer_f32);
					var H   = buffer_read(tempBuff, buffer_f32);
					addShape(new colmesh_capsule(_x, _y, _z, xup, yup, zup, R, H));
					break;
				case eColMeshShape.Cylinder:
					var _x  = buffer_read(tempBuff, buffer_f32);
					var _y  = buffer_read(tempBuff, buffer_f32);
					var _z  = buffer_read(tempBuff, buffer_f32);
					var xup = buffer_read(tempBuff, buffer_f32);
					var yup = buffer_read(tempBuff, buffer_f32);
					var zup = buffer_read(tempBuff, buffer_f32);
					var R   = buffer_read(tempBuff, buffer_f32);
					var H   = buffer_read(tempBuff, buffer_f32);
					addShape(new colmesh_cylinder(_x, _y, _z, xup, yup, zup, R, H));
					break;
				case eColMeshShape.Torus:
					var _x  = buffer_read(tempBuff, buffer_f32);
					var _y  = buffer_read(tempBuff, buffer_f32);
					var _z  = buffer_read(tempBuff, buffer_f32);
					var xup = buffer_read(tempBuff, buffer_f32);
					var yup = buffer_read(tempBuff, buffer_f32);
					var zup = buffer_read(tempBuff, buffer_f32);
					var R   = buffer_read(tempBuff, buffer_f32);
					var r   = buffer_read(tempBuff, buffer_f32);
					addShape(new colmesh_torus(_x, _y, _z, xup, yup, zup, R, r));
					break;
				case eColMeshShape.Cube:
					var _x    = buffer_read(tempBuff, buffer_f32);
					var _y    = buffer_read(tempBuff, buffer_f32);
					var _z    = buffer_read(tempBuff, buffer_f32);
					var hsize = buffer_read(tempBuff, buffer_f32);
					addShape(new colmesh_cube(_x, _y, _z, hsize * 2));
					break;
				case eColMeshShape.Block:
					static M = array_create(16);
					M[15] = 1;
					M[0]  = buffer_read(tempBuff, buffer_f32);
					M[1]  = buffer_read(tempBuff, buffer_f32);
					M[2]  = buffer_read(tempBuff, buffer_f32);
					M[4]  = buffer_read(tempBuff, buffer_f32);
					M[5]  = buffer_read(tempBuff, buffer_f32);
					M[6]  = buffer_read(tempBuff, buffer_f32);
					M[8]  = buffer_read(tempBuff, buffer_f32);
					M[9]  = buffer_read(tempBuff, buffer_f32);
					M[10] = buffer_read(tempBuff, buffer_f32);
					M[12] = buffer_read(tempBuff, buffer_f32);
					M[13] = buffer_read(tempBuff, buffer_f32);
					M[14] = buffer_read(tempBuff, buffer_f32);
					addShape(new colmesh_block(M));
					break;
				case eColMeshShape.None:
				case eColMeshShape.Dynamic:
					//Dynamic shapes are NOT saved! This is a failsafe so that the order of objects added after the dynamic is kept.
					addShape(new colmesh_none());
					break;
			}
		}

		//Read subdivision
		var num = buffer_read(tempBuff, buffer_u32);
		if (num >= 0 && version == 3)
		{
			regionSize = buffer_read(tempBuff, buffer_f32);
			originX	= buffer_read(tempBuff, buffer_f32);
			originY	= buffer_read(tempBuff, buffer_f32);
			originZ	= buffer_read(tempBuff, buffer_f32);
			spHash = ds_map_create();
			repeat num
			{
				var region = ds_list_create();
				var key = buffer_read(tempBuff, buffer_u64);
				repeat buffer_read(tempBuff, buffer_u32)
				{
					var shape = shapeList[| buffer_read(tempBuff, buffer_u32)];
					if (is_struct(shape))
					{
						if (shape.type == eColMeshShape.Dynamic || shape.type == eColMeshShape.None)
						{
							continue;
						}
					}
					ds_list_add(region, shape);
				}
				spHash[? key] = region;
			}
		}

		//Clean up and return result
		colmesh_debug_message("Script colmesh.readFromBuffer: Read colmesh from buffer in " + string(current_time - debugTime) + " milliseconds");
		buffer_delete(tempBuff);
		return true;
	}

	#endregion
}

function colmesh_debug_message(str)
{
	/*
		Only show debug messages if cmDebug is set to true
	*/
	if cmDebug
	{
		show_debug_message(str);
	}
}

function colmesh_load_obj_to_buffer(filename) 
{
	static read_face = function(faceList, str) 
	{
		gml_pragma("forceinline");
		str = string_delete(str, 1, string_pos(" ", str))
		if (string_char_at(str, string_length(str)) == " ")
		{
			//Make sure the string doesn't end with an empty space
			str = string_copy(str, 0, string_length(str) - 1);
		}
		var triNum = string_count(" ", str);
		var vertString = array_create(triNum + 1);
		for (var i = 0; i < triNum; i ++)
		{
			//Add vertices in a triangle fan
			vertString[i] = string_copy(str, 1, string_pos(" ", str));
			str = string_delete(str, 1, string_pos(" ", str));
		}
		vertString[i--] = str;
		while i--
		{
			for (var j = 2; j >= 0; j --)
			{
				var vstr = vertString[(i + j) * (j > 0)];
				var v = 0, n = 0, t = 0;
				//If the vertex contains a position, texture coordinate and normal
				if string_count("/", vstr) == 2 and string_count("//", vstr) == 0
				{
					v = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					vstr = string_delete(vstr, 1, string_pos("/", vstr));
					t = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					n = abs(real(string_delete(vstr, 1, string_pos("/", vstr))));
				}
				//If the vertex contains a position and a texture coordinate
				else if string_count("/", vstr) == 1
				{
					v = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					t = abs(real(string_delete(vstr, 1, string_pos("/", vstr))));
				}
				//If the vertex only contains a position
				else if (string_count("/", vstr) == 0)
				{
					v = abs(real(vstr));
				}
				//If the vertex contains a position and normal
				else if string_count("//", vstr) == 1
				{
					vstr = string_replace(vstr, "//", "/");
					v = abs(real(string_copy(vstr, 1, string_pos("/", vstr) - 1)));
					n = abs(real(string_delete(vstr, 1, string_pos("/", vstr))));
				}
				ds_list_add(faceList, [v-1, n-1, t-1]);
			}
		}
	}
	static read_line = function(str) 
	{
		gml_pragma("forceinline");
		str = string_delete(str, 1, string_pos(" ", str));
		var retNum = string_count(" ", str) + 1;
		var ret = array_create(retNum);
		for (var i = 0; i < retNum; i ++)
		{
			var pos = string_pos(" ", str);
			if (pos == 0)
			{
				pos = string_length(str);
				ret[i] = real(string_copy(str, 1, pos)); 
				break;
			}
			ret[i] = real(string_copy(str, 1, pos)); 
			str = string_delete(str, 1, pos);
		}
		return ret;
	}
	var file = file_text_open_read(filename);
	if (file == -1){colmesh_debug_message("Failed to load model " + string(filename)); return -1;}
	colmesh_debug_message("Script colmesh_load_obj_to_buffer: Loading obj file " + string(filename));

	//Create the necessary lists
	var V = ds_list_create();
	var N = ds_list_create();
	var T = ds_list_create();
	var F = ds_list_create();

	//Read .obj as textfile
	var str, type;
	while !file_text_eof(file)
	{
		str = string_replace_all(file_text_read_string(file),"  "," ");
		//Different types of information in the .obj starts with different headers
		switch string_copy(str, 1, string_pos(" ", str)-1)
		{
			//Load vertex positions
			case "v":
				ds_list_add(V, read_line(str));
				break;
			//Load vertex normals
			case "vn":
				ds_list_add(N, read_line(str));
				break;
			//Load vertex texture coordinates
			case "vt":
				ds_list_add(T, read_line(str));
				break;
			//Load faces
			case "f":
				read_face(F, str);
				break;
		}
		file_text_readln(file);
	}
	file_text_close(file);

	//Loop through the loaded information and generate a model
	var vnt, vertNum, mbuff, vbuff, v, n, t;
	var bytesPerVert = 3 * 4 + 3 * 4 + 2 * 4 + 4 * 1;
	vertNum = ds_list_size(F);
	mbuff = buffer_create(vertNum * bytesPerVert, buffer_fixed, 1);
	for (var f = 0; f < vertNum; f ++)
	{
		vnt = F[| f];
		
		//Add the vertex to the model buffer
		v = V[| vnt[0]];
		if !is_array(v){v = [0, 0, 0];}
		buffer_write(mbuff, buffer_f32, v[0]);
		buffer_write(mbuff, buffer_f32, v[2]);
		buffer_write(mbuff, buffer_f32, v[1]);
		
		n = N[| vnt[1]];
		if !is_array(n){n = [0, 0, 1];}
		buffer_write(mbuff, buffer_f32, n[0]);
		buffer_write(mbuff, buffer_f32, n[2]);
		buffer_write(mbuff, buffer_f32, n[1]);
		
		t = T[| vnt[2]];
		if !is_array(t){t = [0, 0];}
		buffer_write(mbuff, buffer_f32, t[0]);
		buffer_write(mbuff, buffer_f32, 1-t[1]);
		
		buffer_write(mbuff, buffer_u32, c_white);
	}
	ds_list_destroy(F);
	ds_list_destroy(V);
	ds_list_destroy(N);
	ds_list_destroy(T);
	colmesh_debug_message("Script colmesh_load_obj_to_buffer: Successfully loaded obj " + string(filename));
	return mbuff
}

function colmesh_convert_smf(model)
{
	/*
		This script was requested by somebody on the forums.
		Creates a ColMesh-compatible buffer from an SMF model.
		Remember to destroy the buffer after you're done using it!
	*/
	var mBuff = model.mBuff;
	var num = array_length(mBuff);
	
	var newBuff = buffer_create(1, buffer_grow, 1);
	var size = 0;
	
	//Convert to ColMesh-compatible format
	var num = array_length(mBuff);
	var SMFbytesPerVert = 44;
	var targetBytesPerVert = 36;
	for (var m = 0; m < num; m ++)
	{
		var buff = mBuff[m];
		var buffSize = buffer_get_size(buff);
		var vertNum = buffSize div SMFbytesPerVert;
		for (var i = 0; i < vertNum; i ++)
		{
			//Copy position and normal
			buffer_copy(buff, i * SMFbytesPerVert, targetBytesPerVert, newBuff, size + i * targetBytesPerVert);
		}
		size += buffSize;
	}
	
	buffer_resize(newBuff, size);
	return newBuff;
}

function colmesh_get_key(x, y, z)
{
	/*
		Returns a unique hash for any 3D integer position
		Based on the algorithm described here:
			https://dmauro.com/post/77011214305/a-hashing-function-for-x-y-z-coordinates
	*/
    x = (x >= 0) ? 2 * x : - 2 * x - 1;
    y = (y >= 0) ? 2 * y : - 2 * y - 1;
    z = (z >= 0) ? 2 * z : - 2 * z - 1;
	
	if (z > x)
	{
		if (x > y)
		{
			return z * z * z + 2 * z * z + z + y + x * x;
		}
		if (z > y)
		{
			return z * z * z + 2 * z * z + z + y + y * y + x;
		}
		return y * y * y + 2 * y * z + z + y + x;
	}
	if (x > y)
	{
		return x * x * x + 2 * x * z + z + y;
	}
	return y * y * y + 2 * y * z + z + y + x;
}