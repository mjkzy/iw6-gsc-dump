
//#include maps\_vehicle;
//#include maps\_anim;
//#include maps\_utility;
#include common_scripts\_csplines;
#include common_scripts\utility;
#include maps\interactive_models\_interactive_utility;

birds(info)
{
	if( getDvar( "r_reflectionProbeGenerate" ) == "1" )
		return;
	
	birds_finishBirdTypeSetup( info );

	if ( isSP() ) {
		level waittill ( "load_finished" );	
	} else {
		level waittill( "interactive_start" );
	}
	/#
		SetDevDvarIfUninitialized( "interactives_debug"	   , 0 );
		AssertEx( IsDefined( level._interactive ), "birds() setup run before any _interactive setup has been run." );
	#/
		
	if ( !IsDefined( level._interactive[ "birds_setup" ] ) )
	{
		level._interactive[ "birds_setup" ] = true;
		
		AssertEx( !IsDefined( level._interactive[ "bird_perches" ] ), "level._interactive[\"birds_perches\"] already set up!" );
		level._interactive[ "bird_perches" ] = [];
		// 2013/07/01 Perches are now set up from inside birds_setup() because I can't get ents using script_noteworthy in MP.
		
		flocks = GetEntArray( "interactive_birds", "targetname" );
		foreach ( flock in flocks )
		{
			flock thread birds_setup();
		}
	}
}

birds_setup()
{

	self birds_setUpConnectedPerches();
	
	if ( isdefined( self.script_triggername ) ) {
		selfStruct = self birds_saveToStruct();
		level waittill( "start_" + self.script_triggername );
		selfStruct birds_loadFromStruct();
	} else {
		self birds_createEnts();
		self thread birds_fly( self.target );
	}
}

birds_createEnts()
{
	AssertEx( IsDefined( self.interactive_type ), "Interactive_birds entity does not have an interactive_type keypair." );
	AssertEx( IsDefined( level._interactive ), "Interactive_birds entity in map, but level._interactive is not defined." );
	AssertEx( IsDefined( level._interactive[ self.interactive_type ] ), ( "Interactive_birds entity in map, but level._interactive[" + self.interactive_type + "] is not defined." ) );
	
	info = level._interactive[ self.interactive_type ];

	if (!IsDefined( self.interactive_number ) ) {
	    self.interactive_number = info.rig_numtags;
	}
	// TODO This shouldn't be an assert.  Change it to an error print.
	AssertEx( self.interactive_number <= info.rig_numtags, "Interactive_birds at "+self.origin+" has key value interactive_number too high.  According to its precache_script, the "+info.rig_model+" model only has tags for "+info.rig_numtags );
	
	//birdFlock	  = Spawn("script_model", self.origin );
	//self.angles = startAngles;
	if(info.rig_model != "use_radiant_model"){
		self SetModel( info.rig_model );
	}
	//self.animname = info.rig_model;	// Only needed by the _anim functions, which we're not using.
	if ( isSP() ) {
		self call [[ level.func[ "useanimtree" ] ]]( info.rig_animtree );	// UseAnimTree is a substitute for the usual _anim call "self setanimtree();"
	}
	self HideAllParts();
	
	// Attach birds to all the tags
	self.birds		= [];
	self.birdexists = [];
	self.numbirds	= 0;
	for ( i	= 1; i <= self.interactive_number; i++ )
	{
		// Create a bird, sit it on its perch
		self.birds[ i ] = Spawn( "script_model", self GetTagOrigin( "tag_bird" + i ) );
		self.birds[ i ] SetModel( info.bird_model["idle"] );
		self.birds[i].angles = self.angles;	// Needed for MP
		self.birds[ i ] LinkTo( self, ( "tag_bird" + i ) );
		if ( isSP() ) {
			self.birds[ i ] call [[ level.func[ "useanimtree" ] ]]( info.bird_animtree );
		}
		delay = ( i -  RandomFloat( 1 ) ) / self.interactive_number;
		self.birds[ i ] thread wait_then_fn( delay, "Stop initial model setup", ::bird_sit, self, "tag_bird" + i, info.bird_model["idle"], info.birdmodel_anims );
		// Set it so it can be killed
		self.birdexists[ i ] = true;
		self.numbirds++;
		if ( IsDefined( info.bird_health ) ) {
			self.birds[ i ].health = info.bird_health;
		} else {
			self.birds[ i ].health = 20;
		}
		self.birds[ i ] SetCanDamage( true );
		self.birds[ i ] thread bird_waitfordamage( self, i );
	}
	
	if ( IsDefined( self.script_triggername ) ) {
		self thread birds_waitForTriggerStop();
	}
	
	// Check that the perch was set up properly
	/#
	AssertEx( IsDefined( self.target )										  , "Interactive_birds object at " + self.origin + " does not have a target." );
	/*perches = GetEntArray( self.target, "targetname" );
	perchfound = false;
	foreach ( perch in perches )
	{
		if ( IsDefined( perch.script_noteworthy ) )
			if ( perch.script_noteworthy == "bird_perch" ) 
				perchfound = true;
	}
	AssertEx( perchfound						  							  , "Interactive_birds object at " + self.origin + " targets \""+self.target+"\", which is not a perch." );
	*/
	AssertEx( IsDefined( level._interactive[ "bird_perches" ][ self.target ] ), "Interactive birds: problem with target perch \""+self.target+"\"" );
	#/
}

