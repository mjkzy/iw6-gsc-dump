#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_trophy_system;

kNineBangMaxTicks = 5;
kNineBangRadius = 512;
kNineBangEffectTime = 8.0;
kNineBangCookInterval = 875;	// 3.5s / 4 - using priming time from gdt + 1?

attachmentGroup( attachmentName )
{
	if ( is_aliens() )
		return tableLookup( "mp/alien/alien_attachmentTable.csv", 4, attachmentName, 2 );
	else
		return tableLookup( "mp/attachmentTable.csv", 4, attachmentName, 2 );
}

init()
{
	level.scavenger_altmode = true;
	level.scavenger_secondary = true;
	
	// 0 is not valid
	level.maxPerPlayerExplosives = max( getIntProperty( "scr_maxPerPlayerExplosives", 2 ), 1 );
	level.riotShieldXPBullets = getIntProperty( "scr_riotShieldXPBullets", 15 );
	CreateThreatBiasGroup( "DogsDontAttack" );
	CreateThreatBiasGroup( "Dogs" );
	SetIgnoreMeGroup( "DogsDontAttack", "Dogs" );

	switch ( getIntProperty( "perk_scavengerMode", 0 ) )
	{
		case 1: // disable altmode
			level.scavenger_altmode = false;
			break;

		case 2: // disable secondary
			level.scavenger_secondary = false;
			break;
			
		case 3: // disable altmode and secondary
			level.scavenger_altmode = false;
			level.scavenger_secondary = false;
			break;		
	}
	gametype = GetDvar ("g_gametype");
	attachmentList = getAttachmentListBaseNames();
	attachmentList = alphabetize( attachmentList );
	
	// assigns weapons with stat numbers from 0-149
	
	max_weapon_num = 149;

	level.weaponList = [];
	level.weaponAttachments = [];
	
	statsTablename = "mp/statstable.csv";
	if ( is_aliens() )
	{
		statsTablename = "mp/alien/mode_string_tables/alien_statstable.csv";
	}
	
	for( weaponId = 0; weaponId <= max_weapon_num; weaponId++ )
	{
		weapon_name = tablelookup( statsTablename, 0, weaponId, 4 );
		
		if( weapon_name == "" )
			continue;
		
		if ( !isSubStr( tableLookup( statsTablename, 0, weaponId, 2 ), "weapon_" ) )
			continue;
		
		if ( IsSubStr( weapon_name, "iw5" ) || IsSubStr( weapon_name, "iw6" ) )
		{
			weaponTokens = StrTok( weapon_name, "_" );
			weapon_name = weaponTokens[0] + "_" + weaponTokens[1] + "_mp";
			
			level.weaponList[level.weaponList.size] = weapon_name ;
			continue;
		}
		else
			level.weaponList[level.weaponList.size] = weapon_name + "_mp";
		
		/#
		if ( getDvar( "scr_dump_weapon_assets" ) != "" )
		{
			printLn( "" );
			printLn( "// " + weapon_name + " real assets" );
			printLn( "weapon,mp/" + weapon_name + "_mp" );
		}
		#/

		
		attachmentNames = [];
		for ( innerLoopCount = 0; innerLoopCount < 10; innerLoopCount++ )
		{
			// generating attachment combinations
			if( gametype == "aliens" )
			{
				attachmentName = tablelookup( "mp/alien/mode_string_tables/alien_statstable.csv", 0, weaponId, innerLoopCount + 11 );
			}
			else
			{
				attachmentName = getWeaponAttachmentFromStats( weapon_name, innerLoopCount );
			}
			
			if( attachmentName == "" )
				break;
			
			attachmentNames[attachmentName] = true;
		}

		// generate an alphabetized attachment list
		attachments = [];
		foreach ( attachmentName in attachmentList )
		{
			if ( !isDefined( attachmentNames[attachmentName] ) )
				continue;
				
			level.weaponList[level.weaponList.size] = weapon_name + "_" + attachmentName + "_mp";
			attachments[attachments.size] = attachmentName;
			/#
			if ( getDvar( "scr_dump_weapon_assets" ) != "" )
				println( "weapon,mp/" + weapon_name + "_" + attachmentName + "_mp" );
			#/
		}

		attachmentCombos = [];
		for ( i = 0; i < (attachments.size - 1); i++ )
		{
			colIndex = tableLookupRowNum( "mp/attachmentCombos.csv", 0, attachments[i] );
			for ( j = i + 1; j < attachments.size; j++ )
			{
				if ( tableLookup( "mp/attachmentCombos.csv", 0, attachments[j], colIndex ) == "no" )
					continue;
					
				attachmentCombos[attachmentCombos.size] = attachments[i] + "_" + attachments[j];
			}
		}

		/#
		if ( getDvar( "scr_dump_weapon_assets" ) != "" && attachmentCombos.size )
			println( "// " + weapon_name + " virtual assets" );
		#/
		
		foreach ( combo in attachmentCombos )
		{
			/#
			if ( getDvar( "scr_dump_weapon_assets" ) != "" )
				println( "weapon,mp/" + weapon_name + "_" + combo + "_mp" );
			#/

			level.weaponList[level.weaponList.size] = weapon_name + "_" + combo + "_mp";
		}
		
	} 

	foreach ( weaponName in level.weaponList )
	{
		precacheItem( weaponName );
		
		/#
		if ( getDvar( "scr_dump_weapon_assets" ) != "" )
		{
			altWeapon = weaponAltWeaponName( weaponName );
			if ( altWeapon != "none" )
				println( "weapon,mp/" + altWeapon );				
		}
		#/
	}
	
	thread maps\mp\_flashgrenades::main();
	thread maps\mp\_entityheadicons::init();
	thread maps\mp\_empgrenade::init();
	initBombSquadData();
	
	maps\mp\_utility::buildAttachmentMaps();
	maps\mp\_utility::buildWeaponPerkMap();
	
	level._effect[ "weap_blink_friend" ] = LoadFX( "vfx/gameplay/mp/killstreaks/vfx_detonator_blink_cyan" );
	level._effect[ "weap_blink_enemy" ] = LoadFX( "vfx/gameplay/mp/killstreaks/vfx_detonator_blink_orange" );
	level._effect[ "emp_stun" ] = LoadFX( "vfx/gameplay/mp/equipment/vfx_emp_grenade" );
	level._effect[ "equipment_explode_big" ] = loadfx( "vfx/gameplay/mp/killstreaks/vfx_ims_explosion" );
	level._effect[ "equipment_smoke" ] = loadfx( "vfx/gameplay/mp/killstreaks/vfx_sg_damage_blacksmoke" );
	level._effect[ "equipment_sparks" ] = loadfx( "vfx/gameplay/mp/killstreaks/vfx_sentry_gun_explosion" );
	
	level.weaponConfigs = [];
	
	if( !IsDefined(level.weaponDropFunction) )
		level.weaponDropFunction = ::dropWeaponForDeath;
	
	claymoreDetectionConeAngle = 70;
	level.claymoreDetectionDot = cos( claymoreDetectionConeAngle );
	level.claymoreDetectionMinDist = 20;
	level.claymoreDetectionGracePeriod = .75;
	level.claymoreDetonateRadius = 192;
	
	level.mineDetectionGracePeriod = .3;
	level.mineDetectionRadius = 100;
	level.mineDetectionHeight = 20;
	level.mineDamageRadius = 256;
	level.mineDamageMin = 70;
	level.mineDamageMax = 210;
	level.mineDamageHalfHeight = 46;
	level.mineSelfDestructTime = 120;
	level.mine_launch = loadfx( "fx/impacts/bouncing_betty_launch_dirt" );
	level.mine_explode = loadfx( "fx/explosions/bouncing_betty_explosion" );
	
	config = SpawnStruct();
	config.model = "projectile_bouncing_betty_grenade";
	config.bombSquadModel = "projectile_bouncing_betty_grenade_bombsquad";
	config.mine_beacon["enemy"] = loadfx( "fx/misc/light_c4_blink" );
	config.mine_beacon["friendly"] = loadfx( "fx/misc/light_mine_blink_friendly" );
	config.mine_spin = loadfx( "fx/dust/bouncing_betty_swirl" );
	config.armTime = 2;
	config.onTriggeredSfx = "mine_betty_click";
	config.onLaunchSfx = "mine_betty_spin";
	config.onExplodeSfx = "grenade_explode_metal";
	config.launchHeight = 64;
	config.launchTime = 0.65;
	config.onTriggeredFunc = ::mineBounce;
	config.headIconOffset = 20;
	level.weaponConfigs["bouncingbetty_mp"] = config;
	level.weaponConfigs["alienbetty_mp"] = config;
	
	config = SpawnStruct();
	config.model = "weapon_motion_sensor";
	config.bombSquadModel = "weapon_motion_sensor_bombsquad";
	config.mine_beacon["enemy"] = getfx( "weap_blink_enemy" );
	config.mine_beacon["friendly"] = getfx( "weap_blink_friend" );
	config.mine_spin = loadfx( "fx/dust/bouncing_betty_swirl" );
	config.armTime = 2;
	config.onTriggeredSfx = "motion_click";
	config.onTriggeredFunc = ::mineSensorBounce;
	config.onLaunchSfx = "motion_spin";
	config.launchVfx = level.mine_launch;
	config.launchHeight = 64;
	config.launchTime = 0.65;
	config.onExplodeSfx = "motion_explode_default";
	config.onExplodeVfx = LoadFX( "vfx/gameplay/mp/equipment/vfx_motionsensor_exp" );
	config.headIconOffset = 25;
	config.markedDuration = 4.0;
	level.weaponConfigs["motion_sensor_mp"] = config;
	
	config = SpawnStruct();
	config.armingDelay = 1.5;
	config.detectionRadius = 232;	// slightly less than explosion radius
	config.detectionheight = 512;
	config.detectionGracePeriod = 1;
	config.headIconOffset = 20;
	config.killCamOffset = 12;
	level.weaponConfigs["proximity_explosive_mp"] = config;
	
	config = SpawnStruct();
	nineBangRadiusMax = 800; // straight from the gdt entry
	nineBangRadiusMin = 200; // straight from the gdt entry
	config.radius_max_sq = nineBangRadiusMax * nineBangRadiusMax;
	config.radius_min_sq = nineBangRadiusMin * nineBangRadiusMin;
	config.onExplodeVfx = LoadFx( "vfx/gameplay/mp/equipment/vfx_flashbang" );
	config.onExplodeSfx = "flashbang_explode_default";
	config.vfxRadius = 72;
	level.weaponConfigs["flash_grenade_mp"] = config;
	
	//level.empGrenadeExplode = loadfx("fx/explosions/emp_grenade");
	
	level.delayMineTime = 3.0;

	level.sentry_fire = loadfx( "fx/muzzleflashes/shotgunflash" );
	
	// this should move to _stinger.gsc
	level.stingerFXid = loadfx ("fx/explosions/aerial_explosion_large");

	// generating weapon type arrays which classifies the weapon as primary (back stow), pistol, or inventory (side pack stow)
	// using mp/statstable.csv's weapon grouping data ( numbering 0 - 149 )
	level.primary_weapon_array = [];
	level.side_arm_array = [];
	level.grenade_array = [];
	level.missile_array = [];
	level.inventory_array = [];
	level.mines = [];
		
	level._effect[ "equipment_explode" ] = LoadFX( "fx/explosions/sparks_a" );

	level._effect[ "sniperDustLarge" ] = LoadFX( "fx/dust/sniper_dust_kickup" );
	level._effect[ "sniperDustSmall" ] = LoadFX( "fx/dust/sniper_dust_kickup_minimal" );
	level._effect[ "sniperDustLargeSuppress" ] = LoadFX( "fx/dust/sniper_dust_kickup_accum_suppress" );
	level._effect[ "sniperDustSmallSuppress" ] = LoadFX( "fx/dust/sniper_dust_kickup_accum_supress_minimal" );

	level thread onPlayerConnect();
	
	level.c4explodethisframe = false;

	array_thread( getEntArray( "misc_turret", "classname" ), ::turret_monitorUse );
	
/#
	SetDevDvar( "scr_debug_throwingknife", 0 );
#/
//	thread dumpIt();
}


dumpIt()
{
	
	wait ( 5.0 );
	/#
	max_weapon_num = 149;

	for( weaponId = 0; weaponId <= max_weapon_num; weaponId++ )
	{
		weapon_name = tablelookup( "mp/statstable.csv", 0, weaponId, 4 );
		if( weapon_name == "" )
			continue;
	
		if ( !isSubStr( tableLookup( "mp/statsTable.csv", 0, weaponId, 2 ), "weapon_" ) )
			continue;
			
		if ( getDvar( "scr_dump_weapon_challenges" ) != "" )
		{
			/*
			sharpshooter
			marksman
			veteran
			expert
			master
			*/

			weaponLStringName = tableLookup( "mp/statsTable.csv", 0, weaponId, 3 );
			weaponRealName = tableLookupIString( "mp/statsTable.csv", 0, weaponId, 3 );

			prefix = "WEAPON_";
			weaponCapsName = getSubStr( weaponLStringName, prefix.size, weaponLStringName.size );

			weaponGroup = tableLookup( "mp/statsTable.csv", 0, weaponId, 2 );
			
			weaponGroupSuffix = getSubStr( weaponGroup, prefix.size, weaponGroup.size );

			/*
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_SHARPSHOOTER" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Sharpshooter" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_MARKSMAN" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Marksman" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_VETERAN" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Veteran" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_EXPERT" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Expert" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_Master" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Master" );
			*/
			
			iprintln( "cardtitle_" + weapon_name + "_sharpshooter,PLAYERCARDS_TITLE_" + weaponCapsName + "_SHARPSHOOTER,cardtitle_" + weaponGroupSuffix + "_sharpshooter,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_marksman,PLAYERCARDS_TITLE_" + weaponCapsName + "_MARKSMAN,cardtitle_" + weaponGroupSuffix + "_marksman,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_veteran,PLAYERCARDS_TITLE_" + weaponCapsName + "_VETERAN,cardtitle_" + weaponGroupSuffix + "_veteran,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_expert,PLAYERCARDS_TITLE_" + weaponCapsName + "_EXPERT,cardtitle_" + weaponGroupSuffix + "_expert,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_master,PLAYERCARDS_TITLE_" + weaponCapsName + "_MASTER,cardtitle_" + weaponGroupSuffix + "_master,1,1,1" );
			
			wait ( 0.05 );
		}
	}
	#/
}

initBombSquadData()
{
	level.bomb_squad = [];
	
	level.bomb_squad[ "c4_mp" ] = SpawnStruct();
	level.bomb_squad[ "c4_mp" ].model = "weapon_c4_iw6_bombsquad";
	level.bomb_squad[ "c4_mp" ].tag = "tag_origin";
	
	level.bomb_squad[ "claymore_mp" ] = SpawnStruct();
	level.bomb_squad[ "claymore_mp" ].model = "weapon_claymore_bombsquad";
	level.bomb_squad[ "claymore_mp" ].tag = "tag_origin";

	level.bomb_squad[ "frag_grenade_mp" ] = SpawnStruct();
	level.bomb_squad[ "frag_grenade_mp" ].model = "projectile_m67fraggrenade_bombsquad";
	level.bomb_squad[ "frag_grenade_mp" ].tag = "tag_weapon";

	level.bomb_squad[ "frag_grenade_short_mp" ] = SpawnStruct();
	level.bomb_squad[ "frag_grenade_short_mp" ].model = "projectile_m67fraggrenade_bombsquad";
	level.bomb_squad[ "frag_grenade_short_mp" ].tag = "tag_weapon";

	level.bomb_squad[ "semtex_mp" ] = SpawnStruct();
	level.bomb_squad[ "semtex_mp" ].model = "weapon_semtex_grenade_iw6_bombsquad";
	level.bomb_squad[ "semtex_mp" ].tag = "tag_origin";
	
	level.bomb_squad[ "mortar_shell_mp" ] = SpawnStruct();
	level.bomb_squad[ "mortar_shell_mp" ].model = "weapon_canister_bomb_bombsquad";
	level.bomb_squad[ "mortar_shell_mp" ].tag = "tag_weapon";

	level.bomb_squad[ "thermobaric_grenade_mp" ] = SpawnStruct();
	level.bomb_squad[ "thermobaric_grenade_mp" ].model = "weapon_thermobaric_grenade_bombsquad";
	level.bomb_squad[ "thermobaric_grenade_mp" ].tag = "tag_weapon";
	
	level.bomb_squad[ "proximity_explosive_mp" ] = SpawnStruct();
	level.bomb_squad[ "proximity_explosive_mp" ].model = "mp_proximity_explosive_bombsquad";
	level.bomb_squad[ "proximity_explosive_mp" ].tag = "tag_origin";
}

bombSquadWaiter_missileFire()
{
	self endon ( "disconnect" );
	
	for ( ;; )
	{
		missile = self waittill_missile_fire();
		
		if ( missile.weapon_name == "iw6_mk32_mp" )
			missile thread createBombSquadModel( "projectile_semtex_grenade_bombsquad", "tag_weapon", self );
	}
}


createBombSquadModel( modelName, tagName, owner )
{
	bombSquadModel = spawn( "script_model", (0,0,0) );
	bombSquadModel hide();
	wait ( 0.05 );
	
	if (!isDefined( self ) ) //grenade model may not be around if picked up
		return;
	
	self.bombSquadModel = bombSquadModel;
	
	bombSquadModel thread bombSquadVisibilityUpdater( owner );
	bombSquadModel setModel( modelName );
	bombSquadModel linkTo( self, tagName, (0,0,0), (0,0,0) );
	bombSquadModel SetContents( 0 );
	
	self waittill_any ( "death", "trap_death" );
	
	if ( isDefined(self.trigger) )
		self.trigger delete();
	
	bombSquadModel delete();
}


// Disable PVS visibility culling for this model.  This is useful for stuff with disabled depth-test, so they show up
// regardless of occlusion (e.g. objective2 effects).
DisableVisibilityCullingForClient( client )
{
	// Enabling HUD outlining on a model has the side-effect of preventing the engine from visibility-culling it.
	// This hack (ab)uses that feature to disable culling for other purposes.
	// Color '6' is the clear color, so the outline should be invisible.
	// * This should really be replaced with an engine function, but we're currently out of entity flags so that would
	//   be a much bigger change.
	self HudOutlineEnableForClient( client, 6, true );
}


// Re-enable visibility culling.
EnableVisibilityCullingForClient( client )
{
	self HudOutlineDisableForClient( client );
}


bombSquadVisibilityUpdater( owner )
{
	self endon ( "death" );
	self endon ( "trap_death" );

	if( !IsDefined(owner) )
	{
		return;
	}
	
	//teamname is the team of the player who owns this object, players on other teams may see this objects sitrep model if they can detect explosives
	teamname = owner.team;

	for ( ;; )
	{
		self hide();

		foreach ( player in level.players )
		{
			EnableVisibilityCullingForClient( player );

			if ( !( player _hasPerk( "specialty_detectexplosive" ) ) )
				continue;

			if ( level.teamBased )
			{
				if ( player.team == "spectator" || player.team == teamName )
					continue;
			}
			else
			{
				if ( isDefined( owner ) && player == owner )
					continue;
			}
			
			self ShowToPlayer( player );

			// The objective2 shader disables depth-test, but we need this to prevent the model from being visibility-
			// culled.
			self DisableVisibilityCullingForClient( player );
		}

		level waittill_any( "joined_team", "player_spawned", "changed_kit", "update_bombsquad" );
	}
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);

		player.hits = 0;

		maps\mp\gametypes\_gamelogic::setHasDoneCombat( player, false );

		player thread onPlayerSpawned();
		player thread bombSquadWaiter_missileFire();
		player thread watchMissileUsage();
		player thread sniperDustWatcher();
		//player thread watchHitByMissile();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		
		self.currentWeaponAtSpawn = self getCurrentWeapon(); // optimization so these threads we start don't have to call it.
		
		self.empEndTime = 0;
		self.concussionEndTime = 0;
		self.hits = 0;

		maps\mp\gametypes\_gamelogic::setHasDoneCombat( self, false );

		if( !isdefined( self.trackingWeaponName ) )
		{
			self.trackingWeaponName = "";
			self.trackingWeaponName = "none";
			self.trackingWeaponShots = 0;
			self.trackingWeaponKills = 0;
			self.trackingWeaponHits = 0;
			self.trackingWeaponHeadShots = 0;
			self.trackingWeaponDeaths = 0;
		}

		if( !is_aliens() )
		{
			self thread watchWeaponUsage();	
			self thread watchWeaponChange();
			self thread watchWeaponPerkUpdates();
			self thread watchSniperBoltActionKills();
		}

		self thread watchGrenadeUsage();
		// JC-ToDo: Retaining the stinger logic in case we ship a fire and forget launcher. Delete later.
