#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_hostmigration;

init()
{
	level.radarViewTime = 23;	// time radar remains active
	level.uavBlockTime = 23;	// this only seems to be used for the FFA version.

//	level.killStreakFuncs[ "uav" ] =				::tryUseUAV;
//	level.killStreakFuncs[ "uav_support" ] =		::tryUseUAV;
//	level.killStreakFuncs[ "counter_uav" ] =		::tryUseUAV;
//	level.killstreakFuncs[ "directional_uav" ] =	::tryUseUAV;
	level.killstreakFuncs[ "uav_3dping" ] =			::tryUse3DPing;

	level.uavSettings = [];

//	level.uavSettings[ "uav" ] = SpawnStruct();
//	level.uavSettings[ "uav" ].timeOut =						level.radarViewTime;	
//	level.uavSettings[ "uav" ].health =							999999; // keep it from dying anywhere in code	
//	level.uavSettings[ "uav" ].maxHealth =						1000; // this is what we check against for death	
//	level.uavSettings[ "uav" ].streakName =						"uav";
//	level.uavSettings[ "uav" ].modelBase =						"vehicle_uav_static_mp";
//	level.uavSettings[ "uav" ].fxId_explode =					LoadFX( "fx/explosions/uav_advanced_death" );	
//	level.uavSettings[ "uav" ].fxId_leave =						LoadFX( "fx/fire/jet_engine_ac130" );
//	level.uavSettings[ "uav" ].fx_leave_tag =					"tag_origin";
//	level.uavSettings[ "uav" ].fxId_contrail =					undefined;
//	level.uavSettings[ "uav" ].fx_contrail_tag =				undefined;
//	level.uavSettings[ "uav" ].sound_explode =					"ball_drone_explode"; // TODO: get sound
//	level.uavSettings[ "uav" ].teamSplash =						undefined;	
//	level.uavSettings[ "uav" ].calloutDestroyed =				"callout_destroyed_uav";	
//	level.uavSettings[ "uav" ].addFunc =						::addActiveUAV;	
//	level.uavSettings[ "uav" ].removeFunc =						::removeActiveUAV;	
//
//	level.uavSettings[ "uav_support" ] = SpawnStruct();
//	level.uavSettings[ "uav_support" ].timeOut =				level.radarViewTime;	
//	level.uavSettings[ "uav_support" ].health =					999999; // keep it from dying anywhere in code	
//	level.uavSettings[ "uav_support" ].maxHealth =				1000; // this is what we check against for death	
//	level.uavSettings[ "uav_support" ].streakName =				"uav_support";
//	level.uavSettings[ "uav_support" ].modelBase =				"vehicle_uav_static_mp";
//	level.uavSettings[ "uav_support" ].fxId_explode =			LoadFX( "fx/explosions/uav_advanced_death" );	
//	level.uavSettings[ "uav_support" ].fxId_leave =				LoadFX( "fx/fire/jet_engine_ac130" );
//	level.uavSettings[ "uav_support" ].fx_leave_tag =			"tag_origin";
//	level.uavSettings[ "uav_support" ].fxId_contrail =			undefined;
//	level.uavSettings[ "uav_support" ].fx_contrail_tag =		undefined;
//	level.uavSettings[ "uav_support" ].sound_explode =			"ball_drone_explode"; // TODO: get sound
//	level.uavSettings[ "uav_support" ].teamSplash =				undefined;	
//	level.uavSettings[ "uav_support" ].calloutDestroyed =		"callout_destroyed_uav";	
//	level.uavSettings[ "uav_support" ].addFunc =				::addActiveUAV;	
//	level.uavSettings[ "uav_support" ].removeFunc =				::removeActiveUAV;	
//
//	level.uavSettings[ "counter_uav" ] = SpawnStruct();
//	level.uavSettings[ "counter_uav" ].timeOut =				level.uavBlockTime;	
//	level.uavSettings[ "counter_uav" ].health =					999999; // keep it from dying anywhere in code	
//	level.uavSettings[ "counter_uav" ].maxHealth =				1000; // this is what we check against for death	
//	level.uavSettings[ "counter_uav" ].streakName =				"counter_uav";
//	level.uavSettings[ "counter_uav" ].modelBase =				"vehicle_uav_static_mp";
//	level.uavSettings[ "counter_uav" ].fxId_explode =			LoadFX( "fx/explosions/uav_advanced_death" );	
//	level.uavSettings[ "counter_uav" ].fxId_leave =				LoadFX( "fx/fire/jet_engine_ac130" );
//	level.uavSettings[ "counter_uav" ].fx_leave_tag =			"tag_origin";
//	level.uavSettings[ "counter_uav" ].fxId_contrail =			undefined;
//	level.uavSettings[ "counter_uav" ].fx_contrail_tag =		undefined;
//	level.uavSettings[ "counter_uav" ].sound_explode =			"ball_drone_explode"; // TODO: get sound
//	level.uavSettings[ "counter_uav" ].teamSplash =				undefined;	
//	level.uavSettings[ "counter_uav" ].calloutDestroyed =		"callout_destroyed_counter_uav";	
//	level.uavSettings[ "counter_uav" ].addFunc =				::addActiveCounterUAV;	
//	level.uavSettings[ "counter_uav" ].removeFunc =				::removeActiveCounterUAV;	
//
//	level.uavSettings[ "directional_uav" ] = SpawnStruct();
//	level.uavSettings[ "directional_uav" ].timeOut =			level.radarViewTime;	
//	level.uavSettings[ "directional_uav" ].health =				999999; // keep it from dying anywhere in code	
//	level.uavSettings[ "directional_uav" ].maxHealth =			2000; // this is what we check against for death	
//	level.uavSettings[ "directional_uav" ].streakName =			"directional_uav";
//	level.uavSettings[ "directional_uav" ].modelBase =			"vehicle_phantom_ray";
//	level.uavSettings[ "directional_uav" ].fxId_explode =		LoadFX( "fx/explosions/uav_advanced_death" );	
//	level.uavSettings[ "directional_uav" ].fxId_leave =			LoadFX( "fx/fire/jet_engine_ac130" );
//	level.uavSettings[ "directional_uav" ].fx_leave_tag =		"tag_origin";
//	level.uavSettings[ "directional_uav" ].fxId_contrail =		LoadFX( "fx/smoke/advanced_uav_contrail" );
//	level.uavSettings[ "directional_uav" ].fx_contrail_tag =	"tag_jet_trail";
//	level.uavSettings[ "directional_uav" ].sound_explode =		"ball_drone_explode"; // TODO: get sound
//	level.uavSettings[ "directional_uav" ].teamSplash =			"used_directional_uav";	
//	level.uavSettings[ "directional_uav" ].calloutDestroyed =	"callout_destroyed_uav";	
//	level.uavSettings[ "directional_uav" ].addFunc =			::addActiveUAV;	
//	level.uavSettings[ "directional_uav" ].removeFunc =			::removeActiveUAV;	

	level.uavSettings[ "uav_3dping" ] = SpawnStruct();
	level.uavSettings[ "uav_3dping" ].timeOut =					63;	
	level.uavSettings[ "uav_3dping" ].streakName =				"uav_3dping";
	level.uavSettings[ "uav_3dping" ].highlightFadeTime =		1.5; // time it takes to fade out the hightlight
	level.uavSettings[ "uav_3dping" ].pingTime =				10.0; // time between pings	
	level.uavSettings[ "uav_3dping" ].fxId_ping =				LoadFX( "vfx/gameplay/mp/killstreaks/vfx_3d_world_ping" );
	level.uavSettings[ "uav_3dping" ].sound_ping_plr =			"oracle_radar_pulse_plr";
	level.uavSettings[ "uav_3dping" ].sound_ping_npc =			"oracle_radar_pulse_npc";
	level.uavSettings[ "uav_3dping" ].voTimeOut =				"oracle_gone";
	level.uavSettings[ "uav_3dping" ].teamSplash =				"used_uav_3dping";	

	minimapOrigins = GetEntArray( "minimap_corner", "targetname" );
	if ( miniMapOrigins.size )
		uavOrigin = maps\mp\gametypes\_spawnlogic::findBoxCenter( miniMapOrigins[0].origin, miniMapOrigins[1].origin );
	else
		uavOrigin = (0,0,0);
	
	level.UAVRig = Spawn( "script_model", uavOrigin );
	//level.UAVRig SetModel( "c130_zoomrig" );
	level.UAVRig.angles = (0,115,0);
	level.UAVRig Hide();

	// used for debug printing
	level.UAVRig.targetname = "uavrig_script_model";

	level.UAVRig thread rotateUAVRig();
	
	if ( level.multiTeamBased )
	{
		for( i = 0; i < level.teamNameList.size; i++ )
		{
			level.radarMode[level.teamNameList[i]] = "normal_radar";
			level.activeUAVs[level.teamNameList[i]] = 0;
			level.activeCounterUAVs[level.teamNameList[i]] = 0;
			level.uavModels[level.teamNameList[i]] = [];
		}
	}
	else if ( level.teamBased )
	{
		level.radarMode["allies"] = "normal_radar";
		level.radarMode["axis"] = "normal_radar";
		level.activeUAVs["allies"] = 0;
		level.activeUAVs["axis"] = 0;
		level.activeCounterUAVs["allies"] = 0;
		level.activeCounterUAVs["axis"] = 0;
		level.uavModels["allies"] = [];
		level.uavModels["axis"] = [];
	}
	else
	{	
		level.radarMode = [];
		level.activeUAVs = [];
		level.activeCounterUAVs = [];
		level.uavModels = [];
		
		level thread onPlayerConnect();		
	}

	level thread UAVTracker();

/#
	SetDevDvarIfUninitialized( "scr_uav_timeout", level.radarViewTime  );
	SetDevDvarIfUninitialized( "scr_uav_3dping_timeout", level.uavSettings[ "uav_3dping" ].timeOut );
	SetDevDvarIfUninitialized( "scr_uav_3dping_pingTime", level.uavSettings[ "uav_3dping" ].pingTime );
	SetDevDvarIfUninitialized( "scr_uav_3dping_highlightFadeTime", level.uavSettings[ "uav_3dping" ].highlightFadeTime );
#/
}

