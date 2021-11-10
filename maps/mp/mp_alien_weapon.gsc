#include maps\mp\_utility;
#include common_scripts\utility;

	CONST_CORROSIVE_CLOUD_DURATION	  = 5;
	CONST_CORROSIVE_CLOUD_RADIUS	  = 200;
	CONST_CORROSIVE_CLOUD_HEIGHT	  = 150;
	CONST_CORROSIVE_CLOUD_TICK_DAMAGE = 15;
	CONST_CORROSIVE_CLOUD_LINGER_TIME = 5;
	CONST_CORROSIVE_CLOUD_TICK_TIME	  = 1;
	CONST_BLAST_RADIUS				  = 256;
	CONST_BLAST_MINDMG				  = 300;
	CONST_BLAST_MAXDMG				  = 350;
	INITIAL_AMMO_COUNT				  = 10;
	WEAPON_NAME						  = "venomxgun_mp";
	PROJECTILE_NAME						= "venomxproj_mp";

init()
{
	init_armory_weapon_fx();
	level.remaining_alien_weapons = 1;
}

init_armory_weapon_fx()
{
	level._effect[ "corrosive_blast" ] = LoadFX( "vfx/gameplay/mp/equipment/vfx_alien_dome_ns_gun_gas" );
}

special_gun_watcher() //self = player
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self notify ( "gun_watcher_logic" );
	self endon( "gun_watcher_logic" );	
	
	self NotifyOnPlayerCommand( "detonate_venom", "+toggleads_throw" );
	self NotifyOnPlayerCommand( "detonate_venom", "+ads_akimbo_accessible" );
	
	self thread special_gun_detonate_hint_watcher();
	
	weapname = "none";
	projectile = undefined;
	while ( 1 )
	{
		self waittill( "grenade_fire", projectile, weapname );
		if ( weapname == WEAPON_NAME)// ||	weapname == "iw6_aliendlc12_mp" || weapname == "iw6_aliendlc13_mp" || weapname == "iw6_aliendlc14_mp" )
		{
			clipCount = self GetWeaponAmmoClip( WEAPON_NAME );	
			{
				if ( clipCount == 0 )
					self thread remove_alien_weapon ( projectile );
			}

			projectile.health = 9999999;
			projectile thread maps\mp\gametypes\_weapons::createBombSquadModel( "weapon_semtex_grenade_iw6_bombsquad", "tag_origin", self );
			self thread wait_for_detonation( projectile, weapname );
			self thread explode_projectile( projectile, weapname );
		}
	wait( 0.05 );
	}
}

special_gun_detonate_hint_watcher()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "gun_watcher_logic" );
	self endon ( "alien_weapon_removed" );
	
	projectile_time_out_max = 2;
	
	while(!IsDefined(self.no_more_detonate_hint))
	{
		self waittill( "grenade_fire", projectile, weapname );
		if ( weapname == WEAPON_NAME)
		{
			if(!IsDefined(self.projectile_time_out_num))
				self.projectile_time_out_num = 1;
			else
			{
			   	if(self.projectile_time_out_num > projectile_time_out_max)
				{
					projectile_time_out_max = 3;
					self.projectile_time_out_num = 0;
					self thread show_specialweapon_hint_repeat();
				}
			   	else
			   	{
			   		self.projectile_time_out_num++;
			   	}
			}
		}
		wait(.1);
	}
}

// self = player
wait_for_detonation( projectile, weapname )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );   
	projectile endon ( "death" );
	
	self.adsPressed = false;
	self thread ads_watcher();
	self thread toggle_ads_watcher();
	
	DETONATE_TIME_LIMIT = 100;  //time in frames  that players have to detonate the DLC11 projectile
	buttonTime = 0;
	location = ( 0, 0, 0 );
	
	self thread projectile_safety( projectile );
	
	while ( self AdsButtonPressed() && buttonTime < DETONATE_TIME_LIMIT )
	{
		wait ( .05 );
		buttonTime = buttonTime + 1;
	}
	
	while( buttonTime < DETONATE_TIME_LIMIT )
	{
		if ( IsDefined( projectile ) && self.adsPressed && self GetCurrentWeapon() == WEAPON_NAME && isReallyAlive ( self ))
		{
			projectile notify ( "projectile_detonate" );
			projectile notify ( "trap_death" );
			self.no_more_detonate_hint = true;
			return;
		}
		else if ( !IsDefined( projectile ) )
		{
			thread cloud_monitor ( self, location, weapname );
			playSoundAtPos( location, "aliendlc11_explode" );
			return;
		}
		location = projectile.origin;
		wait 0.05;
		buttonTime = buttonTime + 1;
	}
	projectile notify ( "projectile_detonate" );
	projectile notify ( "trap_death" );
}