//		self thread watchStingerUsage();
//		self thread watchJavelinUsage();
		self thread watchSentryUsage();
		
		if ( !is_aliens() )
			self thread maps\mp\gametypes\_class::trackRiotShield();
		self thread stanceRecoilAdjuster();

		self.lastHitTime = [];
		
		self.droppedDeathWeapon = undefined;
		self.tookWeaponFrom = [];
		
		self thread updateSavedLastWeapon();
		
		//self thread updateWeaponRank();
		
		self thread monitorMk32SemtexLauncher();
		
		self.currentWeaponAtSpawn = undefined;
		self.trophyRemainingAmmo = undefined;
	}
}

recordToggleScopeStates()
{
	self.pers[ "toggleScopeStates" ] = [];
	
	weapons = self GetWeaponsListPrimaries();
	foreach ( weap in weapons )
	{
		if ( weap == self.primaryWeapon || weap == self.secondaryWeapon )
		{
			attachments = GetWeaponAttachments( weap );
			foreach ( attachment in attachments )
			{
				if ( isToggleScope( attachment ) )
				{
					self.pers[ "toggleScopeStates" ][ weap ] = self GetHybridScopeState( weap );
					break;
				}
			}
		}
	}
}

updateToggleScopeState( weapon )
{
	if ( IsDefined( self.pers[ "toggleScopeStates" ] ) && IsDefined( self.pers[ "toggleScopeStates" ][ weapon ] ) )
	{
		self SetHybridScopeState( weapon, self.pers[ "toggleScopeStates" ][ weapon ] );
	}
}

isToggleScope( attachUnique )
{
	result = undefined;
	
	// The thermal is a hybrid scope on all weapon
	// classes except for snipers.
	if ( attachUnique == "thermalsniper" )
	{
		result = false;
	}
	else if ( attachUnique == "dlcweap02scope" )
	{
		result = true;	
	}
	else
	{
		attachment = attachmentMap_toBase( attachUnique );
		switch ( attachment )
		{
			case "hybrid":
			case "thermal":
			case "tracker":
				result = true;
				break;
			default:
				result = false;
				break;
		}
	}
	return result;
}

sniperDustWatcher()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	lastLargeShotFiredTime = undefined;
	
	for (;;)
	{
		self waittill( "weapon_fired" );
			
		// Do the prone check first, since getWeaponClass can be expensive
		if ( self GetStance() != "prone" )
			continue;
		
		if( getWeaponClass( self GetCurrentWeapon() ) != "weapon_sniper" )
			continue;
		
		playerForward = AnglesToForward( self.angles );
		//self thread drawLine( self.origin, ( self.origin + (0,0,10) ) + playerForward * 50, 10000, (1,0,0));
		
		if ( !isDefined(lastLargeShotFiredTime) || ( GetTime() - lastLargeShotFiredTime ) > 2000 )
	 	{
	 		playFX( level._effect[ "sniperDustLarge" ], ( self.origin + (0,0,10) ) + playerForward * 50 , playerForward );
	 		lastLargeShotFiredTime = GetTime();
	 	}
	 	else
	 	{
	 		playFX( level._effect[ "sniperDustLargeSuppress" ], ( self.origin + (0,0,10) ) + playerForward * 50 , playerForward );
		}
	}
}


WatchStingerUsage()
{
	self maps\mp\_stinger::StingerUsageLoop();
}

WatchJavelinUsage()
{
	self maps\mp\_javelin::JavelinUsageLoop();
}

weaponPerkUdpate( weaponNew, weaponOld, perksIgnore )
{
	perkAdd = undefined;
	if ( IsDefined( weaponNew ) && weaponNew != "none" )
	{
		weaponNew = getBaseWeaponName( weaponNew );
		perkAdd = weaponPerkMap( weaponNew );
		if ( IsDefined( perkAdd ) && !self _hasPerk( perkAdd ) )
		{
			self givePerk( perkAdd, false );
		}
	}
	
	if ( IsDefined( weaponOld ) && weaponOld != "none" )
	{
		weaponOld = getBaseWeaponName( weaponOld );
		perkRemove = weaponPerkMap( weaponOld );
		if	(	IsDefined( perkRemove )
		    &&	( !IsDefined( perkAdd ) || perkRemove != perkAdd )
		    &&	self _hasPerk( perkRemove )
		    &&	( !IsDefined( perksIgnore ) || !array_contains( perksIgnore, perkRemove ) )
			)
		{
			self _unsetPerk( perkRemove );
		}
	}
}

weaponAttachmentPerkUpdate( weaponNew, weaponOld )
{
	// Collect attachments
	newAttachments = undefined;
	oldAttachments = undefined;
	perksAdd = undefined;
	
	if ( IsDefined( weaponNew ) && weaponNew != "none" )
	{
		newAttachments = GetWeaponAttachments( weaponNew );
		// GetWeaponAttachments() returns undefined for weapon "none"
		if ( IsDefined( newAttachments ) && newAttachments.size > 0 )
		{
			// Collect perks to add by attachment and add them
			perksAdd = [];
			foreach ( newAttach in newAttachments )
			{
				perk = attachmentPerkMap( newAttach );
				if ( !IsDefined( perk ) )
					continue;
				
				perksAdd[ perksAdd.size ] = perk;
				if ( !self _hasPerk( perk ) )
				{
					self givePerk( perk, false );
				}
			}
		}
	}
	
	if ( IsDefined( weaponOld ) && weaponOld != "none" )
	{
		oldAttachments = GetWeaponAttachments( weaponOld );
		// GetWeaponAttachments() returns undefined for weapon "none" 
		if ( IsDefined( oldAttachments ) && oldAttachments.size > 0 )
		{
			// Remove perks from previous weapon if not on new weapon
			foreach( oldAttach in oldAttachments )
			{
				perk = attachmentPerkMap( oldAttach );
				if ( !IsDefined( perk ) )
					continue;
				
				if ( ( !IsDefined( perksAdd ) || !array_contains( perksAdd, perk ) ) && _hasPerk( perk ) )
				{
					self _unsetPerk( perk );
				}
			}
		}
	}
	
	return perksAdd;
}

watchWeaponPerkUpdates()
{
	self endon("death");
	self endon("disconnect");
	self endon("faux_spawn");
	
	weaponPrev = undefined;
	weaponName = self GetCurrentWeapon();
	
	attachPerksAdded = self weaponAttachmentPerkUpdate( weaponName, weaponPrev );
	self weaponPerkUdpate( weaponName, weaponPrev, attachPerksAdded );

	while ( 1 )
	{
		weaponPrev = weaponName;
		// Handle giveLoadout in case the user swaps loadouts
		// at the beginning of a match to another class with
		// the same weapon. In this case no "weapon_change"
		// notify would happen but giveLoadOut would scrub
		// the player's perks.
		self waittill_any( "weapon_change", "giveLoadout" );
		weaponName = self GetCurrentWeapon();
		
		attachPerksAdded = self weaponAttachmentPerkUpdate( weaponName, weaponPrev );
		self weaponPerkUdpate( weaponName, weaponPrev, attachPerksAdded );
	}
}

lethalStowed_clear()
{
	self.loadoutPerkEquipmentStowedAmmo = undefined;
	self.loadoutPerkEquipmentStowed = undefined;
}

hasUnderBarrelWeapon()
{
	result = false;
	
	weapons = self GetWeaponsListPrimaries();
	foreach ( weap in weapons )
	{
		if ( WeaponAltWeaponName( weap ) != "none" )
		{
			result = true;
			break;
		}
	}
	return result;
}

// Handle the player collecting a weapon that has an underbarrel while having lethals
// as part of their loadout. In this case the lethals are stowed until the player drops the weapon
	// This update function assumes the player's off hand is never changed outside of
	// giveLoadout() while the player has an underbarrel. Aliens does not run this logic
	// and horde mode does not give the player underbarrel weapons. - JC: 09/12/13
lethalStowed_updateLethalsOnWeaponChange()
{
	if ( self.loadoutPerkEquipment != "specialty_null" )
	{
		if ( self hasUnderBarrelWeapon() )
		{
			// Store the grenade info for when the weapon is dropped
			self.loadoutPerkEquipmentStowedAmmo = self GetWeaponAmmoClip( self.loadoutPerkEquipment );
			self.loadoutPerkEquipmentStowed = self.loadoutPerkEquipment;
			
			self TakeWeapon( self.loadoutPerkEquipment );
			self.loadoutPerkEquipment = "specialty_null";
			
			self givePerkEquipment( "specialty_null", false );
		}
	}
	else
	{
		if ( IsDefined( self.loadoutPerkEquipmentStowed ) && !self hasUnderBarrelWeapon() )
		{
			self givePerkEquipment( self.loadoutPerkEquipmentStowed, true );
			
			// Set the offhand ammo back to the stowed value
			self SetWeaponAmmoClip( self.loadoutPerkEquipmentStowed, self.loadoutPerkEquipmentStowedAmmo );
			self.loadoutPerkEquipment = self.loadoutPerkEquipmentStowed;	
			
			self lethalStowed_clear();
		}
	}
}

watchWeaponChange()
{
	self endon("death");
	self endon("disconnect");
	self endon("faux_spawn");
	
	self childthread watchStartWeaponChange();
	self.lastDroppableWeapon = self.currentWeaponAtSpawn;
	self.hitsThisMag = [];
	
	weaponName = self GetCurrentWeapon();
	
	if ( isCACPrimaryWeapon( weaponName ) && !isDefined( self.hitsThisMag[ weaponName ] ) )
		self.hitsThisMag[ weaponName ] = weaponClipSize( weaponName );
	
	while(1)
	{
		self waittill( "weapon_change", weaponName );
		
		if( weaponName == "none" )
			continue;
			
		if( weaponName == "briefcase_bomb_mp" || weaponName == "briefcase_bomb_defuse_mp" )
			continue;
		
		self lethalStowed_updateLethalsOnWeaponChange();
		
		if( isKillstreakWeapon( weaponName ) )
		{
			// 2013-10-08 wallace: this whole juggernaut check seems kind of fishy; I'm not sure why it unsets .changingWeapon in some cases but not others
			// added the isAirdropMarker() check because there was a glitch where you could be the juggernaut, pull out the airdrop marker, then scroll up/down the killstreaks
			//	this caused you to be able to use the care package more than once because changingWeapon was getting cleared even though it shouldn't in this case
			if( ( self isJuggernaut() || maps\mp\killstreaks\_killstreaks::isMiniGun(weaponName) || self GetCurrentWeapon() == "venomxgun_mp" ) && !maps\mp\killstreaks\_killstreaks::isAirdropMarker( weaponName ) )
			{
				if ( IsDefined( self.changingWeapon ) )
				{
					// insert this waittillframeend because killstreakUseWaiter may somehow miss the weapon_switch_started notify, 
					// and thus needs .changingweapon to know that we're switching to a KS weapon
					waittillframeend;
					self.changingWeapon = undefined;
				}
			}
			continue;
		}
		
		weaponTokens = StrTok( weaponName, "_" );

		if ( weaponTokens[0] == "alt" )
		{
			tmp = GetSubStr( weaponName, 4 );
			weaponName = tmp;
			weaponTokens = StrTok( weaponName, "_" );
		}
		else if ( weaponTokens[0] != "iw5" && weaponTokens[0] != "iw6" )
			weaponName = weaponTokens[0];

		if ( weaponName != "none" && weaponTokens[0] != "iw5" && weaponTokens[0] != "iw6" )
		{
			if ( isCACPrimaryWeapon( weaponName ) && !isDefined( self.hitsThisMag[ weaponName + "_mp" ] ) )
				self.hitsThisMag[ weaponName + "_mp" ] = weaponClipSize( weaponName + "_mp" );
		}
		else if ( weaponName != "none" && ( weaponTokens[0] == "iw5" || weaponTokens[0] == "iw6" ) )
		{
			if ( isCACPrimaryWeapon( weaponName ) && !isDefined( self.hitsThisMag[ weaponName ] ) )
				self.hitsThisMag[ weaponName ] = weaponClipSize( weaponName );	
		}
		
		self.changingWeapon = undefined;
		
		if ( weaponTokens[0] == "iw5" || weaponTokens[0] == "iw6" )
			self.lastDroppableWeapon = weaponName;
		else if ( weaponName != "none" && mayDropWeapon( weaponName + "_mp" ) )
			self.lastDroppableWeapon = weaponName + "_mp";

//		// we need to manage the weapon buffs here, if the new weapon has a buff then give, if not, take
//		if( IsDefined( self.class_num ) )
//		{
//			// since we stripped _mp off of the weapon name if it doesn't start with iw5, we need it back for this
//			if( weaponTokens[0] != "iw5" && weaponTokens[0] != "iw6" )
//				weaponName += "_mp";
//			
//			// weapon buffs
//			if( IsDefined( self.loadoutPrimaryBuff ) && self.loadoutPrimaryBuff != "specialty_null" )
//			{
//				if( weaponName == self.primaryWeapon && !( self _hasPerk( self.loadoutPrimaryBuff ) ) )
//				{
//					self givePerk( self.loadoutPrimaryBuff, true );
//				}
//				if( weaponName != self.primaryWeapon && self _hasPerk( self.loadoutPrimaryBuff ) )
//				{
//					self _unsetPerk( self.loadoutPrimaryBuff );
//				}
//			}
//
//			if( IsDefined( self.loadoutSecondaryBuff ) && self.loadoutSecondaryBuff != "specialty_null" )
//			{
//				if( weaponName == self.secondaryWeapon && !( self _hasPerk( self.loadoutSecondaryBuff ) ) )
//				{
//					self givePerk( self.loadoutSecondaryBuff, true );
//				}
//				if( weaponName != self.secondaryWeapon && self _hasPerk( self.loadoutSecondaryBuff ) )
//				{
//					// needed to add an extra check to make sure we didn't just get the buff from the primary weapon if they are the same buff
//					//	this fixes an issue where switching between weapons with the same buffs takes the buff away when you switch back to your primary
//					if( weaponName == self.primaryWeapon )
//					{
//						if( self.loadoutPrimaryBuff != self.loadoutSecondaryBuff )
//							self _unsetPerk( self.loadoutSecondaryBuff );
//					}
//					else
//						self _unsetPerk( self.loadoutSecondaryBuff );
//				}
//			}
//		}
	}
}

SCOPE_RECOIL_REDUCTION_MAX_KILLS	= 4;
SCOPE_RECOIL_REDUCTION_PER_KILL		= 3;

watchSniperBoltActionKills()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self thread watchSniperBoltActionKills_onDeath();
	
	if ( !IsDefined( self.pers[ "recoilReduceKills" ] ) )
		self.pers[ "recoilReduceKills" ] = 0;
	
	// Archived omnvars reset on spawn so adjust scope
	// state back to persistent value
	self SetClientOmnvar( "weap_sniper_display_state", self.pers[ "recoilReduceKills" ] );
	
	while ( 1 )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if ( isRecoilReducingWeapon( weapon ) )
		{
			kills = self.pers[ "recoilReduceKills" ] + 1;
			
			self.pers[ "recoilReduceKills" ] = Int( min( kills, SCOPE_RECOIL_REDUCTION_MAX_KILLS ) );
			
			self SetClientOmnvar( "weap_sniper_display_state", self.pers[ "recoilReduceKills" ] );
			
			if ( kills <= SCOPE_RECOIL_REDUCTION_MAX_KILLS )
			{
				stanceRecoilUpdate( self GetStance() );
			}
		}
	}
}

watchSniperBoltActionKills_onDeath()
{
	self notify( "watchSniperBoltActionKills_onDeath" );
	self endon( "watchSniperBoltActionKills_onDeath" );
	
	self endon( "disconnect" );
	
	self waittill( "death" );
	
	self.pers[ "recoilReduceKills" ] = 0;
}

isRecoilReducingWeapon( weapon )
{
	if ( !IsDefined( weapon ) || weapon == "none" )
		return false;
	
	result = false;
	// Substring checks much faster than looping over attachments
	if	(	IsSubStr( weapon, "l115a3scope" )
		||	IsSubStr( weapon, "l115a3vzscope" )
		||	IsSubStr( weapon, "usrscope" )
		||	IsSubStr( weapon, "usrvzscope" )
		)
	{
		result = true;
	}
	return result;
}

getRecoilReductionValue()
{
	if ( !IsDefined( self.pers[ "recoilReduceKills" ] ) )
		self.pers[ "recoilReduceKills" ] = 0;
	
	return self.pers[ "recoilReduceKills" ] * SCOPE_RECOIL_REDUCTION_PER_KILL;
}


watchStartWeaponChange()
{
	self endon("death");
	self endon("disconnect");
	self.changingWeapon = undefined;

	while(1)
	{
		self waittill( "weapon_switch_started", newWeapon );
		
		// need to make sure the weapon changes because changingWeapon can get stuck in limbo if the user double taps weapon change quickly
		//	this led to a care package glitch where they can get more than one because we're stuck in weapon changing limbo
		self thread makeSureWeaponChanges( self GetCurrentWeapon() );

		self.changingWeapon = newWeapon;
		
		// there's an issue where self.changingWeapon can get stuck on "none" if the owner captures but a full weapon_change doesn't happen
		if( newWeapon == "none" && IsDefined( self.isCapturingCrate ) && self.isCapturingCrate )
		{
			while( self.isCapturingCrate )
				wait( 0.05 );

			self.changingWeapon = undefined;
		}
	}
}