birds_setUpConnectedPerches( perchEnt, path )
{
	if ( !IsDefined( perchEnt ) ) {
		Assert( IsDefined( self ) );
		AssertEx( IsDefined( self.target ), "Birds must target a perch.  Bird at "+self.origin+" does not have a target." );
		perchEnt = GetEnt( self.target, "targetname" );
		AssertEx( IsDefined( perchEnt ), "Birds must target a perch.  Cannot find perch with targetname "+self.target+" for bird at "+self.origin+"." );
	}

	perch						  = SpawnStruct();
	perch.targetname			  = perchEnt.targetname;
	perch.target				  = perchEnt.target;
	perch.origin				  = perchEnt.origin;
	perch.angles				  = perchEnt.angles;
	perch.interactive_takeoffAnim = perchEnt.interactive_takeoffAnim;
	perch.interactive_landAnim	  = perchEnt.interactive_landAnim;
	perch.script_radius			  = perchEnt.script_radius;
	perch.script_noteworthy		  = perchEnt.script_noteworthy;
	perch.script_triggername	  = perchEnt.script_triggername;
	if ( IsDefined( path ) ) {
		Assert( path[0] == perchEnt );
		path[0] = perch;
	}
	if ( IsDefined( perchEnt.incoming ) ) {
		AssertEx( 0, "It shouldn't be possible to get here any more.  Boon 2013-07-01" );
		foreach ( birdpath in perchEnt.incoming ) {
			birdpath.endPerch	 = perch;
		}
	}
	perchEnt Delete();
	
	AssertEx( !IsDefined( level._interactive[ "bird_perches" ][ perch.targetname ] ), "Bird perches must have unique targetnames.  More than one has targetname \""+perch.targetname+"\"" );
	level._interactive[ "bird_perches" ][ perch.targetname ] = perch;

	//AssertEx( IsDefined( perch.interactive_takeoffAnim ), "bird_perch node at " + perch.origin + " has no .interactive_takeoffAnim key pair." );
	//AssertEx( IsDefined( perch.interactive_landAnim ), "bird_perch node at " + perch.origin + " has no .interactive_landAnim key pair." );
	if ( !IsDefined( perch.interactive_takeoffAnim ) )  perch.interactive_takeoffAnim = "flying";
	if ( !IsDefined( perch.interactive_landAnim ) )  perch.interactive_landAnim = "flying";
	
	// See if the path has any brush triggers
	perch.triggers = [];
	targets = GetEntArray( perch.targetname, "target" );
	foreach ( target in targets )
	{
		if ( target.classname == "trigger_multiple" ) {
			perch.triggers[perch.triggers.size] = target;
		}
	}
	if( IsDefined( perch.target ) ) {
		targets = GetEntArray( perch.target, "targetname" );
		foreach ( target in targets )
		{
			if ( target.classname == "trigger_multiple" ) {
				perch.triggers[perch.triggers.size] = target;
			}
		}
	}
	if ( IsDefined( perch.script_triggername ) ) {
		targets = GetEntArray( perch.script_triggername, "target" );
		foreach ( target in targets )
		{
			if ( target.classname == "trigger_multiple" ) {
				perch.triggers[perch.triggers.size] = target;
			}
		}
	}
	// Set up the paths flying away from the perch.
	if ( !IsDefined( path ) ) {
		// The perch is an ent.  The paths are vehicle paths that the perch targets.  The perch at the start and end of each path make up part of the path.
		AssertEx( isDefined( perch.target ), "Interactive Bird perch at "+perch.origin+" does not have a target." );
		pathStarts = GetVehicleNodeArray( perch.target, "targetname" );
		AssertEx( pathStarts.size > 0, "Interactive Bird perch at " + perch.origin + " does not connect to any outgoing paths." );
		foreach ( pathStart in pathStarts )
		{
			pathNodes = [];
			pathNodes[ 0 ] = perch;
			pathNodes[ 1 ] = pathStart;
			for( node_num = 1; ( !isDefined( pathNodes[ node_num ].script_noteworthy ) ) || 
			    			   ( pathNodes[ node_num ].script_noteworthy != "bird_perch" ) ; node_num++ )
			{
				if ( !IsDefined( pathNodes[ node_num ].target ) )
				{
					break;
				}
				targetname = pathNodes[ node_num ].target;
				next_node = GetVehicleNode( targetname, "targetname" );
				if ( !IsDefined( next_node ) ) {
					next_node = GetNode( targetname, "targetname" );
					if ( !IsDefined( next_node ) ) {
						// Next_node is not a node, therefore it's a perch.  If it hasn't been set up it's still an ent.
						next_node = GetEnt( targetname, "targetname" );
						if ( IsDefined( next_node ) ) {
							AssertEx( next_node.script_noteworthy=="bird_perch", "Bird paths must be made of nodes and bird perches.  Path node at "+next_node.origin+" ia neither." );
							next_node = birds_setUpConnectedPerches( next_node );
						} else {
							AssertEx( IsDefined( level._interactive[ "bird_perches" ][ targetname ], "Birds error: Couldn't find a path node or perch with targetname "+targetname+"." ) );
							next_node = level._interactive[ "bird_perches" ][ targetname ];
						}
					}
				}
				AssertEx( IsDefined(next_node), "birds_findPathnodes: Couldn't find targetted node with targetname "+targetname+"." );
				pathNodes[ node_num + 1 ] = next_node;
			}
			perch birds_perchSetupPath( pathNodes );
		}
	}
	else {
		perch birds_perchSetupPath( path );
	}
	return perch;
}

birds_perchSetupPath( pathNodes )
{
	if ( !IsDefined( self.outgoing ) ) {
		self.outgoing = [];
	}
	birdpath = cspline_makePath( pathnodes );
	
	endPerch = pathNodes[ pathNodes.size - 1 ];
	if ( isDefined( endPerch.classname ) ) {	
		AssertEx( 0, "It shouldn't be possible to get here any more.  Boon 2013-07-01" );
		// Perch hasn't been converted to a struct yet, so link to this path so the .endPerch pointer can be maintained.
		if ( !IsDefined( endPerch.incoming ) ) endPerch.incoming = [];
		endPerch.incoming[ endPerch.incoming.size ] = birdpath;
	}
	if ( IsDefined( endPerch.script_noteworthy ) && endPerch.script_noteworthy == "bird_perch" )
	{
		birdpath.endPerch	 = endPerch;
		birdpath.landAnim 	 = endPerch.interactive_landAnim;
	}
	// None of these are really necessary.  They're just time savers later on.  Same with .landAnim above.
	birdpath.startOrigin = self.origin;
	birdpath.startAngles = self.angles;
	birdpath.takeoffAnim = self.interactive_takeoffAnim;
	birdpath.endOrigin	 = endPerch.origin;
	birdpath.endAngles	 = endPerch.angles;
	
	self.outgoing[ self.outgoing.size ] = birdpath;
}