onPlayerConnect()
{
	while( true )
	{
		level waittill( "connected", player );
		
		level.activeUAVs[ player.guid ] = 0;
		level.activeUAVs[ player.guid + "_radarStrength" ] = 0;
		level.activeCounterUAVs[ player.guid ] = 0;
		
		level.radarMode[ player.guid ] = "normal_radar";
	}
}

rotateUAVRig( rotateTime, endonMsg )
{
	if( IsDefined( endonMsg ) )
		self endon( endonMsg );

	if( !IsDefined( rotateTime ) )
		rotateTime = 60;

	while( true )
	{
		self RotateYaw( -360, rotateTime );
		wait ( rotateTime );
	}
}

tryUseUAV( lifeId, streakName )
{
	return useUAV( streakName );
}

tryUse3DPing( lifeId, streakName ) // self == player
{
	uavType = "uav_3dping";

	self thread watch3DPing( uavType );
	self thread watch3DPingTimeout( uavType );
	level thread teamPlayerCardSplash( level.uavSettings[ uavType ].teamSplash, self );
	
	return true;
}

useUAV( uavType ) // self == player
{
	self maps\mp\_matchdata::logKillstreakEvent( uavType, self.origin );

	team = self.pers[ "team" ];		
	useTime = level.uavSettings[ uavType ].timeOut;

/#
	useTime = GetDvarInt( "scr_uav_timeout", level.uavSettings[ uavType ].timeOut );
#/

	level thread launchUAV( self, useTime, uavType );	

	switch( uavType )
	{
	case "counter_uav":
		self notify( "used_counter_uav" );
		break;
	
	case "directional_uav":
		self.radarShowEnemyDirection = true;
		if( level.teambased )
		{
			foreach( player in level.players )
			{
				if( player.pers["team"] == team )
				{
					player.radarShowEnemyDirection = true;					
				}
			}
		}
		level thread teamPlayerCardSplash( level.uavSettings[ uavType ].teamSplash, self, team );
		self notify( "used_directional_uav" );
		break;
	
	default:
		self notify( "used_uav" );
		break;
	}

	return true;
}

