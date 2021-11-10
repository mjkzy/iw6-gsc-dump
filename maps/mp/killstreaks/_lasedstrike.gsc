#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	//PrecacheMiniMapIcon( "compass_objpoint_reaper_friendly" );
	//PrecacheMiniMapIcon( "compass_objpoint_reaper_enemy" );
	
	level.killStreakFuncs["lasedStrike"] = ::tryUseLasedStrike;
	level.numberOfSoflamAmmo = 2;
	
	level.lasedStrikeGlow = loadfx("fx/misc/laser_glow");
	level.lasedStrikeExplode = LoadFX( "fx/explosions/uav_advanced_death" );

	//level.lasedStrikeActive = false;
	//level.lasedStrikeDrone = undefined;
	
	remoteMissileSpawnArray = getEntArray( "remoteMissileSpawn" , "targetname" );
	foreach ( startPoint in remoteMissileSpawnArray )
	{
		if ( isDefined( startPoint.target ) )
			startPoint.targetEnt = getEnt( startPoint.target, "targetname" );	
	}
	level.lasedStrikeEnts = remoteMissileSpawnArray;
	
	thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
		player.soflamAmmoUsed = 0;
		player.hasSoflam = false;
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "spawned_player" );
		
		//if( isDefined( level.soflamCrate ) )
		//	level.soflamCrate maps\mp\killstreaks\_airdrop::setUsableByTeam( self.team );
	}
}


tryUseLasedStrike( lifeId, streakName )
{
	return useLasedStrike();
}


useLasedStrike()
{
	//self maps\mp\killstreaks\_killstreaks::giveKillstreakWeapon( "iw5_soflam_mp" );
	
	//level thread teamPlayerCardSplash( "teamstreak_earned_lasedStrike", self, self.team );
	used = self watchSoflamUsage();

	if ( isDefined( used ) && used )
	{
		self.hasSoflam = false;
		return true;
	}
	else
	{
		return false;
	}
}


giveMarker()
{
	//wait( .25 );
	self maps\mp\killstreaks\_killstreaks::giveKillstreakWeapon( "iw5_soflam_mp" );

	self.hasSoflam = true;
	self thread watchSoflamUsage();
}


watchSoflamUsage()
{
	self notify( "watchSoflamUsage" );
	self endon( "watchSoflamUsage" );
	
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "death" );
	
	while( self isChangingWeapon() )
			wait ( 0.05 );	
	
	for(;;)
	{

		if ( self AttackButtonPressed() && self GetCurrentWeapon() == "iw5_soflam_mp" && self AdsButtonPressed() )
		{
			//self WeaponLockNoClearance( false );
			self WeaponLockTargetTooClose( false );
			self WeaponLockFree();
			
			targetInfo = getTargetPoint();
			
			if( !isDefined( targetInfo ) )
			{	
				wait 0.05;
				continue;
			}
				
			if( !isDefined( targetInfo[0] ) )
			{	
				wait 0.05;
				continue;
			}
			
			targPoint = targetInfo[0];
			
			used = self attackLasedTarget( targPoint );
			
			if ( used ) 
				self.soflamAmmoUsed++;

			if ( self.soflamAmmoUsed >= level.numberOfSoflamAmmo )
				return true;
		}
		
		if ( self isChangingWeapon() )
			return false;
			
		wait( 0.05 );
	}
	
}

playLockSound()
{
	if ( isDefined( self.playingLockSound ) && self.playingLockSound )
		return;
	
	self PlayLocalSound( "javelin_clu_lock" );
	self.playingLockSound = true;
	
	wait( .75 );
	
	self StopLocalSound( "javelin_clu_lock" );
	self.playingLockSound = false;
}

playLockErrorSound()
{
	if ( isDefined( self.playingLockSound ) && self.playingLockSound )
		return;
	
	self PlayLocalSound( "javelin_clu_aquiring_lock" );
	self.playingLockSound = true;
	
	wait( .75 );
	
	self StopLocalSound( "javelin_clu_aquiring_lock" );
	self.playingLockSound = false;
}


