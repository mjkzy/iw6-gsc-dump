#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_weapons;

PROTECTION_DIST_SQ = 256 * 256;
PREDATOR_PROTECTION_DIST_SQ = 384 * 384;
SWITCHBLADE_PROTECTION_DIST_SQ = 1024 * 1024;
HIND_PROTECTION_DIST_SQ = 384 * 384;

trophyUsed( grenade ) // self == player
{
	self endon( "spawned_player" );
	self endon( "disconnect" );
	
	if( !IsAlive( self ) )
	{
		grenade delete();
		return;
	}
	
	if( self IsOnLadder() 
	   || !self IsOnGround() )
	{
		// 2013-08-01 wallace: as always, the grenade itself knows whether it is "alientrophy_mp" or "trophy_mp"
		self restockTrophy( grenade.weapon_name );
		grenade delete();
		return;
	}

	if ( isDefined( self.OnHeliSniper ) && self.OnHeliSniper )
	{
		grenade delete();
		self.heliSniper thread trophyActive( self );
		return;
	}

	// need to see if this is being placed far away from the player and not let it do that
	// this will fix a legacy bug where you can stand on a ledge and plant a claymore down on the ground far below you
	grenade Hide();
	
	// grenade waittill( "missile_stuck", stuckTo );
	
	placement = self CanPlayerPlaceSentry( true, 12 );
	if ( placement[ "result" ] 
	    && is_normal_upright( AnglesToUp( placement[ "angles" ] ) )
	   )
	{
		grenade.origin = placement[ "origin" ];
		grenade.angles = placement[ "angles" ];
	}
	else
	{
		// 2013-08-22 wallace: set the trophy to the player's position to address all sorts of weird placement issues (falling through cracks, clipping through walls at weird angles)
		// this will cause the playe to clip through the trophy, though.
		grenade.origin = self.origin;
		grenade.angles = self.angles;
	}
	
	grenade Show();
	
	// these sounds used to be in the gdt grenade fire, but we want to be able to play the scavenger sound if there was a bad placement
	self PlayLocalSound( "trophy_turret_plant_plr" );
	self PlaySoundToTeam( "trophy_turret_plant_npc", "allies", self );
	self PlaySoundToTeam( "trophy_turret_plant_npc", "axis", self );
	
	// need to spawn in a model and delete the "grenade" so we can damage it properly
	trophy = Spawn( "script_model", grenade.origin );
	assert( IsDefined( trophy ) );
	
	//trophy maketrophysystem( self );
	trophy SetModel( "mp_trophy_system_iw6" );
	trophy thread createBombSquadModel( "mp_trophy_system_iw6_bombsquad", "tag_origin", self );
	trophy.angles = grenade.angles;
	trophy.team = self.team;
	trophy.owner = self;
	trophy.isTallForWaterChecks = true;	// make sure that this is not destroyed by the water script in mp_flooded
	
	if ( isDefined ( self.trophyRemainingAmmo ) && self.trophyRemainingAmmo > 0 )
		trophy.ammo = self.trophyRemainingAmmo;
	else if (is_aliens() )
		trophy.ammo = 5;
	else
		trophy.ammo = 2;

	// calculate an origin that is both closer to the center of the trophy system model and higher off the ground to improve the player use trace over uneven/angled script_brushmodels
	offset_magnitude = 16;
	offset_vector = AnglesToUp( trophy.angles );
	offset_vector = offset_magnitude * offset_vector;
	offset_origin = trophy.origin + offset_vector;
	
	trophy.trigger = spawn( "script_origin", offset_origin );
	//trophy.trigger EnableLinkTo();
	trophy.trigger LinkTo( trophy );
	
	trophy thread trophyDamage( self );
	trophy thread trophyWaitForDetonation();
	trophy thread trophyActive( self );
	trophy thread trophyDisconnectWaiter( self );
	trophy thread trophyPlayerSpawnWaiter( self );
	trophy thread trophyUseListener( self );
	
	trophy SetOtherEnt( self );
	trophy maps\mp\gametypes\_weapons::makeExplosiveTargetableByAI( true );
	trophy maps\mp\gametypes\_weapons::explosiveHandleMovers( placement[ "entity" ], true );
	
	if ( level.teamBased )
		trophy maps\mp\_entityheadicons::setTeamHeadIcon( self.team, (0,0,65) );
	else
		trophy maps\mp\_entityheadicons::setPlayerHeadIcon( self, (0,0,65) );
	
	self onTacticalEquipmentPlanted( trophy );
	
	trophy thread playAnimations();
	
	if( IsDefined( grenade ) )
	{
		waitframe();
		grenade Delete();
	}
	if( is_aliens() )
		self TakeWeapon( "alientrophy_mp" );
}