birds_fly( start_perch )
{
	self endon( "death" );
	self.perch = level._interactive[ "bird_perches" ][ start_perch ];
	info  = level._interactive[ self.interactive_type ];
	AssertEx( IsDefined( info.rigmodel_anims[ self.perch.interactive_takeoffAnim ] ), "bird_perch node at " + self.perch.origin + " has .interactive_takeoffAnim key pair of " + self.perch.interactive_takeoffAnim + ", which is not defined for " + info.interactive_type );
	AssertEx( IsDefined( info.rigmodel_anims[ self.perch.interactive_landAnim ] ), "bird_perch node at " + self.perch.origin + " has .interactive_landAnim key pair of " + self.perch.interactive_landAnim + ", which is not defined for " + info.interactive_type );
	
	// Choose the first path to fly on
	birdpath = self.perch.outgoing[ RandomInt( self.perch.outgoing.size ) ];
	posVel		= cspline_getPointAtDistance( birdpath, 0 );
	self.origin = posVel[ "pos" ];
	self.angles = birdpath.startAngles;
	
	// Play an animation, since otherwise the birds will be in their default positions, which may not be appropriate for this perch
	if ( isSP() ) {
		self call [[ level.func[ "setanimknob" ] ]]( info.rigmodel_anims[ birdpath.takeoffAnim ], 1, 0, 0 );
		self call [[ level.func[ "setanimtime" ] ]]( info.rigmodel_anims[ birdpath.takeoffAnim ], 0 );
	} else {
		self call [[ level.func[ "scriptModelPlayAnim" ] ]]( info.rigmodel_anims[ self.perch.interactive_landAnim + "mp" ] );
	}

	speed	 = 0;
	self.landed = 1;
	
	// Monitor the perch for danger
	scareRadius = info.scareRadius;
	if ( IsDefined( self.perch.script_radius ) ) {
		scareRadius = self.perch.script_radius;
	}
	if ( scareRadius > 0 ) {
		self.perch thread birds_perchDangerTrigger( scareRadius, "triggered", "leaving perch" );
	}
		
	for ( ;; )
	{		
		// Calculate how much of the takeoff anim must play before we can start moving, and how much of the 
		// landing must play after we finish moving.
		takeoffStartFrac = 0;
		takeoffAnim 	= info.rigmodel_anims[ birdpath.takeoffAnim ];
		takeoffAnim_mp	= info.rigmodel_anims[ birdpath.takeoffAnim + "mp" ];
		flyAnim			= info.rigmodel_anims[ "flying" ];
		flyAnim_mp		= info.rigmodel_anims[ "flyingmp" ];
		if ( IsDefined( birdpath.landAnim ) ) {
			landAnim	= info.rigmodel_anims[ birdpath.landAnim ];
			landAnim_mp	= info.rigmodel_anims[ birdpath.landAnim + "mp" ];
		} else { 
			landAnim	= undefined;
			landAnim_mp	= undefined;
		}
		if ( isDefined( info.rigmodel_pauseStart [ birdpath.takeoffAnim ] ) )
			pauseStart	= info.rigmodel_pauseStart[ birdpath.takeoffAnim ];//Play animation for this long before starting to move along the path, for all the birds to take off
		else pauseStart = 0;
		takeoffStartTime = 0;
		if ( !self.landed )
		{
			if ( isSP() ) {
				// We need to see what animation we're currently playing, so we can match it
				if ( IsDefined( landAnim ) && self.currentAnim == landAnim ) {
					takeoffStartFrac = 1 - ( self call [[ level.func[ "getanimtime" ] ]]( self.currentAnim ) );
					takeoffStartTime = takeoffStartFrac * GetAnimLength( takeoffAnim );
					pauseStart -= takeoffStartTime;
					pauseStart = max( 0, pauseStart );
				} else {
					// Assume it's the fly anim
					takeoffAnim		= info.rigmodel_anims[ "flying" ];
					takeoffAnim_mp	= info.rigmodel_anims[ "flyingmp" ];
					takeoffStartFrac = self call [[ level.func[ "getanimtime" ] ]]( self.currentAnim );
					takeoffStartTime = takeoffStartFrac * GetAnimLength( takeoffAnim );
					pauseStart = 0;
				}
			} else {
				takeoffAnim		= info.rigmodel_anims[ "flying" ];
				takeoffAnim_mp	= info.rigmodel_anims[ "flyingmp" ];
				takeoffStartFrac = 0;
				takeoffStartTime = 0;
				pauseStart = 0;
			}
		}
		if ( IsDefined( landAnim ) && isDefined( info.rigmodel_pauseEnd [ birdpath.landAnim ] ) )
			pauseEnd   = info.rigmodel_pauseEnd [ birdpath.landAnim ];//Animation should continue for this long after flock finishes path, for all the birds to land
		else pauseEnd = 0;
		
		// Figure out how long it will take to fly the path	
		accnFrame			 = info.accn /( 20 * 20 );			// Inches per frame per frame
		pathLength			 = birdpath.Segments[ birdpath.Segments.size - 1 ].endAt; // In inches
		topSpeedPossible	 = sqrt(  (accnFrame * pathLength ) + ( speed * speed / 2 ) );
		topSpeedFrame		 = info.topSpeed / 20;	   			// Inches per frame
		if ( topSpeedPossible < topSpeedFrame )
			topSpeedFrame = topSpeedPossible;
		
		framesAccelerating	 = Int( ( topSpeedFrame - speed ) / accnFrame );
		distanceAccelerating = ( accnFrame * ( framesAccelerating / 2 ) * ( framesAccelerating + 1 ) ) + ( speed * framesAccelerating );
		if ( IsDefined( birdpath.endPerch ) )
		{
			framesDecelerating	 = Int( topSpeedFrame / accnFrame );
			distanceDecelerating = accnFrame * ( framesDecelerating / 2 ) * ( framesDecelerating + 1 );
			AssertEx( pathLength + topSpeedFrame > distanceAccelerating + distanceDecelerating, "Interactive_birds path math failure.  Path from "+birdpath.startorigin+" to "+birdpath.endPerch.targetname+" is "+pathLength+" long, but distance accelerating is longer: "+ (distanceAccelerating + distanceDecelerating) +"." );
		}
		else
		{
			framesDecelerating = 0;
			distanceDecelerating = 0;
			AssertEx( pathLength + topSpeedFrame > distanceAccelerating + distanceDecelerating, "Interactive_birds path math failure.  Path from "+birdpath.startorigin+" to nowhere is "+pathLength+" long, but distance accelerating is longer: "+ (distanceAccelerating + distanceDecelerating) +"." );
		}			
		
		
		// The idea is that we play a takeoff, an integer number of loops, then a landing.  We scale the playback rate of 
		// all three animations so that they match the amount of time we will be in the air.
		framesTopSpeed		 = ( pathLength - ( distanceAccelerating + distanceDecelerating ) ) / topSpeedFrame;
		pathTime			 = ( framesTopSpeed + ( framesAccelerating + framesDecelerating ) ) / 20;
		loopAnimTime		 = GetAnimLength( flyAnim );
		if ( IsDefined( landAnim ) )
			otherAnimTime		 = GetAnimLength( takeoffAnim ) + GetAnimLength( landAnim ) - ( pauseStart + takeoffStartTime + pauseEnd );
		else
			otherAnimTime		 = GetAnimLength( takeoffAnim )								- ( pauseStart + takeoffStartTime + pauseEnd );
		numLoops			 = Int( ( ( pathTime - otherAnimTime ) / loopAnimTime ) + 0.5 );// Int() rounds down, so add 0.5 to get nearest int.
		animSpeed			 = ( ( numLoops * loopAnimTime ) + otherAnimTime ) / pathTime;
		
		// Figure out the angle change
		angleChange = birdpath.endAngles - birdpath.startAngles;
		angleChange = ( AngleClamp180( angleChange[0] ), AngleClamp180( angleChange[1] ), AngleClamp180( angleChange[2] ) );

		if (self.landed)	// We might already be flying, in which case skip the waiting
		{
			// Wait for something to happen...and fly!
			self thread idle_cooing(info);
			self.perch waittill( "triggered" );
			self notify( "stop_path" ); //Only needed for MP where I can't start an animation partway through so the land might still be playing.
			self.landed = 0;
			self thread flock_fly_anim ( takeoffAnim, 0, flyAnim, landAnim, animSpeed, numLoops, takeoffAnim_mp, flyAnim_mp, landAnim_mp );
			self thread flock_playSound( info, "takeoff" );
			skipTakeoff = ( pauseStart == 0 );
			for ( i = 1; i <= self.interactive_number; i++ )
			{
				if ( self.birdexists[ i ] ) {
					self.birds[ i ] thread bird_flyFromPerch( self, ( "tag_bird" + i ), info.bird_model["fly"], info.bird_model["idle"], info.birdmodel_anims, ( "land_" + i ), ( "takeoff_" + i ), skipTakeoff );
				}
			}
		}
		else
		{
			self notify( "stop_path" );
			self thread flock_fly_anim ( takeoffAnim, takeoffStartFrac, flyAnim, landAnim, animSpeed, numLoops, takeoffAnim_mp, flyAnim_mp, landAnim_mp );
			for ( i = 1; i <= self.interactive_number; i++ )
			{
				if ( self.birdexists[ i ] ) {
					if ( isSP() )
						waitTime = undefined;
					else
						waitTime = RandomFloat(0.5);
					self.birds[ i ] thread bird_fly( self, ( "tag_bird" + i ), info.bird_model["fly"], info.bird_model["idle"], 
												    info.birdmodel_anims, ( "land_" + i ), waitTime );
				}
			}
		}
		if ( IsDefined( self.perch ) ) {
			self.perch notify( "leaving perch" );
			self.perch = undefined;
		}
		/#
			thread cspline_test( birdpath, pathTime );
			self thread debugprint( "PathLength: "+pathLength+"\nnumLoops: "+numLoops+"\n"+"Waiting "+pauseStart+" for birds to take off." );
		#/
		wait ( pauseStart );
		
		/#self thread debugprint( "Accelerating" );#/
		Distance = 0;
		while ( speed < ( topSpeedFrame - accnFrame ) )
		{
			speed += accnFrame;
			Distance += speed;
			posVel = flock_setFlyingPosAndAngles( birdPath, distance, pathLength, speed, angleChange );
			wait 0.05;
		}
		/#self thread debugprint( "Cruising" );#/

		speed = topSpeedFrame;
		while ( Distance < ( pathLength - distanceDecelerating ) )
		{
			Distance += speed;
			posVel = flock_setFlyingPosAndAngles( birdPath, distance, pathLength, speed, angleChange );
			wait 0.05;
		}
		if ( !IsDefined( birdpath.endPerch ) )
		{
			// There's no perch at the end, so delete the birds instead of decelerating.
			self birds_delete();
			assert(0);	// Just checking.  This thread should be killed by the delete function above.
		}
		
		/#self thread debugprint( "Decelerating" );#/

		distanceToTravel = pathLength - Distance;
		speedAdjust		 = distanceToTravel / distanceDecelerating;	 // To make sure we hit the spot exactly
		speed = accnFrame * ( Int( speed/accnFrame ) + 1 );	// Round speed up to nearest multiple of accnFrame;		
		// As we approach, monitor the perch to make sure it's safe
		self.perch = birdpath.endPerch;
		AssertEx( IsDefined( info.rigmodel_anims[ self.perch.interactive_takeoffAnim ] ), "bird_perch node at " + self.perch.origin + " has .intaractive_takeoffAnim key pair of " + self.perch.interactive_takeoffAnim + ", which is not defined for " + info.interactive_type );
		AssertEx( IsDefined( info.rigmodel_anims[ self.perch.interactive_landAnim ] ), "bird_perch node at " + self.perch.origin + " has .interactive_landAnim key pair of " + self.perch.interactive_landAnim + ", which is not defined for " + info.interactive_type );
		self.perch thread birds_perchDangerTrigger( scareRadius, "triggered", "leaving perch" );
		while ( ( speed > topSpeedFrame*0.75 ) || ( ( speed > 0 ) && ( birds_isPerchSafe( self.perch ) ) ) )
		{
			speed -= accnFrame;
			Distance += speed * speedAdjust;
			posVel = flock_setFlyingPosAndAngles( birdPath, distance, pathLength, speed, angleChange );
			wait 0.05;
		}
		
		if ( speed <= 0 )
		{
			/#self thread debugprint( "Waiting for birds to land" );#/
			// We arrived
			AssertEx( abs( Distance - pathLength ) < 0.1, "Please let Boon know that his bird path function failed to hit the end spot perfectly." );
			self.origin = self.perch.origin;
			self.angles = self.perch.angles;
			birdpath = self.perch.outgoing[ RandomInt( self.perch.outgoing.size ) ];
			for ( i=0; (i < 20*pauseEnd) &&  birds_isPerchSafe( self.perch ); i++ )
			{
				wait 0.05;
			}
			if ( birds_isPerchSafe( self.perch ) )
			{
				self.landed = 1;
				/#self thread debugprint( "Landed safely" );#/
			}
		}
		else
		{
			/#self thread debugprint( "Moving to new path" );#/
			// We were interrupted.  Join to an outgoing path and fly away immediately.
			mainPath = self.perch.outgoing[ RandomInt( self.perch.outgoing.size ) ];
			birdpath = birds_path_move_first_point( mainPath, posVel["pos"], posVel["vel"]*(speed/topSpeedFrame) );
			birdpath.startAngles = self.angles;
			self.perch notify( "leaving perch" );
			self.perch = undefined;
		}
	}
}

