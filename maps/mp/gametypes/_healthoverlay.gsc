#include maps\mp\_utility;

init()
{
	level.healthOverlayCutoff = 0.55;
	
	regenTime = 5;
	regenTime = maps\mp\gametypes\_tweakables::getTweakableValue( "player", "healthregentime" );
	
	level.playerHealth_RegularRegenDelay = regenTime;
	
	level.healthRegenDisabled = (level.playerHealth_RegularRegenDelay <= 0);
	
	level thread onPlayerConnect();
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
		self waittill("spawned_player");
		self thread playerHealthRegen();
		
		self VisionSetThermalForPlayer( game[ "thermal_vision" ] );
		
/#
		//self thread showTempDamage();
#/
	}
}


/#
//showTempDamage()
//{
//	self endon ( "death" );
//	self endon ( "disconnect" );
//	setDevDvar( "scr_damage_wait", 0 );
//	setDevDvar( "scr_damage_fadein", 0.25 );
//	setDevDvar( "scr_damage_fadeout", 0.5 );
//	setDevDvar( "scr_damage_holdtime", 0.5 );
//	setDevDvar( "scr_damage_numfades", 5 );
//	
//	for ( ;; )
//	{
//		while ( getDvarFloat( "scr_damage_wait" ) <= 0 )
//			wait ( 1.0 );
//			
//		wait ( getDvarFloat( "scr_damage_wait" ) );
//		
//		for ( i = 0; i < getDvarInt( "scr_damage_numfades" ); i++ )
//		{
//			self VisionSetNakedForPlayer( "near_death_mp", getDvarFloat( "scr_damage_fadein" ) * (getDvarInt( "scr_damage_numfades" ) - i) );
//			wait ( getDvarFloat( "scr_damage_fadein" ) + getDvarFloat( "scr_damage_holdtime" ) );
//			self VisionSetNakedForPlayer( "near_death_mp", getDvarFloat( "scr_damage_fadeout" ) * getDvarInt( "scr_damage_numfades" ) );
//			wait ( getDvarFloat( "scr_damage_fadeout" ) );
//		}
//		
//	}
//}
#/

playerHealthRegen()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "joined_team" );
	self endon ( "joined_spectators" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	if ( self.health <= 0 )
	{
		assert( !isalive( self ) );
		return;
	}
	
	veryHurt = false;
	hurtTime = 0;
	
	thread playerPainBreathingSound( self.maxhealth * 0.55 );

	for (;;)
	{	
		self waittill( "damage" );
		
		if ( self.health <= 0 ) // player dead
			return;
			
		// jugg's don't regen health
		if( self isJuggernaut() )
			continue;

		hurtTime = getTime();
		healthRatio = self.health / self.maxHealth;
		
		self.regenSpeed = 1;
		
		if( self _hasPerk( "specialty_regenfaster" ) )
			self.regenSpeed *= level.regenFasterMod;
		else if( self _hasPerk( "specialty_bloodrush" ) )
			self.regenSpeed *= self.bloodrushRegenSpeedMod;		

		if ( healthRatio <= level.healthOverlayCutoff ) //this is used for a challenge
		{
			self.atBrinkOfDeath = true;
		}
		
		self thread healthRegeneration( hurtTime, healthRatio );
		self thread breathingManager( hurtTime, healthRatio );
	}
	
}

breathingManager( hurtTime, healthRatio )
{
	self notify( "breathingManager" );
	self endon ( "breathingManager" );
	
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "joined_team" );
	self endon ( "joined_spectators" );
	level endon ( "game_ended" );
	
	if( self isUsingRemote() )
		return;
	
	if( !IsPlayer(self) )
		return;

	self.breathingStopTime = hurtTime + ( 6000 * self.regenSpeed );
	
	wait ( 6 * self.regenSpeed );
		
	if ( !level.gameEnded )
	{
		if ( self hasFemaleCustomizationModel() )
		{
			self playLocalSound("Fem_breathing_better");
		}
		else
		{
			self playLocalSound("breathing_better");
		}
	}
	
}

healthRegeneration( hurtTime, healthRatio )
{
	self notify( "healthRegeneration" );
	self endon ( "healthRegeneration" );
	
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "joined_team" );
	self endon ( "joined_spectators" );
	level endon ( "game_ended" );
	
	healthRegenDisabled = level.healthRegenDisabled || ( IsDefined(self.healthRegenDisabled) && self.healthRegenDisabled );
	
	if ( healthRegenDisabled )
		return;

	// Watch when bloodrush is activated and then manually override the regen speed
	// This is only needed if the player is damaged before bloodrush is activated
	self childthread maps\mp\perks\_perkfunctions::regenSpeedWatcher();

	wait ( ( level.playerHealth_RegularRegenDelay ) * self.regenSpeed  ); //reduce this for perk
	
	if ( healthRatio < .55 )
	{
		wasVeryHurt = true;
	}
	else
	{
		wasVeryHurt = false;
	}
	
	while( true )
	{		
		if( !IsDefined( self.regenSpeed ) || self.regenSpeed == 1 ) // standard speed 5 seconds 100 frames	
		{
			wait( 0.05 );
			
			if( self.health < self.maxHealth )
			{		
				self.health += 1; 
				healthRatio = self.health / self.maxHealth;
			}
			else
				break;
		}
		else // faster regen
		{
			wait( 0.05 );
			if( self.health < self.maxHealth )
			{		
				if( self _hasPerk( "specialty_regenfaster" ) )
					self.health += level.regenFasterHealthMod;
				else if( self _hasPerk( "specialty_bloodrush" ) )
					self.health += self.bloodrushRegenHealthMod;
			}
			else
				break;
		}
		
		if( self.health > self.maxHealth )
			self.health = self.maxHealth;
	}
	
	self notify( "healed" );
	
	//fully regenerated
	self maps\mp\gametypes\_damage::resetAttackerList();
	
	if ( wasVeryHurt ) 
		self maps\mp\gametypes\_missions::healthRegenerated();
}

wait_for_not_using_remote()
{
	// this fixes a bug where you can be very damaged and showing the red visionset, then enter a killstreak using a remote
	// once you come out, the red visionset was staying on because we never told it to reset while you were in the killstreak
	self notify( "waiting_to_stop_remote" );
	self endon( "waiting_to_stop_remote" );
	
	self endon( "death" );
	level endon( "game_ended" );

	self waittill( "stopped_using_remote" );
	self restoreBaseVisionSet( 0 );
}

playerPainBreathingSound( healthcap )
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "joined_team" );
	self endon ( "joined_spectators" );
	
	if( !IsPlayer(self) )
		return;
	
	wait ( 2 );

	for (;;)
	{
		wait ( 0.2 );
		
		if ( self.health <= 0 )
			return;
			
		// Player still has a lot of health so no breathing sound
		if ( self.health >= healthcap )
			continue;
		
		healthRegenDisabled = level.healthRegenDisabled || ( IsDefined(self.healthRegenDisabled) && self.healthRegenDisabled );
		
		// Juggernauts may breathe forever
		if ( healthRegenDisabled && IsDefined( self.breathingStopTime ) && gettime() > self.breathingStopTime )
			continue;
			
		if( self isUsingRemote() )
			continue;
		if ( self hasFemaleCustomizationModel() )
			self playLocalSound( "Fem_breathing_hurt" );
		else
			self playLocalSound( "breathing_hurt" );

		wait ( .784 );
		wait ( 0.1 + randomfloat (0.8) );
	}
}
