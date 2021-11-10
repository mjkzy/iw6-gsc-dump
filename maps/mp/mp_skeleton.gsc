#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_skeleton_precache::main();
	maps\createart\mp_skeleton_art::main();
	maps\mp\mp_skeleton_fx::main();
	
	maps\mp\_load::main();
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_skeleton" );
	
	//Set bilinear mip for CurrentGen
	if ( !is_gen4() )
	{
	setdvar( "r_texFilterProbeBilinear", 1 );
	}
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	//Set Spec colorscale dvar to make up for differentials between CG and NG
	setdvar_cg_ng( "r_specularColorScale", 2.5, 6 );
	
	setDvar("r_umbraexclusive", 1 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	level thread portcullis_watch();	
	
	level thread initAdditionalCollision();
	
	level.spawn_closeEnemyDistSq = 1000 * 1000;
}

initAdditionalCollision()
{
	collision1 = GetEnt( "clip128x128x8", "targetname" );
	collision1Ent = spawn( "script_model", (-1065.81, -1288.17, 238.002) );
	collision1ent.angles = (352.044, 14.1584, 10.0585);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
	
	crate1 = spawn( "script_model", (1393.1, 1093.2, 160) );
	crate1 setModel( "com_plasticcase_green_big_us_dirt" );
	crate1.angles = (270, 0.999812, 20);
	
	crate2 = spawn( "script_model", (1381.76, 1122.11, 160) );
	crate2 setModel( "com_plasticcase_green_big_us_dirt" );
	crate2.angles = (270, 2.8, 20);
	
	//gryphon kill trigger
	gryphonTrig1Ent = spawn( "trigger_radius", (4176, 976, -240), 0, 750, 375 );
	gryphonTrig1Ent.radius = 750;
	gryphonTrig1Ent.height = 375;
	gryphonTrig1Ent.angles = (0,0,0);
	gryphonTrig1Ent.targetname = "gryphonDeath";
}

portcullis_watch()
{
	intact_gate = GetEnt( "gate", "targetname" );
	destroyed_gate = GetEnt( "gate_d", "targetname" );
	gate_dest = getstruct( intact_gate.target, "targetname" );
	destroyed_collision = GetEnt( "destroyed_collision", "targetname" );
	intact_collision = GetEnt( "intact_collision", "targetname" );
	killCam_loc = getstruct( "gate_killcam", "targetname" );
	
	gate_crash_time = 1.0;

	intact_collision.killCamEnt = Spawn( "script_model", killCam_loc.origin );
	intact_collision.killCamEnt SetModel( "tag_origin" );
	
	destroyed_gate Hide();
	destroyed_gate LinkTo( intact_gate );

 	//repeatable for debugging		
//	intact_gate.original_origin = intact_gate.origin;	
//	while( 1 )
//	{

		destroyed_collision NotSolid();
		intact_collision NotSolid();
		intact_collision ConnectPaths();
		intact_collision.dest_origin = intact_collision.origin;
		intact_collision MoveTo( intact_gate.origin, 0.1, 0.0, 0.0 );
		
		intact_gate SetCanDamage( true );
		
		// Start Gate fall
		intact_gate waittill( "damage", damage, attacker, direction_vec, impact_loc, damage_type );
	
		intact_gate MoveTo( gate_dest.origin, gate_crash_time, gate_crash_time, 0.0 );
		intact_collision Solid();
		intact_collision MoveTo( intact_collision.dest_origin, gate_crash_time, gate_crash_time, 0.0 );

		// make the gate crush guys underneath
		intact_collision.unresolved_collision_notify_min = 1;
		intact_collision.unresolved_collision_kill = true;
		intact_collision.owner = attacker;
		
		intact_gate PlaySoundOnMovingEnt( "scn_skeleton_portcullis_close" );
		
		intact_collision thread maps\mp\_movers::player_pushed_kill(0);
		
		wait( gate_crash_time );
		
		// Fall finished
		intact_collision DisconnectPaths();
		
		intact_collision thread maps\mp\_movers::stop_player_pushed_kill();
	
		// this code shouldn't be necessary, as player_pushed_kill should handle it, but it's here as a failsafe.
		foreach ( character in level.characters )
		{
			if ( character IsTouching( intact_collision ) && IsAlive( character ) )
			{	
				if ( IsDefined( attacker ) && IsDefined( attacker.team ) && ( attacker.team == character.team ) )
				{
					character maps\mp\_movers::mover_suicide();
				}
				else
				{
					character DoDamage( character.health + 20, character.origin, attacker, intact_collision, "MOD_CRUSH" );
				}
			}
		}
	
		foreach ( vanguard in level.remote_uav )
		{
			if ( vanguard IsTouching( intact_collision ) )
			{
				vanguard notify( "death" );
			}
		}
	
		Earthquake( 0.5, 1.0, intact_gate.origin, 1000 );
		PlayFX( getfx( "vfx_mp_skeleton_gate_dust" ), gate_dest.origin + (0,0,60), AnglesToForward( intact_gate.angles + (0,90,0) ), (1,0,0) );
		
		// Gate is closed, wait to punch a hole through it
		while( 1 )
		{
			intact_gate waittill( "damage", damage, attacker, direction_vec, impact_loc, damage_type );
			if( damage_type == "MOD_EXPLOSIVE" 
			   || damage_type == "MOD_GRENADE_SPLASH" 
			   || damage_type == "MOD_PROJECTILE" 
			   || damage_type == "MOD_GRENADE"
			  )
			{
				PlayFX( getfx( "vfx_gate_explode" ), impact_loc, direction_vec );
				
				break;
			}
		}
		
		// Hiding is insufficient, bullet collision remains. Setcontents(0) didn't work either.
		intact_gate Delete();
	
		intact_collision NotSolid();
		destroyed_collision Solid();
		intact_collision ConnectPaths();
		
		destroyed_gate Show();
		
		PlaySoundAtPos( destroyed_gate.origin, "scn_skeleton_portcullis_exp" );
		
		// repeatable for debugging		
//		wait( 3.0 );
//		destroyed_gate Hide();
//		intact_gate Show();
//		intact_gate MoveTo( intact_gate.original_origin, 0.1 );
//		wait( 0.1 );
//	}

}
