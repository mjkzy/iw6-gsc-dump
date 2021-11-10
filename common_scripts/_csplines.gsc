/*  ====== CUBIC HERMITE SPLINES =======
  
The difference between Hermite splines and Bezier curves is that Hermite splines go through all their nodes.  
Bezier splines touch their end points but use the other nodes to create tangents without actually going through them.

Vehicle splines aren't bezier, but they cut corners too.  

The advantage of these hermite cubic splines is that it's easy to know precisely how long it will take to travel the path.

Hermite spline code, from
http://www.siggraph.org/education/materials/HyperGraph/modeling/splines/hermite.htm
and
http://cubic.org/docs/hermite.htm
Given : Points P1, P4 Tangent vectors R1, R4 on the interval n = 0 to 1.
We want to make a cubic curve that goes through the two points with the correct direction at each point.
Consider each dimension separately.  Here's just the x component: x(n) = axn^3 + bxn^2 + cxn + dx
x(n) = P1x(2n^3 - 3n^2 + 1) + P4x(-2n^3 + 3n^2) + R1x(n^3 - 2n^2 + n) + R4x(n^3 - n^2)

So here's the matrix in a form that is easily usable to precompute coefficients
x(n) = (  2*P1x - 2*P4x +   R1x + R4x ) * n^3
	 + ( -3*P1x + 3*P4x - 2*R1x - R4x ) * n^2
	 + (                    R1x       ) * n
	 + (    P1x                       )

-------------------------------

Tangents
Since we're only given the points, we need to decide on some tangents.  For the end points, I'll set them so the 
acceleration is 0.  For the others, I'll use Cardinal splines:
R[i] = (1-tension) * ( P[i+1] - P[i-1] )

It's not that simple though, since the time between points is variable.
R[i] = R[i] * ( 2L[i-1] / ( L[i-1] + L[i] ) ) where L[i] is the length of the segment after R[i]

-------------------------------
*/

#include common_scripts\utility;

/* ====== Cubic Hermite Spline - Calculate Cardinal Tangent. ======
 * Given the points before and after and the length of the segments before and after, return the tangent at this point. 
 * Set tension to 0.5 for a Catmull-Rom spline.
 * nb Returns an "incoming" and an "outgoing" tangent.  They are the same tangent really, but scaled by the lengths so 
 * that when they are used with a normalized length in csplineSeg_calcCoeffs, they give a consistent result. */
cspline_calcTangent(P1, P3, Length1, Length2, tension)
{
	incoming = [];
	outgoing = [];
	for (i=0; i<3; i++)
	{
		incoming[i]  = ( 1 - tension ) * ( P3[i] - P1[i] );
		outgoing[i]  = incoming[i];
		incoming[i] *= ( 2*Length1 / ( Length1 + Length2 ) );
		outgoing[i] *= ( 2*Length2 / ( Length1 + Length2 ) );
	}
	R = [];
	R["incoming"] = ( incoming[0], incoming[1], incoming[2] );
	R["outgoing"] = ( outgoing[0], outgoing[1], outgoing[2] );
	return R;
}

/* ====== Cubic Hermite Spline - Calculate Kochanek-Bartels Tangent. ======
 * Given the points before and after and the length of the segments before and after, return the tangent at this point. 
 * nb Returns an "incoming" and an "outgoing" tangent.  They are the same tangent really, but scaled by the lengths so 
 * that when they are used with a normalized length in csplineSeg_calcCoeffs, they give a consistent result. */
cspline_calcTangentTCB(P1, P2, P3, Length1, Length2, t, c, b)
{
	incoming = [];
	outgoing = [];
	for (i=0; i<3; i++)
	{
		incoming[i]  = ( 1 - t ) * ( 1 - c ) * ( 1 + b) * 0.5 * ( P2[i] - P1[i] );
		incoming[i] += ( 1 - t ) * ( 1 + c ) * ( 1 - b) * 0.5 * ( P3[i] - P2[i] );
		incoming[i] *= ( 2*Length1 / ( Length1 + Length2 ) );
		outgoing[i]  = ( 1 - t ) * ( 1 + c ) * ( 1 + b) * 0.5 * ( P2[i] - P1[i] );
		outgoing[i] += ( 1 - t ) * ( 1 - c ) * ( 1 - b) * 0.5 * ( P3[i] - P2[i] );
		outgoing[i] *= ( 2*Length2 / ( Length1 + Length2 ) );
	}
	R = [];
	R["incoming"] = ( incoming[0], incoming[1], incoming[2] );
	R["outgoing"] = ( outgoing[0], outgoing[1], outgoing[2] );
	return R;
}

/* ====== Cubic Hermite Spline - Calculate Natural Tangent ====== 
 * Given two points and a tangent at one of them, returns a tangent for the other that will result in 0 acceleration at 
 * that point.  Note that:
 *		- it doesn't matter if tangent is for the start or end of the segment; the result is the same
 * 		- the return value is an array with identical components "incoming" and "outgoing". */
cspline_calcTangentNatural(P1, P2, R1)
{
	// As I understand it, natural splines are those which have constant velocity at the endpoints.
	// For no accn at P1, we need 
	// -3P1 + 3P2 - 2R1 - R2 = 0
	// 		R1[i] = ( -3*P1[i] + 3*P2[i] - R2[i] ) / 2
	// For no accn at P2, we need ( -3*P1[i] + 3*P2[i] - 2*R1[i] - R2[i] ) + 3*( 2*P1[i] - 2*P2[i] +   R1[i] + R2[i] ) = 0
	// -3P1 + 3P2 - 2R1 - R2 + 6P1 - 6P2 + 3R1 + 3R2 = 0
	// 3P1 - 3P2  + R1 + 2R2 = 0
	// 		R2[i] = ( -3*P1[i] + 3*P2[i] - R1[i] ) / 2
	numDimensions = 3;
	incoming = [];
	outgoing = [];
	if ( IsDefined( R1 ) )
	{
		for (i=0; i<numDimensions; i++)
		{
			incoming[i] = ( -3*P1[i] + 3*P2[i] - R1[i] ) / 2;
			outgoing[i] = incoming[i];	// Make them both the same, assume only the relevant one will be used.
		}
	}
	else
	{
		// No supplied tangent, therefore just point the new tangent along a straight line between the points.	
		for (i=0; i<numDimensions; i++)
		{
			incoming[i] = P2[i] - P1[i];
			outgoing[i] = P2[i] - P1[i];	// Make them both the same, assume only the relevant one will be used.
		}
	}
	R = [];
	R["incoming"] = ( incoming[0], incoming[1], incoming[2] );
	R["outgoing"] = ( outgoing[0], outgoing[1], outgoing[2] );
	return R;
}

/* ====== csplineSeg_calcCoeffs ====== 
 * Given points and tangents at either end, returns the coefficients for a cubic spline segment. */
csplineSeg_calcCoeffs(P1, P2, R1, R2)
{
	numDimensions = 3;
	segVars = SpawnStruct();
	segVars.n3 = [];
	segVars.n2 = [];
	segVars.n = [];
	segVars.c = [];
	for (i=0; i<numDimensions; i++)
	{
		segVars.n3[i] =  2*P1[i] - 2*P2[i] +   R1[i] + R2[i] ;
		segVars.n2[i] = -3*P1[i] + 3*P2[i] - 2*R1[i] - R2[i] ;
		segVars.n[i]  =                        R1[i]         ;
		segVars.c[i]  =    P1[i]                             ;
	}
	return segVars;
}