//waittillStopMoving( timeout )
//{
//	self endon( "death" );
//
//	prevOrigin = undefined;
//	while( true )
//	{
//		if( !IsDefined( prevOrigin ) )
//			prevOrigin = self.origin;
//		else if( prevOrigin == self.origin )
//			break;
//		else
//			prevOrigin = self.origin;
//
//		wait(0.05);
//		
//		timeout -= 0.05;
//		if( timeout <= 0 )
//			return false;
//	}
//
//	return true;
//}

trophyUseListener( owner ) // self == trophy
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	owner endon ( "death" );
	
	self.trigger setCursorHint( "HINT_NOICON" );
	self.trigger setHintString( &"MP_PICKUP_TROPHY" );
	self.trigger setSelfUsable( owner );
	self.trigger thread notUsableForJoiningPlayers( owner );

	for ( ;; )
	{
		self.trigger waittill ( "trigger", owner );
		
		self StopLoopSound();
				
		if ( is_aliens() )
		{			
			offhandweapons = owner GetWeaponsListOffhands();
			cannot_pick_up = undefined;
			
			foreach ( offhandweapon in offhandweapons )
			{
				if ( offhandweapon == "alienflare_mp" || offhandweapon == "alientrophy_mp" || offhandweapon == "alienthrowingknife_mp" || ( isDefined( level.trophy_use_pickupfunc ) && [[level.trophy_use_pickupfunc]]( offhandweapon) ) )
				{
					ammo_count = owner GetAmmoCount( offhandweapon );
					if ( ammo_count > 0 )
					{
						owner setLowerMessage( "slots_full", &"ALIEN_COLLECTIBLES_TACTICAL_FULL", 3 );
						cannot_pick_up = true;
						break;
					}
				}
			}
			if ( !IsDefined( cannot_pick_up ) )
			{
				owner setOffhandSecondaryClass( "flash" ); //ALIENS USES THIS CLASS FOR THE TROPHY SYSTEM
				owner playLocalSound( "scavenger_pack_pickup" );
				owner.trophyRemainingAmmo = self.ammo;
				owner TakeWeapon ( "alientrophy_mp" );
				owner _giveweapon ( "alientrophy_mp" );
				self ScriptModelClearAnim();
				
				self deleteExplosive();
				self notify( "death" );
			}
		}
		else  // give item to user if not juggernaut (switched class)  but in aliens we want juggs to be able to move the trophy	
		{
			if(	!owner isJuggernaut() )
			{
				owner restockTrophy( "trophy_mp" );
				owner.trophyRemainingAmmo = self.ammo;
				self ScriptModelClearAnim();
				
				self deleteExplosive();
				self notify( "death" );
			}
		}
	}
}

trophyPlayerSpawnWaiter( owner )
{
	self endon ( "disconnect" );
	self endon ( "death" );
	
	owner waittill( "spawned" );
	self notify ( "detonateExplosive" );
}

trophyDisconnectWaiter( owner )
{
	self endon ( "death" );
	
	owner waittill( "disconnect" );
	self notify ( "detonateExplosive" );
}

