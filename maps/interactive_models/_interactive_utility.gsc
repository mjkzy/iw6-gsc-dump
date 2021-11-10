#include common_scripts\utility;

/*
=============
///ScriptDocBegin
"Name: delete_on_notify( <ent>, <notify1>, <notify2>, <notify3> )"
"Summary: Just like delete_on_death, but takes up to 3 strings.  Notifying any of the strings will result in ent being deleted."
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <ent>: The entity to be deleted"
"OptionalArg: <notify1>: Strings on the called-on-entity that you want to listen for."
"Example: 	self thread delete_on_notify( trigger, "death", "damage" );"
"SPMP: both"
///ScriptDocEnd
=============
*/
delete_on_notify( ent, notify1, notify2, notify3 )
{
	//self ==> the entity you want to wait for a notify on before deleting the ent
	ent endon( "death" );
	self waittill_any( notify1, notify2, notify3 );
	if ( IsDefined( ent ) )
		ent Delete();
}

// array_sortByArray - given an array, and another array of equal size containing a value to sort on, returns a copy of the first array, sorted.  
// Not optimized.  O(n^2), I think.
array_sortByArray( array, sorters )
{
	newArray = [];
	newArray[0] = array[0];
	newSorters = [];
	newSorters[0] = sorters[0];
	for ( i=1; i<array.size; i++ )
	{
		sorted = false;
		for ( j=0; j<newArray.size; j++ )
		{
			if ( sorters[i] < newSorters[j] )
			{
				for ( k=newArray.size-1; k>=j; k-- )
				{
					newArray[ k+1 ] = newArray[ k ];
					newSorters[ k+1 ] = newSorters[ k ];
				}
				newArray[ j ] = array[ i ];
				newSorters[ j ] = sorters[ i ];
				sorted = true;
				break;
			}
		}
		if ( !sorted )
		{
			newArray[ i ] = array[ i ];
			newSorters[ i ] = sorters[ i ];				
		}
	}
	return newArray;
}

// array_sortBySorter - given an array of structs, each of which contains a field named "sorter", returns a copy of the array, sorted.  
// Notes:
// Not optimized.  O(n^2), I think.
// Does not copy the structs.  Copies the array but references the original structs.
array_sortBySorter( array )
{
	newArray = [];
	newArray[0] = array[0];
	for ( i=1; i<array.size; i++ )
	{
		sorted = false;
		for ( j=0; j<newArray.size; j++ )
		{
			if ( array[i].sorter < newArray[j].sorter )
			{
				for ( k=newArray.size-1; k>=j; k-- )
				{
					newArray[ k+1 ] = newArray[ k ];
				}
				newArray[ j ] = array[ i ];
				sorted = true;
				break;
			}
		}
		if ( !sorted )
		{
			newArray[ i ] = array[ i ];
		}
	}
	return newArray;
}

/* 
 ============= 
///ScriptDocBegin
"Name: wait_then_fn( <notifyStr>, <fn>, <arg1>, <arg2>, <arg3> )"
"Summary: Waits for a notify or a time, then calls the specified function with specified args."
"Module: "
"CallOn: Entity"
"MandatoryArg: <notifyStr> : String to notify or time to wait"
"MandatoryArg: <enders>: String (or array of strings) to kill the thread.  Can be undefined."
"MandatoryArg: <fn> : pointer to a script function"
"OptionalArg: <arg1> : parameter 1 to pass to the process"
"OptionalArg: <arg2> : parameter 2 to pass to the process"
"OptionalArg: <arg3> : parameter 3 to pass to the process"
"OptionalArg: <arg4> : parameter 4 to pass to the process"
"Example: fish1 thread wait_then_fn( "path_complete", ::arriveAtLocation, false );"
"SPMP: both"
///ScriptDocEnd
 ============= 
*/ 
wait_then_fn( notifyStr, enders, fn, arg1, arg2, arg3, arg4 )
{
	self endon( "death" );
	if ( IsDefined( enders ) ) {
		if ( IsArray( enders ) ) {
			foreach ( ender in enders )
			{
				self endon( ender );
			}
		} else {
			self endon( enders );
		}
	}
	if ( isString( notifyStr ) )
		self waittill( notifyStr );
	else // Assume it's a time
		wait ( notifyStr );
	if ( IsDefined( arg4 ) )
		self [[ fn ]]( arg1, arg2, arg3, arg4 );
	else if ( IsDefined( arg3 ) )
		self [[ fn ]]( arg1, arg2, arg3 );
	else if ( IsDefined( arg2 ) )
		self [[ fn ]]( arg1, arg2 );
	else if ( IsDefined( arg1 ) )
		self [[ fn ]]( arg1 );
	else
		self [[ fn ]]();
}