/* ====== csplineSeg_calcCoeffs ====== 
 * Given points and tangents at either end, returns the coefficients for a cubic spline segment. 
 * One problem with cubic spline paths is that the speed has no upper bound and commonly goes to 1.25 times the speed you want it to.
 * This function assumes the speed at the tangents is <= 1, and recalculates the segLength so that the speed in between doesn't exceed 1. */
csplineSeg_calcCoeffsCapSpeed(P1, P2, R1, R2, segLength)
{
	csSeg = csplineSeg_calcCoeffs( P1, P2, R1, R2 );
	//prof_begin("csplines_topspeed");
	topSpeed = csplineSeg_calcTopSpeed( csSeg, segLength );
	if ( topSpeed > 1 )
	{
		segLength *= topSpeed;
		R1 /= topSpeed;	// Keep the tangents the same.  We already know they're not too fast.  This isn't mathematically 
		R2 /= topSpeed;	// correct but it produces a nice curve.
		// And we need to recalculate the segment
		csSeg = csplineSeg_calcCoeffs( P1, P2, R1, R2 );
	}
	//prof_end("csplines_topspeed");
	csSeg.endAt = segLength;
	return csSeg;
}

// Returns the positions, velocities and accelerations of the node points along the spline path.
cspline_getNodes(csPath)
{
	array = [];
	segLength = csPath.Segments[0].endAt;
	array[0] = csplineSeg_getPoint( csPath.Segments[0], 0, segLength, csPath.Segments[0].speedStart );
	array[0]["time"] = 0;
	startDist = 0;
	for (segNum=0; segNum < csPath.Segments.size; segNum++)
	{
		segLength = csPath.Segments[segNum].endAt - startDist;
		array[segNum+1] = csplineSeg_getPoint( csPath.Segments[segNum], 1, segLength, csPath.Segments[segNum].speedEnd );
		posVelStart = csplineSeg_getPoint( csPath.Segments[segNum], 0, segLength, csPath.Segments[segNum].speedStart );
		array[segNum]["acc_out"] = posVelStart["acc"];
		array[segNum+1]["time"] = csPath.Segments[segNum].endTime;
		startDist = csPath.Segments[segNum].endAt;
	}
	array[csPath.Segments.size]["acc_out"] = array[csPath.Segments.size]["acc"];
	return array;
}
/*
=============
///ScriptDocBegin
"Name: csplineSeg_getPoint( <csplineSeg> , <x>, <segLength>, <speedMult> )"
"Summary: Given a Hermite Spline segment and a normalized distance along the segment, return position, velocity and acceleration vectors."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <csplineSeg>: a cubic Hermite spline segment - a struct containing n3, n2, n and c, each of which is an array of 3 floats."
"MandatoryArg: <x>: The distance along the segment.  0 <= x <= 1."
"OptionalArg: <segLength>: The length of this segment, used for calculating the correct velocity and acceleration."
"OptionalArg: <speedMult>: The current rate of movement along the path, also used for correcting the velocity and acceleration."
"Example: posVelArray = csplineSeg_getPoint( csPath.Segments[segNum], normalizedDistance );"
"SPMP: both"
///ScriptDocEnd
=============
*/
csplineSeg_getPoint(csplineSeg, x, segLength, speedMult )
{
	numDimensions = 3;//csplineSeg.n3.size;
	posArray = [];
	velArray = [];
	accArray = [];
	returnArray = [];
	for (i=0; i<numDimensions; i++)
	{
		posArray[i] = (csplineSeg.n3[i]*x*x*x) + (csplineSeg.n2[i]*x*x) + (csplineSeg.n[i]*x) + csplineSeg.c[i];
		velArray[i] = (3*csplineSeg.n3[i]*x*x) + (2*csplineSeg.n2[i]*x) + csplineSeg.n[i];
		accArray[i] = (6*csplineSeg.n3[i]*x) + (2*csplineSeg.n2[i]);
	}

	returnArray["pos"] = ( posArray[0], posArray[1], posArray[2] );
	returnArray["vel"] = ( velArray[0], velArray[1], velArray[2] );
	returnArray["acc"] = ( accArray[0], accArray[1], accArray[2] );
	if (IsDefined( segLength ) ) 
	{
		returnArray["vel"] /= segLength;
		returnArray["acc"] /= segLength * segLength;
	}
	if (IsDefined( speedMult ) ) 
	{
		returnArray["vel"] *= speedMult;
		returnArray["acc"] *= speedMult * speedMult;
	}
	returnArray[ "speed" ] = speedMult;
	return returnArray;
}

// csplineSeg_calcTopSpeed
// Find the top speed of a cubic spline segment.  There are two ways I could find to do this.  One using derivatives, which
// still requires some numerical iteration at the end because I can't do a cube root, and one that just iterates along the 
// curve.  In my test map, the derivatives version took 3.6-7ms to calculate 75 segements, while the iterating version took 
// 110ms at a 5 inch step length, 31ms at 5 samples per segment.
csplineSeg_calcTopSpeed( csplineSeg, segLength )
{
//	prof_begin("cspline_ts_derive");
	v1 =  csplineSeg_calcTopSpeedByDeriving( csplineSeg, segLength );
//	prof_end("cspline_ts_derive");
//	prof_begin("cspline_ts_iterate");
//	v2 =  csplineSeg_calcTopSpeedByStepping( csplineSeg, 5, segLength );// For 5 inch steps, I used Int(segLength/5)+1
//	prof_end("cspline_ts_iterate");
	//IPrintLn ( "segLength: "+segLength+", v1: "+v1+", v2: "+v2 );
	return v1;
}