attackLasedTarget( targPoint )
{
	finalTargetEnt = undefined;
	midTargetEnt = undefined;
	
	upQuantity = 6000;
	upVector = (0, 0, upQuantity );
	backDist = 3000;
	forward = AnglesToForward( self.angles );
	ownerOrigin = self.origin;
	startpos = ownerOrigin + upVector + forward * backDist * -1;
	
	foundAngle = false;
	
	//straight down
	
	skyTrace = bulletTrace( targPoint + (0,0,upQuantity), targPoint , false );
	if( skyTrace["fraction"] > .99 )
	{
		foundAngle = true;	
		startPos = targPoint + (0,0,upQuantity);
	}
	//self thread drawLine( targPoint, targPoint + (0,0,upQuantity), 25, (1,0,0) );
	
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (300,0,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (300,0,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (300,0,upQuantity), 25, (1,0,0) );
	}
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (0,300,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (0,300,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (0,300,upQuantity), 25, (1,0,0) );
	}
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (0,-300,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (0,-300,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (0,-300,upQuantity), 25, (1,0,0) );
	}
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (300,300,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (300,300,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (300,300,upQuantity), 25, (1,0,0) );
	}
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (-300,0,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (-300,0,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (-300,0,upQuantity), 25, (1,0,0) );
	}
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (-300,-300,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (-300,-300,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (-300,-300,upQuantity), 25, (1,0,0) );
	}
	
	if( !foundAngle )
	{	
		skyTrace = bulletTrace( targPoint + (300,-300,upQuantity), targPoint , false );
		if( skyTrace["fraction"] > .99 )
		{
			foundAngle = true;	
			startPos = targPoint + (300,-300,upQuantity);
		}
	 	//self thread drawLine( targPoint, targPoint + (300,-300,upQuantity), 25, (1,0,0) );
	}
	
	//backwards vector from player over target area
	if( !foundAngle )
	{	
		for ( i = 0; i < 5; i++ )
		{
			upQuantity = upQuantity / 2;
			upVector = (0, 0, upQuantity );
			startpos = self.origin + upVector + forward * backDist * -1;
			
			targetSkyCheck = BulletTrace( targPoint, startpos, false );
			if ( targetSkyCheck["fraction"] > .99 )
			{
				foundAngle = true;
				break;
			}
			wait( 0.05 );
		}
	}

	//check increased angle to try to get it over large objects
	if( !foundAngle )
	{
		for ( i = 0; i < 5; i++ )
		{
			upQuantity = upQuantity * 2.5;
			
			upVector = (0, 0, upQuantity );
			startpos = self.origin + upVector + forward * backDist * -1;
			
			targetSkyCheck = BulletTrace( targPoint, startpos, false );
			if ( targetSkyCheck["fraction"] > .99 )
			{
				foundAngle = true;
				break;
			}
			wait( 0.05 );
		}
	}
	
	if( !foundAngle )
	{
		self thread cantHitTarget();
		return false;
	}

	//finalTargetEnt = Spawn( "script_origin", targPoint );
	finalTargetEnt = SpawnFx( level.lasedStrikeGlow, targPoint );	
	
	self thread playLockSound();
	//self WeaponLockFinalize( finalTargetEnt, (0,0,0), false );
	self WeaponLockFinalize( targPoint, (0,0,0), false );
	
	missile = MagicBullet("lasedStrike_missile_mp", startPos, targPoint, self);
	missile Missile_SetTargetEnt( finalTargetEnt );

	self thread loopTriggeredeffect( finalTargetEnt, missile );
	
	missile waittill( "death" );
	
	if( isDefined( finalTargetEnt ) )
	{	
		finalTargetEnt delete();
	}
		
	self WeaponLockFree();
	return true;
}

loopTriggeredEffect( effect, missile )
{
	missile endon( "death" );
	level endon( "game_ended" );
	
	for( ;; )
	{
		TriggerFX( effect );
		wait ( 0.05 );
	}
	
}


lasedMissileDistance( remote )
{
	level  endon( "game_ended" );
	remote endon( "death" );
	remote endon( "remote_done" );
	self   endon( "death" );
	
	while( true )
	{
		targetDist = distance( self.origin, remote.targetent.origin );
		remote.owner SetClientDvar( "ui_reaper_targetDistance", int( targetDist / 12 ) );
		
		wait( 0.05 );
	}
}	

cantHitTarget()
{
	self thread playLockErrorSound();
	//self WeaponLockNoClearance( true );
	self WeaponLockTargetTooClose( true );
}


