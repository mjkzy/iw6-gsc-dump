#include common_scripts\utility;
#include maps\mp\_utility;

CONST_KILLSTREAK_CANNON = "pirate_cannons";
CONST_SHIP_NAME = "cannon_ship";
//CONST_SHIP_NAME = "ghost_ship";

CONVO_MIN_WAIT_INIT = 60;
CONVO_MAX_WAIT_INIT = 120;
CONVO_MIN_WAIT = 4 * 60;
CONVO_MAX_WAIT = 6 * 60;

main()
{
	maps\mp\mp_pirate_precache::main();
	maps\createart\mp_pirate_art::main();
	maps\mp\mp_pirate_fx::main();
	
	maps\mp\_load::main();
	
//	AmbientPlay( "ambient_mp_setup_template" );
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_pirate" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	setdvar_cg_ng( "r_specularColorScale", 2.8, 14 );
	setdvar_cg_ng( "sm_sunShadowScale", 0.5, 1 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	thread setupLevelKillstreak();
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
	
	// destructibles
	tower = setupDestructible( "destruction_tower" );
	tower thread towerCollapse( 9 );
	window = setupDestructible( "destruction_window" );
	window thread windowCollapse( 5 );
	
	thread bellsSetup( "churchbell" );
	
	if( is_Gen4() )
	{
		game[ "thermal_vision" ] = "thermal_mp";
		SetThermalBodyMaterial( "thermalbody_snowlevel" );
		VisionSetThermal( game[ "thermal_vision" ] );
	}
	
	/#
		level thread debugWatchDvars();
	
		debugRegisterDvarCallback( "scr_dbg_destructibles", ::dbgDestructibles );
		debugRegisterDvarCallback( "scr_dbg_convos", ::debugConversations );
		
		debugRegisterDvarCallback( "scr_dbg_fx", ::dbgFireFx );
	#/
		
	//HIDING DESTRUCTIBLES TILL THEY GET HOOKED UP PROPERLY
	/*
		DESTHIDE = GetEnt("destruction_window_before","targetname");
	DESTHIDE Hide();
	DESTHIDE = GetEnt("destruction_tower_before","targetname");
	DESTHIDE Hide();
	DESTHIDE = GetEnt("destruction_window_after","targetname");
	DESTHIDE Hide();
	DESTHIDE = GetEnt("destruction_window_anim","targetname");
	DESTHIDE Hide();
	DESTHIDE = GetEnt("destruction_tower_after","targetname");
	DESTHIDE Hide();
	DESTHIDE = GetEnt("destruction_tower_anim","targetname");
	DESTHIDE Hide();
	*/
	
//	thread setupGrog( "drink_grog" );
	
//	thread jailVO();
	thread setupConvos();
}

setupLevelKillstreak()
{
	level._effect[ "cannon_impact" ] 				 	= LoadFX( "vfx/moments/mp_pirate/vfx_exp_can_impact");
	level._effect[ "random_mortars_trail" ]				= LoadFX( "vfx/moments/mp_pirate/vfx_cannon_trail" );
	level._effect[ "cannon_muzzleflash" ]				= LoadFX( "vfx/moments/mp_pirate/vfx_cannon_blast" );
	level._effect[ "ship_wake" ]						= LoadFX( "vfx/moments/mp_pirate/vfx_ghost_boat_wake" );
	
	config = SpawnStruct();
	config.crateWeight		= 85;
	config.crateHint		= &"MP_PIRATE_CANNONS_USE";
	config.debugName		= "Cannon Barrage";
	config.id				= CONST_KILLSTREAK_CANNON;
	config.weaponName		= "warhawk_mortar_mp";
	config.splashName		= "used_" + CONST_KILLSTREAK_CANNON;
//	config.sourceStructs	= "cannon_source";
	config.sourceEnts		= "ship_cannons";
	config.targetStructs	= "cannon_target";
	
	// launch delay
	config.launchDelay		= 12;
	
	config.projectilePerLoop	= 12;
	config.delayBetweenVolleys	= 6;
	
	// air time
	// projectile model
	config.model			= "pirateship_cannon_ball_iw6";
	
	// warning sfx, played in environment
	//config.warningSfxEntName	= "mortar_siren";
	//config.warningSfx			= "mortar_siren";
	//config.warningSfxDuration	= 10;
	
	// launch parameters
	// min delay, max delay, max air time
	// launch sfx
	//config.launchSfx		= "cannon_fire";
	config.launchSfxArray	= [ "cannon_fire_1", "cannon_fire_2", "cannon_fire_3", "cannon_fire_4", "cannon_fire_5", "cannon_fire_6", "cannon_fire_7", "cannon_fire_8", "cannon_fire_9", "cannon_fire_10" ];
	config.launchSfxStartId	= 0;
	
	config.launchVfx		= "cannon_muzzleflash";
	config.launchDelayMin	= 1.0;
	config.launchDelayMax	= 1.5;
	config.launchAirTimeMin	= 2;
	config.launchAirTimeMax	= 3;
	config.strikeDuration	= 35;
	
	// incoming sfx
	config.incomingSfx		= "cannon_ball_incoming";
	config.trailVfx			= "random_mortars_trail";
	
	// impact
	config.impactSfx		= "cannon_ball_impact";
	config.impactVfx		= "cannon_impact";
	
	shipSetup( CONST_SHIP_NAME );
	
	maps\mp\killstreaks\_mortarstrike::createMortar( config );
	
	level.mapCustomKillstreakFunc = ::customKillstreakFunc;
	level.mapCustomCrateFunc = ::customCrateFunc;
	level.mapCustomBotKillstreakFunc = ::customBotKillstreakFunc;
	
	maps\mp\mp_pirate_ghost::init();
	
	/#
	AddDebugCommand( "bind p \"set scr_givekillstreak " + CONST_KILLSTREAK_CANNON + "\"\n" );
	AddDebugCommand( "bind SEMICOLON \"set scr_givekillstreak pirate_ghostcrew\"\n" );
	#/
}

customKillstreakFunc()
{
	maps\mp\killstreaks\_mortarstrike::mortarCustomKillstreakFunc();
	
	level.killStreakFuncs[ CONST_KILLSTREAK_CANNON ] = ::tryUsePirateShip;
	
	maps\mp\mp_pirate_ghost::customKillstreakFunc();
}

customCrateFunc()
{
	maps\mp\killstreaks\_mortarstrike::mortarCustomCrateFunc();
	maps\mp\mp_pirate_ghost::customCrateFunc();
}


customBotKillstreakFunc()
{
	maps\mp\killstreaks\_mortarstrike::mortarCustomBotKillstreakFunc();
	maps\mp\mp_pirate_ghost::cusomBotKillstreakFunc();
}

// ------------------------
// Destruction events
setupDestructible( objName )
{
	pre = GetEntArray( objName + "_before", "targetname" );
	
	post = GetEntArray( objName + "_after", "targetname" );
	foreach ( chunk in post )
	{
		chunk clearPath();
	}
	
	animModels = GetEntArray( objName + "_anim", "targetname" );
	foreach ( animModel in animModels )
	{
		animModel Hide();
	}
	
	destructible = SpawnStruct();
	destructible.postCollapse = post;
	destructible.preCollapse = pre;
	destructible.animModels = animModels;
	
	return destructible;
	// destructible thread destructibleCollapse();
}

CONST_DESTRUCTIBLE_WINDOW_PROJECTILE_FLIGHT_TIME = 0.775;
CONST_DESTRUCTIBLE_WINDOW_RADIUS = 150;
windowCollapse( initialDelay )
{
	level waittill( "mortar_killstreak_start" );
	
	if ( initialDelay > CONST_DESTRUCTIBLE_WINDOW_PROJECTILE_FLIGHT_TIME )
	{
		initialDelay = RandomFloatRange( initialDelay, initialDelay + 5 );
		wait ( initialDelay - CONST_DESTRUCTIBLE_WINDOW_PROJECTILE_FLIGHT_TIME );
	}
	
	exploder( 2 );
	
	wait ( CONST_DESTRUCTIBLE_WINDOW_PROJECTILE_FLIGHT_TIME );
	
	foreach ( chunk in self.preCollapse )
	{
		chunk clearPath();
	}
	
	// play anim
	animLength = 4.0;
//	if( ( level.ps3 ) || ( level.xenon ) )
//	{
//		animLength = GetAnimLength( %mp_ruins_td_01_cg_anim );
//	}
//	else
//	{
//		animLength = GetAnimLength( %mp_ruins_temple_debris_01_anim );
//	}
	
	foreach ( animModel in self.animModels )
	{
		animModel Show();
		
		// AssertEx( IsDefined( animModel.script_noteworthy ) );
		animName = animModel.script_noteworthy;
		if ( IsDefined( animName ) )
		{
//			animModel ScriptModelPlayAnim( "vfx_anim_window_destruction_clust1" );
			animModel ScriptModelPlayAnim( animName );
		}
	}
	
	// PlaySoundAtPos( self.preCollapse[0].origin, "scn_battery3_temple_collapse" );
	
	wait ( 1.5 );
	
	// kill people as the pieces fall so they aren't trapped inside
	impactPoint = self.postCollapse[0].origin;
	foreach ( rubble in self.postCollapse )
	{
		if ( IsDefined( rubble.clip ) )
		{
			impactPoint = rubble.clip.origin;
			break;
		}
	}
	
	Earthquake( 0.1, 0.5, impactPoint, CONST_DESTRUCTIBLE_WINDOW_RADIUS );
	// RadiusDamage( impactPoint, CONST_DESTRUCTIBLE_WINDOW_RADIUS, 500, 500, undefined, "MOD_CRUSH" );
	// crushAllObjects( impactPoint, CONST_DESTRUCTIBLE_WINDOW_RADIUS );
	
	wait ( animLength - 1.5 );	// 3.5 for the two previous waits
	
	// PlaySoundAtPos( impactPos, CONST_COLUMN_IMPACT_SFX );
	// exploder( CONST_COLUMN_IMPACT_VFX_EXPLODER_ID );
	
	foreach ( model in self.postCollapse )
	{
		model blockPath();
	}
	
	foreach ( animModel in self.animModels )
	{
		animModel Hide();
	}
}

CONST_DESTRUCTIBLE_PROJECTILE_FLIGHT_TIME = 0;
CONST_DESTRUCTIBLE_TOWER_RADIUS = 300;
towerCollapse( initialDelay )
{
	level waittill( "mortar_killstreak_start" );
	
	if ( initialDelay > CONST_DESTRUCTIBLE_PROJECTILE_FLIGHT_TIME )
	{
		initialDelay = RandomFloatRange( initialDelay, initialDelay + 5 );
		wait ( initialDelay - CONST_DESTRUCTIBLE_PROJECTILE_FLIGHT_TIME );
	}
	
	exploder( 1 );
	
//	wait( CONST_DESTRUCTIBLE_PROJECTILE_FLIGHT_TIME );
	
	foreach ( chunk in self.preCollapse )
	{
		chunk clearPath();
	}
	
	// play anim
	animLength = 9;
	
	foreach ( animModel in self.animModels )
	{
		animModel Show();
		
		// AssertEx( IsDefined( animModel.script_noteworthy ) );
		animName = animModel.script_noteworthy;
		if ( IsDefined( animName ) )
		{
			animModel ScriptModelPlayAnim( animName );
//			animName = "vfx_anim_tower_destruction_clust1";
		}
	}
	
	PlaySoundAtPos( self.preCollapse[0].origin, "scn_pirate_tower_collapse" );
	
	wait ( 1.5 );
	
	// kill people as the pieces fall so they aren't trapped inside
	impactPoint = self.postCollapse[0].origin;
	foreach ( rubble in self.postCollapse )
	{
		if ( IsDefined( rubble.clip ) )
		{
			impactPoint = rubble.clip.origin;
			break;
		}
	}
	
	Earthquake( 0.25, 0.5, impactPoint, CONST_DESTRUCTIBLE_TOWER_RADIUS );
	// RadiusDamage( impactPoint, CONST_DESTRUCTIBLE_TOWER_RADIUS, 500, 500, undefined, "MOD_CRUSH" );
	// crushAllObjects( impactPoint, CONST_DESTRUCTIBLE_TOWER_RADIUS );
	
	wait ( animLength - 1.5 );	// 3.5 for the two previous waits
	
	// PlaySoundAtPos( impactPos, CONST_COLUMN_IMPACT_SFX );
	// exploder( CONST_COLUMN_IMPACT_VFX_EXPLODER_ID );
	
	foreach ( animModel in self.animModels )
	{
		animModel Hide();
	}
	
	foreach ( model in self.postCollapse )
	{
		model blockPath();
	}
}

// helpers
playRumble( rumbleType )
{
	foreach ( player in level.players )
	{
		player PlayRumbleOnEntity( rumbleType );
	}
}

clearPath()	// self == blockingEnt
{	
	self Hide();
	self NotSolid();
	
	if ( IsDefined( self.target ) )
	{
		clip = GetEnt( self.target, "targetname" );
		self.clip = clip;
		
		clip ConnectPaths();
		clip NotSolid();
		clip Hide();
	}
}

blockPath()
{
	self Show();
	self Solid();
	
	if ( IsDefined( self.clip ) )
	{
		self.clip Show();
		self.clip Solid();
		self.clip DisconnectPaths();
	}
}

crushAllObjects( refPos, radius )
{
	radiusSq = radius * radius;
	
	crushObjects( refPos, radiusSq, "death", level.turrets );
	crushObjects( refPos, radiusSq, "death", level.placedIMS );
	crushObjects( refPos, radiusSq, "death", level.uplinks );
	crushObjects( refPos, radiusSq, "detonateExplosive", level.mines );
	
	foreach ( boxList in level.deployable_box )
	{
		crushObjects( refPos, radiusSq, "death",  boxList );
	}
}

crushObjects( refPos, radiusSq, notifyStr, targets )
{
	foreach ( target in targets )
	{
		if ( DistanceSquared( refPos, target.origin ) < radiusSq )
		{
			target notify( notifyStr );
			// target notify( "damage", 5000 );
			// target notify( "death" );
		}
	}
}

// -----------------------------------------------------------------
// Pirate Ship Cannon Barrage
// -----------------------------------------------------------------
tryUsePirateShip( lifeId, streakName )
{
	if ( maps\mp\killstreaks\_mortarstrike::tryUseMortars( lifeId, streakName ) )
	{
		thread shipRun( CONST_SHIP_NAME, "shipPathStart" );
		
		return true;
	}
	
	return false;
}

CONST_SHIP_SPEED = 300;
shipRun( name, firstNode )
{
	ship = GetEnt( name, "targetname" );
	// ship = GetEnt( anim_ref.target, "targetname" );
	// Adding model link to for boat Model
	shipModels = GetEntArray( "ship_bits", "targetname" );
	foreach ( detail in shipModels )
	{
		detail Show();
		detail LinkTo( ship );
	}
	
	ship thread shipBarragePlayMusic();
	
	ship thread shipVO();
	
	// link to models?
	struct = getstruct( firstNode, "targetname" );
	ship.origin = struct.origin;
	// ship.angles = struct.angles;
	
	// anim_ref.origin = struct.origin;
	ship.angles = struct.angles;
	
	PlayFXOnTag( getfx( "ship_wake" ), ship.wakeTag, "tag_origin" );
	
	// ship LinkTo( anim_ref );
	
	nextNode = struct.target;
	
	while ( IsDefined( nextNode ) )
	{
		nextNode = ship shipMove( nextNode, CONST_SHIP_SPEED );
	}
	
	ship StopSounds();
	
	// hide the ship?
	
	StopFXOnTag( getfx( "ship_wake" ), ship.wakeTag, "tag_origin" );
	
	// clean up
//	ship ScriptModelClearAnim();
//	ship Unlink();
	// anim_ref Delete();
	
	shipModels = GetEntArray( "ship_bits", "targetname" );
	foreach ( detail in shipModels )
	{
		detail Hide();
	}
}

shipSetup( name )
{
	ship = GetEnt( name, "targetname" );
	
	forward = AnglesToForward( ship.angles );
	right = 350 * AnglesToRight( ship.angles );
	
	shipModels = GetEntArray( "ship_bits", "targetname" );
	shipModel = shipModels[0];
	
	for ( i = 0; i < 5; i++ )
	{ 
		tagName = "tag_cannon_" + (i + 1);
		cannon = Spawn( "script_model", shipModel GetTagOrigin( tagName ) );
		cannon.angles = shipModel GetTagAngles( tagName );
		cannon SetModel( "tag_origin" );
		cannon LinkTo( ship );
		cannon.targetname = "ship_cannons";
	}
	
	ship.cannons = ship GetLinkedChildren();
	
	wakeTag = Spawn( "script_model", shipModel GetTagOrigin( "tag_wake" ) + (0, 0, 85) );
	wakeTag.angles = ship.angles + (-90, 0, 0 );
	wakeTag SetModel( "tag_origin" );
	wakeTag LinkTo( ship );
	ship.wakeTag = wakeTag;
	
	
	foreach ( detail in shipModels )
	{
		detail Hide();
	}
}

shipMove( nodeName, speed )	// self == ship
{
	struct = getstruct( nodeName, "targetname" );
	
	if ( IsDefined( struct ) )
	{
		if ( !IsDefined( struct.moveTime ) )
		{
			struct.moveTime = Distance2D( struct.origin, self.origin ) / speed;
		}
		
		self MoveTo( struct.origin, struct.moveTime, 0, 0 );
		self RotateTo( struct.angles, struct.moveTime, 0, 0 );
		
		wait( struct.moveTime );
		
		return struct.target;
	}
	
	return undefined;
}

shipBarragePlayMusic()	// self == ship
{
	level endon( "game_ended" );
	
	self.wakeTag PlaySoundOnMovingEnt( "mus_dead_man_chest_01" );
	
	level waittill( "mortar_killstreak_end" );
	
	self StopSounds();
	
	wait (0.05);
	
	self.wakeTag PlaySoundOnMovingEnt( "mus_dead_man_chest_02" );
}

shipVO()
{
	wait ( 7.5 );
	
	self thread shipVOPlayLines();
	
	// end volley
	level waittill( "mortar_volleyFinished" );
	
	wait ( RandomFloatRange( 3.0, 3.5 ) );
	
	self thread shipVOPlayLines();
}

shipVOPlayLines()
{
	self thread shipVOPlayOneLine( "mp_pirate_cpt_attack" );
	
	wait ( RandomFloatRange( 1.0, 1.5 ) );
	
	// pick a mate to speak first
	if ( RandomInt( 2 ) == 0 )
	{
		self thread shipVOPlayOneLine( "mp_pirate_prt1_attack" );
		
		wait ( RandomFloatRange( 0.5, 1.0 ) );
		
		self thread shipVOPlayOneLine( "mp_pirate_prt2_attack" );
	}
	else
	{
		self thread shipVOPlayOneLine( "mp_pirate_prt2_attack" );
		
		wait ( RandomFloatRange( 0.5, 1.0 ) );
		
		self thread shipVOPlayOneLine( "mp_pirate_prt1_attack" );
	}
}

shipVOPlayOneLine( lineSet, speaker )	// self == ship
{
	speakerEnt = self.cannons[ RandomInt( self.cannons.size ) ];
	
	speakerEnt PlaySoundOnMovingEnt( lineSet );
}

// -----------------------------------------------------------------
// bells
// -----------------------------------------------------------------
bellsSetup( bellName )
{
	// level endon( "game_ended" );
	
	bells = GetEntArray( bellName, "targetname" );
	if (bells.size <= 0 )
	{
		PrintLn( "No church bells found." );
		return;
	}	
	
	array_thread( bells, ::bellsDetectHit );
}

bellsDetectHit()
{
	self SetCanDamage( true );
	self.is_swaying = false;
	
	// self.script_noteworthy
	sound_alias = "pir_big_bell";
	if ( IsDefined( self.script_noteworthy ) && isStrStart( self.script_noteworthy, "pir_bell_" ) )
	{
		sound_alias = self.script_noteworthy;
	}
	
	while ( 1 )
	{
		self waittill( "damage", amount, attacker, direction_vec, hit_point, type );
		
		if ( !IsDefined( attacker ) || !IsPlayer( attacker ) )	// somehow, the heli sniper helicopter will trigger this.
			continue;
		
		current_weapon = attacker GetCurrentWeapon();
		if ( type == "MOD_IMPACT"
		    || type == "MOD_PROJECTILE"
		    || type == "MOD_PROJECTILE_SPLASH"
		    || type == "MOD_GRENADE"
		    || type == "MOD_GRENADE_SPLASH"
		    || type == "MOD_MELEE"
//		     || type == "MOD_EXPLOSIVE"
		    || ( IsDefined( current_weapon ) && (WeaponClass( current_weapon ) == "sniper" ) )
		   )
		{
			self PlaySound( sound_alias );
			
			if ( !self.is_swaying )
			{
				self thread bellsHitSway( attacker );
			}
			
			wait 0.5;
		}
	}
}

bellsHitSway( attacker )
{
	level endon( "game_ended" );
	
	// play animation instead?
	vec = AnglesToRight( self.angles );
	vec2 = VectorNormalize( attacker.origin - self.origin );
	swing_dir = vectordot( vec, vec2 )  * 2.0;
	if ( swing_dir > 0.0 )
		swing_dir = Max( 0.3, swing_dir );
	else
		swing_dir = Min( -0.3, swing_dir );
	
	self.is_swaying = true;
	self RotateRoll( 15 * swing_dir, 1.0, 0, 0.5 );
	wait 1;
	self RotateRoll( -25 * swing_dir, 2.0, 0.5, 0.5 );
	wait 2;
	self RotateRoll( 15 * swing_dir, 1.5, 0.5, 0.5 );
	wait 1.5;
	self RotateRoll( -5 * swing_dir, 1.0, 0.5, 0.5 );
	wait 1.0;
	self.is_swaying = false;
}

CONST_GROG_FX = "pirate_test2";
CONST_GROG_TAG = "j_mainroot";
CONST_GROG_MIN_SPEED = 115 * 115;
CONST_GROG_TIME = 20;
CONST_GROG_NUM_USES = 3;
GROG_USE_TIME = 4;
GROG_DRUNK_TIME = 5;
	
setupGrog( entName )
{
	level endon( "game_ended" );
	
	level._effect[ "pirate_test2" ] = LoadFX( "fx/fire/molotov_bottle_fire" );
	
	level waittill ( "match_ending_soon", reason );
	
	timeLeft = ( maps\mp\gametypes\_gamelogic::getTimeRemaining() * 0.001 ) - 30.0;
	
	if ( reason == "score" )
	{
		if ( getTimeLimit() <= 0 )
		{
			timeLeft = 60;
		}
	}
	else
	{
		// if reason == time, the notify usually fires 30-60 seconds from the end
		timeLeft = min( timeLeft, 30 );
	}
	
	if ( timeLeft > 0 )
	{
		wait( timeLeft );
	}
	
	// create trigger
	grogtrigger = GetEnt( entName, "targetname" );
	
	if ( IsDefined( grogtrigger ) )
	{
		grog = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", grogtrigger, [grogtrigger], (0,0,0) );
		grog.id = "use";
		
		grog maps\mp\gametypes\_gameobjects::setUseTime( GROG_USE_TIME );		
		grog maps\mp\gametypes\_gameobjects::setUseText( &"MP_PIRATE_GROG_USING" );
		grog maps\mp\gametypes\_gameobjects::setUseHintText( &"MP_PIRATE_GROG_USE" );
		grog maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		grog maps\mp\gametypes\_gameobjects::allowUse( "any" );
		
		grog.onUse = ::grogOnUse;
		grog.onBeginUse = ::grogOnBeginUse;
		grog.onEndUse = ::grogOnEndUse;
		
		grog.uses = CONST_GROG_NUM_USES;
	}
}

grogOnUse( player )
{
	if ( !IsDefined( player.grogTriggered ) )
	{
		player thread grogUpdate();
		
		self.uses--;
		if ( self.uses == 0 )
		{
			self grogMakeUnusable();
		}
	}
	else
	{
		player ShellShock( "concussion_grenade_mp", GROG_DRUNK_TIME );
	}
}

grogOnBeginUse( player )
{
	// play drink sfx
}

grogOnEndUse( team, player, result )
{
	// play burp sfx
	if( IsPlayer( player ) )
	{
		player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
	}
}

grogMakeUnusable()
{
	//	self maps\mp\gametypes\_gameobjects::allowUse( "any" );
	self maps\mp\gametypes\_gameobjects::disableObject();
	self maps\mp\gametypes\_gameobjects::deleteUseObject();
}

grogWaitForUse()
{
	level endon( "game_ended" );
	while ( true )
	{
		self waittill( "trigger", user );
		
		user thread grogUpdate( self );
	}
}

grogUpdate( grog )
{
	level endon( "game_ended" );
	self endon( "grogStop" );
	
	if ( IsDefined( self.grogTriggered ) )
	{
		return;
	}
	self.grogTriggered = true;
	
	// make grog unusable for this player
	
	if ( !self _hasPerk( "specialty_lightweight" ) )
	{
		self.grogPerk = true;
		self givePerk( "specialty_lightweight", false );
	}
	
	self thread grogTimer( CONST_GROG_TIME );
	
	while ( IsDefined( self ) && isReallyAlive( self ) )
	{
		speedSq = LengthSquared( self GetVelocity() );
		
		if ( speedSq > CONST_GROG_MIN_SPEED )
		{
			if ( !IsDefined( self.grogged ) )
			{
				self.grogged = true;
				PlayFXOnTag( getfx( "pirate_test2" ), self, CONST_GROG_TAG );
			}
		}
		else if ( IsDefined( self.grogged ) )
		{
			grogStopFx();
		}
		
		wait ( 0.25 );
	}
	
	self grogCleanup();
}

grogCleanup()
{
	if ( IsDefined( self ) )
	{
		self.grogTriggered = undefined;
		if ( IsDefined( self.grogPerk ) )
		{
			self.grogPerk = undefined;
			self _unsetPerk( "specialty_lightweight" );
		}
		
		self grogStopFx();
	}
}

grogTimer( delay )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "death" );
	
	wait( delay );
	
	self notify( "grogStop" );
	
	self grogCleanup();
}

