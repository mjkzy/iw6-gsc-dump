#include maps\mp\_utility;
#include common_scripts\utility;

/* Portable AOE generator
 * 2013-03-25 wsh
 * Class of equipment that can be placed and moved in the world
 * that affects all targeted players in an area around the deployed equipment
 * examples: scrambler, portable radar
 * Adapted from old scrambler code.
 */
init()
{
	if ( !IsDefined( level.portableAOEgeneratorSettings ) )
	{
		level.portableAOEgeneratorSettings = [];
		level.generators = [];
	}
	
	// in your specific implementation, need to set these config vars
	/*
	config = SpawnStruct();
	config.generatorType = GENERATOR_TYPE;
	config.weaponName = "scrambler_mp";
	config.targetType = "enemy"; // valid types { "friendly", "enemy", "all" }
	// callbacks are in the format: generator callbackFunc( player, generatorType )
	config.onDeployCallback = ::onCreateScrambler;
	config.onDestroyCallback = ::onDestroyScrambler;
	// callbacks are in the format: player callbackFunc()
	config.onEnterCallback = ::onEnterScrambler;
	config.onExitCallback = ::onExitScrambler;
	// config.timeLimit = undefined;
	config.health = 100;
	config.placementZTolerance = 40;
	config.placedModel = "weapon_jammer";
	config.bombSquadModel = "weapon_jammer_bombsquad";
	config.damageFeedback = "scrambler";
	config.useHintString = &"MP_PATCH_PICKUP_SCRAMBLER";
	config.headIconHeight = 20;
	config.useSound = "scavenger_pack_pickup";
	config.aoeRadius = 512;
	*/
}

// make sure that killstreaks don't get ammo refills
setWeapon( generatorType )	// self == player
{
	config = level.portableAOEgeneratorSettings[ generatorType ];
	self SetOffhandSecondaryClass( "flash" );
	self _giveWeapon( config.weaponName, 0 );
	self giveStartAmmo( config.weaponName );
	
	if ( !IsDefined( self.deployedGenerators ) )
	{
		self.deployedGenerators = [];
	}
	
	self thread monitorGeneratorUse( generatorType );
}

unsetWeapon( generatorType )	// self == player
{
	self notify( "end_monitorUse_" + generatorType );
}

deleteGenerator( generator, generatorType )	// self == player
{
	if ( !IsDefined( generator ) )
	{
		return;
	}

	foreach ( player in level.players )
	{
		if ( IsDefined( player ) 
		    && IsDefined( player.inGeneratorAOE ) 
		   )
		{
			// need to check if this array is defined
			// or create it
			// !!!
			player.inGeneratorAOE[ generatorType ] = undefined;
		}
	}
	
	// remove all references to this generator
	self registerGenerator( generator, generatorType, undefined );
	
	generator notify( "death" );
	generator Delete();
}

// bRegister = true to register
// 			 = undefined to unregister
registerGenerator( generator, generatorType, bRegister )	// self == player
{
	if ( IsDefined( bRegister ) && bRegister )
	{
		self.deployedGenerators[ generatorType ] = generator;
	}
	else
	{
		self.deployedGenerators[ generatorType ] = undefined;
		bRegister = undefined;	// just to make sure people aren't passing in false
	}
	
	allGeneratorsOfThisType = level.generators[ generatorType ];
	if ( !IsDefined( allGeneratorsOfThisType ) )
	{
		level.generators[ generatorType ] = [];
		allGeneratorsOfThisType = level.generators[ generatorType ];
	}
	id = getID( generator );
	allGeneratorsOfThisType[ id ] = bRegister;
}

