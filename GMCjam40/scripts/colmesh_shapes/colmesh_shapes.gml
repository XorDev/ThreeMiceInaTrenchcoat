/*
	ColMesh - 3D Collisions Made Easy!
	TheSnidr 2021
	
	License
	The ColMesh system is licensed under a CreativeCommons Attribution 4.0 International License
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

enum eColMeshShape
{
	//Do not change the order of these. Changing the order will break saving and loading. Add new entries before "Num".
	Mesh, Sphere, Capsule, Cylinder, Torus, Cube, Block, Dynamic, None, Disk, Cone, Num
}

function colmesh_shapes() constructor
{
	/*
		This is the parent struct for all the other possible collision shapes!
		This is also the parent struct for the ColMesh itself. Weird, huh?
		That is because of some optimizations for triangle meshes. It's much faster to read
		triangle info from a ds_grid than it is to store every triangle as its own struct, 
		so triangles are only saved as indices, and read from the ds_grid when necessary.
		
		This struct contains a bunch of functions that are overwritten for the child structs.
	*/
	type = eColMeshShape.Mesh;
	solid = true;
	
	/// @func setSolid(solid)
	static setSolid = function(_solid)
	{
		/*
			Toggle solid for this shape. Non-solid objects will not displace other objects.
			Typically useful for collectible objects like coins, or trigger objects
		*/
		solid = _solid;
	}
	
	/// @func setCollisionFunction(colFunc)
	static setCollisionFunction = function(_colFunc)
	{
		/*
			This function lets you give the shape a custom collision function.
			This is useful for example for collisions with collectible objects like coins and powerups.
            Collision functions are NOT saved when writing a ColMesh to a buffer!
			
			colFunc will be executed when executeColFunc is enabled and there is a collision with colmesh.displaceCapsule
				You have access to the following global variables:
					cmCol - An array containing the current position of the calling object
					cmCallingObject - The instance that is using colmesh.displaceCapsule
		*/
		colFunc = _colFunc;
	}
	
	/// @func setRayFunction(rayFunc)
	static setRayFunction = function(_rayFunc)
	{
		/*
			This function lets you give the shape a custom function that is executed if a ray hits the shape.
			
			rayFunc will be executed if the object is hit by a ray with colmesh.castRay. 
				You have access to the following global variables:
					cmRay - An array containing the position of intersection with the non-solid object.
					cmCallingObject - The instance that is using colmesh.castRay
				IMPORTANT: rayFunc should return true if the ray should stop once it hits the shape, or false if the ray should ignore the object, after rayFunc has been executed!
		*/
		rayFunc = _rayFunc;
	}
	
	#region Shared functions
	
	/// @func capsuleCollision(x, y, z, xup, yup, zup, radius, height)
	static capsuleCollision = function(x, y, z, xup, yup, zup, radius, height)
	{
		/*
			Returns true if the given capsule collides with the shape
		*/
		if (height != 0)
		{
			var p = _capsuleGetRef(x, y, z, xup, yup, zup, height);
			return (_getPriority(p[0], p[1], p[2], radius) >= 0);
		}
		return (_getPriority(x, y, z, radius) >= 0);
	}
	
	/// @func _displace(nx, ny, nz, xup, yup, zup, _r, slope)
	static _displace = function(nx, ny, nz, xup, yup, zup, _r, slope)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Displaces a sphere.
		*/
		gml_pragma("forceinline");
		var dp = nx * xup + ny * yup + nz * zup;
		if (dp > cmCol[6])
		{
			cmCol[@ 3] = nx;
			cmCol[@ 4] = ny;
			cmCol[@ 5] = nz;
			cmCol[@ 6] = dp;
		}
		if (dp >= slope)
		{ 
			//Prevent sliding
			_r /= dp;
			cmCol[@ 0] += xup * _r;
			cmCol[@ 1] += yup * _r;
			cmCol[@ 2] += zup * _r;
		}
		else
		{
			cmCol[@ 0] += nx * _r;
			cmCol[@ 1] += ny * _r;
			cmCol[@ 2] += nz * _r;
		}
	}
	
	/// @func _addToSubdiv(colMesh)
	static _addToSubdiv = function(colMesh)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Adds the shape to the ColMesh's spatial hash
		*/
		gml_pragma("forceinline");
		var spHash = colMesh.spHash;
		if (spHash < 0){return 0;}
		var originX = colMesh.originX;
		var originY = colMesh.originY;
		var originZ = colMesh.originZ;
		var regionSize = colMesh.regionSize;
		var invRegionSize = 1 / regionSize;
		var regionNum = 0;
		var mm = getMinMax();
		var x1 = floor((mm[0] - originX) * invRegionSize);
		var y1 = floor((mm[1] - originY) * invRegionSize);
		var z1 = floor((mm[2] - originZ) * invRegionSize);
		var x2 = floor((mm[3] - originX) * invRegionSize);
		var y2 = floor((mm[4] - originY) * invRegionSize);
		var z2 = floor((mm[5] - originZ) * invRegionSize);
		var struct = ((type == eColMeshShape.Mesh) ? triangle : self);
		
		for (var xx = x1; xx <= x2; ++xx)
		{
			var _x = (xx + .5) * regionSize + originX;
			for (var yy = y1; yy <= y2; ++yy)
			{
				var _y = (yy + .5) * regionSize + originY;
				for (var zz = z1; zz <= z2; ++zz)
				{
					var _z = (zz + .5) * regionSize + originZ;
					if (_intersectsCube(regionSize * .5, _x, _y, _z))
					{
						var key = colmesh_get_key(xx, yy, zz);
						var list = spHash[? key];
						if (is_undefined(list))
						{
							list = ds_list_create();
							spHash[? key] = list;
							regionNum ++;
						}
						ds_list_add(list, struct);
					}
				}
			}
		}
		return regionNum;
	}
	
	/// @func _removeFromSubdiv(colMesh)
	static _removeFromSubdiv = function(colMesh)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Removes the shape from the colmesh's subdivision
		*/
		var spHash = colMesh.spHash;
		if (spHash < 0){return false;}
		var originX = colMesh.originX;
		var originY = colMesh.originY;
		var originZ = colMesh.originZ;
		var invRegionSize = 1 / colMesh.regionSize;
		var mm = getMinMax();
		var x1 = floor((mm[0] - originX) * invRegionSize);
		var y1 = floor((mm[1] - originY) * invRegionSize);
		var z1 = floor((mm[2] - originZ) * invRegionSize);
		var x2 = floor((mm[3] - originX) * invRegionSize);
		var y2 = floor((mm[4] - originY) * invRegionSize);
		var z2 = floor((mm[5] - originZ) * invRegionSize);
		var struct = ((type == eColMeshShape.Mesh) ? triangle : self);
		
		for (var xx = x1; xx <= x2; ++xx)
		{
			for (var yy = y1; yy <= y2; ++yy)
			{
				for (var zz = z1; zz <= z2; ++zz)
				{
					var key = colmesh_get_key(xx, yy, zz);
					var list = spHash[? key];
					if (is_undefined(list))
					{
						continue;
					}
					var ind = ds_list_find_index(list, struct);
					if (ind < 0){continue;}
					ds_list_delete(list, ind);
					if (ds_list_empty(list))
					{
						ds_list_destroy(list);
						ds_map_delete(spHash, key);
					}
				}
			}
		}
	}
	
	/// @func _updateSubdiv(colMesh, oldMinMax)
	static _updateSubdiv = function(colMesh, oldMinMax)
	{
		var spHash = colMesh.spHash;
		if (spHash < 0)
		{
			colMesh._expandBoundaries(getMinMax());
			return true;
		}
		
		//Update the spatial hash
		var originX = colMesh.originX;
		var originY = colMesh.originY;
		var originZ = colMesh.originZ;
		var invRegionSize = 1 / colMesh.regionSize;
			
		var oldX1 = floor((oldMinMax[0] - originX) * invRegionSize);
		var oldY1 = floor((oldMinMax[1] - originY) * invRegionSize);
		var oldZ1 = floor((oldMinMax[2] - originZ) * invRegionSize);
		var oldX2 = floor((oldMinMax[3] - originX) * invRegionSize);
		var oldY2 = floor((oldMinMax[4] - originY) * invRegionSize);
		var oldZ2 = floor((oldMinMax[5] - originZ) * invRegionSize);
			
		var newMM = getMinMax();
		var newX1 = floor((newMM[0] - originX) * invRegionSize);
		var newY1 = floor((newMM[1] - originY) * invRegionSize);
		var newZ1 = floor((newMM[2] - originZ) * invRegionSize);
		var newX2 = floor((newMM[3] - originX) * invRegionSize);
		var newY2 = floor((newMM[4] - originY) * invRegionSize);
		var newZ2 = floor((newMM[5] - originZ) * invRegionSize);
			
		//If there was no change, we can exit here and now
		if (oldX1 == newX1 & oldY1 == newY1 && oldZ1 == newZ1 && oldX2 == newX2 && oldY2 == newY2 && oldZ2 == newZ2){exit;}
			
		colMesh._expandBoundaries(newMM);
			
		//Remove the shape from the spatial hash
		for (var xx = oldX1; xx <= oldX2; ++xx)
		{
			for (var yy = oldY1; yy <= oldY2; ++yy)
			{
				for (var zz = oldZ1; zz <= oldZ2; ++zz)
				{
					var key = colmesh_get_key(xx, yy, zz);
					var list = spHash[? key];
					if (is_undefined(list)){continue;}
					var ind = ds_list_find_index(list, self);
					if (ind < 0){continue;}
					ds_list_delete(list, ind);
					if (ds_list_empty(list))
					{
						ds_list_destroy(list);
						ds_map_delete(spHash, key);
					}
				}
			}
		}
		
		//Add it back at its new position
		for (var xx = newX1; xx <= newX2; ++xx)
		{
			for (var yy = newY1; yy <= newY2; ++yy)
			{
				for (var zz = newZ1; zz <= newZ2; ++zz)
				{
					var key = colmesh_get_key(xx, yy, zz);
					var list = spHash[? key];
					if (is_undefined(list))
					{
						list = ds_list_create();
						spHash[? key] = list;
					}
					ds_list_add(list, self);
				}
			}
		}
	}
	
	#endregion
	
	#region Shape-specific functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		ret[0] = min(triangle[0], triangle[3], triangle[6]);
		ret[1] = min(triangle[1], triangle[4], triangle[7]);
		ret[2] = min(triangle[2], triangle[5], triangle[8]);
		ret[3] = max(triangle[0], triangle[3], triangle[6]);
		ret[4] = max(triangle[1], triangle[4], triangle[7]);
		ret[5] = max(triangle[2], triangle[5], triangle[8]);
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, xup, yup, zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var nx = triangle[9], ny = triangle[10], nz = triangle[11];
		var v1x = triangle[0], v1y = triangle[1], v1z = triangle[2];
		var d = (xup * nx + yup * ny + zup * nz);
		if (d != 0)
		{
			var trace = ((v1x - _x) * nx + (v1y - _y) * ny + (v1z - _z) * nz) / d;
			var traceX = _x + xup * trace;
			var traceY = _y + yup * trace;
			var traceZ = _z + zup * trace;
			var p = _getClosestPoint(traceX, traceY, traceZ);
			d = (p[0] - _x) * xup + (p[1] - _y) * yup + (p[2] - _z) * zup;
		}
		else
		{
			d = (_x - v1x) * xup + (_y - v1y) * yup + (_z - v1z) * zup;
		}
		d = clamp(d, 0, height);
		ret[@ 0] = _x + xup * d;
		ret[@ 1] = _y + yup * d;
		ret[@ 2] = _z + zup * d;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
		*/
		gml_pragma("forceinline");
		var dx = cmRay[0] - ox;
		var dy = cmRay[1] - oy;
		var dz = cmRay[2] - oz;


		var nx = triangle[9], ny = triangle[10], nz = triangle[11];
		var h = nx * dx + ny * dy + nz * dz;
		if (h == 0){return false;} //Continue if the ray is parallel to the surface of the triangle (ie. perpendicular to the triangle's normal)
		var v1x = triangle[0], v1y = triangle[1], v1z = triangle[2];
		var h = (nx * (v1x - ox) + ny * (v1y - oy) + nz * (v1z - oz)) / h;
		if (h < 0 || h > 1){return false;} //Continue if the intersection is too far behind or in front of the ray
		var itsX = ox + dx * h,		itsY = oy + dy * h,		itsZ = oz + dz * h;

		//Check first edge
		var v2x = triangle[3], v2y = triangle[4], v2z = triangle[5];
		var ax = itsX - v1x,	ay = itsY - v1y,	az = itsZ - v1z;
		var bx = v2x - v1x,		by = v2y - v1y,		bz = v2z - v1z;
		var dp = nx * (az * by - ay * bz) + ny * (ax * bz - az * bx) + nz * (ay * bx - ax * by);
		if (dp < 0){return false;} //Continue if the intersection is outside this edge of the triangle
		if (dp == 0)
		{
			var t = (ax * bx + ay * by + az * bz);
			if (t < 0 || t > bx * bx + by * by + bz * bz){return false;} //Intersection is perfectly on this triangle edge. Continue if outside triangle.
		}
	
		//Check second edge
		var v3x = triangle[6], v3y = triangle[7], v3z = triangle[8];
		var ax = itsX - v2x,	ay = itsY - v2y,	az = itsZ - v2z;
		var bx = v3x - v2x,		by = v3y - v2y,		bz = v3z - v2z;
		var dp = nx * (az * by - ay * bz) + ny * (ax * bz - az * bx) + nz * (ay * bx - ax * by);
		if (dp < 0){return false;} //Continue if the intersection is outside this edge of the triangle
		if (dp == 0)
		{
			var t = (ax * bx + ay * by + az * bz);
			if (t < 0 || t > bx * bx + by * by + bz * bz){return false;} //Intersection is perfectly on this triangle edge. Continue if outside triangle.
		}
	
		//Check third edge
		var ax = itsX - v3x,	ay = itsY - v3y,	az = itsZ - v3z;
		var bx = v1x - v3x,		by = v1y - v3y,		bz = v1z - v3z;
		var dp = nx * (az * by - ay * bz) + ny * (ax * bz - az * bx) + nz * (ay * bx - ax * by);
		if (dp < 0){return false;} //Continue if the intersection is outside this edge of the triangle
		if (dp == 0)
		{
			var t = (ax * bx + ay * by + az * bz);
			if (t < 0 || t > bx * bx + by * by + bz * bz){return false;} //Intersection is perfectly on this triangle edge. Continue if outside triangle.
		}
	
		//The line intersects the triangle. Save the triangle normal and intersection.
		var s = sign(h);
		cmRay[0] = itsX;
		cmRay[1] = itsY;
		cmRay[2] = itsZ;
		cmRay[3] = nx * s;
		cmRay[4] = ny * s;
		cmRay[5] = nz * s;
		cmRay[6] = triangle;
		return true;
	}	
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(x, y, z, xup, yup, zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		gml_pragma("forceinline");
		//Check first edge
		var nx = triangle[9], ny = triangle[10], nz = triangle[11];
		var v1x = triangle[0], v1y = triangle[1], v1z = triangle[2];
		var t0 = x - v1x,	t1 = y - v1y,	t2 = z - v1z;
		var D = t0 * nx + t1 * ny + t2 * nz;
		if (abs(D) > radius)
		{
			return false;
		}
		var v2x = triangle[3], v2y = triangle[4], v2z = triangle[5];
		var u0 = v2x - v1x,			u1 = v2y - v1y,			u2 = v2z - v1z;
		var dp = (t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz;
		if (dp < 0)
		{
			var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
			var _nx = t0 - u0 * a;
			var _ny = t1 - u1 * a;
			var _nz = t2 - u2 * a;
			var dd = _nx * _nx + _ny * _ny + _nz * _nz;
			if (dd <= 0 || dd > radius * radius){return false;}
			var d = sqrt(dd);
			_displace(_nx / d, _ny / d, _nz / d, xup, yup, zup, radius - d, slope);
			return true;
		}
		else{//Check second edge
			var v3x = triangle[6], v3y = triangle[7], v3z = triangle[8];
			var t0 = x - v2x,			t1 = y - v2y,			t2 = z - v2z;
			var u0 = v3x - v2x,			u1 = v3y - v2y,			u2 = v3z - v2z;
			var dp = (t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz;
			if (dp < 0)
			{
				var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
				var _nx = t0 - u0 * a;
				var _ny = t1 - u1 * a;
				var _nz = t2 - u2 * a;
				var dd = _nx * _nx + _ny * _ny + _nz * _nz;
				if (dd <= 0 || dd > radius * radius){return false;}
				var d = sqrt(dd);
				_displace(_nx / d, _ny / d, _nz / d, xup, yup, zup, radius - d, slope);
				return true;
			}
			else{//Check third edge
				var t0 = x - v3x, t1 = y - v3y, t2 = z - v3z;
				var u0 = v1x - v3x, u1 = v1y - v3y, u2 = v1z - v3z;
				var dp = (t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz;
				if (dp < 0)
				{
					var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
					var _nx = t0 - u0 * a;
					var _ny = t1 - u1 * a;
					var _nz = t2 - u2 * a;
					var dd = _nx * _nx + _ny * _ny + _nz * _nz;
					if (dd <= 0 || dd > radius * radius){return false;}
					var d = sqrt(dd);
					_displace(_nx / d, _ny / d, _nz / d, xup, yup, zup, radius - d, slope);
					return true;
				}
			}
		}
		var s = sign(D);
		_displace(nx * s, ny * s, nz * s, xup, yup, zup, radius - abs(D), slope);
		return true;
	}
	
	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(x, y, z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		gml_pragma("forceinline");
		//Check first edge
		var nx = triangle[9], ny = triangle[10], nz = triangle[11];
		var v1x = triangle[0], v1y = triangle[1], v1z = triangle[2];
		var t0 = x - v1x,	t1 = y - v1y,	t2 = z - v1z;
		var D = t0 * nx + t1 * ny + t2 * nz;
		if (abs(D) > maxR){return -1;}
		var v2x = triangle[3], v2y = triangle[4], v2z = triangle[5];
		var u0 = v2x - v1x,			u1 = v2y - v1y,			u2 = v2z - v1z;
		if ((t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz < 0)
		{
			var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
			var _nx = u0 * a - t0;
			var _ny = u1 * a - t1;
			var _nz = u2 * a - t2;
			return _nx * _nx + _ny * _ny + _nz * _nz;
		}
		else
		{	//Check second edge
			var v3x = triangle[6], v3y = triangle[7], v3z = triangle[8];
			var t0 = x - v2x,			t1 = y - v2y,			t2 = z - v2z;
			var u0 = v3x - v2x,			u1 = v3y - v2y,			u2 = v3z - v2z;
			if ((t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz < 0)
			{
				var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
				var _nx = u0 * a - t0;
				var _ny = u1 * a - t1;
				var _nz = u2 * a - t2;
				return _nx * _nx + _ny * _ny + _nz * _nz;
			}
			else
			{	//Check third edge
				var t0 = x - v3x, t1 = y - v3y, t2 = z - v3z;
				var u0 = v1x - v3x, u1 = v1y - v3y, u2 = v1z - v3z;
				if ((t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz < 0)
				{
					var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
					var _nx = u0 * a - t0;
					var _ny = u1 * a - t1;
					var _nz = u2 * a - t2;
					return _nx * _nx + _ny * _ny + _nz * _nz;
				}
			}
		}
		return abs(D);
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(x, y, z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		static ret = array_create(3);
		gml_pragma("forceinline");
		//Check first edge
		var nx = triangle[9], ny = triangle[10], nz = triangle[11];
		var v1x = triangle[0], v1y = triangle[1], v1z = triangle[2];
		var v2x = triangle[3], v2y = triangle[4], v2z = triangle[5];
		var t0 = x - v1x,	t1 = y - v1y,	t2 = z - v1z;
		var u0 = v2x - v1x,			u1 = v2y - v1y,			u2 = v2z - v1z;
		if ((t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz < 0)
		{
			var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
			ret[@ 0] = v1x + u0 * a;
			ret[@ 1] = v1y + u1 * a;
			ret[@ 2] = v1z + u2 * a;
			return ret;
		}
		else{//Check second edge
			var v3x = triangle[6], v3y = triangle[7], v3z = triangle[8];
			var t0 = x - v2x,			t1 = y - v2y,			t2 = z - v2z;
			var u0 = v3x - v2x,			u1 = v3y - v2y,			u2 = v3z - v2z;
			if ((t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz < 0)
			{
				var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
				ret[@ 0] = v2x + u0 * a;
				ret[@ 1] = v2y + u1 * a;
				ret[@ 2] = v2z + u2 * a;
				return ret;
			}
			else{//Check third edge
				var t0 = x - v3x, t1 = y - v3y, t2 = z - v3z;
				var u0 = v1x - v3x, u1 = v1y - v3y, u2 = v1z - v3z;
				if ((t2 * u1 - t1 * u2) * nx + (t0 * u2 - t2 * u0) * ny + (t1 * u0 - t0 * u1) * nz < 0)
				{
					var a = clamp((u0 * t0 + u1 * t1 + u2 * t2) / (u0 * u0 + u1 * u1 + u2 * u2), 0, 1);
					ret[@ 0] = v3x + u0 * a;
					ret[@ 1] = v3y + u1 * a;
					ret[@ 2] = v3z + u2 * a;
					return ret;
				}
			}
		}
		var D = t0 * nx + t1 * ny + t2 * nz;
		ret[@ 0] = x - nx * D;
		ret[@ 1] = y - ny * D;
		ret[@ 2] = z - nz * D;
		return ret;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		gml_pragma("forceinline");
		/********************************************************/
		/* AABB-triangle overlap test code                      */
		/* by Tomas Akenine-Möller                              */
		/* Function: int triBoxOverlap(float boxcenter[3],      */
		/*          float boxhalfsize[3],float tri[3][3]); */
		/* History:                                             */
		/*   2001-03-05: released the code in its first version */
		/*   2001-06-18: changed the order of the tests, faster */
		/*                                                      */
		/* Acknowledgement: Many thanks to Pierre Terdiman for  */
		/* suggestions and discussions on how to optimize code. */
		/* Thanks to David Hunt for finding a ">="-bug!         */
		/********************************************************/
		// Source: http://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/pubs/tribox.pdf

		/* test in X-direction */
		var nx = triangle[9], ny = triangle[10], nz = triangle[11];
		var v1x = triangle[0], v1y = triangle[1], v1z = triangle[2];
		var v2x = triangle[3], v2y = triangle[4], v2z = triangle[5];
		var v3x = triangle[6], v3y = triangle[7], v3z = triangle[8];
		
		var d1x = v1x - bX,	d2x = v2x - bX,	d3x = v3x - bX;
		if (min(d1x, d2x, d3x) > hsize || max(d1x, d2x, d3x) < -hsize){return false;}

		/* test in Y-direction */
		var d1y = v1y - bY,	d2y = v2y - bY,	d3y = v3y - bY;
		if (min(d1y, d2y, d3y) > hsize || max(d1y, d2y, d3y) < -hsize){return false;}

		/* test in Z-direction */
		var d1z = v1z - bZ,	d2z = v2z - bZ,	d3z = v3z - bZ;
		if (min(d1z, d2z, d3z) > hsize || max(d1z, d2z, d3z) < -hsize){return false;}
		
		var minx, maxx, miny, maxy, minz, maxz;
		if (nx > 0){
			minx = -hsize;
			maxx = hsize;}
		else{
			minx = hsize;
			maxx = -hsize;}
		if (ny > 0){
			miny = -hsize;
			maxy = hsize;}
		else{
			miny = hsize;
			maxy = -hsize;}
		if (nz > 0){
			minz = -hsize;
			maxz = hsize;}
		else{
			minz = hsize;
			maxz = -hsize;}

		var d = nx * d1x + ny * d1y + nz * d1z;
		if (nx * minx + ny * miny + nz * minz > d){return false;}
		if (nx * maxx + ny * maxy + nz * maxz < d){return false;}

		/* Bullet 3:  */
		var fex, fey, fez, p0, p1, p2, ex, ey, ez, rad;
		ex = d2x - d1x;
		ey = d2y - d1y;
		ez = d2z - d1z;
		fex = abs(ex) * hsize;
		fey = abs(ey) * hsize;
		fez = abs(ez) * hsize;
   
		p0 = ez * d1y - ey * d1z;
		p2 = ez * d3y - ey * d3z;
		rad = fez + fey;
		if (min(p0, p2) > rad || max(p0, p2) < -rad){return false;}
   
		p0 = -ez * d1x + ex * d1z;
		p2 = -ez * d3x + ex * d3z;
		rad = fez + fex;
		if (min(p0, p2) > rad || max(p0, p2) < -rad){return false;}
           
		p1 = ey * d2x - ex * d2y;                 
		p2 = ey * d3x - ex * d3y;                 
		rad = fey + fex;
		if (min(p1, p2) > rad || max(p1, p2) < -rad){return false;}

		ex = d3x - d2x;
		ey = d3y - d2y;
		ez = d3z - d2z;
		fex = abs(ex) * hsize;
		fey = abs(ey) * hsize;
		fez = abs(ez) * hsize;
	      
		p0 = ez * d1y - ey * d1z;
		p2 = ez * d3y - ey * d3z;
		rad = fez + fey;
		if (min(p0, p2) > rad || max(p0, p2) < -rad){return false;}
          
		p0 = -ez * d1x + ex * d1z;
		p2 = -ez * d3x + ex * d3z;
		rad = fez + fex;
		if (min(p0, p2) > rad || max(p0, p2) < -rad){return false;}
	
		p0 = ey * d1x - ex * d1y;
		p1 = ey * d2x - ex * d2y;
		rad = fey + fex;
		if (min(p0, p1) > rad || max(p0, p1) < -rad){return false;}

		ex = d1x - d3x;
		ey = d1y - d3y;
		ez = d1z - d3z;
		fex = abs(ex) * hsize;
		fey = abs(ey) * hsize;
		fez = abs(ez) * hsize;

		p0 = ez * d1y - ey * d1z;
		p1 = ez * d2y - ey * d2z;
		rad = fez + fey;
		if (min(p0, p1) > rad || max(p0, p1) < -rad){return false;}

		p0 = -ez * d1x + ex * d1z;
		p1 = -ez * d2x + ex * d2z;
		rad = fez + fex;
		if (min(p0, p1) > rad || max(p0, p1) < -rad){return false;}
	
		p1 = ey * d2x - ex * d2y;
		p2 = ey * d3x - ex * d3y;
		rad = fey + fex;
		if (min(p1, p2) > rad || max(p1, p2) < -rad){return false;}

		return true;
	}
	
	/// @func debugDraw(region, [texture])
	static debugDraw = function() 
	{
		/*
			A crude way of drawing the collision shapes in the given region.
			Useful for debugging.
			
			Since dynamic shapes may contain the colmesh itself, this script needs a recursion counter.
		*/
		region = argument[0]
		if is_undefined(region){exit;}
		if (region < 0)
		{
			region = shapeList;
		}
		if (cmRecursion >= cmMaxRecursion){exit;}
		
		var tex = (argument_count > 1) ? argument[1] : -1;
	
		//Create triangle vbuffer if it does not exist
		var triVbuff = global.ColMeshDebugShapes[eColMeshShape.Mesh];
		if (triVbuff < 0)
		{
			global.ColMeshDebugShapes[eColMeshShape.Mesh] = vertex_create_buffer();
			triVbuff = global.ColMeshDebugShapes[eColMeshShape.Mesh];
		}
		if (cmRecursion == 0)
		{
			vertex_begin(triVbuff, global.ColMeshFormat);
		}
	
		shader_set(sh_colmesh_debug);
		var n = ds_list_size(region);
		var baseW = matrix_get(matrix_world);
		var scale = sqrt(baseW[0] * baseW[0] + baseW[1] * baseW[1] + baseW[2] * baseW[2]);
	
		for (var i = 0; i < n; i ++)
		{
			var W = baseW;
			var shape = region[| i];
			var t = ds_list_find_index(shapeList, shape);
			var alpha = 1 - (t < 0) * .5;
			var col = make_color_hsv((t * 10) mod 255, 255, 255 * alpha);
			if (is_struct(shape))
			{
				if (shape.type == eColMeshShape.Dynamic)
				{
					W = matrix_multiply(shape.M, baseW);
					shape = shape.shape;
					if (shape.type == eColMeshShape.Mesh)
					{
						matrix_set(matrix_world, W);
						++ cmRecursion;
						shape.debugDraw(-1, tex);
						-- cmRecursion;
						continue;
					}
				}
			}
			else
			{
				with _getShape(shape)
				{
					var V = triangle;
					if (cmRecursion > 0)
					{
						var v = colmesh_matrix_transform_vertex(W, V[0] + V[9] * .5, V[1] + V[10] * .5, V[2] + V[11] * .5);
						var v1x = v[0], v1y = v[1], v1z = v[2];
						var v = colmesh_matrix_transform_vertex(W, V[3] + V[9] * .5, V[4] + V[10] * .5, V[5] + V[11] * .5);
						var v2x = v[0], v2y = v[1], v2z = v[2];
						var v = colmesh_matrix_transform_vertex(W, V[6] + V[9] * .5, V[7] + V[10] * .5, V[8] + V[11] * .5);
						var v3x = v[0], v3y = v[1], v3z = v[2];
						var v = colmesh_matrix_transform_vector(W, V[9], V[10], V[11]);
						var nx = v[0], ny = v[1], nz = v[2];
					}
					else
					{
						var v1x = V[0], v1y = V[1], v1z = V[2];
						var v2x = V[3], v2y = V[4], v2z = V[5];
						var v3x = V[6], v3y = V[7], v3z = V[8];
						var nx = V[9],  ny = V[10], nz  = V[11];
					}
					vertex_position_3d(triVbuff, v1x + nx*.5, v1y + ny*.5, v1z + nz*.5);
					vertex_normal(triVbuff, nx, ny, nz);
					vertex_texcoord(triVbuff, 0, 0);
					vertex_color(triVbuff, col, 1);
	
					vertex_position_3d(triVbuff, v2x + nx*.5, v2y + ny*.5, v2z + nz*.5);
					vertex_normal(triVbuff, nx, ny, nz);
					vertex_texcoord(triVbuff, 1, 0);
					vertex_color(triVbuff, col, 1);
	
					vertex_position_3d(triVbuff, v3x + nx*.5, v3y + ny*.5, v3z + nz*.5);
					vertex_normal(triVbuff, nx, ny, nz);
					vertex_texcoord(triVbuff, 0, 1);
					vertex_color(triVbuff, col, 1);
				}
				continue;
			}
			with shape
			{
				shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_color"), color_get_red(col) / 255, color_get_green(col) / 255, color_get_blue(col) / 255, 1);
				var vbuff = global.ColMeshDebugShapes[type];
				switch type
				{
					case eColMeshShape.Sphere:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_sphere(20, 10, 1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), R * 1.01 * scale);
						matrix_set(matrix_world, matrix_multiply(matrix_build(x, y, z, 0, 0, 0, 1, 1, 1), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
					case eColMeshShape.Capsule:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_capsule(20, 10, 1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), R * 1.01 * scale);
						matrix_set(matrix_world, matrix_multiply(colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, H * 1.01), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
					case eColMeshShape.Cylinder:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_cylinder(20, 1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), 0);
						matrix_set(matrix_world, matrix_multiply(colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R * 1.01, R * 1.01, H * 1.01), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
					case eColMeshShape.Torus:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_torus(20, 20, 1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), r * 1.01 * scale);
						matrix_set(matrix_world, matrix_multiply(colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, R), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
					case eColMeshShape.Disk:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_disk(20, 20, 1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), r * 1.01 * scale);
						matrix_set(matrix_world, matrix_multiply(colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, R), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
					case eColMeshShape.Block:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_block(1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), 0);
						matrix_set(matrix_world, matrix_multiply(matrix_multiply(matrix_build(0, 0, 0, 0, 0, 0, 1.01, 1.01, 1.01), M), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
					case eColMeshShape.Cube:
						if (vbuff < 0){
							global.ColMeshDebugShapes[type] = colmesh_create_block(1, 1);
							vbuff = global.ColMeshDebugShapes[type];
						}
						shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), 0);
						matrix_set(matrix_world, matrix_multiply(matrix_build(x, y, z, 0, 0, 0, hsize * 1.01, hsize * 1.01, hsize * 1.01), W));
						vertex_submit(vbuff, pr_trianglelist, tex);
						break;
				}
			}
			W = baseW;
		}
	
		if (cmRecursion == 0)
		{
			matrix_set(matrix_world, baseW);
			shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_radius"), 0);
			shader_set_uniform_f(shader_get_uniform(sh_colmesh_debug, "u_color"), 1, 1, 1, 1);
			vertex_end(triVbuff);
			vertex_submit(triVbuff, pr_trianglelist, tex);
		}
		shader_reset();
		matrix_set(matrix_world, matrix_build_identity());
	}
	
	/// @func move(x, y, z)
	static move = function(_x, _y, _z)
	{
		//This does not make sense for a triangle, so we can just return false here and now
		return false;
	}
	
	#endregion
}

/// @func colmesh_sphere(x, y, z, radius)
function colmesh_sphere(_x, _y, _z, radius) : colmesh_shapes() constructor
{
	type = eColMeshShape.Sphere;
	x = _x;
	y = _y;
	z = _z;
	R = radius;
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		ret[0] = x - R;
		ret[1] = y - R;
		ret[2] = z - R;
		ret[3] = x + R;
		ret[4] = y + R;
		ret[5] = z + R;
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, xup, yup, zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var d = (x - _x) * xup + (y - _y) * yup + (z - _z) * zup;
		d = clamp(d, 0, height);
		ret[@ 0] = _x + xup * d;
		ret[@ 1] = _y + yup * d;
		ret[@ 2] = _z + zup * d;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		var ray = colmesh_cast_ray_sphere(x, y, z, R, ox, oy, oz, cmRay[0], cmRay[1], cmRay[2]);
		if (is_array(ray))
		{
			var nx = ray[0] - x;
			var ny = ray[1] - y;
			var nz = ray[2] - z;
			var n = nx * nx + ny * ny + nz * nz;
			if (n <= 0){return false;}
			n = 1 / sqrt(n);
			cmRay[0] = ray[0];
			cmRay[1] = ray[1];
			cmRay[2] = ray[2];
			cmRay[3] = nx * n;
			cmRay[4] = ny * n;
			cmRay[5] = nz * n;
			cmRay[6] = self;
			return true;
		}
		return false;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		static ret = array_create(3);
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var d = dx * dx + dy * dy + dz * dz;
		if (d > 0)
		{
			var _d = R / sqrt(d);
			ret[@ 0] = x + dx * _d;
			ret[@ 1] = y + dy * _d;
			ret[@ 2] = z + dz * _d;
			return ret;
		}
		ret[@ 0] = x + R;
		ret[@ 1] = y;
		ret[@ 2] = z;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, xup, yup, zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var d = dx * dx + dy * dy + dz * dz;
		var _r = R + radius;
		if (d >= _r * _r) return false;
		if (d > 0)
		{
			var _d = sqrt(d);
			_displace(dx / _d, dy / _d, dz / _d, xup, yup, zup, _r - _d, slope);
			return true;
		}
		_displace(1, 0, 0, xup, yup, zup, _r, slope);
		return true;
	}
	
	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		var dx = _x - x, dy = _y - y, dz = _z - z;
		var d = dx * dx + dy * dy + dz * dz;
		var _r = R + maxR;
		if (d > _r * _r) return -1;
		return sqr(max(sqrt(d) - R, 0));
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		var distSqr = R * R;
		var d = x - bX + hsize;
		if (d < 0)
		{
			distSqr -= d * d;
		}
		else
		{
			d = x - bX - hsize;
			if (d > 0)
			{
				distSqr -= d * d;
			}
		}
		d = y - bY + hsize;
		if (d < 0)
		{
			distSqr -= d * d;
		}
		else
		{
			d = y - bY - hsize;
			if (d > 0)
			{
				distSqr -= d * d;
			}
		}
		d = z - bZ + hsize;
		if (d < 0)
		{
			distSqr -= d * d;
		}
		else
		{
			d = z - bZ - hsize;
			if (d > 0)
			{
				distSqr -= d * d;
			}
		}
		return (distSqr > 0);
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_capsule(x, y, z, xup, yup, zup, radius, height)
function colmesh_capsule(_x, _y, _z, _xup, _yup, _zup, radius, height) : colmesh_shapes() constructor
{
	type = eColMeshShape.Capsule;
	x = _x;
	y = _y;
	z = _z;
	var l = sqrt(_xup * _xup + _yup * _yup + _zup * _zup);
	xup = _xup / l;
	yup = _yup / l;
	zup = _zup / l;
	R = radius;
	H = height;
	var M = colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, H);
	var inv = colmesh_matrix_invert_fast(M, M);
	inv0 = inv[0];	inv1 = inv[1];
	inv4 = inv[4];	inv5 = inv[5];
	inv8 = inv[8];	inv9 = inv[9];
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		ret[0] = x - R + H * min(0, xup);
		ret[1] = y - R + H * min(0, yup);
		ret[2] = z - R + H * min(0, zup);
		ret[3] = x + R + H * max(0, xup);
		ret[4] = y + R + H * max(0, yup);
		ret[5] = z + R + H * max(0, zup);
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, _xup, _yup, _zup, height)
	{	
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var upDp = _xup * xup + _yup * yup + _zup * zup;
		
		//If the capsules are parallel, finding the nearest point is trivial
		if (upDp == 1)
		{
			var t = clamp(_xup * (x - _x) + _yup * (y - _y) + _zup * (z - _z), 0, height);
			ret[0] = _x + _xup * t;
			ret[1] = _y + _yup * t;
			ret[2] = _z + _zup * t;
			return ret;
		}
		
		//Find the nearest point between the central axis of each capsule. Source: http://geomalgorithms.com/a07-_distance.html
		var w1 = (_x - x) * xup + (_y - y) * yup + (_z - z) * zup;
		var w2 = (_x - x) * _xup + (_y - y) * _yup + (_z - z) * _zup;
		var s = clamp((w1 - w2 * upDp) / (1 - upDp * upDp), 0, H);
		var t = clamp(_xup * (x + xup * s - _x) + _yup * (y + yup * s - _y) + _zup * (z + zup * s - _z), 0, height);
		ret[0] = _x + _xup * t;
		ret[1] = _y + _yup * t;
		ret[2] = _z + _zup * t;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		/*	Algorithm created by TheSnidr	*/
		var _x = cmRay[0],	_y = cmRay[1],	_z = cmRay[2];
		var dx = _x - ox,	dy = _y - oy,	dz = _z - oz;
		
		//Transform the ray into the cylinder's local space, and do a 2D ray-circle intersection check
		var lox = inv0 * (ox - x) + inv4 * (oy - y) + inv8 * (oz - z);
		var loy = inv1 * (ox - x) + inv5 * (oy - y) + inv9 * (oz - z);
		var ldx = inv0 * dx + inv4 * dy + inv8 * dz;
		var ldy = inv1 * dx + inv5 * dy + inv9 * dz;
		var a = (ldx * ldx + ldy * ldy);
		var b = - (ldx * lox + ldy * loy);
		var c = lox * lox + loy * loy - 1;
		var k = b * b - a * c;
		if (k <= 0) return false;
		k = sqrt(k);
		var t = (b - k) / a;
		if (t > 1 || t < 0) return false;
		
		//Find the 3D intersection
		var itsX = ox + dx * t;
		var itsY = oy + dy * t;
		var itsZ = oz + dz * t;
		var d = (itsX - x) * xup + (itsY - y) * yup + (itsZ - z) * zup;
		var _d = clamp(d, 0, H);
		var tx = x + xup * _d;
		var ty = y + yup * _d;
		var tz = z + zup * _d;
		if (d < 0 || d > H)
		{	//The intersection is outside the end of the capsule. Do a spherical ray cast at the nearest endpoint
			var ray = colmesh_cast_ray_sphere(tx, ty, tz, R, ox, oy, oz, _x, _y, _z);
			if (!is_array(ray)){return false;}
			itsX = ray[0];
			itsY = ray[1];
			itsZ = ray[2];
		}
		var nx = itsX - tx;
		var ny = itsY - ty;
		var nz = itsZ - tz;
		var n = 1 / sqrt(nx * nx + ny * ny + nz * nz);
		cmRay[0] = itsX;
		cmRay[1] = itsY;
		cmRay[2] = itsZ;
		cmRay[3] = nx * n;
		cmRay[4] = ny * n;
		cmRay[5] = nz * n;
		cmRay[6] = self;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var d = clamp(dx * xup + dy * yup + dz * zup, 0, H);
		var tx = x + xup * d;
		var ty = y + yup * d;
		var tz = z + zup * d;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		var d = dx * dx + dy * dy + dz * dz;
		if (d > 0)
		{
			var r = R / sqrt(d);
			ret[@ 0] = tx + dx * r;
			ret[@ 1] = ty + dy * r;
			ret[@ 2] = tz + dz * r;
			return ret;
		}
		ret[@ 0] = tx + R * _xup;
		ret[@ 1] = ty + R * _yup;
		ret[@ 2] = tz + R * _zup;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		var D = clamp((_x - x) * xup + (_y - y) * yup + (_z - z) * zup, 0, H);
		var tx = x + xup * D;
		var ty = y + yup * D;
		var tz = z + zup * D
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		var d = dx * dx + dy * dy + dz * dz;
		var _r = R + radius;
		if (d >= _r * _r) return false;
		if (d > 0)
		{
			var _d = sqrt(d);
			_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, _r - _d, slope);
			return true;
		}
		return true;
	}

	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		var D = clamp((_x - x) * xup + (_y - y) * yup + (_z - z) * zup, 0, H);
		var tx = x + xup * D;
		var ty = y + yup * D;
		var tz = z + zup * D
		var dx = _x - tx, dy = _y - ty, dz = _z - tz;
		var d = dx * dx + dy * dy + dz * dz;
		var _r = R + maxR;
		if (d > _r * _r) return -1;
		return sqr(max(sqrt(d) - R, 0));
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		var p = _getClosestPoint(bX, bY, bZ);
		var dx = p[0] - bX, dy = p[1] - bY, dz = p[2] - bZ;
		if (abs(dx) > hsize || abs(dy) > hsize || abs(dz) > hsize) return false;
		return true;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_cylinder(x, y, z, xup, yup, zup, radius, height)
function colmesh_cylinder(_x, _y, _z, _xup, _yup, _zup, radius, height) : colmesh_shapes() constructor
{
	type = eColMeshShape.Cylinder;
	x = _x;
	y = _y;
	z = _z;
	var l = sqrt(_xup * _xup + _yup * _yup + _zup * _zup);
	xup = _xup / l;
	yup = _yup / l;
	zup = _zup / l;
	R = radius;
	H = height;
	var M = colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, H);
	var inv = colmesh_matrix_invert_fast(M, M);
	inv0 = inv[0]; inv1 = inv[1];
	inv4 = inv[4]; inv5 = inv[5];
	inv8 = inv[8]; inv9 = inv[9];
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		ret[0] = x - R + H * min(0, xup);
		ret[1] = y - R + H * min(0, yup);
		ret[2] = z - R + H * min(0, zup);
		ret[3] = x + R + H * max(0, xup);
		ret[4] = y + R + H * max(0, yup);
		ret[5] = z + R + H * max(0, zup);
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, _xup, _yup, _zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var upDp = _xup * xup + _yup * yup + _zup * zup;
		
		//If the capsules are parallel, finding the nearest point is trivial
		if (upDp == 1)
		{
			var t = clamp(_xup * (x - _x) + _yup * (y - _y) + _zup * (z - _z), 0, height);
			ret[0] = _x + _xup * t;
			ret[1] = _y + _yup * t;
			ret[2] = _z + _zup * t;
			return ret;
		}
		
		//Find the nearest point between the central axis of each capsule. Source: http://geomalgorithms.com/a07-_distance.html
		var w1 = (_x - x) * xup + (_y - y) * yup + (_z - z) * zup;
		var w2 = (_x - x) * _xup + (_y - y) * _yup + (_z - z) * _zup;
		var s = (w1 - w2 * upDp) / (1 - upDp * upDp);
		if (s > 0 && s < H)
		{
			var t = clamp(_xup * (x + xup * s - _x) + _yup * (y + yup * s - _y) + _zup * (z + zup * s - _z), 0, height);
			ret[0] = _x + _xup * t;
			ret[1] = _y + _yup * t;
			ret[2] = _z + _zup * t;
			return ret;
		}
		
		//If the given point is outside either end of the cylinder, find the nearest point to the terminal plane instead
		s = clamp(s, 0, H);
		var traceX = x + xup * s;
		var traceY = y + yup * s;
		var traceZ = z + zup * s;
		var d = (_xup * xup + _yup * yup + _zup * zup);
		if (d != 0)
		{
			var trace = ((traceX - _x) * xup + (traceY - _y) * yup + (traceZ - _z) * zup) / d;
			var traceX = _x + _xup * trace;
			var traceY = _y + _yup * trace;
			var traceZ = _z + _zup * trace;
			var p = _getClosestPoint(traceX, traceY, traceZ);
			d = (p[0] - _x) * _xup + (p[1] - _y) * _yup + (p[2] - _z) * _zup;
		}
		else
		{
			d = (traceX - _x) * _xup + (traceY - _y) * _yup + (traceZ - _z) * _zup;
		}
		var t = clamp(d, 0, height);
		ret[0] = _x + _xup * t;
		ret[1] = _y + _yup * t;
		ret[2] = _z + _zup * t;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		/*	Algorithm created by TheSnidr	*/
		gml_pragma("forceinline");
		var _x = cmRay[0],	_y = cmRay[1],	_z = cmRay[2];
		var dx = _x - ox,	dy = _y - oy,	dz = _z - oz;
		
		//Transform the ray into the cylinder's local space, and do a 2D ray-circle intersection check
		var lox = inv0 * (ox - x) + inv4 * (oy - y) + inv8 * (oz - z);
		var loy = inv1 * (ox - x) + inv5 * (oy - y) + inv9 * (oz - z);
		var ldx = inv0 * dx + inv4 * dy + inv8 * dz;
		var ldy = inv1 * dx + inv5 * dy + inv9 * dz;
		var a = (ldx * ldx + ldy * ldy);
		var b = - (ldx * lox + ldy * loy);
		var c = lox * lox + loy * loy - 1;
		var k = b * b - a * c;
		if (k <= 0){return false;}
		k = sqrt(k);
		var t = (b - k) / a;
		if (t > 1){return false;}
		var inside = false;
		if (t < 0)
		{
			t = (b + k) / a;
			inside = true;
			if (t < 0){return false;}
		}
		
		//Find the 3D intersection
		var itsX = ox + dx * t;
		var itsY = oy + dy * t;
		var itsZ = oz + dz * t;
		var d = (itsX - x) * xup + (itsY - y) * yup + (itsZ - z) * zup;
		if (d < 0 || d > H || inside)
		{	//The intersection is outside the end of the capsule. Do a plane intersection at the endpoint
			d = clamp((ox - x) * xup + (oy - y) * yup + (oz - z) * zup, 0, H);
			var tx = x + xup * d;
			var ty = y + yup * d;
			var tz = z + zup * d;
			var dp = dx * xup + dy * yup + dz * zup;
			var s = - sign(dp);
			if (s == 2 * (d == 0) - 1) return false;
			t = - ((ox - tx) * xup + (oy - ty) * yup + (oz - tz) * zup) / dp;
			if (t > 1){return false;}
			if (t < 0){return false;}
			var itsX = ox + dx * t;
			var itsY = oy + dy * t;
			var itsZ = oz + dz * t;
			var d = sqr(itsX - tx) + sqr(itsY - ty) + sqr(itsZ - tz);
			if (d > R * R) return false;
			cmRay[0] = itsX;
			cmRay[1] = itsY;
			cmRay[2] = itsZ;
			cmRay[3] = xup * s;
			cmRay[4] = yup * s;
			cmRay[5] = zup * s;
			cmRay[6] = self;
			return true;
		}
		
		var tx = x + xup * d;
		var ty = y + yup * d;
		var tz = z + zup * d;
		var nx = itsX - tx;
		var ny = itsY - ty;
		var nz = itsZ - tz;
		n = nx * nx + ny * ny + nz * nz;
		var n = 1 / max(sqrt(n), 0.00001);
		cmRay[0] = itsX;
		cmRay[1] = itsY;
		cmRay[2] = itsZ;
		cmRay[3] = nx * n;
		cmRay[4] = ny * n;
		cmRay[5] = nz * n;
		cmRay[6] = self;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var d = clamp(dx * xup + dy * yup + dz * zup, 0, H);
		var tx = x + xup * d;
		var ty = y + yup * d;
		var tz = z + zup * d;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		var dp = dx * xup + dy * yup + dz * zup;
		dx -= xup * dp;
		dy -= yup * dp;
		dz -= zup * dp;
		var d = dx * dx + dy * dy + dz * dz;
		if (d > 0)
		{
			if (d > R * R)
			{
				var r = R / sqrt(d);
				dx *= r;
				dy *= r;
				dz *= r;
			}
			ret[@ 0] = tx + dx;
			ret[@ 1] = ty + dy;
			ret[@ 2] = tz + dz;
			return ret;
		}
		ret[@ 0] = tx;
		ret[@ 1] = ty;
		ret[@ 2] = tz;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		var D = clamp((_x - x) * xup + (_y - y) * yup + (_z - z) * zup, 0, H);
		var tx = x + xup * D;
		var ty = y + yup * D;
		var tz = z + zup * D;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		var _r = R + radius;
		if (D <= 0 || D >= H)
		{
			var dp = dx * xup + dy * yup + dz * zup;
			dx -= xup * dp;
			dy -= yup * dp;
			dz -= zup * dp;
			var d = dx * dx + dy * dy + dz * dz;
			if (d > R * R)
			{
				var _d = R / sqrt(d);
				dx *= _d;
				dy *= _d;
				dz *= _d;
			}
			dx = _x - tx - dx;
			dy = _y - ty - dy;
			dz = _z - tz - dz;
			_r = radius;
		}
		var d = dx * dx + dy * dy + dz * dz;
		if (d >= _r * _r || d <= 0) return false;
		var _d = sqrt(d);
		_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, _r - _d, slope);
		return true;
	}

	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		var D = clamp((_x - x) * xup + (_y - y) * yup + (_z - z) * zup, 0, H);
		var tx = x + xup * D;
		var ty = y + yup * D;
		var tz = z + zup * D;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		if (D <= 0 || D >= H)
		{
			var dp = dx * xup + dy * yup + dz * zup;
			dx -= xup * dp;
			dy -= yup * dp;
			dz -= zup * dp;
			var d = dx * dx + dy * dy + dz * dz;
			if (d > R * R)
			{
				var _d = R / sqrt(d);
				dx *= _d;
				dy *= _d;
				dz *= _d;
			}
			dx = _x - tx - dx;
			dy = _y - ty - dy;
			dz = _z - tz - dz;
			var d = dx * dx + dy * dy + dz * dz;
			if (d > maxR * maxR) return -1;
			return d;
		}
		var d = max(sqrt(dx * dx + dy * dy + dz * dz) - R, 0);
		if (d > maxR) return -1;
		return d * d;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		var p = _getClosestPoint(bX, bY, bZ);
		var dx = p[0] - bX, dy = p[1] - bY, dz = p[2] - bZ;
		if (abs(dx) > hsize || abs(dy) > hsize || abs(dz) > hsize) return false;
		return true;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_cone(x, y, z, xup, yup, zup, radius, height)
function colmesh_unfinished_cone(_x, _y, _z, _xup, _yup, _zup, radius, height) : colmesh_shapes() constructor
{
	type = eColMeshShape.Cone;
	x = _x;
	y = _y;
	z = _z;
	var l = sqrt(_xup * _xup + _yup * _yup + _zup * _zup);
	xup = _xup / l;
	yup = _yup / l;
	zup = _zup / l;
	R = radius;
	H = height;
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		ret[0] = x - R + H * min(0, xup);
		ret[1] = y - R + H * min(0, yup);
		ret[2] = z - R + H * min(0, zup);
		ret[3] = x + R + H * max(0, xup);
		ret[4] = y + R + H * max(0, yup);
		ret[5] = z + R + H * max(0, zup);
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, _xup, _yup, _zup, height)
	{
		//A supplementary function, not meant to be used by itself.
		//Returns the nearest point along the given capsule to the shape.
		gml_pragma("forceinline");
		static ret = array_create(3);
		var upDp = _xup * xup + _yup * yup + _zup * zup;
		
		//If the capsules are parallel, finding the nearest point is trivial
		if (upDp == 1)
		{
			var t = clamp(_xup * (x - _x) + _yup * (y - _y) + _zup * (z - _z), 0, height);
			ret[0] = _x + _xup * t;
			ret[1] = _y + _yup * t;
			ret[2] = _z + _zup * t;
			return ret;
		}
		
		//Find the nearest point between the central axis of each capsule. Source: http://geomalgorithms.com/a07-_distance.html
		var w1 = (_x - x) * xup + (_y - y) * yup + (_z - z) * zup;
		var w2 = (_x - x) * _xup + (_y - y) * _yup + (_z - z) * _zup;
		var s = (w1 - w2 * upDp) / (1 - upDp * upDp);
		if (s > 0 && s < H)
		{
			var t = clamp(_xup * (x + xup * s - _x) + _yup * (y + yup * s - _y) + _zup * (z + zup * s - _z), 0, height);
			ret[0] = _x + _xup * t;
			ret[1] = _y + _yup * t;
			ret[2] = _z + _zup * t;
			return ret;
		}
		
		//If the given point is outside either end of the cylinder, find the nearest point to the terminal plane instead
		s = clamp(s, 0, H);
		var traceX = x + xup * s;
		var traceY = y + yup * s;
		var traceZ = z + zup * s;
		var d = (_xup * xup + _yup * yup + _zup * zup);
		if (d != 0)
		{
			var trace = ((traceX - _x) * xup + (traceY - _y) * yup + (traceZ - _z) * zup) / d;
			var traceX = _x + _xup * trace;
			var traceY = _y + _yup * trace;
			var traceZ = _z + _zup * trace;
			var p = _getClosestPoint(traceX, traceY, traceZ);
			d = (p[0] - _x) * _xup + (p[1] - _y) * _yup + (p[2] - _z) * _zup;
		}
		else
		{
			d = (traceX - _x) * _xup + (traceY - _y) * _yup + (traceZ - _z) * _zup;
		}
		var t = clamp(d, 0, height);
		ret[0] = _x + _xup * t;
		ret[1] = _y + _yup * t;
		ret[2] = _z + _zup * t;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		/*	Algorithm created by TheSnidr	*/
		gml_pragma("forceinline");
		var _x = cmRay[0],	_y = cmRay[1],	_z = cmRay[2];
		var dx = _x - ox,	dy = _y - oy,	dz = _z - oz;
		
		//Transform the ray into the cylinder's local space, and do a 2D ray-circle intersection check
		var lox = inv0 * (ox - x) + inv4 * (oy - y) + inv8 * (oz - z);
		var loy = inv1 * (ox - x) + inv5 * (oy - y) + inv9 * (oz - z);
		var ldx = inv0 * dx + inv4 * dy + inv8 * dz;
		var ldy = inv1 * dx + inv5 * dy + inv9 * dz;
		var a = (ldx * ldx + ldy * ldy);
		var b = - (ldx * lox + ldy * loy);
		var c = lox * lox + loy * loy - 1;
		var k = b * b - a * c;
		if (k <= 0){return false;}
		k = sqrt(k);
		var t = (b - k) / a;
		if (t > 1){return false;}
		var inside = false;
		if (t < 0)
		{
			t = (b + k) / a;
			inside = true;
			if (t < 0){return false;}
		}
		
		//Find the 3D intersection
		var itsX = ox + dx * t;
		var itsY = oy + dy * t;
		var itsZ = oz + dz * t;
		var d = (itsX - x) * xup + (itsY - y) * yup + (itsZ - z) * zup;
		if (d < 0 || d > H || inside)
		{	//The intersection is outside the end of the capsule. Do a plane intersection at the endpoint
			d = clamp((ox - x) * xup + (oy - y) * yup + (oz - z) * zup, 0, H);
			var tx = x + xup * d;
			var ty = y + yup * d;
			var tz = z + zup * d;
			var dp = dx * xup + dy * yup + dz * zup;
			var s = - sign(dp);
			if (s == 2 * (d == 0) - 1) return false;
			t = - ((ox - tx) * xup + (oy - ty) * yup + (oz - tz) * zup) / dp;
			if (t > 1){return false;}
			if (t < 0){return false;}
			var itsX = ox + dx * t;
			var itsY = oy + dy * t;
			var itsZ = oz + dz * t;
			var d = sqr(itsX - tx) + sqr(itsY - ty) + sqr(itsZ - tz);
			if (d > R * R) return false;
			cmRay[0] = itsX;
			cmRay[1] = itsY;
			cmRay[2] = itsZ;
			cmRay[3] = xup * s;
			cmRay[4] = yup * s;
			cmRay[5] = zup * s;
			cmRay[6] = self;
			return true;
		}
		
		var tx = x + xup * d;
		var ty = y + yup * d;
		var tz = z + zup * d;
		var nx = itsX - tx;
		var ny = itsY - ty;
		var nz = itsZ - tz;
		n = nx * nx + ny * ny + nz * nz;
		var n = 1 / max(sqrt(n), 0.00001);
		cmRay[0] = itsX;
		cmRay[1] = itsY;
		cmRay[2] = itsZ;
		cmRay[3] = nx * n;
		cmRay[4] = ny * n;
		cmRay[5] = nz * n;
		cmRay[6] = self;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var d = clamp(dx * xup + dy * yup + dz * zup, 0, H);
		var tx = x + xup * d;
		var ty = y + yup * d;
		var tz = z + zup * d;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		var dp = dx * xup + dy * yup + dz * zup;
		dx -= xup * dp;
		dy -= yup * dp;
		dz -= zup * dp;
		var d = dx * dx + dy * dy + dz * dz;
		if (d > 0)
		{
			if (d > R * R)
			{
				var r = R / sqrt(d);
				dx *= r;
				dy *= r;
				dz *= r;
			}
			ret[@ 0] = tx + dx;
			ret[@ 1] = ty + dy;
			ret[@ 2] = tz + dz;
			return ret;
		}
		ret[@ 0] = tx;
		ret[@ 1] = ty;
		ret[@ 2] = tz;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		var D = clamp((_x - x) * xup + (_y - y) * yup + (_z - z) * zup, 0, H);
		var tx = x + xup * D;
		var ty = y + yup * D;
		var tz = z + zup * D;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		var _r = R + radius;
		if (D <= 0 || D >= H)
		{
			var dp = dx * xup + dy * yup + dz * zup;
			dx -= xup * dp;
			dy -= yup * dp;
			dz -= zup * dp;
			var d = dx * dx + dy * dy + dz * dz;
			if (d > R * R)
			{
				var _d = R / sqrt(d);
				dx *= _d;
				dy *= _d;
				dz *= _d;
			}
			dx = _x - tx - dx;
			dy = _y - ty - dy;
			dz = _z - tz - dz;
			_r = radius;
		}
		var d = dx * dx + dy * dy + dz * dz;
		if (d >= _r * _r || d <= 0) return false;
		var _d = sqrt(d);
		_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, _r - _d, slope);
		return true;
	}

	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		var D = clamp((_x - x) * xup + (_y - y) * yup + (_z - z) * zup, 0, H);
		var tx = x + xup * D;
		var ty = y + yup * D;
		var tz = z + zup * D;
		var dx = _x - tx;
		var dy = _y - ty;
		var dz = _z - tz;
		if (D <= 0 || D >= H)
		{
			var dp = dx * xup + dy * yup + dz * zup;
			dx -= xup * dp;
			dy -= yup * dp;
			dz -= zup * dp;
			var d = dx * dx + dy * dy + dz * dz;
			if (d > R * R)
			{
				var _d = R / sqrt(d);
				dx *= _d;
				dy *= _d;
				dz *= _d;
			}
			dx = _x - tx - dx;
			dy = _y - ty - dy;
			dz = _z - tz - dz;
			var d = dx * dx + dy * dy + dz * dz;
			if (d > maxR * maxR) return -1;
			return d;
		}
		var d = max(sqrt(dx * dx + dy * dy + dz * dz) - R, 0);
		if (d > maxR) return -1;
		return d * d;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		var p = _getClosestPoint(bX, bY, bZ);
		var dx = p[0] - bX, dy = p[1] - bY, dz = p[2] - bZ;
		if (abs(dx) > hsize || abs(dy) > hsize || abs(dz) > hsize) return false;
		return true;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_torus(x, y, z, xup, yup, zup, R, r)
function colmesh_torus(_x, _y, _z, _xup, _yup, _zup, _R, _r) : colmesh_shapes() constructor
{
	type = eColMeshShape.Torus;
	x = _x;
	y = _y;
	z = _z;
	var l = sqrt(_xup * _xup + _yup * _yup + _zup * _zup);
	xup = _xup / l;
	yup = _yup / l;
	zup = _zup / l;
	R = _R;
	r = _r;
	var M = colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, R);
	var inv = colmesh_matrix_invert_fast(M, M);
	inv0 = inv[0];	inv1 = inv[1];	inv2 = inv[2];
	inv4 = inv[4];	inv5 = inv[5];	inv6 = inv[6];
	inv8 = inv[8];	inv9 = inv[9];	inv10 = inv[10];
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		var rr = R + r;
		ret[0] = x - rr;
		ret[1] = y - rr;
		ret[2] = z - rr;
		ret[3] = x + rr;
		ret[4] = y + rr;
		ret[5] = z + rr;
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, _xup, _yup, _zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var d = (_xup * xup + _yup * yup + _zup * zup);
		if (d != 0)
		{
			var d = ((x - _x) * xup + (y - _y) * yup + (z - _z) * zup) / d;
			repeat 2
			{
				var p = _getRingCoord(_x + _xup * d, _y + _yup * d, _z + _zup * d);
				d = clamp((p[0] - _x) * _xup + (p[1] - _y) * _yup + (p[2] - _z) * _zup, 0, height);
			}
		}
		else
		{
			d = clamp((x - _x) * _xup + (y - _y) * _yup + (z - _z) * _zup, 0, height);
		}
		ret[0] = _x + _xup * d;
		ret[1] = _y + _yup * d;
		ret[2] = _z + _zup * d;
		return ret;
	}
	
	/// @func _getRingCoord(x, y, z)
	static _getRingCoord = function(_x, _y, _z)
	{
		gml_pragma("forceinline");
		static ret = array_create(3);
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var dp = dx * xup + dy * yup + dz * zup;
		dx -= xup * dp;
		dy -= yup * dp;
		dz -= zup * dp;
		var l = dx * dx + dy * dy + dz * dz;
		if (l <= 0)
		{
			ret[0] = x + dx;
			ret[1] = y + dy;
			ret[2] = z + dz;
			return ret;
		}
		var _d = R / sqrt(l);
		ret[0] = x + dx * _d;
		ret[1] = y + dy * _d;
		ret[2] = z + dz * _d;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		/*
			Algorithm created by TheSnidr
			This is an approximation using the same principle as ray marching
		*/
		var _x = cmRay[0],	_y = cmRay[1],	_z = cmRay[2];
		var dx = _x - ox,	dy = _y - oy,	dz = _z - oz;
			ox -= x;		oy -= y;		oz -= z;
		var lox = inv0 * ox + inv4 * oy + inv8 * oz;
		var loy = inv1 * ox + inv5 * oy + inv9 * oz;
		var loz = inv2 * ox + inv6 * oy + inv10 * oz;
		var ldx = inv0 * dx + inv4 * dy + inv8 * dz;
		var ldy = inv1 * dx + inv5 * dy + inv9 * dz;
		var ldz = inv2 * dx + inv6 * dy + inv10 * dz;
		var radiusRatio = r / R;
		var repetitions = 15;
		var l = sqrt(ldx * ldx + ldy * ldy + ldz * ldz);
		ldx /= l;	ldy /= l;	ldz /= l;
		var p = 0, n = 0, d = 0;
		repeat repetitions 
		{
			p = n;
			n = (sqrt(sqr(sqrt(lox * lox + loy * loy) - 1) + loz * loz) - radiusRatio);
			d += n;
			if (p > 0 && n > R) return false; //The ray missed the torus, and we can remove it from the ray casting algorithm
			if (d > l) return false; //The ray did not reach the torus
			lox += ldx * n;	
			loy += ldy * n;
			loz += ldz * n;
		}
		if (n > p) return false; //If the new distance estimate is larger than the previous one, the ray must have missed a close point and is moving away from the object 
		d /= l;
		var itsX = x + ox + dx * d;
		var itsY = y + oy + dy * d;
		var itsZ = z + oz + dz * d;
		var p = _getRingCoord(itsX, itsY, itsZ);
		var nx = itsX - p[0];
		var ny = itsY - p[1];
		var nz = itsZ - p[2];
		var n = 1 / sqrt(nx * nx + ny * ny + nz * nz);
		cmRay[0] = itsX;
		cmRay[1] = itsY;
		cmRay[2] = itsZ;
		cmRay[3] = nx * n;
		cmRay[4] = ny * n;
		cmRay[5] = nz * n;
		cmRay[6] = self;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var p = _getRingCoord(_x, _y, _z);
		var dx = _x - p[0];
		var dy = _y - p[1];
		var dz = _z - p[2];
		var d = dx * dx + dy * dy + dz * dz;
		if (d > 0)
		{
			var _d = sqrt(d);
			dx /= _d;
			dy /= _d;
			dz /= _d;
			ret[@ 0] = p[0] + dx * r;
			ret[@ 1] = p[1] + dy * r;
			ret[@ 2] = p[2] + dz * r;
			return ret;
		}
		ret[@ 0] = _x;
		ret[@ 1] = _y;
		ret[@ 2] = _z;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		gml_pragma("forceinline");
		var p = _getRingCoord(_x, _y, _z);
		var dx = _x - p[0];
		var dy = _y - p[1];
		var dz = _z - p[2];
		var d = dx * dx + dy * dy + dz * dz;
		var _r = r + radius;
		if (d > _r * _r) return false;
		if (d > 0)
		{
			var _d = sqrt(d);
			_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, _r - _d, slope);
			return true;
		}
		_displace(xup, yup, zup, _xup, _yup, _zup, _r, slope);
		return true;
	}

	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		gml_pragma("forceinline");
		var p = _getRingCoord(_x, _y, _z);
		var dx = _x - p[0], dy = _y - p[1], dz = _z - p[2];
		var d = max(sqrt(dx * dx + dy * dy + dz * dz) - r, 0);
		if (d > maxR){return -1;}
		return d * d;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		var p = _getClosestPoint(bX, bY, bZ);
		var dx = p[0] - bX, dy = p[1] - bY, dz = p[2] - bZ;
		if (abs(dx) > hsize || abs(dy) > hsize || abs(dz) > hsize) return false;
		return true;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_disk(x, y, z, xup, yup, zup, R, r)
function colmesh_disk(_x, _y, _z, _xup, _yup, _zup, _R, _r) : colmesh_shapes() constructor
{
	type = eColMeshShape.Disk;
	x = _x;
	y = _y;
	z = _z;
	var l = sqrt(_xup * _xup + _yup * _yup + _zup * _zup);
	xup = _xup / l;
	yup = _yup / l;
	zup = _zup / l;
	R = _R;
	r = _r;
	var M = colmesh_matrix_build_from_vector(x, y, z, xup, yup, zup, R, R, R);
	var inv = colmesh_matrix_invert_fast(M, M);
	inv0 = inv[0];	inv1 = inv[1];	inv2 = inv[2];
	inv4 = inv[4];	inv5 = inv[5];	inv6 = inv[6];
	inv8 = inv[8];	inv9 = inv[9];	inv10 = inv[10];
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		var rr = R + r;
		ret[0] = x - rr;
		ret[1] = y - rr;
		ret[2] = z - rr;
		ret[3] = x + rr;
		ret[4] = y + rr;
		ret[5] = z + rr;
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, _xup, _yup, _zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var d = (_xup * xup + _yup * yup + _zup * zup);
		if (d != 0)
		{
			var d = ((x - _x) * xup + (y - _y) * yup + (z - _z) * zup) / d;
			var p = _getDiskCoord(_x + _xup * d, _y + _yup * d, _z + _zup * d);
			d = clamp((p[0] - _x) * _xup + (p[1] - _y) * _yup + (p[2] - _z) * _zup, 0, height);
		}
		else
		{
			d = clamp((x - _x) * _xup + (y - _y) * _yup + (z - _z) * _zup, 0, height);
		}
		ret[0] = _x + _xup * d;
		ret[1] = _y + _yup * d;
		ret[2] = _z + _zup * d;
		return ret;
	}
	
	/// @func _getDiskCoord(x, y, z)
	static _getDiskCoord = function(_x, _y, _z)
	{
		gml_pragma("forceinline");
		static ret = array_create(3);
		var dx = _x - x;
		var dy = _y - y;
		var dz = _z - z;
		var dp = dx * xup + dy * yup + dz * zup;
		dx -= xup * dp;
		dy -= yup * dp;
		dz -= zup * dp;
		var l = dx * dx + dy * dy + dz * dz;
		if (l <= R * R)
		{
			ret[0] = x + dx;
			ret[1] = y + dy;
			ret[2] = z + dz;
			return ret;
		}
		var _d = R / sqrt(l);
		ret[0] = x + dx * _d;
		ret[1] = y + dy * _d;
		ret[2] = z + dz * _d;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		/*
			Algorithm created by TheSnidr
			This is an approximation using the same principle as ray marching
		*/
		var _x = cmRay[0],	_y = cmRay[1],	_z = cmRay[2];
		var dx = _x - ox,	dy = _y - oy,	dz = _z - oz;
			ox -= x;		oy -= y;		oz -= z;
		var lox = inv0 * ox + inv4 * oy + inv8 * oz;
		var loy = inv1 * ox + inv5 * oy + inv9 * oz;
		var loz = inv2 * ox + inv6 * oy + inv10 * oz;
		var ldx = inv0 * dx + inv4 * dy + inv8 * dz;
		var ldy = inv1 * dx + inv5 * dy + inv9 * dz;
		var ldz = inv2 * dx + inv6 * dy + inv10 * dz;
		var radiusRatio = r / R;
		var repetitions = 15;
		var l = sqrt(ldx * ldx + ldy * ldy + ldz * ldz);
		ldx /= l;	ldy /= l;	ldz /= l;
		var p = 0, n = 0, d = 0;
		repeat repetitions 
		{
			p = n;
			n = (sqrt(sqr(max(0., sqrt(lox * lox + loy * loy) - 1)) + loz * loz) - radiusRatio);
			d += n;
			if (p > 0 && n > R) return false; //The ray missed the torus, and we can remove it from the ray casting algorithm
			if (d > l) return false; //The ray did not reach the torus
			lox += ldx * n;	
			loy += ldy * n;
			loz += ldz * n;
		}
		if (n > p) return false; //If the new distance estimate is larger than the previous one, the ray must have missed a close point and is moving away from the object 
		d /= l;
		var itsX = x + ox + dx * d;
		var itsY = y + oy + dy * d;
		var itsZ = z + oz + dz * d;
		var p = _getDiskCoord(itsX, itsY, itsZ);
		var nx = itsX - p[0];
		var ny = itsY - p[1];
		var nz = itsZ - p[2];
		var n = 1 / sqrt(nx * nx + ny * ny + nz * nz);
		cmRay[0] = itsX;
		cmRay[1] = itsY;
		cmRay[2] = itsZ;
		cmRay[3] = nx * n;
		cmRay[4] = ny * n;
		cmRay[5] = nz * n;
		cmRay[6] = self;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		var p = _getDiskCoord(_x, _y, _z);
		var dx = _x - p[0];
		var dy = _y - p[1];
		var dz = _z - p[2];
		var d = dx * dx + dy * dy + dz * dz;
		if (d > 0)
		{
			var _d = sqrt(d);
			dx /= _d;
			dy /= _d;
			dz /= _d;
			ret[@ 0] = p[0] + dx * r;
			ret[@ 1] = p[1] + dy * r;
			ret[@ 2] = p[2] + dz * r;
			return ret;
		}
		ret[@ 0] = _x;
		ret[@ 1] = _y;
		ret[@ 2] = _z;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		gml_pragma("forceinline");
		var p = _getDiskCoord(_x, _y, _z);
		var dx = _x - p[0];
		var dy = _y - p[1];
		var dz = _z - p[2];
		var d = dx * dx + dy * dy + dz * dz;
		var _r = r + radius;
		if (d > _r * _r) return false;
		if (d > 0)
		{
			var _d = sqrt(d);
			_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, _r - _d, slope);
			return true;
		}
		_displace(xup, yup, zup, _xup, _yup, _zup, _r, slope);
		return true;
	}

	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		gml_pragma("forceinline");
		var p = _getDiskCoord(_x, _y, _z);
		var dx = _x - p[0], dy = _y - p[1], dz = _z - p[2];
		var d = max(sqrt(dx * dx + dy * dy + dz * dz) - r, 0);
		if (d > maxR){return -1;}
		return d * d;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		var p = _getClosestPoint(bX, bY, bZ);
		var dx = p[0] - bX, dy = p[1] - bY, dz = p[2] - bZ;
		if (abs(dx) > hsize || abs(dy) > hsize || abs(dz) > hsize) return false;
		return true;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_cube(x, y, z, sideLength)