idle_cooing(info)
{
	if ( IsDefined( info.sounds ) && IsDefined( info.sounds[ "idle" ] ) )
	{
		self.perch endon ( "triggered" );
		while(1)
		{
			wait RandomFloatRange(8, 16);//TODO JL change this delay to whatever is appropriate for the new sound
			self thread flock_playSound( info, "idle" );
		}
	}
}

debugprint( str )
{
	/#
	self notify( "stop_debugprint" );
	self endon ( "stop_debugprint" );
	self endon ( "death" );
	while(1)
	{
		if ( GetDvarInt( "interactives_debug" ) )
		{
			Print3d( self.origin, str, (0,0,1), 1, 2, 1 );
			wait (0.05);
		}
		else
		{
			wait 1;
		}
	}
	#/
}

birds_set_flying_angles( birdFlock, flockVel, birds )
{
	// Blend the angles of each bird between the angle of its tag and the direction the flock is moving
	// (TODO: This could really use profiling. It looks slow.)
	tagWeight = 0.2;
	assert( isSP() );	// This function is SP only.
	for ( i = 1; i <= birds.size; i++ )
	{
		if ( self.birdexists[ i ] )
		{
			tagAngles	= birdFlock GetTagAngles( "tag_bird" + i );
			tagForward	= AnglesToForward( tagAngles ) / tagWeight;
			newForward	= tagForward + flockVel;
			newAngles	= VectorToAngles( newForward );
			anglesToTag = newAngles - tagAngles;
			anglesToTag = ( AngleClamp180( anglesToTag[ 0 ] ) / 3, AngleClamp180( anglesToTag[ 1 ] ), 0 );
			birds[ i ] LinkTo( birdFlock, ( "tag_bird" + i ), ( 0, 0, 0 ), anglesToTag );
			/#
			if ( GetDvarInt( "interactives_debug" ) )
			{
				tagOrigin = birdFlock GetTagOrigin( "tag_bird" + i );
									   //   org1 	   org2 				   r    g    b    timer   
				thread draw_line_for_time( tagOrigin, tagOrigin + tagForward, 1	 , 0  , 0  , 0.1 );
				thread draw_line_for_time( tagOrigin, tagOrigin + flockVel	, 0	 , 1  , 0  , 0.1 );
			}
			#/	
		}
	}
}