makeSureWeaponChanges( currentWeapon ) // self == player
{
	self endon( "weapon_switch_started" );
	self endon( "weapon_change" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	if( isKillstreakWeapon( currentWeapon ) )
		return;

	// wait for weapon_change to happen if it is going to, the longest drop time for a weapon doesn't exceed 1 second right now
	wait( 1.0 );

	// weapon_change didn't happen, clear the changingWeapon variable
	self.changingWeapon = undefined;
}

isHackWeapon( weapon )
{
	if ( weapon == "radar_mp" || weapon == "airstrike_mp" || weapon == "helicopter_mp" )
		return true;
	if ( weapon == "briefcase_bomb_mp" )
		return true;
	return false;
}


mayDropWeapon( weapon )
{
	if ( weapon == "none" )
		return false;
		
	if ( isSubStr( weapon, "ac130" ) )
		return false;
		
	if ( isSubStr( weapon, "uav" ) )
		return false;

	if ( isSubStr( weapon, "killstreak" ) )
		return false;

	invType = WeaponInventoryType( weapon );
	
	if ( invType != "primary" )
		return false;
	
	return true;
}

dropWeaponForDeath( attacker, sMeansOfDeath )
{
	if ( isDefined( level.blockWeaponDrops ) )
		return;
	
	if ( isdefined( self.droppedDeathWeapon ) )
		return;

	if ( level.inGracePeriod )
		return;
	
	weapon = self.lastDroppableWeapon;
	if ( !isdefined( weapon ) )
	{
		/#
		if ( getdvar("scr_dropdebug") == "1" )
			println( "didn't drop weapon: not defined" );
		#/
		return;
	}
	
	if ( weapon == "none" )
	{
		/#
		if ( getdvar("scr_dropdebug") == "1" )
			println( "didn't drop weapon: weapon == none" );
		#/
		return;
	}
	
	if ( !( self hasWeapon( weapon ) ) )
	{
		/#
		if ( getdvar("scr_dropdebug") == "1" )
			println( "didn't drop weapon: don't have it anymore (" + weapon + ")" );
		#/
		return;
	}
	
	// don't drop juggernaut weapons
	if( self isJuggernaut() )
		return;
	
	if ( IsDefined( level.gameModeMayDropWeapon ) && !(self [[ level.gameModeMayDropWeapon ]]( weapon )) )
		return;

	tokens = strTok( weapon, "_" );
	
	//passing weapon if the weapon is in alt mode.	
	if ( tokens[0] == "alt" )
	{
		for( i = 1; i < tokens.size; i++ )
		{
			if ( i > 1 )
				weapon += "_";
			
			weapon += tokens[i];
		}
	}
	
	if ( weapon != "iw6_riotshield_mp" )
	{
		if ( !(self AnyAmmoForWeaponModes( weapon )) )
		{
			return;
		}

		clipAmmoR = self GetWeaponAmmoClip( weapon, "right" );
		clipAmmoL = self GetWeaponAmmoClip( weapon, "left" );
		if ( !clipAmmoR && !clipAmmoL )
		{
			return;
		}
  
		stockAmmo = self GetWeaponAmmoStock( weapon );
		stockMax = WeaponMaxAmmo( weapon );
		if ( stockAmmo > stockMax )
			stockAmmo = stockMax;

		item = self dropItem( weapon );
		if ( !isDefined( item ) )
			return;
		
		// drop the weapon a little lower so it not obstructing the attacker viewmodel anim view
//		if ( sMeansOfDeath == "MOD_MELEE" )
//			item.origin = (item.origin[0], item.origin[1], item.origin[2] - 5);

		item ItemWeaponSetAmmo( clipAmmoR, stockAmmo, clipAmmoL );
	}
	else
	{
		item = self dropItem( weapon );	
		if ( !isDefined( item ) )
			return;
		item ItemWeaponSetAmmo( 1, 1, 0 );
	}

	self.droppedDeathWeapon = true;

	item.owner = self;
	item.ownersattacker = attacker;
	item.targetname = "dropped_weapon";

	item thread watchPickup();
	item thread deletePickupAfterAWhile();
}


detachIfAttached( model, baseTag )
{
	attachSize = self getAttachSize();
	
	for ( i = 0; i < attachSize; i++ )
	{
		attach = self getAttachModelName( i );
		
		if ( attach != model )
			continue;
		
		tag = self getAttachTagName( i );			
		self detach( model, tag );
		
		if ( tag != baseTag )
		{
			attachSize = self getAttachSize();
			
			for ( i = 0; i < attachSize; i++ )
			{
				tag = self getAttachTagName( i );
				
				if ( tag != baseTag )
					continue;
					
				model = self getAttachModelName( i );
				self detach( model, tag );
				
				break;
			}
		}		
		return true;
	}
	return false;
}


deletePickupAfterAWhile()
{
	self endon("death");
	
	wait 60;

	if ( !isDefined( self ) )
		return;

	self delete();
}

getItemWeaponName()
{
	classname = self.classname;
	assert( getsubstr( classname, 0, 7 ) == "weapon_" );
	weapname = getsubstr( classname, 7 );
	return weapname;
}

watchPickup()
{
	self endon("death");
	
	weapname = self getItemWeaponName();
		
	while(1)
	{
		self waittill( "trigger", player, droppedItem );
		
		if ( isdefined( droppedItem ) )
			break;
		// otherwise, player merely acquired ammo and didn't pick this up
	}
	
	/#
	if ( getdvar("scr_dropdebug") == "1" )
		println( "picked up weapon: " + weapname + ", " + isdefined( self.ownersattacker ) );
	#/

	assert( isdefined( player.tookWeaponFrom ) );
	
	// make sure the owner information on the dropped item is preserved
	droppedWeaponName = droppedItem getItemWeaponName();
	
	// storing what weapon they dropped, primary or secondary, just so we can use this information later if needed
	if( IsDefined( player.primaryWeapon ) && player.primaryWeapon == droppedWeaponName )
		player.primaryWeapon = weapname;
	if( IsDefined( player.secondaryWeapon ) && player.secondaryWeapon == droppedWeaponName )
		player.secondaryWeapon = weapname;

	if ( isdefined( player.tookWeaponFrom[ droppedWeaponName ] ) )
	{
		droppedItem.owner = player.tookWeaponFrom[ droppedWeaponName ];
		droppedItem.ownersattacker = player;
		player.tookWeaponFrom[ droppedWeaponName ] = undefined;
	}
	droppedItem.targetname = "dropped_weapon";
	droppedItem thread watchPickup();
	
	// take owner information from self and put it onto player
	if ( isdefined( self.ownersattacker ) && self.ownersattacker == player )
	{
		player.tookWeaponFrom[ weapname ] = self.owner;
	}
	else
	{
		player.tookWeaponFrom[ weapname ] = undefined;
	}
}

itemRemoveAmmoFromAltModes()
{
	origweapname = self getItemWeaponName();
	
	curweapname = weaponAltWeaponName( origweapname );
	
	altindex = 1;
	while ( curweapname != "none" && curweapname != origweapname )
	{
		self itemWeaponSetAmmo( 0, 0, 0, altindex );
		curweapname = weaponAltWeaponName( curweapname );
		altindex++;
	}
}

handleScavengerBagPickup( scrPlayer )
{
	self endon( "death" );
	level endon ( "game_ended" );

	assert( isDefined( scrPlayer ) );

	// Wait for the pickup to happen
	self waittill( "scavenger", player );
	assert( isDefined ( player ) );

	player notify( "scavenger_pickup" );
		
	scavengerGiveAmmo( player );
	
	player maps\mp\gametypes\_damagefeedback::hudIconType( "scavenger" );
}

scavengerGiveAmmo( player )
{
	offhandWeapons = player GetWeaponsListOffhands();
	foreach ( offhand in offhandWeapons )
	{
		if ( !isThrowingKnife( offhand ) )
			continue;
		
		knifeMax = ter_op( player _hasPerk( "specialty_extra_deadly" ), 2, 1 );
		knifeCurr = player GetWeaponAmmoClip( offhand );
		
		if ( knifeCurr + 1 <= knifeMax )
		{
			player SetWeaponAmmoClip( offhand, knifeCurr + 1 );
		}
	}

	primaryWeapons = player GetWeaponsListPrimaries();	
	foreach ( primary in primaryWeapons )
	{
		if ( !isCACPrimaryWeapon( primary ) && !level.scavenger_secondary )
			continue;
		
		if ( IsSubStr( primary, "alt_" ) && IsSubStr( primary, "_gl" ) )
			continue;
		
		//MW3 Scavenger no longer refills explosives
		if ( getWeaponClass( primary ) == "weapon_projectile" )
			continue;
		
		// Ensure that the special weapon for mp_dome_ns does not get an ammo refill
		if ( primary == "venomxgun_mp" )
			continue;
		
		currentStockAmmo = player GetWeaponAmmoStock( primary );
		addStockAmmo	 = WeaponClipSize( primary );
		
		player SetWeaponAmmoStock( primary, currentStockAmmo + addStockAmmo );
	}
}

dropScavengerForDeath( attacker )
{
	if ( level.inGracePeriod )
		return;
	
 	if( !isDefined( attacker ) )
 		return;

 	if( attacker == self )
 		return;

	dropBag = self DropScavengerBag( "scavenger_bag_mp" );	
	dropBag thread handleScavengerBagPickup( self );

	if ( IsDefined( level.bot_funcs["bots_add_scavenger_bag"] ) )
		[[ level.bot_funcs["bots_add_scavenger_bag"] ]]( dropBag );
}

setWeaponStat( name, incValue, statName )
{
	self maps\mp\gametypes\_gamelogic::setWeaponStat(  name, incValue, statName );
}

watchWeaponUsage( weaponHand )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );
	level endon ( "game_ended" );
	
	if( IsAI(self) )
	{
		return;
	}
	
	for ( ;; )
	{	
		self waittill ( "weapon_fired", weaponName );
		
		// JC-10/15/13: "weapon_fired" does not return the alt weapon in
		// the case of an underbarrel. Grab the current weapon to handle
		// this case.
		weaponName = self GetCurrentWeapon();
		
		maps\mp\gametypes\_gamelogic::setHasDoneCombat( self, true );
		
		self.lastShotFiredTime = GetTime();

		if ( !isCACPrimaryWeapon( weaponName ) && !isCACSecondaryWeapon( weaponName ) )
			continue;
		
		if ( isDefined( self.hitsThisMag[ weaponName ] ) )
			self thread updateMagShots( weaponName );
			
		totalShots = self maps\mp\gametypes\_persistence::statGetBuffered( "totalShots" ) + 1;
		hits = self maps\mp\gametypes\_persistence::statGetBuffered( "hits" );
		
		assert( totalShots > 0 );
		accuracy = Clamp( float( hits ) / float( totalShots ), 0.0, 1.0 ) * 10000.0;
		
		if ( !IsSquadsMode() )
		{
			self maps\mp\gametypes\_persistence::statSetBuffered( "totalShots", totalShots );
			self maps\mp\gametypes\_persistence::statSetBuffered( "accuracy", int( accuracy ) );		
			self maps\mp\gametypes\_persistence::statSetBuffered( "misses", int( totalShots - hits ) );
		}
		
		if ( isDefined( self.lastStandParams ) && self.lastStandParams.lastStandStartTime == GetTime() )
	 	{
	 		self.hits = 0;
	 		return;
	 	}
	 	
	 	shotsFired = 1;
	 	self setWeaponStat( weaponName , shotsFired, "shots" );
	 	self setWeaponStat( weaponName , self.hits, "hits");
	 	
	 	self.hits = 0;
	}
}

updateMagShots( weaponName )
{
	if ( !is_aliens() )
	{
		updateMagShots_regularMP( weaponName );
	}
}

updateMagShots_regularMP( weaponName )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "updateMagShots_" + weaponName );
	
	self.hitsThisMag[ weaponName ]--;
	
	wait ( 0.05 );
	
	self.hitsThisMag[ weaponName ] = weaponClipSize( weaponName );
}

checkHitsThisMag( weaponName )
{
	if ( !is_aliens() )
	{
		checkHitsThisMag_regularMP( weaponName );
	}
}

checkHitsThisMag_regularMP( weaponName )
{
	self endon ( "death" );
	self endon ( "disconnect" );

	self notify ( "updateMagShots_" + weaponName );
	waittillframeend;
	
	if ( isDefined( self.hitsThisMag[ weaponName ] ) && self.hitsThisMag[ weaponName ] == 0 )
	{
		weaponClass = getWeaponClass( weaponName );
		
		maps\mp\gametypes\_missions::genericChallenge( weaponClass );

		self.hitsThisMag[ weaponName ] = weaponClipSize( weaponName );
	}	
}


checkHit( weaponName, victim )
{
	self endon ( "disconnect" );
	
	if( isStrStart( weaponName, "alt_" ) )
	{
		attachments = getWeaponAttachmentsBaseNames( weaponName );
		
		if ( array_contains( attachments, "shotgun" ) || array_contains( attachments, "gl" ) )
		{
			self.hits = 1;
		}
		else
		{
			weaponName = GetSubStr( weaponName, 4 );
		}
	}

	if ( !maps\mp\gametypes\_weapons::isPrimaryWeapon( weaponName ) && !maps\mp\gametypes\_weapons::isSideArm( weaponName ) )
		return;

	if ( self MeleeButtonPressed() && weaponName != "iw6_knifeonly_mp" && weaponName != "iw6_knifeonlyfast_mp" )
		return;
		
	switch ( WeaponClass( weaponName ) )
	{
		case "rifle":
		case "pistol":
		case "mg":
		case "smg":
		case "sniper":
			self.hits++;
			break;
		case "spread":
			self.hits = 1;
			break;
		default:
			break;
	}
	
	if ( isRiotShield( weaponName ) || weaponName == "iw6_knifeonly_mp" || weaponName == "iw6_knifeonlyfast_mp" )
	{
		self thread maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName( weaponName, self.hits, "hits" );
		self.hits = 0;
	}
	
	// sometimes the "weapon_fired" notify happens after we hit the guy...
	waittillframeend;

	if ( isDefined( self.hitsThisMag[ weaponName ] ) )
		self thread checkHitsThisMag( weaponName );

	if ( !isDefined( self.lastHitTime[ weaponName ] ) )
		self.lastHitTime[ weaponName ] = 0;
		
	// already hit with this weapon on this frame
	if ( self.lastHitTime[ weaponName ] == GetTime() )
		return;

	self.lastHitTime[ weaponName ] = GetTime();
	
	if ( !IsSquadsMode() )
	{
		totalShots = self maps\mp\gametypes\_persistence::statGetBuffered( "totalShots" );		
		hits = self maps\mp\gametypes\_persistence::statGetBuffered( "hits" ) + 1;
	
		if ( hits <= totalShots )
		{
			self maps\mp\gametypes\_persistence::statSetBuffered( "hits", hits );
			self maps\mp\gametypes\_persistence::statSetBuffered( "misses", int(totalShots - hits) );
			
			// defensive clamping to make sure the values stay within 100%, this was done in watchWeaponUsage() but not here so we're doing it here to to be consistent
			accuracy = Clamp( float( hits ) / float( totalShots ), 0.0, 1.0 ) * 10000.0;
			self maps\mp\gametypes\_persistence::statSetBuffered( "accuracy", int( accuracy ) );
		}
	}
}


attackerCanDamageItem( attacker, itemOwner )
{
	return friendlyFireCheck( itemOwner, attacker );
}

// returns true if damage should be done to the item given its owner and the attacker
friendlyFireCheck( owner, attacker, forcedFriendlyFireRule )
{
	if ( !isdefined( owner ) )// owner has disconnected? allow it
		return true;

	if ( !level.teamBased )// not a team based mode? allow it
		return true;

	attackerTeam = attacker.team;

	friendlyFireRule = level.friendlyfire;
	if ( isdefined( forcedFriendlyFireRule ) )
		friendlyFireRule = forcedFriendlyFireRule;

	if ( friendlyFireRule != 0 )// friendly fire is on? allow it
		return true;

	if ( attacker == owner )
	{
		// in alien, owner cannot attack his own items
		// other MP modes, owner may attack his own items
		return ( !is_aliens() );
	}

	if ( !isdefined( attackerTeam ) )// attacker not on a team? allow it
		return true;

	if ( attackerTeam != owner.team )// attacker not on the same team as the owner? allow it
		return true;

	return false;// disallow it
}

watchGrenadeUsage()
{
	self notify( "watchGrenadeUsage" );
	self endon( "watchGrenadeUsage" );
	
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );

	self.throwingGrenade = undefined;
	self.gotPullbackNotify = false;

	if ( getIntProperty( "scr_deleteexplosivesonspawn", 1 ) == 1 )
	{
		if ( IsDefined( self.dont_delete_grenades_on_next_spawn ) )
		{
			self.dont_delete_grenades_on_next_spawn = undefined;
		}
		else
		{
			self delete_all_grenades();
		}
	}
	else if ( !IsDefined( self.plantedLethalEquip ) )
	{
		// since the player can only have one of any type of lethal
		// let's just keep one array
		self.plantedLethalEquip = [];
		self.plantedTacticalEquip = [];
	}
	
	// this needs to be independent of grenadeTracking because there's no pullback for throwbacks
	self thread watchForThrowbacks();

	while( true )
	{
		self waittill( "grenade_pullback", weaponName );
	
		if( !is_aliens() )
		{
			self setWeaponStat( weaponName, 1, "shots" );	
		}	
		
		maps\mp\gametypes\_gamelogic::setHasDoneCombat( self, true );
		
		self thread watchOffhandCancel();

		self.throwingGrenade = weaponName;
		self.gotPullbackNotify = true;
		
		if ( weaponName == "c4_mp" )
			self thread beginC4Tracking();

		self beginGrenadeTracking();
			
		self.throwingGrenade = undefined;
	}
}

beginGrenadeTracking()
{
	self endon( "offhand_end" );
	self endon( "weapon_change" );

	startTime = GetTime();

	grenade = self waittill_grenade_fire();
	if( !IsDefined( grenade ) )
		return;
	if( !IsDefined( grenade.weapon_name ) )
		return;
	
	self.changingWeapon = undefined;

	if( IsDefined( level.bomb_squad[ grenade.weapon_name ] ) )
		grenade thread createBombSquadModel( level.bomb_squad[ grenade.weapon_name ].model, level.bomb_squad[ grenade.weapon_name ].tag, self );
	
	switch( grenade.weapon_name )
	{
		case "frag_grenade_mp":
		case "thermobaric_grenade_mp":
			if( GetTime() - startTime > 1000 )
				grenade.isCooked = true;
			grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
			grenade.originalOwner = self;
			break;
		case "mortar_shell_mp":
		case "iw6_aliendlc22_mp": //pipe bomb
		case "iw6_aliendlc43_mp": //cortex grenade
			grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
			grenade.originalOwner = self;
			break;
		case "semtex_mp":
		case "aliensemtex_mp":
			self thread semtexUsed( grenade );
			break;
		case "c4_mp":
			self thread c4Used( grenade );
			break;
		case "proximity_explosive_mp":
			self thread proximityExplosiveUsed( grenade );
			break;
		case "flash_grenade_mp":
			cookTime = GetTime() - startTime;
			grenade.nineBangTicks = 1;
			if( cookTime > 1000 )
			{
				grenade.isCooked = true;
				grenade.nineBangTicks += min( int( cookTime / kNineBangCookInterval ), kNineBangMaxTicks );
			}
			grenade thread nineBangExplodeWaiter();
			break;
		case "smoke_grenade_mp":
		case "smoke_grenadejugg_mp":
			grenade thread watchSmokeExplode();
			break;
		case "trophy_mp":
		case "alientrophy_mp":
			self thread trophyUsed( grenade );
			break;
		case "claymore_mp":
		case "alienclaymore_mp":
			self thread claymoreUsed( grenade );
			break;
		case "bouncingbetty_mp":
		case "alienbetty_mp":
			self thread mineUsed( grenade, ::spawnMine );
			break;
		case "motion_sensor_mp":
			self thread mineUsed( grenade, ::spawnMotionSensor );
			break;
		case "throwingknife_mp":
		case "throwingknifejugg_mp":
			level thread throwingKnifeUsed( self, grenade, grenade.weapon_name );
				break;
	}
}


throwingKnifeUsed( owner, grenade, weapon_name )
{
	level endon( "game_ended" );
	
	grenade waittill( "missile_stuck", stuckTo );
	
	grenade endon( "death" );
	
	grenade MakeUnusable();
	
	knifeTrigger = Spawn( "trigger_radius", grenade.origin, 0, 64, 64 );
	knifeTrigger EnableLinkTo();
	knifeTrigger LinkTo( grenade );
	knifeTrigger.targetname = "dropped_knife";
	grenade.knife_trigger = knifeTrigger;
	
	grenade thread watchGrenadeDeath();
	
/#
	grenade thread drawDebugCylinder();
#/
	
	while( true )
	{
		waitframe();
		
		if ( !isDefined( knifeTrigger ) )
			return;
		
		knifeTrigger waittill( "trigger", player );
		
		if( !IsPlayer(player) || !isReallyAlive(player) )
			continue;
		
		if( !(player HasWeapon( weapon_name )) )
			continue;
		
		currentClipAmmo = player GetWeaponAmmoClip( weapon_name );
		
		// only refill if they have no throwing knives or they have the extra lethal perk, that way they can only have one unless using the perk
		player_has_extra_lethal_perk = player _hasPerk( "specialty_extra_deadly" );

		if( player_has_extra_lethal_perk && currentClipAmmo == 2 )
			continue;
		if( !player_has_extra_lethal_perk && currentClipAmmo == 1 )
			continue;
		
	 	player SetWeaponAmmoClip( weapon_name, currentClipAmmo + 1 );
	 	player thread maps\mp\gametypes\_damagefeedback::hudIconType( "throwingknife" );
	 	grenade delete();
		break;
	}
}

