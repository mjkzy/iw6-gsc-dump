#include common_scripts\utility;
#include common_scripts\_fx;
#include maps\mp\_utility;

main()
{
	if ( isDefined( level._loadStarted ) )
		return;

	level._loadStarted = true;

	level.createFX_enabled = ( getdvar( "createfx" ) != "" );

	struct_class_init();

	initGameFlags();
	initLevelFlags();
	initGlobals();
	
	level.generic_index = 0;
	// flag_struct is used as a placeholder when a flag is set without an entity

	level.flag_struct = spawnstruct();
	level.flag_struct assign_unique_id();
	if ( !isdefined( level.flag ) )
	{
		level.flag = [];
		level.flags_lock = [];
	}

	level.requiredMapAspectRatio = getDvarFloat( "scr_RequiredMapAspectratio", 1 );	
	level.createClientFontString_func = maps\mp\gametypes\_hud_util::createFontString;
	level.HUDsetPoint_func = maps\mp\gametypes\_hud_util::setPoint;
	level.leaderDialogOnPlayer_func	= maps\mp\_utility::leaderDialogOnPlayer;
	
	thread maps\mp\gametypes\_tweakables::init();
	
	
	if ( !isdefined( level.func ) )
		level.func = [];
	level.func[ "precacheMpAnim" ] = ::precacheMpAnim;
	level.func[ "scriptModelPlayAnim" ] = ::scriptModelPlayAnim;
	level.func[ "scriptModelClearAnim" ] = ::scriptModelClearAnim;
	
	// dodge this stuff for createfx tool.
	if( ! level.createFX_enabled )
	{
		thread maps\mp\_minefields::minefields();
		thread maps\mp\_radiation::radiation();
		thread maps\mp\_shutter::main();
		thread maps\mp\_movers::init();
		thread maps\mp\_destructables::init();
		thread common_scripts\_elevator::init();
		thread common_scripts\_dynamic_world::init();
		thread common_scripts\_destructible::init();
		level notify( "interactive_start" );
	}

	game["thermal_vision"] = "thermal_mp";
	
	VisionSetNaked( "", 0 ); // go to default visionset
	VisionSetNight( "default_night_mp" );
	VisionSetMissilecam( "missilecam" );
	VisionSetThermal( game[ "thermal_vision" ] );
	VisionSetPain( "", 0 );

	lanterns = getentarray("lantern_glowFX_origin","targetname");
	for( i = 0 ; i < lanterns.size ; i++ )
		lanterns[i] thread lanterns();

	maps\mp\_audio::init_audio();
	maps\mp\_art::main();
	/#
	thread common_scripts\_painter::main("painter_mp");
	#/

	setupExploders();

	thread common_scripts\_fx::initFX();
	if ( level.createFX_enabled )
	{
		maps\mp\gametypes\_spawnlogic::setMapCenterForDev();
		maps\mp\_createfx::createfx();
	}

	if ( getdvar( "r_reflectionProbeGenerate" ) == "1" )
	{
		maps\mp\gametypes\_spawnlogic::setMapCenterForDev();
		maps\mp\_global_fx::main();
		level waittill( "eternity" );
	}

	thread maps\mp\_global_fx::main();
	
	// Do various things on triggers
	for ( p = 0;p < 6;p ++ )
	{
		switch( p )
		{
			case 0:
				triggertype = "trigger_multiple";
				break;

			case 1:
				triggertype = "trigger_once";
				break;

			case 2:
				triggertype = "trigger_use";
				break;
				
			case 3:	
				triggertype = "trigger_radius";
				break;
			
			case 4:	
				triggertype = "trigger_lookat";
				break;

			default:
				assert( p == 5 );
				triggertype = "trigger_damage";
				break;
		}

		triggers = getentarray( triggertype, "classname" );

		for ( i = 0;i < triggers.size;i ++ )
		{
			if( isdefined( triggers[ i ].script_prefab_exploder) )
				triggers[i].script_exploder = triggers[ i ].script_prefab_exploder;

			if( isdefined( triggers[ i ].script_exploder) )
				level thread maps\mp\_load::exploder_load( triggers[ i ] );
		}
	}

	thread maps\mp\_animatedmodels::main();
	
	// auto-sentry
	level.func[ "damagefeedback" ] = maps\mp\gametypes\_damagefeedback::updateDamageFeedback;
	level.func[ "setTeamHeadIcon" ] = maps\mp\_entityheadicons::setTeamHeadIcon;
	level.laserOn_func = ::laserOn;
	level.laserOff_func = ::laserOff;

	level.connectPathsFunction = ::connectPaths;
	level.disconnectPathsFunction = ::disconnectPaths;
	
	 // defaults
	setDvar( "sm_sunShadowScale", 1 );
	setDvar( "sm_spotLightScoreModelScale", 0 );
	setDvar( "r_specularcolorscale", 2.5 );
	setDvar( "r_diffusecolorscale", 1 );
	setDvar( "r_lightGridEnableTweaks", 0 );
	setDvar( "r_lightGridIntensity", 1 );
	setDvar( "r_lightGridContrast", 0 );

	// created these so we can turn things on/off individually without having to set the game to hardcore
	SetDvar( "ui_showInfo", 1 );
	SetDvar( "ui_showMinimap", 1 );

	// setup kill cam ents on destructibles
	setupDestructibleKillCamEnts();

	// precache the bomb site weapon
	PreCacheItem( "bomb_site_mp" );

	// precache dog fur for PC
	if ( !level.console )
	{
		level.furFX = loadfx( "vfx/apex/nv_dog_a" );
		level.wolfFurFX = [];
		level.wolfFurFX[0] = loadfx( "vfx/apex/nv_wolf_b" );
		level.wolfFurFX[1] = loadfx( "vfx/apex/nv_wolf_c" );
	}

	level.fauxVehicleCount = 0;	// this keeps an artificial count so we can check airspace and vehicles limits preemptively
	level.littlebird_model = "vehicle_aas_72x_killstreak";
	
/#
	// when host migration happens, all of the dev dvars get cleared, so this will reset them all	
	level thread reInitializeDevDvarsOnMigration();
#/
}

