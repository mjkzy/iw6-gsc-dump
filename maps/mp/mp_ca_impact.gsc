#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_ca_impact_precache::main();
	maps\createart\mp_ca_impact_art::main();
	maps\mp\mp_ca_impact_fx::main();
	
	maps\mp\_breach::main();
	
	common_scripts\_pipes::main();
	
	//TODO: If something is breaking with the map killstreak, comment out the line below:
	thread maps\mp\mp_ca_killstreaks_a10::init("impact");
	//thread maps\mp\mp_ca_behemoth_killstreak::init();
	//thread maps\mp\mp_ca_impact_killstreak_b::init();
	
	//PrintLn( GetTime() + " -- setting up custom funcs" );
	
	// setting up the custom functions
	level.mapCustomCrateFunc = ::impactCustomCrateFunc;
	level.mapCustomKillstreakFunc = ::impactCustomKillstreakFunc;
	level.mapCustomBotKillstreakFunc = ::impactCustomBotKillstreakFunc;
	
	maps\mp\_load::main();
	
//	AmbientPlay( "ambient_mp_setup_template" );
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_ca_impact" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	
	if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.55" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".15" );
	}
	else if ( level.xenon )
	{
		SetDvar( "sm_sunShadowScale", "0.56" +
			    "" ); //  optimization
		SetDvar( "sm_sunsamplesizenear", ".22" );
	}
	else
	{
		SetDvar( "sm_sunShadowScale", "0.9" ); // optimization
		SetDvar( "sm_sunsamplesizenear", ".27" );
	}
	
//	setdvar_cg_ng( "r_specularColorScale", 1.7, 5 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	thread impact_breach_init();
	thread setup_extinguishers();
	thread setup_watertanks();
	thread setup_phys_hits();

	// overriding this setting
	level._pipes._pipe_fx_time["steam"]   = 10;
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
	thread watersheet_trig_setup();
	
}

IMPACT_KILLSTREAK_WEIGHT = 80;

watersheet_trig_setup()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "using_remote" );
	self endon( "stopped_using_remote" );	
	self endon( "disconnect" );
	self endon( "above_water" );
	
	triggers = GetEntArray( "watersheet", "targetname" );
	
	foreach ( trig in triggers )
	{
		trig thread waterTriggerWaiter();
	}
}

waterTriggerWaiter()
{
	while(1)
	{		
		self waittill("trigger", player );
		
		if( isAI( player ) )
			continue;
		
		if( !IsPlayer( player ) )
			continue;
		
		if ( !isDefined(player.isTouchingWaterSheetTrigger) || player.isTouchingWaterSheetTrigger == false)
			thread watersheet_PlayFX( player );
	}
}

watersheet_PlayFX( player ) {
	
	player.isTouchingWaterSheetTrigger = true;

	player SetWaterSheeting( 1, 2 );
	wait( randomfloatrange( .15, .75) );
	player SetWaterSheeting( 0 );	
	
	player.isTouchingWaterSheetTrigger = false;
}

watersheet_sound( trig )
{
	trig endon("death");
	thread watersheet_sound_play(trig);
	while( 1 )
	{
		trig waittill( "trigger", player );
		
		trig.sound_end_time = GetTime() + 100;
		trig notify("start_sound");
	}
}

watersheet_sound_play(trig)
{
	trig endon("death");
	
	while(1)
	{
		trig waittill("start_sound");
		
		trig PlayLoopSound("scn_jungle_under_falls_plr");
		
		while(trig.sound_end_time>GetTime())
			wait (trig.sound_end_time-GetTime())/1000;
		
		trig StopLoopSound();
	}
}

// map-specific killstreak
impactCustomCrateFunc()
{
	//PrintLn("impactCustomCrateFunc");
	if(!IsDefined(game["player_holding_level_killstrek"]))
		game["player_holding_level_killstrek"] = false;
		
	if(!allowLevelKillstreaks() || game["player_holding_level_killstrek"])
		return;
	
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault",	"ca_a10_strafe", IMPACT_KILLSTREAK_WEIGHT,	maps\mp\killstreaks\_airdrop::killstreakCrateThink,	maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), maps\mp\killstreaks\_airdrop::get_enemy_crate_model(),	&"MP_CA_KILLSTREAKS_A10_STRAFE_PICKUP" );
	maps\mp\killstreaks\_airdrop::generateMaxWeightedCrateValue();
	level thread watch_for_impact_crate();
	
}

impactCustomKillstreakFunc()
{
	//PrintLn("impactCustomKillstreakFunc");
	
	// have to use warhawk_mortars as the keyword, otherwise it throws a bunch of errors
	
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/Impact Killstreak\" \"set scr_devgivecarepackage ca_a10_strafe; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Impact Killstreak\" \"set scr_givekillstreak ca_a10_strafe\"\n");
	
	level.killStreakFuncs[ "ca_a10_strafe" ] = ::tryUseImpactKillstreak;
	
}