//does one check per frame
checkBestTargetVector( remote, targPoint )
{

	foreach( ent in level.lasedStrikeEnts )
	{
		check = BulletTrace( ent.origin, targPoint, false, remote );
		if ( check["fraction"] >= .98 )
		{
			return ent;
		}
		
		wait (0.05 );
	}
	
	return;
}


getTargetPoint()
{
	origin = self GetEye();
	angles = self GetPlayerAngles();
	forward = AnglesToForward( angles );
	endpoint = origin + forward * 15000;
	
	res = BulletTrace( origin, endpoint, false, undefined );

	if ( res["surfacetype"] == "none" )
		return undefined;
	if ( res["surfacetype"] == "default" )
		return undefined;

	ent = res["entity"];
	if ( IsDefined( ent ) )
	{
		if ( ent == level.ac130.planeModel )
			return undefined;
	}

	results = [];
	results[0] = res["position"];
	results[1] = res["normal"];
	
	return results;
}


//Not In Use
spawnRemote( owner )
{
	remote = spawnPlane( owner, "script_model", level.UAVRig getTagOrigin( "tag_origin" ), "compass_objpoint_reaper_friendly", "compass_objpoint_reaper_enemy" );
	if ( !isDefined( remote ) )
		return undefined;
		
	remote setModel( "vehicle_predator_b" );
	remote.team = owner.team;
	remote.owner = owner;
	remote.numFlares = 2;
	
	remote setCanDamage( true );	
	remote thread damageTracker();
	
	remote.heliType = "remote_mortar";	
	
	//	for target lists (javelin, stinger, sam, emp, etc)
	remote.uavType = "remote_mortar";	
	remote maps\mp\killstreaks\_uav::addUAVModel();

	//	same height and radius as the AC130 with random angle and counter rotation
	zOffset = 6300;
	angle = randomInt( 360 );
	radiusOffset = 6100;
	xOffset = cos( angle ) * radiusOffset;
	yOffset = sin( angle ) * radiusOffset;
	angleVector = vectorNormalize( (xOffset,yOffset,zOffset) );
	angleVector = ( angleVector * 6100 );
	remote linkTo( level.UAVRig, "tag_origin", angleVector, (0,angle-90,10) );	
	
	remote thread handleDeath( owner );

	remote thread handleOwnerChangeTeam( owner );
	remote thread handleOwnerDisconnect( owner );
	remote thread handleTimeOut();
	
	remote thread handleIncomingStinger();
	remote thread handleIncomingSAM();

	return remote;	
}


handleDeath( owner )
{
	level endon( "game_ended" );	
	owner endon( "disconnect" );
	self endon( "remote_removed" );
	self  endon( "remote_done" );

	self waittill( "death" );
		
	level thread removeRemote( self, true );
}


handleOwnerChangeTeam( owner )
{
	level endon( "game_ended" );
	self  endon( "remote_done" );
	self  endon( "death" );
	owner endon( "disconnect" );
	owner endon( "removed_reaper_ammo" );
		
	owner waittill_any( "joined_team", "joined_spectators" );
	
	self thread remoteLeave();	
}


handleOwnerDisconnect( owner )
{
	level endon( "game_ended" );
	self  endon( "remote_done" );
	self  endon( "death" );
	owner endon( "removed_reaper_ammo" );
	
	owner waittill( "disconnect" );
	
	self thread remoteLeave();
}


shotCounter()
{
	level endon( "game_ended" );
	self endon( "death" );
	self  endon( "remote_done" );
	
	numShotsFired = 0;
	
	for( ;; )
	{
		self waittill( "lasedTargetShotFired" );
		
		numShotsFired++;
		
		if ( numShotsFired >= 5 )
			break;
	}
	
	self thread remoteLeave();
}


handleTimeOut()
{
	level endon( "game_ended" );
	self endon( "death" );
	self  endon( "remote_done" );
	
	wait 120;
	
	self thread remoteLeave();
}

removeRemote( remote, clearLevelRef )
{
	self notify( "remote_removed" );
	
	if ( isDefined( remote.targetEnt ) )
		remote.targetEnt delete();

	level.lasedStrikeActive = false;
	level.lasedStrikeCrateActive = false;

	if( IsDefined( remote ) )
	{
		remote delete();	
		remote maps\mp\killstreaks\_uav::removeUAVModel();
	}
	
	if ( !IsDefined( clearLevelRef ) || clearLevelRef == true )
		level.remote_mortar = undefined;
}