exploder_load( trigger )
{
	level endon( "killexplodertridgers" + trigger.script_exploder );
	trigger waittill( "trigger" );
	if ( isdefined( trigger.script_chance ) && randomfloat( 1 ) > trigger.script_chance )
	{
		if ( isdefined( trigger.script_delay ) )
			wait trigger.script_delay;
		else
			wait 4;
		level thread exploder_load( trigger );
		return;
	}
	exploder( trigger.script_exploder );
	level notify( "killexplodertridgers" + trigger.script_exploder );
}


setupExploders()
{
	// Hide exploder models.
	ents = getentarray( "script_brushmodel", "classname" );
	smodels = getentarray( "script_model", "classname" );
	for ( i = 0;i < smodels.size;i ++ )
		ents[ ents.size ] = smodels[ i ];

	for ( i = 0;i < ents.size;i ++ )
	{
		if ( isdefined( ents[ i ].script_prefab_exploder ) )
			ents[ i ].script_exploder = ents[ i ].script_prefab_exploder;

		if ( isdefined( ents[ i ].script_exploder ) )
		{
			if ( ( ents[ i ].model == "fx" ) && ( ( !isdefined( ents[ i ].targetname ) ) || ( ents[ i ].targetname != "exploderchunk" ) ) )
				ents[ i ] hide();
			else if ( ( isdefined( ents[ i ].targetname ) ) && ( ents[ i ].targetname == "exploder" ) )
			{
				ents[ i ] hide();
				ents[ i ] notsolid();
				//if ( isdefined( ents[ i ].script_disconnectpaths ) )
					//ents[ i ] connectpaths();
			}
			else if ( ( isdefined( ents[ i ].targetname ) ) && ( ents[ i ].targetname == "exploderchunk" ) )
			{
				ents[ i ] hide();
				ents[ i ] notsolid();
				//if ( isdefined( ents[ i ].spawnflags ) && ( ents[ i ].spawnflags & 1 ) )
					//ents[ i ] connectpaths();
			}
		}
	}

	script_exploders = [];

	potentialExploders = getentarray( "script_brushmodel", "classname" );
	for ( i = 0;i < potentialExploders.size;i ++ )
	{
		if ( isdefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;
			
		if ( isdefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}

	potentialExploders = getentarray( "script_model", "classname" );
	for ( i = 0;i < potentialExploders.size;i ++ )
	{
		if ( isdefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( isdefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}

	potentialExploders = getentarray( "item_health", "classname" );
	for ( i = 0;i < potentialExploders.size;i ++ )
	{
		if ( isdefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( isdefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}
	
	if ( !isdefined( level.createFXent ) )
		level.createFXent = [];
	
	acceptableTargetnames = [];
	acceptableTargetnames[ "exploderchunk visible" ] = true;
	acceptableTargetnames[ "exploderchunk" ] = true;
	acceptableTargetnames[ "exploder" ] = true;
	
	for ( i = 0; i < script_exploders.size; i ++ )
	{
		exploder = script_exploders[ i ];
		ent = createExploder( exploder.script_fxid );
		ent.v = [];
		ent.v[ "origin" ] = exploder.origin;
		ent.v[ "angles" ] = exploder.angles;
		ent.v[ "delay" ] = exploder.script_delay;
		ent.v[ "firefx" ] = exploder.script_firefx;
		ent.v[ "firefxdelay" ] = exploder.script_firefxdelay;
		ent.v[ "firefxsound" ] = exploder.script_firefxsound;
		ent.v[ "firefxtimeout" ] = exploder.script_firefxtimeout;
		ent.v[ "earthquake" ] = exploder.script_earthquake;
		ent.v[ "damage" ] = exploder.script_damage;
		ent.v[ "damage_radius" ] = exploder.script_radius;
		ent.v[ "soundalias" ] = exploder.script_soundalias;
		ent.v[ "repeat" ] = exploder.script_repeat;
		ent.v[ "delay_min" ] = exploder.script_delay_min;
		ent.v[ "delay_max" ] = exploder.script_delay_max;
		ent.v[ "target" ] = exploder.target;
		ent.v[ "ender" ] = exploder.script_ender;
		ent.v[ "type" ] = "exploder";
// 		ent.v[ "worldfx" ] = true;
		if ( !isdefined( exploder.script_fxid ) )
			ent.v[ "fxid" ] = "No FX";
		else
			ent.v[ "fxid" ] = exploder.script_fxid;
		ent.v[ "exploder" ] = exploder.script_exploder;
		assertEx( isdefined( exploder.script_exploder ), "Exploder at origin " + exploder.origin + " has no script_exploder" );

		if ( !isdefined( ent.v[ "delay" ] ) )
			ent.v[ "delay" ] = 0;
			
		if ( isdefined( exploder.target ) )
		{
			org = getent( ent.v[ "target" ], "targetname" ).origin;
			ent.v[ "angles" ] = vectortoangles( org - ent.v[ "origin" ] );
// 			forward = anglestoforward( angles );
// 			up = anglestoup( angles );
		}
			
		// this basically determines if its a brush / model exploder or not
		if ( exploder.classname == "script_brushmodel" || isdefined( exploder.model ) )
		{
			ent.model = exploder;
			ent.model.disconnect_paths = exploder.script_disconnectpaths;
		}
		
		if ( isdefined( exploder.targetname ) && isdefined( acceptableTargetnames[ exploder.targetname ] ) )
			ent.v[ "exploder_type" ] = exploder.targetname;
		else
			ent.v[ "exploder_type" ] = "normal";
		
		ent common_scripts\_createfx::post_entity_creation_function();
	}
}

lanterns()
{
	if (!isdefined(level._effect["lantern_light"]))
		level._effect["lantern_light"]	= loadfx("fx/props/glow_latern");
		
	loopfx("lantern_light", self.origin, 0.3, self.origin + (0,0,1));
}

setupDestructibleKillCamEnts()
{
	// TODO: this needs to be done in code
	
	destructible_vehicles = GetEntArray( "scriptable_destructible_vehicle", "targetname" );
	foreach( dest in destructible_vehicles )
	{
		bulletStart = dest.origin + ( 0, 0, 5 );
		bulletEnd = ( dest.origin + ( 0, 0, 128 ) );
		result = BulletTrace( bulletStart, bulletEnd, false, dest );
		dest.killCamEnt = Spawn( "script_model", result[ "position" ] );
		dest.killCamEnt.targetname = "killCamEnt_destructible_vehicle";
		dest.killCamEnt SetScriptMoverKillCam( "explosive" );
		dest thread deleteDestructibleKillCamEnt();
	}

// Not needed anymore?
//	destructible_toys = GetEntArray( "destructible_toy", "targetname" );
//	foreach( dest in destructible_toys )
//	{
//		bulletStart = dest.origin + ( 0, 0, 5 );
//		bulletEnd = ( dest.origin + ( 0, 0, 128 ) );
//		result = BulletTrace( bulletStart, bulletEnd, false, dest );
//		dest.killCamEnt = Spawn( "script_model", result[ "position" ] );
//		dest.killCamEnt.targetname = "killCamEnt_destructible_toy";
//		dest.killCamEnt SetScriptMoverKillCam( "explosive" );
//		dest thread deleteDestructibleKillCamEnt();
//	}
//
	explodable_barrels = GetEntArray( "scriptable_destructible_barrel", "targetname" );
	foreach( dest in explodable_barrels )
	{
		bulletStart = dest.origin + ( 0, 0, 5 );
		bulletEnd = ( dest.origin + ( 0, 0, 128 ) );
		result = BulletTrace( bulletStart, bulletEnd, false, dest );
		dest.killCamEnt = Spawn( "script_model", result[ "position" ] );
		dest.killCamEnt.targetname = "killCamEnt_explodable_barrel";
		dest.killCamEnt SetScriptMoverKillCam( "explosive" );
		dest thread deleteDestructibleKillCamEnt();
	}

	// ADD MORE DESTRUCTIBLES HERE IF APPLICABLE
}

deleteDestructibleKillCamEnt()
{
	level endon( "game_ended" );

	killCamEnt = self.killCamEnt;
	killCamEnt endon( "death" );

	self waittill( "death" );

	wait( 10 );
	if( IsDefined( killCamEnt ) )
		killCamEnt delete();
}