launchUAV( owner, duration, uavType ) // self == level
{
	team = owner.team;

	UAVModel = Spawn( "script_model", level.UAVRig GetTagOrigin( "tag_origin" ) );
	
/#
	if( GetDvarInt( "scr_debuguav" ) )
	{
		UAVModel thread debugLocation();
		UAVModel thread debugTrace();
	}
#/

	UAVModel SetModel( level.uavSettings[ uavType ].modelBase );

	UAVModel.team = team;
	UAVModel.owner = owner;
	UAVModel.timeToAdd = 0;
	UAVModel.uavType = uavType;
	UAVModel.health = level.uavSettings[ uavType ].health;
	UAVModel.maxHealth = level.uavSettings[ uavType ].maxHealth;

	if( uavType == "directional_uav" )
		UAVModel thread spawnFxDelay( level.uavSettings[ uavType ].fxId_contrail, level.uavSettings[ uavType ].fx_contrail_tag );
	
	UAVModel addUAVModel();

	UAVModel thread damageTracker();
	UAVModel thread handleIncomingStinger();
	UAVModel thread removeUAVModelOnDeath();

	zOffset = RandomIntRange( 3000, 5000 );

	// we need to make sure the uav doesn't go higher than 8100 units because bullets die at 8192
	if( IsDefined( level.spawnpoints ) )
		spawns = level.spawnPoints;
	else
		spawns = level.startSpawnPoints;

	lowestSpawn = spawns[0];
	foreach( spawn in spawns )
	{
		if ( spawn.origin[2] < lowestSpawn.origin[2] )
			lowestSpawn = spawn; 
	}
	lowestZ = lowestSpawn.origin[2];
	UAVRigZ = level.UAVRig.origin[2];
	if( lowestZ < 0 )
	{
		UAVRigZ += lowestZ * -1;
		lowestZ = 0;
	}
	diffZ = UAVRigZ - lowestZ;
	AssertEx( diffZ < 8100.0, "The lowest spawn and the UAV node are more than 8100 z units apart, please notify MP Design." );
	if( diffZ + zOffset > 8100.0 )
	{
		zOffset -= ( ( diffZ + zOffset ) - 8100.0 );
	}

	angle = RandomInt( 360 );
	radiusOffset = RandomInt( 2000 ) + 5000;

	xOffset = cos( angle ) * radiusOffset;
	yOffset = sin( angle ) * radiusOffset;

	angleVector = VectorNormalize( (xOffset,yOffset,zOffset) );
	angleVector = ( angleVector * RandomIntRange( 6000, 7000 ) );
	
	UAVModel LinkTo( level.UAVRig, "tag_origin", angleVector, (0,angle - 90,0) );

	UAVModel thread updateUAVModelVisibility();	
		
	UAVModel [[ level.uavSettings[ uavType ].addFunc ]]();

	// this adds 5 seconds of time to all active UAV's of the same type.
	if( IsDefined( level.activeUAVs[ team ] ) )
	{
		foreach( uav in level.UAVModels[ team ] )
		{
			if( uav == UAVModel )
				continue;
			
			uav.timeToAdd += 5;
		}
	}

	level notify ( "uav_update" );
	
	UAVModel waittill_notify_or_timeout_hostmigration_pause( "death", duration );

	if( UAVModel.damageTaken < UAVModel.maxHealth )
	{
		UAVModel Unlink();
	
		destPoint = UAVModel.origin + ( AnglesToForward( UAVModel.angles ) * 20000 );
		UAVModel MoveTo( destPoint, 60 );
		if( IsDefined( level.uavSettings[ uavType ].fxId_leave ) && IsDefined( level.uavSettings[ uavType ].fx_leave_tag ) )
			PlayFXOnTag( level.uavSettings[ uavType ].fxId_leave, UAVModel, level.uavSettings[ uavType ].fx_leave_tag );

		UAVModel waittill_notify_or_timeout_hostmigration_pause( "death", 3 );

		if ( UAVModel.damageTaken < UAVModel.maxHealth )
		{
			UAVModel notify( "leaving" );
			UAVModel.isLeaving = true;
			UAVModel MoveTo( destPoint, 4, 4, 0.0 );
		}
	
		UAVModel waittill_notify_or_timeout_hostmigration_pause( "death", 4 + UAVModel.timeToAdd );
	}

	UAVModel [[ level.uavSettings[ uavType ].removeFunc ]]();

	UAVModel delete();
	UAVModel removeUAVModel();
	
	if( uavType == "directional_uav" )
	{
		owner.radarShowEnemyDirection = false;
		if( level.teambased )
		{
			foreach( player in level.players )
			{
				if( player.pers["team"] == team )
				{
					player.radarShowEnemyDirection = false;					
				}
			}
		}
	}
	
	level notify ( "uav_update" );
}