trophyActive( owner )
{
	owner endon( "disconnect" );
	self endon ( "death" );
	
	// 2013-08-22 wallace: camera_jnt is at the position of the camera sensor in the IW6 model
	// we use this is our ref point b/c self.origin might sometimes be underground, which would cause the BulletTracePassed call to fail
	if ( is_aliens() && self.model == "mp_weapon_alien_crate" ) //aliens engineer class slow field bubble also works as a trophy
		position = self.origin;
	else
		position = self GetTagOrigin( "camera_jnt" );
	
	if ( IsDefined ( self.cameraOffset ) )
		self.cameraOffsetVector = (0, 0, self.cameraOffset);
	else
		self.cameraOffsetVector = position - self.origin;	// add this in case the trophy is on a moving platform
	normalProtectionDistanceSquared = 256 * 256;
	specialProtectionDistanceSquared = 384 * 384;
	
	self.killCamEnt = Spawn( "script_model", position + ( 0, 0, 5 ) );
	self.killCamEnt LinkTo( self );
	
	if ( !IsDefined( level.grenades ) )
		level.grenades = [];
	if ( !IsDefined( level.missiles ) )
		level.missiles = [];
	
	for( ;; )
	{
		if ( IsDefined( self.disabled )
		    || ( level.grenades.size < 1 && level.missiles.size < 1 )
		   )
		{
			wait( .05 );
			continue;
		}
		
		sentryTargets = array_combine ( level.grenades, level.missiles );
			
		foreach ( grenade in sentryTargets )
		{
			if ( !isDefined(grenade) )
				continue;
			
			if ( grenade == self )
				continue;
			
			if ( IsDefined( grenade.exploding ) )
			{
				AssertEx( grenade.exploding == true, "grenade.exploding should always be set to true" );
				continue;
			}
			
			if ( isDefined( grenade.weapon_name ) )
			{
				switch( grenade.weapon_name )
				{
					case "trophy_mp":
					case "claymore_mp":
					case "throwingknife_mp":
					case "throwingknifejugg_mp":
					case "airdrop_marker_mp":
					case "deployable_vest_marker_mp":
					case "deployable_weapon_crate_marker_mp":
					case "odin_projectile_marking_mp":
					case "odin_projectile_smoke_mp":
					case "odin_projectile_airdrop_mp":
					case "odin_projectile_large_rod_mp":
					case "odin_projectile_small_rod_mp":
						continue;
				}
			}

			if ( !isDefined( grenade.owner ) )
				grenade.owner = GetMissileOwner( grenade );
			
			//assertEx( isDefined( grenade.owner ), "grenade has no owner"  );
			//grenades owner may have disconnected by now if they do we should just assume enemy and detonate it.
			
			if ( IsDefined( grenade.owner ) && !(owner isEnemy( grenade.owner ) ) )
				continue;
			
			// If this is a night owl, we need to make sure we update the position, otherwise it will no longer block grenades when it moves to a new location
			if ( isDefined( self.cameraOffsetVector ) )
				position = self.origin + self.cameraOffsetVector;
			
			grenadeDistanceSquared = DistanceSquared( grenade.origin, position );
			
			protectionDistanceSquared = trophy_getProtectionDistance( grenade );	
			
			if ( grenadeDistanceSquared < protectionDistanceSquared )
			{
				// can't use BulletTracePassed any more b/c traces collide with C4 for some reason?
				// we are checking the trace fraction to make sure it is getting to the target entity (ala nothing in the way), then we want to make sure the target entity is the grenade
				traceResult = BulletTrace( position, grenade.origin, false, self );
				if ( traceResult[ "fraction" ] == 1 || ( IsDefined( traceResult[ "entity" ] ) && traceResult[ "entity" ] == grenade ) )
				{
					playFX( level.sentry_fire, position, ( grenade.origin - position ), AnglesToUp( self.angles ) );
					self playSound( "trophy_detect_projectile" );

					// do a little extra if this was a predator missile or reaper missile
					if( trophy_grenadeIsKillstreakMissile( grenade ) )
					{
						if( IsDefined( grenade.type ) && grenade.type == "remote" )
						{
							// show that you destroyed a killstreak and give the streak point
							level thread maps\mp\gametypes\_missions::killstreakKilled( grenade.owner, owner, undefined, owner, undefined, "MOD_EXPLOSIVE", "trophy_mp" );
							level thread teamPlayerCardSplash( "callout_destroyed_predator_missile", owner );
							owner thread maps\mp\gametypes\_rank::giveRankXP( "kill", 100, "trophy_mp", "MOD_EXPLOSIVE" );				
							owner notify( "destroyed_killstreak", "trophy_mp" );
						}

						// play fx and a sound
						if( IsDefined( level.chopper_fx["explode"]["medium"] ) )
							PlayFX( level.chopper_fx["explode"]["medium"], grenade.origin );
						if( IsDefined( level.barrelExpSound ) )
							grenade PlaySound( level.barrelExpSound );
					}

					owner thread projectileExplode( grenade, self );
					owner maps\mp\gametypes\_missions::processChallenge( "ch_noboomforyou" );
					
					if( !is_aliens() )
					{
						//for weapons stats tracking
						owner thread maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName( "trophy_mp", 1, "hits" );
					}
					
					self.ammo--;
					
					if ( self.ammo <= 0 )
					{
						// if we are out of ammo then we don't need to track the remaining ammo
						//	there was a bug here where every trophy set down after this would only have 1 ammo
						owner.trophyRemainingAmmo = undefined;	
						self notify ( "detonateExplosive" );
					}
				}
			}
		}
		
		wait( .05 );
	}
}

trophy_grenadeIsKillstreakMissile( grenade )
{
	return ( ( IsDefined( grenade.classname ) && grenade.classname == "rocket" ) &&
			( IsDefined( grenade.type ) && ( grenade.type == "remote" || grenade.type == "remote_mortar" ) ) );
}

