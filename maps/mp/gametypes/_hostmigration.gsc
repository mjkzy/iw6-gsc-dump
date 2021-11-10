#include maps\mp\_utility;
#include common_scripts\utility;

Callback_HostMigration()
{
	if ( is_aliens() )
	{
		SetNoJIPTime( true );
	}
		
	level.hostMigrationReturnedPlayerCount = 0;

	if ( level.gameEnded )
	{
		println( "Migration starting at time " + gettime() + ", but game has ended, so no countdown." );
		return;
	}

	println( "Migration starting at time " + gettime() );

	foreach ( character in level.characters )
		character.hostMigrationControlsFrozen = false;

	level.hostMigrationTimer = true;
	setDvar( "ui_inhostmigration", 1 );

	level notify( "host_migration_begin" );
	maps\mp\gametypes\_gamelogic::UpdateTimerPausedness();

	foreach ( character in level.characters )
	{
		character thread hostMigrationTimerThink();

		if ( IsPlayer( character ) )
		{
			// reset client dvars
			character SetClientOmnvar( "ui_session_state", character.sessionstate );
		}
	}

	// reset game state
	SetDvar( "ui_game_state", game[ "state" ] );

	level endon( "host_migration_begin" );
	hostMigrationWait();

	level.hostMigrationTimer = undefined;
	setDvar( "ui_inhostmigration", 0 );
	println( "Migration finished at time " + gettime() );

	level notify( "host_migration_end" );
	maps\mp\gametypes\_gamelogic::UpdateTimerPausedness();

	level thread maps\mp\gametypes\_gamelogic::updateGameEvents();
	if( ( GetDvar( "squad_use_hosts_squad" ) == "1" ) )
	{
		level thread maps\mp\gametypes\_menus::update_wargame_after_migration();
	}
}

hostMigrationWait()
{
	level endon( "game_ended" );
	
	// start with a 20 second wait.
	// once we get enough players, or the first 15 seconds pass, switch to a 5 second timer.
	
	level.inGracePeriod = 25;
	thread maps\mp\gametypes\_gamelogic::matchStartTimer( "waiting_for_players", 20.0 );
	hostMigrationWaitForPlayers();

	level.inGracePeriod = 10;
	thread maps\mp\gametypes\_gamelogic::matchStartTimer( "match_resuming_in", 5.0 );
	wait 5;
	level.inGracePeriod = false;
}

hostMigrationWaitForPlayers()
{
	level endon( "hostmigration_enoughplayers" );
	wait 15;
}

hostMigrationName( ent )
{
	if ( !IsDefined( ent ) )
		return "<removed_ent>";

	entNum = -1;
	entName = "?";
	
	if ( IsDefined( ent.entity_number ) )
		entNum = ent.entity_number;
	
	if ( isPlayer( ent ) && IsDefined( ent.name ) )
		entName = ent.name;

	if ( isPlayer( ent ) )
		return "player <" + entName + ">";
	
	if ( IsAgent( ent ) && IsGameParticipant( ent ) )
		return "participant agent <" + entNum + ">";

	if ( IsAgent( ent ) )
		return "non-participant agent <" + entNum + ">";

	return "unknown entity <" + entNum + ">";
}

hostMigrationTimerThink_Internal()
{
	level endon( "host_migration_begin" );
	level endon( "host_migration_end" );

	assertex( IsDefined( self.hostMigrationControlsFrozen ), "Not properly tracking controller frozen for " + hostMigrationName( self ) );

	while ( !isReallyAlive( self ) )
	{
		self waittill( "spawned" );
	}

	println( "Migration freezing controls for " + hostMigrationName( self ) + " with hostMigrationControlsFrozen = " + self.hostMigrationControlsFrozen );

	self.hostMigrationControlsFrozen = true;
	self freezeControlsWrapper( true );

	level waittill( "host_migration_end" );
}

hostMigrationTimerThink()
{
	self endon( "disconnect" );

	assertex( IsDefined( self.hostMigrationControlsFrozen ), "Not properly tracking controller frozen for " + hostMigrationName( self ) );

	if ( IsPlayer( self ) )
		self setClientDvar( "cg_scoreboardPingGraph", "0" );

	hostMigrationTimerThink_Internal();

	assertex( IsDefined( self.hostMigrationControlsFrozen ), "Attempted to unfreeze controls for " + hostMigrationName( self ) );
	println( "Migration attempting to unfreeze controls for " + hostMigrationName( self ) + " with hostMigrationControlsFrozen = " + self.hostMigrationControlsFrozen );

	if ( self.hostMigrationControlsFrozen )
	{
		// make sure we aren't in prematch still before we unfreeze controls because prematch wants them frozen and will unfreeze when done
		if( gameFlag( "prematch_done" ) )
			self freezeControlsWrapper( false );
		self.hostMigrationControlsFrozen = undefined;
	}

	if ( IsPlayer( self ) )
		self setClientDvar( "cg_scoreboardPingGraph", "1" );
}

waitTillHostMigrationDone()
{
	if ( !isDefined( level.hostMigrationTimer ) )
		return 0;
	
	starttime = gettime();
	level waittill( "host_migration_end" );
	return gettime() - starttime;
}

waitTillHostMigrationStarts( duration )
{
	if ( isDefined( level.hostMigrationTimer ) )
		return;
	
	level endon( "host_migration_begin" );
	wait duration;
}

waitLongDurationWithHostMigrationPause( duration )
{
	if ( duration == 0 )
		return;
	assert( duration > 0 );
	
	starttime = gettime();
	
	endtime = gettime() + duration * 1000;
	
	while ( gettime() < endtime )
	{
		waitTillHostMigrationStarts( (endtime - gettime()) / 1000 );
		
		if ( isDefined( level.hostMigrationTimer ) )
		{
			timePassed = waitTillHostMigrationDone();
			endtime += timePassed;
		}
	}
	
	waitTillHostMigrationDone();
	
	return gettime() - starttime;
}

waittill_notify_or_timeout_hostmigration_pause( msg, duration )
{
	self endon( msg );

	if ( duration == 0 )
		return;
	assert( duration > 0 );

	starttime = gettime();

	endtime = gettime() + duration * 1000;

	while ( gettime() < endtime )
	{
		waitTillHostMigrationStarts( (endtime - gettime()) / 1000 );

		if ( isDefined( level.hostMigrationTimer ) )
		{
			timePassed = waitTillHostMigrationDone();
			endtime += timePassed;
		}
	}

	waitTillHostMigrationDone();

	return gettime() - starttime;
}

waitLongDurationWithGameEndTimeUpdate( duration )
{
	if ( duration == 0 )
		return;
	assert( duration > 0 );
	
	starttime = gettime();
	
	endtime = gettime() + duration * 1000;
	
	while ( gettime() < endtime )
	{
		waitTillHostMigrationStarts( (endtime - gettime()) / 1000 );
		
		while ( isDefined( level.hostMigrationTimer ) )
		{
			endTime += 1000;
			setGameEndTime( int( endTime ) );
			wait 1;
		}
	}
	
	while ( isDefined( level.hostMigrationTimer ) )
	{
		endTime += 1000;
		setGameEndTime( int( endTime ) );
		wait 1;
	}
	
	return gettime() - starttime;
}