updateUAVModelVisibility() // self == uavmodel
{
	self endon ( "death" );

	while( true )
	{
		level waittill_either( "joined_team", "uav_update" );
		
		self Hide();
		foreach( player in level.players )
		{
			if( level.teamBased )
			{
				if( player.team != self.team )
					self ShowToPlayer( player );
			}
			else
			{
				if( IsDefined( self.owner ) && player == self.owner )
					continue;
					
				self ShowToPlayer( player );
			}
		}
	}	
}

damageTracker() // self == uavmodel
{
	level endon ( "game_ended" );
	
	self SetCanDamage( true );
	self.damageTaken = 0; // how much damage has it taken
	
	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		if ( !IsPlayer( attacker ) )
		{
			if ( !IsDefined( self ) )
				return;
				
			continue;
		}
			
		if ( IsDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
			self.wasDamagedFromBulletPenetration = true;

		self.wasDamaged = true;

		modifiedDamage = damage;

		if( IsPlayer( attacker ) )
		{					
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "" );

			if( meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET" )
			{
				if ( attacker _hasPerk( "specialty_armorpiercing" ) )
					modifiedDamage += damage * level.armorPiercingMod;
			}
		}

		if( IsDefined( weapon ) )
		{
			switch( weapon )
			{
			case "stinger_mp":
			case "javelin_mp":
				self.largeProjectileDamage = true;
				modifiedDamage = self.maxHealth + 1;
				break;

			case "sam_projectile_mp":
				self.largeProjectileDamage = true;		
				mult = 0.25;
				if( self.uavType == "directional_uav" )
					mult = 0.15;
				modifiedDamage = self.maxHealth * mult; // takes about 2 burst of sam rockets
				break;
			}
			
			maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );

		}
		
		self.damageTaken += modifiedDamage;
/#
		if ( IsDefined( self ) && GetDvarInt( "g_debugDamage" ) )
			PrintLn( "uav:" + self getEntityNumber() + " health:" + ( self.health - self.damageTaken ) + " attacker:" + attacker.clientid + " inflictor is player:" + IsPlayer( attacker ) + " damage:" + modifiedDamage + " range:" + Distance( attacker.origin, self.origin ) );
#/

		if ( self.damageTaken >= self.maxHealth )
		{
			if ( IsPlayer( attacker ) && ( !IsDefined( self.owner ) || attacker != self.owner ) )
			{
				thread teamPlayerCardSplash( level.uavSettings[ self.uavType ].calloutDestroyed, attacker );

				thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, damage, meansOfDeath, weapon );
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 50, weapon, meansOfDeath );
				attacker notify( "destroyed_killstreak" );

				
				if ( IsDefined( self.UAVRemoteMarkedBy ) && self.UAVRemoteMarkedBy != attacker )
					self.UAVRemoteMarkedBy thread maps\mp\killstreaks\_remoteuav::remoteUAV_processTaggedAssist();				
			}
			
			self Hide();
			forward = ( AnglesToRight( self.angles ) * 200 );
			PlayFX ( level.uavSettings[ self.uavType ].fxId_explode, self.origin, forward );

			self notify( "death" );
			return;
		}
	}
}