flock_setFlyingPosAndAngles( birdPath, distance, pathLength, speed, angleChange )
{
	posVel		= cspline_getPointAtDistance( birdpath, distance );
	self.origin = posVel[ "pos" ];
	if ( isSP() ) {
		self.angles = birdpath.startAngles + ( ( angleChange ) * ( distance / pathLength ) );
		birds_set_flying_angles( self, ( posVel[ "vel" ] * speed ), self.birds );
	} else {
		lookAhead = 15;	// Frames
		lookAheadDistance = distance + ( speed * lookAhead );
		if ( lookAheadDistance < pathLength ) {
			targetPosVel = cspline_getPointAtDistance( birdpath, lookAheadDistance );
			pathAngles = VectorToAngles( targetPosVel[ "vel" ] );
			angleChange = pathAngles - self.angles;
			angleChange = anglesSoftClamp(angleChange, 2, 0.3, 8);
		} else {
			// We're near the end. Just interpolate smoothly to the final angles.
			angleChange = birdPath.endAngles - self.angles;
			angleChange = ( AngleClamp180(angleChange[0]), AngleClamp180(angleChange[1]), AngleClamp180(angleChange[2]) );
			if ( speed > 0 ) {
				timeRemaining = ( pathLength - distance ) / speed;
				if ( timeRemaining > 1 ) {	// (Could probably assert that timeRemaining > 0 rather than testing.)
					angleChange /= timeRemaining;
				}
			}
		}
		self.angles += angleChange;
		///#
		//thread draw_arrow_time( self.origin, self.origin + 50 * AnglesToForward( self.angles ), (1,1,1), 0.1 );
		//for ( i = 1; i <= self.birds.size; i++ ) {
		//	if ( self.birdexists[ i ] ) {
		//		thread draw_arrow_time( self.birds[i].origin, self.birds[i].origin + 15 * AnglesToForward( self.birds[i].angles ), (1,1,1), 0.1 );
		//	}
		//}
		//#/
	}
	//print3d( self.origin, speed, (0,0,1), 1, 2, 1 );
	return posVel;
}


flock_playSound( info, soundIndex )
{
	if ( IsDefined( info.sounds ) && IsDefined( info.sounds[ soundIndex ] ) ) {
		AssertEx ( SoundExists( info.sounds[ soundIndex ] ), "Interactive " + info.interactive_type + ": missing soundalias " + info.sounds[ soundIndex ] );
		self PlaySound( info.sounds[ soundIndex ] );
	}
}

flock_fly_anim ( takeoffAnim, takeoffFrac, loopAnim, landAnim, animSpeed, numLoops, takeoffAnim_mp, loopAnim_mp, landAnim_mp )
{
	self endon( "death" );
	self endon( "stop_path" );
	if ( isSP() ) {
		blendTime = 0;
		if ( GetAnimLength( takeoffAnim ) == 0 ) {
			PrintLn( "^1ERROR: Animation (printed below) not found.  You may need to Repackage the map.\n" );	
			PrintLn( takeoffAnim );
		} else {
			fracPerFrame = animSpeed / ( GetAnimLength( takeoffAnim ) * 20 );
			takeoffFrac -= 2 * fracPerFrame;	// Don't mess with timing unless it's out by a few frames
			if ( takeoffFrac > fracPerFrame )
			{
				blendTime = 0.3;
			}
		
			self call [[ level.func[ "setflaggedanimknob" ] ]]( "bird_rig_takeoff_anim", takeoffAnim, 1, blendTime, animSpeed );
			self.currentAnim = takeoffAnim;
			if ( takeoffFrac > fracPerFrame )
			{
				// Jump through a bunch of hoops because SetAnimTime doesn't work on the same frame as SetFlaggedAnimKnob.
				// Note: I also tried to do this by fast-forwarding through the animation, so I would get the notetracks for free, but 
				// once the animation playback speed got above 5 or 10, the actual playback speed would occasionally be out by a factor 
				// of more than 2, which messed everything up.
				waitframe();
				self call [[ level.func[ "setanimtime" ] ]]( takeoffAnim, takeoffFrac );
				self waittillmatch( "bird_rig_takeoff_anim", "end" );
				// else, go straight to the loop animation
			}
			else
			{
				self waittillmatch( "bird_rig_takeoff_anim", "end" );
			}
		}
	
		self call [[ level.func[ "setflaggedanimknobrestart" ] ]]( "bird_rig_loop_anim", loopAnim, 1, 0, animSpeed );
		self.currentAnim = loopAnim;
		for ( i=0; i<numLoops; i++ )
		{
			self waittillmatch( "bird_rig_loop_anim", "end" );
		}
	
		if ( IsDefined( landAnim ) )
		{
			self call [[ level.func[ "setflaggedanimknobrestart" ] ]]( "bird_rig_land_anim", landAnim, 1, 0.05, animSpeed );
			self.currentAnim = landAnim;
			self waittillmatch( "bird_rig_land_anim", "end" );
		}
	} else {
		if ( GetAnimLength( takeoffAnim ) == 0 ) {
			PrintLn( "^1ERROR: Animation "+takeoffAnim_mp+" not found.  You may need to Repackage the map.\n" );	
		} else {
			if ( takeoffFrac < 0.2 ) {
				self call [[ level.func[ "scriptModelPlayAnim" ] ]]( takeoffAnim_mp );
				self.currentAnim = takeoffAnim;
				wait( GetAnimLength( takeoffAnim ) );
			}
		}
		self call [[ level.func[ "scriptModelPlayAnim" ] ]]( loopAnim_mp );
		self.currentAnim = loopAnim;
		for ( i=0; i<numLoops; i++ ) {
			wait( GetAnimLength( loopAnim ) );
		}
		if ( IsDefined( landAnim ) )
		{
			self call [[ level.func[ "scriptModelPlayAnim" ] ]]( landAnim_mp );
			self.currentAnim = landAnim;
			wait( GetAnimLength( landAnim ) );
			for ( i = 1; i <= self.birds.size; i++ ) {
				self notify( "bird_rig_land_anim", ( "land_" + i ) );	// Tell birds to stop flapping
			}
		}
	}
}

bird_flyFromPerch( rigModel, rigTag, birdFlyModel, birdSitModel, animArray, notifyLand, notifyTakeoff, skipTakeoff )
{
	self endon( "death" );
	rigModel endon( "stop_path" );
	if ( isSP() ) {
		if ( IsDefined( notifyTakeoff ) && !skipTakeoff )
		{
			rigModel waittillmatch( "bird_rig_takeoff_anim", notifyTakeoff );
		}
	} else {
		wait ( RandomFloat( 0.3 ) );
	}
	self notify( "Stop initial model setup" );
	self SetModel( birdFlyModel );
	self notify( "stop_loop" );
	if ( skipTakeoff ) {
		flyAnim = self single_anim( animArray, "flying", undefined, false );
		if ( isSP() ) {
			waitframe();
			self call [[ level.func[ "setanimtime" ] ]]( flyAnim, RandomFloat( 1 ) );
		}
	}
	else if ( IsDefined( animArray[ "takeoff" ] ) ) {
		takeoffAnim = self single_anim( animArray, "takeoff", "takeoff_anim", true );
		if ( isSP() ) {
			self waittillmatch( "takeoff_anim", "end" );
		} else {
			wait ( GetAnimLength( takeoffAnim ) );
		}
	}
	bird_fly( rigModel, rigTag, birdFlyModel, birdSitModel, animArray, notifyLand );
}