/#
drawDebugCylinder() // self == grenade
{
	self endon( "death" );
	while( true )
	{
		if( GetDvarInt( "scr_debug_throwingknife" ) > 0 )
		{
			Cylinder( self.origin, self.origin + ( 0, 0, 64 ), 64 );
		}
		wait( 0.05 );
	}
}
#/
	
watchGrenadeDeath() // self == grenade
{
	self waittill( "death" );
	if( IsDefined( self.knife_trigger ) )
		self.knife_trigger delete();
}

watchOffhandCancel()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );
	self endon( "grenade_fire" );

	self waittill( "offhand_end" );
	
	// if they cancel a grenade throw then we need to clear the changing weapon variable
	//	this fixes a nasty bug where you could cancel placing a trophy and not show the earning of any of your killstreaks until you died or swapped weapons
	//	the reason why we waittill offhand_end is because that will happen if you cancel or successfully throw/plant, unfortunately waittill weapon_change doesn't work
	//	we're ending on grenade_fire so if we successfully throw the grenade then we don't need to run this portion
	//	NOTE: c4 needs it's own thing to stay the same in beginC4Tracking()
	if( IsDefined( self.changingWeapon ) && self.changingWeapon != self GetCurrentWeapon() )
		self.changingWeapon = undefined;
}

watchSmokeExplode()	// self == smoke grenade
{
	level endon( "smokeTimesUp" );
	
	owner = self.owner;
	owner endon( "disconnect" );

	self waittill( "explode", position );

	smokeRadius = 128;
	smokeTime = 8;
	level thread waitSmokeTime( smokeTime, smokeRadius, position );

/#
	//maps\mp\killstreaks\_ac130::debug_circle( position, smokeRadius, smokeTime, ( 0, 0, 1 ) );
#/

	while( true )
	{
		if( !IsDefined( owner ) )
			break;

		foreach( player in level.players )
		{
			if( !IsDefined( player ) )
				continue;

			if( level.teamBased && player.team == owner.team )
				continue;

			if( DistanceSquared( player.origin, position ) < smokeRadius * smokeRadius )
				player.inPlayerSmokeScreen = owner;
			else
				player.inPlayerSmokeScreen = undefined;
		}

		wait( 0.05 );
	}
}

waitSmokeTime( smokeTime, smokeRadius, position )
{
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( smokeTime );
	level notify( "smokeTimesUp" );
	waittillframeend;

	foreach( player in level.players )
	{
		if( IsDefined( player ) )
		{
			player.inPlayerSmokeScreen = undefined;
		}
	}

}

// Brought over from _stinger.gsc. Very ugly function that
// handles climbing into killstreak global lists to get
// track-able targets
lockOnLaunchers_getTargetArray()
{
	targets = [];

	if ( level.teamBased )
	{
		if ( IsDefined( level.chopper ) && ( level.chopper.team != self.team || ( IsDefined( level.chopper.owner ) && level.chopper.owner == self ) ) )
			targets[ targets.size ] = level.chopper;

		if ( IsDefined( level.littleBirds ) )
		{
			foreach ( lb in level.littleBirds )
			{
				if ( IsDefined( lb ) && ( lb.team != self.team || ( IsDefined( lb.owner ) && lb.owner == self ) ) )
					targets[ targets.size ] = lb;
			}
		}
		
		if ( IsDefined( level.ballDrones ) )
		{
			foreach ( bd in level.ballDrones )
			{
				if ( IsDefined( bd ) && ( bd.team != self.team || ( IsDefined( bd.owner ) && bd.owner == self ) ) )
					targets[ targets.size ] = bd;
			}
		}
		
		if ( IsDefined( level.harriers ) )
		{
			foreach ( harrier in level.harriers )
			{
				if ( IsDefined( harrier ) && ( harrier.team != self.team || ( IsDefined( harrier.owner ) && harrier.owner == self ) ) )
					targets[ targets.size ] = harrier;
			}
		}
	}
	else
	{
		if ( IsDefined( level.chopper ) ) //check for teams IW5: ( level.chopper.owner != self )
			targets[ targets.size ] = level.chopper;
		
		if ( IsDefined( level.littleBirds ) )
		{
			foreach ( lb in level.littleBirds )
			{
				if ( !IsDefined( lb ) )
					continue;

				targets[ targets.size ] = lb;
			}
		}
		
		if ( IsDefined( level.ballDrones ) )
		{
			foreach ( bd in level.ballDrones )
			{
				if ( !IsDefined( bd ) )
					continue;
				
				targets[ targets.size ] = bd;
			}
		}
		
		if ( IsDefined( level.harriers ) )
		{
			foreach ( harrier in level.harriers )
			{
				if ( !IsDefined( harrier ) )
					continue;
				
				targets[ targets.size ] = harrier;
			}
		}
	}
	
	return targets;
}

watchMissileUsage()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		missile = self waittill_missile_fire();
		
		if ( isSubStr( missile.weapon_name, "gl_" ) )
		{
			missile.primaryWeapon = self getCurrentPrimaryWeapon();
			missile thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
		}
		
		switch ( missile.weapon_name )
		{
			case "at4_mp":
			case "iw5_smaw_mp":
			case "stinger_mp":
				level notify ( "stinger_fired", self, missile, self.stingerTarget );
//				self thread setAltSceneObj( missile, "tag_origin", 65 );
				break;
			case "remote_mortar_missile_mp":
			case "lasedStrike_missile_mp":
			case "javelin_mp":
				level notify ( "stinger_fired", self, missile, self.javelinTarget );
//				self thread setAltSceneObj( missile, "tag_origin", 65 );
				break;			
			default:
				break;
		}

		switch ( missile.weapon_name )
		{
			case "remote_mortar_missile_mp":	
			case "lasedStrike_missile_mp":
			case "ac130_105mm_mp":
			case "ac130_40mm_mp":
			case "remotemissile_projectile_mp":
			case "iw6_maaws_mp":
			case "iw6_panzerfaust3_mp":
				missile thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
			default:
				break;
		}
	}
}

watchHitByMissile()
{
	self endon( "disconnect" );
	
	//disabling this until we have a better spec for this feature
	while ( 1 )
	{
		self waittill( "hit_by_missile", attacker, missile, weaponName, impactPos, missileDir, impactNormal, partGroup, partName );
				
		if( !isDefined( attacker ) || !isDefined( missile ) )
			continue;
		
		//returning if the same team
		if( level.teamBased && self.team == attacker.team )
		{
			self CancelRocketCorpse( missile, impactPos, missileDir, impactNormal, partGroup, partName );
			continue;
		}
		
		//only rpg7 does this
		if( weaponName != "rpg_mp" )
		{
			self CancelRocketCorpse( missile, impactPos, missileDir, impactNormal, partGroup, partName );
			continue;
		}
		
		//1% chance of rocket corpse
		if ( RandomIntRange( 0,100 ) < 99 )
		{
			self CancelRocketCorpse( missile, impactPos, missileDir, impactNormal, partGroup, partName );
			continue;
		}
		
		drag_player_time_seconds 	= GetDvarFloat( "rocket_corpse_max_air_time", 0.5 );
		camera_offset_up 			= GetDvarFloat( "rocket_corpse_view_offset_up", 100 );
		camera_offset_forward 		= GetDvarFloat( "rocket_corpse_view_offset_forward", 35 );
		
		self.isRocketCorpse = true;
		self SetContents( 0 ); // This is needed for the single frame in between when the missile hits, when ClientEndFrame() is called by the code (which resets the contents) and when this notify finally runs and links the corpse to the missile

		durationMs = self SetRocketCorpse( true );
		durationSec = durationMs / 1000.0;
		
		self.killCamEnt = Spawn( "script_model", missile.origin );
		self.killCamEnt.angles = missile.angles;
		self.killCamEnt LinkTo( missile );
		self.killCamEnt SetScriptMoverKillCam( "rocket_corpse" );
		self.killCamEnt SetContents( 0 );

		self DoDamage( 1000, self.origin, attacker, missile );
		
		self.body = self ClonePlayer( durationMs );
		self.body.origin = missile.origin;
		self.body.angles = missile.angles;
		self.body.targetname = "player_corpse";
		self.body SetCorpseFalling( false );
		self.body EnableLinkTo();
		self.body LinkTo( missile );
		self.body SetContents( 0 );
		
		if ( !IsDefined( self.switching_teams ) )
			thread maps\mp\gametypes\_deathicons::addDeathicon( self.body, self, self.team, 5.0 );

		self PlayerHide();
		
		missile_up = VectorNormalize( AnglesToUp( missile.angles ) );
		missile_forward = VectorNormalize( AnglesToForward( missile.angles ) );
		eye_offset = ( missile_forward * camera_offset_up ) + ( missile_up * camera_offset_forward );
		eye_origin = missile.origin + eye_offset;
		
		eye_pos = spawn( "script_model", eye_origin );
		eye_pos SetModel( "tag_origin" );
		eye_pos.angles = VectorToAngles( missile.origin - eye_pos.origin );
		eye_pos LinkTo( missile );
		eye_pos SetContents( 0 );
		
		self CameraLinkTo( eye_pos, "tag_origin" );
		
		if ( drag_player_time_seconds > durationSec )
			drag_player_time_seconds = durationSec;
				
		value = missile waittill_notify_or_timeout_return( "death", drag_player_time_seconds );
				
		if ( IsDefined( value ) && value == "timeout" && IsDefined( missile ) )
			missile Detonate();
		
		self notify( "final_rocket_corpse_death" );
					
		self.body Unlink();
		self.body SetCorpseFalling( true );
		self.body StartRagdoll();

		eye_pos LinkTo( self.body );

		self.isRocketCorpse = undefined;
		
		self waittill( "death_delay_finished" );
		
		self CameraUnlink();
		self.killCamEnt Delete();

		eye_pos Delete();
	}
}


watchSentryUsage()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );

	for ( ;; )
	{
		self waittill( "sentry_placement_finished", sentry );
		
		self thread setAltSceneObj( sentry, "tag_flash", 65 );
	}
}

nineBangExplodeWaiter() // self == grenade
{
	self thread maps\mp\gametypes\_shellshock::endOnDeath();
	self endon( "end_explode" );

	self waittill( "explode", position );

	self thread doNineBang( position, self.owner, self.nineBangTicks );

	self nineBangDoEmpDamage( position, self.owner, self.nineBangTicks );
}

nineBangDoEmpDamage( position, player, numTicks )	// self == grenade
{
	// kMaxNineBangGrenadeTicks is actually one less than the max number
	// but also, the cook indicator only shows 4 slots
	if ( numTicks >= kNineBangMaxTicks || pitcherCheck( player, numTicks ) )
	{
		PlaySoundAtPos( position, "weap_emp_explode" );
		
		ents = getEMPDamageEnts( position, kNineBangRadius, false );

		foreach ( ent in ents )
		{
			if ( isDefined( ent.owner ) && !friendlyFireCheck( player, ent.owner ) )
				continue;
	
			ent notify( "emp_damage", self.owner, kNineBangEffectTime );
		}
	}
}

pitcherCheck( player, numTicks )
{	
	// If the player has strong arm equipped it will cut the cook time by about 50%
	// so the max ticks cannot stay at 5
	if ( player _hasPerk("specialty_pitcher") )
	{
		if ( numTicks >= 4 )
			return true;
	}
	
	return false;
}

// NOTE: prototyping nine bang
doNineBang( pos, attacker, ticks ) // self == grenade
{
	level endon( "game_ended" );
	
	// the weapon should still exist at this point, but it may not after the random waits
	config = level.weaponConfigs[ self.weapon_name ];
	
	wait( RandomFloatRange( 0.25, 0.5 ) );
	
	// the nine bang will go off N times and flash everything in the vacinity
	for( i = 1; i < ticks; i++ )
	{
		newPos = self getNineBangSubExplosionPos( pos, config.vfxRadius );
		playSoundAtPos( newPos, config.onExplodeSfx );
		PlayFX( config.onExplodeVfx, newPos );

		// get players within the radius
		foreach( player in level.players )
		{
			if( !isReallyAlive( player ) || player.sessionstate != "playing" )
				continue;
			
			// viewOrigin = player.origin + (0, 0, player GetPlayerViewHeight());
		
			viewOrigin = player GetEye();
			// first make sure they are within distance
			dist = DistanceSquared( pos, viewOrigin );
			if( dist > config.radius_max_sq )
				continue;
		
			// now make sure they can be hit by it
			if( !BulletTracePassed( pos, viewOrigin, false, player ) )
				continue;
		
			if ( dist <= config.radius_min_sq )
				percent_distance = 1.0;
			else
				percent_distance = 1.0 - ( dist - config.radius_min_sq ) / ( config.radius_max_sq - config.radius_min_sq );
		
			forward = AnglesToForward( player GetPlayerAngles() );
		
			toBlast = pos - viewOrigin;
			toBlast = VectorNormalize( toBlast );
		
			percent_angle = 0.5 * ( 1.0 + VectorDot( forward, toBlast ) );
		
			extra_duration = 1; // first blast is 1 sec, each after is 2 sec
			player notify( "flashbang", pos, percent_distance, percent_angle, attacker, extra_duration );
		}
		
		// also get killstreaks that the player pilots
		
		// 2013-07-19 wallace: let's not do emp damage on every sub explosion, it's kind of expensive
		// self nineBangDoEmpDamage( pos, attacker, ticks );

		wait( RandomFloatRange( 0.25, 0.5 ) );
	}
}

getNineBangSubExplosionPos( startPos, range )
{
	offset = ( RandomFloatRange( -1.0 * range, range ), RandomFloatRange( -1.0 * range, range ), 0 );
	newPos = startPos + offset;
	
	// make sure we don't spawn through walls
	trace = BulletTrace( startPos, newPos, false, self, false, false, false, false, false );
	if ( trace["fraction"] < 1 )
	{
		newPos = startPos + trace["fraction"] * offset;
	}
	
	return newPos;
}

beginC4Tracking()
{
	self notify( "beginC4Tracking" );
	self endon( "beginC4Tracking" );
	
	self endon( "death" );
	self endon( "disconnect" );

	self waittill_any( "grenade_fire", "weapon_change", "offhand_end" );
	
	// need to clear the changing weapon because it'll get stuck on c4_mp and player will stop spawning because we get locked in isChangingWeapon() loop when a killstreak is earned
	self.changingWeapon = undefined;
}

watchForThrowbacks()
{
	self endon( "death" );
	self endon( "disconnect" );

	while ( true )
	{
		self waittill( "grenade_fire", grenade, weapname );
		
		if ( self.gotPullbackNotify )
		{
			self.gotPullbackNotify = false;
			continue;
		}
		if ( !isSubStr( weapname, "frag_" ) && !isSubStr( weapname, "mortar_shell" ) )
			continue;

		// no grenade_pullback notify! we must have picked it up off the ground.
		grenade.threwBack = true;
		self thread incPlayerStat( "throwbacks", 1 );

		grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
		grenade.originalOwner = self;
	}
}


c4Used( grenade ) // self == player
{
	if( !isReallyAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	grenade thread onDetonateExplosive();
	
	self thread watchC4Detonation();
	self thread watchC4AltDetonation();

	if ( !self.plantedLethalEquip.size )
		self thread watchC4AltDetonate();

	grenade SetOtherEnt(self);
	grenade.activated = false;
	
	// track c4 as soon as it spawns. if there are too many c4's, clean them up first.
	self onLethalEquipmentPlanted( grenade );
	
	grenade thread maps\mp\gametypes\_shellshock::c4_earthQuake();
	grenade thread c4Activate();
	grenade thread c4Damage();
	grenade thread c4EMPDamage();
	grenade thread watchC4Stuck();
	
	level thread monitorDisownedEquipment( self, grenade );
}


movingPlatformDetonate( data )
{
	// this defaults to true
	if ( !IsDefined( data.lastTouchedPlatform )
	    || !IsDefined( data.lastTouchedPlatform.destroyExplosiveOnCollision ) 
	    || data.lastTouchedPlatform.destroyExplosiveOnCollision 
	   )
	{
		self notify ( "detonateExplosive" );
	}
}


watchC4Stuck() // self == c4
{
	self endon( "death" );

	self waittill( "missile_stuck", stuckTo ); //to spawn pickup trigger in the correct location
	
	self makeExplosiveUsable();
	self makeExplosiveTargetableByAI();
	self explosiveHandleMovers( stuckTo );
}

c4EMPDamage()
{
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "emp_damage", attacker, duration );

		self equipmentEmpStunVfx();

		self.disabled = true;
		self notify( "disabled" );

		wait( duration );

		self.disabled = undefined;
		self notify( "enabled" );
	}
}

proximityExplosiveUsed( grenade )
{
	if( !isReallyAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	grenade waittill( "missile_stuck", stuckTo );

	if( !isReallyAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	if ( !IsDefined( grenade.owner.team ) )
	{
		grenade delete();
		return;
	}
	
	// 2013-08-08 wallace - move the grenade down a little bit, but *NOT* flush with the ground, which will block the explosive
	// in a future game, we should have a tag_explode to control the position of the explosion so that planted ones use their tag_origin not to float off the ground
	upVec = AnglesToUp( grenade.angles );
	grenade.origin = grenade.origin - upVec;
	
	config = level.weaponConfigs[ grenade.weapon_name ];
	killCamEnt = Spawn( "script_model", grenade.origin + config.killCamOffset * upVec );
	killCamEnt SetScriptMoverKillCam( "explosive" );
	killCamEnt LinkTo( grenade );
	grenade.killCamEnt = killCamEnt;
	
	grenade explosiveHandleMovers( stuckTo );
	grenade makeExplosiveUsable();
	grenade makeExplosiveTargetableByAI();
	
	self onLethalEquipmentPlanted( grenade );

	grenade thread onDetonateExplosive();
	grenade thread c4Damage();
	grenade thread proximityExplosiveEMPStun();
	grenade thread proximityExplosiveTrigger( stuckTo );
	
	if( !is_aliens() )
	{
		grenade thread setClaymoreTeamHeadIcon( self.team, 20 );
	}
	
	level thread monitorDisownedEquipment( self, grenade );
}

proximityExplosiveTrigger( parent )
{
	self endon( "death" );
	self endon( "disabled" );
	
	config = level.weaponConfigs[ self.weapon_name ];
	
	//	arming time
	wait( config.armingDelay );
	
	self PlayLoopSound( "ied_explo_beeps" );
	self thread doBlinkingLight( "tag_fx" );

	startPositionForTrigger = self.origin * (1,1,0);
	halfHeight = config.detectionheight/2;
	usableHeight = self.origin[2] - halfHeight;
	startPositionForTrigger = startPositionForTrigger + (0,0,usableHeight);
	
	damagearea = Spawn( "trigger_radius", startPositionForTrigger, 0, config.detectionRadius, config.detectionheight );
	damagearea.owner = self;
	
	if ( IsDefined( parent ) )
	{
		damagearea EnableLinkTo();
		damagearea LinkTo( self );
	}
	
	self.damagearea = damagearea;
	self thread deleteOnDeath( damagearea );

	player = undefined;
	while ( true )
	{
		damagearea waittill( "trigger", player );
		
		if ( !isDefined( player ) )
			continue;

		if ( getdvarint( "scr_minesKillOwner" ) != 1 )
		{
			if ( isDefined( self.owner ) )
			{
				if ( player == self.owner )
					continue;
				if ( isdefined( player.owner ) && player.owner == self.owner )
					continue;
			}

			if ( !friendlyFireCheck( self.owner, player, 0 ) )
				continue;
		}
		
		if ( lengthsquared( player getEntityVelocity() ) < 10 )
			continue;

		if ( player damageConeTrace( self.origin, self ) > 0 )
			break;
	}

	self StopLoopSound( "ied_explo_beeps" );
	self PlaySound( "ied_warning" );
	
	self explosiveTrigger( player, config.detectionGracePeriod, "proxExplosive" );
	
	self notify( "detonateExplosive" );
}

proximityExplosiveEMPStun()
{
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "emp_damage", attacker, duration );
		
		// "sentry_explode_mp"
		self equipmentEmpStunVfx();

		self.disabled = true;
		self notify( "disabled" );
		
		self proximityExplosiveCleanup();

		wait( duration );
		
		if ( IsDefined( self ) )
		{
			self.disabled = undefined;
			self notify( "enabled" );
			
			parent = self GetLinkedParent();
			self thread proximityExplosiveTrigger( parent );
		}
	}
}

