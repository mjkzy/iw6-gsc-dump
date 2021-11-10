#include common_scripts\utility;

main()
{
	flag_init( "give_player_abilities" );
	if( maps\mp\alien\_utility::is_chaos_mode() )
		thread maps\mp\alien\_chaos::chaos_setup_op_weapons();
	else	
		thread setup_op_weapons();

	level._effect[ "smoke_green_signal" ] 			= loadfx( "vfx/gameplay/alien/vfx_alien_cskill_medic_smk_01" ) ;
}

setup_op_weapons()
{
	level.opWeaponsArray = [];
	level.opWeaponsArray[0] = "iw5_alienriotshield_mp";
	level.opWeaponsArray[1] = "iw5_alienriotshield1_mp";
	level.opWeaponsArray[2] = "iw5_alienriotshield2_mp";
	level.opWeaponsArray[3] = "iw5_alienriotshield3_mp";
	level.opWeaponsArray[4] = "iw5_alienriotshield4_mp";
	level.opWeaponsArray[5] = "iw6_alienminigun_mp";
	level.opWeaponsArray[6] = "iw6_alienminigun1_mp";
	level.opWeaponsArray[7] = "iw6_alienminigun2_mp";
	level.opWeaponsArray[8] = "iw6_alienminigun3_mp";
	level.opWeaponsArray[9] = "iw6_alienminigun4_mp";
	level.opWeaponsArray[10] = "iw6_alienmk32_mp";
	level.opWeaponsArray[11] = "iw6_alienmk321_mp";
	level.opWeaponsArray[12] = "iw6_alienmk322_mp";
	level.opWeaponsArray[13] = "iw6_alienmk323_mp";
	level.opWeaponsArray[14] = "iw6_alienmk324_mp";
	level.opWeaponsArray[15] = "iw6_alienpanzerfaust3_mp";
	level.opWeaponsArray[16] = "iw6_alienrgm_mp";
	level.opWeaponsArray[17] = "mp/iw6_alienrgm_mp";
	level.opWeaponsArray[18] = "weapon_iw6_alienrgm_mp";
	level.opWeaponsArray[19] = "iw6_alienmaaws_mp";
	level.opWeaponsArray[20] = "venomxgun_mp";
	level.opWeaponsArray[21] = "venomxproj_mp";
	level.opWeaponsArray[22] = "iw6_aliendlc11_mp";
	level.opWeaponsArray[23] = "alienbomb_mp";
	level.opWeaponsArray[24] = "iw6_aliendlc11sp_mp";
	level.opWeaponsArray[25] = "iw6_aliendlc11li_mp";
	level.opWeaponsArray[26] = "iw6_aliendlc11fi_mp";
	level.opWeaponsArray[27] = "iw6_aliendlc11_mp";
	level.opWeaponsArray[28] = "aliensoflam_mp";
	level.opWeaponsArray[29] = "aliencortex_mp";
	level.opWeaponsArray[30] = "iw6_aliendlc41_mp";	
	
}

assign_skills()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self.ability_scalar_bullet = 1;
	self.ability_scalar_melee = 1;
	
	player = self;
	flag_wait( "give_player_abilities" );
	primaryClass = player maps\mp\alien\_persistence::get_selected_perk_0();
	secondaryClass = maps\mp\alien\_persistence::get_selected_perk_0_secondary();
	self thread death_check();
	
	if( primaryClass == "perk_bullet_damage" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "weapon_specialist_upgrade" ) )
		{
			player thread specialist_skill_icon_waiter( );
		}
	}
	
	if( secondaryClass == "perk_bullet_damage" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "weapon_specialist_upgrade" ) )
		{
			player thread specialist_skill_icon_waiter( "secondary" );
		}
	}
	
	if( primaryClass == "perk_health" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "tank_upgrade" ) )
		{
			player thread tank_skill_icon_waiter();
		}
	}
	
	if( secondaryClass == "perk_health"  )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "tank_upgrade" ) )
		{
			player thread tank_skill_icon_waiter( "secondary" );
		}
	}
	
	if( primaryClass == "perk_medic" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "medic_upgrade" ) )
		{
			player thread medic_skill_icon_waiter();
		}
	}
	
	if( secondaryClass == "perk_medic" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "medic_upgrade" ) )
		{
			player thread medic_skill_icon_waiter( "secondary" );
		}
	}
	
	if( primaryClass == "perk_rigger" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "engineer_upgrade" ) )
		{
			player thread engineer_skill_icon_waiter();
		}
	}
	
	if( secondaryClass == "perk_rigger" )
	{
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "engineer_upgrade" ) )
		{
			player thread engineer_skill_icon_waiter( "secondary" );
		}
	}
	
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												 			TANK SKILL
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//The tank pulls out two flares and gets all of the aggro
tank_skill_icon_waiter( secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "clear_skills" );
	self endon( "clear_skills" );

	level.meleeStunRadius = 128;
	level.meleeStunMaxDamage = 1;
	level.meleeStunMinDamage = 1;

	tank_skill = [];
	tank_skill[ "rank_0_cost" ] = 200;
	tank_skill[ "rank_1_cost" ] = 350;
	tank_skill[ "rank_2_cost" ] = 380;
	tank_skill[ "rank_3_cost" ] = 415;
	tank_skill[ "rank_4_cost" ] = 475;

	tank_skill[ "rank_0_duration" ] = 5.00;
	tank_skill[ "rank_1_duration" ] = 5.625;
	tank_skill[ "rank_2_duration" ] = 6.25;
	tank_skill[ "rank_3_duration" ] = 7.5;
	tank_skill[ "rank_4_duration" ] = 10.0;

	tank_skill[ "rank_0_cooldown" ] = 180;
	tank_skill[ "rank_1_cooldown" ] = 180;
	tank_skill[ "rank_2_cooldown" ] = 180;
	tank_skill[ "rank_3_cooldown" ] = 180;
	tank_skill[ "rank_4_cooldown" ] = 180;

	tank_skill[ "perk" ] = "perk_health";

	self thread tank_skill_setup( tank_skill, secondary );
	
	self thread generic_skill_waiter( tank_skill , 2, secondary );
}