bird_fly( rigModel, rigTag, birdFlyModel, birdSitModel, animArray, notifyLand, waitTime )
{
	self endon( "death" );
	rigModel endon( "stop_path" );
	
	if ( IsDefined( waitTime ) ) {
		wait waitTime;	// For MP, because anims always restart in MP and we don't want all birds flapping in sync.
	}
	self SetModel( birdFlyModel );
	self notify( "stop_loop" );
	self thread loop_anim( animArray, "flying", "stop_loop" );
	
	rigModel waittillmatch( "bird_rig_land_anim", notifyLand );
	if ( !isSP() ) {
		wait( RandomFloat( 1 ) * RandomFloat( 1 ) );
	}
	if ( IsDefined( animArray[ "land" ] ) ) {
		self notify( "stop_loop" );
		self endon( "stop_loop" );
		self single_anim( animArray, "land", undefined, true );
	}
	self thread bird_sit( rigModel, rigTag, birdSitModel, animArray );
}

bird_sit( rigModel, rigTag, birdSitModel, animArray )
{
	self endon( "death" );
	self SetModel( birdSitModel );
	self notify( "stop_loop" );
	self loop_anim( animArray, "idle", "stop_loop" );
}

bird_waitfordamage( flock, number )
{
	while ( 1 ) {
		self waittill( "damage", damage, attacker, direction_vec, point, type );
		//self waittill( "damage" );
		if ( IsDefined( flock.perch ) ) {
			flock.perch notify( "triggered" );
			flock.perch.lastAIEventTrigger = GetTime();
		}
		if ( isDefined( self.origin ) )	// That is, this bird hasn't been deleted already
		{
			if ( type == "MOD_GRENADE_SPLASH" )
				point = self.origin + (0,0,5);
			PlayFX( level._interactive[ flock.interactive_type ].death_effect, point );
			if ( self.health <= 0 ) {
				flock.birdexists[ number ] = false;
				flock.numbirds--;
				if ( flock.numbirds == 0 )
					flock Delete();
				self Delete();
			}
		}
	}
}

// Optional takeoffDelay is for larger flocks (eg Egrets) that have a takeoff animation for the bird models.  Once all 
// the takeoff notetracks in the flock animation have played, we need to wait an additional time (takeoffDelay) for the 
// last bird takeoff animation to play.
birds_finishBirdTypeSetup( info, takeoffDelay )
{
	AssertEx( IsDefined( info.rigmodel_anims[ "flying" ] ), "Rig \"Flying\" animation for "+info.interactive_type+" not defined.  Birds cannot work without a fly anim." );
	AssertEx( GetAnimLength( info.rigmodel_anims[ "flying" ] ) > 0, "Flock fly anim for "+info.interactive_type+" not found.  Birds cannot work without a fly anim." );
	if ( !IsDefined( takeoffDelay ) ) takeoffDelay = 0;
	// Precache.	
	// Feb 2014: According to SimonC, precache is deprecated and should generate errors. They don't generate 
	// errors, and they seem to be necessary for reflection probe generation (easily avoided in this case).
	/*
	PreCacheModel( info.rig_model );
	foreach ( model in info.bird_model ) {
		PreCacheModel( model );
	}
	if ( !isSP() ) {
		foreach ( sound in info.sounds ) {
			PrecacheSound( sound );
		}
		for ( i=1; i<=12; i++ ) {
			PreCacheString( "tag_bird"+i );
		}
		foreach ( animIndex in GetArrayKeys( level._interactive[ self.interactive_type ].rigmodel_anims ) ) {
			if ( IsEndStr( animIndex, "mp" ) ) {
				anims = level._interactive[ self.interactive_type ].rigmodel_anims[ animIndex ];
				if ( IsArray( anims ) ) {
			    	foreach ( a in anims ) {
			    		call [[ level.func[ "precacheMpAnim" ] ]]( a );
			    	}
			    } else {
			    	call [[ level.func[ "precacheMpAnim" ] ]]( anims );
			    }
			}
		}
		foreach ( animIndex in GetArrayKeys( level._interactive[ self.interactive_type ].birdmodel_anims ) ) {
			if ( IsEndStr( animIndex, "mp" ) ) {
				anims = level._interactive[ self.interactive_type ].birdmodel_anims[ animIndex ];
				if ( IsArray( anims ) ) {
			    	foreach ( a in anims ) {
			    		call [[ level.func[ "precacheMpAnim" ] ]]( a );
			    	}
			    } else {
			    	call [[ level.func[ "precacheMpAnim" ] ]]( anims );
			    }
			}
		}
	}*/
	// Define functions for removing entities when they're not needed.
	info.saveToStructFn = ::birds_saveToStruct;
	info.loadFromStructFn = ::birds_loadFromStruct;
	// Determine how far into the takeoff and land animations the flock can move away from its perch.
	info.rigmodel_pauseStart = [];
	info.rigmodel_pauseEnd = [];
	indices = GetArrayKeys( info.rigmodel_anims );
	foreach ( index in indices )
	{
		if ( !IsEndStr( index, "mp" ) ) {
			if ( string_starts_with( index, "takeoff_" ) ) {
				if ( GetAnimLength( info.rigmodel_anims[ index ] ) == 0 ) {
					PrintLn( "^1ERROR: Animation "+index+" for interactive "+info.interactive_type+" not found.  You may need to Repackage the map.\n" );		
					info.rigmodel_anims[ index ] = info.rigmodel_anims[ "fly" ];
					info.rigmodel_pauseStart[ index ] = 0;
				} else {
					info.rigmodel_pauseStart[ index ]	= birds_get_last_takeoff( info, index, info.rig_numtags ) + takeoffDelay;
				}
			} else if ( string_starts_with( index, "land_" ) ) {
				if ( GetAnimLength( info.rigmodel_anims[ index ] ) == 0 ) {
					PrintLn( "^1ERROR: Animation "+index+" for interactive "+info.interactive_type+" not found.  You may need to Repackage the map.\n" );		
					info.rigmodel_anims[ index ] = info.rigmodel_anims[ "fly" ];
					info.rigmodel_pauseEnd[ index ] = 0;
				} else {
					info.rigmodel_pauseEnd[ index ]		= birds_get_first_land( info, index, info.rig_numtags );
				}
			}
		}
	}
}