monitorGeneratorUse( generatorType )	// self == player
{
	self notify( "end_monitorUse_" + generatorType );
	self endon( "end_monitorUse_" + generatorType );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	config = level.portableAOEgeneratorSettings[ generatorType ];
	while ( true )
	{
		self waittill( "grenade_fire", grenade, weapName );
		
		// grenade is the entity spawned by the G_FireGrenade() since we want this to be
		// script controlled, we won't actually use this entity
		if ( weapName == config.weaponName || weapName == generatorType )
		{
			if ( !IsAlive( self ) )
			{
				grenade delete();
				return;
			}
			
			if ( checkGeneratorPlacement( grenade, config.placementZTolerance ) )
			{
				previousGenerator = self.deployedGenerators[ generatorType ];
				if ( IsDefined( previousGenerator ) )
				{
					deleteGenerator( previousGenerator, generatorType );
				}
				
				generator = self spawnNewGenerator( generatorType, grenade.origin );
				
				// For moving platforms. 
				parent = grenade GetLinkedParent();
				if ( IsDefined( parent ) )
				{
					generator LinkTo( parent );
				}
				
				if( IsDefined( grenade ) )
				{
					grenade Delete();
				}
			}
			else
			{
				self SetWeaponAmmoStock( config.weaponName, self GetWeaponAmmoStock( "trophy_mp" ) + 1 );
			}
		}
	}
}

checkGeneratorPlacement( grenade, maxZDistance )	// self == player
{
	// need to see if this is being placed far away from the player and not let it do that
	// this will fix a legacy bug where you can stand on a ledge and plant a claymore down on the ground far below you
	grenade Hide();
	grenade waittill( "missile_stuck", stuckTo );
	
	if( maxZDistance * maxZDistance < DistanceSquared( grenade.origin, self.origin ) )
	{
		secTrace = bulletTrace( self.origin, self.origin - (0, 0, maxZDistance), false, self );
		
		if( secTrace["fraction"] == 1 )
		{
			// there's nothing under us so don't place the grenade up in the air
			grenade delete();
			return false;
		}
		
		// move the grenade to a reasonable place
		grenade.origin = secTrace["position"];
	}
	
	grenade Show();
	
	return true;
}

spawnNewGenerator( generatorType, origin )	// self == player
{
	config = level.portableAOEgeneratorSettings[ generatorType ];
	
	generator = spawn( "script_model", origin );
	generator.health = config.health;
	generator.team = self.team;
	generator.owner = self;

	generator SetCanDamage( true );
	
	generator SetModel( config.placedModel );
	
	// setup icons for item so friendlies see it
	if ( level.teamBased )
		generator maps\mp\_entityheadIcons::setTeamHeadIcon( self.team , (0,0,config.headIconHeight) );
	else
		generator maps\mp\_entityheadicons::setPlayerHeadIcon( self, (0,0,config.headIconHeight) );

	generator thread watchOwner( self, generatorType );
	generator thread watchDamage( self, generatorType );
	generator thread watchUse( self, generatorType );
	// 2013-03-25 wsh:
	// not sure why we need to set notUsableForJoiningPlayers
	generator thread notUsableForJoiningPlayers( self );

	if ( IsDefined( config.onDeployCallback ) )
	{
		generator [[ config.onDeployCallback ]]( self, generatorType );
	}
	
	generator thread maps\mp\gametypes\_weapons::createBombSquadModel( config.bombSquadModel, "tag_origin", self );
	
	self registerGenerator( generator, generatorType, true );
	
	// need to clear the changing weapon because it'll get stuck on c4_mp and player will stop spawning because we get locked in isChangingWeapon() loop when a killstreak is earned
	self.changingWeapon = undefined;

	wait(0.05); // allows for the plant sound to play
	
	if( IsDefined(generator) && (generator touchingBadTrigger()) )
	{
		generator notify( "death" );
	}
	
	return generator;
}

watchOwner( owner, generatorType )	// self == generator
{
	self endon( "death" );
	level endon ( "game_ended" );
	
	if ( bot_is_fireteam_mode() )
	{
		owner waittill( "killstreak_disowned" );
	}
	else
	{
		owner waittill_either( "killstreak_disowned", "death" );
	}
	
	owner thread deleteGenerator( self, generatorType );
}

watchDamage( owner, generatorType )	// self == generator
{
	self.generatorType = generatorType;
	config = level.portableAOEgeneratorSettings[ generatorType ];
	
	self maps\mp\gametypes\_damage::monitorDamage(
		config.health,
		config.damageFeedback,
		::handleDeathDamage,
		::modifyDamage,
		false	// isKillstreak
	);
}