tank_skill_setup( tank_skill, secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	while(1)
	{
		if( IsDefined( self.has_died_primary ) || IsDefined( self.has_died_secondary ) ) 
		{
			if( isDefined( secondary ) )
			{
				self.has_died_secondary = undefined;
				skill_cooldown_secondary( tank_skill );
			}
			else
			{
				self.has_died_primary = undefined;
				skill_cooldown_primary( tank_skill );
			}
		}
		//Wait for the player to press the skill button
		
		if( isDefined( secondary ) )
			self wait_for_secondary_skill_button();
		else
			self wait_for_primary_skill_button();
		
		variables = generic_variable_setup( tank_skill );
		
		self thread sound_audio_weapon_activate();

		if( ability_cost( variables[ "cost" ], secondary ) )
		{
			self VisionSetNakedForPlayer( "mp_alien_thermal_trinity", .5 );

			self maps\mp\alien\_music_and_dialog::playTankClassSkillVO(self);
			//Attach flares
			self thread create_tank_ring( variables );
			self tank_skill_flare( variables );

			self VisionSetNakedForPlayer( "", .5 );

			//Wait for power to be ready
			if( isDefined( secondary ) )
				skill_cooldown_secondary( tank_skill );
			else
				skill_cooldown_primary( tank_skill );	
		}
		wait .05;
	}
}

tank_skill_flare( variables )
{
	self endon( "death" );
	self endon( "disconnect" );
	//increase the threat of our tank
	current_bias 	= self.threatbias;

	self.threatbias = 3000;
//	self.moveSpeedScaler = 1.4;
	self.ability_scalar_melee = 1.25;
	self.tank_skill_active = true;
	self thread tank_death_watcher();
	self.ability_invulnerable = true;
//	self thread tank_health_watch();

	self thread super_punch();
	level notify( "aggro_grab" );
	self thread aggro_grab();
	
	self thread sound_audio_tank(variables);

	wait variables["duration"];
//	self proto_hack_flare_update();

	//reset threat bias and speed
	self.threatbias = current_bias;
	self.ability_scalar_melee = 1;

	aliens = [];
	aliens = maps\mp\alien\_spawnlogic::get_alive_agents();
	self.tank_skill_active = undefined;
	self notify( "super_expired" );

	foreach ( alien in aliens)
	{
		alien.favoriteenemy = undefined;
	}
}

sound_audio_tank(variables)
{
	audio_tank = spawn( "script_origin", self.origin );
	self thread sound_position_update( audio_tank );
	audio_tank PlayLoopSound( "alien_skill_tank_lp" );
	waittill_any_timeout(variables["duration"], variables["death"]);
	audio_tank StopLoopSound();
	audio_tank notify( "kill_node" );
	wait 1;
	audio_tank delete();
}

sound_position_update(node)
{
	self endon( "death" );
	self endon( "disconnect" );
	node endon( "kill_node" );
	while(1)
	{
		node.origin = self.origin;
		wait 0.1;		
	}
}

tank_death_watcher()
{
	self waittill_any( "disconnect" , "death" , "super_expired" );
	self.ability_invulnerable = undefined;
	
}

tank_health_watch()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "super_expired" );

	iHealth = self.health;
	while(1)
	{
		if( iHealth <= self.health )
		{
			iHealth = self.health;
		}
		else
		{
			self.health = iHealth;	
		}
	 	wait .05;
	}
}

super_punch()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "super_expired" );

	while(1)
	{
		if( self MeleeButtonPressed() && self IsMeleeing()  )
		{
			wait 0.05;  
			Earthquake( 0.30,0.2,self.origin, 10 );  //make it feel good
            RadiusDamage( self.origin, level.meleeStunRadius, level.meleeStunMaxDamage, level.meleeStunMinDamage, self, "MOD_MELEE", "meleestun_mp"  ); // pass in a bogus weapon we are not using so the damage isn't caught in an infinate MOD_MELEE loop
            self PlaySoundToPlayer( "bodyfall_asphault_large", self );
            self wait_for_melee_end();

		}
		wait 0.05;  
	}
}

wait_for_melee_end()
{
	while(1)
	{
		if( self IsMeleeing() ==  false )
		{
			return;	
		}
		wait .1;
	}
}

aggro_grab()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "aggro_grab" );
	self endon( "super_expired" );

	while(1)
	{
		aliens = [];
		aliens = maps\mp\alien\_spawnlogic::get_alive_agents();

		foreach ( alien in aliens)
		{
			alien.favoriteenemy = self;
		}	
		wait .5;
	}
}


//TODO: HACKHACK BAD BAD  -- This stuff is for proto only, need better way of rendering flare
proto_hack_flare_update()
{
	self endon( "death" );
	self endon( "disconnect" );
	counter = 0;	

	while(1)
	{
		glowStick = spawn( "script_model", self GetTagOrigin( "tag_weapon_right" ) );
		glowstick setmodel("mil_emergency_flare_mp");
		glowstick.angles = self GetTagAngles( "tag_weapon_right" );
		glowStick LinkTo( self , "tag_weapon_right" );

		wait .05;

		angles = glowStick getTagAngles( "tag_fire_fx" );
		fxEnt = SpawnFx( loadfx( "fx/misc/flare_ambient_green" ), glowStick getTagOrigin( "tag_fire_fx" ), anglesToForward( angles ), anglesToUp( angles ) );
		TriggerFx( fxEnt );

		glowStick playLoopSound( "emt_road_flare_burn" );
	//	self thread deleteOnDeath( fxEnt );
	//	self.flareType = true;

		wait .05;	
		glowStick delete();
		fxEnt delete();

		counter = counter + 1;

		if( counter == 50 )
		{
			return;
		}
	}
}