// birds_get_last_takeoff() - Internal _birds function.
// Gets the time of the last "takeoff" notetrack in an animation. This is used to prevent the 
// flock from beginning to fly along a path until all the individual birds are in the air.
birds_get_last_takeoff( info, animalias, numtags )
{
	Assert( IsDefined( info.interactive_type ) );
	animation = info.rigmodel_anims[ animalias ];
	Assert ( GetAnimLength( animation ) > 0 );
	lastTime  = 0;
	for ( i	  = 1; i <= numtags; i++ )
	{
		times = GetNotetrackTimes( animation, "takeoff_" + i );

		if ( times.size <= 0 ) {
			PrintLn( "^1ERROR: Found no notetrack called \""+"takeoff_"+i+"\" in "+info.interactive_type+" rigmodel animation " + animalias + "\n" );
		} else if ( times.size > 1 ) {
			PrintLn( "^1ERROR: Found more than one notetrack called \""+"takeoff_"+i+"\" in "+info.interactive_type+" rigmodel animation " + animalias + "\n" );
		} else if ( times[ 0 ]  > lastTime )
		{
			lastTime = times[ 0 ];
		}
	}
	return GetAnimLength( info.rigmodel_anims[ animalias ] ) * lastTime;
}

// birds_get_first_land() - Internal _birds function.
// Gets the time of the first "land" notetrack in an animation. This is used to make sure the 
// flock arrives at its destination before the individual birds stop flying.
birds_get_first_land( info, animalias, numtags )
{
	Assert( IsDefined( info.interactive_type ) );
	animation = info.rigmodel_anims[ animalias ];
	Assert ( GetAnimLength( animation ) > 0 );
	firstTime = 1;
	for ( i	  = 1; i <= numtags; i++ )
	{
		times = GetNotetrackTimes( animation, "land_" + i );
		if ( times.size <= 0 ) {
			PrintLn( "^1ERROR: Found no notetrack called \""+"land_"+i+"\" in "+info.interactive_type+" rigmodel animation " + animalias + "\n" );
		} else if ( times.size > 1 ) {
			PrintLn( "^1ERROR: Found more than one notetrack called \""+"land_"+i+"\" in "+info.interactive_type+" rigmodel animation " + animalias + "\n" );
		} else if ( times[ 0 ] < firstTime ) {
			firstTime = times[ 0 ];
		}
	}
	return GetAnimLength( info.rigmodel_anims[ animalias ] ) * ( 1 - firstTime );
}

// Create triggers to monitor a perch for danger.
birds_perchDangerTrigger( radius, notifyStr, ender )
{
	// I think the trigger_radius flags are as follows: AI_AXIS = 1, AI_ALLIES = 2, AI_NEUTRAL = 4, NOTPLAYER = 8 VEHICLE = 16 TRIGGER_SPAWN = 32 TOUCH_ONCE = 64
	// AI_AXIS + AI_ALLIES + AI_NEUTRAL + VEHICLE = 23
	self.trigger = Spawn( "trigger_radius", self.origin-(0,0,radius), 23, radius, 2*radius );
	self thread delete_on_notify( self.trigger, "death", ender );
	self thread birds_perchTouchTrigger( self.trigger, notifyStr, ender );
	self thread birds_perchEventTrigger( radius, notifyStr, ender);
	foreach ( trigger in self.triggers )
		self thread birds_perchTouchTrigger( trigger, notifyStr, ender );
}

birds_perchTouchTrigger( trigger, notifyStr, ender )
{
	self endon( "death" );
	self endon( ender );

	while( 1 )
	{
		trigger.anythingTouchingTrigger = 0;
		trigger waittill( "trigger" );
	    self notify( notifyStr );
		trigger.anythingTouchingTrigger = 1;
		/#if ( GetDvarInt( "interactives_debug" ) ) {
			Print3d( self.origin, "Triggered by touch", (0,0,1), 1, 2, 100 );
		}#/
	    wait 1;
	}
}

birds_perchEventTrigger( radius, notifyStr, ender )
{
	self.lastAIEventTrigger = GetTime() - 500;
	if ( isSP() ) {
		self endon( "death" );
		self endon( ender );
		
		self.sentient = Spawn( "script_origin", self.origin );
		self.sentient call [[ level.makeEntitySentient_func ]]( "neutral" );
		self thread wait_then_fn( ender, "death", ::birds_deletePerchSentient );
		self.sentient call [[ level.addAIEventListener_func ]]( "projectile_impact" );
		self.sentient call [[ level.addAIEventListener_func ]]( "bulletwhizby"		 );
	//	self.sentient call [[ level.addAIEventListener_func ]]( "gunshot"			 );	// Prevents impacts and whizzys from being detected.
		self.sentient call [[ level.addAIEventListener_func ]]( "explode"			 );

		while( 1 )
		{
			self.sentient waittill( "ai_event", eventType, originator, position );
			if ( ( eventType != "explode" && eventType != "gunshot" ) || DistanceSquared( self.origin, position ) < 2 * radius ) {
			    self notify( notifyStr );
				self.lastAIEventTrigger = GetTime();
				/#if ( GetDvarInt( "interactives_debug" ) ) {
					Print3d( self.origin, "Triggered by event", (0,0,1), 1, 2, 100 );
				}#/
			}
		}
	}
}

birds_deletePerchSentient()
{
	//self FreeEntitySentient();// This gives my 360 the Purple Bars of Death.  TODO Repro and bug it.
	self.sentient Delete();
}

birds_isPerchSafe ( perch )
{
	AssertEx( IsDefined( perch.trigger ), "birds_isPerchSafe() called on perch with no trigger.");
	safeFromDmg = 1;
	safeFromTouch = !perch.trigger.anythingTouchingTrigger;
	if ( safeFromTouch ) {
   		foreach ( trigger in perch.triggers ) {
   			if ( trigger.anythingTouchingTrigger )
   			{
   				safeFromTouch = false;
   				continue;
   			}
   		}
		// First, check for the bad state caused by GetTime being reset on player death.
		// NB: In MP, lastAIEventTrigger is only trigger by birds being shot.
		if ( perch.lastAIEventTrigger > GetTime() ) 
			perch.lastAIEventTrigger = GetTime() - 500;
		// OK, now compare the times.
		if ( GetTime() - perch.lastAIEventTrigger < 500 ) 
			safeFromDmg = 0;
	}
	return ( safeFromTouch && safeFromDmg );
}

birds_path_move_first_point(path, newStartPos, newStartVel)
{
	newPath = cspline_moveFirstPoint( path, newStartPos, newStartVel );	
	newPath.startOrigin = newStartPos;
	
	if ( IsDefined( path.startAngles )	)newPath.startAngles = path.startAngles;
	if ( IsDefined( path.endOrigin )	)newPath.endOrigin	 = path.endOrigin;
	if ( IsDefined( path.endAngles )	)newPath.endAngles	 = path.endAngles;
	if ( IsDefined( path.endPerch )		)newPath.endPerch	 = path.endPerch;
	if ( IsDefined( path.takeoffAnim )	)newPath.takeoffAnim = path.takeoffAnim;
	if ( IsDefined( path.landAnim )		)newPath.landAnim	 = path.landAnim;
	
	return newPath;
}