impactCustomBotKillstreakFunc()
{
	//PrintLn("impactCustomBotKillstreakFunc");
	AddDebugCommand("devgui_cmd  \"MP/Bots(Killstreak)/Level Events:5/Impact Killstreak\" \"set scr_testclients_givekillstreak ca_a10_strafe\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( "ca_a10_strafe",	maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
}

watch_for_impact_crate()
{
	//PrintLn("Watching for impact crate");
	while(1)
	{
		level waittill("createAirDropCrate", dropCrate);

		if(IsDefined(dropCrate) && IsDefined(dropCrate.crateType) && dropCrate.crateType=="ca_a10_strafe")
		{	
			maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "ca_a10_strafe", 0);
			captured = wait_for_capture(dropCrate);
			
			if(!captured)
			{
				//reEnable warhawk mortars care packages if it expires with out anyone picking it up
				maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "ca_a10_strafe", IMPACT_KILLSTREAK_WEIGHT);
			}
			else
			{
				//Once its picked up it needs to remain off.
				game["player_holding_level_killstrek"] = true;
				break;
			}
		}
	}
}

//death and capture are sent on the same frame but death is processed first :(
wait_for_capture(dropCrate)
{
	result = watch_for_air_drop_death(dropCrate);
	return !IsDefined(result); //If !isdefined the captured notify was also sent.
}

watch_for_air_drop_death(dropCrate)
{
	dropCrate endon("captured");
	
	dropCrate waittill("death");
	waittillframeend;
	
	return true;
}

tryUseImpactKillstreak(lifeId, streakName)
{	
	// this contains all the code to run the killstreak
	
	return maps\mp\mp_ca_killstreaks_a10::onUse(lifeId, streakName);
	
}

// BREACH
impact_breach_init()
{
	wait 0.5;
	
	breaches = getstructarray( "breach", "targetname" );
	
	// disable all connected pathnodes
	foreach (breach in breaches)
	{
		pathnodes = GetNodeArray(breach.target, "targetname");
		foreach(p in pathnodes)
			p DisconnectNode();
	}
	
	proxy = getstructarray( "breach_proxy", "targetname" );
	foreach ( p in proxy )
	{
		if ( !IsDefined( p.target ) )
			continue;
		breach = getstruct( p.target, "targetname" );
		if ( !IsDefined( breach ) )
			continue;
		breaches[ breaches.size ] = breach;			
	}
	array_thread( breaches, ::impact_breach_update );
}

impact_breach_update()
{
	// these game modes don't use breach doors, so skip the wait and explosion if it's one of these modes
	if(!(level.gameType == "gun") && !(level.gameType == "sotf_ffa") && !(level.gameType == "horde") && !(level.gameType == "sotf") && !(level.gameType == "infect"))
	{
		self waittill( "breach_activated" );
		
		eq_scale = 0.5;
		eq_duration = .5;
		eq_radius = 200;
	
		if(IsDefined(self.script_dot))
			eq_scale = self.script_dot;
		if(IsDefined(self.script_wait))
			eq_duration = self.script_wait;
		if(IsDefined(self.radius))
			eq_radius = self.radius;
		
		Earthquake( eq_scale, eq_duration, self.origin, eq_radius );	
	}
	
	// find all the related pathnodes and connect them.
	pathnodes = GetNodeArray(self.target, "targetname");
	foreach(p in pathnodes)
		p ConnectNode();
}

setup_extinguishers()
{
	extinguishers = GetEntArray("extinguisher", "targetname");
	array_thread(extinguishers, ::update_extinguisher);
}

update_extinguisher()
{
	self SetCanDamage(true);
	damaged = false;

	// wait until it's damaged by melee, grenade, or bullet	
	while(!damaged)
	{
		// this will only play its FX once and never again
		self waittill( "damage", amount, attacker, direction_vec, hit_point, damage_type);
		
		if ( IsSubStr( damage_type, "MELEE") || IsSubStr( damage_type, "BULLET" ))
		{
			
			self SetCanDamage(false);
			// point toward the player
			PlayFX(level._effect["vfx_fire_extinguisher"], hit_point, RotateVector(direction_vec, (0, 180.0, 0.0)));
			playSoundAtPos(self.origin, "extinguisher_break");
			damaged = true;
		}
		else
		{
			self SetCanDamage(false);
			PlayFX(level._effect["vfx_fire_extinguisher"], self.origin, AnglesToUp(self.angles));
			playSoundAtPos(self.origin, "extinguisher_break");
		}
	}
}

play_hit( effect_id, spawn_point, spawn_dir)
{
	//PrintLn("Playing hit!");
	vfx_ent = SpawnFx( effect_id, spawn_point, AnglesToForward( spawn_dir ), AnglesToUp( spawn_dir ) );
	TriggerFX( vfx_ent );
	wait 5.0;
	vfx_ent Delete();
}

