#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\killstreaks\_emp_common;


init()
{
	thread onPlayerConnect();
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
		self waittill( "spawned_player" );
		
		self thread monitorEMPGrenade();
	}
}


monitorEMPGrenade()
{
	self endon("death");
	self endon("disconnect");
	self endon("faux_spawn");
	self.empEndTime = 0;
	
	while(1)
	{
		// self waittill( "emp_grenaded", attacker );
		self waittill( "emp_damage", attacker, duration );
		
		if ( !IsAlive( self ) 
		    || IsDefined( self.usingRemote )
			|| ( self _hasPerk( "specialty_empimmune" ) )	//MW3 emp resistance perk
			|| !IsDefined( attacker )
			)
		{
			continue;
		}
		
		hurtVictim = true;
		hurtAttacker = false;
		
		assert( IsDefined(self.pers["team"]) );
		
		if ( level.teamBased 
		    && attacker != self 
		    && IsDefined(attacker.pers["team"]) 
		    && attacker.pers["team"] == self.pers["team"] 
		   )
		{
			if(level.friendlyfire == 0) // no FF
			{
				continue;
			}
			else if(level.friendlyfire == 1) // FF
			{
				hurtattacker = false;
				hurtvictim = true;
			}
			else if(level.friendlyfire == 2) // reflect
			{
				hurtvictim = false;
				hurtattacker = true;
			}
			else if(level.friendlyfire == 3) // share
			{
				hurtattacker = true;
				hurtvictim = true;
			}
		}		
		else
		{
			attacker notify( "emp_hit" );
			
			if( attacker != self )
			{
				attacker maps\mp\gametypes\_missions::processChallenge( "ch_onthepulse" );
			}
		}

		if ( hurtvictim && IsDefined(self) )
		{
			self thread applyEMP( duration );
		}
		if ( hurtattacker )
		{
			attacker thread applyEMP( duration );
		}
	}
}

applyEMP( duration )
{
	self notify( "applyEmp" );
	self endon( "applyEmp" );
	self endon( "disconnect" );
	
	self endon( "death" );
	
	wait .05;
	
	self.empGrenaded = true;
	self shellshock( "flashbang_mp", 1 ); 
	self.empEndTime = GetTime() + (duration * 1000);
	
	self applyPerPlayerEMPEffects_OnDetonate();
	self applyPerPlayerEMPEffects();
	self thread empRumbleLoop( .75 );
	self thread empGrenadeDeathWaiter();
	
	wait ( duration );
	
	self notify( "empGrenadeTimedOut" );
	self checkToTurnOffEmp();
}

empGrenadeDeathWaiter()
{
	self notify( "empGrenadeDeathWaiter" );
	self endon( "empGrenadeDeathWaiter" );
	
	self endon( "empGrenadeTimedOut" );
	
	self waittill( "death" );
	self checkToTurnOffEmp();
}

checkToTurnOffEmp()
{
	self.empGrenaded = false;
	
	if ( !(self shouldPlayerBeAffectedByEMP()) )
	{
		self removePerPlayerEMPEffects();
	}
}

empRumbleLoop( duration )
{
	self endon("emp_rumble_loop");
	self notify("emp_rumble_loop");
	
	goalTime = GetTime() + duration * 1000;
	
	while ( GetTime() < goalTime )
	{
		self PlayRumbleOnEntity( "damage_heavy" );
		wait( 0.05 );
	}
}

// 2013-06-30 wallace: is isEMPGrenaded being used any more? Not sure if we even need the timestamp
isEMPGrenaded()
{
	return isDefined( self.empEndTime ) && gettime() < self.empEndTime;
}