UAVTracker() // self == level
{
	level endon ( "game_ended" );
	
	while( true )
	{
		level waittill ( "uav_update" );
		
		if( level.multiTeamBased )
		{
			for( i = 0; i < level.teamNameList.size; i++ )
			{
				updateTeamUAVStatus( level.teamNameList[i] );
			}
		}
		else if ( level.teamBased )
		{
			updateTeamUAVStatus( "allies" );
			updateTeamUAVStatus( "axis" );		
		}
		else
		{
			updatePlayersUAVStatus();
		}
	}
}

_getRadarStrength( team )
{
	activeUAVs = 0;
	activeCounterUAVs = 0;
	

	foreach ( uav in level.UAVModels[ team ] )
	{
		if ( uav.uavType == "counter_uav" )
			continue;
		
		if ( uav.uavType == "remote_mortar" )
			continue;
	
		activeUAVs++;
	}	

	if( level.multiTeamBased )
	{
		//count active counter uav's owned by the other team.
		foreach( teamName in level.teamNameList )
		{
			foreach ( uav in level.UAVModels[teamName] )
			{
				if( teamName == team )
					continue;

				if ( uav.uavType != "counter_uav" )
					continue;
		
				activeCounterUAVs++;
			}
		}
	}
	else
	{
		foreach ( uav in level.UAVModels[level.otherTeam[team] ] )
		{
			if ( uav.uavType != "counter_uav" )
				continue;
		
			activeCounterUAVs++;
		}
	}

	
	if( activeCounterUAVs > 0 )
		radarStrength = -3;
	else
		radarStrength = activeUAVs;
	
	strengthMin = GetUAVStrengthMin();
	strengthMax = GetUAVStrengthMax();	
	
	//clamp between min/max
	if( radarStrength <= strengthMin )
	{
		radarStrength = strengthMin;
	}
	else if( radarStrength >= strengthMax ) 
	{
		radarStrength = strengthMax;	
	}
	
	return radarStrength;
}