setup_watertanks()
{
	level.tank_hitfx_throttle = 600;
	level.tank_hitfx_throttle_max = 1200;
	level.next_tank_hitfx_time = -1.0;
	
	watertanks = GetEntArray( "watertank", "targetname" );
	if ( watertanks.size > 0 )
	{
		for ( i=0; i<watertanks.size; i++ )
			 watertanks[i] thread update_watertank( i );
	}
	
}

update_watertank( index )
{

	self SetCanDamage( true );
	self.tank_damage = 0;
	surface_offset = 20.0;
	current_surface = self.origin[2] + surface_offset;
	water_surface = Spawn("script_origin", (self.origin[0], self.origin[1], self.origin[2] + surface_offset));
	lowest_hit_z = self.origin[2] + surface_offset;
	drain_rate = 2.0;
	drain_time = 4.0;
	start_time = 1.0;
	stop_time = 2.0;

	while ( self.tank_damage < 1200.0 )
	{
		self waittill( "damage", amount, attacker, direction_vec, hit_point, damage_type );
		
		self.tank_damage += amount;

		if ( !IsSubStr( damage_type, "BULLET" ) )
			continue;

		if ( !can_allocate_new_tank_crack() )
			continue;
		
		current_surface = water_surface.origin[2] + surface_offset;
		if ( hit_point[2] >= current_surface )
			continue;

		hit_angles = get_watertank_hit_angle( attacker, direction_vec, hit_point );
		if ( !IsDefined( hit_angles ) )
			continue;
		
		drain_limit = Min( drain_time * drain_rate, current_surface - self.origin[2] );
		actual_move_z = Max( self.origin[2], Max( hit_point[2], current_surface - drain_limit ) );
		move_dist = actual_move_z - current_surface;

		move_time = Abs( move_dist ) / drain_rate;
		move_time = Max( move_time, start_time + stop_time );

		self thread spawn_watertank_hit( level._effect["vfx_watertank_bullet_hit"], attacker, hit_angles, hit_point, move_time, water_surface, surface_offset );

		if ( actual_move_z >= lowest_hit_z )
			continue;

		lowest_hit_z = actual_move_z;
		water_surface MoveZ( move_dist, move_time, start_time, stop_time );
	}
}

spawn_watertank_hit( effect_id, attacker, hit_angles, hit_point, drain_time, water_surface, surface_offset )
{
	
	water_fx_ent = SpawnFx( effect_id, hit_point, hit_angles );
	TriggerFX( water_fx_ent );
	
	//water_fx_ent PlaySound( "water_tank_hit" );
	
	stop_time = GetTime() + drain_time * 1000.0;
	water_fx_ent monitor_watertank_hit( water_surface, stop_time, surface_offset );
	
	water_fx_ent StopSounds();
	wait 0.05;
	water_fx_ent Delete();
}

monitor_watertank_hit( water_surface, stop_time, surface_offset )
{
	water_surface endon( "tank_destroyed" );

	while ( GetTime() < stop_time )
	{
		if ( self.origin[2] >= ((water_surface.origin[2] + surface_offset) - 1.0) )
			break;
		wait 0.05;
	}
}

update_watertank_invulnerable()
{
	self SetCanDamage( true );
	while ( 1 )
	{
		self waittill( "damage", amount, attacker, direction_vec, hit_point, damage_type );
		
		//PrintLn("HIT");
		
		if ( !IsSubStr( damage_type, "BULLET" ) )
			continue;
		
		hit_angles = get_watertank_hit_angle( attacker, direction_vec, hit_point );
		if ( !IsDefined( hit_angles ) )
			continue;

		hit_angles = VectorToAngles( hit_angles );
		PlayFX( level._effect["vfx_watertank_bullet_hit"], hit_point, AnglesToForward( hit_angles ), AnglesToUp( hit_angles ) );
		//PlaySoundAtPos( hit_point, "water_tank_hit" );
	}
}

get_watertank_hit_angle( attacker, direction_vec, hit_point )
{
	E = attacker.origin;
	temp_vec = hit_point - E;

	trace = BulletTrace( E, E + 1.5 * temp_vec, false, attacker, false );
	if ( IsDefined ( trace[ "normal" ] ) && IsDefined( trace[ "entity" ] ) && (trace["entity"] == self) )
		return trace[ "normal" ];
	
	return undefined;
}

can_allocate_new_tank_crack()
{
	if ( GetTime() < level.next_tank_hitfx_time )
		return false;
	return true;
}

allocate_new_tank_crack()
{
	level.next_tank_hitfx_time = GetTime() + RandomFloatRange( level.tank_hitfx_throttle, level.tank_hitfx_throttle_max );
}

setup_phys_hits()
{
	phys_objs = GetEntArray("shootable_hanger", "targetname");
	if(phys_objs.size)
		array_thread(phys_objs, ::update_phys_hits);
}

update_phys_hits()
{
	self SetCanDamage(true);
	self waittill( "damage", amount, attacker, direction_vec, hit_point, damage_type );
	self Hide();
	PlayFX(level._effect["vfx_" + self.model], self.origin, self.angles);
	self Delete();
}