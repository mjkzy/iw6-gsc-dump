#include common_scripts\utility;
	
/*
=============
///ScriptDocBegin
"Name: vulture_circling( <origin> )"
"Summary: Creates a vulture circling around the specified origin. Don't forget to include interactive_vulture_circling.csv in your zone file."
"Module: "
"CallOn: Nothing"
"MandatoryArg: <origin>: A vector specifying a point in space."
"Example: vulture_circling((105, -1320, 1600));"
"SPMP: Both"
///ScriptDocEnd
=============
*/

vulture_circling(origin, number)
{
	if ( !IsDefined(number) )
		number = 1;
	if ( !IsDefined(level._interactive) ) {
		level._interactive = [];
	}
	if ( !IsDefined(level._interactive["vultures"]) ) {
		level._interactive["vultures"]["count"] = 0;
		level._interactive["vultures"]["anims"][0] = "vulture_rig_circle";
		level._interactive["vultures"]["anims"][1] = "vulture_rig_circle2";
		level._interactive["vultures"]["anims"][2] = "vulture_rig_circle3";
		level._interactive["vultures"]["rigs"] = [];
		level._interactive["vultures"]["vultures"] = [];
	}
	for ( i=0; i<number; i++ ) {
		newOrigin = origin + ( (0,0,50) * i );
		if ( i > 0 )
			newOrigin += (0,0,RandomIntRange(-20,20));
		thread vulture_circling_internal(newOrigin);
	}
}

vulture_circling_internal(origin)
{
	count = level._interactive["vultures"]["rigs"].size;
	
	yaw = RandomInt(360);
	
	rig = Spawn( "script_model", origin );
	rig.angles = (0, yaw, 0);
	rig SetModel( "vulture_circle_rig" );
	
	vulture = Spawn( "script_model", rig.origin );
	vulture.angles = (0, yaw, 0);
	vulture SetModel( "ng_vulture" );
	
	vulture LinkTo( rig, "tag_attach" );
	riganim = level._interactive["vultures"]["anims"][mod(count, 3)];
	rig ScriptModelPlayAnim( riganim );
	level._interactive["vultures"]["vultures"][count] = vulture;
	level._interactive["vultures"]["rigs"][count] = rig;
	
	vulture endon("death");
	wait( RandomFloat(5) );
	vulture ScriptModelPlayAnim( "vulture_fly_loop_all" );
}

/#
vultures_toggle_thread()
{
	SetDevDvar("vultures_enable", "1");
	while ( true ) {
		while( GetDvarInt("vultures_enable") >= 1 )
		{
			wait .5;
		}
		IPrintLn("Deleting vultures");
		positions = [];
		foreach  (vulture in level._interactive["vultures"]["vultures"] ) {
			vulture Delete();
		}
		foreach ( rig in level._interactive["vultures"]["rigs"] ) {
			positions[positions.size] = rig.origin;
			rig Delete();
		}
		level._interactive["vultures"]["rigs"] = [];
		level._interactive["vultures"]["vultures"] = [];
		
		while( GetDvarInt("vultures_enable") < 1 )
		{
			wait .5;
		}
		IPrintLn("Adding vultures");
		foreach ( position in positions ) {
			thread vulture_circling(position);
		}
	}
}
#/