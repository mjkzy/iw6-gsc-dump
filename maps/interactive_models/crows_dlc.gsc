// Interactive_models\crows_dlc.gsc

// At Nate's suggestion I'm trying not to entangle this with other systems.  There are some things I can't avoid though.
// I introduced a level array called "_interactive" that I'll use for all this stuff that isn't a traditional destructible.
// However, my intention is that any given type of interactive object can have its own struct in this array.
// Crows are interactive_birds.  They have a rig that all the birds attach to and different bird models for flying vs sitting.

// The 'dlc' version uses modified mp animations, which are hacky but still, it should be copied over the original version if 
// we plan to continue using it for the next game. (NB: It hasn't been tested in SP yet.)
#include common_scripts\utility;
	
#using_animtree( "animals_dlc" );
main()
{
	info = SpawnStruct();
	info.interactive_type	= "crows_dlc";
	info.rig_model 			= "use_radiant_model";
	info.rig_animtree		= #animtree;
	info.rig_numtags		= 2;//backup, really handled in Radiant
	info.bird_model["idle"] = "crow_fly";
	info.bird_model["fly"]	= "crow_fly";
	info.bird_animtree		= #animtree;
	info.topSpeed			= 300;			// Inches per second.
	info.accn				= 75;			// Use this for both acceleration and deceleration.
	info.scareRadius		= 600;			// Default distance at which pigeons will leave perch to avoid player or AI.
	info.death_effect		= LoadFX( "fx/props/bird_feather_exp_black" );
	info.birdmodel_anims	= [];
	info.rigmodel_anims		= [];
	info.birdmodel_anims[ "idle" ][ 0 ] 		= %crow_idle_1;
	info.birdmodel_anims[ "idleweight" ][ 0 ]	= 1;
	info.birdmodel_anims[ "idle" ][ 1 ] 		= %crow_idle_2;
	info.birdmodel_anims[ "idleweight" ][ 1 ]	= 0.3;
	info.birdmodel_anims[ "flying" ] 			= %crow_fly;
	info.rigmodel_anims[ "flying" ]				= %pigeon_flock_fly_loop;
	info.rigmodel_anims[ "takeoff_wire" ]		= %pigeon_flock_takeoff_wire;	// These match the Radiant keypairs "interactive_takeoffAnim" and "interactive_landAnim"
	info.rigmodel_anims[ "land_wire" ]			= %pigeon_flock_land_wire;
	info.rigmodel_anims[ "takeoff_ground" ]		= %pigeon_flock_takeoff_ground;
	info.rigmodel_anims[ "land_ground" ]		= %pigeon_flock_land_ground;
	info.rigmodel_anims[ "takeoff_inpipe" ]		= %pigeon_flock_takeoff_inpipe;
	info.rigmodel_anims[ "land_inpipe" ]		= %pigeon_flock_land_inpipe;
	if ( !isSP() ) {
		info.birdmodel_anims[ "idlemp" ][ 0 ] 		= "crow_idle_1";
		info.birdmodel_anims[ "idlemp" ][ 1 ] 		= "crow_idle_2";
		info.birdmodel_anims[ "flyingmp" ] 			= "crow_fly";
		// These _mp animations for the rig are a hack. They are identical to the SP animations in length and 
		// motion, but keep the tags all facing forward, since the MP animations can't be rotated the same way 
		// the SP ones can.
		info.rigmodel_anims[ "flyingmp" ]			= "pigeon_flock_fly_loop_mp";
		info.rigmodel_anims[ "takeoff_wiremp" ]		= "pigeon_flock_takeoff_wire_mp";
		info.rigmodel_anims[ "land_wiremp" ]		= "pigeon_flock_land_wire_mp";
		info.rigmodel_anims[ "takeoff_groundmp" ]	= "pigeon_flock_takeoff_ground_mp";
		info.rigmodel_anims[ "land_groundmp" ]		= "pigeon_flock_land_ground_mp";
		info.rigmodel_anims[ "takeoff_inpipemp" ]	= "pigeon_flock_takeoff_inpipe_mp";
		info.rigmodel_anims[ "land_inpipemp" ]		= "pigeon_flock_land_inpipe_mp";		
		/*info.rigmodel_anims[ "flyingmp" ]			= "pigeon_flock_fly_loop";
		info.rigmodel_anims[ "takeoff_wiremp" ]		= "pigeon_flock_takeoff_wire";
		info.rigmodel_anims[ "land_wiremp" ]		= "pigeon_flock_land_wire";
		info.rigmodel_anims[ "takeoff_groundmp" ]	= "pigeon_flock_takeoff_ground";
		info.rigmodel_anims[ "land_groundmp" ]		= "pigeon_flock_land_ground";
		info.rigmodel_anims[ "takeoff_inpipemp" ]	= "pigeon_flock_takeoff_inpipe";
		info.rigmodel_anims[ "land_inpipemp" ]		= "pigeon_flock_land_inpipe";*/

	}
	info.sounds										= [];
	info.sounds[ "takeoff" ]						= "anml_crow_startle_flyaway";
	info.sounds[ "idle" ]							= "anml_crow_idle";
	//TODO JL will also need to change KVPs in 'prefabs/mp_shipment_ns/shns_interactive_crows.map' from 'sound_csv_include:animal_bird' to the new csv
	
	PreCacheModel( info.rig_model );
	foreach ( model in info.bird_model ) {
		PreCacheModel( model );
	}
	
	if( !isdefined ( level._interactive ) )
		level._interactive = [];
	level._interactive[ info.interactive_type ] = info;
	thread maps\interactive_models\_birds_dlc::birds(info);
}