grogStopFx()
{
	self.grogged = undefined;
	StopFXOnTag( getfx( CONST_GROG_FX ), self, CONST_GROG_TAG );
}

// ----------------------------------------------------------
//	Conversations
// ----------------------------------------------------------
setupConvos()
{	
	level.convoLocs = [
		"convo_dock_3",
		"convo_dock_3",
		"convo_tavern_1",
		"convo_voodoo_1",
		"convo_brothel_1"
	];
	
	level.convoVos = [
		"mp_pirate_vo_docked",
		"mp_pirate_vo_docked",
		"mp_pirate_vo_tavern",
		"mp_pirate_vo_voodoo",
		"mp_pirate_vo_brothel"
	];
	
	level endon( "game_ended" );
	
	// should I try to stop the vo if the game ends?
	convoPlayOne( CONVO_MIN_WAIT_INIT, CONVO_MAX_WAIT_INIT );
	
	convoPlayOne( CONVO_MIN_WAIT, CONVO_MAX_WAIT );
	
	convoPlayOne( CONVO_MIN_WAIT, CONVO_MAX_WAIT );
}

convoPlayOne( minWait, maxWait )
{
	delay = RandomIntRange( minWait, maxWait );
	wait( delay );
	
	index = RandomInt( level.convoLocs.size );
	while ( level.convoLocs[ index ] == "" )
	{
		index = RandomInt( level.convoLocs.size );
	}
	
	soundStruct = getstruct( level.convoLocs[ index ], "targetname" );
	
	/#
/*
	IPrintLnBold( "VO: " + level.convoVos[ index ] + " @ " + level.convoLocs[ index ] );
		
	Sphere( soundStruct.origin, 5, (0, 0, 1), 1, 200 );	
	
	wait ( 8 );
	
	player = maps\mp\gametypes\_gamelogic::getHostplayer();
	if ( IsDefined( player ) )
		player.origin = soundStruct.origin;
*/
	#/
	
	PlaySoundAtPos( soundStruct.origin, level.convoVos[ index ] );
	
	// make sure we don't use this vo again
	level.convoLocs[ index ] = "";
}