updateTeamUAVStatus( team )
{
	radarStrength = _getRadarStrength( team );

	SetTeamRadarStrength( team, radarStrength );

	if ( radarStrength >= GetUAVStrengthLevelNeutral() )
		unblockTeamRadar( team );
	else
		blockTeamRadar( team );
	
	if ( radarStrength <= GetUAVStrengthLevelNeutral() )
	{
		setTeamRadarWrapper( team, 0 );
		updateTeamUAVType( team );
		return;
	}
	
	if ( radarStrength >= GetUAVStrengthLevelShowEnemyFastSweep() )
		level.radarMode[team] = "fast_radar";
	else
		level.radarMode[team] = "normal_radar";

	updateTeamUAVType( team );
	setTeamRadarWrapper( team, 1 );	
}

//for FFA
updatePlayersUAVStatus()
{
	strengthMin = GetUAVStrengthMin();
	strengthMax = GetUAVStrengthMax();
	strengthDirectional = GetUAVStrengthLevelShowEnemyDirectional();
	
	//allPlayersCounterUAVTotal = 0;
	////calculate total counter uavs that currently exists across all players
	//foreach ( player in level.players )
	//{
	//	allPlayersCounterUAVTotal += level.activeCounterUAVs[ player.guid ];		
	//}
	
	foreach ( player in level.players )
	{
		radarStrength = level.activeUAVs[ player.guid + "_radarStrength" ];

		// if there are any counters up that aren't this player's then they are blocked
		foreach( enemyPlayer in level.players )
		{
			if( enemyPlayer == player )
				continue;

			activeCounterUAVs = level.activeCounterUAVs[ enemyPlayer.guid ];
			if( activeCounterUAVs > 0 )
			{
				radarStrength = -3;
				break;
			}
		}

		//clamp between min/max
		if( radarStrength <= strengthMin )
		{
			radarStrength = strengthMin;
		}
		else if( radarStrength >= strengthMax ) 
		{
			radarStrength = strengthMax;	
		}
			
		player.radarstrength = radarStrength;
				
		if ( radarStrength >= GetUAVStrengthLevelNeutral() )
			player.isRadarBlocked = false;
		else
			player.isRadarBlocked = true;
				
				
		if ( radarStrength <= GetUAVStrengthLevelNeutral()  )
		{
			player.hasRadar = false;
			player.radarShowEnemyDirection = false;
			continue;
		}
		
		if ( radarStrength >= GetUAVStrengthLevelShowEnemyFastSweep() )
			player.radarMode = "fast_radar";
		else
			player.radarMode = "normal_radar";
			
		//set directional status
		player.radarShowEnemyDirection = radarStrength >= strengthDirectional;
		
		player.hasRadar = true;
	}
}


blockPlayerUAV()
{
	self endon ( "disconnect" );
	
	self notify ( "blockPlayerUAV" );
	self endon ( "blockPlayerUAV" );

	self.isRadarBlocked = true;
	
	wait ( level.uavBlockTime );

	self.isRadarBlocked = false;

	//self iPrintLn( &"KILLSTREAKS_WAR_COUNTER_RADAR_EXPIRED" );
}


updateTeamUAVType( team )
{
	shouldBeDirectional = _getRadarStrength( team ) >= GetUAVStrengthLevelShowEnemyDirectional();

	foreach ( player in level.players )
	{
		if ( player.team == "spectator" )
			continue;
		
		player.radarMode = level.radarMode[player.team];
				
		//use direction based on uav signal strength
		if( player.team == team )
		{
			player.radarShowEnemyDirection = shouldBeDirectional;			
		}		
	}
}

usePlayerUAV( doubleUAV, useTime )
{
	level endon("game_ended");
	self endon("disconnect");

	self notify ( "usePlayerUAV" );
	self endon ( "usePlayerUAV" );
	
	if ( doubleUAV )
		self.radarMode = "fast_radar";
	else
		self.radarMode = "normal_radar";

	self.hasRadar = true;
	
	wait ( useTime );
	
	self.hasRadar = false;
}


setTeamRadarWrapper( team, value )
{
	setTeamRadar( team, value );
	level notify( "radar_status_change", team );
}



handleIncomingStinger()
{
	level endon ( "game_ended" );
	self endon ( "death" );
	
	while( true )
	{
		level waittill ( "stinger_fired", player, missile, lockTarget );
		
		if ( !IsDefined( lockTarget ) || (lockTarget != self) )
			continue;
			
		missile thread stingerProximityDetonate( lockTarget, player );
	}
}