/*
=============
///ScriptDocBegin
"Name: waittill_notify ( <waitStr> , <notifyEnt> , <notifyStr> , <ender> )"
"Summary: Wait for a notify on one ent and then notify another ent."
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <waitStr>: String to wait for."
"MandatoryArg: <notifyEnt>: Entity to notify."
"MandatoryArg: <notifyStr>: String to notify."
"OptionalArg: <ender>: String that will end this thread."
"OptionalArg: <multiple>: Continue waiting for more notifies after the first one.  Defaults to false."
"Example: waittill_notify ( "trigger", self, trigger.script_triggername );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

waittill_notify ( waitStr, notifyEnt, notifyStr, ender, multiple )
{
	if ( !isDefined( multiple ) ) multiple = false;
	doItAgain = true;
	while ( doItAgain )
	{
		self endon( "death" );
		if ( IsDefined( ender ) ) self endon( ender );
		self waittill( waitStr );
		notifyEnt notify( notifyStr );
		doItAgain = multiple;
	}
}

/*
=============
///ScriptDocBegin
"Name: loop_anim( <animArray> , <animName> , <ender> )"
"Summary: Plays an animation or a group of animations over and over until notified.  A very simple alternative to anim_loop_solo. Takes the animations as a parameter, so you don't need to set the model up in level.scr_anim."
"Module: Anim"
"CallOn: An entity"
"MandatoryArg: <animArray>: An array.  Can contain animations, arrays of animations and animweights (just like those found in level.scr_anim[animname])."
"MandatoryArg: <animName>: The animation index in the array, just like anime in anim_loop_solo."
"OptionalArg: <ender>: Notify string"
"OptionalArg: <animRate>: Playback speed for the animation.  Defaults to 1."
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/
loop_anim( animArray, animName, ender, animRate )
{
	self endon( "death" );
	if ( IsDefined( ender ) ) self endon( ender );
	
	while ( 1 )
	{
		a = self single_anim( animArray, animName, "loop_anim", false, animRate );
		if ( isSP() ) {
			self waittillmatch( "loop_anim", "end" );
		} else {
			wait GetAnimLength( a );
		}
	}
}

/*
=============
///ScriptDocBegin
"Name: single_anim( <animArray> , <animName> , <notifyStr> , <restartAnim> )"
"Summary: Plays an animation or a group of animations.  Similar to (but much simpler than) anim_single_solo. Takes the animations as a parameter, so you don't need to set the model up in level.scr_anim.  Returns the animation chosen, so you can check the length or whatever."
"Module: Anim"
"CallOn: An entity"
"MandatoryArg: <animArray>: An array.  Can contain animations, arrays of animations and weights (just like those found in level.scr_anim[animname]).  Can also contain mp animations (strings) using the suffix "mp"."
"MandatoryArg: <animName>: The animation index in the array, just like anime in anim_loop_solo."
"OptionalArg: <notifyStr>: String that the animation will notify for notetracks and when finished. Defaults to single_anim. SP only."
"OptionalArg: <restartAnim>: Set to true to force the animation to start from the beginning, otherwise it will simply continue if it is already playing.  Defaults to false. SP only."
"OptionalArg: <animRate>: Playback speed for the animation. Defaults to 1. SP only."
"Example: "
"SPMP: both"
///ScriptDocEnd
=============
*/