csplineSeg_calcTopSpeedByDeriving( csplineSeg, segLength )
{
	// Total speed (squared) = speed[0]^2 + speed[1]^2 + speed[2]^2
	// speed[0] = 3*n3[0]*x^2 + 2*n2[0]*x + n[0]
	// Speed[0]^2 = 9*n3[0]^2*x^4 + 12*n3[0]*n2[0]*x^3 + ( 6*n3[0]*n + 4*n2[0]^2 )*x^2 + 4*n2[0]*n[0]*x + n[0]^2
	// I can sum these by summing the parameters, eg n3_n2 = (n3[0]*n2[0]) + (n3[1]*n2[1]) + (n3[2]*n2[2])
	n3_n3 = 0; n3_n2 = 0; n3_n = 0; n2_n2 = 0; n2_n = 0; n_n = 0;
	for (axis=0; axis<3; axis++)
	{
		n3_n3  += csplineSeg.n3[axis] * csplineSeg.n3[axis];
		n3_n2 += csplineSeg.n3[axis] * csplineSeg.n2[axis];
		n3_n  += csplineSeg.n3[axis] * csplineSeg.n[axis];
		n2_n2  += csplineSeg.n2[axis] * csplineSeg.n2[axis];
		n2_n  += csplineSeg.n2[axis] * csplineSeg.n[axis];
		n_n   += csplineSeg.n[axis]  * csplineSeg.n[axis];
	}
	// So the total speed (squared) is represented by a quartic function, with coefficients:
	/*
	a = 9*n3_n3;
	b = 12*n3_n2;
	c = 6*n3_n + 4*n2_n2;
	d = 4*n2_n;
	e = n_n;
	*/
	// I have a quartic equation to find the maximum of. Derivative is cubic:
	// 36*n3_n3*x^3 + 36*n3_n2*x^2 + ( 12*n3_n + 8*n2_n2 )*x + 4*n2_n
	// So 
	a = 36*n3_n3;
	b = 36*n3_n2; 
	c = 12*n3_n + 8*n2_n2;
	d = 4*n2_n;
	
	// So I need to find the roots of the cubic, and I only care about the ones where the slope of the cubic is negative.  
	// I can't do it mathematically without a cube root function, so do it numerically.
	// I need to find out exactly how many there are so I can be sure I don't miss any.
	// Also, by restricting myself to the 0-1 interval, I can pretty easily find a bunch of early outs.
	values = [];
	values[0] = 0;
	if ( a == 0 )
	{
		if ( ( b == 0 ) && ( c == 0 ) && ( d == 0 ) ) {
			// The original quartic was a flat line with constant value n_n.  That is, the spline is a straight line with no variation.
			return sqrt( n_n ) / segLength;
		}
		// a==0, so it's really a quadratic so it's easy to get its roots.
		cubicRoots = maps\interactive_models\_interactive_utility::rootsOfQuadratic( b, c, d );
		if ( IsDefined( cubicRoots[0] ) && cubicRoots[0] > 0 && cubicRoots[0] < 1 )
		{
			slope = (2*b*cubicRoots[0]) + c;
			if ( slope < 0 )
				values[values.size] = cubicRoots[0];
		}
		if ( IsDefined( cubicRoots[1] ) && cubicRoots[1] > 0 && cubicRoots[1] < 1 )
		{
			slope = (2*b*cubicRoots[0]) + c;
			if ( slope < 0 )
				values[values.size] = cubicRoots[1];
		}
	}
	else
	{
		// Divide the interval up into sub-intervals based on roots of the cubic's derivative.
		// Within each sub-interval, we know the cubic is constantly increasing or constantly decreasing, so there can only be one 
		// root at most.  Then within those intervals that are decreasing we can quickly check whether or not there is a root, and only 
		// then do we have to actually find it.
		quadRoots = maps\interactive_models\_interactive_utility::rootsOfQuadratic( 3*a, 2*b, c );
		i = 0;
		points[0] = 0;
		for ( i=0; i< quadRoots.size; i++ )
		{
			if ( quadRoots[i] > 0 && quadRoots[i] < 1 )
			{
				points[points.size] = quadRoots[i];
			}
		}
		points[points.size] = 1;
		for ( i=1; i<points.size; i++ )
		{
			x0 = points[i-1];
			x1 = points[i];
			startVal = ( a*x0*x0*x0 ) + ( b*x0*x0 ) + ( c*x0 ) + d;
			endVal   = ( a*x1*x1*x1 ) + ( b*x1*x1 ) + ( c*x1 ) + d;
			if ( (startVal > 0 ) && (endVal < 0) )
			{
				// There's a cubic root in the interval that corresponds to a maximum of the quartic.
				values[values.size] = maps\interactive_models\_interactive_utility::newtonsMethod( x0, x1, a, b, c, d, 0.02 );
			}
		}
	}
	values[values.size] = 1;
	
	// Now check through the contenders we have and see which has the highest speed.
	// Switch our variables over to the quartic that represents the square of the speed
	a = 9*n3_n3;
	b = 12*n3_n2;
	c = 6*n3_n + 4*n2_n2;
	d = 4*n2_n;
	e = n_n;
	
	maxSpeedSq = 0;
	foreach ( x in values )
	{
		speedSq = ( a*x*x*x*x ) + ( b*x*x*X ) + ( c*x*x ) + ( d*x ) + e;
		if ( speedSq > maxSpeedSq ) 
			maxSpeedSq = speedSq;
		/*/#
		// Check my math.
		actualPoint = csplineSeg_getPoint( csplineSeg, x );
		actualSpeedSq = LengthSquared( actualPoint["vel"] );
		actualSpeedSq *= 1;	// Just so I can get a breakpoint here.
		#/*/
	}
	
	return ( sqrt( maxSpeedSq ) / segLength );
}

csplineSeg_calcLengthByStepping( csplineSeg, numSteps )
{
	oldPos = csplineSeg_getPoint( csplineSeg, 0 );
	distance = 0;
	for ( i=1; i <= numSteps; i++ )
	{
		n = i / numSteps;
		newPos = csplineSeg_getPoint( csplineSeg, n );
		distance += Length( oldPos["pos"] - newPos["pos"] );
		oldPos = newPos;
	}	
	return distance;
}

csplineSeg_calcTopSpeedByStepping( csplineSeg, numSteps, segLength )
{
	oldPos = csplineSeg_getPoint( csplineSeg, 0 );
	topSpeed = 0;
	for ( i=1; i <= numSteps; i++ )
	{
		n = i / numSteps;
		newPos = csplineSeg_getPoint( csplineSeg, n );
		distance = Length( oldPos["pos"] - newPos["pos"] );
		if ( distance > topSpeed ) topSpeed = distance;
		oldPos = newPos;
	}	
	topSpeed *= numSteps / segLength ;
	return topSpeed;
}


/* Take a targetname for the first node in a path and return an array with positions for all nodes */
/*
=============
///ScriptDocBegin
"Name: cspline_findPathnodes( <targetname> )"
"Summary: Take a targetname for the first node in a path and return an array of nodes."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <targetname>: The targetname of the first node in the path.  Currently requires a path of vehicle nodes."
"Example: csPath = cspline_findPathnodes( targetname );"
"SPMP: both"
///ScriptDocEnd
=============
*/

cspline_findPathnodes( first_node )	// Adapted from waterball_get_pathnodes in flood_flooding.gsc
{
	next_node = first_node;
	array = [];
	
	for( node_num = 0; IsDefined( next_node.target ); node_num++ )
	{
		array[node_num] = next_node;
		targetname = next_node.target;
		next_node = GetNode( targetname, "targetname" );
		if ( !IsDefined( next_node ) )
		{
			next_node = GetVehicleNode( targetname, "targetname" );
			if ( !IsDefined( next_node ) )
			{
				next_node = GetEnt( targetname, "targetname" );
				if ( !IsDefined( next_node ) )
				{
					next_node = getstruct( targetname, "targetname" );
			}
		}
		}

		AssertEx( IsDefined(next_node), "cspline_findPathnodes: Couldn't find targetted node with targetname "+targetname+"." );
	}
	array[node_num] = next_node;
	return( array );
}