function colmesh_cube(_x, _y, _z, sideLength) : colmesh_shapes() constructor
{
	type = eColMeshShape.Cube;
	x = _x;
	y = _y;
	z = _z;
	hsize = sideLength / 2;
	
	#region functions
		
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		ret[0] = x - hsize;
		ret[1] = y - hsize;
		ret[2] = z - hsize;
		ret[3] = x + hsize;
		ret[4] = y + hsize;
		ret[5] = z + hsize;
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, xup, yup, zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		//Check bottom
		var bx = x + clamp(_x - x, -hsize, hsize);
		var by = y + clamp(_y - y, -hsize, hsize);
		var bz = z + clamp(_z - z, -hsize, hsize);
		var d = clamp((bx - _x) * xup + (by - _y) * yup + (bz - _z) * zup, 0, height);
		var rx1 = _x + xup * d;
		var ry1 = _y + yup * d;
		var rz1 = _z + zup * d;
		var d1 = sqr(rx1 - bx) + sqr(ry1 - by) + sqr(rz1 - bz);
		
		//Check top
		var bx = x + clamp(_x + xup * height - x, -hsize, hsize);
		var by = y + clamp(_y + yup * height - y, -hsize, hsize);
		var bz = z + clamp(_z + zup * height - z, -hsize, hsize);
		var d = clamp((bx - _x) * xup + (by - _y) * yup + (bz - _z) * zup, 0, height);
		var rx2 = _x + xup * d;
		var ry2 = _y + yup * d;
		var rz2 = _z + zup * d;
		if (sqr(rx2 - bx) + sqr(ry2 - by) + sqr(rz2 - bz) < d1)
		{
			ret[0] = rx2;
			ret[1] = ry2;
			ret[2] = rz2;
			return ret;
		}
		ret[0] = rx1;
		ret[1] = ry1;
		ret[2] = rz1;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		//Algorithm created by TheSnidr
		var t = 2;
		var x1 = ox - x;
		var y1 = oy - y;
		var z1 = oz - z;
		var x2 = cmRay[0] - x;
		var y2 = cmRay[1] - y;
		var z2 = cmRay[2] - z;
		var nx = 0, ny = 0, nz = 0;
		var intersection = false;
		var insideBlock = true;
		if (x2 != x1 && abs(x1) > hsize)
		{
			insideBlock = false;
			var s = hsize * sign(x1 - x2);
			var _t = (s - x1) / (x2 - x1);
			if (_t > 1)
			{
				t = min(t, _t);
			}
			else if (_t >= 0 && _t <= 1)
			{
				var itsY = lerp(y1, y2, _t);
				var itsZ = lerp(z1, z2, _t);
				if (abs(itsY) <= hsize && abs(itsZ) <= hsize)
				{
					t = _t;
					x2 = s;
					y2 = itsY;
					z2 = itsZ;
					nx = sign(z1);
					intersection = true;
				}
			}
		}
		if (y2 != y1 && abs(y1) > hsize)
		{
			insideBlock = false;
			var s = hsize * sign(y1 - y2);
			var _t = (s - y1) / (y2 - y1);
			if (_t > 1)
			{
				t = min(t, _t);
			}
			else if (_t >= 0 && _t <= 1)
			{
				var itsX = lerp(x1, x2, _t);
				var itsZ = lerp(z1, z2, _t);
				if (abs(itsX) <= hsize && abs(itsZ) <= hsize)
				{
					t = _t;
					x2 = itsX;
					y2 = s;
					z2 = itsZ;
					nx = 0; ny = sign(y1); nz = 0;
					intersection = true;
				}
			}
		}
		if (z2 != z1 && abs(z1) > hsize)
		{
			insideBlock = false;
			var s = hsize * sign(z1 - z2);
			var _t = (s - z1) / (z2 - z1);
			if (_t > 1)
			{
				t = min(t, _t);
			}
			else if (_t >= 0 && _t <= 1)
			{
				var itsX = lerp(x1, x2, _t);
				var itsY = lerp(y1, y2, _t);
				if (abs(itsX) <= hsize && abs(itsY) <= hsize)
				{
					t = _t;
					x2 = itsX;
					y2 = itsY;
					z2 = s;
					nx = 0; ny = 0; nz = sign(z1);
					intersection = true;
				}
			}
		}
		if (insideBlock || !intersection) return false;

		///////////////////////////////////////////////////////////////////
		//Return the point of intersection in world space
		cmRay[0] = x + x2;
		cmRay[1] = y + y2;
		cmRay[2] = z + z2;
		cmRay[3] = nx;
		cmRay[4] = ny;
		cmRay[5] = nz;
		cmRay[6] = self;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		static ret = array_create(3);
		//Find normalized block space position
		var bx = _x - x;
		var by = _y - y;
		var bz = _z - z;
		var b = max(abs(bx), abs(by), abs(bz));
		var nx = 0, ny = 0, nz = 0;
		
		//If the center of the sphere is inside the cube, normalize the largest axis
		if (b <= hsize)
		{
			if (b == abs(bx))
			{
				nx = sign(bx);
				bx = hsize * nx;
			}
			else if (b == abs(by))
			{
				ny = sign(by);
				by = hsize * ny;
			}
			else
			{
				nz = sign(bz);
				bz = hsize * nz;
			}
			bx += x;
			by += y;
			bz += z;
			ret[@ 6] = sqr(bx - _x) + sqr(by - _y) + sqr(bz - _z);
		}
		else
		{	//Nearest point on the cube in normalized block space
			bx = x + clamp(bx, -hsize, hsize);
			by = y + clamp(by, -hsize, hsize);
			bz = z + clamp(bz, -hsize, hsize);
		}
		ret[@ 0] = bx;
		ret[@ 1] = by;
		ret[@ 2] = bz;
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		//Find normalized block space position
		var bx = _x - x;
		var by = _y - y;
		var bz = _z - z;
		var b = max(abs(bx), abs(by), abs(bz));
		var nx = 0, ny = 0, nz = 0;
		var D = 0;
		
		//If the center of the sphere is inside the cube, normalize the largest axis
		if (b <= hsize)
		{
			if (b == abs(bx))
			{
				nx = sign(bx);
				bx = hsize * nx;
			}
			else if (b == abs(by))
			{
				ny = sign(by);
				by = hsize * ny;
			}
			else
			{
				nz = sign(bz);
				bz = hsize * nz;
			}
			bx += x;
			by += y;
			bz += z;
			var dx = _x - bx;
			var dy = _y - by;
			var dz = _z - bz;
			var _d = dx * nx + dy * ny + dz * nz;
			_displace(nx, ny, nz, _xup, _yup, _zup, radius - _d, slope);
			return true;
		}
		//Nearest point on the cube in normalized block space
		bx = x + clamp(bx, -hsize, hsize);
		by = y + clamp(by, -hsize, hsize);
		bz = z + clamp(bz, -hsize, hsize);
		var dx = _x - bx;
		var dy = _y - by;
		var dz = _z - bz;
		var d = dx * dx + dy * dy + dz * dz;
		if (d > radius * radius) return false;
		var _d = sqrt(d);
		_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, radius - _d, slope);
		return true;
	}
	
	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		//Find normalized block space position
		var bx = _x - x;
		var by = _y - y;
		var bz = _z - z;
		var b = max(abs(bx), abs(by), abs(bz));
		if (b <= hsize)
		{
			return 0; //0 is the highest possible priority
		}
		//Nearest point on the cube in normalized block space
		bx = x + clamp(bx, -hsize, hsize);
		by = y + clamp(by, -hsize, hsize);
		bz = z + clamp(bz, -hsize, hsize);
		var dx = _x - bx;
		var dy = _y - by;
		var dz = _z - bz;
		var d = dx * dx + dy * dy + dz * dz;
		if (d > maxR * maxR){return -1;}
		return d;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(_hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		if	(x - hsize > bX + _hsize) ||
			(x + hsize < bX - _hsize) ||
			(y - hsize > bY + _hsize) ||
			(y + hsize < bY - _hsize) ||
			(z - hsize > bZ + _hsize) ||
			(z + hsize < bZ - _hsize) return false;
		return true;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		x = _x;
		y = _y;
		z = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_block(blockMatrix)
function colmesh_block(_M) : colmesh_shapes() constructor
{
	type = eColMeshShape.Block;
	M = _M;
	lx = 1 / sqrt(M[0] * M[0] + M[1] * M[1] + M[2] * M[2]);
	ly = 1 / sqrt(M[4] * M[4] + M[5] * M[5] + M[6] * M[6]);
	lz = 1 / sqrt(M[8] * M[8] + M[9] * M[9] + M[10] * M[10]);
	
	//Remove any potential shear from the matrix
	colmesh_matrix_orthogonalize(M);
	colmesh_matrix_scale(M, 1 / lx, 1 / ly, 1 / lz);
	
	var inv = colmesh_matrix_invert_fast(M, matrix_build_identity());
	inv0  = inv[0];		inv1  = inv[1];		inv2  = inv[2];
	inv4  = inv[4];		inv5  = inv[5];		inv6  = inv[6];
	inv8  = inv[8];		inv9  = inv[9];		inv10 = inv[10];	
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		var dx = abs(M[0]) + abs(M[4]) + abs(M[8]);
		var dy = abs(M[1]) + abs(M[5]) + abs(M[9]);
		var dz = abs(M[2]) + abs(M[6]) + abs(M[10]);
		ret[0] = M[12] - dx;
		ret[1] = M[13] - dy;
		ret[2] = M[14] - dz;
		ret[3] = M[12] + dx;
		ret[4] = M[13] + dy;
		ret[5] = M[14] + dz;
		return ret;
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, xup, yup, zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		gml_pragma("forceinline");
		static ret = array_create(3);
		
		//Check bottom of capsule
		var xx = _x - M[12];
		var yy = _y - M[13];
		var zz = _z - M[14];
		var bx = clamp(xx * inv0 + yy * inv4 + zz * inv8, -1, 1);
		var by = clamp(xx * inv1 + yy * inv5 + zz * inv9, -1, 1);
		var bz = clamp(xx * inv2 + yy * inv6 + zz * inv10, -1, 1);
		var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
		var d = clamp((p[0] - _x) * xup + (p[1] - _y) * yup + (p[2] - _z) * zup, 0, height);
		var rx1 = _x + xup * d;
		var ry1 = _y + yup * d;
		var rz1 = _z + zup * d;
		var d1 = sqr(rx1 - p[0]) + sqr(ry1 - p[1]) + sqr(rz1 - p[2]);
		
		//Check top of capsule
		xx += xup * height;
		yy += yup * height;
		zz += zup * height;
		var bx = clamp(xx * inv0 + yy * inv4 + zz * inv8, -1, 1);
		var by = clamp(xx * inv1 + yy * inv5 + zz * inv9, -1, 1);
		var bz = clamp(xx * inv2 + yy * inv6 + zz * inv10, -1, 1);
		var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
		var d = clamp((p[0] - _x) * xup + (p[1] - _y) * yup + (p[2] - _z) * zup, 0, height);
		var rx2 = _x + xup * d;
		var ry2 = _y + yup * d;
		var rz2 = _z + zup * d;
		if (sqr(rx2 - p[0]) + sqr(ry2 - p[1]) + sqr(rz2 - p[2]) < d1)
		{
			ret[0] = rx2;
			ret[1] = ry2;
			ret[2] = rz2;
			return ret;
		}
		ret[0] = rx1;
		ret[1] = ry1;
		ret[2] = rz1;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		//Algorithm created by TheSnidr
		var t = 2;
		ox -= M[12];	oy -= M[13];	oz -= M[14];
		var tx = cmRay[0] - M[12], ty = cmRay[1] - M[13], tz = cmRay[2] - M[14];
		var x1 = ox * inv0 + oy * inv4 + oz * inv8;
		var y1 = ox * inv1 + oy * inv5 + oz * inv9;
		var z1 = ox * inv2 + oy * inv6 + oz * inv10;
		var x2 = tx * inv0 + ty * inv4 + tz * inv8;
		var y2 = tx * inv1 + ty * inv5 + tz * inv9;
		var z2 = tx * inv2 + ty * inv6 + tz * inv10;
		var nx = 0, ny = 0, nz = 1;
		var intersection = false;
		var insideBlock = true;
		if (x2 != x1 && abs(x1) > 1)
		{
			insideBlock = false;
			var s = sign(x1 - x2);
			var _t = (s - x1) / (x2 - x1);
			if (_t > 1)
			{
				t = min(t, _t);
			}
			else if (_t >= 0 && _t <= 1)
			{
				var itsY = lerp(y1, y2, _t);
				var itsZ = lerp(z1, z2, _t);
				if (abs(itsY) <= 1 && abs(itsZ) <= 1)
				{
					t = _t;
					x2 = s;
					y2 = itsY;
					z2 = itsZ;
					s = sign(x1) * lx;
					nx = M[0] * s;
					ny = M[1] * s;
					nz = M[2] * s;
					intersection = true;
				}
			}
		}
		if (y2 != y1 && abs(y1) > 1)
		{
			insideBlock = false;
			var s = sign(y1 - y2);
			var _t = (s - y1) / (y2 - y1);
			if (_t > 1)
			{
				t = min(t, _t);
			}
			else if (_t >= 0 && _t <= 1)
			{
				var itsX = lerp(x1, x2, _t);
				var itsZ = lerp(z1, z2, _t);
				if (abs(itsX) <= 1 && abs(itsZ) <= 1)
				{
					t = _t;
					x2 = itsX;
					y2 = s;
					z2 = itsZ;
					s = sign(y1) * ly;
					nx = M[4] * s;
					ny = M[5] * s;
					nz = M[6] * s;
					intersection = true;
				}
			}
		}
		if (z2 != z1 && abs(z1) > 1)
		{
			insideBlock = false;
			var s = sign(z1 - z2);
			var _t = (s - z1) / (z2 - z1);
			if (_t > 1)
			{
				t = min(t, _t);
			}
			else if (_t >= 0 && _t <= 1)
			{
				var itsX = lerp(x1, x2, _t);
				var itsY = lerp(y1, y2, _t);
				if (abs(itsX) <= 1 && abs(itsY) <= 1)
				{
					t = _t;
					x2 = itsX;
					y2 = itsY;
					z2 = s;
					s = sign(z1) * lz;
					nx = M[8] * s;
					ny = M[9] * s;
					nz = M[10] * s;
					intersection = true;
				}
			}
		}
		if (insideBlock || !intersection) return false;

		///////////////////////////////////////////////////////////////////
		//Return the point of intersection in world space
		cmRay[0] = M[12] + x2 * M[0] + y2 * M[4] + z2 * M[8];
		cmRay[1] = M[13] + x2 * M[1] + y2 * M[5] + z2 * M[9];
		cmRay[2] = M[14] + x2 * M[2] + y2 * M[6] + z2 * M[10];
		cmRay[3] = nx;
		cmRay[4] = ny;
		cmRay[5] = nz;
		cmRay[6] = self;
		return true;
	}
		
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		static ret = array_create(3);
		//Find normalized block space position
		_x -= M[12];
		_y -= M[13];
		_z -= M[14];
		var bx = _x * inv0 + _y * inv4 + _z * inv8;
		var by = _x * inv1 + _y * inv5 + _z * inv9;
		var bz = _x * inv2 + _y * inv6 + _z * inv10;
		var b = max(abs(bx), abs(by), abs(bz));
		
		//If the center of the sphere is inside the cube, normalize the largest axis
		if (b <= 1){
			if (b == abs(bx)){
				bx = sign(bx);
			}
			else if (b == abs(by)){
				by = sign(by);
			}
			else{
				bz = sign(bz);
			}
			var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
			ret[@ 6] = 0;
		}
		else
		{	//Nearest point on the cube in normalized block space
			bx = clamp(bx, -1, 1);
			by = clamp(by, -1, 1);
			bz = clamp(bz, -1, 1);
			var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
		}
		ret[@ 0] = p[0];
		ret[@ 1] = p[1];
		ret[@ 2] = p[2];
		return ret;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(_x, _y, _z, _xup, _yup, _zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		//Find normalized block space position
		var xx = _x - M[12];
		var yy = _y - M[13];
		var zz = _z - M[14];
		var bx = xx * inv0 + yy * inv4 + zz * inv8;
		var by = xx * inv1 + yy * inv5 + zz * inv9;
		var bz = xx * inv2 + yy * inv6 + zz * inv10;
		var b = max(abs(bx), abs(by), abs(bz));
		var nx = 0, ny = 0, nz = 0;
		//If the center of the sphere is inside the cube, normalize the largest axis
		if (b <= 1)
		{
			if (b == abs(bx))
			{
				nx = M[0] * lx;
				ny = M[1] * lx;
				nz = M[2] * lx;
			}
			else if (b == abs(by))
			{
				by = sign(by);
				nx = M[4] * ly;
				ny = M[5] * ly;
				nz = M[6] * ly;
			}
			else
			{
				bz = sign(bz);
				nx = M[8] * lz;
				ny = M[9] * lz;
				nz = M[10] * lz;
			}
			var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
			var dx = _x - p[0];
			var dy = _y - p[1];
			var dz = _z - p[2];
			var _d = dx * nx + dy * ny + dz * nz;
			_displace(nx, ny, nz, _xup, _yup, _zup, radius - _d, slope);
			return true;
		}
		//Nearest point on the cube in normalized block space
		bx = clamp(bx, -1, 1);
		by = clamp(by, -1, 1);
		bz = clamp(bz, -1, 1);
		var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
		var dx = _x - p[0];
		var dy = _y - p[1];
		var dz = _z - p[2];
		var d = dx * dx + dy * dy + dz * dz;
		if (d > radius * radius) return false;
		var _d = sqrt(d);
		_displace(dx / _d, dy / _d, dz / _d, _xup, _yup, _zup, radius - _d, slope);
		return true;
	}
	
	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		//Find normalized block space position
		var xx = _x - M[12];
		var yy = _y - M[13];
		var zz = _z - M[14];
		var bx = xx * inv0 + yy * inv4 + zz * inv8;
		var by = xx * inv1 + yy * inv5 + zz * inv9;
		var bz = xx * inv2 + yy * inv6 + zz * inv10;
		var b = max(abs(bx), abs(by), abs(bz));
		if (b <= 1)
		{	//If the center of the sphere is inside the cube, normalize the largest axis
			return 0; //0 is the highest possible priority
		}
		//Nearest point on the cube in normalized block space
		bx = clamp(bx, -1, 1);
		by = clamp(by, -1, 1);
		bz = clamp(bz, -1, 1);
		var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
		var dx = _x - p[0];
		var dy = _y - p[1];
		var dz = _z - p[2];
		var d = dx * dx + dy * dy + dz * dz;
		if (d > maxR * maxR){return -1;}
		return d;
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ) 
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns true if the shape intersects the given axis-aligned cube
		*/
		//First check if the nearest point in the AABB to the cube is inside the cube
		bX -= M[12];
		bY -= M[13];
		bZ -= M[14];
		var dx = bX - clamp(bX, -hsize, hsize);
		var dy = bY - clamp(bY, -hsize, hsize);
		var dz = bZ - clamp(bZ, -hsize, hsize);
		
		//Find normalized block space position
		var bx = dx * inv0 + dy * inv4 + dz * inv8;
		var by = dx * inv1 + dy * inv5 + dz * inv9;
		var bz = dx * inv2 + dy * inv6 + dz * inv10;
		if (max(abs(bx), abs(by), abs(bz)) < 1) return true;
		
		//Then check if the nearest point in the cube is inside the AABB
		bx = clamp(bX * inv0 + bY * inv4 + bZ * inv8, -1, 1);
		by = clamp(bX * inv1 + bY * inv5 + bZ * inv9, -1, 1);
		bz = clamp(bX * inv2 + bY * inv6 + bZ * inv10, -1, 1);
		dx = M[12] + bx * M[0] + by * M[4] + bz * M[8] - bX;
		dy = M[13] + bx * M[1] + by * M[5] + bz * M[9] - bY;
		dz = M[14] + bx * M[2] + by * M[6] + bz * M[10] - bZ;
		if (max(abs(dx), abs(dy), abs(dz)) < hsize) return true;
		
		return false;
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		var oldMM = getMinMax();
		M[12] = _x;
		M[13] = _y;
		M[14] = _z;
		_updateSubdiv(colMesh, oldMM);
	}
	
	#endregion
}