single_anim( animArray, animName, notifyStr, restartAnim, animRate )
{
	if ( !IsDefined( notifyStr ) ) notifyStr = "single_anim";
	if ( !IsDefined( animRate ) ) animRate = 1;
	
	if ( IsArray( animArray[ animName ] ) )
	{
		//AssertEx( IsDefined( animArray[ ( animName + "weight" ) ] )						 , "Array of anims labeled \""+animName+"\" does not have associated \""+animName+"weight\" array." );
		if ( !IsDefined( animArray[ ( animName + "weight" ) ] ) )
		{
			animArray[ ( animName + "weight" ) ] = [];
			keys = GetArrayKeys( animArray[ animName ] );
			foreach ( key in keys )
			{
				animArray[ ( animName + "weight" ) ][ key ] = 1;
			}
		}
		AssertEx( IsArray( animArray[ ( animName + "weight" ) ] )						 , "Array of anim weights labeled \""+animName+"weight\" is not an array." );
		AssertEx( animArray[ ( animName + "weight" ) ].size == animArray[ animName ].size, "Array of anims labeled \""+animName+"\" does not have a matching array of weights." );
		numAnims	= animArray[ animName ].size;
		totalWeight = 0;
		for ( i		= 0; i < numAnims; i++ )
		{
			totalWeight += animArray[ ( animName + "weight" ) ][ i ];
		}
		rand		  = RandomFloat( totalWeight );
		runningWeight = 0;
		sel			  = -1;
		while ( runningWeight <= rand )
		{
			sel++;
			runningWeight += animArray[ ( animName + "weight" ) ][ sel ];
		}
		animation = animArray[ animName ][ sel ];
		if ( IsDefined( animArray[ animName + "mp" ] ) ) {
			animation_mp = animArray[ animName + "mp" ][ sel ];
		} else {
			animation_mp = undefined;
		}
	}
	else
	{
		animation = animArray[ animName ];
		animation_mp = animArray[ animName + "mp" ];
	}
	if ( isSP() ) {
		if ( IsDefined( restartAnim) && restartAnim )
			self call [[ level.func[ "setflaggedanimknobrestart" ] ]]( notifyStr, animation, 1, 0.1, animRate );
		else
			self call [[ level.func[ "setflaggedanimknob" ] ]]( notifyStr, animation, 1, 0.1, animRate );
	} else {
		self call [[ level.func[ "scriptModelPlayAnim" ] ]]( animation_mp );
	}
	return animation;
}

/*
=============
///ScriptDocBegin
"Name: blendAnimsBySpeed( <speed> , <anims> , <animSpeeds>, <animLengths> )"
"Summary: Only blends in SPBlends between animations in an array according to the speed parameter.  Keeps all animations playing in sync (without using loopsync in the animtree).  Note: uses SetAnimLimited, so be sure to set the parent node in the animtree separately."
"Module: Anim"
"CallOn: An entity"
"MandatoryArg: <speed>: The number to be compared to the values in animSpeeds."
"MandatoryArg: <anims>: Array of animations."
"MandatoryArg: <anims>: Array of speeds that correspond to the animations."
"MandatoryArg: <animLengths>: Array of lengths of the animations, to save it having to be calculated every time the function is called."
"OptionalArg: <blendTime>: Blend time used as a parameter to SetAnim."
"Example: "
"SPMP: both"
///ScriptDocEnd
=============
*/
blendAnimsBySpeed( speed, anims, animSpeeds, animLengths, blendTime )
{
	/#
	Assert( anims.size == animSpeeds.size && anims.size == animLengths.size );
	for ( i=1; i<animSpeeds.size; i++)
		Assert( animSpeeds[ i-1 ] < animSpeeds[ i ] );
	#/
	if ( !IsDefined( blendTime ) ) blendTime = 0.1;
		
	speed = clamp( speed, animSpeeds[ 0 ], animSpeeds[ animSpeeds.size-1 ] );
	i = 0;
	while ( speed > animSpeeds[ i+1 ] )
	{
		i++;
	}
	fastWeight = speed - animSpeeds[ i ];
	fastWeight /=animSpeeds[ i+1 ] - animSpeeds[ i ];
	if ( isSP() )	// We only blend in SP
	{
		fastWeight = clamp( fastWeight, 0.01, 0.99 );	// Don't allow anims to blend out so they don't lose their time.
		// Scale playback rates according to blend weights.  
		// I'd love to use loopsync to achieve this but it appears to prevent SetAnimTime from working.
		speedRatio = animLengths[ i+1 ] / animLengths[ i ];
		fastRate = fastWeight + ( ( 1 - fastWeight ) * speedRatio );
		self call [[ level.func[ "setanimlimited" ] ]]( anims[ i   ], 1 - fastWeight, blendTime, fastRate / speedRatio );
		self call [[ level.func[ "setanimlimited" ] ]]( anims[ i+1 ],     fastWeight, blendTime, fastRate );
		for ( j=0; j<i; j++ )
		{
			speedRatio = animLengths[ i+1 ] / animLengths[ j ];
			self call [[ level.func[ "setanimlimited" ] ]]( anims[ j ],     0.01, blendTime, fastRate / speedRatio );
		}
		for ( j=i+2; j<animSpeeds.size; j++ )
		{
			speedRatio = animLengths[ i+1 ] / animLengths[ j ];
			self call [[ level.func[ "setanimlimited" ] ]]( anims[ j ],     0.01, blendTime, fastRate / speedRatio );
		}
	}
	else	// MP.  Just play the one that matches the speed best.
	{
		if ( fastWeight > 0.5 )
		{
			self call [[ level.func[ "scriptModelPlayAnim" ] ]]( anims[ i+1 ] );
		}
		else
		{
			self call [[ level.func[ "scriptModelPlayAnim" ] ]]( anims[ i ] );
		}
	}
}