proximityExplosiveCleanup()
{
	self stopBlinkingLight();
	
	if ( IsDefined( self.damagearea ) )
	{
		self.damagearea Delete();
	}
}

setClaymoreTeamHeadIcon( team, offset )
{
	self endon( "death" );
	wait .05;
	if ( level.teamBased )
		self maps\mp\_entityheadicons::setTeamHeadIcon( team, ( 0, 0, offset ) );
	else if ( isDefined( self.owner ) )
		self maps\mp\_entityheadicons::setPlayerHeadIcon( self.owner, (0,0,offset) );
}


claymoreUsed( grenade )
{
	if( !IsAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	grenade Hide();
	grenade waittill_any_timeout( .05, "missile_stuck" );
	
	if( !isDefined( self ) || !IsAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	TotalDistance = 60;
	claymoreZOffset = (0,0,4);
	
	distanceFromOrigin = DistanceSquared( self.origin, grenade.origin );
	distanceFromEye = DistanceSquared( self GetEye(), grenade.origin );
	
	distanceFromOrigin += 600;
	
	// For moving platforms. 
	parent = grenade GetLinkedParent();
	if ( IsDefined( parent ) )
	{
		grenade unlink();
	}

	//if closer to ground
	if ( distanceFromOrigin < distanceFromEye )
	{
		if( TotalDistance * TotalDistance < DistanceSquared( grenade.origin, self.origin ) )
		{				
			//try to put it on the ground
			secTrace = bulletTrace( self.origin, self.origin - (0, 0, TotalDistance), false, self );
			
			if( secTrace["fraction"] == 1 )
			{
				// there's nothing under us so don't place the claymore up in the air
				grenade delete();
				// this will handle both normal and aliens claymores
				self SetWeaponAmmoStock( grenade.weapon_name, self GetWeaponAmmoStock( grenade.weapon_name ) + 1 );
				
				return;
			}
			else
			{
				grenade.origin = secTrace["position"];
				parent = secTrace["entity"];
			}
		}
		else
		{
			println("not sure why this is here");
		}
	}
	else//closer to eye
	{
		if( TotalDistance * TotalDistance < DistanceSquared( grenade.origin, self GetEye() ) )
		{
			//try to put it on the ground
			secTrace = bulletTrace( self.origin, self.origin - (0, 0, TotalDistance), false, self );
			
			if( secTrace["fraction"] == 1 )
			{
				// there's nothing under us so don't place the claymore up in the air
				grenade delete();
				
				self SetWeaponAmmoStock( grenade.weapon_name, self GetWeaponAmmoStock( grenade.weapon_name ) + 1 );
				
				return;
			}
			else
			{
				grenade.origin = secTrace["position"];
				parent = secTrace["entity"];
			}
		}
		else
		{
			claymoreZOffset = (0,0,-5);
			grenade.angles += (0,180,0);
		}
	}

	grenade.angles *= (0,1,1);
	grenade.origin = grenade.origin + claymoreZOffset;

	grenade explosiveHandleMovers( parent );

	grenade Show();
	grenade makeExplosiveUsable();
	grenade makeExplosiveTargetableByAI();
	
	self onLethalEquipmentPlanted( grenade );

	grenade thread onDetonateExplosive();
	grenade thread c4Damage();
	grenade thread c4EMPDamage();
	grenade thread claymoreDetonation( parent );
	//claymore thread claymoreDetectionTrigger_wait( self.pers[ "team" ] );
	if( !is_aliens() )
	{
		grenade thread setClaymoreTeamHeadIcon( self.pers[ "team" ], 20 );
	}
	// need to clear the changing weapon because it'll get stuck on claymore_mp and player will stop spawning because we get locked in isChangingWeapon() loop when a killstreak is earned
	self.changingWeapon = undefined;
	
	/#
	if ( getdvarint( "scr_claymoredebug" ) )
	{
		grenade thread claymoreDebug();
	}
	#/
		
	level thread monitorDisownedEquipment( self, grenade );
}

equipmentWatchUse( owner, updatePosition )
{
	if ( !is_aliens() )
	{
		self notify( "equipmentWatchUse" );
		
		self endon( "spawned_player" );
		self endon( "disconnect" );
		self endon( "equipmentWatchUse" );
		
		self.trigger setCursorHint( "HINT_NOICON" );
		
		
		switch( self.weapon_name )
		{
			case "c4_mp":
				self.trigger SetHintString( &"MP_PICKUP_C4" );
				break;
			case "claymore_mp":
				self.trigger SetHintString( &"MP_PICKUP_CLAYMORE" );
				break;
			case "bouncingbetty_mp":
				self.trigger SetHintString( &"MP_PICKUP_BOUNCING_BETTY" );
				break;
			case "motion_sensor_mp":
				self.trigger SetHintString( &"MP_PICKUP_MOTION_SENSOR" );
				break;
			case "proximity_explosive_mp":
				self.trigger SetHintString( &"MP_PICKUP_PROXIMITY_EXPLOSIVE" );
				break;
		}
		
		self.trigger setSelfUsable( owner );
		self.trigger thread notUsableForJoiningPlayers( owner );
	
		if( isDefined( updatePosition ) && updatePosition )
		{
			self thread updateTriggerPosition();
		}
		
		for ( ;; )
		{
			self.trigger waittill ( "trigger", owner );
			
			owner playLocalSound( "scavenger_pack_pickup" );
			
			if ( IsDefined( owner.loadoutPerkEquipmentStowed ) && owner.loadoutPerkEquipmentStowed == self.weapon_name )
			{
				owner.loadoutPerkEquipmentStowedAmmo++;
			}
			else
			{
				owner SetWeaponAmmoStock( self.weapon_name, owner GetWeaponAmmoStock( self.weapon_name ) + 1 );
			}
	
			self deleteExplosive();
	
			self notify( "death" );
		}
	}
}

updateTriggerPosition()
{
	self endon( "death" );
	
	for( ;; )
	{
		if ( isDefined( self ) && isDefined( self.trigger ) )
		{
			self.trigger.origin = self.origin + self getExplosiveUsableOffset();
			
			if ( isDefined( self.bombSquadModel ) )
						self.bombSquadModel.origin = self.origin;
		}
		else
		{
			return;
		}
			
		wait( 0.05 );
	}
}

 /#
claymoreDebug()
{
	self waittill( "missile_stuck", stuckTo );
	self thread showCone( acos( level.claymoreDetectionDot ), level.claymoreDetonateRadius, ( 1, .85, 0 ) );
	self thread showCone( 60, 256, ( 1, 0, 0 ) );
}

showCone( angle, range, color )
{
	self endon( "death" );

	start = self.origin;
	forward = anglestoforward( self.angles );
	right = vectorcross( forward, ( 0, 0, 1 ) );
	up = vectorcross( forward, right );

	fullforward = forward * range * cos( angle );
	sideamnt = range * sin( angle );

	while ( 1 )
	{
		prevpoint = ( 0, 0, 0 );
		for ( i = 0; i <= 20; i++ )
		{
			coneangle = i / 20.0 * 360;
			point = start + fullforward + sideamnt * ( right * cos( coneangle ) + up * sin( coneangle ) );
			if ( i > 0 )
			{
				line( start, point, color );
				line( prevpoint, point, color );
			}
			prevpoint = point;
		}
		wait .05;
	}
}
#/

claymoreDetonation( parent )
{
	self endon( "death" );

	//self waittill( "missile_stuck", stuckTo );

	damagearea = spawn( "trigger_radius", self.origin + ( 0, 0, 0 - level.claymoreDetonateRadius ), 0, level.claymoreDetonateRadius, level.claymoreDetonateRadius * 2 );

	if ( IsDefined( parent ) )
	{
		damagearea enablelinkto();
		damagearea linkto( parent );
	}

	self thread deleteOnDeath( damagearea );

	while ( 1 )
	{
		damagearea waittill( "trigger", player );

		if ( getdvarint( "scr_claymoredebug" ) != 1 )
		{
			if ( isdefined( self.owner ) )
			{
				if ( player == self.owner )
					continue;
				if ( isdefined( player.owner ) && player.owner == self.owner )
					continue;
			}
			if ( !friendlyFireCheck( self.owner, player, 0 ) )
				continue;
		}
		if ( lengthsquared( player getEntityVelocity() ) < 10 )
			continue;
		
		zDistance = abs( player.origin[2] - self.origin[2] );
		
		if ( zDistance > 128)
			continue;

		if ( !player shouldAffectClaymore( self ) )
			continue;

		if ( player damageConeTrace( self.origin, self ) > 0 )
			break;
	}
	
	self playsound ("claymore_activated");
	
	self explosiveTrigger( player, level.claymoreDetectionGracePeriod, "claymore" );
	
	if ( IsDefined( self.owner ) && IsDefined( level.leaderDialogOnPlayer_func ) )
		self.owner thread [[ level.leaderDialogOnPlayer_func ]]( "claymore_destroyed", undefined, undefined, self.origin );
	
	self notify ( "detonateExplosive" );
}

shouldAffectClaymore( claymore )
{
	if ( isDefined( claymore.disabled ) )
		return false;

	pos = self.origin + ( 0, 0, 32 );

	dirToPos = pos - claymore.origin;
	claymoreForward = anglesToForward( claymore.angles );

	dist = vectorDot( dirToPos, claymoreForward );
	if ( dist < level.claymoreDetectionMinDist )
		return false;

	dirToPos = vectornormalize( dirToPos );

	dot = vectorDot( dirToPos, claymoreForward );
	return( dot > level.claymoreDetectionDot );
}

deleteOnDeath( ent )
{
	self waittill( "death" );
	wait .05;
	
	if ( isdefined( ent ) )
	{
		if ( isDefined( ent.trigger ) )
			ent.trigger delete();
		
		ent delete();
	}
}

c4Activate()
{
	self endon( "death" );

	self waittill( "missile_stuck", stuckTo );
	
	wait 0.05;

	self notify( "activated" );
	self.activated = true;
}

watchC4AltDetonate()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "detonated" );
	level endon( "game_ended" );

	buttonTime = 0;
	for ( ;; )
	{
		if ( self UseButtonPressed() )
		{
			buttonTime = 0;
			while ( self UseButtonPressed() )
			{
				buttonTime += 0.05;
				wait( 0.05 );
			}

			println( "pressTime1: " + buttonTime );
			if ( buttonTime >= 0.5 )
				continue;

			buttonTime = 0;
			while ( !self UseButtonPressed() && buttonTime < 0.5 )
			{
				buttonTime += 0.05;
				wait( 0.05 );
			}

			println( "delayTime: " + buttonTime );
			if ( buttonTime >= 0.5 )
				continue;

			if ( !self.plantedLethalEquip.size )
				return;

			self notify( "alt_detonate" );
		}
		wait( 0.05 );
	}
}

watchC4Detonation()
{
	self endon( "death" );
	self endon( "disconnect" );

	while ( 1 )
	{
		self waittillmatch( "detonate", "c4_mp" );
		self c4DetonateAllCharges();
	}
}


watchC4AltDetonation()
{
	self endon( "death" );
	self endon( "disconnect" );

	while ( 1 )
	{
		self waittill( "alt_detonate" );
		weap = self getCurrentWeapon();
		if ( weap != "c4_mp" )
		{
			self c4DetonateAllCharges();
		}
	}
}

c4DetonateAllCharges()	// self == player
{
	foreach ( c4 in self.plantedLethalEquip )
	{
		if ( IsDefined( c4 ) )
			c4 thread waitAndDetonate( 0.1 );
	}
	self.plantedLethalEquip = [];
	
	self notify( "detonated" );
}


waitAndDetonate( delay )
{
	self endon( "death" );
	wait delay;

	self waitTillEnabled();

	self notify( "detonateExplosive" );
}

c4Damage()
{
	self endon( "death" );

	self setcandamage( true );
	self.maxhealth = 100000;
	self.health = self.maxhealth;

	attacker = undefined;

	while ( 1 )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );
		
		if ( !isPlayer( attacker ) && !isAgent( attacker ) )
			continue;

		// don't allow people to destroy C4 on their team if FF is off
		if ( !friendlyFireCheck( self.owner, attacker ) )
			continue;

		if( IsDefined( weapon ) )
		{
			switch( weapon )
			{
			case "concussion_grenade_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
				continue;
			}
		}

		break;
	}

	if ( level.c4explodethisframe )
		wait .1 + randomfloat( .4 );
	else
		wait .05;

	if ( !isdefined( self ) )
		return;

	level.c4explodethisframe = true;

	thread resetC4ExplodeThisFrame();

	if ( isDefined( type ) && ( isSubStr( type, "MOD_GRENADE" ) || isSubStr( type, "MOD_EXPLOSIVE" ) ) )
		self.wasChained = true;

	if ( isDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
		self.wasDamagedFromBulletPenetration = true;

	self.wasDamaged = true;
	
	if ( isDefined( attacker ) )
		self.damagedBy = attacker;

	if( isPlayer( attacker ) )
	{
		attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "c4" );
	}

	if ( level.teamBased )
	{
		// "destroyed_explosive" notify, for challenges
		if ( IsDefined(attacker) && IsDefined(self.owner) )
		{
			attacker_pers_team = attacker.pers[ "team" ];
			self_owner_pers_team = self.owner.pers[ "team" ];
			if ( IsDefined( attacker_pers_team ) && IsDefined( self_owner_pers_team ) && attacker_pers_team != self_owner_pers_team )
				attacker notify( "destroyed_equipment" );
		}
	}
	else
	{
		// checking isDefined attacker is defensive but it's too late in the project to risk issues by not having it
		if ( isDefined( self.owner ) && isDefined( attacker ) && attacker != self.owner )
			attacker notify( "destroyed_equipment" );		
	}
	
	self notify( "detonateExplosive", attacker );
}

resetC4ExplodeThisFrame()
{
	wait .05;
	level.c4explodethisframe = false;
}

saydamaged( orig, amount )
{
	for ( i = 0; i < 60; i++ )
	{
		print3d( orig, "damaged! " + amount );
		wait .05;
	}
}

waitTillEnabled()
{
	if ( !isDefined( self.disabled ) )
		return;

	self waittill( "enabled" );
	assert( !isDefined( self.disabled ) );
}


c4DetectionTrigger( ownerTeam )
{
	self waittill( "activated" );

	trigger = spawn( "trigger_radius", self.origin - ( 0, 0, 128 ), 0, 512, 256 );
	trigger.detectId = "trigger" + GetTime() + randomInt( 1000000 );

	trigger.owner = self;
	trigger thread detectIconWaiter( level.otherTeam[ ownerTeam ] );

	self waittill( "death" );
	trigger notify( "end_detection" );

	if ( isDefined( trigger.bombSquadIcon ) )
		trigger.bombSquadIcon destroy();

	trigger delete();
}


//claymoreDetectionTrigger_wait( ownerTeam )
//{
//	self endon( "death" );
//	self waittill( "missile_stuck" );
//
//	self thread claymoreDetectionTrigger( ownerTeam );
//}

claymoreDetectionTrigger( ownerTeam )
{
	trigger = spawn( "trigger_radius", self.origin - ( 0, 0, 128 ), 0, 512, 256 );
	trigger.detectId = "trigger" + GetTime() + randomInt( 1000000 );

	trigger.owner = self;

	trigger thread detectIconWaiter( level.otherTeam[ ownerTeam ] );
	
	self waittill( "death" );
	trigger notify( "end_detection" );

	if ( isDefined( trigger.bombSquadIcon ) )
		trigger.bombSquadIcon destroy();

	trigger delete();
}


detectIconWaiter( detectTeam )
{
	self endon( "end_detection" );
	level endon( "game_ended" );

	while ( !level.gameEnded )
	{
		self waittill( "trigger", player );

		if ( !player.detectExplosives )
			continue;

		if ( level.teamBased && player.team != detectTeam )
			continue;
		else if ( !level.teamBased && player == self.owner.owner )
			continue;

		if ( isDefined( player.bombSquadIds[ self.detectId ] ) )
			continue;

		player thread showHeadIcon( self );
	}
}

// -------------------------------------------------------------
// Helpers
// -------------------------------------------------------------
monitorDisownedEquipment( player, equipment )
{
	level endon ( "game_ended" );
	equipment endon( "death" );
	
	player waittill_any( "joined_team", "joined_spectators", "disconnect" );

	equipment deleteExplosive();
}

onLethalEquipmentPlanted( newLethal )
{
	if ( self.plantedLethalEquip.size )
	{
		self.plantedLethalEquip = array_removeUndefined( self.plantedLethalEquip );
		
		if ( self.plantedLethalEquip.size >= level.maxPerPlayerExplosives )
		{
			self.plantedLethalEquip[0] notify( "detonateExplosive" );
		}
	}
	
	self.plantedLethalEquip[ self.plantedLethalEquip.size ] = newLethal;
	
	entNum = newLethal GetEntityNumber();
	level.mines[ entNum ] = newLethal;
	
	level notify( "mine_planted" );
}

onTacticalEquipmentPlanted( newTactical )
{
	if ( self.plantedTacticalEquip.size )
	{
		self.plantedTacticalEquip = array_removeUndefined( self.plantedTacticalEquip );
		
		if ( self.plantedTacticalEquip.size >= level.maxPerPlayerExplosives )
		{
			self.plantedTacticalEquip[0] notify( "detonateExplosive" );
		}
	}
	
	self.plantedTacticalEquip[ self.plantedTacticalEquip.size ] = newTactical;
	
	entNum = newTactical GetEntityNumber();
	level.mines[ entNum ] = newTactical;
	
	level notify( "mine_planted" );
}

disablePlantedEquipmentUse()
{
	if ( IsDefined( self.plantedLethalEquip ) && self.plantedLethalEquip.size > 0 )
	{
		foreach ( equip in self.plantedLethalEquip )
		{
			if ( IsDefined( equip.trigger ) && IsDefined( equip.owner ) )
			{
				equip.trigger DisablePlayerUse( equip.owner );
			}
		}
	}
	
	if ( IsDefined( self.plantedTacticalEquip ) && self.plantedTacticalEquip.size > 0 )
	{
		foreach ( equip in self.plantedTacticalEquip )
		{
			if ( IsDefined( equip.trigger ) && IsDefined( equip.owner ) )
			{
				equip.trigger DisablePlayerUse( equip.owner );
			}
		}
	}
}

cleanupEquipment( equipNum, equipKillCamEnt, equipTrigger, equipSensor )
{	
	if ( IsDefined( equipNum ) )
		level.mines[ equipNum ] = undefined;
		
	if ( IsDefined( equipKillCamEnt ) )
		equipKillCamEnt Delete();
	
	if ( IsDefined( equipTrigger ) )
		equipTrigger Delete();
	
	// 2013-09-26 wallace: not happy about doing this, but I don't have a way of overriding this function for the motion sensor
	// when the player respawns, he deletes all planted equipment
	if ( IsDefined( equipSensor ) )
		equipSensor Delete();
}

deleteExplosive()
{
	if ( IsDefined( self ) )
	{
		equipNum = self GetEntityNumber();
		equipKillCamEnt = self.killCamEnt;
		equipTrigger = self.trigger;
		equipSensor = self.sensor;
	
		self cleanupEquipment( equipNum, equipKillCamEnt, equipTrigger, equipSensor );
		
		self notify ( "deleted_equipment" );
		
		self delete();
	}
}

onDetonateExplosive()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	self thread cleanupExplosivesOnDeath();
	
	self waittill( "detonateExplosive" );
	
	self Detonate( self.owner );
}