create_tank_ring( variables )
{
	if( IsDefined( self ) )
		PlayFXOnTag( loadfx( "vfx/gameplay/alien/vfx_alien_cskill_tank_01" ) , self , "tag_origin" );

	waittill_any_timeout( variables[ "duration" ] , "last_stand" );
	if( IsDefined( self ) )
		StopFXOnTag( loadfx( "vfx/gameplay/alien/vfx_alien_cskill_tank_01" ) , self , "tag_origin" );
}
   
 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												 			MEDIC SKILL
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//The medic tosses a medkit that heals a hurt player or pciks up a downed player

HEAL_TICK = .1;

medic_skill_icon_waiter( secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "clear_skills" );
	self endon( "clear_skills" );

	medic_skill = [];
	medic_skill[ "rank_0_cost" ] = 225;
	medic_skill[ "rank_1_cost" ] = 350;
	medic_skill[ "rank_2_cost" ] = 390;
	medic_skill[ "rank_3_cost" ] = 430;
	medic_skill[ "rank_4_cost" ] = 515;

	medic_skill[ "rank_0_duration" ] = 5;
	medic_skill[ "rank_1_duration" ] = 5.625;
	medic_skill[ "rank_2_duration" ] = 6.25;
	medic_skill[ "rank_3_duration" ] = 7.5;
	medic_skill[ "rank_4_duration" ] = 10;

	medic_skill[ "rank_0_cooldown" ]= 180;
	medic_skill[ "rank_1_cooldown" ]= 180;
	medic_skill[ "rank_2_cooldown" ]= 180;
	medic_skill[ "rank_3_cooldown" ]= 180;
	medic_skill[ "rank_4_cooldown" ]= 180;

	medic_skill[ "perk" ] = "perk_medic";
	self thread medic_skill_setup( medic_skill, secondary );

	self thread generic_skill_waiter( medic_skill , 4, secondary );	
}

medic_skill_setup( medic_skill, secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	while(1)
	{
		if( IsDefined( self.has_died_primary ) || IsDefined( self.has_died_secondary ) ) 
		{
			if( isDefined( secondary ) )
			{
				self.has_died_secondary = undefined;
				skill_cooldown_secondary( medic_skill );
			}
			else
			{
				self.has_died_primary = undefined;
				skill_cooldown_primary( medic_skill );
			}
		}
		
		//Wait for the player to press the skill button
		if( isDefined( secondary ) )
			self wait_for_secondary_skill_button();
		else
			self wait_for_primary_skill_button();

		variables = generic_variable_setup( medic_skill );

		self thread sound_audio_weapon_activate();
		
		if( ability_cost( variables[ "cost" ], secondary ) )
		{
			self  maps\mp\alien\_music_and_dialog::playMedicClassSkillVO(self);
			self create_heal_ring( variables );
			if( isDefined( secondary ) )
				skill_cooldown_secondary( medic_skill );
			else
				skill_cooldown_primary( medic_skill );	
		}

		wait .05;	
	}
}
create_heal_ring( variables )
{
	carriedObj = SpawnTurret( "misc_turret", self.origin + ( 0, 0, 20 ), "sentry_minigun_mp" );
	carriedObj.owner = self;
	carriedObj.angles = AnglesToUp( ( 0 , 0 , 90 )  );

	carriedObj SetModel( "tag_origin_vehicle" );

	carriedObj MakeTurretInoperable();
	carriedObj SetTurretModeChangeWait( true );
	carriedObj SetMode( "sentry_offline" );
	carriedObj MakeUnusable();
	carriedObj SetSentryOwner( self );
	carriedObj SetSentryCarrier( self );

	carriedObj SetCanDamage( false );
	carriedObj SetContents( 0 );
	
	wait .1;
	PlayFXOnTag(level._effect[ "smoke_green_signal" ] , carriedObj , "tag_origin" );
	sound_heal = spawn( "script_model", self.origin );
	sound_heal LinkTo( carriedObj );
	sound_heal PlayLoopSound( "alien_skill_medic_lp" );
	self thread heal_logic();
	self thread death_deletes_heal_ring(carriedObj);
	self waittill_any_timeout( variables[ "duration" ] , "last_stand" , "death" , "disconnect" );

	if( IsDefined( self ) )
		self notify( "heal_over" );

	sound_heal StopLoopSound();
	sound_heal unlink();
	if( IsDefined( carriedObj ) )
		carriedObj delete();	
	wait 0.1;
	if( IsDefined( sound_heal ) )
		sound_heal delete();
}

death_deletes_heal_ring(carriedObj)
{
	self endon( "heal_over" );
	self waittill_any( "death","disconnect", "vanguard_used" );
	if( IsDefined( carriedObj ))
	{
		carriedObj delete();
	}
}
save_grenade()
{
	self endon( "missile_stuck" );
	wait 5;
	self.failthrow = true;
	self notify( "missile_stuck" );
}