//self = a player
//this is for when a player has the controller set up for toggling ADS ( N0M4D )
toggle_ads_watcher()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "projectile_detonate" );
	self endon( "ads_pressed");
	
	self waittill( "detonate_venom" );
	self.adsPressed = true;
	self notify( "ads_pressed" );
}

//self = a player
//normal non-toggled ads watcher
ads_watcher()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "projectile_detonate" );
	self endon( "ads_pressed");
	
	while ( 1 )
	{
		if ( self AdsButtonPressed() )
		{
			self.adsPressed = true;
			self notify( "ads_pressed" );
		}
		wait .05;		
	}
}

// self = player
// detonates unexploded projectile in the event of player death or disconnect
projectile_safety( projectile )
{
	projectile endon ( "projectile_detonate" );
	self waittill_any ( "death", "disconnect" );
	wait 1;
	projectile notify ( "trap_death" );
	projectile notify ( "projectile_detonate" );
}

// self = player
explode_projectile( projectile, weapname )
{
	projectile endon ( "death" );
	projectile notify ( "trap_death" );
	duration 				= CONST_CORROSIVE_CLOUD_DURATION + 1;
	projectile waittill ( "projectile_detonate" );
	if ( IsDefined ( projectile ) ) 
	{
		projectile thread cloud_monitor ( self, projectile.origin, weapname );
		playSoundAtPos( projectile.origin, "aliendlc11_explode" );
		projectile hide();
		wait duration;
		projectile delete();
	}
}

// self = projectile
cloud_monitor( attacker, position, weapname )
{
	cloud = undefined;
	cloudRadius 			= CONST_CORROSIVE_CLOUD_RADIUS;
	cloudHeight 			= CONST_CORROSIVE_CLOUD_HEIGHT;
	cloudTickDamage 		= CONST_CORROSIVE_CLOUD_TICK_DAMAGE;
	cloudLingerTime			= CONST_CORROSIVE_CLOUD_LINGER_TIME;
	duration 				= CONST_CORROSIVE_CLOUD_DURATION;
	tickTime 				= CONST_CORROSIVE_CLOUD_TICK_TIME;
	blast_radius			= CONST_BLAST_RADIUS;
	blast_mindmg			= CONST_BLAST_MINDMG;
	blast_maxdmg			= CONST_BLAST_MAXDMG;
	attacker_team 			= attacker.team;
	
	cloud = SpawnFX( level._effect[ "corrosive_blast" ], position );
		 
	location = position - ( 0, 0, cloudHeight );
	effectHeight = cloudHeight + cloudHeight;
	
	// spawn trigger radius for the effect areas
	effectArea = spawn( "trigger_radius", location, 1, cloudRadius, effectHeight );
	effectArea.owner = attacker;
	
	self RadiusDamage( position, blast_radius, blast_maxdmg, blast_mindmg, attacker, "MOD_EXPLOSIVE", weapname );
	Earthquake( .5,1,position,512 );
	
	PlayRumbleOnPosition( "grenade_rumble", position );
	
	TriggerFX( cloud );
	
	totalTime 	= 0.0;		// keeps track of the total time the cloud has been "alive"
	initialWait = 1;		// wait this long before the cloud starts ticking for damage
	tickCounter = 0;		// just an internal counter to count  damage ticks
	
	wait( initialWait );
	totalTime += initialWait;
	
	//level thread maps\mp\alien\_utility::mark_dangerous_nodes( position, stasisCloudRadius, duration );
	while ( totalTime < cloudLingerTime )
	{
		//create array of guys affected.
		agents_touching = [];
		agents = array_combine ( level.players, level.agentArray );
		
		foreach ( agent in agents )
		{
			if( isDefined( agent ) && isAlive( agent ) && agent isTouching( effectArea ) )
			{
				agents_touching[ agents_touching.size ] = agent;
			}
			
		}
		
		//throttle
		foreach ( agent in agents_touching )
		{
			if ( !isdefined ( attacker ))
			{
			    if ( isDefined( agent ) && isReallyAlive ( agent ) && ( agent.team != attacker_team  ) )
				{
					agent thread cloud_do_damage( cloudTickDamage, undefined , duration, effectArea, tickTime , weapname, self, attacker_team );	
				}	
			}
			else
			{
				if ( isDefined( agent ) && isReallyAlive ( agent ) && ( agent.team != attacker_team || agent == attacker) )
				{
					agent thread cloud_do_damage( cloudTickDamage, attacker, duration, effectArea, tickTime , weapname, self, attacker_team );	
				}	
			}
			waitframe();
		}
		
		wait( tickTime );
		totalTime += tickTime;
	}
	
	//clean up
	effectArea delete();
	cloud delete();
}