cleanupExplosivesOnDeath()
{
	self endon ( "deleted_equipment" );
	level endon ( "game_ended");
	
	equipNum = self GetEntityNumber();
	equipKillCamEnt = self.killCamEnt;
	equipTrigger = self.trigger;
	equipSensor = self.sensor;
	
	self waittill ( "death" );
	
	self cleanupEquipment( equipNum, equipKillCamEnt, equipTrigger, equipSensor );
}

getExplosiveUsableOffset()
{
	upVec = AnglesToUp( self.angles );
	return (10 * upVec);
}

makeExplosiveUsable()	// self == explosive
{
	// 2014-02-07 wallace: check to see if owner is really alive, to prevent dangling triggers (Bug 16460)
	if ( isReallyAlive( self.owner ) )
	{
		self SetOtherEnt( self.owner );
		
		self.trigger = Spawn( "script_origin", self.origin + self getExplosiveUsableOffset() );
		self.trigger.owner = self;
		
		self thread equipmentWatchUse( self.owner, true );
	}
}

makeExplosiveTargetableByAI( nonLethal )
{
	self make_entity_sentient_mp( self.owner.team );
	if ( !IsDefined(nonLethal) || !nonLethal )
		self MakeEntityNoMeleeTarget();
	if ( IsSentient( self ) )
	{
		self SetThreatBiasGroup( "DogsDontAttack" );
	}
}

explosiveHandleMovers( parent, useDefaultInvalidParentCallback )
{
	data = SpawnStruct();
	data.linkParent = parent;
	data.deathOverrideCallback = ::movingPlatformDetonate;
	data.endonString = "death";
	
	if ( !IsDefined( useDefaultInvalidParentCallback ) || !useDefaultInvalidParentCallback )
	{
		data.invalidParentOverrideCallback = maps\mp\_movers::moving_platform_empty_func;
	}
	self thread maps\mp\_movers::handle_moving_platforms( data );
}

// don't thread this
explosiveTrigger( target, gracePeriod, notifyStr )	// self == explosive
{
	if ( IsPlayer( target ) && target _hasPerk( "specialty_delaymine" ) )
	{
		// changed 
		target notify( "triggeredExpl", notifyStr );
		gracePeriod = level.delayMineTime;
	}
	
	wait gracePeriod;
}

setupBombSquad()
{
	self.bombSquadIds = [];

	if ( self.detectExplosives && !self.bombSquadIcons.size )
	{
		for ( index = 0; index < 4; index++ )
		{
			self.bombSquadIcons[ index ] = newClientHudElem( self );
			self.bombSquadIcons[ index ].x = 0;
			self.bombSquadIcons[ index ].y = 0;
			self.bombSquadIcons[ index ].z = 0;
			self.bombSquadIcons[ index ].alpha = 0;
			self.bombSquadIcons[ index ].archived = true;
			self.bombSquadIcons[ index ] setShader( "waypoint_bombsquad", 14, 14 );
			self.bombSquadIcons[ index ] setWaypoint( false, false );
			self.bombSquadIcons[ index ].detectId = "";
		}
	}
	else if ( !self.detectExplosives )
	{
		for ( index = 0; index < self.bombSquadIcons.size; index++ )
			self.bombSquadIcons[ index ] destroy();

		self.bombSquadIcons = [];
	}
}


showHeadIcon( trigger )
{
	triggerDetectId = trigger.detectId;
	useId = -1;
	for ( index = 0; index < 4; index++ )
	{
		detectId = self.bombSquadIcons[ index ].detectId;

		if ( detectId == triggerDetectId )
			return;

		if ( detectId == "" )
			useId = index;
	}

	if ( useId < 0 )
		return;

	self.bombSquadIds[ triggerDetectId ] = true;

	self.bombSquadIcons[ useId ].x = trigger.origin[ 0 ];
	self.bombSquadIcons[ useId ].y = trigger.origin[ 1 ];
	self.bombSquadIcons[ useId ].z = trigger.origin[ 2 ] + 24 + 128;

	self.bombSquadIcons[ useId ] fadeOverTime( 0.25 );
	self.bombSquadIcons[ useId ].alpha = 1;
	self.bombSquadIcons[ useId ].detectId = trigger.detectId;

	while ( isAlive( self ) && isDefined( trigger ) && self isTouching( trigger ) )
		wait( 0.05 );

	if ( !isDefined( self ) )
		return;

	self.bombSquadIcons[ useId ].detectId = "";
	self.bombSquadIcons[ useId ] fadeOverTime( 0.25 );
	self.bombSquadIcons[ useId ].alpha = 0;
	self.bombSquadIds[ triggerDetectId ] = undefined;
}


// these functions are used with scripted weapons (like c4, claymores, artillery)
// returns an array of objects representing damageable entities (including players) within a given sphere.
// each object has the property damageCenter, which represents its center (the location from which it can be damaged).
// each object also has the property entity, which contains the entity that it represents.
// to damage it, call damageEnt() on it.
getDamageableEnts( pos, radius, doLOS, startRadius )
{
	ents = [];

	if ( !isdefined( doLOS ) )
		doLOS = false;

	if ( !isdefined( startRadius ) )
		startRadius = 0;
	
	radiusSq = radius * radius;

	// players
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		if ( !isalive( players[ i ] ) || players[ i ].sessionstate != "playing" )
			continue;

		playerpos = get_damageable_player_pos( players[ i ] );
		distSq = distanceSquared( pos, playerpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, playerpos, startRadius, players[ i ] ) ) )
		{
			ents[ ents.size ] = get_damageable_player( players[ i ], playerpos );
		}
	}

	// grenades
	grenades = getentarray( "grenade", "classname" );
	for ( i = 0; i < grenades.size; i++ )
	{
		entpos = get_damageable_grenade_pos( grenades[ i ] );
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, grenades[ i ] ) ) )
		{
			ents[ ents.size ] = get_damageable_grenade( grenades[ i ], entpos );
		}
	}

	destructibles = getentarray( "destructible", "targetname" );
	for ( i = 0; i < destructibles.size; i++ )
	{
		entpos = destructibles[ i ].origin;
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, destructibles[ i ] ) ) )
		{
			newent = spawnstruct();
			newent.isPlayer = false;
			newent.isADestructable = false;
			newent.entity = destructibles[ i ];
			newent.damageCenter = entpos;
			ents[ ents.size ] = newent;
		}
	}

	destructables = getentarray( "destructable", "targetname" );
	for ( i = 0; i < destructables.size; i++ )
	{
		entpos = destructables[ i ].origin;
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, destructables[ i ] ) ) )
		{
			newent = spawnstruct();
			newent.isPlayer = false;
			newent.isADestructable = true;
			newent.entity = destructables[ i ];
			newent.damageCenter = entpos;
			ents[ ents.size ] = newent;
		}
	}
	
	//sentries
	sentries = getentarray( "misc_turret", "classname" );
	foreach ( sentry in sentries )
	{
		entpos = sentry.origin + (0,0,32);
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, sentry ) ) )
		{
			switch( sentry.model )
			{
			case "sentry_minigun_weak":
			case "mp_sam_turret":
			case "mp_scramble_turret":
			case "mp_remote_turret":
			case "vehicle_ugv_talon_gun_mp":
				ents[ ents.size ] = get_damageable_sentry(sentry, entpos);
				break;
			}
		}
	}

	// mines ( the problem here seems to be the traceline from 1 ground position to another is easily blocked, the origin offset helps but may have it's own issues )
	mines = getentarray( "script_model", "classname" );
	foreach ( mine in mines )
	{
		if ( mine.model != "projectile_bouncing_betty_grenade" && mine.model != "ims_scorpion_body" )
			continue;

		entpos = mine.origin + (0,0,32);
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, mine ) ) )
			ents[ ents.size ] = get_damageable_mine( mine, entpos );
	}

	return ents;
}


getEMPDamageEnts( pos, radius, doLOS, startRadius )
{
	ents = [];

	if ( !isDefined( doLOS ) )
		doLOS = false;

	if ( !isDefined( startRadius ) )
		startRadius = 0;
	
	radiusSq = radius * radius;

	/*
	grenades = getEntArray( "grenade", "classname" );
	foreach ( targetEnt in grenades )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}
	*/
	// for some reason, motion_sensor_mp isn't getting collected by the grenades check
	// instead, we'll use our manually tracked level.mines array. There may be old items in here, so must check IsDefined
	level.mines = array_removeUndefined( level.mines );
	foreach ( targetEnt in level.mines )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}

	turrets = getEntArray( "misc_turret", "classname" );
	foreach ( targetEnt in turrets )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}
	
	foreach ( targetEnt in level.uplinks )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}
	
	foreach ( targetEnt in level.remote_uav )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}
	
	foreach ( targetEnt in level.ballDrones )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}
	
	foreach ( targetEnt in level.placedIMS )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}
	
	foreach ( targetEnt in level.players )
	{
		if ( empCanDamage( targetEnt, pos, radiusSq, doLOS, startRadius ) )
			ents[ ents.size ] = targetEnt;
	}

	return ents;
}

empCanDamage( ent, pos, radiusSq, doLOS, startRadius )
{
	entpos = ent.origin;
	distSq = DistanceSquared( pos, entpos );
	return ( distSq < radiusSq
	    && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, ent ) ) );
}


weaponDamageTracePassed( from, to, startRadius, ent )
{
	midpos = undefined;

	diff = to - from;
	if ( lengthsquared( diff ) < startRadius * startRadius )
		return true;
	
	dir = vectornormalize( diff );
	midpos = from + ( dir[ 0 ] * startRadius, dir[ 1 ] * startRadius, dir[ 2 ] * startRadius );

	trace = bullettrace( midpos, to, false, ent );

	if ( getdvarint( "scr_damage_debug" ) != 0 || getdvarint( "scr_debugMines" ) != 0 )
	{
		thread debugprint( from, ".dmg" );
		if ( isdefined( ent ) )
			thread debugprint( to, "." + ent.classname );
		else
			thread debugprint( to, ".undefined" );
		if ( trace[ "fraction" ] == 1 )
		{
			thread debugline( midpos, to, ( 1, 1, 1 ) );
		}
		else
		{
			thread debugline( midpos, trace[ "position" ], ( 1, .9, .8 ) );
			thread debugline( trace[ "position" ], to, ( 1, .4, .3 ) );
		}
	}

	return( trace[ "fraction" ] == 1 );
}

// eInflictor = the entity that causes the damage (e.g. a claymore)
// eAttacker = the player that is attacking
// iDamage = the amount of damage to do
// sMeansOfDeath = string specifying the method of death (e.g. "MOD_PROJECTILE_SPLASH")
// sWeapon = string specifying the weapon used (e.g. "claymore_mp")
// damagepos = the position damage is coming from
// damagedir = the direction damage is moving in
damageEnt( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, damagepos, damagedir )
{
	if ( self.isPlayer )
	{
		self.damageOrigin = damagepos;
		self.entity thread [[ level.callbackPlayerDamage ]](
			eInflictor,// eInflictor The entity that causes the damage.( e.g. a turret )
			eAttacker,// eAttacker The entity that is attacking.
			iDamage,// iDamage Integer specifying the amount of damage done
			0,// iDFlags Integer specifying flags that are to be applied to the damage
			sMeansOfDeath,// sMeansOfDeath Integer specifying the method of death
			sWeapon,// sWeapon The weapon number of the weapon used to inflict the damage
			damagepos,// vPoint The point the damage is from?
			damagedir,// vDir The direction of the damage
			"none",// sHitLoc The location of the hit
			0// psOffsetTime The time offset for the damage
		 );
	}
	else
	{
		// destructable walls and such can only be damaged in certain ways.
		if ( self.isADestructable && ( sWeapon == "artillery_mp" || sWeapon == "claymore_mp" || sWeapon == "stealth_bomb_mp" || sWeapon == "alienclaymore_mp" ) )
			return;

		self.entity notify( "damage", iDamage, eAttacker, ( 0, 0, 0 ), ( 0, 0, 0 ), "MOD_EXPLOSIVE", "", "", "", undefined, sWeapon );
	}
}


debugline( a, b, color )
{
	for ( i = 0; i < 30 * 20; i++ )
	{
		line( a, b, color );
		wait .05;
	}
}

debugcircle( center, radius, color, segments )
{
	if ( !isDefined( segments ) )
		segments = 16;
		
	angleFrac = 360/segments;
	circlepoints = [];
	
	for( i = 0; i < segments; i++ )
	{
		angle = (angleFrac * i);
		xAdd = cos(angle) * radius;
		yAdd = sin(angle) * radius;
		x = center[0] + xAdd;
		y = center[1] + yAdd;
		z = center[2];
		circlepoints[circlepoints.size] = ( x, y, z );
	}
	
	for( i = 0; i < circlepoints.size; i++ )
	{
		start = circlepoints[i];
		if (i + 1 >= circlepoints.size)
			end = circlepoints[0];
		else
			end = circlepoints[i + 1];
		
		thread debugline( start, end, color );
	}
}

debugprint( pt, txt )
{
	for ( i = 0; i < 30 * 20; i++ )
	{
		print3d( pt, txt );
		wait .05;
	}
}


onWeaponDamage( eInflictor, sWeapon, meansOfDeath, damage, eAttacker )
{
	self endon( "death" );
	self endon( "disconnect" );

	switch( sWeapon )
	{
		case "concussion_grenade_mp":
			// should match weapon settings in gdt
			
			if ( !isDefined( eInflictor ) )//check to ensure inflictor wasnt destroyed.
				return;
			else if( meansOfDeath == "MOD_IMPACT" )
				return;
			
			giveFeedback = true;
			if( IsDefined( eInflictor.owner ) && eInflictor.owner == eAttacker )
				giveFeedback = false;

			radius = 512;
			scale = 1 - ( distance( self.origin, eInflictor.origin ) / radius );

			if ( scale < 0 )
				scale = 0;

			time = 2 + ( 4 * scale );
			
			time = maps\mp\perks\_perkfunctions::applyStunResistence( time );
			
			wait( 0.05 );
			eAttacker notify( "stun_hit" );
			self notify( "concussed", eAttacker );
			if( eAttacker != self )
				eAttacker maps\mp\gametypes\_missions::processChallenge( "ch_alittleconcussed" );
			self shellShock( "concussion_grenade_mp", time );
			self.concussionEndTime = GetTime() + ( time * 1000 );
			if( giveFeedback )
				eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "stun" );
		break;

		case "weapon_cobra_mk19_mp":
			// mk19 is too powerful with shellshock slowdown
		break;

		default:
			// shellshock will only be done if meansofdeath is an appropriate type and if there is enough damage.
			maps\mp\gametypes\_shellshock::shellshockOnDamage( meansOfDeath, damage );
		break;
	}

}

// weapon class boolean helpers
isPrimaryWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	if ( weaponInventoryType( weapName ) != "primary" )
		return false;

	switch ( weaponClass( weapName ) )
	{
		case "rifle":
		case "smg":
		case "mg":
		case "spread":
		case "pistol":
		case "rocketlauncher":
		case "sniper":
			return true;

		default:
			return false;
	}	
}

isBulletWeapon( weapName )
{
	if ( weapName == "none" || isRiotShield( weapName ) || isKnifeOnly( weapName )  )
		return false;
	
	switch ( weaponClass( weapName ) )
	{
		case "rifle":
		case "smg":
		case "mg":
		case "spread":
		case "pistol":
		case "sniper":
			return true;

		default:
			return false;
	}	
}

isKnifeOnly( weapName )
{
	return IsSubStr( weapName, "knifeonly" );
}

isAltModeWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( weaponInventoryType( weapName ) == "altmode" );
}

isInventoryWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( weaponInventoryType( weapName ) == "item" );
}

isRiotShield( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( WeaponType( weapName ) == "riotshield" );
}

isOffhandWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( weaponInventoryType( weapName ) == "offhand" );
}

isSideArm( weapName )
{
	if ( weapName == "none" )
		return false;

	if ( weaponInventoryType( weapName ) != "primary" )
		return false;

	return ( weaponClass( weapName ) == "pistol" );
}

// This needs for than this.. this would qualify c4 as a grenade
isGrenade( weapName )
{
	weapClass = weaponClass( weapName );
	weapType = weaponInventoryType( weapName );

	if ( weapClass != "grenade" )
		return false;
		
	if ( weapType != "offhand" )
		return false;
	
	return true;
}

isThrowingKnife( weapName )
{
	if ( weapName == "none" )
		return false;
	
	// need to check against "throwingknife_mp", "throwingknifejugg_mp"
	return ( IsSubStr(weapName, "throwingknife" ) );
}

isRocketLauncher( weapName )
{
	// 2013-09-09 wallace: urgh, hind rockets are also considered rocket launchers
	// return ( WeaponClass( weapName ) == "rocketlauncher" );
	// so use specific weapon names instead
	return ( weapName == "iw6_panzerfaust3_mp"
		    || weapName == "iw6_maaws_mp" );
}

updateSavedLastWeapon()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );

	currentWeapon = self.currentWeaponAtSpawn;
	if( IsDefined( self.saved_lastWeaponHack ) )
		currentWeapon = self.saved_lastWeaponHack;

	self.saved_lastWeapon = currentWeapon;

	for ( ;; )
	{
		self waittill( "weapon_change", newWeapon );
	
		if ( newWeapon == "none" )
		{
			self.saved_lastWeapon = currentWeapon;
			continue;
		}

		weaponInvType = weaponInventoryType( newWeapon );

		if ( weaponInvType != "primary" && weaponInvType != "altmode" )
		{
			self.saved_lastWeapon = currentWeapon;
			continue;
		}

		self updateMoveSpeedScale();

		self.saved_lastWeapon = currentWeapon;
		
		currentWeapon = newWeapon;
	}
}

//updateWeaponRank()
//{
//	self endon( "death" );
//	self endon( "disconnect" );
//	self endon( "faux_spawn" );
//
//	currentWeapon = self.currentWeaponAtSpawn;
//
//	// we just want the weapon name up to the first underscore
//	weaponTokens = StrTok( currentWeapon, "_" );
//	
//	if ( weaponTokens[0] == "iw5" || weaponTokens[0] == "iw6" )
//		weaponTokens[0] = weaponTokens[0] + "_" + weaponTokens[1];
//	else if ( weaponTokens[0] == "alt" )
//		weaponTokens[0] = weaponTokens[1] + "_" + weaponTokens[2];
//	
//	self.pers[ "weaponRank" ] = self maps\mp\gametypes\_rank::getWeaponRank( weaponTokens[0] ); 
//
//	for ( ;; )
//	{
//		self waittill( "weapon_change", newWeapon );
//
//		if( newWeapon == "none" || self isJuggernaut() )
//		{
//			continue;
//		}
//
//		weaponInvType = weaponInventoryType( newWeapon );
//
//		if ( weaponInvType == "primary" )
//		{
//			// we just want the weapon name up to the first underscore unless its an IW5 weapon...
//			weaponTokens = StrTok( newWeapon, "_" );
//			if ( weaponTokens[0] == "iw5" || weaponTokens[0] == "iw6" )
//				self.pers[ "weaponRank" ] = self maps\mp\gametypes\_rank::getWeaponRank( weaponTokens[0] + "_" + weaponTokens[1] ); 
//			else if( weaponTokens[0] == "alt" )
//				self.pers[ "weaponRank" ] = self maps\mp\gametypes\_rank::getWeaponRank( weaponTokens[1] + "_" + weaponTokens[2] ); 
//			else
//				self.pers[ "weaponRank" ] = self maps\mp\gametypes\_rank::getWeaponRank( weaponTokens[0] ); 
//		}
//	}
//}

EMPPlayer( numSeconds )
{
	self endon( "disconnect" );
	self endon( "death" );

	self thread clearEMPOnDeath();

}


clearEMPOnDeath()
{
	self endon( "disconnect" );

	self waittill( "death" );
}