medic_heal_skill( position ,  grenade , variables )
{
	self endon( "death" );
	self endon( "disconnect" );
	wait 1.5;

	//THE REAL ONE
//	 fxEnt = SpawnFx( loadfx( "vfx/gameplay/alien/vfx_alien_cskill_medic_smk_01" ) , position , anglesToForward( self.angles + ( -90 , 0 , 0 ) ), anglesToUp( self.angles + ( 0 , 0 , 0 ) ) );
//     TriggerFx( fxEnt );
	self thread heal_logic( position );

	//HACK HACK BAD
	fxEnt = SpawnFx( level._effect[ "smoke_green_signal" ] , position , anglesToForward( self.angles ), anglesToUp( self.angles + ( 0 , 0 , 0 ) ) );
	TriggerFx( fxEnt );
//
//	fxEnt3 = SpawnFx( level._effect[ "smoke_green_signal" ] , position + ( -100 , 100 , 0 ) , anglesToForward( self.angles ), anglesToUp( self.angles + ( 0 , 0 , -180 ) ) );
//	TriggerFx( fxEnt3 );

	wait variables["duration"];
	self notify( "heal_over" );
	fxEnt Delete();
//	fxEnt2 Delete();
//	fxEnt3 Delete();
}

heal_logic( )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "heal_over" );

	while(1)
	{
		foreach ( player in level.players)
		{
			healAmount = int(floor( player.maxhealth * HEAL_TICK ));
						
			if( Distance( player.origin , self.origin) <= 128 )
			{
				if( IsDefined( player.laststand ) && player.laststand )
				{
					player notify( "revive_success" );
					player setClientOmnvar ( "ui_laststand_end_milliseconds", 0 );
					maps\mp\alien\_laststand::record_revive_success( self , player );
				}
				else
				{
					if( ( player.health + healAmount ) >= player.maxhealth	)
					{
						player.health = player.maxhealth;	
					}
					else
					{
						player.health = player.health + healAmount ;
					}
				}
			}
		}
		wait .5;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												 		 ENGINEER SKILL
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Slow field traps enemies//
engineer_skill_icon_waiter( secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "clear_skills" );
	self endon( "clear_skills" );

	engineer_skill = [];
	engineer_skill[ "rank_0_cost" ] = 200;
	engineer_skill[ "rank_1_cost" ] = 350;
	engineer_skill[ "rank_2_cost" ] = 380;
	engineer_skill[ "rank_3_cost" ] = 415;
	engineer_skill[ "rank_4_cost" ] = 475;

	engineer_skill[ "rank_0_duration" ] = 5.00;
	engineer_skill[ "rank_1_duration" ] = 5.625;
	engineer_skill[ "rank_2_duration" ] = 6.25;
	engineer_skill[ "rank_3_duration" ] = 7.5;
	engineer_skill[ "rank_4_duration" ] = 10.0;

	engineer_skill[ "rank_0_cooldown" ] =  180;
	engineer_skill[ "rank_1_cooldown" ] =  180;
	engineer_skill[ "rank_2_cooldown" ] =  180;
	engineer_skill[ "rank_3_cooldown" ] =  180;
	engineer_skill[ "rank_4_cooldown" ] =  180;

	engineer_skill[ "perk" ] = "perk_rigger";
	self thread engineer_skill_setup(engineer_skill, secondary);

	self thread generic_skill_waiter( engineer_skill , 3, secondary );
}

engineer_skill_setup(engineer_skill, secondary)
{
	self endon( "death" );
	self endon( "disconnect" );

	while(1)
	{
		if( IsDefined( self.has_died_primary ) || IsDefined( self.has_died_secondary ) ) 
		{
			if( isDefined( secondary ) )
			{
				self.has_died_secondary = undefined;
				skill_cooldown_secondary( engineer_skill );
			}
			else
			{
				self.has_died_primary = undefined;
				skill_cooldown_primary( engineer_skill );
			}
		}
		//Wait for the player to press the skill button
		if( isDefined( secondary ) )
			self wait_for_secondary_skill_button();
		else
			self wait_for_primary_skill_button();

		variables = generic_variable_setup( engineer_skill );
		
		self thread sound_audio_weapon_activate();
		
		if( ability_cost( variables[ "cost" ], secondary ) )
		{
			//Spawn the slowfield
			self maps\mp\alien\_music_and_dialog::playEngineerClassSkillVO(self);
			self engineer_slow_field( variables );

			//Wait for power to be ready
			if( isDefined( secondary ) )
				skill_cooldown_secondary( engineer_skill );
			else
				skill_cooldown_primary( engineer_skill );	
		}

		wait .05;
	}
}

engineer_slow_field( variables )
{
	self endon( "death" );
	self endon( "disconnect" );

	//Place the effect at the location of the engineer
	generator = spawn( "script_model", self.origin );
	newOrigin = GetGroundPosition( self.origin + ( 0,0,20 )  , 2 );
	generator.ammo = 1000;  //used for trophy upgrade and players should not run out of ammo, as this field is based off time.
	
	if( IsDefined( newOrigin ) )
	{
		generator.origin = newOrigin ;	
	}

	generator SetModel( "mp_weapon_alien_crate" );
	//HACK TEMP
//	fxEnt = SpawnFx( loadfx( "vfx/gameplay/alien/vfx_alien_chopper_escape_ring" ), generator.origin , anglesToForward( generator.angles ), anglesToUp( generator.angles ) );

	//THE REAL ONE
	fxEnt = SpawnFx( loadfx( "vfx/gameplay/alien/vfx_alien_cskill_engnr_ff_01" ), generator.origin , anglesToForward( self.angles + ( -90 , 0 , 0 ) ), anglesToUp( generator.angles ) );
	sound_engineer = Spawn( "script_origin", generator.origin );
	sound_engineer PlayLoopSound( "alien_skill_engineer_lp" );
	TriggerFx( fxEnt );
	self thread disconnect_delete( fxEnt , "skill_done" );

	//Deal a slight amount of pain to enemies in the field
	level.slow_field_active = true;
	self thread handle_ally_threat( generator , variables );
	
//	if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "engineer_class_trophy_upgrade" ) )
	generator thread maps\mp\gametypes\_trophy_system::trophyActive( self );
	
	self alien_blocker_field( generator , variables );
	
	level.slow_field_active = false;
	sound_engineer StopLoopSound();
	wait 0.1;
	fxEnt delete();
	generator delete();
	sound_engineer delete();

	foreach ( player in level.players )
	{
		player.ignoreme = false;
	}
}