remoteLeave()
{
	// setting the level variable here because there is a bug if this gets shot down on the way out then this doesn't get cleared because of the endon("death")
	//	now it'll definitely get cleared as soon as it tries to leave
	level.remote_mortar = undefined;

	level endon( "game_ended" );
	self  endon( "death" );
	
	self notify( "remote_done" );			
	
	destPoint = self.origin + ( AnglesToForward( self.angles ) * 20000 );
	self moveTo( destPoint, 30 );
	PlayFXOnTag( level._effect[ "ac130_engineeffect" ] , self, "tag_origin" );
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 3 );

	self moveTo( destPoint, 4, 4, 0.0 );
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 4 );		
	
	level thread removeRemote( self, false );		
}


remoteExplode()
{
	self notify( "death" );
	self Hide();
	forward = ( AnglesToRight( self.angles ) * 200 );
	playFx ( level.lasedStrikeExplode, self.origin, forward );		
	
	level.lasedStrikeActive = false;
	level.lasedStrikeCrateActive = false;
}


//	Entities spawned from SpawnPlane do not respond to pre-damage callbacks 
//	so we have to wait until we get the post-damage event.
//
//	Because the damage has already happened by the time we find out about it,
//	we need to use an artificially high health value, restore it on erroneous damage
//	events and track a virtual damage taken against a virtual max health.
damageTracker()
{	
	level endon( "game_ended" );
	self.owner endon( "disconnect" );
	
	self.health = 999999; // keep it from dying anywhere in code
	self.maxHealth = 1500; // this is the health we'll check
	self.damageTaken = 0; // how much damage has it taken
	
	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );		
				
		// don't allow people to destroy things on their team if FF is off
		if ( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
			continue;

		if ( !IsDefined( self ) )
			return;

		if ( isDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
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
				modifiedDamage = self.maxhealth + 1;
				break;

			case "sam_projectile_mp":
				self.largeProjectileDamage = true;		
				break;
			}
			
			maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
		}

		self.damageTaken += modifiedDamage;
		
		if( IsDefined( self.owner ) )
			self.owner playLocalSound( "reaper_damaged" );
					
		if ( self.damageTaken >= self.maxHealth )
		{
			if ( isPlayer( attacker ) && ( !isDefined( self.owner ) || attacker != self.owner ) )
			{						
				attacker notify( "destroyed_killstreak", weapon );
				thread teamPlayerCardSplash( "callout_destroyed_remote_mortar", attacker );			
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 50, weapon, meansOfDeath );			
				attacker thread maps\mp\gametypes\_rank::xpEventPopup( "destroyed_remote_mortar" );
				thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, damage, meansOfDeath, weapon );
				
			}
			
			if ( isDefined( self.owner ) )
				self.owner StopLocalSound( "missile_incoming" );
			
			self thread remoteExplode();			
			// adding this to make sure it gets undefined, there was a weird bug where it could get killed as soon as it was leaving
			//	then the threads got killed because of the endon's and this never got reset
			level.remote_mortar = undefined;
			return;
		}			
	}	
}

handleIncomingStinger() // self == remote mortar
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "remote_done" );

	while( true )
	{
		level waittill ( "stinger_fired", player, missile, lockTarget );

		if ( !IsDefined( lockTarget ) || (lockTarget != self) )
			continue;

		missile thread stingerProximityDetonate( lockTarget, player );
	}
}