WEAPON_WEIGHT_VALUE_DEFAULT = 8;
getWeaponHeaviestValue()
{
	heaviestWeaponValue = 1000;
	
	self.weaponList = self GetWeaponsListPrimaries();	
	if ( self.weaponList.size )
	{
		foreach ( weapon in self.weaponList )
		{
			weaponWeight = getWeaponWeight( weapon );
			
			if ( weaponWeight == 0 )
				continue;
			
			if ( weaponWeight < heaviestWeaponValue )
			{	
				heaviestWeaponValue = weaponWeight;
			}	
		}
		
		/#	//Debug for odd cases where move speed is erroring based on equiped weapons.
		if ( heaviestWeaponValue == 1000 )
		{
			AssertMsg( "No weapons of non zero speed" );
			
			foreach ( weapon in self.weaponList )
			{
				AssertMsg( "Weapon Name:" + weapon );
			}
		}
		#/
	}
	else
	{
		//	This should only ever happen half way through giveLoadout(), after weapons were
		//	cleared, when clearing perks (if player had juiced), and no secondary (in some new game modes).
		//	In that case, this would be called again at the end of giveLoadout(), after the primary had been 
		//	set and overwrite this correctly anyway.
		//	Setting a heavy default value to catch ending up here in any other circumstance (cheating).
		heaviestWeaponValue = WEAPON_WEIGHT_VALUE_DEFAULT;
	}
	
	heaviestWeaponValue = clampWeaponWeightValue( heaviestWeaponValue );
	
	return heaviestWeaponValue;
}

getWeaponWeight( weapon )
{
	weaponSpeed = undefined;
	baseWeapon = getBaseWeaponName( weapon );
	
	if ( is_aliens() )
	{
		weaponSpeed = Float( TableLookup( "mp/alien/mode_string_tables/alien_statstable.csv", 4, baseWeapon, 8 ) );
	}
	else
	{
		weaponSpeed = Float( TableLookup( "mp/statstable.csv", 4, baseWeapon, 8 ) );
	}
	
	return weaponSpeed;
}

clampWeaponWeightValue( value )
{
	// Pistols now move at 10.5 or 105% so don't clamp at 100%
	return clamp( value, 0.0, 11.0 );
}

updateMoveSpeedScale()
{
	weaponWeight = undefined;
	
	self.weaponList = self GetWeaponsListPrimaries();
	if ( !self.weaponList.size )
	{
		//	This should only ever happen half way through giveLoadout(), after weapons were
		//	cleared, when clearing perks (if player had juiced), and no secondary (in some new game modes).
		//	In that case, this would be called again at the end of giveLoadout(), after the primary had been 
		//	set and overwrite this correctly anyway.
		//	Setting a heavy default value to catch ending up here in any other circumstance (cheating).
		weaponWeight = WEAPON_WEIGHT_VALUE_DEFAULT;
	}
	else
	{
		weapon = self GetCurrentWeapon();
		
		// If the current weapon is not a primary weapon ignore it
		weaponInvType = WeaponInventoryType( weapon );
		if ( weaponInvType != "primary" && weaponInvType != "altmode" )
		{
			// If no primary was found use the saved_lastWeapon which is always primary
			if ( IsDefined( self.saved_lastWeapon ) )
			{
				weapon = self.saved_lastWeapon;
			}
			else
			{
				weapon = undefined;
			}
		}
		
		// If no weapon was found at this point, just use the heaviest
		if ( !IsDefined( weapon ) || !self HasWeapon( weapon ) )
		{
			weaponWeight = self getWeaponHeaviestValue();
		}
		else
		{
			weaponWeight = getWeaponWeight( weapon );
			
			//dev only for new weapons and firing range.
			/#
			if( !isDefined( weaponWeight ) || weaponWeight == 0 )
				weaponWeight = 10;
			#/
			
			weaponWeight = clampWeaponWeightValue( weaponWeight );
		}
	}
	
	normalizedWeaponSpeed = weaponWeight / 10;
	
	self.weaponSpeed = normalizedWeaponSpeed;
	Assert( IsDefined( self.weaponSpeed ) );
	Assert( IsDefined( self.moveSpeedScaler ) );
	
	if ( !IsDefined( self.combatSpeedScalar ) )
	{
		self.combatSpeedScalar = 1;
	}
	
	self SetMoveSpeedScale( normalizedWeaponSpeed * self.moveSpeedScaler * self.combatSpeedScalar );
}

CONST_RECOIL_REDUCTION_LMG_PRONE		   = 40;
CONST_RECOIL_REDUCTION_LMG_CROUCH		   = 10;
CONST_RECOIL_REDUCTION_SNIPER_PRONE		   = 40;
CONST_RECOIL_REDUCTION_SNIPER_CROUCH	   = 20;
CONST_RECOIL_REDUCTION_SNIPER_PRONE_BORED  = 20;
CONST_RECOIL_REDUCTION_SNIPER_CROUCH_BORED = 10;

stanceRecoilAdjuster()
{
	if ( !IsPlayer(self) )
		return;
	
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );	
	
	self notifyOnPlayerCommand( "adjustedStance", "+stance" );
	self notifyOnPlayerCommand( "adjustedStance", "+goStand" );
	
	if( !level.console && !isAI(self) )
	{
		self notifyOnPlayerCommand( "adjustedStance", "+togglecrouch" );	// Toggle Crouch
		self notifyOnPlayerCommand( "adjustedStance", "toggleprone" );		// Toggle Prone
		self notifyOnPlayerCommand( "adjustedStance", "+movedown" );		// Hold Crouch Press
		self notifyOnPlayerCommand( "adjustedStance", "-movedown" );		// Hold Crouch Release
		self notifyOnPlayerCommand( "adjustedStance", "+prone" );			// Hold Prone Hold Press
		self notifyOnPlayerCommand( "adjustedStance", "-prone" );			// Hold Prone Hold Release
	}
	
	for ( ;; )
	{
		// added weapon_change because there's a bug where you can go prone, scope up with a sniper, hold breath, and switch weapons to have no recoil on the weapon
		//	if you stayed prone then you could have a no recoil weapon
		self waittill_any( "adjustedStance", "sprint_begin", "weapon_change" );
		
		// NOTE: removed a check for weapon_lmg and weapon_sniper that would continue and skip everything below, we want to run everything below
		//	there's a bug where you can go prone, scope up with a sniper, hold breath, and switch weapons to have no recoil on the weapon
		//	by continuing here we never reset the recoil for the other weapon

		wait( 0.5 ); //necessary to ensure proper stance is given and to balance to ensure duck diving isnt a valid tactic
		
		// NOTE: moved this to be after the wait because you could still do the no recoil glitch by hitting Y+B and shoot at the same time
		if ( IsDefined( self.onHeliSniper ) && self.OnHeliSniper )
			continue;
		
		stance = self GetStance();
		
		stanceRecoilUpdate( stance );
	}
}

stanceRecoilUpdate( stance )
{
	weapName = self GetCurrentPrimaryWeapon();
	sniperReduction = 0;
	if ( isRecoilReducingWeapon( weapName ) )
	{
		sniperReduction = self getRecoilReductionValue();
	}
	
	// Bolt action sniper scopes reduce recoil with consecutive kills
	// without dying. Grab this reduction if it exists
	if ( stance == "prone" )
	{
		weapClass = getWeaponClass( weapName );
		
		if ( weapClass == "weapon_lmg" )
		{
			self setRecoilScale( 0, CONST_RECOIL_REDUCTION_LMG_PRONE );	
		}
		else if ( weapClass == "weapon_sniper" )
		{
			// Bored out barrel should still kick a lot
			if ( IsSubStr( weapName, "barrelbored" ) )
			{
				self setRecoilScale( 0, CONST_RECOIL_REDUCTION_SNIPER_PRONE_BORED + sniperReduction );
			}
			else
			{
				self setRecoilScale( 0, CONST_RECOIL_REDUCTION_SNIPER_PRONE + sniperReduction );
			}
		}
		else
		{
			self setRecoilScale();
		}
	}
	else if ( stance == "crouch" )
	{
		weapClass = getWeaponClass( weapName );
		if ( weapClass == "weapon_lmg" )
		{
			self setRecoilScale( 0, CONST_RECOIL_REDUCTION_LMG_CROUCH );
		}
		else if ( weapClass == "weapon_sniper" )
		{
			// Bored out barrel should still kick a lot
			if ( IsSubStr( weapName, "barrelbored" ) )
			{
				self setRecoilScale( 0, CONST_RECOIL_REDUCTION_SNIPER_CROUCH_BORED + sniperReduction );
			}
			else
			{
				self setRecoilScale( 0, CONST_RECOIL_REDUCTION_SNIPER_CROUCH + sniperReduction );
			}
		}
		else
		{
			self setRecoilScale();
		}
	}
	else
	{
		if ( sniperReduction > 0 )
		{
			self setRecoilScale( 0, sniperReduction );
		}
		else
		{
			self setRecoilScale();
		}
	}
}

// JC-ToDo: I don't believe this function is needed anymore.
buildWeaponData( filterPerks )
{
	attachmentList = getAttachmentListBaseNames();
	attachmentList = alphabetize( attachmentList );
	max_weapon_num = 149;

	baseWeaponData = [];
	
	statsTableName = "mp/statstable.csv";
	gametype = GetDvar ("g_gametype");
	if ( gametype == "aliens" )
	{
		statsTableName = "mp/alien/mode_string_tables/alien_statstable.csv";
	}
	
	for( weaponId = 0; weaponId <= max_weapon_num; weaponId++ )
	{
		
		baseName = tablelookup( statsTableName, 0, weaponId, 4 );
		if( baseName == "" )
			continue;

		assetName = baseName + "_mp";

		if ( !isSubStr( tableLookup( statsTableName, 0, weaponId, 2 ), "weapon_" ) )
			continue;
		
		if ( weaponInventoryType( assetName ) != "primary" )
			continue;

		weaponInfo = spawnStruct();
		weaponInfo.baseName = baseName;
		weaponInfo.assetName = assetName;
		weaponInfo.variants = [];

		weaponInfo.variants[0] = assetName;
		// the alphabetize function is slow so we try not to do it for every weapon/attachment combo; a code solution would be better.
		attachmentNames = [];
		for ( innerLoopCount = 0; innerLoopCount < 6; innerLoopCount++ )
		{
			// generating attachment combinations
			attachmentName = tablelookup( statsTableName, 0, weaponId, innerLoopCount + 11 );
			
			if ( filterPerks )
			{
				switch ( attachmentName )
				{
					case "fmj":
					case "xmags":
					case "rof":
						continue;
				}
			}
			
			if( attachmentName == "" )
				break;
			
			attachmentNames[attachmentName] = true;
		}

		// generate an alphabetized attachment list
		attachments = [];
		foreach ( attachmentName in attachmentList )
		{
			if ( !isDefined( attachmentNames[attachmentName] ) )
				continue;
			
			weaponInfo.variants[weaponInfo.variants.size] = baseName + "_" + attachmentName + "_mp";
			attachments[attachments.size] = attachmentName;
		}

		for ( i = 0; i < (attachments.size - 1); i++ )
		{
			colIndex = tableLookupRowNum( "mp/attachmentCombos.csv", 0, attachments[i] );
			for ( j = i + 1; j < attachments.size; j++ )
			{
				if ( tableLookup( "mp/attachmentCombos.csv", 0, attachments[j], colIndex ) == "no" )
					continue;
					
				weaponInfo.variants[weaponInfo.variants.size] = baseName + "_" + attachments[i] + "_" + attachments[j] + "_mp";
			}
		}
		
		baseWeaponData[baseName] = weaponInfo;
	}
	
	return ( baseWeaponData );
}

monitorMk32SemtexLauncher()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "faux_spawn" );
	
	for( ;; )
	{
		grenade = self waittill_grenade_fire();
		
		if ( IsDefined( grenade.weapon_name ) && grenade.weapon_name == "iw6_mk32_mp" )
		{
			self semtexUsed( grenade );
		}
	}	
}

semtexUsed( grenade ) // self == player
{
	if ( !IsDefined( grenade ) )
		return;
	if ( !IsDefined( grenade.weapon_name ) )
		return;
	// MK32 is a semtex launcher
	if ( !IsSubStr( grenade.weapon_name, "semtex" ) && grenade.weapon_name != "iw6_mk32_mp" )
		return;

	grenade.originalOwner = self;	
	grenade waittill( "missile_stuck", stuckTo );

	grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
	
	if ( IsPlayer( stuckTo ) || IsAgent( stuckTo ) )
	{
		//player could disconnect after throwing the grenade
		//for safety we are 
		if ( !isDefined(self) )
		{
			grenade.stuckEnemyEntity = stuckTo;
			
			// need this for Operations tracking
			stuckTo.stuckByGrenade = grenade;
		}
		else if ( level.teamBased && IsDefined( stuckTo.team ) && stuckTo.team == self.team )
		{
			grenade.isStuck = "friendly";
		}
		else
		{
			grenade.isStuck		   = "enemy";
			grenade.stuckEnemyEntity = stuckTo;
			
			if ( IsPlayer( stuckTo ) )
				stuckTo maps\mp\gametypes\_hud_message::playerCardSplashNotify( "semtex_stuck", self );
			
			self thread maps\mp\gametypes\_hud_message::splashNotify( "stuck_semtex", 100 );
			
			// need this for Operations tracking
			stuckTo.stuckByGrenade = grenade;
		}
	}

	grenade explosiveHandleMovers( undefined );
}


turret_monitorUse()
{
	for( ;; )
	{
		self waittill ( "trigger", player );
		
		self thread turret_playerThread( player );
	}
}

turret_playerThread( player )
{
	player endon ( "death" );
	player endon ( "disconnect" );

	player notify ( "weapon_change", "none" );
	
	self waittill ( "turret_deactivate" );
	
	player notify ( "weapon_change", player getCurrentWeapon() );
}

spawnMine( origin, owner, weaponName, angles )
{
	Assert( isDefined( owner ) );

	if ( !isDefined( angles ) )
		angles = (0, RandomFloat(360), 0);
	
	config = level.weaponConfigs[ weaponName ];
	Assert( IsDefined( config ) );

	mine = Spawn( "script_model", origin );
	mine.angles = angles;
	mine SetModel( config.model );
	mine.owner = owner;
	mine SetOtherEnt(owner);
	mine.weapon_name = weaponName;
	mine.config = config;

	mine.killCamOffset = ( 0, 0, 4 );
	mine.killCamEnt = Spawn( "script_model", mine.origin + mine.killCamOffset );
	
	mine.killCamEnt SetScriptMoverKillCam( "explosive" );
	
	owner onLethalEquipmentPlanted( mine );

	mine thread createBombSquadModel( config.bombSquadModel, "tag_origin", owner ); // may have issues with team and owner here
	if ( IsDefined( config.mine_beacon ) )
	{
		mine thread doBlinkingLight( "tag_fx", config.mine_beacon["friendly"], config.mine_beacon["enemy"] );
	}

	if( !is_aliens() )
	{
		mine thread setClaymoreTeamHeadIcon( owner.pers[ "team" ], config.headIconOffset );
	}
	
	// For moving platforms. 
	movingPlatformParent = undefined;
	if( self != level ) // sometimes we spawn a mine using the level in dev only
	{
		movingPlatformParent = self GetLinkedParent();
	}
	mine explosiveHandleMovers( movingPlatformParent );
	
	mine thread mineProximityTrigger( movingPlatformParent );	
	mine thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
	//mine thread mineSelfDestruct();
	
	mine makeExplosiveTargetableByAI( true );
	if ( is_aliens() && IsSentient( mine ) )
	{
		mine SetThreatBiasGroup( "deployable_ammo" );
		mine.threatbias = -10000;
	}
	
	mine thread mineExplodeOnNotify();
	
	level thread monitorDisownedEquipment( owner, mine );
	
	return mine;
}

spawnMotionSensor( origin, owner, weaponName, angles )
{
	Assert( isDefined( owner ) );

	if ( !isDefined( angles ) )
		angles = (0, RandomFloat(360), 0);
	
	config = level.weaponConfigs[ weaponName ];
	Assert( IsDefined( config ) );

	mine = Spawn( "script_model", origin );
	mine.angles = angles;
	mine SetModel( config.model );
	mine.owner = owner;
	mine SetOtherEnt(owner);
	mine.weapon_name = weaponName;
	mine.config = config;

	owner onTacticalEquipmentPlanted( mine );

	mine thread createBombSquadModel( config.bombSquadModel, "tag_origin", owner ); // may have issues with team and owner here
	
	mine thread setClaymoreTeamHeadIcon( owner.pers[ "team" ], config.headIconOffset );
	
	// For moving platforms. 
	movingPlatformParent = undefined;
	if( self != level ) // sometimes we spawn a mine using the level in dev only
	{
		movingPlatformParent = self GetLinkedParent();
	}
	mine explosiveHandleMovers( movingPlatformParent, true );
	mine thread mineProximityTrigger( movingPlatformParent );	
	mine thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
	mine thread motionSensorEMPDamage();
	
	mine makeExplosiveTargetableByAI( false );
	
	mine thread mineSensorOnNotify();
	
	level thread monitorDisownedEquipment( owner, mine );
	
	return mine;
}

mineDamageMonitor()
{
	self endon( "mine_triggered" );
	self endon( "mine_selfdestruct" );
	self endon( "death" );

	self setcandamage( true );
	self.maxhealth = 100000;
	self.health = self.maxhealth;

	attacker = undefined;

	while ( 1 )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );
		
		if ( is_aliens() && is_hive_explosion( attacker, type ) )
			break;
		
		if ( !isPlayer( attacker ) && !IsAgent( attacker ) )
			continue;
		
		// this should catch both "bouncingbetty_mp" and "alienbetty_mp"
		if ( IsDefined( weapon ) && IsEndStr( weapon, "betty_mp" ) )
			continue;
		
		// don't allow people to destroy mines on their team if FF is off
		if ( !friendlyFireCheck( self.owner, attacker ) )
			continue;

		if( IsDefined( weapon ) )
		{
			switch( weapon )
			{
			case "concussion_grenade_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
			case "smoke_grenadejugg_mp":
				continue;
			}
		}

		break;
	}

	self notify( "mine_destroyed" );

	if ( isDefined( type ) && ( isSubStr( type, "MOD_GRENADE" ) || isSubStr( type, "MOD_EXPLOSIVE" ) ) )
		self.wasChained = true;

	if ( isDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
		self.wasDamagedFromBulletPenetration = true;

	self.wasDamaged = true;
	
	if ( isDefined( attacker ) )
		self.damagedBy = attacker;
	
	if( isPlayer( attacker ) )
	{
		attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "bouncing_betty" );
	}

	if ( !is_Aliens() )
	{
		if ( level.teamBased )
		{
			// "destroyed_explosive" notify, for challenges
			if ( isdefined( attacker ) && isdefined( attacker.pers[ "team" ] ) && isdefined( self.owner ) && isdefined( self.owner.pers[ "team" ] ) )
			{
				if ( attacker.pers[ "team" ] != self.owner.pers[ "team" ] )
					attacker notify( "destroyed_equipment" );
			}
		}
		else
		{
			// checking isDefined attacker is defensive but it's too late in the project to risk issues by not having it
			if ( isDefined( self.owner ) && isDefined( attacker ) && attacker != self.owner )
				attacker notify( "destroyed_equipment" );		
		}
	}

	self notify( "detonateExplosive", attacker );
}

is_hive_explosion( attacker, type )
{
	if ( !isDefined( attacker ) || !isDefined( attacker.classname ) )
		return false;
	
	return ( attacker.classname == "scriptable" && type == "MOD_EXPLOSIVE" );
}