alien_blocker_field( generator , variables )
{
	self endon( "death" );
	self endon( "disconnect" );

	radius  = 245;
//	origins = [];
//	origins[0] 	= Spawn( "script_origin" , generator.origin + ( radius + 50 , 0 , 32 ) );
//	origins[1] 	= Spawn( "script_origin" , generator.origin - ( radius + 50 , 0 , 32 ) );
//	origins[2] 	= Spawn( "script_origin" , generator.origin + ( 0 , radius + 50 , 32 ) );
//	origins["rightOrg"]	= Spawn( "script_origin" , generator.origin - ( 0 , radius + 50 , 32 ) );
	
	self thread damage_enemies_in_range( generator);

//	linker = Spawn( "script_origin" , generator.origin );

//	foreach ( origin in origins)
//	{
//		origin MakeEntitySentient( "allies" );
//		origin.threatbias = self.threatbias;
//		origin.health = 10000;  
//		origin SetCanDamage( true );
//		origin LinkTo( linker );
//		self thread melee_attackers( origin );
//	}
//	linker RotateYaw( 180 , 10 , 0 , 10 );
	BadPlace_Cylinder( "cray_dome" , variables[ "duration" ] , generator.origin , radius , radius , "axis" );
	//Duration
	wait variables["duration"];	
	self notify( "stop_eng_damage" );
//	foreach ( origin in origins)
//	{
//		origin delete();
//	}
	BadPlace_Delete( "cray_dome" );
}

damage_enemies_in_range( generator )
{
	self endon( "stop_eng_damage" );
	self endon( "death" );
	self endon( "disconnect" );

	while(1)
	{
		aliens = maps\mp\alien\_spawnlogic::get_alive_agents();
		foreach ( alien in aliens )
		{
			if( Distance2D( generator.origin , alien.origin ) <= 256 )
			{
				alien DoDamage( 1 , generator.origin , self , self , "MOD_MELEE" );
				
				wait .5;
			}
			else
			{
//				alien.favoriteenemy = undefined;
			}
			wait .05;
		}
		wait .05;
	}
}

//melee_attackers( origin )
//{
//	self endon( "disconnect" );
//	self endon( "death" );
//	
//	while(1)
//	{
//		attacker DoDamage( 1 , origin.origin , self , self , "MOD_MELEE" );	
//	}
//}

handle_ally_threat( generator , variables )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "stop_eng_damage" );

	IGNORE_DISTANCE_SQ = 30625; // 175 * 175
	
	while(1)
	{
		foreach ( player in level.players )
		{
			if( Distance2DSquared( generator.origin , player.origin ) <= IGNORE_DISTANCE_SQ )
			{
				player.ignoreme = true;
				player thread safe_threat_restore( variables );
			}	
			else
			{
				player.ignoreme = false;
			}
		}
		wait .5;	
	}
}

safe_threat_restore( array )
{
	self endon( "death" );
	self endon( "disconnect" );
	wait array[ "duration" ];
	
	self.ignoreme = false;
	
}
 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												WEAPON SPECIALIST SKILL
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Crazy damage awesome mode pew pew pew
specialist_skill_icon_waiter( secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "clear_skills" );
	self endon( "clear_skills" );

	specialist_skill = [];
	specialist_skill[ "rank_0_cost" ] = 250;
	specialist_skill[ "rank_1_cost" ] = 350;
	specialist_skill[ "rank_2_cost" ] = 400;
	specialist_skill[ "rank_3_cost" ] = 450;
	specialist_skill[ "rank_4_cost" ] = 500;

	specialist_skill[ "rank_0_duration" ] = 5.00;
	specialist_skill[ "rank_1_duration" ] = 5.625;
	specialist_skill[ "rank_2_duration" ] = 6.25;
	specialist_skill[ "rank_3_duration" ] = 7.5;
	specialist_skill[ "rank_4_duration" ] = 10.0;

	specialist_skill[ "rank_0_cooldown" ] = 180;
	specialist_skill[ "rank_1_cooldown" ] = 180;
	specialist_skill[ "rank_2_cooldown" ] = 180; 
	specialist_skill[ "rank_3_cooldown" ] = 180;
	specialist_skill[ "rank_4_cooldown" ] = 180; 

	specialist_skill[ "perk" ] = "perk_bullet_damage";
	self thread specialist_skill_setup( specialist_skill, secondary );

	self thread generic_skill_waiter( specialist_skill , 1, secondary );
}