stingerProximityDetonate( targetEnt, player )
{
	self endon ( "death" );

	minDist = Distance( self.origin, targetEnt GetPointInBounds( 0, 0, 0 ) );
	lastCenter = targetEnt GetPointInBounds( 0, 0, 0 );

	while( true )
	{
		// UAV already destroyed
		if ( !IsDefined( targetEnt ) )
			center = lastCenter;
		else
			center = targetEnt GetPointInBounds( 0, 0, 0 );
			
		lastCenter = center;		
		
		curDist = Distance( self.origin, center );
		
		if ( curDist < minDist )
			minDist = curDist;
		
		if ( curDist > minDist )
		{
			if ( curDist > 1536 )
				return;
				
			RadiusDamage( self.origin, 1536, 600, 600, player, "MOD_EXPLOSIVE", "stinger_mp" );
			PlayFX( level.stingerFXid, self.origin );

			//self playSound( "remotemissile_explode" );
			self Hide();
			
			self notify("deleted");
			wait ( 0.05 );
			self delete();
			player notify( "killstreak_destroyed" );
		}
		
		wait ( 0.05 );
	}	
}


addUAVModel() // self == uavmodel
{
	if ( level.teamBased )
		level.UAVModels[ self.team ][ level.UAVModels[ self.team ].size ] = self;
	else
		level.UAVModels[ self.owner.guid + "_" + GetTime() ] = self;	
}	

removeUAVModelOnDeath() // self == uavmodel
{
	self waittill( "death" );

	if( IsDefined( self.UAVRig ) )
		self.UAVRig delete();

	if( IsDefined( self ) )
		self delete();

	removeUAVModel();
}

removeUAVModel() // self == uavmodel
{
	UAVModels = [];

	if ( level.teamBased )
	{
		team = self.team;
		
		foreach ( uavModel in level.UAVModels[team] )
		{
			if ( !IsDefined( uavModel ) )
				continue;
				
			UAVModels[UAVModels.size] = uavModel;
		}

		level.UAVModels[team] = UAVModels;
	}
	else
	{
		foreach ( uavModel in level.UAVModels )
		{
			if ( !IsDefined( uavModel ) )
				continue;
				
			UAVModels[UAVModels.size] = uavModel;
		}

		level.UAVModels = UAVModels;
	}	
}


addActiveUAV() // self == uav model
{
	if ( level.teamBased )
	{
		level.activeUAVs[self.team]++;	
	}
	else
	{
		level.activeUAVs[ self.owner.guid ]++;
		level.activeUAVs[ self.owner.guid + "_radarStrength" ]++;
	}
}


addActiveCounterUAV()
{
	if ( level.teamBased )
		level.activeCounterUAVs[self.team]++;	
	else
		level.activeCounterUAVs[self.owner.guid]++;	
}


removeActiveUAV() // self == uav model
{
	if ( level.teamBased )
	{
		level.activeUAVs[self.team]--;
	}
	else if ( IsDefined( self.owner ) )
	{
		level.activeUAVs[ self.owner.guid ]--;
		level.activeUAVs[ self.owner.guid + "_radarStrength" ]--;
	}
}


removeActiveCounterUAV()
{
	if ( level.teamBased )
	{
		level.activeCounterUAVs[self.team]--;
	}
	else if ( IsDefined( self.owner ) )
	{
		level.activeCounterUAVs[self.owner.guid]--;
	}
}

spawnFXDelay( fxID, tag )
{
	self endon( "death" );
	level endon( "game_ended" );

	wait( 0.5 );
	PlayFXOnTag( fxID, self, tag );
}