JAIL_VO_MIN_WAIT = 120;
JAIL_VO_MAX_WAIT = 180;
jailVO()
{
	level endon ( "game_ended" );
	
	jailLines = [
		"mp_pirate_prs_jail_1",
		"mp_pirate_prs_jail_2",
		"mp_pirate_prs_jail_3",
		"mp_pirate_prs_jail_4",
		"mp_pirate_prs_jail_5"
	];
	
	soundStruct = getstruct( "convo_jail_1", "targetname" );
	soundEnt = Spawn( "script_origin", soundStruct.origin );
	
	// use a trigger?
	while ( true )
	{
		delay = RandomFloatRange( JAIL_VO_MIN_WAIT, JAIL_VO_MAX_WAIT );
		
		wait( delay );
		
		index = RandomInt( jailLines.size );
		
		soundEnt PlaySound( jailLines[ index ] );
	}
}

/#
debugConversations( conversation )
{
	testString = "convo_" + conversation + "_1";
	i = 0;
	for ( ; i < level.convoLocs.size; i++ )
	{
		if ( level.convoLocs[ i ] == testString )
		{
			break;
		}
	}
	
	if ( i == level.convoLocs.size )
	{
		i = 0;
	}
	soundStruct = getstruct( level.convoLocs[ i ], "targetname" );
	PlaySoundAtPos( soundStruct.origin, level.convoVos[ i ] );
	
	Sphere( soundStruct.origin, 5, (0, 1, 0), 1, 200 );
}
#/