/*
=============
///ScriptDocBegin
"Name: cspline_makePath1Seg( <startOrg>, <endOrg>, <startVel>, <endVel> )"
"Summary: Take two points and returns a data structure with a single-piece hermite spline path defined in it. 
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <startOrg>: Point to start from."
"MandatoryArg: <endOrg>: Point to end at."
"OptionalArg: <startVel>: Velocity vector for the beginning of the spline; indicates movement in one frame.  Will use natural (ie zero acceleration) if not supplied."
"OptionalArg: <endVel>: Velocity vector for the end of the spline; indicates movement in one frame.  Will use natural (ie zero acceleration) if not supplied."
"Example: csPath = cspline_makePath1Seg( self.origin, targetPoint, currentVelocity );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_makePath1Seg(startOrg, endOrg, startVel, endVel)
{
	nodes = [];
	nodes[0] = SpawnStruct();
	nodes[0].origin = startOrg;
	if ( IsDefined(startVel) ) {
		nodes[0].speed = Length( startVel );
		startVel /= nodes[0].speed;
		nodes[0].speed *= 20;	// Speeds of real nodes are inches per second; velocity is per frame.
	} else {
		nodes[0].speed = 20;
	}
	nodes[1] = SpawnStruct();
	nodes[1].origin = endOrg;
	if ( IsDefined(endVel) ) {
		nodes[1].speed = Length( endVel );
		endVel /= nodes[1].speed;
		nodes[1].speed *= 20;
	} else {
		nodes[1].speed = 20;
	}
	return cspline_makePath( nodes, true, startVel, endVel );
}

/*
=============
///ScriptDocBegin
"Name: cspline_makePathToPoint( <startOrg>, <endOrg>, <startVel>, <endVel> )"
"Summary: Take two end points and returns a data structure with a fairly smooth hermite spline path defined in it. 
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <startOrg>: Point to start from."
"MandatoryArg: <endOrg>: Point to end at."
"OptionalArg: <startVel>: Velocity vector for the beginning of the spline; indicates movement in one frame.  Will use natural (ie zero acceleration) if not supplied."
"OptionalArg: <endVel>: Velocity vector for the end of the spline; indicates movement in one frame.  Will use natural (ie zero acceleration) if not supplied."
"OptionalArg: <forceCreateIntermediateNodes>: forces the creation of two intermediate nodes, making a 3-segment path.  These nodes are normally created only if the velocities do not line up with the direction of the path."
"Example: csPath = cspline_makePathToPoint( self.origin, targetOrigin, currentVelocity );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_makePathToPoint(startOrg, endOrg, startVel, endVel, forceCreateIntermediateNodes)
{
	dirs = [];
	if ( !IsDefined( forceCreateIntermediateNodes ) ) forceCreateIntermediateNodes = false;
	if ( IsDefined(startVel) ) {
		startSpeed = Length( startVel );
		dirs[0] = startVel / startSpeed;
		startSpeed *= 20;	// Speeds of real nodes are inches per second; velocity is per frame.
	} else {
		startSpeed = 20;
	}
	if ( IsDefined(endVel) ) {
		endSpeed = Length( endVel );
		dirs[1] = endVel / endSpeed;
		endSpeed *= 20;	// Speeds of real nodes are inches per second; velocity is per frame.
	} else {
		endSpeed = 20;
	}
	if ( ( startSpeed / endSpeed > 1.2 ) || ( endSpeed / startSpeed > 1.2 ) || ( forceCreateIntermediateNodes ) ) {
		if ( !IsDefined( dirs[0] ) )
			dirs[0] = (0,0,0);
		if ( !IsDefined( dirs[1] ) ) {
			dirs[1] = (0,0,0);
		}
	}
	pathVec = endOrg - startOrg;
	pathLength = Length( pathVec );
	pathDir = pathVec / pathLength;
	
	nodes = [];
	nodes[0] = SpawnStruct();
	nodes[0].origin = startOrg;
	nodes[0].speed = startSpeed;
	
	// Find an offset based on the start/end velocity, and make sure it's a good distance from the straight line path
	offsetLengths = [];
	midSpeed = max( startSpeed, endSpeed );
	if ( IsDefined( dirs[0] ) )
	{
		offsetLengths[0] = ( startSpeed + midSpeed ) / ( 2 * 20 );
	}
	if ( IsDefined( dirs[1] ) )
	{
		offsetLengths[1] = ( endSpeed + midSpeed ) / ( 2 * 20 );
	}
	for (i=0; i<2; i++)
	{
		if ( IsDefined( dirs[i]) )
		{
			sign = ( 0.5 - i ) * 2;	// 1 or -1
			offsetVec = dirs[i];
			offsetVec *= sign;
			offsetDotPath = VectorDot( offsetVec, pathDir );
			// Only create a new node if the direction doesn't line up with the straight line path, or if there is a significant speed difference.
			if ( ( offsetDotPath * sign < 0.3 )	|| ( startSpeed / endSpeed > 1.2 )	|| ( endSpeed / startSpeed > 1.2 ) || forceCreateIntermediateNodes )
			{
				// If the velocity goes against the direction of the path, make sure the new point is out wide
				if ( offsetDotPath * sign < 0 )
				{
					offsetAlongPath = offsetDotPath * pathDir;
					offsetVec -= offsetAlongPath;
					AssertEx( VectorDot( offsetVec, pathDir ) == 0, "Dot result should be 0: "+VectorDot( offsetVec, pathDir ) );
					offsetVec = VectorNormalize( offsetVec );
					offsetVec += offsetAlongPath;
				}
				// Now move the new point along the path a bit
				offsetVec += pathDir * sign;
				offsetVec = offsetVec * offsetLengths[i];
				offsetVec *= sqrt(pathLength) * 2;
				nodes[nodes.size  ]		   = SpawnStruct();
				if ( i==0 ) {
					nodes[nodes.size-1].origin = startOrg + offsetVec;
				}
				else {
					nodes[nodes.size-1].origin = endOrg + offsetVec;
				}
				nodes[nodes.size-1].speed  = midSpeed ;				
			}
		}
	}
	n = nodes.size;
	nodes[n] = SpawnStruct();
	nodes[n].origin = endOrg;
	nodes[n].speed = endSpeed;
	/#
	if ( GetDvarInt( "interactives_debug" ) )
	{
		thread draw_line_for_time ( startOrg, endOrg, 0, .7, .7, 1 );
		for ( n=1; n<nodes.size; n++ )
			thread draw_line_for_time ( nodes[n-1].origin, nodes[n].origin, 0, .7, .7, 1 );
	}
	#/

	return cspline_makePath( nodes, true, dirs[0], dirs[1] );
}
	
/*
=============
///ScriptDocBegin
"Name: cspline_makePath( <path_nodes>, <startVel>, <endVel> )"
"Summary: Take an array of nodes in a path and return a data structure with the hermite spline path defined in it."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <path_nodes>: An array of nodes (or any structs with .origin fields)."
"OptionalArg: <useNodeSpeeds>: Use the speed keypairs from the nodes."
"OptionalArg: <startVel>: Velocity (or tangent) vector for the beginning of the spline.  Will use natural (ie zero acceleration) if not supplied."
"OptionalArg: <endVel>: Velocity (or tangent) vector for the end of the spline.  Will use natural (ie zero acceleration) if not supplied."
"OptionalArg: <capSpeed>: Can be set to false to avoid the expensive speed capping calculation.  If false, speed between nodes will exceed the speed set at the nodes."
"Example: csPath = cspline_makePath( targetname );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_makePath(nodes, useNodeSpeeds, startVel, endVel, capSpeed)
{
	//prof_begin("cspline_makePath");
	csPath = SpawnStruct();
	csPath.Segments	= [];
	if (!IsDefined( useNodeSpeeds ) ) useNodeSpeeds = false;
	AssertEx( !useNodeSpeeds || IsDefined( nodes[0].speed ), "cspline_makePath: Speed keypair required for first node in path (node at "+nodes[0].origin+")" );
	if (!IsDefined( capSpeed ) ) capSpeed = true;
	
	AssertEx( IsDefined( nodes[0] ), "cspline_makePath: No nodes supplied" );
	AssertEx( IsDefined( nodes[1] ), "cspline_makePath: Only one node supplied" );
	path_length = 0;
	nextTangent = [];
	nextSegLength = Distance( nodes[0].origin, nodes[1].origin );
	
	while ( IsDefined( nodes[csPath.Segments.size+2] ) )
	{
		i = csPath.Segments.size;
		prevPoint = nodes[i].origin;
		nextPoint = nodes[i+1].origin;
		nextNextPoint = nodes[i+2].origin;
		thisSegLength = nextSegLength;
		nextSegLength = Distance( nodes[i+1].origin, nodes[i+2].origin );
		prevTangent = nextTangent;
		nextTangent = cspline_calcTangent( prevPoint, nextNextPoint, thisSegLength, nextSegLength, 0.5 );
		AssertEx( abs( Length( nextTangent["incoming"] ) ) <= thisSegLength, "cspline_makePath: Tangent slope is > 1.  This shouldn't be possible." );
		AssertEx( abs( Length( nextTangent["outgoing"] ) ) <= nextSegLength, "cspline_makePath: Tangent slope is > 1.  This shouldn't be possible." );
		if (i==0)
		{
			if ( IsDefined( startVel ) ) {
				prevTangent["outgoing"] = startVel * thisSegLength;
			}
			else {
				prevTangent = cspline_calcTangentNatural( prevPoint, nextPoint, nextTangent["incoming"] );
			}
		}
		if ( capSpeed )
		{
			csPath.Segments[i] = csplineSeg_calcCoeffsCapSpeed( prevPoint, nextPoint, prevTangent["outgoing"], nextTangent["incoming"], thisSegLength );
			path_length += csPath.Segments[i].endAt;
		}
		else
		{
			csPath.Segments[i] = csplineSeg_calcCoeffs( prevPoint, nextPoint, prevTangent["outgoing"], nextTangent["incoming"] );
			path_length += thisSegLength;
		}
		csPath.Segments[i].endAt = path_length;
	}
	i = csPath.Segments.size;
	prevPoint = nodes[i].origin;
	nextPoint = nodes[i+1].origin;
	thisSegLength = nextSegLength;
	prevTangent = nextTangent;
	if ( i==0 && IsDefined( startVel ) ) {
		prevTangent["outgoing"] = startVel * thisSegLength;
	}
	if ( IsDefined( endVel ) ) {
		nextTangent["incoming"] = endVel * thisSegLength;
	}
	else {
		nextTangent = cspline_calcTangentNatural(prevPoint, nextPoint, prevTangent["outgoing"]);
	}
	if ( i==0 && !IsDefined( startVel ) ) {
		prevTangent = cspline_calcTangentNatural( prevPoint, nextPoint, nextTangent["incoming"] );
	}
	if ( capSpeed )
	{
		csPath.Segments[i] = csplineSeg_calcCoeffsCapSpeed( prevPoint, nextPoint, prevTangent["outgoing"], nextTangent["incoming"], thisSegLength );
		path_length += csPath.Segments[i].endAt;
	}
	else
	{
		csPath.Segments[i] = csplineSeg_calcCoeffs( prevPoint, nextPoint, prevTangent["outgoing"], nextTangent["incoming"] );
		path_length += thisSegLength;
	}
	csPath.Segments[i].endAt = path_length;
	
	// We keep the speed separate from the tangents because otherwise a low speed causes pinching in 
	// the path (which can be achieved with the "tension" parameter in a TCB tangent if you really want it).
	if ( useNodeSpeeds ) {
		pathTime = 0;
		prevEndAt = 0;
		for ( i	= 0; i < csPath.Segments.size; i++ )
		{
			if ( !IsDefined( nodes[i+1].speed ) )
			    nodes[i+1].speed = nodes[i].speed;
			thisSegLength = csPath.Segments[i].endAt - prevEndAt;
			segTime = 2 * thisSegLength / ( ( nodes[i].speed + nodes[i+1].speed ) / 20 ); // /20 to convert from per second to per frame.
			pathTime += segTime;
			csPath.Segments[i].endTime = pathTime;
			prevEndAt = csPath.Segments[i].endAt;
			csPath.Segments[i].speedStart = nodes[i  ].speed / 20;
			csPath.Segments[i].speedEnd   = nodes[i+1].speed / 20;
		}
	}
	else {
		for ( i	= 0; i < csPath.Segments.size; i++ )
		{
			csPath.Segments[i].endTime = csPath.Segments[i].endAt;
			csPath.Segments[i].speedStart = 1;
			csPath.Segments[i].speedEnd   = 1;
		}
	}
		
	//prof_end("cspline_makePath");
	return csPath;
}

/*
=============
///ScriptDocBegin
"Name: cspline_moveFirstPoint( <csPath> , <newStartPos>, <newStartVel> )"
"Summary: Moves the start point of the first segment of a path."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <csPath>: A cubic Hermite spline path as returned from cspline_makePath()"
"MandatoryArg: <newStartPos>: New position for the beginning of the path"
"MandatoryArg: <newStartVel>: New velocity (or tangent) for the beginning of the path.  Currently mandatory because I haven't had a need to make it optional."
"Example: 	newPath = cspline_moveFirstPoint( nextPath, currentPos, currentVel );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_moveFirstPoint(csPath, newStartPos, newStartVel)
{

	newPath = SpawnStruct();
	newPath.Segments	= [];
	posVel = csplineSeg_getPoint( csPath.Segments[0], 1 );
	segLength3D = posVel["pos"] - newStartPos;
	segLength = Length(segLength3D);
	newPath.Segments[0] = csplineSeg_calcCoeffs( newStartPos, posVel["pos"], newStartVel * segLength, posVel["vel"] );
	newPath.Segments[0].endTime = csPath.Segments[0].endTime * segLength / csPath.Segments[0].endAt;
	newPath.Segments[0].endAt = segLength;
	lengthDiff = segLength - csPath.Segments[0].endAt;
	timeDiff = newPath.Segments[0].endTime - csPath.Segments[0].endTime;
	
	for ( seg=1; seg<csPath.Segments.size; seg++ )
	{
		newPath.Segments[seg] = csplineSeg_copy( csPath.Segments[seg] );
		newPath.Segments[seg].endAt += lengthDiff;
		newPath.Segments[seg].endTime += timeDiff;
	}
	return newPath;
}

/*
=============
///ScriptDocBegin
"Name: cspline_getPointAtDistance( <csPath> , <distance> )"
"Summary: Take a cubic Hermite spline path and a distance along that path, and returns a position vector and velocity vector."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <csPath>: A cubic Hermite spline path as returned from cspline_makePath()"
"MandatoryArg: <distance>: Distance along the path, in inches.  The length of the path csPath can be found by cspline_length()"
"Example: testModel.origin = cspline_getPointAtDistance( csPath, distance );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_getPointAtDistance(csPath, distance, speedIsImportant)
{
	if (distance <= 0)
	{
		segLength = csPath.Segments[0].endAt;
		posVel = csplineSeg_getPoint( csPath.Segments[0], 0, segLength, csPath.Segments[0].speedStart );
		return posVel;
	}
	else if (distance >= csPath.Segments[csPath.Segments.size-1].endAt)
    {
		if ( csPath.Segments.size > 1 )
			segLength = csPath.Segments[csPath.Segments.size-1].endAt - csPath.Segments[csPath.Segments.size-2].endAt;
		else
			segLength = csPath.Segments[csPath.Segments.size-1].endAt;
		posVel = csplineSeg_getPoint( csPath.Segments[csPath.Segments.size-1], 1, segLength, csPath.Segments[csPath.Segments.size-1].speedEnd );
		return posVel;
    }
    else
	{
		// Find the segment we want (brute force way).		
		segNum=0;
		while (csPath.Segments[segNum].endAt < distance)
		{
			segNum++;
		}
		if (segNum>0) {
			startAt = csPath.Segments[segNum-1].endAt;
		} else {
			startAt = 0;
		}
		segLength = csPath.Segments[segNum].endAt - startAt;
		normalized = ( distance - startAt ) / segLength;
		speed = undefined;
		if ( IsDefined( speedIsImportant ) && speedIsImportant )
			speed = cspline_speedFromDistance( csPath.Segments[segNum].speedStart, csPath.Segments[segNum].speedEnd, normalized );
		posVel = csplineSeg_getPoint( csPath.Segments[segNum], normalized, segLength, speed );
		return posVel;
	}	
}

/*
=============
///ScriptDocBegin
"Name: cspline_getPointAtTime( <csPath> , <time> )"
"Summary: Take a cubic Hermite spline path and a time along that path, and returns a position vector and velocity vector.  Useful if you set the path up with varying speed at each node."
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <csPath>: A cubic Hermite spline path as returned from cspline_makePath()"
"MandatoryArg: <time>: Time spent traveling along the path, in whatever units you set the path up with (usually frames).  The total time for the path can be found by cspline_time()"
"Example: posVel = cspline_getPointAtTime( self.path, piece.distance );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/
cspline_getPointAtTime( csPath, time )
{
	if (time <= 0)
	{
		segLength = csPath.Segments[0].endAt;
		posVel = csplineSeg_getPoint( csPath.Segments[0], 0, segLength, csPath.Segments[0].speedStart );
		return posVel;
	}
	else if (time >= csPath.Segments[csPath.Segments.size-1].endTime)
    {
		if ( csPath.Segments.size > 1 )
			segLength = csPath.Segments[csPath.Segments.size-1].endAt - csPath.Segments[csPath.Segments.size-2].endAt;
		else
			segLength = csPath.Segments[csPath.Segments.size-1].endAt;
		posVel = csplineSeg_getPoint( csPath.Segments[csPath.Segments.size-1], 1, segLength, csPath.Segments[csPath.Segments.size-1].speedEnd );
		return posVel;
    }
    else
	{
		// Find the segment we want (brute force way).	
		segNum=0;
		while (csPath.Segments[segNum].endTime < time)
		{
			segNum++;
		}
		if (segNum>0) {
			startTime = csPath.Segments[segNum-1].endTime;
			segLength = csPath.Segments[segNum].endAt - csPath.Segments[segNum-1].endAt;
		} else {
			startTime = 0;
			segLength = csPath.Segments[0].endAt;
		}
		// Convert the time to a distance and get the point.
		segTime = csPath.Segments[segNum].endTime - startTime;
		normTime = ( time - startTime ) / segTime;
		speed = csPath.Segments[segNum].speedStart + ( normTime * ( csPath.Segments[segNum].speedEnd - csPath.Segments[segNum].speedStart ) );
		dist = ( time - startTime ) * ( csPath.Segments[segNum].speedStart + speed ) / 2;
		normDist = dist / segLength;
		posVel = csplineSeg_getPoint( csPath.Segments[segNum], normDist, segLength, speed );
		return posVel;
	}	
}

cspline_speedFromDistance( speedStart, speedEnd, normalizedDistance )
{
	// Let's say sS = speedStart, sD = speedEnd, t = normalized time, s = current speed
	// We're pretending that the distance from start to end is 1.  
	// Thus total time = 1 / total average speed = 2/(sS+sD)
	// acceleration a = speed change / total time = (sD-sS) * (sS+sD) / 2
	// Speed s = sS + a*t
	// t = (s-sS)/a
	// d = t * average speed
	// d = ( (s-sS)/a ) * ( (sS+s)/2 )
	// s = sqrt( 2*a*d + sS^2 )
	d = normalizedDistance;
	a = ( speedEnd - speedStart ) * ( speedEnd + speedStart ) / 2;
	return sqrt( ( 2*a*d ) + ( speedStart*speedStart ) );
}

cspline_adjustTime( csPath, newTime )
{
	// Leave the first and last node alone, and scale the speeds of all the other nodes to make the path take a different amount of time.
	
	// time = distance / av speed
	// R = speed multiply ratio
	// d0, d1 and d2 are distances for first, sum of middle and last segments, respectively.
	// av speed for middle sections multiplies by R, ie time for middle sections divides by R
	// av speed for ends multiplies by (1+R)/2
	// tnew = ( (t0+t2)*2/(1+R) ) + t1/R
	// R = ( sqrt( ( (2*t0) + t1 + (2*t2) - tnew )^2 + (4*t1*tnew) ) + (2*d0) + d1 + (2*d2) - tnew ) / (2*tnew)
	
	oldTime = cspline_time( csPath );
	t0 = csPath.Segments[0].endTime;
	t1 = csPath.Segments[ csPath.Segments.size-2 ].endTime - t0;
	t2 = csPath.Segments[ csPath.Segments.size-1 ].endTime - csPath.Segments[ csPath.Segments.size-2 ].endTime;
	tempsum = (2*t0) + t1 + (2*t2) - newtime;
	R = ( sqrt( (tempsum*tempsum) + (4*t1*newTime) ) + tempsum ) / (2*newTime);
	/#
		checkNewTime = ( (t0+t2)*2/(1+R) ) + (t1/R);
		AssertEx( abs(checkNewTime - newTime) < 0.001, "cspline_adjustTime math failure: "+checkNewTime+" != "+newTime );
	#/
	
	nextTime = undefined;		// For debugging only.
	checkEndTime = undefined;	// For debugging only.
	csPath.Segments[0].speedEnd *= R;
	offset = csPath.Segments[0].endtime * ( (1/R) - (2/(1+R)) );
	/#
		checkEndTime = ( csPath.Segments[0].endtime / R ) - offset;
		nextTime = csPath.Segments[1].endtime - csPath.Segments[0].endtime;
	#/
	csPath.Segments[0].endtime /= (1+R)/2;
	AssertEx( abs( checkEndTime - csPath.Segments[0].endtime ) < 0.001, "cspline_adjustTime math failure (offset). "+checkEndTime+" != "+csPath.Segments[0].endtime );
	for ( i=1; i<csPath.Segments.size-1; i++ )
	{
		thisOldTime = undefined;	// For debugging only.
		/# 
		thisOldTime = nextTime;
		nextTime = csPath.Segments[i+1].endtime - csPath.Segments[i].endtime;
		#/
		csPath.Segments[i].speedStart *= R;
		csPath.Segments[i].speedEnd *= R;
		csPath.Segments[i].endtime /= R;
		csPath.Segments[i].endtime -= offset;
		/# 
		thisTime = csPath.Segments[i].endtime - csPath.Segments[i-1].endtime;
		AssertEx( abs(thisTime - (thisOldTime/R) ) < 0.001, "cspline_adjustTime math failure. "+thisTime+" != "+(thisOldTime/R) );
		#/
	}
	i = csPath.Segments.size-1;
	csPath.Segments[i].speedStart *= R;
	csPath.Segments[i].endtime = newTime;
	/#
	t0New = csPath.Segments[0].endtime;
	t1new = csPath.Segments[csPath.Segments.size-2].endtime - csPath.Segments[0].endtime;
	t2New = csPath.Segments[i].endtime - csPath.Segments[i-1].endtime;
	AssertEx( abs( t0New - (t0*2/(1+R)) ) < 0.001, "cspline_adjustTime math failure t0. "+t0New+" != "+(t0*2/(1+R)) );
	AssertEx( abs( t1new - (t1/R) ) < 0.001,       "cspline_adjustTime math failure t1. "+t1new+" != "+(t1/R) );
	AssertEx( abs( t2New - (t2*2/(1+R)) ) < 0.001, "cspline_adjustTime math failure t2. "+t2New+" != "+(t2*2/(1+R)) );
	#/
}



/*
=============
///ScriptDocBegin
"Name: cspline_makeNoisePath( <size> , <minVal> , <maxVal> )"
"Summary: Creates a looping cubic spline path of random 3D points."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <size>: Number of entries in the returned array"
"MandatoryArg: <minVal>: Minimum allowed for the random values.  Must be a vector."
"MandatoryArg: <maxVal>: Maximum allowed for the random values.  Must be a vector."
"OptionalArg: <firstVal>: Value for the first and last point in the path."
"Example: 	nodes = cspline_makeNoisePathNodes( 10, -5, 5 );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_makeNoisePath( size, minVal, maxVal, firstVal )
{
	nodes = cspline_makeNoisePathNodes( size, minVal, maxVal );
	if ( IsDefined(firstVal) ) {
		nodes[1].origin = firstVal;	// Nodes[1] will eventually be the start and end point of the path.
	}
	// Duplicate the first three onto the end so the eventual path loops with no discontinuities
	newNode = SpawnStruct();
	newNode.origin = nodes[0].origin;
	nodes[ nodes.size ] = newNode;
	newNode = SpawnStruct();
	newNode.origin = nodes[1].origin;
	nodes[ nodes.size ] = newNode;
	newNode = SpawnStruct();
	newNode.origin = nodes[2].origin;
	nodes[ nodes.size ] = newNode;
	
	
	cspath = cspline_makePath( nodes );
	
	// Now strip the first and last off
	newPath = SpawnStruct();
	newPath.Segments	= [];
	for ( seg = 0; seg < csPath.Segments.size - 2; seg++ )
	{
		newPath.Segments[ seg ]		  = csplineSeg_copy( csPath.Segments[ seg + 1 ] );
		newPath.Segments[ seg ].endAt = seg + 1;
	}	
	return newPath;
}

cspline_makeNoisePathNodes( size, minVal, maxVal )
{
	AssertEx( minVal[0]<maxVal[0] && minVal[1]<maxVal[1] && minVal[2]<maxVal[2], "minVal must be < maxVal: "+minVal+", "+maxVal );
	nodes = [];
	for ( i = 0; i < size; i++ )
	{
		nodes[ i ]  = SpawnStruct();
		
		x = RandomFloatRange( minVal[ 0 ], maxVal[ 0 ] );
		y = RandomFloatRange( minVal[ 1 ], maxVal[ 1 ] );
		z = RandomFloatRange( minVal[ 2 ], maxVal[ 2 ] );
		
		nodes[ i ].origin = ( x, y, z );
	}
	return nodes;
}

/*
=============
///ScriptDocBegin
"Name: cspline_test( <csPath> , <timeSecs> )"
"Summary: Displays a cubic spline path in 3D, if the dvar interactives_debug is set."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <csPath>: A cubic spline path, as returned from cspline_makePath"
"OptionalArg: <timeSecs>: Time in seconds to display the path for.  Defaults to infinity."
"Example: 	thread cspline_test( "bird_path" );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_test( csPath, timeSecs )
{
	/#
	sec = 0;
	arrowLength = 10;
	arrowSpacing = 50;
	maxArrows = 50;

	for (;;)
	{
		if ( GetDvarInt( "interactives_debug" ) )
		{
			pathLength = cspline_time( csPath );
			minArrowSpacing = pathLength / maxArrows;
			col = ( minArrowSpacing/arrowSpacing, arrowSpacing/minArrowSpacing, 0 );	// Fade to red if arrows are widely spaced
			if ( minArrowSpacing > arrowSpacing ) arrowSpacing = minArrowSpacing;
			posVel = cspline_getPointAtTime( csPath, 0 );
			for(time = 0; time <= cspline_time( csPath ); time += arrowSpacing)
			{
				prevPos = posVel["pos"];
				if ( isDefined( csPath.Segments[0].speedEnd ) )
					posVel = cspline_getPointAtTime( csPath, time );
				else
					posVel = cspline_getPointAtDistance( csPath, time );
				thread draw_arrow_time( prevPos, posVel["pos"], (0,1,0), 1 );
			}
			hsArray = cspline_getNodes( csPath );
			size=12;
			foreach ( i in [0, hsArray.size-1] )
			{
				thread draw_line_for_time ( hsArray[ i ][ "pos" ] -( size, 0, 0 ), hsArray[ i ][ "pos" ] +( size, 0, 0 ), 1	 , 0  , 0  , 1 );
				thread draw_line_for_time ( hsArray[ i ][ "pos" ] -( 0, size, 0 ), hsArray[ i ][ "pos" ] +( 0, size, 0 ), 1	 , 0  , 0  , 1 );
				thread draw_line_for_time ( hsArray[ i ][ "pos" ] -( 0, 0, size ), hsArray[ i ][ "pos" ] +( 0, 0, size ), 1	 , 0  , 0  , 1 );
				//Print3d( hsArray[ i ][ "pos" ] -( 0, 0, size )	   , ( "accn: " + ( 100 * hsArray[ i ][ "acc" ] ) )	 , ( 1, 0, 0 ), 1, 1, 20 );
				/*Print3d( hsArray[ i ][ "pos" ] -( 0, 0, size ), ( "time:  " + ( hsArray[ i ][ "time" ] ) ) , ( 1, 1, 0 ), 1, 1, 20 );
				speed = Length( hsArray[ i ][ "vel" ] );
				Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 2*size ), ( "speed: " + speed ) , ( 1, 1, 0 ), 1, 1, 20 );
				if ( i==0 && IsDefined( csPath.Segments[i].straightLineLength ) )
				{
					Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 3*size ), ( "straight length: " + csPath.Segments[i].straightLineLength ) , ( 1, 1, 0 ), 1, 1, 20 );
					Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 4*size ), ( "top speed: " + csPath.Segments[i].calcTopSpeed ) , ( 1, 1, 0 ), 1, 1, 20 );
					Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 5*size ), ( "actual length: " + csPath.Segments[i].actualLength ) , ( 1, 1, 0 ), 1, 1, 20 );
				}*/
			}
			for ( i = 1; i < hsArray.size - 1; i++ )
			{
				thread draw_line_for_time ( hsArray[ i ][ "pos" ] -( size, 0, 0 ), hsArray[ i ][ "pos" ] +( size, 0, 0 ), 1	 , 1  , 0  , 1 );
				thread draw_line_for_time ( hsArray[ i ][ "pos" ] -( 0, size, 0 ), hsArray[ i ][ "pos" ] +( 0, size, 0 ), 1	 , 1  , 0  , 1 );
				thread draw_line_for_time ( hsArray[ i ][ "pos" ] -( 0, 0, size ), hsArray[ i ][ "pos" ] +( 0, 0, size ), 1	 , 1  , 0  , 1 );
				//Print3d( hsArray[ i ][ "pos" ] -( 0, 0, size )	   , ( "accn  in: " + ( 100 * hsArray[ i ][ "acc"     ] ) ) , ( 1, 1, 0 ), 1, 1, 20 );
				//Print3d( hsArray[ i ][ "pos" ] -( 0, 0, size + 10 ), ( "accn out: " + ( 100 * hsArray[ i ][ "acc_out" ] ) ) , ( 1, 1, 0 ), 1, 1, 20 );
				/*Print3d( hsArray[ i ][ "pos" ] -( 0, 0, size ), ( "time: " + ( hsArray[ i ][ "time" ] ) ) , ( 1, 1, 0 ), 1, 1, 20 );
				speed = Length( hsArray[ i ][ "vel" ] );
				Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 2*size ), ( "speed: " + speed ) , ( 1, 1, 0 ), 1, 1, 20 );
				if ( IsDefined( csPath.Segments[i].straightLineLength ) )
				{
					Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 3*size ), ( "straight length: " + csPath.Segments[i].straightLineLength ) , ( 1, 1, 0 ), 1, 1, 20 );
					Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 4*size ), ( "top speed: " + csPath.Segments[i].calcTopSpeed ) , ( 1, 1, 0 ), 1, 1, 20 );
					Print3d( hsArray[ i ][ "pos" ] -( 0, 0, 5*size ), ( "actual length: " + csPath.Segments[i].actualLength ) , ( 1, 1, 0 ), 1, 1, 20 );
				}*/
			}
		}
		wait 1;
		sec++;
		if ( IsDefined( timeSecs) && ( sec >= timeSecs ) ) break;
	}
	#/
}