cloud_do_damage( interval_damage, attacker, duration, damage_trigger, interval_time, weapname, projectile, attacker_team )
{
	// self is victim
	
	// only one instance of burn
	self notify( "stasis_cloud_burning" );
	self endon( "stasis_cloud_burning" );
	self endon( "death" );
	if ( IsDefined ( attacker) )
		attacker endon ( "disconnect" );
	
	if ( !isdefined( duration ) )
		duration = 6;

	elapsed_time = 0;
	while ( elapsed_time < duration )
	{
		// Don't do damage to your own team
		if ( self.team != attacker_team )
		{
			if ( isDefined ( damage_trigger ) ) //in case the damage trigger gets deleted during this while loop
			{
				// Check to see if self is a bot; we have to use a different function call if it's a player we're killing
				if ( IsBot( self ) )
				{
					projectile RadiusDamage( self.origin, 10, interval_damage, interval_damage, attacker, "MOD_PROJECTILE_SPLASH", weapname );	
				}
				else 
					self maps\mp\gametypes\_damage::finishPlayerDamageWrapper( damage_trigger, attacker, interval_damage, 0, "MOD_PROJECTILE_SPLASH", weapname, self.origin, ( 0, 0, 1 ), "none", 0, 0 );
			}
		}
		else
			if ( self == attacker && isDefined ( damage_trigger )) // Still damage the player that shot the weapon though
				damage_trigger RadiusDamage( self.origin, 10, interval_damage, interval_damage, attacker, "MOD_PROJECTILE_SPLASH", weapname );
				
		elapsed_time += interval_time;
		wait interval_time;
	}
}

give_alien_weapon( deployableBoxWeapon )
{
	if ( "iw6_maaws_mp" == self GetCurrentWeapon() || self isJuggernaut() )
		return;
	
	// There are issues with the bots using the Venom-X, so when they grab one from the deployable box, we just give them a random gun instead.
	if ( IsBot ( self ))
	{
	    maps\mp\killstreaks\_deployablebox_gun::giveRandomGun( self );
	    return;
	}
	
	if ( !self HasWeapon( WEAPON_NAME ) )
	{
		// We don't want to decrement the amount if the alien weapon was found in a box of guns
		if ( !IsDefined( deployableBoxWeapon ) || !deployableBoxWeapon )
			level.remaining_alien_weapons --;
		
		self thread special_gun_watcher();
		self GiveWeapon( WEAPON_NAME );
			
		self SetWeaponAmmoClip( WEAPON_NAME,INITIAL_AMMO_COUNT );
		// self SetWeaponAmmoStock( WEAPON_NAME,2 );
		self SwitchToWeapon( WEAPON_NAME );
		
		self thread manage_alien_weapon_inventory();
		
		self thread show_specialweapon_hint();
	}
	else
	{
		self iPrintLnBold ( &"MP_DOME_NS_ALREADY_HAVE_ALIEN_GUN" );
	}
}

// ensure the player cannot swap this weapon for another one
manage_alien_weapon_inventory()
{
	level endon( "game_ended" );
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "alien_weapon_removed" );
	while ( 1 )
	{
		if ( self GetCurrentWeapon(  ) == WEAPON_NAME )
			self DisableWeaponPickup();
		else
			self EnableWeaponPickup();
		wait .1;
	}
}

// Remove the weapon from inventory when it's out of ammo.
remove_alien_weapon( projectile )	
{
	level endon( "game_ended" );
	self endon ( "death" );
	self endon ( "disconnect" );

	projectile waittill_any ( "death", "projectile_detonate" );
	
	self SwitchToWeapon( self.primaryWeapon );
	self TakeWeapon ( WEAPON_NAME);
	self notify ( "alien_weapon_removed" );
	self EnableWeaponPickup();
}

show_specialweapon_hint()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	wait ( 1 );
	self setLowerMessage( "weapon_hint", &"MP_DOME_NS_ALIEN_GUN_HINT",6 );
}

show_specialweapon_hint_repeat()
{
	self endon( "disconnect" );
	
	wait ( 1 );
	self IPrintLnBold(&"MP_DOME_NS_ALIEN_GUN_HINT");
}