trophy_getProtectionDistance( grenade )
{
	// !!! HACK
	// the child projectile moves even faster than other killstreak missiles. 
	// also the check has to come first, because it will also pass the second check
	if ( isDefined ( grenade.weapon_name) && grenade.weapon_name == "switch_blade_child_mp" )
	{
		return SWITCHBLADE_PROTECTION_DIST_SQ;
	}
	// if the projectile in a predator missile or reaper missile then we need a larger radius check because of speed
	else if ( trophy_grenadeIsKillstreakMissile( grenade ) )
	{
		return PREDATOR_PROTECTION_DIST_SQ;
	}
	else if ( isDefined ( grenade.weapon_name) && ( grenade.weapon_name == "hind_missile_mp" || grenade.weapon_name == "hind_bomb_mp" ) )
	{
		return HIND_PROTECTION_DIST_SQ;
	}
	else
	{
		return PROTECTION_DIST_SQ;
	}
}

projectileExplode( projectile, trophy ) // self == owner
{
	self endon( "death" );
	
	projPosition = projectile.origin;
	projType = projectile.model;
	projAngles = projectile.angles;
	
	projectile StopSounds();
	projectile.exploding = true;
	
	if ( projType == "weapon_light_marker" )
	{
		playFX( level.empGrenadeExplode, projPosition, AnglesToForward( projAngles ), AnglesToUp( projAngles ) );
		
		trophy notify ( "detonateExplosive" );
		
		waitframe();
		projectile delete();
		return;
	}
	
	trophy playSound( "trophy_fire" );
	playFX( level.mine_explode, projPosition, AnglesToForward( projAngles ), AnglesToUp( projAngles ) );
	if ( is_aliens() )
	{
		trophy RadiusDamage( projPosition, 128, 105, 10, self, "MOD_EXPLOSIVE", "alientrophy_mp" );
	}
	else
	{
		trophy RadiusDamage( projPosition, 128, 105, 10, self, "MOD_EXPLOSIVE", "trophy_mp" );
	}
	
	// wait for stop sounds
	waitframe();
	
	if ( IsDefined( projectile ) )
	{
		projectile delete();
	}
}

trophyDamage( owner )
{
	self maps\mp\gametypes\_damage::monitorDamage(
		100,
		"trophy",
		::trophyHandleDeathDamage,
		::trophyModifyDamage,
		false	// isKillstreak
	);
}

trophyModifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	// modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

trophyHandleDeathDamage( attacker, weapon, type, damage )	// self == trophy
{
	if( IsDefined( self.owner ) && attacker != self.owner )
	{
		attacker notify("destroyed_equipment");
	}
	
	self notify ( "detonateExplosive" );
}

trophyWaitForDetonation()
{
	level endon ("game_ended");
	
	self waittill ("detonateExplosive" );
	
	self ScriptModelClearAnim();
	self StopLoopSound();
	
	self equipmentDeathVfx();
	
	self notify( "death" );
	
	placement = self.origin;
	
	self.trigger MakeUnusable();
	self FreeEntitySentient();
	
	wait(3);//timer for trophy to self delete
	
	if ( IsDefined( self ) )
	{
		if( IsDefined( self.killCamEnt ) )
			self.killCamEnt delete();
	
		self equipmentDeleteVfx();
		
		self deleteExplosive();
	}
}

#using_animtree( "animated_props" );
playAnimations()	// self
{
	self endon( "emp_damage" );
	self endon( "death" );
	
	self ScriptModelPlayAnim( "trophy_system_deploy" );
	
	animLength = GetAnimLength( %trophy_system_deploy );
	wait( animLength );
	
	self ScriptModelPlayAnim( "trophy_system_idle" );
	self PlayLoopSound( "trophy_turret_rotate_lp" );
	
	// play vfx
	// upLinkEnt thread maps\mp\gametypes\_weapons::doBlinkingLight( "tag_fx" );
}

restockTrophy( weapon_name )	// self == player
{
	self PlayLocalSound( "scavenger_pack_pickup" );
	self SetWeaponAmmoStock( weapon_name, self GetWeaponAmmoStock( weapon_name ) + 1 );
}

// stolen from aliens utility
is_normal_upright( normal )
{
	UPRIGHT_VECTOR = ( 0, 0, 1 );
	UPRIGHT_DOT = 0.85;
	return ( VectorDot( normal, UPRIGHT_VECTOR ) > UPRIGHT_DOT );
}