/*
=============
///ScriptDocBegin
"Name: cspline_testNodes( <nodes> , <timeSecs> )"
"Summary: Displays the nodes with lines between them."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <nodes>: An array of structs with .origin fields"
"MandatoryArg: <timeSecs>: Time in seconds to display the path for"
"Example: 	thread cspline_testNodes( nodes_array, 5 );"
"SPMP: both"
///ScriptDocEnd
=============
*/
cspline_testNodes( nodes, timeSecs )
{
	size = 20;
	prevNode = undefined;
	foreach ( node in nodes )
	{
		if ( IsDefined( prevNode ) )
			thread draw_arrow_time( prevNode.origin, node.origin, (0,1,0), timeSecs );
		prevNode = node;
	}
	foreach ( node in nodes )
	{
		thread draw_line_for_time ( node.origin -( size, 0, 0 ), node.origin +( size, 0, 0 ), 1	 , 1  , 0  , timeSecs );
		thread draw_line_for_time ( node.origin -( 0, size, 0 ), node.origin +( 0, size, 0 ), 1	 , 1  , 0  , timeSecs );
		thread draw_line_for_time ( node.origin -( 0, 0, size ), node.origin +( 0, 0, size ), 1	 , 1  , 0  , timeSecs );
	}
}

csplineSeg_copy (csSeg )
{
	newSeg = SpawnStruct();
	numDimensions = 3;
	for (d=0; d<numDimensions; d++)
	{
		newSeg.n3[d] = csSeg.n3[d];
		newSeg.n2[d] = csSeg.n2[d];
		newSeg.n[d]  = csSeg.n[d];
		newSeg.c[d]  = csSeg.c[d];
	}
	newSeg.endAt = csSeg.endAt;
	newSeg.endTime = csSeg.endTime;
	return newSeg;
}