specialist_skill_setup( specialist_skill, secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	self.damage_increased = true;
	
	while(1)
	{
		if( IsDefined( self.has_died_primary ) || IsDefined( self.has_died_secondary ) ) 
		{
			if( isDefined( secondary ) )
			{
				self.has_died_secondary = undefined;
				skill_cooldown_secondary( specialist_skill );
			}
			else
			{
				self.has_died_primary = undefined;
				skill_cooldown_primary( specialist_skill );
			}
		}
		
		//Wait for the player to press the skill button
		if( isDefined( secondary ) )
			self wait_for_secondary_skill_button();
		else
			self wait_for_primary_skill_button();

		variables = generic_variable_setup( specialist_skill );
		
		self thread sound_audio_weapon_activate();
		
		if( ability_cost( variables[ "cost" ], secondary ) )
		{
			//Sends the weapon specialist into awesome kill mode
                        self maps\mp\alien\_music_and_dialog::playWeaponClassSkillVO(self);
			self.skill_in_use = true;
			self thread effect_on_fire( variables );
			self.camFX = SpawnFXForClient( LoadFX( "vfx/gameplay/alien/vfx_alien_cskill_wspecial_01" ), self.origin , self );
			TriggerFX( self.camFX );
			self specialist_boost( variables );

			self.skill_in_use = undefined;
			if( IsDefined( self.camFX ) )
				self.camFX delete();
			//Wait for power to be ready
			if( isDefined( secondary ) )
				skill_cooldown_secondary( specialist_skill );
			else
				skill_cooldown_primary( specialist_skill );	
		}

		wait .05;
	}
}

sound_audio_weapon_activate()
{
	audio_weapon = spawn_tag_origin();
	audio_weapon.origin = self.origin;
	audio_weapon.angles = self.angles;
	audio_weapon LinkTo( self );
	audio_weapon PlaySound( "alien_skill_activate" );
	wait 2;
	audio_weapon delete();
}

effect_on_fire(variables)
{
	self endon( "death" );
	self endon( "disconnect" );	
	PlayFXOnTag(LoadFX( "vfx/gameplay/alien/vfx_alien_cskill_wspecial_02" ) , self , "tag_origin" );

	self thread sound_audio_weapon(variables);
	
	waittill_any_timeout( variables[ "duration" ] , "last_stand" );
	StopFXOnTag(LoadFX( "vfx/gameplay/alien/vfx_alien_cskill_wspecial_02" ) , self , "tag_origin" );

}

sound_audio_weapon(variables)
{
	wait 0.3;
	audio_weapon = spawn( "script_origin", self.origin );
	self thread sound_position_update( audio_weapon );
	audio_weapon PlayLoopSound( "alien_skill_weapon_lp" );
	waittill_any_timeout(variables["duration"], variables["death"]);
	audio_weapon StopLoopSound();
	audio_weapon notify( "kill_node" );
	wait 1;
	audio_weapon delete();
}


//
specialist_boost( variables )
{
	self endon( "death" );
	self endon( "disconnect" );

	//store current damage multiplier, speed, and ammo
	ammo 			= self specialist_ammo_round_up();
//	initial_speed	= self.moveSpeedScaler;

	//Boost that damage!
	self thread specialist_death_watcher();
	self.ability_scalar_bullet = .9;
	foreach ( player in level.players)
	{
		if( player != self )
		{
			player thread temp_damage_increase( variables );
		}
	}

	//Unlimited Ammo!
	self thread unlimited_ammo( ammo );
//	self VisionSetNakedForPlayer( "aftermath_post", .5 );
	self maps\mp\alien\_utility::restore_client_fog( 0 );
	self thread maps\mp\alien\_outline_proto::set_alien_outline();

	wait variables["duration"];

	//Reset everything
	self SetClientOmnvar ( "ui_alien_unlimited_ammo", 0);
	level notify( "stop_specialist_power" );
	self.ability_scalar_bullet = 1;
//	self VisionSetNakedForPlayer( "", .5 );

	self remove_the_outline();
}

specialist_death_watcher()
{
	self waittill_any( "death" , "disconnect" , "stop_specialist_power" );
	if( IsDefined( self ) )
	{
		self.ability_scalar_bullet = 1;
		self SetClientOmnvar ( "ui_alien_unlimited_ammo", 0);
		StopFXOnTag(LoadFX( "vfx/gameplay/alien/vfx_alien_cskill_wspecial_02" ) , self , "tag_origin" );
	}
	if( IsDefined( self.camFX ) )
		self.camFX delete();
}

temp_damage_increase( variables )
{
	self endon( "death" );
	self endon( "disconnect" );

	if( !IsDefined( self.damage_increased ) )
	{
	   	self.damage_increased = true;
		self.ability_scalar_bullet = 1.1;
		wait variables["duration"];
		self.ability_scalar_bullet = 1;
		self.damage_increased = undefined;
	}
}

remove_the_outline()
{
	self endon( "death" );
	self endon( "disconnect" );

	if( IsDefined( self.isFeral ) && self.isFeral )
		return;
	
	self notify( "switchblade_over" );

	aliens = maps\mp\alien\_spawnlogic::get_alive_agents();
	foreach ( alien in aliens )
	{
		if ( isDefined( alien.damaged_by_players ) ) // this is set by a challenge that uses outlines, so don't mess with the outlines for these guys
			continue;
			
		if ( isDefined( alien.marked_for_challenge ) ) // this is set by a challenge that uses outlines, so don't mess with the outlines for these guys
			continue;
		
		if ( !isDefined( alien.pet) )
			maps\mp\alien\_outline_proto::disable_outline_for_player( alien, self );
	}
	if( !IsDefined( level.seeder_active_turrets ) )
		return;

	foreach ( turret in level.seeder_active_turrets)
	{
		if ( isDefined( turret ) && !isdefined(turret.pet))
		{
			maps\mp\alien\_outline_proto::disable_outline_for_player( turret, self );
		}
	}
	
}

specialist_ammo_round_up()
{
	self endon( "death" );
	self endon( "disconnect" );

	ammo = [];
	foreach ( weapon in self.weaponlist)
	{
		ammo[ weapon ] = self GetAmmoCount( weapon );
	}
	return ammo;
}