/*
=============
///ScriptDocBegin
"Name: birds_SpawnAndFlyAway( <birdType> , <startPos> , <flyVec> , <count> )"
"Summary: spawn birds from script rather than Radiant"
"Module: _birds"
"CallOn: nothing"
"MandatoryArg: <birdType>: eg pigeons, parakeets, egrets."
"MandatoryArg: <startPos>: Location where birds will spawn."
"MandatoryArg: <flyVec>: Vector birds will fly along before they are deleted."
"OptionalArg: <count>: Number of birds in flock.  Default and current max is 12."
"Example: maps\interactive_models\_birds::birds_SpawnAndFlyAway( "parakeets", enemyPos, (500,0,500), RandomIntRange(5,10) );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

birds_SpawnAndFlyAway( birdType, startPos, flyVec, count )
{
	// You need to run the main function in the appropriate interactive_models\*.gsc in your level script before you can call this function
	Assert( IsDefined( level._interactive ) && IsDefined( level._interactive[ birdType ] ) );

	if ( !IsDefined( level._interactive[ "scriptSpawnedCount" ] ) ) {
	    level._interactive[ "scriptSpawnedCount" ] = 0;
	}
	level._interactive[ "scriptSpawnedCount" ]++;
	
	perch = Spawn( "script_model", startPos );
	perch.angles = VectorToAngles( flyVec );
	perch.targetname = "scriptSpawned_" + level._interactive[ "scriptSpawnedCount" ];	// Unique name
	perch.script_noteworthy = "bird_perch";
	path = [];
	path[0] = perch;
	path[1] = SpawnStruct();
	path[1].origin = startPos + flyVec;
	path[1].angles = perch.angles;
	perch = birds_setUpConnectedPerches( perch, path );
	
	flockStruct = SpawnStruct();
	flockStruct.interactive_type = birdType;
	flockStruct.target = perch.targetname;
	flockStruct.origin = startPos;
	flockStruct.interactive_number = count;	// Optional
	flockStruct birds_loadFromStruct();
	
	perch notify( "triggered" );
	
	// Delete the perch to free up its variables.  I think this will do it.
	waitframe();
	level._interactive[ "bird_perches" ][ perch.targetname ] = undefined;
}



birds_waitForTriggerStop()
{
	self endon( "death" );	// NB self endon( "delete" ) doesn't seem to work.
	level waittill( "stop_" + self.script_triggername ); // TODO Could also detect "delete_" to save script vars.
	self thread birds_saveToStructAndWaitForTriggerStart();	// Spawn a new thread to escape from the endon("death")
}
birds_saveToStructAndWaitForTriggerStart()
{
	selfStruct = self birds_saveToStruct();
	level waittill( "start_" + self.script_triggername );
	selfStruct birds_loadFromStruct();
}


/*
=============
///ScriptDocBegin
"Name: birds_saveToStruct()"
"Summary: Saves the entity information into a struct, so that entities are freed up for other uses.  My intention is that this will be called through [[level._interactive[...].saveToStructFn]]"
"Module: Birds"
"CallOn: A bird flock entity"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

birds_saveToStruct()
{
	AssertEx( IsDefined( self.interactive_type ), "Interactive_birds entity does not have an interactive_type keypair." );
	AssertEx( IsDefined( level._interactive ), "Interactive_birds entity in map, but level._interactive is not defined." );
	AssertEx( IsDefined( level._interactive[ self.interactive_type ] ), ( "Interactive_birds entity in map, but level._interactive[" + self.interactive_type + "] is not defined." ) );
	AssertEx( IsDefined( self.target )			  , "Interactive_birds object at " + self.origin + " does not have a target." );

	struct = spawnStruct();
	struct.interactive_type = self.interactive_type;
	struct.target = self.target;
	struct.origin = self.origin;
	struct.targetname = self.targetname;
	if ( IsDefined( self.interactive_number ) )
		struct.interactive_number = self.interactive_number;
	struct.script_triggername = self.script_triggername;
	self birds_delete();
	return struct;
}

/*
=============
///ScriptDocBegin
"Name: birds_loadFromStruct()"
"Summary: Loads the entity information from a struct and recreates the bird flock.  My intention is that this will be called through [[level._interactive[...].loadFromStructFn]]"
"Module: Birds"
"CallOn: A struct that was created using birds_saveToStruct()"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

birds_loadFromStruct()
{
	ent = Spawn( "script_model", self.origin );
	ent.interactive_type = self.interactive_type;
	ent.target = self.target;
	ent.origin = self.origin;
	if ( IsDefined( self.interactive_number ) )
		ent.interactive_number = self.interactive_number;
	ent.script_triggername = self.script_triggername;
	ent.targetname = "interactive_birds";
	if ( !IsDefined( level._interactive[ "bird_perches" ][ self.target ] ) ) {
		ent birds_setUpConnectedPerches();
	}
	ent birds_createEnts();
	ent thread birds_fly( ent.target );
}

/*
=============
///ScriptDocBegin
"Name: birds_delete()"
"Summary: Deletes a bird flock entity and all its birds."
"Module: Birds"
"CallOn: A bird flock entity"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

birds_delete()
{
	if ( IsDefined( self.birds ) ) {
		for ( i = 1; i <= self.birds.size; i++ ) {
			if ( self.birdexists[ i ] ) {
				self.birds[ i ] Delete();
			}
		}
	}
	if ( IsDefined( self.perch ) ) {
		self.perch notify( "leaving perch" );
	}
	self Delete();
}

/*
=============
///ScriptDocBegin
"Name: angleSoftClamp(<a>, <softLimit>, <scaler>, <hardLimit>)"
"Summary: Clamp an angle between -hardLimit and hardLimit. If abs(a) is above softLimit, amount above will be scaled by scaler."
"Module: _interactive_utility"
"CallOn: nothing"
"MandatoryArg: <a>: angle."
"MandatoryArg: <softLimit>: If abs(a) is < softLimit, return a unchanged."
"MandatoryArg: <scaler>: Amount above softLimit will be scaled by scaler. Scaler should be between 0 and 1."
"MandatoryArg: <hardLimit>: Return value will be clamped between -hardLimit and hardLimit."
"Example: yaw = angleSoftClamp(angles[1], 3, 0.2, 6);"
"SPMP: both"
///ScriptDocEnd
=============
*/
angleSoftClamp(a, softLimit, scaler, hardLimit)
{
	assert(softLimit >= 0);
	
	a = AngleClamp180(a);
	absa = abs(a);
	if ( absa <= softLimit ) {
		return a;
	} else {
		signa = a / absa;
		absa = ( ( absa - softLimit ) * scaler ) + softLimit;
		absa = clamp( absa, 0, hardLimit );
		return absa * signa;
	}
}

/*
=============
///ScriptDocBegin
"Name: angleSoftClamp(<a>, <softLimit>, <scaler>, <hardLimit>)"
"Summary: Clamp a set of angles. See angleSoftClamp for more information."
"Module: _interactive_utility"
"CallOn: nothing"
"Example: angles = anglesSoftClamp(angles, 3, 0.2, 6);"
"SPMP: both"
///ScriptDocEnd
=============
*/
anglesSoftClamp(a, softLimit, scaler, hardLimit)
{
	return ( angleSoftClamp( a[0], softLimit, scaler, hardLimit ), 
		     angleSoftClamp( a[1], softLimit, scaler, hardLimit ), 
		     angleSoftClamp( a[2], softLimit, scaler, hardLimit ) );
}