// Simple, readable way of getting the length of a path
cspline_length( csPath )
{
	return csPath.Segments[ csPath.Segments.size - 1 ].endAt;
}
cspline_time( csPath )
{
	return csPath.Segments[ csPath.Segments.size - 1 ].endTime;
}



//-----------------------------------------------------------
//
// Cubic spline noise
//
//-----------------------------------------------------------

// cspline_InitNoise
// 
/*
=============
///ScriptDocBegin
"Name: cspline_InitNoise( <center> , <startPoint> , <variance_amt> , <variance_time> )"
"Summary: Creates a series of points with random positions around a center point. Returns a struct that can be passed to cspline_Noise to get a position."
"Module: CSplines"
"CallOn: nothing"
"MandatoryArg: <center>: Center point for the returned positions"
"MandatoryArg: <variance_amt>: Max distance positions can be from center."
"MandatoryArg: <variance_time>: "
"OptionalArg: <startPoint>: Position for first point."
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

cspline_InitNoise( center, variance_amt, variance_time, startPoint )
{
	ns			 = SpawnStruct();
	largeAmt	 = variance_amt;
	ns.largeStep = variance_time;
	//smallAmt	 = small_variance_amt;
	//ns.smallStep = small_variance_time;
	
	centerMin			   = ( center[ 0 ] - largeAmt, center[ 1 ] - largeAmt, center[ 2 ] - largeAmt );
	centerMax			   = ( center[ 0 ] + largeAmt, center[ 1 ] + largeAmt, center[ 2 ] + largeAmt );
	startPoint			   = ( center[ 0 ], center[ 1 ], center[ 2 ] - largeAmt );
	ns.largeScale		   = cspline_makeNoisePath( 10, centerMin, centerMax, startPoint );
	//ns.smallScale		   = cspline_makeNoisePath( 10, -1 * ( smallAmt, smallAmt, smallAmt ), ( smallAmt, smallAmt, smallAmt ) );
	ns.largeScale.Length   = ns.largeScale.Segments[ ns.largeScale.Segments.size - 1 ].endAt;
	//ns.smallScale.Length = ns.smallScale.Segments[ ns.smallScale.Segments.size - 1 ].endAt;
	
	thread cspline_test( ns.largeScale, 20 );
	return ns;
}

/*
=============
///ScriptDocBegin
"Name: cspline_Noise( <ns> , <frameNum> )"
"Summary: "
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <ns>: "
"MandatoryArg: <frameNum>: "
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

cspline_Noise( ns, frameNum )
{
	tl = mod( frameNum/ns.largeStep, ns.largeScale.length );
	//ts = mod( frameNum/ns.smallStep, ns.smallScale.length );
	
	pl = cspline_getPointAtDistance( ns.largeScale, tl );
	//ps = cspline_getPointAtDistance( ns.smallScale, ts );
	
	return pl["pos"];// + ps["pos"];
}