unlimited_ammo( ammo )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "stop_specialist_power" );

	if( self.weaponlist.size == 0 ) 
	{
		self.weaponlist[0] = self GetCurrentWeapon();
	}

	while(1)
	{
		bCheck = false;
		foreach ( index in self.weaponlist)
		{
			if( weapon_no_unlimited_check( self GetCurrentWeapon() ) )
			{
				self SetClientOmnvar ( "ui_alien_unlimited_ammo", 1);
			}
			else
			{
				self SetClientOmnvar ( "ui_alien_unlimited_ammo", 0);				
			}

			if( index == self GetCurrentWeapon() && weapon_no_unlimited_check( index )  )
			{
				bCheck = true;	
				self SetWeaponAmmoClip(	index , WeaponClipSize( index ) , "left" );
			}

			if( index == self GetCurrentWeapon() && weapon_no_unlimited_check( index ) )
			{
				bCheck = true;	
				self SetWeaponAmmoClip(	index , WeaponClipSize( index ) , "right" );
			}

			if( bCheck == false )
			{
				self specialist_ammo_round_up();
			}
		}
		wait .05;
	}
}

weapon_no_unlimited_check( weapon )
{
	bCheck = true;

	foreach( opWeapon in level.opWeaponsArray)
	{
		if( weapon == opWeapon )
		{
			bCheck = false;	
		}
	}
	return bCheck;	
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																															  UTILITIES
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Waits for the power to the be ready
skill_cooldown_primary( array )
{
	self endon( "death" );
	self endon( "disconnect" );

	bPause = false;
	cooldown_duration = get_wait_seconds( array );
	self.is_cooling_primary = true;
	self SetClientOmnvar( "ui_alien_class_skill_active" , false );
	timer = gettime() + int(1000 * cooldown_duration );
	self SetClientOmnvar( "ui_alien_class_skill_timer" , timer );
	self thread pause_cooldown_watcher();
	checker = timer;
	while( timer >= Gettime() )
	{
		if( IsDefined( self.laststand ) )
		{
			timer = timer + 1000;
			bPause = true;
		}
		else
		{
			checker = checker - 1000;
			if( bPause == true )
			{
				self SetClientOmnvar( "ui_alien_class_skill_timer" , checker );
				bPause = false;
			}			
		}
		wait 1;
	}
	self SetClientOmnvar( "ui_alien_class_skill_timer" , 0 );
	self.is_cooling_primary = undefined;
}

skill_cooldown_secondary( array )
{
	self endon( "death" );
	self endon( "disconnect" );

	bPause = false;
	cooldown_duration = get_wait_seconds( array );
	self.is_cooling_secondary = true;
	self SetClientOmnvar( "ui_alien_class_skill_active_secondary" , false );
	timer = gettime() + int(1000 * cooldown_duration );
	self SetClientOmnvar( "ui_alien_class_skill_timer_secondary" , timer );
	self thread pause_cooldown_watcher();
	checker = timer;
	while( timer >= Gettime() )
	{
		if( IsDefined( self.laststand ) )
		{
			timer = timer + 1000;
			bPause = true;
		}
		else
		{
			checker = checker - 1000;
			if( bPause == true )
			{
				self SetClientOmnvar( "ui_alien_class_skill_timer_secondary" , checker );
				bPause = false;
			}			
		}
		wait 1;
	}
	self SetClientOmnvar( "ui_alien_class_skill_timer_secondary" , 0 );
	self.is_cooling_secondary = undefined;
}
pause_cooldown_watcher()
{	
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "death" );
	
	while(IsDefined( self.is_cooling_secondary ) || IsDefined( self.is_cooling_primary ) )
	{
		if( IsDefined( self.laststand ) )
		{
			self SetClientOmnvar( "ui_alien_class_skill_blocked" , 1 );			
		}
		else
		{
			self SetClientOmnvar( "ui_alien_class_skill_blocked" , 0 );	
		}
		wait .1;
	}
}

get_wait_seconds( skill_array )
{
	cooldown=skill_array[ "rank_0_cooldown" ];
	
	primaryClass = self maps\mp\alien\_persistence::get_selected_perk_0();
	class_level = self maps\mp\alien\_persistence::get_perk_0_level();

	if( primaryClass == skill_array["perk"] && class_level == 0 )
	{
		cooldown = skill_array[ "rank_0_cooldown" ];
	}
	else if( primaryClass == skill_array["perk"] && class_level == 1 )
	{
		cooldown = skill_array[ "rank_1_cooldown" ];
	}
	else if( primaryClass == skill_array["perk"] && class_level == 2 )
	{
		cooldown = skill_array[ "rank_2_cooldown" ];
	}
	else if( primaryClass == skill_array["perk"] && class_level == 3 )
	{
		cooldown = skill_array[ "rank_3_cooldown" ];
	}
	else if( primaryClass == skill_array["perk"] && class_level == 4 )
	{
		cooldown = skill_array[ "rank_4_cooldown" ];
	}
	
	if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "cooldown_skills_upgrade" ) )
		cooldown = cooldown * 0.5;	

	return cooldown;
}

//Waits for the player to push the primary skill button
wait_for_primary_skill_button()
{
	self endon( "death" );
	self endon( "disconnect" );

	self.double_tapped_primary = undefined;
	while( !IsDefined( self.double_tapped_primary ) )
	{
		if( !IsDefined( self ) )
		{
			wait 1;
			break;			
		}

		self waittill( "action_slot_1" );
		if(IsDefined(self.turn_off_class_skill_activation))
			continue;
		if( !IsDefined( self.laststand ) )
		{
			self check_for_double_tap_primary();
		}
	}
}
check_for_double_tap_primary()
{
	self endon( "d_tap_limit_primary" );

	self thread timer_for_double_tap_primary();
	waittill_any( "action_slot_1" );
	self notify( "double_tapped_primary" );
	self.double_tapped_primary = true;
}