/*
=============
///ScriptDocBegin
"Name: detect_events()"
"Summary: Makes an entity sentient and sets it up to detect nearby firefights.  self.interrupted will be set to true for the frame in which an interruption occurs, so you can check it in situations where you can't wait for a notification."
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <notifyString>: String that will be notified when violence is detected."
"Example: 	self thread detect_events( "interrupted" );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

detect_events( notifyString )
{
	if ( isSP() ) {
		self endon( "death" );
		self endon( "damage" );
		self call [[ level.makeEntitySentient_func ]]( "neutral" );
		self call [[ level.addAIEventListener_func ]]( "projectile_impact" );
		self call [[ level.addAIEventListener_func ]]( "bulletwhizby"		 );
		self call [[ level.addAIEventListener_func ]]( "gunshot"			 );
		self call [[ level.addAIEventListener_func ]]( "explode"			 );
		
		while( 1 )
		{
		    self waittill( "ai_event", eventtype );
		    self notify( notifyString );
		    self.interrupted = true;
			waittillframeend;
			self.interrupted = false;
		}
	}
}

/*
=============
///ScriptDocBegin
"Name: detect_people( <radius> , <notifyStr> )"
"Summary: Creates a trigger that detects people and vehicles.  self.interrupted will be set to true for the frame in which an interruption occurs, so you can check it in situations where you can't wait for a notification."
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <radius>: Radious and height of the trigger volume."
"MandatoryArg: <notifyStr>: String to notify when someone enters the trigger."
"MandatoryArg: <endonStr>: String(s) that will end this thread and delete the trigger when notified."
"Example: 	self thread detect_people( info.react_distance, "interrupted", [ "death", "damage" ] );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

detect_people( radius, notifyStr, endonStr )
{
	if ( !IsArray( endonStr ) )
	{
		tempStr = endonStr;
		endonStr = [];
		endonStr[0] = tempStr;
	}
	foreach (str in endonStr )
		self endon( str );
	
	// I think the trigger_radius flags are as follows: AI_AXIS = 1, AI_ALLIES = 2, AI_NEUTRAL = 4, NOTPLAYER = 8 VEHICLE = 16 TRIGGER_SPAWN = 32 TOUCH_ONCE = 64
	// AI_AXIS + AI_ALLIES + AI_NEUTRAL + VEHICLE = 23
	self.detect_people_trigger[ notifyStr ] = Spawn( "trigger_radius", self.origin, 23, radius, radius );
	
	for ( i = endonStr.size; i < 3; i++ )	// Pad the array to make it easier to use for function parameters.
		endonStr[i] = undefined;
	self thread delete_on_notify( self.detect_people_trigger[ notifyStr ], endonStr[0], endonStr[1], endonStr[2] );
	
	while( 1 )
	{
		self.detect_people_trigger[ notifyStr ] waittill( "trigger", interruptedEnt );
		self.interruptedEnt = interruptedEnt;	// (self.interruptedEnt can't be modified directly as a parameter to waittill.) 
	    self notify( notifyStr );
	    self.interrupted = true;
		waittillframeend;
		self.interrupted = false;
	}
}

detect_player_event( radius, notifyStr, endonStr, eventStr )
{
	if ( !IsArray( endonStr ) )
	{
		tempStr = endonStr;
		endonStr = [];
		endonStr[0] = tempStr;
	}
	foreach (str in endonStr )
		self endon( str );
	
	while( 1 ) {
		level.player waittill( eventStr );
		if ( DistanceSquared( level.player.origin, self.origin ) < radius*radius ) {
		    self notify( notifyStr );
			self.interruptedEnt = level.player;
		    self notify( notifyStr );
		    self.interrupted = true;
			waittillframeend;
			self.interrupted = false;
		}
	}
}

// Wraps <number> into 0 to <range>, just like AngleClamp does for the range of 0-360.  Result will be >=0 and < abs(range).  AKA modulo, %, remainder.
wrap( number, range )
{
	quotient = Int( number / range );
	remainder = number - ( range * quotient );
	if ( number < 0 ) remainder += range;
	if ( remainder == range ) remainder = 0;
	return remainder;
}

interactives_DrawDebugLineForTime( org1, org2, r, g, b, timer )
{
	/#
	if ( GetDvarInt( "interactives_debug" ) )
	{
		thread draw_line_for_time( org1, org2, r, g, b, timer );
	}
	#/
}

// Draws a cross in 3D space
drawCross( origin, size, color, timeSeconds )
{
	thread draw_line_for_time ( origin -( size, 0, 0 ), origin +( size, 0, 0 ), color[0], color[1], color[2], timeSeconds );
	thread draw_line_for_time ( origin -( 0, size, 0 ), origin +( 0, size, 0 ), color[0], color[1], color[2], timeSeconds );
	thread draw_line_for_time ( origin -( 0, 0, size ), origin +( 0, 0, size ), color[0], color[1], color[2], timeSeconds );
}

// Draws a circle in 3D space
drawCircle( origin, radius, color, timeSeconds )
{
	numSegments = 16;
	for ( i=0; i<360; i+=(360/numSegments) )
	{
		j = i + (360/numSegments);
		thread draw_line_for_time ( origin + ( radius*Cos(i), radius*Sin(i), 0 ), origin + ( radius*Cos(j), radius*Sin(j), 0 ), color[0], color[1], color[2], timeSeconds );
	}
}

// Draw an arc with an arrowhead on the end, in 3D space. Positive degrees means counterclockwise.
drawCircularArrow( origin, radius, color, timeseconds, degrees )
{
	if ( degrees == 0 ) return;
	numSegmentsFullCircle = 16;
	numSegments = int( 1 + (numSegmentsFullCircle * abs(degrees) / 360 ) );
	for ( seg=0; seg<numSegments; seg++ )
	{
		i = seg * degrees / numSegments;
		j = i + (degrees / numSegments);
		thread draw_line_for_time ( origin + ( radius*Cos(i), radius*Sin(i), 0 ), origin + ( radius*Cos(j), radius*Sin(j), 0 ), color[0], color[1], color[2], timeSeconds );
	}
	i = degrees;
	j = degrees - ( sign( degrees ) * 20 );
	thread draw_line_for_time ( origin + ( radius*Cos(i), radius*Sin(i), 0 ), origin + ( radius*0.8*Cos(j), radius*0.8*Sin(j), 0 ), color[0], color[1], color[2], timeSeconds );
	thread draw_line_for_time ( origin + ( radius*Cos(i), radius*Sin(i), 0 ), origin + ( radius*1.2*Cos(j), radius*1.2*Sin(j), 0 ), color[0], color[1], color[2], timeSeconds );
}

IsInArray( e, array )
{
	foreach ( a in array )
	{
		if ( e == a ) return true;
	}
	return false;
}

// Newton's Method (Newton-Raphson method) to find a root of the polynomial y = p3*x^3 + p2*x^2 + p1*x + p0 in the interval x0 to x1.
newtonsMethod( x0, x1, p3, p2, p1, p0, tolerance )
{
	iterations = 5;
	x = ( x0 + x1 ) / 2;
	offset = tolerance + 1;
	while ( abs( offset ) > tolerance && iterations > 0)
	{
		value = (p3*x*x*x) + (p2*x*x) + (p1*x) + p0;
		slope = (3*p3*x*x) + (2*p2*x) + p1;
		AssertEx( slope != 0, "newtonsMethod found zero slope.  Can't work with that." );
		offset = -1 * value / slope;
		oldx = x;
		x += offset;
		// Hack to keep the value within the bounds
		if ( x > x1 )
			x = ( oldX + (3*x1) ) / 4;
		else if ( x < x0 )
			x = ( oldX + (3*x0) ) / 4;
		iterations--;
		/# if ( iterations == 0 ) 
			Print( "_interactive_utility::newtonsMethod failed to converge. x0:"+x0+", x1:"+x1+", p3:"+p3+", p2:"+p2+", p1:"+p1+", p0:"+p0+", x:"+x );
		#/
	}
	return x;
}

// rootsOfCubic.  Doesn't work.
rootsOfCubic(a,b,c,d)
{
	if ( a == 0 ) {
		return rootsOfQuadratic(b,c,d);
	}
	// I can't do this mathematically without having a cube root function.
	q = (2*b*b*b) - (9*a*b*c) + (27*a*a*d);
	//Q = sqrt( q*q*q );
	bSquared3ac = (b*b) - (3*a*c);
	if ( ( bSquared3ac == 0 ) )
	{
		// If ( bSquared3ac == 0 ) there's only one real root regardless of what q is, but I can't find it without a cube root function.
		// root = cubeRoot( d/a );
	}
	if ( q == 0 && bSquared3ac==0 )
	{
		x[0] = -1 * b / (3*a);
	}
	else if ( q == 0 && bSquared3ac!=0 )
	{
		// There's a double root that I don't care about since it isn't a change from acceleration to deceleration
		// The other root is
		x[0] = ( (9*a*a*d) - (4*a*b*c) + (b*b*b) ) / ( a * ( (3*a*c) - (b*b) ) );
	}
	else
	{
		// Typical case...can't do it mathematically so do it numerically.
		// Need to break the curve into intervals and use Newton's Method above.
	}
}

rootsOfQuadratic(a,b,c)
{
	// The spline code generates some big numbers which cause errors due to overflow
	while ( abs(a)>65536 || abs(b)>65536 || abs(c)>65536 ) {
		a /= 10;
		b /= 10;
		c /= 10;
	}
	x = [];
	if ( a == 0 ) {
		if ( b != 0 ) {
			x[0] = -1 * c / b;
		}
	}
	else {
		bSquared4ac = (b*b) - (4*a*c);
		if ( bSquared4ac > 0 ) {
			x[0] = ( (-1*b) - sqrt( bSquared4ac ) ) / (2*a);
			x[1] = ( (-1*b) + sqrt( bSquared4ac ) ) / (2*a);
		}
		else if ( bSquared4ac == 0 ) {
			x[0] = -1 * b / (2*a);
		}
	}
	// Note: If there are no roots, x will be empty.
	return x;
}

// NonVectorLength
// Just like Length, but gets the length of a vector represented as an array.
// Optional second array will be sutracted (per-component) from the first.  That is, NonVectorLength(origin1,origtin2) is the same as Length(origin1-origin2).
NonVectorLength( array, array2 )
{
	AssertEx( ( !IsDefined(array2) ) || ( array.size==array2.size ), "NonVectorLength: second array must have same number of components as first array." );
	sum = 0;
	for ( i=0; i<array.size; i++ )
	{
		value = array[i];
		if ( IsDefined(array2) ) value -= array2[i];
		sum += value*value;
	}
	return sqrt( sum );
}

// clampAndNormalize
// Clamps x to the range min-max and then divides it by that range, to give a result between 0 and 1.
// Works for min<max and max<min.
clampAndNormalize( x, min, max )
{
	AssertEx( min != max, "clampAndNormalize: min must not equal max" );
	if ( min < max )
		x = clamp( x, min, max );
	else x = clamp( x, max, min );
	return ( x - min ) / (max - min );
}

PointOnCircle( center, radius, deg )
{
	x = Cos( deg );
	x *= radius;
	x += center[0];
	y = Sin( deg );
	y *= radius;
	y += center[1];
	z = center[2];
	return (x,y,z);
}

zeroComponent( vector, comp )
{
	return ( vector[0] * (comp != 0 ), vector[1] * (comp != 1 ), vector[2] * (comp != 2 ) );
}

rotate90AroundAxis( vector, comp )
{
	if ( comp == 0 )
	{
		return ( vector[0], vector[2], -1 * vector[1] );
	}
	else if ( comp == 1 )
	{
		return ( -1 * vector[2], vector[1], vector[0] );
	}
	else
	{
		return ( vector[1], -1 * vector[0], vector[2] );
	}
}