stingerProximityDetonate( missileTarget, player ) // self == missile
{
	self endon ( "death" );
	missileTarget endon( "death" );

	if( IsDefined( missileTarget.owner ) )
		missileTarget.owner PlayLocalSound( "missile_incoming" );

	self Missile_SetTargetEnt( missileTarget );

	minDist = Distance( self.origin, missileTarget GetPointInBounds( 0, 0, 0 ) );
	lastCenter = missileTarget GetPointInBounds( 0, 0, 0 );

	while( true )
	{		
		// already destroyed
		if( !IsDefined( missileTarget ) )
			center = lastCenter;
		else
			center = missileTarget GetPointInBounds( 0, 0, 0 );

		lastCenter = center;		

		curDist = Distance( self.origin, center );

		if( curDist < 3000 && missileTarget.numFlares > 0 )
		{
			missileTarget.numFlares--;			

			missileTarget thread maps\mp\killstreaks\_flares::flares_playFx();	
			newTarget = missileTarget maps\mp\killstreaks\_flares::flares_deploy();

			self Missile_SetTargetEnt( newTarget );
			missileTarget = newTarget;
			
			if( IsDefined( missileTarget.owner ) )
				missileTarget.owner StopLocalSound( "missile_incoming" );

			return;
		}		

		if( curDist < minDist )
			minDist = curDist;

		if( curDist > minDist )
		{
			if( curDist > 1536 )
				return;

			if( IsDefined( missileTarget.owner ) )
			{
				missileTarget.owner stopLocalSound( "missile_incoming" ); 

				if( level.teambased )
				{
					if( missileTarget.team != player.team )
						RadiusDamage( self.origin, 1000, 1000, 1000, player, "MOD_EXPLOSIVE", "stinger_mp" );
				}
				else
				{
					RadiusDamage( self.origin, 1000, 1000, 1000, player, "MOD_EXPLOSIVE", "stinger_mp" );
				}
			}

			self Hide();

			wait( 0.05 );
			self delete();
		}

		wait ( 0.05 );
	}	
}

handleIncomingSAM() // self == remote mortar
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "remote_done" );

	while( true )
	{
		level waittill ( "sam_fired", player, missileGroup, lockTarget );

		if ( !IsDefined( lockTarget ) || (lockTarget != self) )
			continue;

		level thread samProximityDetonate( lockTarget, player, missileGroup );
	}
}

samProximityDetonate( missileTarget, player, missileGroup )
{
	missileTarget endon( "death" );

	if( IsDefined( missileTarget.owner ) )
		missileTarget.owner PlayLocalSound( "missile_incoming" );

	sam_projectile_damage = 150; // this should match the gdt entry
	sam_projectile_damage_radius = 1000;

	minDist = [];
	for( i = 0; i < missileGroup.size; i++ )
	{
		if( IsDefined( missileGroup[ i ] ) )
			minDist[ i ] = Distance( missileGroup[ i ].origin, missileTarget GetPointInBounds( 0, 0, 0 ) );
		else
			minDist[ i ] = undefined;
	}

	while( true )
	{
		center = missileTarget GetPointInBounds( 0, 0, 0 );

		curDist = [];
		for( i = 0; i < missileGroup.size; i++ )
		{
			if( IsDefined( missileGroup[ i ] ) )
				curDist[ i ] = Distance( missileGroup[ i ].origin, center );
		}

		for( i = 0; i < curDist.size; i++ )
		{
			if( IsDefined( curDist[ i ] ) )
			{
				// if one of the missiles in the group get close, set off flares and redirect them all
				if( curDist[ i ] < 3000 && missileTarget.numFlares > 0 )
				{
					missileTarget.numFlares--;			

					missileTarget thread maps\mp\killstreaks\_flares::flares_playFx();	
					newTarget = missileTarget maps\mp\killstreaks\_flares::flares_deploy();

					for( j = 0; j < missileGroup.size; j++ )					
					{
						if( IsDefined( missileGroup[ j ] ) )
						{
							missileGroup[ j ] Missile_SetTargetEnt( newTarget );
						}
					}

					if( IsDefined( missileTarget.owner ) )
						missileTarget.owner StopLocalSound( "missile_incoming" );

					return;
				}		

				if( curDist[ i ] < minDist[ i ] )
					minDist[ i ] = curDist[ i ];

				if( curDist[ i ] > minDist[ i ] )
				{
					if( curDist[ i ] > 1536 )
						continue;

					if( IsDefined( missileTarget.owner ) )
					{
						missileTarget.owner StopLocalSound( "missile_incoming" ); 

						if( level.teambased )
						{
							if( missileTarget.team != player.team )
								RadiusDamage( missileGroup[ i ].origin, sam_projectile_damage_radius, sam_projectile_damage, sam_projectile_damage, player, "MOD_EXPLOSIVE", "sam_projectile_mp" );
						}
						else
						{
							RadiusDamage( missileGroup[ i ].origin, sam_projectile_damage_radius, sam_projectile_damage, sam_projectile_damage, player, "MOD_EXPLOSIVE", "sam_projectile_mp" );
						}
					}

					missileGroup[ i ] Hide();

					wait ( 0.05 );
					missileGroup[ i ] delete();
				}
			}
		}

		wait ( 0.05 );
	}	
}