watch3DPing( uavType, uavEnt ) // self == player
{
	if( IsDefined( uavEnt ) )
		uavEnt endon( "death" );
	
	self endon( "leave" );
	self endon( "killstreak_disowned" );
	level endon( "game_ended" );

	uavConfig = level.uavSettings[ uavType ];
	
	// every N seconds do a ping of the world and show enemies in red
	pingTime = uavConfig.pingTime;

	if (level.teamBased)
	{
		level.activeUAVs[ self.team ]++;
	}
	else
	{
		level.activeUAVs[ self.guid ]++;
	}
	
	while( true )
	{
		//PrintLn( "watch3DPing: GetTime() " + GetTime() + " PingTime " + pingTime );
		PlayFX( uavConfig.fxId_ping, self.origin );
		self PlayLocalSound( uavConfig.sound_ping_plr );
		playSoundAtPos( self.origin + ( 0, 0, 5 ), uavConfig.sound_ping_npc );

		// highlight all enemies in the world that can't be seen
		// 2013-08-24 wallace: in the future, instead of doing two nested for-loops, probably could sort the participants into friendly and enemy lists
		// then draw the enemies for friendlies
		foreach( enemy in level.participants )
		{
			if( !isReallyAlive( enemy ) )
				continue;

			if ( !(self isEnemy( enemy ) ) )
				continue;

			if( enemy _hasPerk( "specialty_noplayertarget" ) )
				continue;
			
			enemy maps\mp\gametypes\_damagefeedback::hudIconType( "oracle" );

			foreach( friendly in level.participants )
			{
				if( !isReallyAlive( friendly ) )
					continue;

				if ( self isEnemy( friendly ) )
					continue;

				if( IsAI( friendly ) )
					friendly ai_3d_sighting_model( enemy );
				else
				{
					// do outline for this enemy for this friendly
					// we don't use the team based version of this because we're calling it on every friendly anways. 
					// It was causing a bug where the outline would continue to be drawn after a friendly owner of the oracle disconnected
					id = outlineEnableForPlayer( enemy, "orange", friendly, false, "killstreak" );

					fadeTime = uavConfig.highlightFadeTime;
/#
					fadeTime = GetDvarFloat( "scr_" + uavType + "_highlightFadeTime" );
					// host migration wipes out this dvar for some reason and causes the loop to continue when it shouldn't
					if( fadeTime < 1 )
						fadeTime = uavConfig.highlightFadeTime;
#/

					friendly thread watchHighlightFadeTime( id, enemy, fadeTime, uavEnt );
				}
			}
		}

/#
		pingTime = GetDvarFloat( "scr_" + uavType + "_pingTime" );
		// host migration wipes out this dvar for some reason and causes the loop to continue when it shouldn't
		if( pingTime < 1 )
			pingTime = uavConfig.pingTime;
#/
			
		waitLongDurationWithHostMigrationPause( pingTime );
	}
}

watch3DPingTimeout( uavType ) // self == player
{
	self endon( "killstreak_disowned" );
	level endon( "game_ended" );

	config = level.uavSettings[ uavType ];
	useTime = config.timeOut;

/#
	useTime = GetDvarInt( "scr_" + uavType + "_timeout", useTime );
#/
	
	// save this index early, in case of player disconnect
	index = self.guid;
	if (level.teamBased)
	{
		index = self.team;
	}
	
	self thread watch_3dping_KillStreakDisowned( index );
	
	waitLongDurationWithHostMigrationPause( useTime );
	self leaderDialogOnPlayer( config.voTimeOut );
	self notify( "leave" );
	
	cleanup3dping( index );
}

watch_3dping_KillStreakDisowned( index ) // self == player
{
	self endon( "leave" );
	
	self waittill( "killstreak_disowned" );

	cleanup3dping( index );
}

cleanup3dping( index )
{
	level.activeUAVs[ index ]--;
		
	if ( level.activeUAVs[ index ] < 0 )
		level.activeUAVs[ index ] = 0;
}

watchHighlightFadeTime( id, ent, time, uavEnt ) // self == player
{
	if( IsDefined( uavEnt ) )
		uavEnt endon( "death" );

	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill_any_timeout_no_endon_death( time, "leave" );
	
	if( IsDefined( ent ) )
		outlineDisable( id, ent );
}

/#
debugLocation()
{
	self endon( "death" );

	while( true )
	{
		Print3d( self.origin, "UAV", ( 1, 0, 0 ) );
		Print3d( self.origin, "UAV origin: " + self.origin[0] + ", " + self.origin[1] + ", " + self.origin[2], ( 1, 0, 0 ) );

		Print3d( level.UAVRig.origin, "UAV Rig", ( 1, 0, 0 ) );
		Print3d( level.UAVRig.origin, "UAV Rig origin: " + level.UAVRig.origin[0] + ", " + level.UAVRig.origin[1] + ", " + level.UAVRig.origin[2], ( 1, 0, 0 ) );

		Print3d( level.UAVRig.origin - ( 0, 0, 50), "Distance: " + Distance( level.UAVRig.origin, self.origin ), ( 1, 0, 0 ) );

		Line( level.UAVRig.origin, self.origin, ( 0, 0, 1 ) );

		anglesForward = AnglesToForward( level.players[0].angles );
		scalar = (anglesForward[0] * 200, anglesForward[1] * 200, anglesForward[2] );
		Print3d( level.players[0].origin + scalar, "Distance: " + Distance( level.players[0].origin, self.origin ), ( 1, 0, 0 ) );
		wait( 0.05 );
	}
}

debugTrace()
{
	self endon( "death" );

	while( true )
	{
		result = BulletTrace( level.players[0].origin, self.origin, false, undefined );
		if( IsDefined( result ) && IsDefined( result[ "surfacetype" ] ) )
		{
			PrintLn( "UAV debugTrace: " + result[ "surfacetype" ] );
		}
		wait( 1.0 );
	}
}
#/

