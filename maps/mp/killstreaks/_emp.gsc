#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_emp_common;

init()
{
	// 2013-06-30 wallace: make sure emp code doesn't run. jammer reuses some of the sstuff, and we don't want the two stomping on each other
	/*
	level._effect[ "emp_flash" ] = loadfx( "fx/explosions/emp_flash_mp" );

	if( level.multiTeamBased )
	{
		for( i = 0; i < level.teamNameList.size; i++ )
		{
			level.teamEMPed[level.teamNameList[i]] = false;
		}
	}
	else
	{
		level.teamEMPed["allies"] = false;
		level.teamEMPed["axis"] = false;
	}

	level.empPlayer = undefined;
	level.empTimeout = 15.0;
	level.empTimeRemaining = int( level.empTimeout );

	if ( level.teamBased )
		level thread EMP_TeamTracker();
	else
		level thread EMP_PlayerTracker();
	
	level.killstreakFuncs["emp"] = ::EMP_Use;
	
	level thread onPlayerConnect();
	*/
/#
	SetDevDvarIfUninitialized( "scr_emp_timeout", 15.0 );
	SetDevDvarIfUninitialized( "scr_emp_damage_debug", 0 );
#/
}



onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}


onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "spawned_player" );
		
		if ( (level.teamBased && level.teamEMPed[self.team]) || (!level.teamBased && isDefined( level.empPlayer ) && level.empPlayer != self) )
			self setEMPJammed( true );
	}
}


EMP_Use( lifeId, streakName )
{
	assert( isDefined( self ) );

	myTeam = self.pers["team"];
	if( level.multiTeamBased )
	{
		self thread EMP_JamTeams( myTeam );
	}
	else if ( level.teamBased )
	{
		otherTeam = level.otherTeam[myTeam];
		self thread EMP_JamTeam( otherTeam );
	}
	else
		self thread EMP_JamPlayers( self );

	self maps\mp\_matchdata::logKillstreakEvent( "emp", self.origin );
	self notify( "used_emp" );

	return true;
}

EMP_JamTeams( ownerTeam )
{
	level endon ( "game_ended" );
	
	assert( ownerTeam == "allies" || ownerTeam == "axis" || IsSubStr( ownerTeam, "team_" ));

	thread teamPlayerCardSplash( "used_emp", self );

	level notify ( "EMP_JamTeam" + ownerTeam );
	level endon ( "EMP_JamTeam" + ownerTeam );
	
	//turn off jammer abilities on emp'd players
	foreach ( player in level.players )
	{
		player playLocalSound( "emp_activate" );
		
		if ( player.team == ownerTeam )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player ClearScrambler();
	}
	
	VisionSetNaked( "coup_sunblind", 0.1 ); 
	thread empEffects();
	
	wait ( 0.1 );
	
	// resetting the vision set to the same thing won't normally have an effect.
	// however, if the client receives the previous visionset change in the same packet as this one,
	// this will force them to lerp from the bright one to the normal one.
	VisionSetNaked( "coup_sunblind", 0 );
	VisionSetNaked( "", 3.0 ); // go to default visionset
	
	for( i = 0; i < level.teamNameList.size; i++ )
	{
		if( ownerTeam != level.teamNameList[i] )
		{
			level.teamEMPed[level.teamNameList[i]] = true;
		}
	}

	level notify ( "emp_update" );
	
	for( i = 0; i < level.teamNameList.size; i++ )
	{
		if( ownerTeam != level.teamNameList[i] )
		{
			level destroyActiveVehicles( self, level.teamNameList[i] );
		}
	}
	
/#
	level.empTimeout = GetDvarFloat( "scr_emp_timeout" );
#/
	level thread keepEMPTimeRemaining();
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( level.empTimeout );
	
	for( i = 0; i < level.teamNameList.size; i++ )
	{
		if( ownerTeam != level.teamNameList[i] )
		{
			level.teamEMPed[level.teamNameList[i]] = false;
		}
	}
	
	//turn jammer abilities back on
	foreach ( player in level.players )
	{
		if ( player.team == ownerTeam )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player MakeScrambler();
	}
	
	level notify ( "emp_update" );
}

//jams all players on the team passed in the argument teamName
EMP_JamTeam( teamName )
{
	level endon ( "game_ended" );
	
	assert( teamName == "allies" || teamName == "axis" );

	thread teamPlayerCardSplash( "used_emp", self );

	level notify ( "EMP_JamTeam" + teamName );
	level endon ( "EMP_JamTeam" + teamName );
	
	foreach ( player in level.players )
	{
		player playLocalSound( "emp_activate" );
		
		if ( player.team != teamName )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player ClearScrambler();

		player VisionSetNakedForPlayer( "coup_sunblind", 0.1 );
	}
	
	thread empEffects();
	
	wait ( 0.1 );
	
	// resetting the vision set to the same thing won't normally have an effect.
	// however, if the client receives the previous visionset change in the same packet as this one,
	// this will force them to lerp from the bright one to the normal one.
	VisionSetNaked( "coup_sunblind", 0 );
	VisionSetNaked( "", 3.0 ); // go to default visionset
	
	level.teamEMPed[teamName] = true;
	level notify ( "emp_update" );
	
	level destroyActiveVehicles( self, teamName );
	
/#
	level.empTimeout = GetDvarFloat( "scr_emp_timeout" );
#/
	level thread keepEMPTimeRemaining();
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( level.empTimeout );
	
	level.teamEMPed[teamName] = false;
	
	foreach ( player in level.players )
	{
		if ( player.team != teamName )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player MakeScrambler();
	}
	
	level notify ( "emp_update" );
}