/#
dbgDestructibles( obj )
{
	level endon( "game_ended" );
	
	if ( obj == "tower" )
	{
		tower = setupDestructible( "destruction_tower" );
		tower thread towerCollapse( 0 );
		
		level notify( "mortar_killstreak_start" );
		
		wait ( 10 );
		
		pre = GetEntArray( "destruction_tower" + "_before", "targetname" );
		foreach ( chunk in pre )
		{
			chunk blockPath();
		}
	}
	else
	{
		pre = GetEntArray( "destruction_window" + "_before", "targetname" );
		foreach ( chunk in pre )
		{
			chunk blockPath();
		}
		
		window = setupDestructible( "destruction_window" );
		window thread windowCollapse( 0 );
		
		level notify( "mortar_killstreak_start" );
		
		wait ( 6 );
		
		pre = GetEntArray( "destruction_window" + "_before", "targetname" );
		foreach ( chunk in pre )
		{
			chunk blockPath();
		}
	}
}
	
debugWatchDvars()
{
	level endon( "game_ended" );
	
	level.dbgDvarNotify = [];
	level.dbgDvarCallback = [];
	
	while ( true )
	{
		foreach ( dvar, event in level.dbgDvarNotify )
		{
			if ( GetDvarInt( dvar ) > 0 )
			{
				level notify( event );
				SetDvar( dvar, 0 );
			}
		}
		
		foreach ( dvar, callback in level.dbgDvarCallback )
		{
			value = GetDvar( dvar );
			if ( value != "" )
			{
				[[ callback ]]( value );
				SetDvar( dvar, "" );
			}
		}
		
		wait (0.1);
	}
}

debugRegisterDvarNotify( dvar, eventName )
{
	if ( !IsDefined( level.dbgDvarUpdate ) )
	{
		level.dbgDvarUpdate = true;
		
		level thread debugWatchDvars();
	}
	
	SetDvarIfUninitialized( dvar, 0 );
	level.dbgDvarNotify[ dvar ] = eventName;
}

debugRegisterDvarCallback( dvar, callback )
{
	if ( !IsDefined( level.dbgDvarUpdate ) )
	{
		level.dbgDvarUpdate = true;
		
		level thread debugWatchDvars();
	}
	
	SetDvarIfUninitialized( dvar, "" );
	level.dbgDvarCallback[ dvar ] = callback;
}

dbgFireFx( fxId )
{
	exploder( Int(fxId) );
}
#/