// we should just use the default one
modifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleGrenadeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

handleDeathDamage( attacker, weapon, type )
{
	owner = self.owner;
	config = level.portableAOEgeneratorSettings[ self.generatorType ];
	
	if ( isDefined( owner ) && attacker != owner )
	{
		attacker notify( "destroyed_equipment" ); // count towards SitRep Pro challenge
	}
	
	if ( IsDefined( config.onDestroyCallback ) )
	{
		owner [[ config.onDestroyCallback ]]( self, self.generatorType );
	}
	owner thread deleteGenerator( self, self.generatorType );
}

watchUse( owner, generatorType )	// self == generator
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	
	config = level.portableAOEgeneratorSettings[ generatorType ];
	self setCursorHint( "HINT_NOICON" );
	self setHintString( config.useHintString );
	self setSelfUsable( owner );

	while ( true )
	{
		self waittill ( "trigger", player );
		
		player playLocalSound( config.useSound );
		
		// give item to user (only if they haven't restocked from scavenger pickup since dropping)		
		if ( player getAmmoCount( config.weaponName ) == 0 && !player isJuggernaut() )
		{
			player setWeapon( generatorType );
		}
	
		player thread deleteGenerator( self, generatorType );
	}
}

// called from _perks.gsc::spawnPlayer
// because we want to accumlate the effects of all generators
// before we determine whether or not to enable the effect
// DOES NOT COUNT THE # OF EFFECTS ACTIVE, though it's easily changed
generatorAOETracker()	// self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );
	level endon( "game_ended" );
	
	// wait a random amount so that all players aren't checking at the same time
	delay = RandomFloat( 0.5 );
	wait( delay );
	
	self.inGeneratorAOE = [];
	
	while ( true )
	{
		wait ( 0.05 );
		
		if ( level.generators.size > 0 || self.inGeneratorAOE.size > 0 )
		{
			foreach ( config in level.portableAOEgeneratorSettings )
			{
				self checkAllGeneratorsOfThisType( config.generatorType );
			}
		}
	}
}

checkAllGeneratorsOfThisType( generatorType )	// self == player
{
	generators = level.generators[ generatorType ];
	if ( IsDefined( generators ) )
	{
		config = level.portableAOEgeneratorSettings[ generatorType ];
		maxDistSq = config.aoeRadius * config.aoeRadius;
		result = undefined;
		foreach ( generator in generators )
		{
			// should I be cleaning the array?
			if ( IsDefined( generator ) && isReallyAlive( generator ) )
			{
				if ( ( level.teamBased && matchesTargetTeam( generator.team, self.team, config.targetType ) )
					  || ( !level.teamBased && matchesOwner( generator.owner, self, config.targetType ) )
					)
				{
					// stop as soon as we find a valid candidate
					distSq = DistanceSquared( generator.origin, self.origin );
					if ( distSq < maxDistSq )
					{
						result = generator;
						break;
					}
				}
			}
		}
		
		isInThisGenerator = IsDefined(result);
		wasInGeneratorOfThisType = IsDefined( self.inGeneratorAOE[ generatorType ] );
		if ( isInThisGenerator && !wasInGeneratorOfThisType )
		{
			self [[ config.onEnterCallback ]]();
		}
		else if ( !isInThisGenerator && wasInGeneratorOfThisType )
		{
			self [[ config.onExitCallback ]]();
		}
		
		self.inGeneratorAOE[ generatorType ] = result;
	}
}

matchesTargetTeam( myTeam, theirTeam, teamType )
{
	return (
			( teamType == "all" )
			|| ( teamType == "friendly" && myTeam == theirTeam )
			|| ( teamType == "enemy" && myTeam != theirTeam )
			);
}

matchesOwner( myOwner, player, teamType )
{
	return (
		( teamType == "all" )
		|| ( teamType == "friendly" && myOwner == player )
		|| ( teamType == "enemy" && myOwner != player )
	);
}

// since I can't use the generator itself as an index into the array
// create some kind of unique ID to use as an index
getID( generator )
{
	return generator.owner.guid + generator.birthtime;
}