EMP_JamPlayers( owner )
{
	level notify ( "EMP_JamPlayers" );
	level endon ( "EMP_JamPlayers" );
	
	assert( isDefined( owner ) );
		
	foreach ( player in level.players )
	{
		player playLocalSound( "emp_activate" );
		
		if ( player == owner )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player ClearScrambler();
	}
	
	VisionSetNaked( "coup_sunblind", 0.1 );
	thread empEffects();

	wait ( 0.1 );
	
	// resetting the vision set to the same thing won't normally have an effect.
	// however, if the client receives the previous visionset change in the same packet as this one,
	// this will force them to lerp from the bright one to the normal one.
	VisionSetNaked( "coup_sunblind", 0 );
	VisionSetNaked( "", 3.0 ); // go to default visionset
	
	level notify ( "emp_update" );
	
	level.empPlayer = owner;
	level.empPlayer thread empPlayerFFADisconnect();
	level destroyActiveVehicles( owner );
	
	level notify ( "emp_update" );
	
/#
	level.empTimeout = GetDvarFloat( "scr_emp_timeout" );
#/
	level thread keepEMPTimeRemaining();
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( level.empTimeout );
	
	foreach ( player in level.players )
	{
		if ( player == owner )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player MakeScrambler();
	}
	
	level.empPlayer = undefined;
	level notify ( "emp_update" );
	level notify ( "emp_ended" );
}

keepEMPTimeRemaining()
{
	level notify( "keepEMPTimeRemaining" );
	level endon( "keepEMPTimeRemaining" );

	level endon( "emp_ended" );

	// we need to know how much time is left for the unavailable string
	level.empTimeRemaining = int( level.empTimeout );
	while( level.empTimeRemaining )
	{
		wait( 1.0 );
		level.empTimeRemaining--;
	}
}

empPlayerFFADisconnect()
{
	level endon ( "EMP_JamPlayers" );	
	level endon ( "emp_ended" );
	
	self waittill( "disconnect" );
	level notify ( "emp_update" );
}

empEffects()
{
	foreach( player in level.players )
	{
		playerForward = anglestoforward( player.angles );
		playerForward = ( playerForward[0], playerForward[1], 0 );
		playerForward = VectorNormalize( playerForward );
	
		empDistance = 20000;

		empEnt = Spawn( "script_model", player.origin + ( 0, 0, 8000 ) + ( playerForward * empDistance ) );
		empEnt setModel( "tag_origin" );
		empEnt.angles = empEnt.angles + ( 270, 0, 0 );
		empEnt thread empEffect( player );
	}
}

empEffect( player )
{
	player endon( "disconnect" );

	wait( 0.5 );
	PlayFXOnTagForClients( level._effect[ "emp_flash" ], self, "tag_origin", player );
}

EMP_TeamTracker()
{
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		level waittill_either ( "joined_team", "emp_update" );
		
		foreach ( player in level.players )
		{
			if ( player.team == "spectator" )
				continue;
				
			// if this emp is over, let's do an extra check to make sure we shouldn't be nuke emped, isEmped() does the extra nuke emp check
			if( !level.teamEMPed[ player.team ] && !player isEMPed() )
				player enableJammedEffect( false );
			else
				player enableJammedEffect( true );
		}
	}
}


EMP_PlayerTracker()
{
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		level waittill_either ( "joined_team", "emp_update" );
		
		foreach ( player in level.players )
		{
			if ( player.team == "spectator" )
				continue;
				
			if ( isDefined( level.empPlayer ) && level.empPlayer != player )
			{
				player enableJammedEffect( true );
			}
			else
			{
				// if this emp is over, let's do an extra check to make sure we shouldn't be nuke emped, isEmped() does the extra nuke emp check
				if( !player isEMPed() )
					player enableJammedEffect( false );				
			}
		}
	}
}

destroyActiveVehicles( attacker, teamEMPed )
{
	// thread all of the things that need to get destroyed, this way we can put frame waits in between each destruction so we don't hit the server with a lot at one time
	thread destroyActiveHelis( attacker, teamEMPed );
	thread destroyActiveLittleBirds( attacker, teamEMPed );
	thread destroyActiveTurrets( attacker, teamEMPed );
	thread destroyActiveRockets( attacker, teamEMPed );
	thread destroyActiveUAVs( attacker, teamEMPed );
	thread destroyActiveIMSs( attacker, teamEMPed );
	thread destroyActiveUGVs( attacker, teamEMPed );
	thread destroyActiveAC130( attacker, teamEMPed );
	thread destroyActiveBallDrones( attacker, teamEMPed );
	thread destroyTargets( attacker, teamEMPed, level.remote_uav );
	thread destroyTargets( attacker, teamEMPed, level.uplinks );
}