/// @func colmesh_dynamic(shape, colMesh, M, shapeInd)
function colmesh_dynamic(_shape, _colMesh, _M, _shapeInd) : colmesh_shapes() constructor
{
	type = eColMeshShape.Dynamic;
	shape = _shape;
	colMesh = _colMesh;
	shapeInd = _shapeInd;
	M = matrix_build_identity(); //World matrix
	I = matrix_build_identity(); //Inverse world matrix
	pI = matrix_build_identity(); //Previous inverse world matrix
	scale = 1;
	moving = false;
	
	#region Shared functions (this is only overwritten for the dynamic
	
	/// @func capsuleCollision(x, y, z, xup, yup, zup, radius, height)
	static capsuleCollision = function(x, y, z, xup, yup, zup, radius, height)
	{
		//Returns true if the given capsule collides with the shape
		var xx = I[0] * x + I[4] * y + I[8] * z + I[12];
		var yy = I[1] * x + I[5] * y + I[9] * z + I[13];
		var zz = I[2] * x + I[6] * y + I[10]* z + I[14];
		var ux = (I[0] * xup + I[4] * yup + I[8] * zup) * scale;
		var uy = (I[1] * xup + I[5] * yup + I[9] * zup) * scale;
		var uz = (I[2] * xup + I[6] * yup + I[10]* zup) * scale;
		return shape.capsuleCollision(xx, yy, zz, ux, uy, uz, radius / scale, height / scale);
	}
	
	#endregion
	
	#region Shape-specific functions
	
	/// @func setMatrix(M, moving)
	static setMatrix = function(_M, _moving) 
	{	
		/*	
			This script lets you make it seem like a colmesh instance has been transformed.
			What really happens though, is that the collision shape is transformed by the inverse of the given matrix, 
			then it performs collision checks, and then it is transformed back. This is an efficient process.
			This script creates a new matrix from the given matrix, making sure that all the vectors are perpendicular, 
			and making sure the scaling is uniform (using the scale in the first column as reference).
		*/
		moving = _moving;
		var oldMM = getMinMax();
		array_copy(M, 0, _M, 0, 16);

		//Orthogonalize the side vector
		var sqrScale = M[0] * M[0] + M[1] * M[1] + M[2] * M[2];
		var sideDp = (M[0] * M[4] + M[1] * M[5] + M[2] * M[6]) / sqrScale;
		M[4] -= M[0] * sideDp;
		M[5] -= M[1] * sideDp;
		M[6] -= M[2] * sideDp;
		var l = M[4] * M[4] + M[5] * M[5] + M[6] * M[6];
		if (l <= 0){return false;}
		scale = sqrt(sqrScale);
		l = scale / max(sqrt(l), 0.00001);
		M[4] *= l;	M[@ 5] *= l;	M[@ 6] *= l;

		//Orthogonalize the up vector
		M[8] = (M[1] * M[6] - M[2] * M[5]) / scale;
		M[9] = (M[2] * M[4] - M[0] * M[6]) / scale;
		M[10]= (M[0] * M[5] - M[1] * M[4]) / scale;
		
		M[3] = 0;
		M[7] = 0;
		M[11] = 0;
		M[15] = 1;
		
		if (moving)
		{	//If the object is moving, save the previous inverse matrix to pI
			array_copy(pI, 0, I, 0, 16);
		}
		colmesh_matrix_invert_fast(M, I);
		
		//Update the spatial hash
		_updateSubdiv(colMesh, oldMM);
	}
	
	/// @func move(colMesh, x, y, z)
	static move = function(colMesh, _x, _y, _z)
	{
		static temp = matrix_build_identity();
		array_copy(temp, 0, M, 0, 16);
		temp[12] = _x;
		temp[13] = _y;
		temp[14] = _z;
		setMatrix(temp, true);
	}
	
	#endregion
	
	#region functions
	
	/// @func getMinMax()
	static getMinMax = function()
	{
		/*
			Returns the AABB of the shape as an array with six values
		*/
		static ret = array_create(6);
		if (shape.type == eColMeshShape.Mesh)
		{
			array_copy(ret, 0, shape.minimum, 0, 3);
			array_copy(ret, 3, shape.maximum, 0, 3);
			var mm = ret;
		}
		else
		{
			var mm = shape.getMinMax();
		}
		var xs = (mm[3] - mm[0]) * .5;
		var ys = (mm[4] - mm[1]) * .5;
		var zs = (mm[5] - mm[2]) * .5;
		var mx = (mm[0] + mm[3]) * .5;
		var my = (mm[1] + mm[4]) * .5;
		var mz = (mm[2] + mm[5]) * .5;
		var tx = M[12] + M[0] * mx + M[4] * my + M[8] * mz;
		var ty = M[13] + M[1] * mx + M[5] * my + M[9] * mz;
		var tz = M[14] + M[2] * mx + M[6] * my + M[10]* mz;
		var dx = abs(M[0] * xs) + abs(M[4] * ys) + abs(M[8] * zs);
		var dy = abs(M[1] * xs) + abs(M[5] * ys) + abs(M[9] * zs);
		var dz = abs(M[2] * xs) + abs(M[6] * ys) + abs(M[10]* zs);
		ret[0] = tx - dx;
		ret[1] = ty - dy;
		ret[2] = tz - dz;
		ret[3] = tx + dx;
		ret[4] = ty + dy;
		ret[5] = tz + dz;
		return ret;
	}
	
	/// @func _castRay(ox, oy, oz)
	static _castRay = function(ox, oy, oz)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.castRay
			Changes the global array cmRay if the ray intersects the shape
		*/
		//Make a copy of the ray, since the ray casting process might change this
		static temp = array_create(7);
		array_copy(temp, 0, cmRay, 0, 7);
		
		//Transform the ray to local space
		var ex = cmRay[0], ey = cmRay[1], ez = cmRay[2];
		cmRay[0] = I[0] * ex + I[4] * ey + I[8] * ez + I[12];
		cmRay[1] = I[1] * ex + I[5] * ey + I[9] * ez + I[13];
		cmRay[2] = I[2] * ex + I[6] * ey + I[10]* ez + I[14];
		cmRay[3] = I[0] * ox + I[4] * oy + I[8] * oz + I[12];
		cmRay[4] = I[1] * ox + I[5] * oy + I[9] * oz + I[13];
		cmRay[5] = I[2] * ox + I[6] * oy + I[10]* oz + I[14];
		
		var success = false;
		if (shape.type == eColMeshShape.Mesh)
		{
			//If this is a mesh, we want to raycast against all the shapes the mesh contains
			success = is_array(shape.castRay(cmRay[3], cmRay[4], cmRay[5], cmRay[0], cmRay[1], cmRay[2]));
		}
		else
		{
			//If this is not a mesh, we can raycast against just this shape
			success = shape._castRay(cmRay[3], cmRay[4], cmRay[5]);
		}
		if (!success)
		{
			array_copy(cmRay, 0, temp, 0, 7);
			return false;
		}
		var ex = cmRay[0], ey = cmRay[1], ez = cmRay[2];
		var nx = cmRay[3], ny = cmRay[4], nz = cmRay[5];
		cmRay[0] = M[0] * ex + M[4] * ey + M[8] * ez + M[12];
		cmRay[1] = M[1] * ex + M[5] * ey + M[9] * ez + M[13];
		cmRay[2] = M[2] * ex + M[6] * ey + M[10]* ez + M[14];
		cmRay[3] = (M[0] * nx + M[4] * ny + M[8] * nz) / scale;
		cmRay[4] = (M[1] * nx + M[5] * ny + M[9] * nz) / scale;
		cmRay[5] = (M[2] * nx + M[6] * ny + M[10]* nz) / scale;
		return true;
	}
	
	/// @func _getClosestPoint(x, y, z)
	static _getClosestPoint = function(_x, _y, _z)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Used by colmesh.getClosestPoint
		*/
		if (shape.type == eColMeshShape.Mesh)
		{
			//Find normalized block space position
			var bx = I[12] + _x * I[0] + _y * I[4] + _z * I[8];
			var by = I[13] + _x * I[1] + _y * I[5] + _z * I[9];
			var bz = I[14] + _x * I[2] + _y * I[6] + _z * I[10];
			var b = max(abs(bx), abs(by), abs(bz));
			var nx = 0, ny = 0, nz = 0;
		
			//If the center of the sphere is inside the cube, normalize the largest axis
			if (b <= 1){
				if (b == abs(bx)){
					bx = sign(bx);
				}
				else if (b == abs(by)){
					by = sign(by);
				}
				else{
					bz = sign(bz);
				}
				var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
				cmCol[0] = p[0];
			}
			else
			{	//Nearest point on the cube in normalized block space
				bx = clamp(bx, -1, 1);
				by = clamp(by, -1, 1);
				bz = clamp(bz, -1, 1);
				var p = colmesh_matrix_transform_vertex(M, bx, by, bz);
			}
			cmCol[@ 0] = p[0];
			cmCol[@ 1] = p[1];
			cmCol[@ 2] = p[2];
			return cmCol;
		}
		var p = colmesh_matrix_transform_vertex(I, _x, _y, _z);
		var n = shape._getClosestPoint(p[0], p[1], p[2]);
		return colmesh_matrix_transform_vertex(M, _x, _y, _z);
	}
	
	/// @func _capsuleGetRef(x, y, z, xup, yup, zup, height)
	static _capsuleGetRef = function(_x, _y, _z, xup, yup, zup, height)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns the nearest point along the given capsule to the shape.
		*/
		if (shape.type == eColMeshShape.Mesh)
		{
			//If the dynamic contains a mesh, there's no point in finding the actual reference at this time. Return the input position.
			static ret = array_create(3);
			ret[0] = _x;
			ret[1] = _y;
			ret[2] = _z;
			return ret;
		}
		var p = colmesh_matrix_transform_vertex(I, _x, _y, _z);
		_x = p[0]; _y = p[1]; _z = p[2];
		var u = colmesh_matrix_transform_vector(I, xup * scale, yup * scale, zup * scale);
		var r = shape._capsuleGetRef(_x, _y, _z, u[0], u[1], u[2], height / scale);
		return colmesh_matrix_transform_vertex(M, r[0], r[1], r[2]);
	}
	
	/// @func _intersectsCube(cubeHalfSize, cubeCenterX, cubeCenterY, cubeCenterZ)
	static _intersectsCube = function(hsize, bX, bY, bZ)
	{
		/*
			A supplementary function, not meant to be used by itself.
			For dynamic shapes it always returns true
		*/
		return true;
	}
	
	/// @func _displaceSphere(x, y, z, xup, yup, zup, height, radius, slope, fast)
	static _displaceSphere = function(x, y, z, xup, yup, zup, height, radius, slope, fast)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Pushes a sphere out of the shape by changing the global array cmCol
			Returns true if there was a collision.
		*/
		var temp = array_create(7);
		array_copy(temp, 0, cmCol, 0, 7);
		
		//cmCol contains the current position of the capsule in indices 0-3, and the current collision normal vector in indices 3-5
		var _x = cmCol[0], _y = cmCol[1], _z = cmCol[2];
		var nx = cmCol[3], ny = cmCol[4], nz = cmCol[5];
		cmCol[0] = I[0] * _x + I[4] * _y + I[8] * _z + I[12];
		cmCol[1] = I[1] * _x + I[5] * _y + I[9] * _z + I[13];
		cmCol[2] = I[2] * _x + I[6] * _y + I[10]* _z + I[14];
		cmCol[3] = (I[0] * nx + I[4] * ny + I[8] * nz) * scale;
		cmCol[4] = (I[1] * nx + I[5] * ny + I[9] * nz) * scale;
		cmCol[5] = (I[2] * nx + I[6] * ny + I[10]* nz) * scale;
		
		var _xup = (I[0] * xup + I[4] * yup + I[8] * zup) * scale;
		var _yup = (I[1] * xup + I[5] * yup + I[9] * zup) * scale;
		var _zup = (I[2] * xup + I[6] * yup + I[10]* zup) * scale;
		
		var col = false;
		if (shape.type == eColMeshShape.Mesh)
		{
			//Special case if this dynamic contains a mesh
			var slopeAngle = (slope >= 1) ? 0 : darccos(slope);
			shape.displaceCapsule(cmCol[0], cmCol[1], cmCol[2], _xup, _yup, _zup, radius / scale, height / scale, slopeAngle, fast);
			if (cmCol[6])
			{
				cmCol[6] = max(temp[6], _xup * cmCol[3] + _yup * cmCol[4] + _zup * cmCol[5]);
				col = true;
			}
		}
		else
		{
			//This dynamic contains a primitive
			var lx = I[0] * x + I[4] * y + I[8] * z + I[12];
			var ly = I[1] * x + I[5] * y + I[9] * z + I[13];
			var lz = I[2] * x + I[6] * y + I[10]* z + I[14];
			col = shape._displaceSphere(lx, ly, lz, _xup, _yup, _zup, height / scale, radius / scale, slope, fast);
		}
		if (col)
		{
			if (slope < 1 && cmTransform >= 0)
			{
				ds_queue_enqueue(cmTransform, M);
				if (moving)
				{
					//This object is moving. Save its current world matrix and the inverse of the previous 
					//world matrix so that figuring out the delta matrix later is as easy as a matrix multiplication
					ds_queue_enqueue(cmTransform, pI);
				}
				//If the transformation queue is empty, this is the first dynamic to be added. 
				//If it's static as well, there's no point in adding it to the transformation queue
				else if (!ds_queue_empty(cmTransform))
				{	
					//If the dynamic is not marked as "moving", save the current inverse matrix to the transformation 
					//queue so that no transformation is done. It will then only transform the preceding transformations
					//into its own frame of reference
					ds_queue_enqueue(cmTransform, I);
				}
			}
			//Transform collision position and normal to world-space
			var _x = cmCol[0], _y = cmCol[1], _z = cmCol[2];
			var nx = cmCol[3], ny = cmCol[4], nz = cmCol[5];
			cmCol[0] = M[0] * _x + M[4] * _y + M[8] * _z + M[12];
			cmCol[1] = M[1] * _x + M[5] * _y + M[9] * _z + M[13];
			cmCol[2] = M[2] * _x + M[6] * _y + M[10]* _z + M[14];
			cmCol[3] = (M[0] * nx + M[4] * ny + M[8] * nz) / scale;
			cmCol[4] = (M[1] * nx + M[5] * ny + M[9] * nz) / scale;
			cmCol[5] = (M[2] * nx + M[6] * ny + M[10]* nz) / scale;
			return true;
		}
		array_copy(cmCol, 0, temp, 0, 7);
		return false;
	}
	
	/// @func _getPriority(x, y, z, maxR)
	static _getPriority = function(_x, _y, _z, maxR)
	{
		/*
			A supplementary function, not meant to be used by itself.
			Returns -1 if the shape is too far away
			Returns the square of the distance between the shape and the given point
		*/
		if (shape.type == eColMeshShape.Mesh)
		{
			return 0; //0 is maximum priority
		}
		var p = colmesh_matrix_transform_vertex(I, _x, _y, _z);
		var pri = shape._getPriority(p[0], p[1], p[2], maxR / scale);
		return pri * scale * scale;
	}
	
	#endregion
	
	//Update the matrix
	setMatrix(_M, false);
}

function colmesh_none() constructor
{
	/*
		This is a failsafe object for when loading a ColMesh that contains dynamic objects
	*/
	type = eColMeshShape.None;
	static capsuleCollision = function(x, y, z, xup, yup, zup, radius, height){return false;}
	static _displace = function(nx, ny, nz, xup, yup, zup, _r, slope){}
	static _addToSubdiv = function(colMesh, ind){return 0;}
	static getMinMax = function()
	{
		static ret = array_create(6);
		return ret;
	}
	static _capsuleGetRef = function(_x, _y, _z, xup, yup, zup, height)
	{
		static ret = array_create(3);
		return ret;
	}
	static _castRay = function(ox, oy, oz){return false;}	
	static _displaceSphere = function(x, y, z, xup, yup, zup, height, radius, slope, fast){return false;}
	static _getPriority = function(x, y, z, maxR){return -1;}
	static _getClosestPoint = function(x, y, z)
	{
		static ret = array_create(3);
		return ret;
	}
	static _intersectsCube = function(hsize, bX, bY, bZ){return false;}
}