timer_for_double_tap_primary()
{
	self endon( "double_tapped_primary" );
	
	counter = 10;

	while( counter > 0 )
	{
		wait .05;
		counter = counter - 1;
	}
	self notify( "d_tap_limit_primary" );
}

//Waits for the player to push the secondary skill button
wait_for_secondary_skill_button()
{
	self endon( "death" );
	self endon( "disconnect" );

	self.double_tapped_secondary = undefined;
	while( !IsDefined( self.double_tapped_secondary ) )
	{
		if( !IsDefined( self ) )
		{
			wait 1;
			break;			
		}

		self waittill( "action_slot_3" );
		if(IsDefined(self.turn_off_class_skill_activation))
			continue;
		if( !IsDefined( self.laststand ) )
		{
			self check_for_double_tap_secondary();
		}
	}
}
check_for_double_tap_secondary()
{
	self endon( "d_tap_limit_secondary" );

	self thread timer_for_double_tap_secondary();
	waittill_any( "action_slot_3" );
	self notify( "double_tapped_secondary" );
	self.double_tapped_secondary = true;
}

timer_for_double_tap_secondary()
{
	self endon( "double_tapped_secondary" );
	
	counter = 10;

	while( counter > 0 )
	{
		wait .05;
		counter = counter - 1;
	}
	self notify( "d_tap_limit_secondary" );
}


//Remove money when the ability gets used
ability_cost( amount, secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
//	amount = 0;

//	cash_money = self maps\mp\alien\_persistence::get_player_currency();

//	if( cash_money >= amount && self offhand_check() == true )
//	if( self offhand_check() == true )
//	{
//		self maps\mp\alien\_persistence::set_player_currency( cash_money - amount );
//		self thread maps\mp\alien\_persistence::take_player_currency( amount , false , "ability" );
		
	if( isDefined ( secondary ) )
		self SetClientOmnvar( "ui_alien_class_skill_active_secondary" , true );
	else
		self SetClientOmnvar( "ui_alien_class_skill_active" , true );
	self notify( "class_skill_used" );
	return true;
//	}
//	else
//	{
//		return false;
//	}
}

deleteOnDeath( ent )
{
	self endon( "death" );
	self endon( "disconnect" );

	self waittill( "death" );

	if ( IsDefined( ent ) )
		ent delete();
}

//Makes sure the player doesn't have anything equipped in the offhand before allowing them to use their skills
offhand_check()
{
	self endon( "death" );
	self endon( "disconnect" );
	weapons = self GetWeaponsListOffhands();
	foreach ( weapon in weapons)
	{
		if( self GetAmmoCount( weapon ) )
		{
			return false;
		}
	}
	return true;
}

generic_skill_waiter( skill_array , omnvarNum, secondary )
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if( isDefined( secondary ) )
		self SetClientOmnvar ( "ui_alien_class_skill_secondary", omnvarNum );
	else
		self SetClientOmnvar ( "ui_alien_class_skill", omnvarNum );
}

generic_variable_setup( skill_array )
{
	self endon( "death" );
	self endon( "disconnect" );
	variables = [];

	secondaryClass = maps\mp\alien\_persistence::get_selected_perk_0_secondary();
	primaryClass = self maps\mp\alien\_persistence::get_selected_perk_0();
	class_level = self maps\mp\alien\_persistence::get_perk_0_level();

	if( ( primaryClass == skill_array["perk"] || secondaryClass == skill_array[ "perk" ] ) && class_level == 0 )
	{
		variables[ "cooldown" ] = skill_array[ "rank_0_cooldown" ];
		variables[ "cost" ]		= skill_array[ "rank_0_cost" ];
		variables[ "duration" ]	= skill_array[ "rank_0_duration" ];
	}
	else if( ( primaryClass == skill_array["perk"] || secondaryClass == skill_array[ "perk" ] ) && class_level == 1 )
	{
		variables[ "cooldown" ] = skill_array[ "rank_1_cooldown" ];	
		variables[ "cost" ]		= skill_array[ "rank_1_cost" ];	
		variables[ "duration" ]	= skill_array[ "rank_1_duration" ];
	}
	else if( ( primaryClass == skill_array["perk"] || secondaryClass == skill_array[ "perk" ] ) && class_level == 2 )
	{
		variables[ "cooldown" ] = skill_array[ "rank_2_cooldown" ];	
		variables[ "cost" ]		= skill_array[ "rank_2_cost" ];
		variables[ "duration" ]	= skill_array[ "rank_2_duration" ];
	}
	else if( ( primaryClass == skill_array["perk"] || secondaryClass == skill_array[ "perk" ] ) && class_level == 3 )
	{
		variables[ "cooldown" ] = skill_array[ "rank_3_cooldown" ];	
		variables[ "cost" ]		= skill_array[ "rank_3_cost" ];
		variables[ "duration" ]	= skill_array[ "rank_3_duration" ];
	}
	else if( ( primaryClass == skill_array["perk"] || secondaryClass == skill_array[ "perk" ] ) && class_level == 4 )
	{
		variables[ "cooldown" ] = skill_array[ "rank_4_cooldown" ];	
		variables[ "cost" ]		= skill_array[ "rank_4_cost" ];
		variables[ "duration" ]	= skill_array[ "rank_4_duration" ];
	}

	return variables;
}

death_check()
{
	self waittill( "death" );
	self.has_died_primary = true;
	self.has_died_secondary = true;
}

disconnect_delete( entity , notifyString )
{
	self endon( notifyString );

	self waittill_any( "disconnect" , "death" );
	if( IsDefined( entity) )
		entity delete();
}