destroyTargets( attacker, teamEMPed, targetList )
{
	meansOfDeath = "MOD_EXPLOSIVE";
	weapon = "killstreak_emp_mp";

	damage = 5000;
	direction_vec = ( 0, 0, 0 );
	point = ( 0, 0, 0 );
	modelName = "";
	tagName = "";
	partName = "";
	iDFlags = undefined;

	foreach ( target in targetList )
	{
		if ( level.teamBased && IsDefined( teamEMPed ) )
		{
			if( IsDefined( target.team ) && target.team != teamEMPed )
				continue;
		}
		else
		{
			if( IsDefined( target.owner ) && target.owner == attacker )
				continue;
		}

		target notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		wait( 0.05 );
	}
}

destroyActiveHelis( attacker, teamEMPed )
{
	destroyTargets( attacker, teamEMPed, level.helis );
}

destroyActiveLittleBirds( attacker, teamEMPed )
{
	destroyTargets( attacker, teamEMPed, level.littleBirds );
}

destroyActiveTurrets( attacker, teamEMPed )
{
	destroyTargets( attacker, teamEMPed, level.turrets );
}

destroyActiveRockets( attacker, teamEMPed )
{
	meansOfDeath = "MOD_EXPLOSIVE";
	weapon = "killstreak_emp_mp";

	damage = 5000;
	direction_vec = ( 0, 0, 0 );
	point = ( 0, 0, 0 );
	modelName = "";
	tagName = "";
	partName = "";
	iDFlags = undefined;

	foreach ( rocket in level.rockets )
	{
		if ( level.teamBased && IsDefined( teamEMPed ) )
		{
			if( IsDefined( rocket.team ) && rocket.team != teamEMPed )
				continue;
		}
		else
		{
			if( IsDefined( rocket.owner ) && rocket.owner == attacker )
				continue;
		}

		// this is different from destroy target
		PlayFX( level.remotemissile_fx[ "explode" ], rocket.origin );
		rocket delete();
		wait( 0.05 );
	}
}

destroyActiveUAVs( attacker, teamEMPed )
{
	uavArray = level.uavModels;
	if ( level.teamBased && IsDefined( teamEMPed ) )
		uavArray = level.uavModels[ teamEMPed ];
	
	destroyTargets( attacker, teamEMPed, uavArray );
}

destroyActiveIMSs( attacker, teamEMPed )
{
	destroyTargets( attacker, teamEMPed, level.ims );
}

destroyActiveUGVs( attacker, teamEMPed )
{
	destroyTargets( attacker, teamEMPed, level.ugvs );
}

destroyActiveAC130( attacker, teamEMPed )
{
	meansOfDeath = "MOD_EXPLOSIVE";
	weapon = "killstreak_emp_mp";

	damage = 5000;
	direction_vec = ( 0, 0, 0 );
	point = ( 0, 0, 0 );
	modelName = "";
	tagName = "";
	partName = "";
	iDFlags = undefined;

	if ( level.teamBased && IsDefined( teamEMPed ) )
	{
		if ( IsDefined( level.ac130player ) && IsDefined( level.ac130player.team ) && level.ac130player.team == teamEMPed )
			level.ac130.planeModel notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
	}
	else
	{
		if ( IsDefined( level.ac130player ) )
		{
			if( !IsDefined( level.ac130.owner ) || ( IsDefined( level.ac130.owner ) && level.ac130.owner != attacker ) )
				level.ac130.planeModel notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		}
	}
}

destroyActiveBallDrones( attacker, teamEMPed )
{
	destroyTargets( attacker, teamEMPed, level.ballDrones );
}

enableJammedEffect( flag )
{
	self setEMPJammed( flag );
	shakeValue = 0;
	if ( flag )
	{
		shakeValue = 1;
	}
	
	self thread startEmpJamSequence();
}

/#
drawEMPDamageOrigin( pos, ang, radius )
{
	while( GetDvarInt( "scr_emp_damage_debug" ) )
	{
		Line( pos, pos + ( AnglesToForward( ang ) * radius ), ( 1, 0, 0 ) );
		Line( pos, pos + ( AnglesToRight( ang ) * radius ), ( 0, 1, 0 ) );
		Line( pos, pos + ( AnglesToUp( ang ) * radius ), ( 0, 0, 1 ) );

		Line( pos, pos - ( AnglesToForward( ang ) * radius ), ( 1, 0, 0 ) );
		Line( pos, pos - ( AnglesToRight( ang ) * radius ), ( 0, 1, 0 ) );
		Line( pos, pos - ( AnglesToUp( ang ) * radius ), ( 0, 0, 1 ) );

		wait( 0.05 );
	}
}
#/