mineProximityTrigger( movingPlatformParent )
{
	self endon( "mine_destroyed" );
	self endon( "mine_selfdestruct" );
	self endon( "death" );
	self endon( "disabled" );
	
	config = self.config;
	//	arming time
	wait( config.armTime );
	
	if ( IsDefined( config.mine_beacon ) )
	{
		self thread doBlinkingLight( "tag_fx", config.mine_beacon["friendly"], config.mine_beacon["enemy"] );
	}

	trigger = Spawn( "trigger_radius", self.origin, 0, level.mineDetectionRadius, level.mineDetectionHeight );
	trigger.owner = self;
	self thread mineDeleteTrigger( trigger );
	
	if ( IsDefined( movingPlatformParent ) )
	{
		trigger enablelinkto();
		trigger linkto( movingPlatformParent );
	}
	self.damagearea = trigger;

	player = undefined;
	while ( 1 )
	{
		trigger waittill( "trigger", player );
		
		if ( !isDefined( player ) )
			continue;

		if ( getdvarint( "scr_minesKillOwner" ) != 1 )
		{
			if ( isDefined( self.owner ) )
			{
				if ( player == self.owner )
					continue;
				if ( isdefined( player.owner ) && player.owner == self.owner )
					continue;
			}

			if ( !friendlyFireCheck( self.owner, player, 0 ) )
				continue;
		}
		
		if ( lengthsquared( player getEntityVelocity() ) < 10 )
			continue;

		if ( player damageConeTrace( self.origin, self ) > 0 )
			break;
	}

	self notify( "mine_triggered" );
	
	self PlaySound( self.config.onTriggeredSfx );
	
	self explosiveTrigger( player, level.mineDetectionGracePeriod, "mine" );

	self thread [[ self.config.onTriggeredFunc ]]();
}

mineDeleteTrigger( trigger )
{
	self waittill_any( "mine_triggered", "mine_destroyed", "mine_selfdestruct", "death" );

	if ( IsDefined( trigger ) )
		trigger delete();
}

motionSensorEMPDamage()
{
	self endon( "mine_triggered" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "emp_damage", attacker, duration );

		self equipmentEmpStunVfx();
		self stopBlinkingLight();
		if ( IsDefined( self.damagearea ) )
			self.damagearea Delete();

		self.disabled = true;
		self notify( "disabled" );

		wait( duration );

		if ( IsDefined( self ) )
		{
		  self.disabled = undefined;
		  self notify( "enabled" );
		  
		  parent = self GetLinkedParent();
		  self thread mineProximityTrigger( parent );
		}
	}
}

mineSelfDestruct()
{
	self endon( "mine_triggered" );
	self endon( "mine_destroyed" );
	self endon( "death" );
	
	wait( level.mineSelfDestructTime + RandomFloat( 0.4 ) );

	self notify( "mine_selfdestruct" );
	self notify ( "detonateExplosive" );
}

// TODO: 
//		 Handle a drop outside of a level, like highrise.
//		 Spawn protection against these. "protect players from spawnkill grenades"
//		 Killcam doesn't fly up. Probably needs code.
mineBounce()
{
	self playsound( self.config.onLaunchSfx );
	playFX( level.mine_launch, self.origin );
	
	if ( IsDefined( self.trigger ) )
		self.trigger delete();
	
	explodePos = self.origin + (0, 0, 64);
	self MoveTo( explodePos, 0.7, 0, .65 );
	self.killCamEnt MoveTo( explodePos + self.killCamOffset, 0.7, 0, .65 );

	self RotateVelocity( (0, 750, 32), 0.7, 0, .65 );
	self thread playSpinnerFX();

	wait( 0.65 );

	self notify ( "detonateExplosive" );
}

mineExplodeOnNotify()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	self waittill( "detonateExplosive", attacker );
	
	if ( !IsDefined( self ) || !IsDefined(self.owner) )
		return;
	
	// using a passed in attacker means that the owner wasn't the one who detonated this, this way the correct credit will go to the correct player
	if( !IsDefined( attacker ) )
		attacker = self.owner;

	self PlaySound( self.config.onExplodeSfx );
	
	// there was a bug where the explosion fx weren't playing (possibly because there were too many events happening on the entity at once)
	//	so don't do this PlayFXOnTag( level.mine_explode, self, "tag_fx" );
	tagOrigin = self GetTagOrigin( "tag_fx" );
	PlayFX( level.mine_explode, tagOrigin );
	self notify( "explode", tagOrigin );
	
	wait( 0.05 ); // needed or the effect doesn't play
	if ( !IsDefined( self ) || !IsDefined(self.owner) )
		return;
	
	self Hide();
	
	self RadiusDamage( self.origin, level.mineDamageRadius, level.mineDamageMax, level.mineDamageMin, attacker, "MOD_EXPLOSIVE", self.weapon_name );		
	
	if ( IsDefined( self.owner ) && IsDefined( level.leaderDialogOnPlayer_func ) )
		self.owner thread [[ level.leaderDialogOnPlayer_func ]]( "mine_destroyed", undefined, undefined, self.origin );

	wait( 0.2 );
	
	self deleteExplosive();
}

mineSensorBounce()
{
	self playsound( self.config.onLaunchSfx );
	
	PlayFX( self.config.launchVfx, self.origin );
	
	if ( IsDefined( self.trigger ) )
		self.trigger delete();
	
	// hide the part that will shoot up
	self HidePart( "tag_sensor" );
	
	self stopBlinkingLight();
	
	// spawn a sensor
	// attach the sensor to the base
	// move the sensor
	sensor = Spawn( "script_model", self.origin );
	sensor.angles = self.angles;
	sensor SetModel( self.config.model );
	sensor HidePart( "tag_base" );
	sensor.config = self.config;
	self.sensor = sensor;
	
	explodePos = self.origin + (0, 0, self.config.launchHeight);
	
	timeToDetonation = self.config.launchTime;
	flightTime = self.config.launchTime + 0.1;
	
	sensor MoveTo( explodePos, flightTime, 0, timeToDetonation );

	sensor RotateVelocity( (0, 1100, 32), flightTime, 0, timeToDetonation );
	sensor thread playSpinnerFX();

	wait( timeToDetonation );

	self notify ( "detonateExplosive" );
}

mineSensorOnNotify()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	self waittill( "detonateExplosive", attacker );
	
	if ( !IsDefined( self ) || !IsDefined(self.owner) )
		return;
	
	if( !IsDefined( attacker ) )
		attacker = self.owner;

	self PlaySound( self.config.onExplodeSfx );

	tagOrigin = undefined;
	if ( IsDefined( self.sensor ) )
	{
		tagOrigin = self.sensor GetTagOrigin( "tag_sensor" );
	}
	else
	{
		tagOrigin = self GetTagOrigin( "tag_origin" );
	}
	PlayFX( self.config.onExplodeVfx, tagOrigin );
	
	waitframe();
	
	if ( !IsDefined( self ) || !IsDefined(self.owner) )
		return;
	
	//self Hide();
	if ( IsDefined( self.sensor ) )
	{
		self.sensor Delete();
	}
	else
	{
		self HidePart( "tag_sensor" );
	}
	
	// the owner always gets a notify, not the guy who shot it
	self.owner thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "hitmotionsensor" );
	
	markedPlayers = [];
	
	foreach( character in level.characters )
	{
		if( character.team == self.owner.team )
			continue;
		
		if( !isReallyAlive(character) )
			continue;
		
		if( character _hasPerk("specialty_heartbreaker") )
			continue;
			
		if( Distance2D(self.origin, character.origin) < 300 )
			markedPlayers[markedPlayers.size] = character;
	}
	
	foreach( player in markedPlayers )
	{
		self thread markPlayer( player, self.owner );
		level thread sensorScreenEffects( player, self.owner );
	}
	
	if ( markedPlayers.size > 0 )
	{
		self.owner maps\mp\gametypes\_missions::processChallenge( "ch_motiondetected", markedPlayers.size );
		
		//tracks weapon hits for stats
		self.owner thread maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName( "motion_sensor", 1, "hits" );
	}
	
	if ( IsDefined( self.owner ) && IsDefined( level.leaderDialogOnPlayer_func ) )
		self.owner thread [[ level.leaderDialogOnPlayer_func ]]( "mine_destroyed", undefined, undefined, self.origin );

	wait( 0.2 );
	
	self deleteExplosive();
}

markPlayer( player, owner )
{
	if( player == owner )
		return;
	
	player endon( "disconnect" );
	
	outlineID = undefined;
	if( level.teamBased )
	{
		outlineID = outlineEnableForTeam( player, "orange", owner.team, false, "equipment" );
	}
	else
	{
		outlineID = outlineEnableForPlayer( player, "orange", owner, false, "equipment" );
	}
	
	player thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "hitmotionsensor" );
	
	// 2013-07-18 wallace: this will give an assist even after the player is no longer marked, but it's much simpler than the remoteUAV version
	// maps\mp\gametypes\_damage::addAttacker( player, owner, owner, self.weapon_name, 0, (0,0,0), (0,0,0), "none", 0, "MOD_EXPLOSIVE" );
	player.motionSensorMarkedBy = owner;
	
	player waittill_any_timeout( self.config.markedDuration, "death" );
	
	player.motionSensorMarkedBy = undefined;
	
	outlineDisable( outlineID, player );
}


sensorScreenEffects( player, owner )
{
	if( player == owner )
		return;
	
	if( isAI(player) )
		return;
		
	effectName = "coup_sunblind";
	
	player SetClientOmnvar( "ui_hud_shake", true );
	player VisionSetNakedforPlayer( effectName, 0.05 );
	
	wait ( 0.05 );
	
	player VisionSetNakedforPlayer( effectName, 0 );
	player VisionSetNakedforPlayer( "", 0.5 );
}

motionSensor_processTaggedAssist( victim )
{
	if ( IsDefined( level.assists_disabled ) )
		return;
		
	self.taggedAssist = true;
	if ( isDefined( victim ) )
		self thread maps\mp\gametypes\_gamescore::processAssist( victim );	
	else
	{
		maps\mp\gametypes\_gamescore::givePlayerScore( "assist", self, undefined, true );
		self thread maps\mp\gametypes\_rank::giveRankXP( "assist" );		
	}
}

playSpinnerFX()
{
	if ( IsDefined( self.config.mine_spin ) )
	{
		self endon( "death");
		
		timer = gettime() + 1000;
		
		while ( gettime() < timer )
		{
			wait .05;
			playFXontag( self.config.mine_spin, self, "tag_fx_spin1" );
			playFXontag( self.config.mine_spin, self, "tag_fx_spin3" );
			wait .05;
			playFXontag( self.config.mine_spin, self, "tag_fx_spin2" );
			playFXontag( self.config.mine_spin, self, "tag_fx_spin4" );
		}
	}
}

/*mineDamagePassed( damageCenter, recieverCenter, radiusSq, ignoreEnt )
{
	damageTop = damageCenter[2] + level.mineDamageHalfHeight;
	damageBottom = damageCenter[2] - level.mineDamageHalfHeight;

	/#
	if ( getdvarint( "scr_debugMines" ) != 0 )
		thread mineDamageDebug( damageCenter, recieverCenter, radiusSq, ignoreEnt, damageTop, damageBottom );
	#/

	if ( recieverCenter[2] > damageTop || recieverCenter[2] < damageBottom )
		return false;

	distSq = distanceSquared( damageCenter, recieverCenter );
	if ( distSq > radiusSq )
		return false;

	if ( !weaponDamageTracePassed( damageCenter, recieverCenter, 0, ignoreEnt ) )
		return false;

	return true;
}*/

mineDamageDebug( damageCenter, recieverCenter, radiusSq, ignoreEnt, damageTop, damageBottom )
{
	color[0] = ( 1, 0, 0 );
	color[1] = ( 0, 1, 0 );

	/*if ( recieverCenter[2] > damageTop )
		pass = false;
	else
		pass = true;

	damageTopOrigin = ( damageCenter[0], damageCenter[1], damageTop );
	recieverTopOrigin = ( recieverCenter[0], recieverCenter[1], damageTop );
	thread debugcircle( damageTopOrigin, level.mineDamageRadius, color[pass], 32 );*/
	
	if ( recieverCenter[2] < damageBottom  )
		pass = false;
	else
		pass = true;

	damageBottomOrigin = ( damageCenter[0], damageCenter[1], damageBottom );
	recieverBottomOrigin = ( recieverCenter[0], recieverCenter[1], damageBottom );
	thread debugcircle( damageBottomOrigin, level.mineDamageRadius, color[pass], 32 );

	distSq = distanceSquared( damageCenter, recieverCenter );
	if ( distSq > radiusSq )
		pass = false;
	else
		pass = true;

	thread debugline( damageBottomOrigin, recieverBottomOrigin, color[pass] );
}

mineDamageHeightPassed( mine, victim )
{
	if ( isPlayer( victim ) && isAlive( victim ) && victim.sessionstate == "playing" )
		victimPos = victim getStanceCenter();
	else if ( victim.classname == "misc_turret" )
		victimPos = victim.origin + ( 0, 0, 32 );
	else
		victimPos = victim.origin;
	
	tempZOffset = 0; //66
	damageTop = mine.origin[2] + tempZOffset + level.mineDamageHalfHeight;  //46
	damageBottom = mine.origin[2] + tempZOffset - level.mineDamageHalfHeight;

	/#
	//if ( getdvarint( "scr_debugMines" ) != 0 )
		//thread mineDamageDebug( damageCenter, recieverCenter, radiusSq, victim, damageTop, damageBottom );
	#/

	if ( victimPos[2] > damageTop || victimPos[2] < damageBottom )
		return false;

	return true;
}

mineUsed( grenade, spawnFunc ) // self == player
{
	if( !IsAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	maps\mp\gametypes\_gamelogic::setHasDoneCombat( self, true );
	
	grenade thread mineThrown( self, grenade.weapon_name, spawnFunc );
}

// TODO: need self endon( "death" ); but also need an explosion to still happen
// TODO: fix beacon effect lasting through launch
// What if we never get "missile_stuck"? Endon death happen automatically after a set lifetime has passed?
// Owner may not exist by the time it is used. (maybe make this run on owner instead)
// Hitting trigger after respawn on these causes a script error.
mineThrown( owner, weaponName, spawnFunc )
{
	self.owner = owner;
	
	self waittill( "missile_stuck", stuckTo );

	if( !isDefined( owner ) )
		return;
	
	trace = bulletTrace( self.origin + (0, 0, 4), self.origin - (0, 0, 4), false, self );
	
	pos = trace["position"];
	if ( trace["fraction"] == 1 ) //wtf, stuck to somthing that trace didnt hit
	{	
		pos = GetGroundPosition( self.origin, 12, 0, 32);
		trace["normal"] *= -1;
	}
	
	normal = vectornormalize( trace["normal"] );
	plantAngles = vectortoangles( normal );
	plantAngles += ( 90, 0, 0 );
	
	mine = [[ spawnFunc ]]( pos, owner, weaponName, plantAngles );
	
	mine makeExplosiveUsable();
	mine thread mineDamageMonitor();

	self delete();
}

delete_all_grenades()
{
	if ( IsDefined( self.plantedLethalEquip ) )
	{
		foreach ( grenade in self.plantedLethalEquip )
		{
			grenade deleteExplosive();
		}
	}
				
	if ( IsDefined( self.plantedTacticalEquip ) )
	{
		foreach ( grenade in self.plantedTacticalEquip )
		{
			grenade deleteExplosive();
		}
	}
	
	if ( IsDefined( self ) )
	{
		self.plantedLethalEquip = [];
		self.plantedTacticalEquip = [];
	}
}
	
transfer_grenade_ownership( newOwner )
{
	//clear anything the newOwner had
	newOwner delete_all_grenades();
	
	//give the lists to newOwner
	if ( IsDefined( self.plantedLethalEquip ) )
		newOwner.plantedLethalEquip = array_removeUndefined( self.plantedLethalEquip );
	
	if ( IsDefined( self.plantedTacticalEquip ) )
		newOwner.plantedTacticalEquip = array_removeUndefined( self.plantedTacticalEquip );

	//transfer ownership
	if ( IsDefined( newOwner.plantedLethalEquip ) )
	{
		foreach ( equip in newOwner.plantedLethalEquip )
		{
			equip.owner = newOwner;
			equip thread equipmentWatchUse( newOwner );
		}
	}

	if ( IsDefined( newOwner.plantedTacticalEquip ) )
	{
		foreach ( equip in newOwner.plantedTacticalEquip )
		{
			equip.owner = newOwner;
			equip thread equipmentWatchUse( newOwner );
		}
	}

	//forget about them
	self.plantedLethalEquip = [];
	self.plantedTacticalEquip = [];
	self.dont_delete_grenades_on_next_spawn = true;
	self.dont_delete_mines_on_next_spawn = true;
}

doBlinkingLight( tagName, friendlyFXSrc, enemyFXSrc )	// self == ent
{
	if ( !IsDefined( friendlyFXSrc ) )
	{
		friendlyFXSrc = getfx( "weap_blink_friend" );
	}
	
	if ( !IsDefined( enemyFXSrc ) )
	{
		enemyFXSrc = getfx( "weap_blink_enemy" );
	}
	
	self.blinkingLightFx["friendly"] = friendlyFXSrc;
	self.blinkingLightFx["enemy"] = enemyFXSrc;
	self.blinkingLightTag = tagName;
	
	self thread updateBlinkingLight( friendlyFXSrc, enemyFXSrc, tagName );
	
	self waittill( "death" );
	
	self stopBlinkingLight();
}

updateBlinkingLight( friendlyFXSrc, enemyFXSrc, tagName )
{
	self endon ( "death" );
	self endon ( "carried" );
	self endon( "emp_damage" );
	
	checkFunc = ::checkTeam;
	if ( !level.teamBased )
	{
		checkFunc = ::checkPlayer;
	}
	
	delay = RandomFloatRange( 0.05, 0.25 );
	wait (delay);
	
	self childthread onJoinTeamBlinkingLight( friendlyFXSrc, enemyFXSrc, tagName, checkFunc );
	
	foreach ( player in level.players )
	{
		// make sure we don't test against removed entities, since players might quit in the time it takes to iterate through the list
		if ( IsDefined( player ) )	
		{
			if ( self.owner [[ checkFunc ]]( player ) )
			{
				PlayFXOnTagForClients( friendlyFXSrc, self, tagName, player );
			}
			else
			{
				PlayFXOnTagForClients( enemyFXSrc, self, tagName, player );
			}
			
			wait(0.05);		// PlayFXOnTagForClients use the entity event system which is limited to 4 events per frame (and subsequent ones will be dropped)
		}
	}
}

onJoinTeamBlinkingLight( friendlyFXSrc, enemyFXSrc, tagName, checkFunc )	// self == object that blinks
{
	self endon( "death" );
	level endon( "game_ended" );
	self endon( "emp_damage" );

	while( true )
	{
		level waittill ( "joined_team", player );
		
		// 2013-09-04 wallace: there is a bug that if a player swaps teams repeatedly
		// he will stack lights. The ideal solution is to get a StopFXOnTagForClients
		// because stopping the FX for everyone is pretty network heavy
		if ( self.owner [[ checkFunc ]]( player ) )
		{
			PlayFXOnTagForClients( friendlyFXSrc, self, tagName, player );
		}
		else
		{
			PlayFXOnTagForClients( enemyFXSrc, self, tagName, player );
		}
	}
}

stopBlinkingLight()
{
	if ( IsAlive( self ) && IsDefined( self.blinkingLightFx ) )
	{
		StopFXOnTag( self.blinkingLightFx["friendly"], self, self.blinkingLightTag );
		StopFXOnTag( self.blinkingLightFx["enemy"], self, self.blinkingLightTag );
		
		self.blinkingLightFx = undefined;
		self.blinkingLightTag = undefined;
	}
}

checkTeam( other )	// self == player
{
	return ( self.team == other.team );
}

checkPlayer( other )
{
	return ( self == other );
}

// equipmentDeathVfx - call when the equipment is done, but before it's deleted
equipmentDeathVfx()	// self == equipment
{
	// do some objects need to play on tag? typically not.
	//PlayFXOnTag( getfx( "equipment_sparks" ), self, tagName);
	
	PlayFX( getfx( "equipment_sparks" ), self.origin );
	
	self PlaySound( "sentry_explode" );
}

// equipmentDeleteVfx - call to mask the object deletion
equipmentDeleteVfx()	// self == equipment
{
	PlayFX( getfx( "equipment_explode_big" ), self.origin );
	PlayFX( getfx( "equipment_smoke" ), self.origin );
	
	self PlaySound( "mp_killstreak_disappear" );	
}

equipmentEmpStunVfx()	// self == equipment
{
	PlayFXOnTag( getfx( "emp_stun" ), self, "tag_origin" );
}
